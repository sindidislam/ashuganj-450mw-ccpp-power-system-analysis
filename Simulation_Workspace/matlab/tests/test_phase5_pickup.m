function [np, nf] = test_phase5_pickup()
%TEST_PHASE5_PICKUP  Phase-5 Task 6 pickup methodology engine tests (TDD RED).
%   Asserts locked interface P = phase5_pickup(device, Iload_A, Imin_fault_A):
%   output fields setting/unit/basis/source/validation present (PRIMARY A);
%   GEN-51 == 15023.75 A; GEN-51N < 7.27 A (must-detect, SENSITIVE flag +
%   limitation); GIS-Q0-51 == 1.2x frozen-flow anchor; every pickup >
%   normal-load anchor (no-trip-on-load). Study settings documented, never
%   tuned-to-pass. All errors phase5-prefixed (asserted via NOTE/boundary).
T = t_case('test_phase5_pickup');
R = phase5_registry();
ids = {R.devices.device_id};
d51  = R.devices(strcmp(ids, 'GEN-51'));
d51N = R.devices(strcmp(ids, 'GEN-51N'));
dQ0  = R.devices(strcmp(ids, 'GIS-Q0-51'));

% Frozen anchors (PRIMARY A, from results/phase4_fault/production/
% phase4_ct_data.csv FL_anchor_kA column; derivation Task-13 report from
% results/phase3_loadflow/phase3_system_summary.csv LF360_GAT_OUT row):
% GEN_Q 9.47574312698307 kA; LINE_Q9 0.869956651959241 kA.
FL_GENQ_A  = 9.47574312698307 * 1000;
FL_LINEQ9_A = 0.869956651959241 * 1000;
% Min phase fault (bus, PRIMARY A): F3 LL OUT 43.7588597559 kA from
% phase5_import backbone (excludes LG earth 7.27 A regime).
IMIN_PHASE_A = 43758.8597559;
% F1 LG earth physics (PRIMARY A): 0.00727200442799167 kA = 7.272 A.
IMIN_EARTH_A = 7.27200442799167;

% --- Locked interface: fields present ---
P = phase5_pickup(d51, FL_GENQ_A, IMIN_PHASE_A);
T = T.chk(isstruct(P) && all(isfield(P, {'setting', 'unit', 'basis', 'source', 'validation'})), 'output fields setting/unit/basis/source/validation present');

% --- GEN-51 phase: 1.25 x 12019 = 15023.75 A primary ---
T = T.chk(abs(P.setting - 15023.75) < 1e-9, 'GEN-51 pickup 1.25x12019 = 15023.75 A primary');
T = T.chk(strcmp(char(P.unit), 'A-primary'), 'pickup unit A-primary (T7 converts via CT)');
T = T.chk(P.setting > FL_GENQ_A, 'GEN-51 pickup > normal-load anchor (no-trip-on-load)');
T = T.chk(P.setting < IMIN_PHASE_A, 'GEN-51 pickup below min phase fault (must-detect zone fault)');
T = T.chk(~isempty(strfind(char(P.basis), 'above-rated-below-min-phase-fault')), 'GEN-51 BASIS above-rated-below-min-phase-fault');

% --- GEN-51N earth: must be < F1 LG 7.27 A, SENSITIVE + limitation ---
PN = phase5_pickup(d51N, 0, IMIN_EARTH_A);
T = T.chk(PN.setting < 7.27, 'GEN-51N EF pickup < F1 LG 7.27 A (must-detect)');
T = T.chk(PN.setting > 0, 'GEN-51N pickup > earth-load anchor 0 (no-trip-on-load)');
T = T.chk(~isempty(strfind(char(PN.source), 'SENSITIVE')) || ~isempty(strfind(char(PN.validation), 'SENSITIVE')), 'GEN-51N flagged SENSITIVE');
T = T.chk(~isempty(strfind(lower(char(PN.validation)), 'limitation')) || ~isempty(strfind(lower(char(PN.validation)), 'noise')) || ~isempty(strfind(lower(char(PN.validation)), 'susceptible')), 'GEN-51N limitation noted (noise/susceptible)');
T = T.chk(abs(IMIN_EARTH_A / PN.setting - 1.45) < 0.05, 'GEN-51N margin ~1.45 vs F1 LG');

% --- GIS-Q0-51: 1.2 x frozen-flow anchor ---
PG = phase5_pickup(dQ0, FL_LINEQ9_A, IMIN_PHASE_A);
T = T.chk(abs(PG.setting - 1.2 * FL_LINEQ9_A) < 1e-9, 'GIS-Q0-51 pickup 1.2x frozen-flow anchor');
T = T.chk(PG.setting > FL_LINEQ9_A, 'GIS-Q0-51 pickup > load anchor (no-trip-on-load)');
T = T.chk(~isempty(strfind(char(PG.basis), 'FL_anchor')) || ~isempty(strfind(char(PG.source), 'FL_anchor')), 'GIS-Q0-51 cites FL_anchor from ct_data');

[np, nf] = T.done();
end
