function [np, nf] = test_phase5_duty()
%TEST_PHASE5_DUTY  Phase-5 Task 10 breaker-duty engine tests (TDD, separate from coordination).
%   Locks interface D = phase5_duty(Tthrough, ratings):
%   exact 10-col duty schema (no t_up/t_down/margin columns); symmetrical RMS
%   THROUGH-current branch selection per F4 leg-semantics investigation
%   (breaker-path current, never fault-point total); Q0 (52-1) only
%   duty-eligible device, Q1/Q2/Q9 disconnectors + Q51/Q52/Q8 earthing never
%   duty; ratings MISSING unless source proves them -> verdict
%   'NOT DETERMINABLE FROM AVAILABLE DATA' (never PASS/FAIL invented);
%   exactly one 50-kA estimated-reference NOTE row (F3 LLL 50.53 vs 50.00,
%   +1.06%, never PASS/FAIL); peak ip informational only (borrowed-shape
%   design-defined, never duty input); no 'IEC' string anywhere in duty
%   outputs. All errors phase5-prefixed. Real-data leg runs honestly.
T = t_case('test_phase5_duty');

% --- Synthetic through-table mirroring backbone leg values (F4 leg-semantics) ---
locs  = {'F1'; 'F3'; 'F4'; 'F5'; 'F4'};
typs  = {'LLL'; 'LLL'; 'LLL'; 'LLL'; 'LL'};
cases = {'CASE_A'; 'CASE_A'; 'CASE_A'; 'CASE_A'; 'CASE_A'};
Itot  = [126.21414119005; 50.5308851865359; 51.058; 53.087; 44.215];
lGRID = [72.105; 47.37; 47.946; 49.941; 0.77298];
lHV   = [72.105; 3.2184; 3.1721; 3.2076; 0.77298];
lTOT  = [72.105; 47.37; 51.058; 3.2076; 1.0912e-13];
lB1   = [NaN; NaN; 14.325; NaN; 0.38649];
lB2   = [NaN; NaN; 36.737; NaN; 0.38649];
lGEN  = [55.049; 3.2285; 3.1826; 3.2177; 0.94037];
pk    = [348.255062723563; 129.76; 131.31; 136.0; 113.71];
Tsyn = table(locs, typs, cases, Itot, lGRID, lHV, lTOT, lB1, lB2, lGEN, pk, ...
    'VariableNames', {'fault_location', 'fault_type', 'caseID', 'I_primary_kA', ...
    'leg_GRID_kA', 'leg_GSUT_HV_kA', 'leg_LINE_total_kA', 'leg_LINE_B1_kA', ...
    'leg_LINE_B2_kA', 'leg_GEN_kA', 'r_kappa_ip'});

% --- MISSING ratings: no verdict without documented rating + duty basis ---
D = phase5_duty(Tsyn, []);

% --- Exact 10-col schema, locked order; separation from coordination ---
exp10 = {'location', 'breaker_ref', 'fault_type', 'caseID', 'I_sym_kA', ...
    'I_peak_kA', 'rating_kA', 'basis', 'verdict', 'note'};
T = T.chk(isequal(D.Properties.VariableNames, exp10), 'duty exact 10-col schema in locked order');
T = T.chk(~any(strcmp(D.Properties.VariableNames, 't_up_s')), 'no t_up column (separate from coordination)');
T = T.chk(~any(strcmp(D.Properties.VariableNames, 't_down_s')), 'no t_down column (separate from coordination)');
T = T.chk(~any(strcmp(D.Properties.VariableNames, 'margin_s')), 'no margin column (separate from coordination)');

% --- No 'IEC' string anywhere in duty outputs (table scan) ---
T = T.chk(~table_has_str(D, 'IEC'), 'no IEC string in duty table');

% --- F4 leg-semantics: breaker-path current, never fault-point sum ---
rF4 = D(strcmp(D.location, 'F4') & strcmp(D.fault_type, 'LLL') & strcmp(D.caseID, 'CASE_A'), :);
T = T.chk(height(rF4) == 1, 'F4 LLL duty row present');
T = T.chk(abs(rF4.I_sym_kA - 3.1721) < 1e-9, 'F4 LLL through-current 3.1721 kA (breaker-path, not 51.058 total)');
T = T.chk(strcmp(rF4.breaker_ref{1}, 'Q0'), 'F4 duty breaker_ref Q0 (only duty-eligible device)');
% --- F3: plant infeed through Q0, not remote-side LINE_Q9 == GRID_Q ---
rF3 = D(strcmp(D.location, 'F3') & ~strcmp(D.verdict, 'NOTE'), :);
T = T.chk(abs(rF3.I_sym_kA - 3.2184) < 1e-9, 'F3 LLL through-current 3.2184 kA (plant infeed, not 47.37 remote-side)');
% --- F1: grid infeed through Q0 toward generator fault ---
rF1 = D(strcmp(D.location, 'F1'), :);
T = T.chk(abs(rF1.I_sym_kA - 72.105) < 1e-9, 'F1 LLL through-current 72.105 kA (grid infeed through Q0, not 126.21 total)');
% --- F5: plant infeed through Q0 toward remote fault ---
rF5 = D(strcmp(D.location, 'F5'), :);
T = T.chk(abs(rF5.I_sym_kA - 3.2076) < 1e-9, 'F5 LLL through-current 3.2076 kA (plant infeed, not 49.94 remote infeed)');

