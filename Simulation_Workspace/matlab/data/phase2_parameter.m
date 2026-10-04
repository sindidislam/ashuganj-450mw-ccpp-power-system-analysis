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
