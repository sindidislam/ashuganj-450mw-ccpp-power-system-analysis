function E = phase5b_effectiveness(T40, devices, B)
%PHASE5B_EFFECTIVENESS Conditional detectability and engineering time proxies.
%   The original 13 columns and 48-row layout remain. Optional B reuses the
%   identity-gated phasors. Their magnitudes are on the FAULT-location base,
%   so all comparisons are referred to the physical relay voltage first.
%   These magnitude screens do not simulate vector-group compensation,
%   percentage restraint, CT saturation, channel logic, or installed relays.
%   A positive screen is CONDITIONAL-DETECTABILITY. Inf means NO-TRIP or an
%   explicit NO-PAIR/OUT-OF-ZONE, never an unresolved operating time.
%   Primary times are operate proxies; breaker clearing is a separate field.
if nargin < 2 || nargin > 3
    error('phase5b_effectiveness:args','usage: E = phase5b_effectiveness(T40,devices[,B]).');
end
if ~istable(T40) || isempty(T40) || ~all(ismember({'fault_location','fault_type','caseID','leg_NER_earth_kA'},T40.Properties.VariableNames))
    error('phase5b_effectiveness:schema','T40 requires non-empty imported rows and the NER branch.');
end
if ~isstruct(devices) || isempty(devices) || ~isfield(devices,'device_id')
    error('phase5b_effectiveness:devices','devices must be registry rows.');
end
g87=reqdev(devices,'GEN-87G'); t87=reqdev(devices,'GSUT-87T');
b87=reqdev(devices,'GIS-87B'); l87=reqdev(devices,'LINE-7SD');
gen=reqdev(devices,'GEN-51'); ef=reqdev(devices,'GEN-51N');
hv=reqdev(devices,'GSUT-HV-51'); q0=reqdev(devices,'GIS-Q0-51');
bl=reqdev(devices,'GEN-51-SIEMENS-BL'); earth64=reqdev(devices,'GEN-64G');
% Registry owns the adopted thresholds and explicitly classified timings.
for d=[g87,t87,b87,l87]
    if ~isfinite(d.pickup_A) || d.pickup_A<=0
        error('phase5b_effectiveness:pickup','%s requires a numerical adopted study pickup.',d.device_id);
    end
end
if nargin < 3 || isempty(B)
    if exist('phase5b_cached_branches','file') == 2
        B=phase5b_cached_branches(T40);
    else
        B=phase5b_branch_phasors(T40);
    end