% --- Q1/Q2/Q9 disconnectors + Q51/Q52/Q8 earthing NEVER duty ---
refs = D.breaker_ref;
T = T.chk(all(strcmp(refs, 'Q0') | strcmp(refs, 'Q0-REF50kA') | strcmp(D.verdict, 'NOTE') & strcmp(refs, 'Q0')), ...
    'breaker_ref Q0 only (no disconnector/earthing duty invented)');
T = T.chk(~any(strcmp(refs, 'Q1')) && ~any(strcmp(refs, 'Q2')) && ~any(strcmp(refs, 'Q9')), 'Q1/Q2/Q9 disconnectors never duty');
T = T.chk(~any(strcmp(refs, 'Q51')) && ~any(strcmp(refs, 'Q52')) && ~any(strcmp(refs, 'Q8')), 'Q51/Q52/Q8 earthing never duty');

% --- MISSING ratings -> NOT DETERMINABLE, never PASS/FAIL (except NOTE row) ---
isNote = strcmp(D.verdict, 'NOTE');
dutyRows = D(~isNote, :);
T = T.chk(all(strcmp(dutyRows.verdict, 'NOT DETERMINABLE FROM AVAILABLE DATA')), 'MISSING ratings -> all duty rows NOT DETERMINABLE');
T = T.chk(~any(strcmp(dutyRows.verdict, 'PASS')) && ~any(strcmp(dutyRows.verdict, 'FAIL')), 'no PASS/FAIL without rating');
T = T.chk(all(isnan(dutyRows.rating_kA)), 'MISSING ratings -> rating_kA NaN');
T = T.chk(all(~cellfun(@isempty, strfind(dutyRows.basis, 'MISSING'))), 'MISSING ratings -> basis carries MISSING tag');

% --- Exactly one 50-kA NOTE row (frozen-constant path: synthetic has no F3/LLL/OUT backbone total) ---
T = T.chk(sum(isNote) == 1, 'duty table contains exactly one NOTE row for 50-kA comparison');
nRow = D(isNote, :);
T = T.chk(abs(nRow.I_sym_kA - 50.5308851865359) < 1e-6, 'NOTE row I_sym 50.53 kA (F3 LLL reference)');
T = T.chk(abs(nRow.rating_kA - 50.0) < 1e-12, 'NOTE row estimated reference 50.00 kA');
T = T.chk(~isempty(strfind(nRow.note{1}, '+1.06%')), 'NOTE row carries +1.06% comparison');
T = T.chk(~isempty(strfind(lower(nRow.basis{1}), 'estimat')), 'NOTE row basis flags estimated reference');
T = T.chk(~strcmp(nRow.verdict{1}, 'PASS') && ~strcmp(nRow.verdict{1}, 'FAIL'), 'NOTE row never PASS/FAIL');

% --- Peak ip informational only: passthrough + never a duty input ---
T = T.chk(abs(rF4.I_peak_kA - 131.31) < 1e-9, 'peak ip passthrough from borrowed-shape r_kappa_ip');
D2 = phase5_duty(Tsyn, []);
T = T.chk(isequal(D2.verdict, D.verdict), 'peak presence never changes verdict (informational only)');
TsynNoPk = removevars(Tsyn, 'r_kappa_ip');
Dnopk = phase5_duty(TsynNoPk, []);
rF4np = Dnopk(strcmp(Dnopk.location, 'F4') & strcmp(Dnopk.fault_type, 'LLL'), :);
T = T.chk(isnan(rF4np.I_peak_kA), 'missing peak -> NaN (never invented)');
T = T.chk(~isempty(strfind(rF4np.note{1}, 'MISSING-peak')), 'missing peak -> MISSING-peak note');
T = T.chk(isequal(Dnopk.verdict, D.verdict), 'missing peak never changes verdict');

