function Tc = phase5_ct_table(T, ratio, tag)
%PHASE5_CT_TABLE  Stamp secondary currents onto an import table (Phase-5 Task 4).
%   Tc = PHASE5_CT_TABLE(T, ratio, tag) copies table T (phase5_import output,
%   must carry I_primary_A in A) and adds columns:
%     I_secondary_A = I_primary_A / ratio
%     ct_ratio      scalar ratio stamped per row
%     ct_tag        'PRIMARY-15000/1' (ratio 15000) or 'LEGACY-16000/1' (16000)
%   tag must match ratio or this errors (16000 fenced to LEGACY scope).
%   Conversion itself delegates to phase5_ct (single source of truth).
%   All errors are 'phase5'-prefixed.
if nargin ~= 3
    error('phase5_ct_table:args', 'usage: Tc = phase5_ct_table(T, ratio, tag).');
end
if ~istable(T) || ~any(strcmp(T.Properties.VariableNames, 'I_primary_A'))
    error('phase5_ct_table:schema', 'T must be a table with I_primary_A column.');
end
if ~isnumeric(ratio) || ~isscalar(ratio) || ~isreal(ratio) ...
        || ~isfinite(ratio) || (ratio ~= 15000 && ratio ~= 16000)
    error('phase5_ct_table:ratio', 'ratio must be 15000 (PRIMARY) or 16000 (LEGACY).');
end
if ~(ischar(tag) || (isstring(tag) && isscalar(tag)))
    error('phase5_ct_table:tag', 'tag must be char ''PRIMARY-15000/1'' or ''LEGACY-16000/1''.');
end
tag = char(tag);
if ratio == 15000
    want = 'PRIMARY-15000/1';
else
    want = 'LEGACY-16000/1';
end
if ~strcmp(tag, want)
    error('phase5_ct_table:tag', 'tag ''%s'' mismatches ratio %d (want ''%s'').', tag, ratio, want);
end
S = phase5_ct(T.I_primary_A, ratio);
Tc = T;
Tc.I_secondary_A = S.Isec_A(:);
Tc.ct_ratio = repmat(ratio, height(T), 1);
Tc.ct_tag = repmat({tag}, height(T), 1);
end
