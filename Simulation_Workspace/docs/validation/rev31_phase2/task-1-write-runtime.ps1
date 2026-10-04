$ErrorActionPreference = 'Stop'
$utf8 = New-Object System.Text.UTF8Encoding($false)
function Write-Matlab([string]$path, [string]$content) {
    [System.IO.File]::WriteAllText((Join-Path (Get-Location) $path), $content.Replace("`r`n", "`n") + "`n", $utf8)
}
$path = 'matlab/data/ashuganj_generators.m'
$original = [System.IO.File]::ReadAllText((Join-Path (Get-Location) 'docs/validation/rev31_phase2/originals/matlab/data/ashuganj_generators.m.original'))
$old = @'
G.Qmin_MVAr=-inf; G.Qmax_MVAr=inf; G.Qlim_Status='NOT_APPLICABLE'; G.Qlim_Note='Unconstrained until capability curve digitization is verified';
G.Qcurve_Status='AVAILABLE_NOT_DIGITIZED'; G.Qcurve_Source='Siemens Generator Protection Setting Report Attachment 1'; G.Qcurve_Note='Old PSAF scalar limits invalid';
'@
$new = @'
% Physical capability only: frozen PV builder solver settings stay unbounded
% by explicit user approval. They are neither physical Q nor grounding data.
G.capabilityCurve=struct('P_MW',[0 100 200 300 389.3 458], ...
    'Qmax_MVAr',[335 329 311 280 241 0], 'Qmin_MVAr',[-231 -231 -220 -205 -182 0], ...
    'status','PRIMARY_SOURCE_EXTRACTED', 'source_status','PRIMARY_SOURCE_EXTRACTED', ...
    'source','Siemens Generator Protection Setting Report', 'source_locator','Attachment 1', ...
    'extraction_method','MANUAL_GRAPH_EXTRACTION', 'extracted_by','USER', ...
    'confirmation_date','2026-09-15', 'attachment_locally_inspected',false, ...
    'confidence','User-confirmed graph extraction; graphical uncertainty not quantified', ...
    'rationale','Six user-supplied graph readings, not directly tabulated manufacturer values; original attachment not locally inspected.', ...
    'P_unit','MW', 'Q_unit','MVAr', 'interpolation','linear', 'extrapolation','REJECT', ...
    'interpretation_status','QUALIFIED', ...
    'applicability','Source envelope through 458 MW is not dispatch authorization; primary active capacity remains 360 MW.');
[G.Qmin_MVAr,G.Qmax_MVAr]=generatorCapability(G.P_capacity_MW,G.capabilityCurve);
G.Qlim_P_MW=G.P_capacity_MW;
G.Qlim_Status='DERIVED_FROM_PRIMARY_SOURCE_EXTRACTED'; G.Qlim_Source_status=G.capabilityCurve.status;
G.Qlim_Note='Physical compatibility bounds at Qlim_P_MW only; interpolate at actual dispatch. Frozen unconstrained solver is an approved exception, not physical capability.';
G.Qcurve_Status=G.capabilityCurve.status; G.Qcurve_Source='Siemens Generator Protection Setting Report Attachment 1';
G.Qcurve_Note='User-supplied manual graph extraction; attachment not locally inspected. Old PSAF scalar limits remain invalid.';
'@
# Preserve the original CRLF bytes outside the exact replacement.
$old = $old.Replace("`r`n", "`n").Replace("`n", "`r`n")
$new = $new.Replace("`r`n", "`n").Replace("`n", "`r`n")
if (-not $original.Contains($old)) { throw 'Original generator search block missing' }
[System.IO.File]::WriteAllText((Join-Path (Get-Location) $path), $original.Replace($old,$new), $utf8)
Write-Matlab 'matlab/data/generatorCapability.m' @'
function [Qmin_MVAr,Qmax_MVAr] = generatorCapability(P_MW,curve)
%GENERATORCAPABILITY Piecewise-linear physical capability, lower then upper.
% [Qmin_MVAr,Qmax_MVAr] = generatorCapability(P_MW [,curve])
% P_MW is a nonempty real finite numeric array in [0,458] MW. Output arrays
% retain its shape. No extrapolation, clipping or dispatch authorization.
% Optional scalar curve has numeric vector fields P_MW, Qmin_MVAr,
% Qmax_MVAr, equal lengths >=2, strictly increasing P from 0 to 458,
% finite real entries and ordered Q bounds. It supports provider construction
% without recursion. Omitted curve comes from ashuganj_generators().
if ~isnumeric(P_MW) || isempty(P_MW) || ~isreal(P_MW) || ...
        any(~isfinite(P_MW(:))) || any(P_MW(:)<0 | P_MW(:)>458)
    error('generatorCapability:InvalidP','P must be real finite numeric MW in [0,458].');
