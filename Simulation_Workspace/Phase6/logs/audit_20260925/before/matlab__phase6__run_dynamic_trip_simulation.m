function R = run_dynamic_trip_simulation(varargin)
%RUN_DYNAMIC_TRIP_SIMULATION  Closed-loop dynamic relay-trip evidence.
%   R = RUN_DYNAMIC_TRIP_SIMULATION() or (outDir) or (outDir, root).
%
%   Fault applied at t = 0.50 s with the breaker pre-fault closed.
%   Analytical IEC operating times come from PHASE5_TIME on same-side
%   primary A (never re-derived). Four traces are synthesized at a 50 us
%   step: three-phase current (truncated within 2 cycles of trip),
%   IEC SI integrator 0 -> 1, breaker 1 -> 0, voltage sag restored to
%   1 pu. A sim() run on the closed-loop model is attempted inside
%   try/catch (short probe StopTime); the reported traces are labelled
%   sim vs analytical honestly. Writes
%   results/phase6/dynamic_trip_times.csv and
%   results/phase6/dynamic_relay_trip_validation.png (4 subplots,
%   1400x850, titles/footers carrying the assumption notes).
%
%   The plotted breaker is driven by the 6.6 kV feeder SI loop. The 22 kV
%   GEN backup time is the would-be operating time if the fault persisted
%   (pre-empted by the primary in the closed loop). The 87G/50 instant is
%   a generator-zone definite element reported for reference.
%
%   All errors are 'run_dynamic_trip_simulation'-prefixed.
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
    error('run_dynamic_trip_simulation:args', ...
        'usage: R = run_dynamic_trip_simulation() or (outDir) or (outDir, root).');
end
if isstring(outDir) && isscalar(outDir), outDir = char(outDir); end
if isstring(root) && isscalar(root), root = char(root); end
if ~ischar(outDir) || isempty(strtrim(outDir))
    error('run_dynamic_trip_simulation:args', 'outDir must be a non-empty path (char).');
end
if ~ischar(root) || isempty(strtrim(root))
    error('run_dynamic_trip_simulation:args', 'root must be a non-empty project-root path (char).');
end
if exist(root, 'dir') ~= 7
    error('run_dynamic_trip_simulation:root', 'project root not found: %s', root);
end
if exist(outDir, 'dir') ~= 7
    [okMk, msgMk] = mkdir(outDir);
    if ~okMk
        error('run_dynamic_trip_simulation:mkdir', 'cannot create outDir %s (%s).', outDir, msgMk);
    end
end

% Ensure staged parameters exist (same constants as the build function).
params_csv = fullfile(outDir, 'closed_loop_trip_params.csv');
if exist(params_csv, 'file') ~= 2
    build_dynamic_protection_sim(outDir, root);
end

f_Hz       = 50;
dt         = 50e-6;
fault_at_s = 0.50;

Iload_66_A  = 14e6 / (sqrt(3) * 6600 * 0.85);
Ipick_66_A  = 1.20 * Iload_66_A;
TMS_66      = 0.10;
Ifault_66_A = 15000;
t_op_66_s   = phase5_time(Ifault_66_A, Ipick_66_A, TMS_66, 'SI');

Ipick_22_A  = 17170.8;
TMS_22      = 0.20;
Ifault_22_A = 55048.7096805279;
t_op_22_s   = phase5_time(Ifault_22_A, Ipick_22_A, TMS_22, 'SI');

t_inst_s = 0.040;

t_trip_66  = fault_at_s + t_op_66_s;   % breaker driver (feeder loop)
t_trip_22  = fault_at_s + t_op_22_s;   % would-be backup time (fault pre-empted)
t_trip_ins = fault_at_s + t_inst_s;    % reference instant (other zone)

% Synthesis window: fault plus primary trip plus 0.30 s post-trip view.
t_end = t_trip_66 + 0.30;
t = (0:dt:t_end).';
n = numel(t);

w = 2 * pi * f_Hz;
pk_load  = Iload_66_A * sqrt(2);
pk_fault = Ifault_66_A * sqrt(2);
isFlt = t >= fault_at_s;
isOpen = t >= t_trip_66;
amp = pk_load * ones(n, 1);
amp(isFlt & ~isOpen) = pk_fault;
amp(isOpen) = 0;  % ideal truncation at trip (within 1 sample << 2 cycles)
ia = amp .* sin(w * t);
ib = amp .* sin(w * t - 2 * pi / 3);
ic = amp .* sin(w * t + 2 * pi / 3);