end
rows=cell(0,24);
for i=1:height(T40)
    loc=char(string(T40.fault_location(i))); typ=char(string(T40.fault_type(i)));
    cs=char(string(T40.caseID(i)));
    if any(strcmp(loc,{'F1','F2'})), vf=22; else, vf=230; end
    neutral=double(T40.leg_NER_earth_kA(i))*3000;
    supplementary='NONE'; supplementaryTime=NaN;
    supplementaryBasis='NOT-APPLICABLE: no supplementary stator-earth proxy in this row';
    breakerProxy=NaN;
    switch loc
        case 'F1'
            pd=g87; pf='GEN-87G'; base=22;
            observed=bget(B,cs,loc,typ,'GEN')*vf/base;
            if strcmp(typ,'LG')
                % LG phase through-current contains a large circulating/load
                % component. The incremental earth-fault screen uses the
                % dedicated neutral 3I0, not that terminal magnitude.
                observed=neutral;
                pnote=sprintf('LG incremental-earth-fault screen 3I0 %.9g A; phase terminal %.9g A includes circulating/load component and is not differential current', ...
                    observed,bget(B,cs,loc,typ,'GEN'));
                supplementary='GEN-64G'; supplementaryTime=proxy(earth64,'trip_delay_s');
                supplementaryBasis=sprintf('ENGINEERING_STUDY_PROXY:64G %.9g s; 20Hz injection is not simulated by this 50Hz phasor model; no detection conclusion',supplementaryTime);
            else
                pnote=sprintf('GEN terminal %.9g A at 22 kV; internal-zone magnitude threshold screen',observed);
            end
            cts='DOCUMENTARY_VERIFIED:GEN T1/T2 15000/1 phase CT; LG backup dedicated 20/1 neutral CT ENGINEERING_ASSUMPTION';
        case 'F2'
            pd=t87; pf='GSUT-87T'; base=230;
            genHv=bget(B,cs,loc,typ,'GEN')*vf/base;
            terminalHv=bget(B,cs,loc,typ,'GSUT_HV')*vf/base;
            if strcmp(typ,'LG')
                % F1/F2 share B22 in the frozen network. As at F1, load or
                % circulating terminal current is not an incremental LG
                % differential signal. Refer the neutral-earth proxy to the
                % HV comparison base; this is not zero-sequence transfer
                % through the transformer delta or a full 87T calculation.
                observed=neutral*vf/base;
                pnote=sprintf('F2 LG shares the F1 B22 fault node; incremental-earth-fault proxy 3I0 %.9g A x %.0f/230 = %.9g A on HV comparison base; GEN %.9g A and GSUT_HV %.9g A include circulating/load current and do not establish differential detection; delta blocks zero-sequence transfer, so the referred proxy is not actual transferred neutral current', ...
                    neutral,vf,observed,genHv,terminalHv);
            else
                observed=min(genHv,terminalHv);
                pnote=sprintf('GEN LV referred to HV %.9g A, GSUT_HV %.9g A; BOTH raw columns use %.0f kV fault base and are converted by %.0f/230; 0.30 x Siemens-nameplate HV 1292.8 A = 387.84 A; minimum-terminal threshold proxy, not a compensated differential sum', ...
                    genHv,terminalHv,vf,vf);
            end
            cts='CONDITIONAL:GSUT HV 1600/1 and GEN LV 15000/1; both terminal currents referred to HV before screening';
        case 'F3'
            pd=b87; pf='GIS-87B'; base=230;
            a=bget(B,cs,loc,typ,'GSUT_HV'); b=bget(B,cs,loc,typ,'LINE_total');
            observed=max(a,b);
            pnote=sprintf('incident branch magnitude screen GSUT_HV %.9g A and LINE_total %.9g A; GRID is upstream of LINE_total and is not counted again; threshold 0.20 x adopted CT base 1600 A = 320 A',a,b);
            cts='ENGINEERING_ASSUMPTION:87B adopted 1600/1 CT base; installed bus-zone CT allocation not verified';
        case 'F4'
            pd=l87; pf='LINE-7SD'; base=230;
            a=bget(B,cs,loc,typ,'LINE_B1'); b=bget(B,cs,loc,typ,'LINE_B2');
            observed=min(a,b);
            pnote=sprintf('two-ended section magnitude screen LINE_B1 %.9g A, LINE_B2 %.9g A; use faulted B/C for LL/LLG, not the LINE_total cancellation residual; threshold 0.20 x 1600 A = 320 A',a,b);
            cts='ENGINEERING_ASSUMPTION:line differential adopted 1600/1 CT base; channel and installed end-to-end logic not simulated';
            breakerProxy=proxy(pd,'trip_delay_s');
        case 'F5'
            pd=[]; pf='NONE-no-zone-primary-mapped'; base=230; observed=NaN;
            pnote='NO-PAIR/OUT-OF-ZONE:F5 remote fault has no mapped primary pair; no finite primary operating time assigned';
            cts='CONDITIONAL:transformer-bay Q0 backup CT 1600/1';
        otherwise
            error('phase5b_effectiveness:topology','Unsupported fault location %s.',loc);
    end
    if isempty(pd)
        availability='NO-PAIR/OUT-OF-ZONE'; pickup=NaN; operate=Inf; tp=Inf;
        primarySource='NOT-APPLICABLE:no primary relay in study zone'; determinable=false;
    else
        if ~isfinite(observed) || observed<0
            error('phase5b_effectiveness:branch','Required %s current is unavailable.',pf);
        end
        pickup=double(pd.pickup_A);
        operate=proxy(pd,'operate_proxy_s');
        if observed>=pickup
            availability='CONDITIONAL-DETECTABILITY'; tp=operate; determinable=true;
        else
            availability='NO-TRIP'; tp=Inf; determinable=true;
        end
        primarySource=char(pd.provenance);
        pnote=sprintf('%s; current %.9g A versus pickup %.9g A on %.0f kV base; %s; ENGINEERING_STUDY_PROXY operate %.3f s; no manufacturer-operation claim; bias/slopes, vector group, CT saturation and communications not simulated', ...
            pnote,observed,pickup,base,availability,operate);
    end
    % Q0 is the conditional TRANSFORMER-bay device throughout. LINE_B1 is
    % used for the line primary only; it is not the transformer-bay current.
    if strcmp(loc,'F1') && strcmp(typ,'LG')
        bd=ef; bf='GEN-51N-SI-STUDY'; current=neutral; load=0;
        backupNote='dedicated neutral 20/1 CT; 3I0 residual; 4 A pickup; TMS 0.15';
    elseif strcmp(loc,'F1')
        bd=gen; bf='GEN-51-SI'; current=bget(B,cs,loc,typ,'GEN'); load=14309;
        backupNote='GEN 22 kV faulted-phase branch';
    elseif strcmp(loc,'F2')
        bd=hv; bf='GSUT-HV-51'; current=bget(B,cs,loc,typ,'GSUT_HV')*vf/230; load=870.772573866956;
        backupNote='GSUT_HV physical 230 kV branch; raw 22 kV fault-base current converted by 22/230';
    else
        bd=q0; bf='GIS-Q0-51'; current=bget(B,cs,loc,typ,'GSUT_HV')*vf/230; load=870.772573866956;
        backupNote='CONDITIONAL transformer-bay Q0 uses GSUT_HV physical 230 kV branch; not line or remote-source current';
    end
    P=phase5b_pickup(bd,load,max(current,1));
    tb=studytime(current,P);
    reason=sprintf('%s; backup %s, I %.9g A / pickup %.9g A, time %.9g s',pnote,backupNote,current,P.setting,tb);
    if strcmp(typ,'LLG') && isfinite(neutral)
        reason=sprintf('%s; GEN-LLG residual 3I0 %.3f A observed; this row compares phase backup; neutral evaluated separately in matrix',reason,neutral);
    end
    timeBasis='ENGINEERING_STUDY_PROXY:primary operate and breaker fields are separate; backup inverse/DT is calculated from adopted study inputs';
    r={loc,typ,cs,pf,availability,tp,bf,tb,cts, ...
        ['primary:' primarySource ' | backup:' P.source],availability,determinable,reason, ...
        'CONDITIONAL',timeBasis,pickup,observed,operate,breakerProxy,current,P.setting, ...
        supplementary,supplementaryTime,supplementaryBasis};
    rows(end+1,:)=r; %#ok<AGROW>
    if strcmp(loc,'F1')
        % The comparator uses the GENERATOR PHASE branch, including LG;
        % the dedicated neutral backup current must never be reused here.
        comparatorCurrent=bget(B,cs,loc,typ,'GEN');
        Pb=phase5b_pickup(bl,14309,max(comparatorCurrent,1));
        delay=proxy(bl,'trip_delay_s');
        tbb=phase5_time(comparatorCurrent,Pb.setting,delay,'DT');
        twin=r; twin{7}='GEN-51-SIEMENS-BL'; twin{8}=tbb;
        twin{10}=['primary:' primarySource ' | backup:CONDITIONAL ENGINEERING_STUDY_PROXY DT comparator; ' Pb.source];
        twin{13}=sprintf('%s; conditional sensitivity comparator %.9g A versus %.9g A, DT %.3f s, resulting time %.9g s; actual installed characteristic not verified',pnote,comparatorCurrent,Pb.setting,delay,tbb);
        twin{14}='SENSITIVITY'; twin{20}=comparatorCurrent; twin{21}=Pb.setting;
        rows(end+1,:)=twin; %#ok<AGROW>
    end