end
if nargin < 2
    G = ashuganj_generators();
    curve = G.capabilityCurve;
end
fields = {'P_MW','Qmin_MVAr','Qmax_MVAr'};
if ~isstruct(curve) || ~isscalar(curve) || ~all(isfield(curve,fields))
    error('generatorCapability:InvalidCurve','Curve must contain P and both Q bounds.');
end
for k=1:numel(fields)
    v = curve.(fields{k});
    if ~isnumeric(v) || ~isvector(v) || ~isreal(v) || numel(v)<2 || any(~isfinite(v(:)))
        error('generatorCapability:InvalidCurve','Curve fields must be real finite numeric vectors.');
    end
end
p = double(curve.P_MW(:)); lo = double(curve.Qmin_MVAr(:)); hi = double(curve.Qmax_MVAr(:));
if numel(p)~=numel(lo) || numel(p)~=numel(hi) || ...
        any(diff(p)<=0) || p(1)~=0 || p(end)~=458 || any(lo>hi)
    error('generatorCapability:InvalidCurve','Curve lengths, domain or bound ordering are invalid.');
end
Qmin_MVAr = reshape(interp1(p,lo,double(P_MW(:)),'linear'),size(P_MW));
Qmax_MVAr = reshape(interp1(p,hi,double(P_MW(:)),'linear'),size(P_MW));
end
'@
Write-Matlab 'matlab/data/phase2_parameter.m' @'
function r = phase2_parameter(value,unit,source,source_locator,status,confidence,rationale,varargin)
%PHASE2_PARAMETER Construct a normalized lowercase metadata record.
% r = phase2_parameter(value,unit,source,source_locator,status,confidence,
%                      rationale,Name,Value,...)
% Seven required inputs: numeric/text value and six nonempty text metadata
% fields. Names: assumption_basis (default NOT_APPLICABLE), reasonable_range
% and assumed_range (default []), source_status (default status), derivation
% (default ''), interpretation_status (default DIRECT). selected_value=value.
% ENGINEERING_ASSUMPTION requires finite real numeric value, explicit basis,
% and finite ordered [lower upper] ranges; assumed range must be contained
% within reasonable range and contain every selected value. Degenerate
% ranges are permitted for an explicitly fixed approved assumption.
% Source records may retain NaN for MISSING and UNRESOLVED units. This helper
% never invents units, replaces missing evidence or upgrades source status.
p = inputParser;
p.FunctionName = 'phase2_parameter';
p.PartialMatching = false;
text = @(x) (ischar(x) && isrow(x) && ~isempty(strtrim(x))) || ...
    (isstring(x) && isscalar(x) && ~ismissing(x) && strlength(strtrim(x))>0);
p.addRequired('value',@(x) isnumeric(x) || islogical(x) || ischar(x) || isstring(x));
p.addRequired('unit',text); p.addRequired('source',text);
p.addRequired('source_locator',text); p.addRequired('status',text);
p.addRequired('confidence',text); p.addRequired('rationale',text);
p.addParameter('assumption_basis','NOT_APPLICABLE',text);
p.addParameter('reasonable_range',[],@isnumeric);
p.addParameter('assumed_range',[],@isnumeric);
p.addParameter('source_status',status,text);
p.addParameter('derivation','',@(x) ischar(x) || (isstring(x) && isscalar(x)));
p.addParameter('interpretation_status','DIRECT',text);
p.parse(value,unit,source,source_locator,status,confidence,rationale,varargin{:});
r = p.Results;
for name = {'unit','source','source_locator','status','confidence','rationale', ...
        'assumption_basis','source_status','derivation','interpretation_status'}
    r.(name{1}) = char(r.(name{1}));
