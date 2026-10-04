function S = build_dynamic_protection_sim(varargin)
%BUILD_DYNAMIC_PROTECTION_SIM  Stage the closed-loop trip model + parameters.
%   S = BUILD_DYNAMIC_PROTECTION_SIM() or (outDir) or (outDir, root).
%
%   Copies the frozen base model
%       Phase6/model/PHASE6_ASHUGANJ_CCPP_DYNAMIC_MODEL.slx
%   to
%       Phase6/PHASE6_ASHUGANJ_CCPP_CLOSED_LOOP_TRIP.slx
%   (skips gracefully with an honest flag if the base model is missing, and
%   still produces the parameter CSV + JSON meta), writes
%   closed_loop_trip_params.csv + closed_loop_trip_meta.json into outDir,
%   and attempts a programmatic relay/breaker-hook insertion
%   (DFT/True-RMS @50 Hz front end, IEC SI integrator int(dt/t_op) >= 1 to
%   TRIP, ZOH driving breaker external control) via add_block/add_line
%   inside try/catch, recording inserted/not-inserted status honestly.
%
%   Protection settings (Task-8 study, same-side primary A throughout):
%     6.6 kV feeder OC: Iload = 14 MW @ 0.85 pf / 6.6 kV (~1441 A RMS),
%       pickup 1.20x (~1729 A), TMS 0.10, IEC SI.
%     22 kV GEN-51-SI backup: pickup 17170.8 A (frozen GEN-51 derivation),
%       TMS 0.20 (Task-8 backup sensitivity; frozen GEN-51 TMS is 0.10),
%       IEC SI. Fault branch 55048.71 A = F1 LLL GEN-51 physical-CT branch
%       from Phase6/data/phase5_reference/phase5_relay_currents.csv;
%       system reference F1 LLL Ikpp 126.21 kA from
%       results/phase4_fault/production/phase4_fault_currents.csv.
%     87G/50 instantaneous proxy: definite 0.040 s (Task-8 study value;
%       frozen 87G operate proxy is 0.045 s).
%   Operating times are computed with PHASE5_TIME (never re-derived).
%
%   All errors are 'build_dynamic_protection_sim'-prefixed.
if nargin == 0
    root = ashuganj_root();
    outDir = fullfile(root, 'results', 'phase6');
elseif nargin == 1
    outDir = varargin{1};
    root = ashuganj_root();
elseif nargin == 2
    outDir = varargin{1};
    root = varargin{2};
else
    error('build_dynamic_protection_sim:args', ...
        'usage: S = build_dynamic_protection_sim() or (outDir) or (outDir, root).');
end
if isstring(outDir) && isscalar(outDir), outDir = char(outDir); end
if isstring(root) && isscalar(root), root = char(root); end
if ~ischar(outDir) || isempty(strtrim(outDir))
    error('build_dynamic_protection_sim:args', 'outDir must be a non-empty path (char).');
end
if ~ischar(root) || isempty(strtrim(root))
    error('build_dynamic_protection_sim:args', 'root must be a non-empty project-root path (char).');
end
if exist(root, 'dir') ~= 7
    error('build_dynamic_protection_sim:root', 'project root not found: %s', root);
end
if exist(outDir, 'dir') ~= 7
    [okMk, msgMk] = mkdir(outDir);
    if ~okMk
        error('build_dynamic_protection_sim:mkdir', 'cannot create outDir %s (%s).', outDir, msgMk);
    end
end

f_Hz   = 50;
dt_s   = 50e-6;
fault_at_s = 0.50;

% 6.6 kV feeder load from first principles: 14 MW @ 0.85 pf, 6.6 kV LL.
Iload_66_A  = 14e6 / (sqrt(3) * 6600 * 0.85);
Ipick_66_A  = 1.20 * Iload_66_A;
TMS_66      = 0.10;
Ifault_66_A = 15000;  % Task-8 study feeder fault level (ENGINEERING_ASSUMPTION).
t_op_66_s   = phase5_time(Ifault_66_A, Ipick_66_A, TMS_66, 'SI');

