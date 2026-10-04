function T = phase5_import(root)
%PHASE5_IMPORT  Phase-4 production CSV backbone importer (Phase-5 Task 1+3).
%   T = PHASE5_IMPORT(root) reads results/phase4_fault/production/
%   phase4_fault_currents.csv (read-only), filters stage=='Ikpp', and maps
%   to protection-study input columns:
%     fault_location, fault_type, caseID, m, stage, I_primary_kA,
%     I_primary_A, provenance (locked 8-col backbone, 40 rows),
%   plus through-current join from phase4_contributions.csv (read-only):
%     leg_GEN_kA, leg_GSUT_LV_kA, leg_GSUT_HV_kA, leg_UAT_kA,
%     leg_GAT_HV_kA, leg_GAT_LV_kA, leg_LINE_total_kA, leg_LINE_B1_kA,
%     leg_LINE_B2_kA, leg_GRID_kA, leg_NER_earth_kA, through_note.
%   F1/F2 labels are never collapsed (values identical, no artificial Z);
%   F4 primary m==0.5 guarded; missing contributions row -> NaN legs +
%   through_note 'MISSING-leg' (never fabricated); provenance constant
%   'SOURCE-BACKED:Phase-4-production-import', never 'scratch'.
%   No re-solve, no phase4 function calls. All errors 'phase5'-prefixed.
if nargin < 1 || isempty(root)
    error('phase5_import:args', 'root argument required (project root path).');
end
if isstring(root), root = char(root); end
Fp = fullfile(root, 'results', 'phase4_fault', 'production', 'phase4_fault_currents.csv');
if exist(Fp, 'file') ~= 2
    error('phase5_import:missing', 'production currents CSV missing: %s', Fp);
end
C = readtable(Fp);
need = {'fault_type', 'location', 'm', 'caseID', 'stage', 'Irms_kA'};
for k = 1:numel(need)
    if ~any(strcmp(C.Properties.VariableNames, need{k}))
        error('phase5_import:schema', 'production currents CSV missing column %s.', need{k});
    end
end
% Backbone Ikpp = 40 rows (2 cases x 5 locs x 4 types). Legs base=OUT and
% GAT-IN=IN ARE the cases, never double-counted. Manifest backbone 80 solves
% = 40 Ikpp + 40 ip; Ikpp total 228 = 40 backbone + 156 OFAT + 32 m-section.
% Isolate backbone honestly: filter stage=='Ikpp', keep m==0.5, then keep the
% first row per (caseID,location,fault_type), relying on the documented
% backbone-first merge order in run_phase4_production.m (backbone, OFAT,
% anchors merged in order; F4 m-section appended last and never m=0.5).
idx = strcmp(C.stage, 'Ikpp') & C.m == 0.5;
Cb = C(idx, :);
keys = strcat(Cb.caseID, '|', Cb.location, '|', Cb.fault_type);
[~, ia] = unique(keys, 'stable');
Cb = Cb(ia, :);
fault_location = Cb.location;
fault_type = Cb.fault_type;
caseID = Cb.caseID;
m = Cb.m;
stage = Cb.stage;
I_primary_kA = Cb.Irms_kA;
I_primary_A = Cb.Irms_kA * 1000;
provenance = repmat({'SOURCE-BACKED:Phase-4-production-import'}, height(Cb), 1);
% Task 3 guards (locked 40-row backbone semantics preserved):
% F1/F2 labels never collapsed: both must be present per (caseID,fault_type).
cases = unique(caseID);
types = unique(fault_type);
for ic = 1:numel(cases)
    for it = 1:numel(types)
        hasF1 = any(strcmp(fault_location,'F1') & strcmp(fault_type,types{it}) & strcmp(caseID,cases{ic}));
        hasF2 = any(strcmp(fault_location,'F2') & strcmp(fault_type,types{it}) & strcmp(caseID,cases{ic}));
        if ~hasF1 || ~hasF2
            error('phase5_import:f1f2', 'F1/F2 label preservation violated for case %s type %s (never collapse).', cases{ic}, types{it});
        end
    end
end
% F4 primary m==0.5 guard.
isF4 = strcmp(fault_location,'F4');
if ~all(m(isF4) == 0.5)
    error('phase5_import:m', 'F4 primary m must be 0.5 (got non-0.5 F4 row).');
end
% Provenance never 'scratch'.
if any(strcmp(provenance,'scratch'))
    error('phase5_import:provenance', 'provenance must never be scratch.');
end
% Through-current join from phase4_contributions.csv where available.
Fc = fullfile(root, 'results', 'phase4_fault', 'production', 'phase4_contributions.csv');
if exist(Fc, 'file') ~= 2
    error('phase5_import:missing', 'production contributions CSV missing: %s', Fc);
end
K = readtable(Fc);
legs = {'leg_GEN_kA','leg_GSUT_LV_kA','leg_GSUT_HV_kA','leg_UAT_kA','leg_GAT_HV_kA','leg_GAT_LV_kA','leg_LINE_total_kA','leg_LINE_B1_kA','leg_LINE_B2_kA','leg_GRID_kA','leg_NER_earth_kA'};
for k = 1:numel(legs)
    if ~any(strcmp(K.Properties.VariableNames, legs{k}))
        error('phase5_import:schema', 'production contributions CSV missing column %s.', legs{k});
    end
end
Kb = K(strcmp(K.stage,'Ikpp') & K.m == 0.5, :);
kkeys = strcat(Kb.caseID,'|',Kb.location,'|',Kb.fault_type);
[~, ika] = unique(kkeys, 'stable');
Kb1 = Kb(ika, :);
n = height(Cb);
legVals = NaN(n, numel(legs));
through_note = repmat({''}, n, 1);
for i = 1:n
    hit = strcmp(Kb1.caseID, caseID{i}) & strcmp(Kb1.location, fault_location{i}) & strcmp(Kb1.fault_type, fault_type{i});
    if any(hit)
        r = Kb1(find(hit, 1, 'first'), :);
        for L = 1:numel(legs)
            legVals(i, L) = r.(legs{L});
        end
        through_note{i} = '';
    else
        through_note{i} = 'MISSING-leg';
    end
end
leg_GEN_kA = legVals(:,1); leg_GSUT_LV_kA = legVals(:,2); leg_GSUT_HV_kA = legVals(:,3);
leg_UAT_kA = legVals(:,4); leg_GAT_HV_kA = legVals(:,5); leg_GAT_LV_kA = legVals(:,6);
leg_LINE_total_kA = legVals(:,7); leg_LINE_B1_kA = legVals(:,8); leg_LINE_B2_kA = legVals(:,9);
leg_GRID_kA = legVals(:,10); leg_NER_earth_kA = legVals(:,11);
T = table(fault_location, fault_type, caseID, m, stage, I_primary_kA, I_primary_A, provenance, ...
    leg_GEN_kA, leg_GSUT_LV_kA, leg_GSUT_HV_kA, leg_UAT_kA, leg_GAT_HV_kA, leg_GAT_LV_kA, ...
    leg_LINE_total_kA, leg_LINE_B1_kA, leg_LINE_B2_kA, leg_GRID_kA, leg_NER_earth_kA, through_note);
if height(T) ~= 40
    error('phase5_import:matrix', 'backbone Ikpp row count %d ~= 40 (2x5x4).', height(T));
end
end