end
r.selected_value = value;
if strcmp(r.status,'ENGINEERING_ASSUMPTION')
    a = r.assumed_range; b = r.reasonable_range;
    valid = isnumeric(value) && ~isempty(value) && isreal(value) && all(isfinite(value(:))) && ...
        ~strcmp(r.assumption_basis,'NOT_APPLICABLE') && ...
        isreal(a) && numel(a)==2 && all(isfinite(a(:))) && a(1)<=a(2) && ...
        isreal(b) && numel(b)==2 && all(isfinite(b(:))) && b(1)<=b(2);
    if ~valid || a(1)<b(1) || a(2)>b(2) || any(value(:)<a(1) | value(:)>a(2))
        error('phase2_parameter:InvalidAssumption', ...
            'Assumptions require finite selected values, explicit basis and consistent containing ranges.');
    end
end
end
'@
Write-Matlab 'matlab/data/phase2_source_data.m' @'
function S = phase2_source_data(G)
%PHASE2_SOURCE_DATA Read-only normalized Task-1 source/provenance view.
% S = phase2_source_data() uses ashuganj_generators(); S=phase2_source_data(G)
% accepts that scalar generator record, never an assembled master dataset.
% No provider is modified. S.generator has one parameter record per field
% in G.Provenance, each with raw_provenance retaining the full original.
% Other groups: capabilityCurve (same authoritative object), excitation,
% sfc, ner, grid and cooling. Group leaves are phase2_parameter records;
% S.dataset_id identifies the generator. Units are explicit at every leaf.
% Source status, derivation and interpretation are distinct. Additional
% records are contextual only: no grid/transformer/grounding model changes,
% no conversion of field resistance and no inferred SFC power or DC wiring.
if nargin < 1
    G = ashuganj_generators();
end
S.dataset_id = G.Dataset_ID;
names = fieldnames(G.Provenance);
for k=1:numel(names)
    n = names{k}; old = G.Provenance.(n);
    locator = old.Source_locator;
    if ~strcmp(old.Source_sheet,'NOT_APPLICABLE')
        locator = [locator '; sheet "' old.Source_sheet '"'];
    end
    if ~strcmp(old.Source_cell,'NOT_APPLICABLE')
        locator = [locator '; cell ' old.Source_cell];
    end
    r = phase2_parameter(old.Normalized_value,old.Normalized_unit, ...
        old.Source_document,locator,old.Source_status,old.Confidence, ...
        old.Interpretation_note,'source_status',old.Source_status, ...
        'derivation',old.Derivation,'interpretation_status',old.Interpretation_status);
    r.raw_provenance = old;
    S.generator.(n) = r;
end
S.capabilityCurve = G.capabilityCurve;
S.excitation.type = S.generator.Excitation_type;
S.excitation.designation = S.generator.Excitation_designation;
doc = 'Generator Data_South.pdf';
loc = 'PDF p.1 / report p.6 section 2.1.1';
verified = 'VERIFIED_ENGINEERING_DOCUMENT';
S.excitation.no_load_voltage_V = phase2_parameter(G.Uexc0_V,'V',doc,loc, ...
    G.Uexc0_Status,'High','No-load excitation voltage only; not a controller parameter or a defined per-unit field base.');
S.sfc.dc_link_kV = phase2_parameter(G.SFC_DC_link_kV,'kV',doc,loc, ...
    G.SFC_DC_link_Status,'High','SFC DC-link voltage, separate from generator field and station DC.');
S.sfc.dc_link_kV.side = 'DC_LINK';
S.sfc.max_starting_output_A = phase2_parameter(G.SFC_Imax_A,'A',doc,loc, ...
    G.SFC_Imax_Status,'High','Maximum starting OUTPUT current; not DC-link current. Do not multiply by DC-link voltage to claim verified power.');