% 22 kV GEN-51-SI backup (Task-8 TMS 0.20 sensitivity on frozen pickup).
Ipick_22_A  = 17170.8;
TMS_22      = 0.20;
Ifault_22_A = 55048.7096805279;  % F1 LLL GEN-51 physical-CT branch (phase5_relay_currents.csv).
t_op_22_s   = phase5_time(Ifault_22_A, Ipick_22_A, TMS_22, 'SI');

% Instantaneous element: definite-time proxy for the generator zone.
t_inst_s = 0.040;

devices  = {'FEEDER-6.6kV-51'; 'GEN-51-SI-BACKUP'; 'GEN-87G-50-INST'};
voltage  = [6.6; 22; 22];
Iload    = [Iload_66_A; 12019.0; 12019.0];
Ipick    = [Ipick_66_A; Ipick_22_A; 2403.8];
TMS      = [TMS_66; TMS_22; NaN];
curve    = {'SI'; 'SI'; 'DT-INST'};
Ifault   = [Ifault_66_A; Ifault_22_A; NaN];
t_op     = [t_op_66_s; t_op_22_s; t_inst_s];
prov = { ...
    'Task-8 study: 14MW@0.85/6.6kV load, 1.20x pickup, TMS 0.10 SI; fault 15kA study level'; ...
    'Pickup 17170.8A frozen GEN-51 derivation; TMS 0.20 Task-8 backup (frozen TMS 0.10); branch 55048.71A F1-LLL GEN-51 phase5_relay_currents.csv; system F1 LLL 126.21kA phase4_fault_currents.csv'; ...
    'Task-8 definite 0.040s generator-zone instant proxy (frozen 87G operate proxy 0.045s); threshold 2403.8A frozen 87G pickup'};

T = table(devices, voltage, Iload, Ipick, TMS, curve, Ifault, t_op, prov, ...
    'VariableNames', {'device', 'voltage_kV', 'Iload_A', 'pickup_A', ...
    'TMS', 'curve', 'I_fault_A', 't_op_s', 'provenance'});
params_csv = fullfile(outDir, 'closed_loop_trip_params.csv');
writetable(T, params_csv);

S = struct('out_dir', outDir, 'params_csv', params_csv, ...
    'f_Hz', f_Hz, 'dt_s', dt_s, 'fault_at_s', fault_at_s, ...
    'Iload_66_A', Iload_66_A, 'Ipick_66_A', Ipick_66_A, ...
    'TMS_66', TMS_66, 'Ifault_66_A', Ifault_66_A, 't_op_66_s', t_op_66_s, ...
    'Ipick_22_A', Ipick_22_A, 'TMS_22', TMS_22, ...
    'Ifault_22_A', Ifault_22_A, 't_op_22_s', t_op_22_s, ...
    't_inst_s', t_inst_s, 'pickup_87G_A', 2403.8, ...
    'model_copied', false, 'model_src', '', 'model_dst', '', ...
    'model_note', '', 'insertion_status', 'not-inserted: no model target attempted');

% Model copy: base .slx -> closed-loop .slx (graceful skip if missing).
S.model_src = fullfile(root, 'Phase6', 'model', 'PHASE6_ASHUGANJ_CCPP_DYNAMIC_MODEL.slx');
S.model_dst = fullfile(root, 'Phase6', 'PHASE6_ASHUGANJ_CCPP_CLOSED_LOOP_TRIP.slx');
if exist(S.model_src, 'file') == 2
    try
        copyfile(S.model_src, S.model_dst);
        S.model_copied = true;
        S.model_note = 'base model copied to closed-loop target.';
    catch ME
        S.model_copied = false;
        S.model_note = ['copy failed: ' ME.identifier ' ' ME.message];
    end
else
    S.model_copied = false;
    S.model_note = ['base model missing, skipped gracefully: ' S.model_src];
end

