function run_full_project(varargin)
%RUN_FULL_PROJECT One-command entry point (Rev2).
% Usage:
%   run_full_project            % Phase1 only (default, bounded phase)
%   run_full_project('Phase1')  % re-baseline + loadflow
%   run_full_project('Phase2')  % fault engine (next session)
%   run_full_project('All')     % full chain when Phases 2-4 land
% Keeps matlab/* intact; operates on rev2/* only.
here = fileparts(mfilename('fullpath'));
addpath(here); addpath(fullfile(here,'data')); addpath(fullfile(here,'tests'));
if nargin>=1, phase=varargin{1}; else, phase='Phase1'; end
fprintf('=== Ashuganj South Rev2 %s (%s) ===\n',phase,'2026-09-10');
test_rev2_registry();
if strcmpi(phase,'Phase1')||strcmpi(phase,'All')
  R = run_phase1_loadflow('Write',true);
  % plots
  try
    outP=fullfile(here,'plots'); if ~isfolder(outP), mkdir(outP); end
    ids={R.sol.ID}; V2=arrayfun(@(s)s.V(2),R.sol); V4=arrayfun(@(s)s.V(4),R.sol);
    figure('Visible','off'); bar([V2;V4]'); grid on;
    set(gca,'XTickLabel',ids); ylabel('Voltage pu (C-values labelled)'); title('Rev2 Phase1 bus voltages B02/B03... B02 & B11');
    legend('B02 230kV GIS','B11 6.6kV aux'); saveas(gcf,fullfile(outP,'phase1_bus_voltage.png')); close(gcf);
    Pexp=arrayfun(@(s)s.Pexport_MW,R.sol);
    figure('Visible','off'); bar(categorical(ids),Pexp); grid on; ylabel('MW'); title('Net export per case (342MW target ± losses)');
    saveas(gcf,fullfile(outP,'phase1_export.png')); close(gcf);
    fprintf('Plots written to rev2/plots/\n');
  catch ME
    fprintf('Plot warning (non-fatal): %s\n',ME.message);
  end
  % acceptance
  ok=true;
  for k=1:numel(R.sol)
    if ~R.sol(k).converged, ok=false; fprintf('FAIL %s not converged\n',R.sol(k).ID); end
    if abs(R.sol(k).Pbal_pu)>1e-6, ok=false; fprintf('FAIL %s pbal %.2e\n',R.sol(k).ID,abs(R.sol(k).Pbal_pu)); end
  end
  if ok, fprintf('Phase1 acceptance: CONVERGED + PBAL OK (see CSVs)\n');
  else, fprintf('Phase1 acceptance: CHECK FAILS — see above\n'); end
end
if strcmpi(phase,'Phase2')||strcmpi(phase,'All')
  test_phase2_fault(); test_phase2_kcl();
  R2 = run_phase2_fault('Write',true);
  try
    outP=fullfile(here,'plots'); if ~isfolder(outP), mkdir(outP); end
    ids={R2.res.CaseID}; sym=[R2.res.Isym_kA]; pk=[R2.res.Ipeak_kA];
    figure('Visible','off'); bar(categorical(ids),[sym;pk]'); grid on;
    ylabel('kA'); title('Rev2 Phase2 fault currents: Isym (blue) vs Ipeak IEC60909 (red)');
    legend('Isym','Ipeak'); saveas(gcf,fullfile(outP,'phase2_fault_currents.png')); close(gcf);
    bn={R2.duty.breaker}; bi=[R2.duty.I_kA];
    figure('Visible','off'); bar(categorical(bn),bi); grid on; hold on;
    yline(50,'r--','50kA withstand'); ylabel('kA');
    title('Rev2 Phase2 breaker duty vs 50kA GIS withstand (interrupting assumed 50kA-C)');
    saveas(gcf,fullfile(outP,'phase2_breaker_duty.png')); close(gcf);
    figure('Visible','off');
    sLLL=R2.sens(strcmp({R2.sens.type},'LLL')); sLG=R2.sens(strcmp({R2.sens.type},'LG'));
    plot([sLLL.grid_k],[sLLL.Isym_kA],'o-'); hold on; grid on;
    plot([sLG.grid_k],[sLG.Isym_kA],'s-');
    xlabel('grid_k (Zth scale)'); ylabel('kA @B02');
    title('Sens: LLL/LG @B02 vs grid strength (Xdpp sat+unsat, line 0.8-1.2)');
    legend('LLL','LG'); saveas(gcf,fullfile(outP,'phase2_sens.png')); close(gcf);
    fprintf('Plots written to rev2/plots/\n');
  catch ME
    fprintf('Plot warning (non-fatal): %s\n',ME.message);
  end
  ok2=true;
  for f={'phase2_fault_currents.csv','phase2_sequence_Z.csv','phase2_breaker_duty.csv'}
    if ~exist(fullfile(here,'results',f{1}),'file'), ok2=false; fprintf('FAIL missing %s\n',f{1}); end
  end
  % symmetry spot-check on engine output
  r5=R2.res(5); r6=R2.res(6);
  if abs(r6.I1-r6.I2)/abs(r6.I1)>1e-6||abs(r6.I1-r6.I0)/abs(r6.I1)>1e-6, ok2=false; fprintf('FAIL LG symmetry\n'); end
  if abs(r5.I2)>1e-9||abs(r5.I0)>1e-9, ok2=false; fprintf('FAIL LLL symmetry\n'); end
  if ok2, fprintf('Phase2 acceptance: CSVs + SYMMETRY OK (see CSVs)\n');
  else, fprintf('Phase2 acceptance: CHECK FAILS — see above\n'); end
  fprintf('Simulink cross-check: run run_loadflow_v2_tests (rev2/simulink) separately (~20min).\n');
end
if strcmpi(phase,'Phase3')||strcmpi(phase,'All')
  test_phase3_protection();
  R3 = run_phase3_protection('Write',true);
  try
    outP=fullfile(here,'plots'); if ~isfolder(outP), mkdir(outP); end
    figure('Visible','off');
    for k=1:numel(R3.relays)
      r=R3.relays(k);
      Imax=r.maxFault_A*1.5; Imin=r.pickup_A*1.05;
      I=logspace(log10(Imin),log10(Imax),200);
      t=arrayfun(@(x) iec_si(r.TMS,x/r.pickup_A),I);
      loglog(I/1e3,t,'DisplayName',r.zone); hold on; grid on;
    end
    xlabel('Current kA'); ylabel('Time s (IEC-SI)');
    title('Rev2 Phase3 TCC: OC relays (pickup 1.2xFL-C, graded 0.3s-C)');
    legend('show','Location','southwest'); ylim([0.05 10]);
    saveas(gcf,fullfile(outP,'phase3_tcc.png')); close(gcf);
    fprintf('Plots written to rev2/plots/\n');
  catch ME
    fprintf('Plot warning (non-fatal): %s\n',ME.message);
  end
  ok3=true;
  for f={'phase3_settings.csv','phase3_coordination.csv'}
    if ~exist(fullfile(here,'results',f{1}),'file'), ok3=false; fprintf('FAIL missing %s\n',f{1}); end
  end
  for k=1:numel(R3.coord)
    if strcmp(R3.coord(k).verdict,'PASS'), continue; end
    if R3.coord(k).margin_s<0.3-1e-9, ok3=false; fprintf('FAIL pair %d margin %.3f\n',k,R3.coord(k).margin_s); end
  end
  for k=1:numel(R3.relays)
    if R3.relays(k).TMS>1.0, ok3=false; fprintf('FAIL %s TMS %.3f\n',R3.relays(k).zone,R3.relays(k).TMS); end
  end
  if ok3, fprintf('Phase3 acceptance: CSVs + GRADING + TMS-CAP OK\n');
  else, fprintf('Phase3 acceptance: CHECK FAILS — see above\n'); end
end
fprintf('Done. Update PROGRESS.md with exact CSV numbers before context reset.\n');
end
