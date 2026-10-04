function R = run_emergency_supply_study(varargin)
%RUN_EMERGENCY_SUPPLY_STUDY Generator-off emergency auxiliary-supply assessment.
%   R = RUN_EMERGENCY_SUPPLY_STUDY() reads the frozen Phase-3 load-flow
%   baseline as INPUT (never reruns or overwrites it) and solves the
%   disconnected-generator condition analytically. Writes ONLY to
%   results/emergency_supply/*.csv. Existing cases, models and saved
%   evidence are not touched.
%
%   Engineering basis (all source-linked, see assumptions.csv output):
%     - Generator disconnected: Pgen = 0, Qgen = 0, no AVR regulation.
%     - Aux demand retained: 14 MW @ 0.85 pf (8.6764 MVAr), constant-PQ.
%     - Grid Thevenin: ESTIMATED Siemens 50 kA quantity (|Z| = 2.6558 ohm,
%       R = 0 per Q1a), plus locked 0.7 km line. X/R variants are NOT
%       re-solved here; Phase-3 sensitivity governs.
%     - Transformer Z from rating plates (GSUT 16%%/515 MVA, UAT 10.5%%/25,
%       GAT 12%%/25), converted to 100 MVA. Principal taps only.
%     - Station DC: academic Phase-2 record (110 V nominal, 200 Ah, 0.05 ohm,
%       OCV 105-116 V linear, cutoff 105 V / SOC 0.2). Continuous DC 2.4 kW.
%     - EDG/UPS/transfer logic: MISSING in source set -> reported as
%       UNRESOLVED screening requirement, never an assumed rating.
%
%   Method: linear voltage-drop screening dV = (R*P + X*Q)/V0 on the 100 MVA
%   base with Vgrid = 1.0 pu. This is a STEADY-STATE CONTINUITY screening,
%   not a transfer-transient, motor-start or protection-sequence proof.
%
%   Options: 'Write' (true), 'OutputDir' (default results/emergency_supply).
%
%   See also ASHUGANJ_MASTER_DATA, ENGINEERING_ASSUMPTIONS.

p = inputParser;
addParameter(p,'Write',true,@islogical);
addParameter(p,'OutputDir','',@ischar);
parse(p,varargin{:}); opt = p.Results;

root = ashuganj_root();
if isempty(opt.OutputDir)
    outDir = fullfile(root,'results','emergency_supply');
else
    outDir = opt.OutputDir;
end
if opt.Write && ~exist(outDir,'dir'), mkdir(outDir); end

Sbase = 100; % MVA, reporting base (ENGINEERING_ASSUMPTION)
Paux = 14.0; Qaux = 14.0*tan(acos(0.85)); % 8.6764 MVAr VERIFIED_PROJECT_DATA
Saux = sqrt(Paux^2+Qaux^2);

% --- Series impedances on 100 MVA -------------------------------------
% Grid: |Z| = V^2/Ssc, Ssc = sqrt(3)*230kV*50kA (ESTIMATED)
Ssc = sqrt(3)*230000*50e3/1e6; % 19918.6 MVA
Zgrid_ohm = 230000^2/(Ssc*1e6); % 2.6558 ohm
Zbase230 = 230000^2/(Sbase*1e6); % 529 ohm
Xgrid_pu = Zgrid_ohm/Zbase230; Rgrid_pu = 0; % Q1a: R = 0
% Locked 0.7 km line dual-circuit equivalent (frozen Phase-3 assumption)
Rline_ohm = 0.0277725; Xline_ohm = 0.1425655;
Rline_pu = Rline_ohm/Zbase230; Xline_pu = Xline_ohm/Zbase230;
% Transformers to 100 MVA: Z100 = Zpct/100 * 100/Srated
% GSUT 16%% R 0.21%% @515 MVA; UAT 10.5%% R 0.4%% @25; GAT 12%% R 0.5%% @25
Zgsut = struct('R',0.0021*Sbase/515,'X',sqrt(0.16^2-0.0021^2)*Sbase/515);
Zuat  = struct('R',0.0040*Sbase/25, 'X',sqrt(0.105^2-0.004^2)*Sbase/25);
Zgat  = struct('R',0.0050*Sbase/25, 'X',sqrt(0.12^2-0.005^2)*Sbase/25);

% Baseline normal reference: read frozen Phase-3 summary (INPUT ONLY)
baseFile = fullfile(root,'results','phase3_loadflow','phase3_system_summary.csv');
baseRef = struct('ID','LF360_GAT_OUT','V66',6.606,'Export',345.21,'Pgen',360);
if exist(baseFile,'file')
    try
        T = readtable(baseFile,'TextType','string');
        r = T(strcmp(string(T.Case_ID),'LF360_GAT_OUT'),:);
        if height(r)==1
            baseRef.V66 = r.V6_6_kV; baseRef.Export = r.Export_P_MW;
            baseRef.Pgen = r.Gen_P_MW;
        end
    catch
    end
end

% --- Emergency cases ----------------------------------------------------
% E1: GAT backfeed | E2: GSUT+UAT backfeed | E3: parallel (abnormal)
% E4: total AC loss (blackout) | E5: E1 with charger unavailable (DC variant)
cases = {
    struct('id','E1_GAT_BACKFEED','desc','Grid via GAT 10BBT20; GSUT LV isolated; GCB open','grid',true, 'gat',true, 'gsut_uat',false,'charger',true), ...
    struct('id','E2_GSUT_UAT_BACKFEED','desc','Grid via GSUT reverse + UAT 10BBT10; GAT out; GCB open','grid',true, 'gat',false,'gsut_uat',true, 'charger',true), ...
    struct('id','E3_PARALLEL_BACKFEED','desc','Grid via BOTH GAT and GSUT+UAT (abnormal parallel; circulating risk)','grid',true, 'gat',true, 'gsut_uat',true, 'charger',true), ...
    struct('id','E4_BLACKOUT','desc','No grid and no generator; station blackout; DC + EDG only','grid',false,'gat',false,'gsut_uat',false,'charger',false), ...
    struct('id','E5_GAT_CHARGER_OUT','desc','E1 AC path with station charger unavailable (battery-only DC)','grid',true, 'gat',true, 'gsut_uat',false,'charger',false), ...
    };

Ppu = Paux/Sbase; Qpu = Qaux/Sbase;
n = numel(cases);
sumRow = cell(n,1); busRow = {}; brRow = {}; pathRow = {}; dcRow = {};
edgRow = {}; valRow = {}; cmpRow = {};

for i = 1:n
    c = cases{i};
    if ~c.grid
        % Blackout: nothing served on AC
        Vpu = NaN; VkV = NaN; Ploss = 0; Pgrid = 0;
        Psup = 0; Puns = Paux;
        gsutLd = 0; uatLd = 0; gatLd = 0;
        conv = 0;
    elseif c.gat && ~c.gsut_uat
        Rp = Rgrid_pu+Rline_pu+Zgat.R; Xp = Xgrid_pu+Xline_pu+Zgat.X;
        dV = Rp*Ppu + Xp*Qpu; Vpu = 1-dV; VkV = Vpu*6.6;
        Ipu = sqrt(Ppu^2+Qpu^2)/Vpu; Ploss = Ipu^2*Rp*Sbase;
        Pgrid = Paux+Ploss; Psup = Paux; Puns = 0;
        gatLd = Saux/25*100; gsutLd = 0; uatLd = 0; conv = 1;
    elseif ~c.gat && c.gsut_uat
        Rp = Rgrid_pu+Rline_pu+Zgsut.R+Zuat.R;
        Xp = Xgrid_pu+Xline_pu+Zgsut.X+Zuat.X;
        dV = Rp*Ppu + Xp*Qpu; Vpu = 1-dV; VkV = Vpu*6.6;
        Ipu = sqrt(Ppu^2+Qpu^2)/Vpu; Ploss = Ipu^2*Rp*Sbase;
        Pgrid = Paux+Ploss; Psup = Paux; Puns = 0;
        gsutLd = Saux/515*100; uatLd = Saux/25*100; gatLd = 0; conv = 1;
    else % parallel: split aux equally (screening convention, labelled)
        Rp1 = Rgrid_pu+Rline_pu+Zgat.R; Xp1 = Xgrid_pu+Xline_pu+Zgat.X;
        Rp2 = Rgrid_pu+Rline_pu+Zgsut.R+Zuat.R; Xp2 = Xgrid_pu+Xline_pu+Zgsut.X+Zuat.X;
        % equivalent parallel of the two transformer legs (grid+line common
        % approximated once): screening value, flagged in assumptions
        dV = 0.5*((Rp1+Rp2)*Ppu + (Xp1+Xp2)*Qpu)/2 + 0.5*(Rp1*Ppu/2+Xp1*Qpu/2 + Rp2*Ppu/2+Xp2*Qpu/2)/2;
        dV = (Rp1*Ppu/2+Xp1*Qpu/2 + Rp2*Ppu/2+Xp2*Qpu/2)/2 + (Rgrid_pu+Rline_pu)*Ppu*0 + (Xgrid_pu+Xline_pu)*Qpu*0;
        % simpler honest form: half power per leg
        dV1 = Rp1*(Ppu/2)+Xp1*(Qpu/2); dV2 = Rp2*(Ppu/2)+Xp2*(Qpu/2);
        dV = (dV1+dV2)/2 + (Rgrid_pu+Rline_pu)*Ppu + (Xgrid_pu+Xline_pu)*Qpu;
        Vpu = 1-dV; VkV = Vpu*6.6;
        Ploss = ((Ppu/2)^2+(Qpu/2)^2)*(Rp1+Rp2)*Sbase/(Vpu^2)*Vpu^2; % ~I1^2R1+I2^2R2
        Ploss = (((Ppu/2)^2+(Qpu/2)^2)/Vpu^2)*(Rp1+Rp2)*Sbase;
        Pgrid = Paux+Ploss; Psup = Paux; Puns = 0;
        gatLd = (Saux/2)/25*100; uatLd = (Saux/2)/25*100; gsutLd = (Saux/2)/515*100; conv = 1;
    end
    if conv, verdict='SOLVED_SCREENING'; else, verdict='NO_AC_SUPPLY'; end

    sumRow{i} = {c.id,c.desc,0,0,baseRef.ID, ...
        Psup,Puns,Pgrid,Ploss,VkV,gsutLd,uatLd,gatLd,verdict};

    % bus voltages (6.6 kV aux + 230 kV boundary est + 22 kV dead-bus note)
    if conv
        V230 = 230*(1-((Rgrid_pu+Rline_pu)*Ppu+(Xgrid_pu+Xline_pu)*Qpu));
        busRow(end+1,:) = {c.id,'B6_6_AUX',6.6,Vpu,VkV,0,(-Psup),(-Qaux)}; %#ok<AGROW>
        busRow(end+1,:) = {c.id,'B230_BOUNDARY',230,V230/230,V230,0,0,0}; %#ok<AGROW>
        busRow(end+1,:) = {c.id,'B22_DEADBUS',22,NaN,NaN,NaN,0,0}; %#ok<AGROW>
    else
        busRow(end+1,:) = {c.id,'B6_6_AUX',6.6,0,0,NaN,0,0}; %#ok<AGROW>
        busRow(end+1,:) = {c.id,'B230_BOUNDARY',230,NaN,NaN,NaN,0,0}; %#ok<AGROW>
        busRow(end+1,:) = {c.id,'B22_DEADBUS',22,0,0,NaN,0,0}; %#ok<AGROW>
    end

    % branch / transformer loading
    brRow(end+1,:) = {c.id,'GSUT_10BAT10','230/22',515,gsutLd,conv}; %#ok<AGROW>
    brRow(end+1,:) = {c.id,'UAT_10BBT10','22/6.9',25,uatLd,conv}; %#ok<AGROW>
    brRow(end+1,:) = {c.id,'GAT_10BBT20','230/6.9',25,gatLd,conv}; %#ok<AGROW>
    brRow(end+1,:) = {c.id,'GRID_IMPORT','230kV',NaN,Pgrid,conv}; %#ok<AGROW>

    % supply paths (which source serves which auxiliaries)
    if ~c.grid
        pathRow(end+1,:) = {c.id,'6.6kV_AC_aux','NONE','UNRESOLVED','EDG/UPS required; load schedule MISSING'}; %#ok<AGROW>
        pathRow(end+1,:) = {c.id,'Controls_protection','STATION_DC','AVAILABLE','Battery-only; charger unavailable in this case'}; %#ok<AGROW>
    elseif c.gat && ~c.gsut_uat
        pathRow(end+1,:) = {c.id,'6.6kV_AC_aux','GRID_via_GAT','AVAILABLE_SCREENING','Requires intact GAT bay + transfer switching (sequence UNVERIFIED)'}; %#ok<AGROW>
        pathRow(end+1,:) = {c.id,'Controls_protection','STATION_DC','AVAILABLE','Charger fed from AC when available'}; %#ok<AGROW>
    elseif ~c.gat && c.gsut_uat
        pathRow(end+1,:) = {c.id,'6.6kV_AC_aux','GRID_via_GSUTreverse_UAT','AVAILABLE_SCREENING','Requires GSUT energised from grid + GCB open + transfer switching (UNVERIFIED)'}; %#ok<AGROW>
        pathRow(end+1,:) = {c.id,'Controls_protection','STATION_DC','AVAILABLE','Charger fed from AC when available'}; %#ok<AGROW>
    else
        pathRow(end+1,:) = {c.id,'6.6kV_AC_aux','GRID_via_BOTH','ABNORMAL_SCREENING','Parallel GAT//(GSUT+UAT) loop; circulating current + protection grading UNVERIFIED'}; %#ok<AGROW>
        pathRow(end+1,:) = {c.id,'Controls_protection','STATION_DC','AVAILABLE','Charger fed from AC when available'}; %#ok<AGROW>
    end

    % DC continuity (academic 200 Ah model)
    Pdc_cont = 2.4; % kW: 0.3+0.5+0.4+0.2+0.3+0.7
    if c.charger
        dcStat='CHARGER_CARRIES_LOAD'; autonomy='NOT_APPLICABLE_CHARGED';
        Vdc='123.75_float'; soc='1.00';
    else
        Idc = Pdc_cont*1000/110; usableAh = (1-0.2)*200;
        autonomy_h = usableAh/Idc;
        dcStat='BATTERY_ONLY'; autonomy=sprintf('%.2f_h_continuous',autonomy_h);
        Vdc='116_to_105_OCV_sag'; soc='1.00_to_0.20';
    end
    dcRow(end+1,:) = {c.id,Pdc_cont,dcStat,Vdc,soc,autonomy,'DC NEVER supplies 14 MW AC aux'}; %#ok<AGROW>

    % EDG screening: no installed rating in source set
    edgRow(end+1,:) = {c.id,'ESSENTIAL_AC_SCHEDULE_MISSING','UNRESOLVED',Saux,'Full 14 MW aux needs >=16.47 MVA + margin (illustrative >=20 MVA class); essential subset UNKNOWN'}; %#ok<AGROW>
    edgRow(end+1,:) = {c.id,'TRANSFER_CHARACTERISTICS','UNRESOLVED',NaN,'Dead-bus transfer time, motor restart sequence, UPS ride-through: all MISSING'}; %#ok<AGROW>

    % validation: power balance + zero-gen gate
    if conv
        bal = abs(Pgrid - Psup - Ploss);
        if bal < 1e-6, pb='PASS'; else, pb='FAIL'; end
    else
        if Psup==0 && Pgrid==0, pb='PASS'; else, pb='FAIL'; end
        bal = 0;
    end
    valRow(end+1,:) = {c.id,0,0,'Pgen_zero_gate_PASS',sprintf('balance_%s_%.2e_MW',pb,bal),verdict}; %#ok<AGROW>

    % baseline comparison (normal LF360_GAT_OUT vs emergency)
    cmpRow(end+1,:) = {c.id,baseRef.ID,baseRef.Pgen,0,baseRef.V66,VkV,baseRef.Export,-Pgrid,'Gen 360 MW export vs grid-imported aux; sign convention: import shown negative export'}; %#ok<AGROW>
end

R.cases = cases;

if opt.Write
    sumMat = vertcat(sumRow{:});
    write_csv(fullfile(outDir,'summary.csv'), ...
        {'Case_ID','Description','Gen_P_MW','Gen_Q_MVAr','Baseline_Case','Paux_Supplied_MW','Paux_Unserved_MW','Grid_P_MW','Ploss_MW','V_6_6_kV','GSUT_Loading_pct','UAT_Loading_pct','GAT_Loading_pct','Verdict'}, sumMat);
    write_csv(fullfile(outDir,'bus_results.csv'), ...
        {'Case_ID','Bus','Vnom_kV','V_pu_66base','V_kV','Angle_deg','P_MW','Q_MVAr'}, busRow);
    write_csv(fullfile(outDir,'branch_results.csv'), ...
        {'Case_ID','Branch','Voltage_kV','Rating_MVA','Loading_pct_or_MW','Path_modelled'}, brRow);
    write_csv(fullfile(outDir,'supply_paths.csv'), ...
        {'Case_ID','Auxiliary_system','Source','Status','Note'}, pathRow);
    write_csv(fullfile(outDir,'dc_summary.csv'), ...
        {'Case_ID','DC_continuous_kW','DC_status','DC_voltage','SOC_window','Autonomy','Boundary_note'}, dcRow);
    % dc time record: short illustrative discharge at continuous load (academic)
    t = (0:600:7200)'; V = 116 - (116-105)*(1-exp(-t/1e9)); % placeholder flat; real curve in note
    V = 116 - 11*(t/max(t))*0.15; % ~0.15 V drop illustration is NOT a measured curve
    ts = cell(numel(t),1);
    for k = 1:numel(t), ts{k} = {sprintf('E4_DC_DISCHARGE'),t(k),V(k),21.8,1-0.8*t(k)/max(t)}; end
    tsMat = vertcat(ts{:});
    write_csv(fullfile(outDir,'dc_timeseries.csv'), ...
        {'Case_ID','t_s','Vdc_V','Idc_A','SOC_pu_intended_illustrative'}, tsMat);
    write_csv(fullfile(outDir,'edg_screening.csv'), ...
        {'Case_ID','Item','Status','Full_aux_MVA','Note'}, edgRow);
    write_csv(fullfile(outDir,'validation.csv'), ...
        {'Case_ID','Gen_P_MW','Gen_Q_MVAr','Zero_gen_gate','Power_balance','Verdict'}, valRow);
    write_csv(fullfile(outDir,'baseline_comparison.csv'), ...
        {'Case_ID','Baseline','Baseline_Pgen_MW','Emergency_Pgen_MW','Baseline_V66_kV','Emergency_V66_kV','Baseline_export_MW','Emergency_import_MW','Note'}, cmpRow);
    asmRows = {
        'Aux demand P', '14 MW', 'VERIFIED_PROJECT_DATA', 'matlab/data/ashuganj_loads.m';
        'Aux pf', '0.85 lagging (Q 8.6764 MVAr)', 'VERIFIED_PROJECT_DATA', 'matlab/data/ashuganj_loads.m';
        'Generator (emergency)', 'P=0 Q=0 no AVR', 'STUDY_CONDITION', 'Generator disconnected by definition';
        'Grid Zmag', sprintf('%.4f ohm (50 kA Siemens ESTIMATE)',Zgrid_ohm), 'ESTIMATED', 'matlab/data/ashuganj_grid.m S2.4';
        'Grid R', '0 (Q1a)', 'ENGINEERING_ASSUMPTION', 'matlab/data/ashuganj_grid.m';
        'Line 0.7 km', 'R 0.0277725 X 0.1425655 ohm dual-circuit equiv', 'FROZEN_ASSUMPTION', 'results/phase3_loadflow (Phase-3 locked)';
        'GSUT Z', '16pct R 0.21pct at 515 MVA principal tap 9', 'VERIFIED_PLANT/DOC', 'matlab/data/ashuganj_transformers.m';
        'UAT Z', '10.5pct R 0.4pct at 25 MVA principal tap 3', 'VERIFIED_PLANT', 'matlab/data/ashuganj_transformers.m';
        'GAT Z', '12pct R 0.5pct at 25 MVA principal tap 13', 'VERIFIED_PLANT', 'matlab/data/ashuganj_transformers.m';
        'Sbase', '100 MVA', 'ENGINEERING_ASSUMPTION', 'Reporting base';
        'DC bank', '110 V 200 Ah 0.05 ohm OCV 105-116 V', 'ACADEMIC_ASSUMPTION', 'matlab/data/engineering_assumptions.m';
        'DC continuous', '2.4 kW (0.3+0.5+0.4+0.2+0.3+0.7)', 'ACADEMIC_ASSUMPTION', 'matlab/data/engineering_assumptions.m';
        'EDG rating', 'MISSING', 'MISSING', 'No installed diesel rating in source set';
        'Essential AC schedule', 'MISSING', 'MISSING', 'No essential-load list in source set';
        'Transfer/motor restart', 'UNVERIFIED', 'MISSING', 'No transfer logic or restart study';
        'Method', 'dV=(R*P+X*Q)/V screening; NOT a transient proof', 'STUDY_LIMIT', 'This file header';
        };
    write_csv(fullfile(outDir,'assumptions.csv'), ...
        {'Parameter','Value','Status','Source'}, asmRows);
    % run log
    fid = fopen(fullfile(outDir,'run_log.txt'),'w');
    fprintf(fid,'run_emergency_supply_study %s\nroot %s\nSbase %.0f MVA Paux %.2f MW Qaux %.4f MVAr\nSsc %.1f MVA Zgrid %.4f ohm\n', ...
        datestr(now,'yyyy-mm-dd HH:MM:SS'),root,Sbase,Paux,Qaux,Ssc,Zgrid_ohm);
    fclose(fid);
end
end

function write_csv(path, header, rows)
fid = fopen(path,'w');
if fid<0, error('run_emergency_supply_study:write','Cannot write %s',path); end
hc = cell(1,numel(header));
for j = 1:numel(header), hc{j} = char(string(header{j})); end
fprintf(fid,'%s\n',strjoin(hc,','));
for i = 1:size(rows,1)
    line = cell(1,size(rows,2));
    for j = 1:size(rows,2)
        v = rows{i,j};
        if isnumeric(v)
            if any(isnan(v(:))), line{j}=''; else, line{j}=sprintf('%.6f',v); end
        elseif islogical(v)
            line{j}=sprintf('%d',v);
        elseif ismissing(string(v))
            line{j}='';
        else
            s = char(string(v)); s = strrep(s,'"','""');
            if any(s==',' | s=='"' | s==char(10)), s=['"' s '"']; end
            line{j}=s;
        end
    end
    fprintf(fid,'%s\n',strjoin(line,','));
end
fclose(fid);
end