% Programmatic relay/breaker-hook insertion attempt (honest status).
if S.model_copied
    [~, mdlName] = fileparts(S.model_dst);
    try
        load_system(S.model_dst);
        hookPath = [mdlName '/CL_TripRelayHook'];
        already = find_system(mdlName, 'SearchDepth', 1, 'Name', 'CL_TripRelayHook');
        if ~isempty(already)
            S.insertion_status = 'inserted: hook block already present from a prior run.';
        else
            % Placeholder hook subsystem documenting the intended wiring:
            % DFT/True-RMS @50 Hz -> IEC SI integrator int(dt/t_op)>=1 ->
            % TRIP latch -> ZOH -> breaker external control.
            add_block('built-in/SubSystem', hookPath, ...
                'Description', ['Task-8 closed-loop trip hook. Intended wiring: ' ...
                'DFT/True-RMS measurement @50Hz; IEC SI integrator int(dt/t_op)>=1 to TRIP; ' ...
                'ZOH to breaker external control. Placeholder, unconnected; full SPS port ' ...
                'mapping pending.']);
            try
                add_block('built-in/Constant', [hookPath '/inv_top'], 'Value', '1');
                add_block('built-in/Gain', [hookPath '/SI_integrator'], 'Gain', '1');
                add_block('built-in/Terminator', [hookPath '/TRIP_out']);
                add_line(hookPath, 'inv_top/1', 'SI_integrator/1', 'autorouting', 'on');
                add_line(hookPath, 'SI_integrator/1', 'TRIP_out/1', 'autorouting', 'on');
                S.insertion_status = ['inserted: hook subsystem placed via add_block/add_line ' ...
                    'with inv_top->SI_integrator->TRIP_out skeleton ' ...
                    '(placeholder, unconnected at top level; SPS port mapping pending).'];
            catch MEin
                S.insertion_status = ['inserted: hook subsystem placed via add_block ' ...
                    '(placeholder; skeleton wiring incomplete: ' MEin.identifier ').'];
            end
        end
        save_system(mdlName);
        close_system(mdlName);
    catch ME
        try close_system(mdlName, 0); catch, end
        S.insertion_status = ['not-inserted: ' ME.identifier ' ' firstline(ME.message)];
    end
else
    S.insertion_status = ['not-inserted: ' S.model_note];
end

meta = struct('params_csv', params_csv, ...
    'model_src', S.model_src, 'model_dst', S.model_dst, ...
    'model_copied', S.model_copied, 'model_note', S.model_note, ...
    'insertion_status', S.insertion_status, ...
    't_op_66_s', t_op_66_s, 't_op_22_s', t_op_22_s, 't_inst_s', t_inst_s, ...
    'Iload_66_A', Iload_66_A, 'Ipick_66_A', Ipick_66_A, ...
    'assumptions', {{ ...
        'Analytical IEC SI times via phase5_time (same-side primary A).'; ...
        '6.6kV feeder fault 15 kA is a Task-8 study level, not a frozen fault-study value.'; ...
        'GEN backup TMS 0.20 is a Task-8 sensitivity (frozen GEN-51 TMS 0.10).'; ...
        'Instant 0.040 s is a Task-8 proxy (frozen 87G operate proxy 0.045 s).'; ...
        'Hook insertion is a placeholder subsystem; closed-loop evidence is analytical synthesis.'}});
meta_json = fullfile(outDir, 'closed_loop_trip_meta.json');
fid = fopen(meta_json, 'w');
if fid < 0
    error('build_dynamic_protection_sim:write', 'cannot write %s.', meta_json);
end
fprintf(fid, '%s', jsonencode(meta, 'PrettyPrint', true));
fclose(fid);
S.meta_json = meta_json;
end

function s = firstline(m)
m = char(m);
nl = find(m == newline, 1);
if ~isempty(nl), m = m(1:min(nl - 1, 160)); end
if numel(m) > 160, m = m(1:160); end
s = strtrim(m);
end