integ = zeros(n, 1);
during = isFlt & ~isOpen;
integ(during) = (t(during) - fault_at_s) / t_op_66_s;
integ(isOpen) = 1.0;
integ = min(max(integ, 0), 1);

cb = ones(n, 1);       % 1 = closed, 0 = open
cb(isOpen) = 0;

v_pu = ones(n, 1);     % 1 pu pre-fault
v_pu(isFlt & ~isOpen) = 0.25;
v_pu(isOpen) = 1.0;    % restoration after breaker opening

% sim() probe on the closed-loop model: short StopTime, honest label.
sim_mode = 'analytical-synthesis';
sim_note = 'reported traces are analytical synthesis at 50 us (no full-model transient run).';
model_dst = fullfile(root, 'Phase6', 'PHASE6_ASHUGANJ_CCPP_CLOSED_LOOP_TRIP.slx');
if exist(model_dst, 'file') == 2
    try
        if isempty(ver('simulink'))
            error('run_dynamic_trip_simulation:noSimulink', 'Simulink toolbox not installed.');
        end
        [~, mdlName] = fileparts(model_dst);
        load_system(model_dst);
        set_param(mdlName, 'StopTime', '0.02');
        sim(mdlName);
        sim_mode = 'analytical-synthesis (sim probe: 0.02 s compile+run OK)';
        sim_note = ['0.02 s sim probe of closed-loop model compiled and ran; ' ...
            'reported trip traces remain analytical synthesis at 50 us.'];
        close_system(mdlName, 0);
    catch ME
        try, [~, mn] = fileparts(model_dst); close_system(mn, 0); catch, end
        sim_mode = 'analytical-synthesis';
        sim_note = ['analytical synthesis at 50 us; sim probe did not run: ' ...
            ME.identifier ' ' firstline(ME.message)];
    end
else
    sim_note = 'analytical synthesis at 50 us; closed-loop model file absent, no sim attempted.';
end

device = {'FEEDER-6.6kV-51-SI'; 'GEN-51-SI-BACKUP'; 'GEN-87G-50-INST'};
element = {'IEC-SI-primary'; 'IEC-SI-backup'; 'definite-instant'};
I_A = [Ifault_66_A; Ifault_22_A; NaN];
Is_A = [Ipick_66_A; Ipick_22_A; 2403.8];
TMScol = [TMS_66; TMS_22; NaN];
curvec = {'SI'; 'SI'; 'DT'};
t_op_s = [t_op_66_s; t_op_22_s; t_inst_s];
t_abs_s = [t_trip_66; t_trip_22; t_trip_ins];
mode = {sim_mode; sim_mode; sim_mode};
notes = { ...
    'drives plotted breaker; truncation at trip'; ...
    'would-be time if fault persisted; pre-empted by primary'; ...
    'generator-zone reference element; 0.040 s Task-8 proxy (frozen 87G proxy 0.045 s)'};
TT = table(device, element, I_A, Is_A, TMScol, curvec, t_op_s, t_abs_s, mode, notes, ...
    'VariableNames', {'device', 'element', 'I_A', 'Is_A', 'TMS', 'curve', ...
    't_op_s', 't_abs_s', 'mode', 'notes'});
times_csv = fullfile(outDir, 'dynamic_trip_times.csv');
writetable(TT, times_csv);

png = fullfile(outDir, 'dynamic_relay_trip_validation.png');
draw_validation(t, ia, ib, ic, integ, cb, v_pu, fault_at_s, t_trip_66, ...
    t_op_66_s, t_op_22_s, t_inst_s, sim_mode, png);

postIdx = t >= t_trip_66 + 2 / f_Hz;  % beyond 2 cycles after trip
R = struct('out_dir', outDir, 'times_csv', times_csv, 'png', png, ...
    't_op_66_s', t_op_66_s, 't_op_22_s', t_op_22_s, 't_inst_s', t_inst_s, ...
    't_trip_66_s', t_trip_66, 't_trip_22_s', t_trip_22, ...
    'fault_at_s', fault_at_s, 'dt_s', dt, ...
    'Ifault_66_A', Ifault_66_A, 'Ipick_66_A', Ipick_66_A, 'TMS_66', TMS_66, ...
    'Ifault_22_A', Ifault_22_A, 'Ipick_22_A', Ipick_22_A, 'TMS_22', TMS_22, ...
    'sim_mode', sim_mode, 'sim_note', sim_note, ...
    'integrator_max', max(integ), ...
    'i_post_max_A', max(abs([ia(postIdx); ib(postIdx); ic(postIdx)])), ...
    'i_fault_peak_A', pk_fault, ...
    'v_post_min_pu', min(v_pu(isOpen)));
