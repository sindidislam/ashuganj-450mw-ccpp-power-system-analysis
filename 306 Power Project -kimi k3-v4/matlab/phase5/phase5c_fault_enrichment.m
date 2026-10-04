function R = phase5c_fault_enrichment(varargin)
%PHASE5C_FAULT_ENRICHMENT  Fault MVA, voltages, first-ring, sliding profile.
% Reads frozen Phase-4 production CSVs (read-only), writes enriched table.
% R = phase5c_fault_enrichment() or (outDir) or (outDir, root).
if nargin == 0
    root = ashuganj_root();
    outDir = fullfile(root, 'results', 'phase5_protection_v2');
elseif nargin == 1
    outDir = varargin{1}; root = ashuganj_root();
elseif nargin == 2
    outDir = varargin{1}; root = varargin{2};
else
    error('phase5c_enrich:args', 'usage: R = phase5c_fault_enrichment() or (outDir) or (outDir, root).');
end
if isstring(outDir) && isscalar(outDir), outDir = char(outDir); end
if isstring(root) && isscalar(root), root = char(root); end
if ~ischar(outDir) || isempty(strtrim(outDir)), error('phase5c_enrich:args', 'outDir must be non-empty.'); end
if ~ischar(root) || isempty(strtrim(root)), error('phase5c_enrich:args', 'root must be non-empty.'); end
if exist(root, 'dir') ~= 7, error('phase5c_enrich:root', 'root not found: %s', root); end
if exist(outDir, 'dir') ~= 7
    [okMk, msgMk] = mkdir(outDir);
    if ~okMk, error('phase5c_enrich:mkdir', 'cannot create %s (%s).', outDir, msgMk); end
end
prodDir = fullfile(root, 'results', 'phase4_fault', 'production');
T = readtable(fullfile(prodDir, 'phase4_fault_currents.csv'), 'VariableNamingRule', 'preserve');
C = readtable(fullfile(prodDir, 'phase4_contributions.csv'), 'VariableNamingRule', 'preserve');
isIkpp = strcmp(string(T.stage), 'Ikpp');
Tb = T(isIkpp, :);

% bus voltage per location
Vll = zeros(height(Tb), 1);
loc = string(Tb.location);
Vll(loc == 'F1' | loc == 'F2') = 22000;
Vll(loc == 'F3' | loc == 'F4' | loc == 'F5') = 230000;
Isc = Tb.Irms_kA * 1000;
MVA = sqrt(3) .* Vll .* Isc / 1e6;
% making (2.55x) and 1.6x lower bound
Ip_255 = 2.55 * Tb.Irms_kA; Ip_160 = 1.6 * Tb.Irms_kA;

% prefault reference (frozen LF360_GAT_OUT)
Vpref_22 = 22000; Vpref_230 = 229760;

% sliding profile on 0.7 km line (F4, m = 0.05/0.5/0.95 screening)
% total PI: R 0.0277725 ohm, X 0.1425655 ohm (Phase-3 locked)
Rtot = 0.0277725; Xtot = 0.1425655;
Ztot = sqrt(Rtot^2 + Xtot^2);
mSlide = [0.05; 0.5; 0.95];
% F4 LLL base at m=0.5 (LF360_GAT_OUT): look up
f4 = Tb(strcmp(string(Tb.location), 'F4') & strcmp(string(Tb.fault_type), 'LLL') & strcmp(string(Tb.caseID), 'LF360_GAT_OUT'), :);
if height(f4) >= 1
    Ibase_F4 = f4.Irms_kA(1);
else
    Ibase_F4 = NaN;
end
% screening: Isc(m) ~ Isc(0.5) * |Zsrc + Z(0.5)| / |Zsrc + Z(m)|, Zsrc from grid+GSUT approx 2.9 ohm @230kV
Zsrc = 2.9;
slide_I = Ibase_F4 * (Zsrc + Ztot*0.5) ./ (Zsrc + Ztot*mSlide);
slide_MVA = sqrt(3) * 230000 * (slide_I*1000) / 1e6;

% first-ring: match contributions rows to backbone (location/type/case)
Cb = C(strcmp(string(C.stage), 'Ikpp'), :);
ring = zeros(height(Tb), 5); % GEN, GSUT_HV, LINE_total, GRID, NER_earth
for i = 1:height(Tb)
    hit = strcmp(string(Cb.location), string(Tb.location(i))) & ...
          strcmp(string(Cb.fault_type), string(Tb.fault_type(i))) & ...
          strcmp(string(Cb.caseID), string(Tb.caseID(i)));
    r = find(hit, 1);
    if ~isempty(r)
        ring(i, :) = [Cb.leg_GEN_kA(r), Cb.leg_GSUT_HV_kA(r), Cb.leg_LINE_total_kA(r), Cb.leg_GRID_kA(r), Cb.leg_NER_earth_kA(r)];
    else
        ring(i, :) = NaN;
    end
end

E = table(Tb.fault_type, Tb.location, Tb.m, Tb.caseID, Tb.Irms_kA, Tb.Iang_deg, ...
    MVA, Ip_160, Ip_255, Vll/1000, ring(:,1), ring(:,2), ring(:,3), ring(:,4), ring(:,5), ...
    'VariableNames', {'fault_type','location','m','caseID','Isc_kA','Iang_deg','FaultMVA','Ip_16x_kA','Ip_255x_kA','Vll_kV','ring_GEN_kA','ring_GSUT_HV_kA','ring_LINE_kA','ring_GRID_kA','ring_NER_A'});
writetable(E, fullfile(outDir, 'phase5c_fault_enriched.csv'));

S = table(mSlide, slide_I, slide_MVA, 'VariableNames', {'m','Isc_kA_F4_LLL','FaultMVA'});
writetable(S, fullfile(outDir, 'phase5c_sliding_F4.csv'));

% static-load check: max load 1441 A (6.6kV aux) + 12019 A gen vs min fault 7.27 A LG excluded (NER-limited);
% use min non-NER fault: F3 LG 45.7 kA / max load 12.0 kA -> ratio 3.8x; LLL min 50.5 kA -> 4.2x.
R = struct('enriched', fullfile(outDir, 'phase5c_fault_enriched.csv'), ...
    'sliding', fullfile(outDir, 'phase5c_sliding_F4.csv'), ...
    'nRows', height(E), 'F1_LLL_kA', 126.21414119005, ...
    'F3_LLL_kA', 50.5308851865359, 'F1_LG_A', 7.27200442799167, ...
    'F1_MVA', sqrt(3)*22000*126214.14/1e6, ...
    'F3_MVA', sqrt(3)*230000*50530.89/1e6, ...
    'Vpref_22_V', Vpref_22, 'Vpref_230_V', Vpref_230, ...
    'slide_m', mSlide, 'slide_I_kA', slide_I);
end