S.sfc.max_starting_output_A.side = 'OUTPUT';
loc = 'PDF p.2 / report p.7 section 2.3 Neutral Earthing Transformer (BAB), 10BAB11';
S.ner.primary_kV = phase2_parameter(22/sqrt(3),'kV',doc,loc,verified,'High', ...
    'Source 22/sqrt(3) kV primary phase voltage; not a line-line 22 kV winding rating.', ...
    'derivation','22 / sqrt(3)');
S.ner.secondary_V = phase2_parameter(500,'V',doc,loc,verified,'High','NER secondary rating.');
S.ner.rating_kVA = phase2_parameter(135,'kVA',doc,loc,verified,'High','Short-time rating, valid for 20 s, not continuous.');
S.ner.duration_s = phase2_parameter(20,'s',doc,loc,verified,'High','Duration associated with 135 kVA rating.');
S.ner.hv_dc_resistance_ohm = phase2_parameter(60,'ohm',doc,loc,verified,'Qualified / approximate', ...
    'HV-winding DC resistance approximately 60 ohm; source carries a question mark. Not a verified zero-sequence equivalent.', ...
    'interpretation_status','QUALIFIED');
S.ner.loading_resistance_ohm = phase2_parameter(2.62,'ohm',doc,loc,verified,'Qualified / approximate', ...
    'Secondary loading resistor approximately 2.62 ohm; source carries question marks. Do not add directly to HV resistance across different sides.', ...
    'interpretation_status','QUALIFIED');
S.ner.grounding = S.generator.Earthing;
loc = 'PDF p.2 / report p.7 section 2.4 High voltage network (GRID)';
S.grid.estimate_Isc_kA = phase2_parameter(50,'kA',doc,loc,'ESTIMATED','Estimated', ...
    'Report estimated grid context; frozen provider uses 50 kA GIS withstand proxy, not verified PGCB fault strength.');
S.grid.estimate_Ssc_GVA = phase2_parameter(19.919,'GVA',doc,loc,'ESTIMATED','Estimated', ...
    'Source rounded 19,919 MVA = 19.919 GVA; not a replacement for frozen sqrt(3)*230*50 MVA arithmetic.', ...
    'derivation','19919 MVA / 1000');
secondary = 'Secondary 2019 fault-level compilation, ASHUGANJ S 230 kV';
locator = 'Existing project reconciliation: matlab/studies/rev3_b1_derivations.m secondary sensitivity; original secondary attachment not re-inspected';
S.grid.sensitivity_Isc_kA = phase2_parameter(45.01,'kA',secondary,locator, ...
    'SECONDARY_SOURCE_CONTEXT','Qualified secondary context','Sensitivity only, not selected frozen grid strength.');
S.grid.sensitivity_XR = phase2_parameter(10.99,'dimensionless',secondary,locator, ...
    'SECONDARY_SOURCE_CONTEXT','Qualified secondary context','Sensitivity only; frozen grid R=0 and infinite X/R remain untouched.');
doc = 'GSUT Data Sheet_South.pdf';
loc = 'CTI 1.7 loss table, 515 MVA ODAF stage; existing rev3_b1_derivations source transcription';
S.cooling.gsut_total_kW = phase2_parameter(1282,'kW',doc,loc,verified,'High','Total source loss at 515 MVA cooling stage; contextual accounting only.');
S.cooling.gsut_no_load_kW = phase2_parameter(159,'kW',doc,loc,verified,'High','Source no-load loss; numerical transformer provider unchanged.');
S.cooling.gsut_load_kW = phase2_parameter(1095,'kW',doc,loc,verified,'High','Source load loss at 515 MVA; numerical transformer provider unchanged.');
cooling = S.cooling.gsut_total_kW.value-S.cooling.gsut_no_load_kW.value-S.cooling.gsut_load_kW.value;
S.cooling.gsut_cooling_kW = phase2_parameter(cooling,'kW',doc,loc, ...
    'DERIVED_FROM_VERIFIED_DATA','High arithmetic / source-qualified', ...
    'Residual source cooling loss, not added to frozen LF demand or transformer losses; auxiliary overlap unresolved.', ...
    'source_status',verified,'derivation','1282 - 159 - 1095','interpretation_status','QUALIFIED');
end
'@
Write-Output 'Restored original generator with scoped replacement; wrote three new runtime files without editor formatting.'
