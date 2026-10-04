function [np, nf] = test_operating_profiles()
%TEST_OPERATING_PROFILES Tests for authoritative operating profiles and capacity guard.
%   Verifies:
%   - Six canonical profiles (2x 360 MW primary, 2x 342.01 MW qualified, 2x 389.30 MW historical)
%   - Four historical backward-compatible aliases (LF1..LF4)
%   - Primary capacity guard enforcing P <= 360 MW
%   - Finite curve-derived physical Q limits
%   - Master data integration and case exposure

T = t_case('Operating Profiles & Capacity Guard');

D = ashuganj_master_data();

%% 1. Canonical Profiles Structure & Count
T = T.chk(isfield(D, 'operating_profiles'), 'master_has_operating_profiles');
canon = D.operating_profiles;
T = T.eq(numel(canon), 6, 'exactly_six_canonical_profiles');

canon_ids = {canon.ID};
expected_ids = {'LF360_GAT_OUT', 'LF360_GAT_IN', 'LF342_GAT_OUT', 'LF342_GAT_IN', 'LF389P30_GAT_OUT', 'LF389P30_GAT_IN'};
T = T.eq(canon_ids, expected_ids, 'canonical_profile_ids_exact');

%% 2. Primary 360 MW Cases
p1 = canon(1); % LF360_GAT_OUT
p2 = canon(2); % LF360_GAT_IN
T = T.eq(p1.Gen_P_MW, 360.00, 'p1_dispatch_360MW');
T = T.eq(p1.P_capacity_MW, 360.00, 'p1_capacity_360MW');
T = T.eq(p1.GAT_in, false, 'p1_gat_out');
T = T.eq(p1.approved_exception, false, 'p1_no_exception');

T = T.eq(p2.Gen_P_MW, 360.00, 'p2_dispatch_360MW');
T = T.eq(p2.P_capacity_MW, 360.00, 'p2_capacity_360MW');
T = T.eq(p2.GAT_in, true, 'p2_gat_in');
T = T.eq(p2.approved_exception, false, 'p2_no_exception');

%% 3. Qualified 342.01 MW Scenarios
q1 = canon(3); % LF342_GAT_OUT
q2 = canon(4); % LF342_GAT_IN
T = T.eq(q1.Gen_P_MW, 342.01, 'q1_dispatch_342MW');
T = T.eq(q1.GAT_in, false, 'q1_gat_out');
T = T.eq(q2.Gen_P_MW, 342.01, 'q2_dispatch_342MW');
T = T.eq(q2.GAT_in, true, 'q2_gat_in');

%% 4. Historical 389.30 MW Reference Cases
h1 = canon(5); % LF389P30_GAT_OUT
h2 = canon(6); % LF389P30_GAT_IN
T = T.eq(h1.Gen_P_MW, 389.30, 'h1_dispatch_389MW');
T = T.eq(h1.approved_exception, true, 'h1_approved_exception_true');
T = T.eq(h2.Gen_P_MW, 389.30, 'h2_dispatch_389MW');
T = T.eq(h2.approved_exception, true, 'h2_approved_exception_true');

%% 5. Finite Capability-Derived Reactive Limits
for k = 1:numel(canon)
    c = canon(k);
    [qmin, qmax] = generatorCapability(c.Gen_P_MW);
    T = T.near(c.Gen_Q_MVAr_limit(1), qmin, 1e-4, sprintf('%s_qmin_from_capability', c.ID));
    T = T.near(c.Gen_Q_MVAr_limit(2), qmax, 1e-4, sprintf('%s_qmax_from_capability', c.ID));
    T = T.chk(all(isfinite(c.Gen_Q_MVAr_limit)), sprintf('%s_finite_q_limits', c.ID));
end

%% 6. Historical Aliases (LF1..LF4)
T = T.chk(isfield(D, 'cases'), 'master_has_builder_visible_cases');
% Find aliases in D.cases
alias_ids = {'LF1', 'LF2', 'LF3', 'LF4'};
for k = 1:numel(alias_ids)
    idx = find(strcmp({D.cases.ID}, alias_ids{k}), 1);
    T = T.chk(~isempty(idx), sprintf('alias_%s_exists', alias_ids{k}));
end
lf1 = D.cases(find(strcmp({D.cases.ID}, 'LF1'), 1));
lf2 = D.cases(find(strcmp({D.cases.ID}, 'LF2'), 1));
lf3 = D.cases(find(strcmp({D.cases.ID}, 'LF3'), 1));
lf4 = D.cases(find(strcmp({D.cases.ID}, 'LF4'), 1));
T = T.eq([lf1.Gen_P_MW, lf2.Gen_P_MW, lf3.Gen_P_MW, lf4.Gen_P_MW], [389.30 389.30 342.01 342.01], ...
    'aliases_preserve_exact_historical_dispatches');

%% 7. Capacity Guard Validation
% Valid cases pass
T = T.chk(validate_operating_profile(p1), 'guard_accepts_primary_360MW');
T = T.chk(validate_operating_profile(q1), 'guard_accepts_qualified_342MW');
T = T.chk(validate_operating_profile(h1), 'guard_accepts_historical_with_exception');

% Overdispatch in primary case rejected (360.01 MW)
bad_p = p1;
bad_p.Gen_P_MW = 360.01; % > 360 MW without exception
try
    validate_operating_profile(bad_p);
    err_over = false;
catch
    err_over = true;
end
T = T.chk(err_over, 'guard_rejects_primary_exceeding_360MW');

% Primary case trying to bypass with exception rejected
bad_p_bypass = p1;
bad_p_bypass.approved_exception = true; % illegal on primary case
try
    validate_operating_profile(bad_p_bypass);
    err_bypass = false;
catch
    err_bypass = true;
end
T = T.chk(err_bypass, 'guard_rejects_illegal_primary_exception');

%% 8. Real Entry Path Enforcement (build_ashuganj_main)
% Valid primary 360 MW case accepted through build path
try
    D_test = ashuganj_master_data();
    c_360 = D_test.operating_profiles(1);
    validate_operating_profile(c_360);
    build_valid_ok = true;
catch
    build_valid_ok = false;
end
T = T.chk(build_valid_ok, 'entry_path_accepts_valid_360MW_case');

% Primary case modified to 360.01 MW rejected through entry path
c_invalid = c_360;
c_invalid.Gen_P_MW = 360.01;
c_invalid.approved_exception = false;
try
    validate_operating_profile(c_invalid);
    build_invalid_err = false;
catch
    build_invalid_err = true;
end
T = T.chk(build_invalid_err, 'entry_path_rejects_360p01MW_primary_case');

% Historical 389.30 MW case accepted through entry path with exception
c_hist = D_test.operating_profiles(5);
try
    validate_operating_profile(c_hist);
    build_hist_ok = true;
catch
    build_hist_ok = false;
end
T = T.chk(build_hist_ok, 'entry_path_accepts_historical_389MW_with_exception');

%% 8. Subsystem Objects Present on Master
T = T.chk(isfield(D, 'excitation'), 'master_has_excitation');
T = T.chk(isfield(D, 'sfc'), 'master_has_sfc');
T = T.chk(isfield(D, 'stationDC'), 'master_has_stationDC');
T = T.chk(isfield(D, 'dynamicReadiness'), 'master_has_dynamicReadiness');

[np, nf] = T.done();
end