end
E=cell2table(rows,'VariableNames',{'fault_location','fault_type','caseID','primary_function', ...
    'primary_availability','primary_time_s','backup_function','backup_time_s','ct_source','setting_source', ...
    'detection','determinable','not_determinable','scope','time_basis','primary_pickup_A','primary_current_A', ...
    'primary_operate_proxy_s','primary_breaker_proxy_s','backup_current_A','backup_pickup_A', ...
    'supplementary_function','supplementary_time_s','supplementary_basis'});
end
function I=bget(B,cs,loc,typ,leg)
hit=strcmp(B.caseID,cs)&strcmp(B.location,loc)&strcmp(B.fault_type,typ)&strcmp(B.leg,leg);
if sum(hit)~=1
    error('phase5b_effectiveness:branch','Expected one %s branch for %s %s %s.',leg,cs,loc,typ);
end
I=double(B.Ibranch_faulted_A(hit));
if ~isscalar(I) || ~isfinite(I) || I<0
    error('phase5b_effectiveness:branch','Invalid required %s branch current.',leg);
end
end
function d=reqdev(devices,id)
hit=strcmp({devices.device_id},id);
if sum(hit)~=1, error('phase5b_effectiveness:devices','Expected one %s device.',id); end
d=devices(hit);
end
function t=proxy(d,field)
if ~isfield(d,field) || ~isscalar(d.(field)) || ~isfinite(d.(field)) || d.(field)<0
    error('phase5b_effectiveness:proxy','%s requires finite nonnegative %s.',d.device_id,field);
end
t=double(d.(field));
end
function t=studytime(I,P)
if ~isfinite(I) || I<0
    error('phase5b_effectiveness:current','Required backup current must be finite and nonnegative.');
end
if ~P.use_phase5_time
    error('phase5b_effectiveness:time','Active backup must have an executable adopted study characteristic.');
end
t=phase5_time(I,P.setting,P.tms,P.curve);
end