% --- B1/B2 per-circuit contributions never duty, even when plant leg missing ---
Tgap = Tsyn(3, :);
Tgap.leg_GSUT_HV_kA = NaN;
Dgap = phase5_duty(Tgap, []);
gF4 = Dgap(~strcmp(Dgap.verdict, 'NOTE'), :);
T = T.chk(isnan(gF4.I_sym_kA), 'missing plant leg -> I_sym NaN (B1/B2 never substituted)');
T = T.chk(strcmp(gF4.verdict{1}, 'NOT DETERMINABLE FROM AVAILABLE DATA'), 'missing leg -> NOT DETERMINABLE');
T = T.chk(~isempty(strfind(gF4.note{1}, 'MISSING-leg')), 'missing leg -> MISSING-leg note');

% --- Documented rating + duty basis -> PASS/FAIL allowed ---
Rdoc = struct('breaker_ref', 'Q0', 'rating_kA', 40.0, 'source', 'STUDY:documented-test-rating-only');
Dr = phase5_duty(Tsyn, Rdoc);
frF4 = Dr(strcmp(Dr.location, 'F4') & strcmp(Dr.fault_type, 'LLL') & ~strcmp(Dr.verdict, 'NOTE'), :);
frF1 = Dr(strcmp(Dr.location, 'F1') & ~strcmp(Dr.verdict, 'NOTE'), :);
T = T.chk(strcmp(frF4.verdict{1}, 'PASS'), 'documented 40 kA rating: F4 3.17 kA -> PASS');
T = T.chk(strcmp(frF1.verdict{1}, 'FAIL'), 'documented 40 kA rating: F1 72.11 kA -> FAIL (honest, never tuned)');
% --- Rating without source still MISSING (no verdict without duty basis) ---
Rnos = struct('breaker_ref', 'Q0', 'rating_kA', 40.0, 'source', '');
Dns = phase5_duty(Tsyn, Rnos);
T = T.chk(all(strcmp(Dns(~strcmp(Dns.verdict, 'NOTE'), :).verdict, 'NOT DETERMINABLE FROM AVAILABLE DATA')), ...
    'rating without source -> still NOT DETERMINABLE');

% --- Real-data integration (honest backbone leg join) ---
root = ashuganj_root();
Ti = phase5_import(root);
Di = phase5_duty(Ti, []);
T = T.chk(height(Di) == height(Ti) + 1, 'real-data duty rows = import rows + exactly one NOTE row');
iF4 = Di(strcmp(Di.location, 'F4') & strcmp(Di.fault_type, 'LLL') & strcmp(Di.caseID, 'LF360_GAT_OUT') & ~strcmp(Di.verdict, 'NOTE'), :);
T = T.chk(~isempty(iF4) && abs(iF4.I_sym_kA - 3.1721) < 1e-4, 'real-data F4 LLL OUT through-current 3.1721 kA (not 51.058 total)');
iF3n = Di(strcmp(Di.verdict, 'NOTE'), :);
T = T.chk(height(iF3n) == 1 && abs(iF3n.I_sym_kA - 50.5308851865359) < 1e-6, 'real-data NOTE row uses joined F3 LLL OUT total 50.53 kA');
T = T.chk(~table_has_str(Di, 'IEC'), 'real-data duty outputs carry no IEC string');
T = T.chk(~any(strcmp(Di.Properties.VariableNames, 't_up_s')) && ~any(strcmp(Di.Properties.VariableNames, 'margin_s')), ...
    'real-data duty stays separate from coordination');

% --- Errors phase5-prefixed ---
try
    phase5_duty(table(), []);
    T = T.chk(false, 'empty table must error');
catch ME
    T = T.chk(strncmp(ME.identifier, 'phase5_duty', 11), 'empty-table error is phase5_duty-prefixed');
end
try
    phase5_duty(Tsyn, struct('breaker_ref', 'Q9', 'rating_kA', 40.0, 'source', 'STUDY:x'));
    T = T.chk(false, 'Q9 rating must error (disconnectors never duty)');
catch ME
    T = T.chk(strncmp(ME.identifier, 'phase5_duty', 11), 'Q9-rating error is phase5_duty-prefixed');
end

[np, nf] = T.done();
end

function tf = table_has_str(D, pat)
%TABLE_HAS_STR  True if pattern appears in any variable name or string cell of D.
tf = ~isempty(strfind(strjoin(D.Properties.VariableNames, '|'), pat));
if tf, return; end
for k = 1:numel(D.Properties.VariableNames)
    col = D.(D.Properties.VariableNames{k});
    if iscell(col)
        for i = 1:numel(col)
            v = col{i};
            if (ischar(v) || isstring(v)) && ~isempty(strfind(char(v), pat))
                tf = true; return;
            end
        end
    elseif ischar(col) || isstring(col)
        if ~isempty(strfind(char(col), pat)), tf = true; return; end
    end
end
end