end

function draw_validation(t, ia, ib, ic, integ, cb, v_pu, fault_at, t_trip, ...
    t_op_66, t_op_22, t_inst, sim_mode, pngPath)
fig = figure('Visible', 'off', 'Color', 'white', 'Position', [50 50 1400 850]);
tms = t * 1000;
fx = fault_at * 1000;
tx = t_trip * 1000;

subplot(4, 1, 1); hold on;
plot(tms, ia / 1000, 'Color', [0 0.4470 0.7410], 'LineWidth', 1.1);
plot(tms, ib / 1000, 'Color', [0.8500 0.3250 0.0980], 'LineWidth', 1.1);
plot(tms, ic / 1000, 'Color', [0.4660 0.6740 0.1880], 'LineWidth', 1.1);
xline(fx, '--k', 'LineWidth', 1.0);
xline(tx, '-r', 'LineWidth', 1.2);
ylabel('kA');
title(sprintf('Feeder 6.6 kV phase currents (fault 0.50 s, SI trip %.3f s -> %.3f s)', t_op_66, t_trip), ...
    'Interpreter', 'none');
legend({'ia', 'ib', 'ic', 'fault on', 'TRIP (breaker opens)'}, 'Location', 'northeast', ...
    'Interpreter', 'none', 'FontSize', 7);
grid on;

subplot(4, 1, 2); hold on;
plot(tms, integ, 'Color', [0 0.4470 0.7410], 'LineWidth', 1.4);
xline(fx, '--k', 'LineWidth', 1.0);
xline(tx, '-r', 'LineWidth', 1.2);
yline(1.0, ':k', 'LineWidth', 1.0);
ylim([-0.05 1.15]);
ylabel('duty');
title('IEC SI integrator int(dt/t_{op}) 0 -> 1 (TRIP at 1.0)', 'Interpreter', 'none');
grid on;

subplot(4, 1, 3); hold on;
plot(tms, cb, 'Color', [0.8500 0.3250 0.0980], 'LineWidth', 1.4);
xline(fx, '--k', 'LineWidth', 1.0);
xline(tx, '-r', 'LineWidth', 1.2);
ylim([-0.1 1.1]);
ylabel('1 shut / 0 open');
title('Breaker state 1 -> 0 at feeder SI trip (pre-fault closed)', 'Interpreter', 'none');
grid on;

subplot(4, 1, 4); hold on;
plot(tms, v_pu, 'Color', [0.4660 0.6740 0.1880], 'LineWidth', 1.4);
xline(fx, '--k', 'LineWidth', 1.0);
xline(tx, '-r', 'LineWidth', 1.2);
yline(0.95, ':k', 'LineWidth', 1.0);
ylim([0 1.15]);
ylabel('pu');
xlabel('Time, ms');
title('Bus voltage: sag 0.25 pu during fault, restored to 1 pu after trip', 'Interpreter', 'none');
grid on;

sgtitle({['Phase-6 closed-loop dynamic relay trip | ' sim_mode], ...
    sprintf(['feeder SI %.3f s | GEN backup %.3f s (would-be) | instant %.3f s | ' ...
    'F1 LLL ref 126.21 kA | 50 us step'], t_op_66, t_op_22, t_inst)}, ...
    'Interpreter', 'none', 'FontSize', 10);
annotation('textbox', [0.01 0.005 0.98 0.035], 'String', ...
    {['Assumptions: analytical synthesis (no CT saturation/DC offset); feeder fault 15 kA study level; ' ...
    'GEN backup TMS 0.20 Task-8 (frozen 0.10); instant 0.040 s proxy (frozen 87G 0.045 s); ' ...
    'GEN branch 55.05 kA F1-LLL phase5_relay_currents.csv; system F1 LLL 126.21 kA phase4 CSV.']}, ...
    'EdgeColor', 'none', 'FontSize', 7, 'Interpreter', 'none', ...
    'HorizontalAlignment', 'center');
print(fig, pngPath, '-dpng');
close(fig);
if exist(pngPath, 'file') ~= 2
    error('run_dynamic_trip_simulation:write', 'validation PNG not written: %s', pngPath);
end
end

function s = firstline(m)
m = char(m);
nl = find(m == newline, 1);
if ~isempty(nl), m = m(1:min(nl - 1, 160)); end
if numel(m) > 160, m = m(1:160); end
s = strtrim(m);
end
