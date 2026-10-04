function S = phase5_ct(I_primary_A, ct_ratio)
%PHASE5_CT  Primary-to-secondary CT conversion (Phase-5 Task 4).
%   S = PHASE5_CT(I_primary_A, ct_ratio) returns struct S with
%     .I_primary_A  input primary current in A (preserved shape)
%     .ct_ratio     CT ratio scalar (15000 primary, 16000 legacy)
%     .Isec_A       = I_primary_A / ct_ratio (secondary current in A)
%
%   CT ledger (locked): 15000/1 primary SOURCE-BACKED (Siemens protection
%   report); 16000/1 LEGACY fenced sensitivity only; 2000/1 STUDY CTs live
%   in the registry. Fencing lives in ct_tag/scope/provenance (see
%   PHASE5_CT_TABLE), never in this arithmetic: any real finite ratio > 0
%   is accepted here.
%   Zero primary gives zero secondary (never Inf). Negative primary errors.
%   All errors are 'phase5'-prefixed.
if nargin ~= 2
    error('phase5_ct:args', 'usage: S = phase5_ct(I_primary_A, ct_ratio).');
end
if ~isnumeric(I_primary_A) || ~isreal(I_primary_A) || isempty(I_primary_A) ...
        || any(~isfinite(I_primary_A(:)))
    error('phase5_ct:primary', 'I_primary_A must be real finite numeric (A).');
end
if any(I_primary_A(:) < 0)
    error('phase5_ct:primary', 'I_primary_A must be >= 0 (no negative primary).');
end
if ~isnumeric(ct_ratio) || ~isscalar(ct_ratio) || ~isreal(ct_ratio) ...
        || ~isfinite(ct_ratio) || ct_ratio <= 0
    error('phase5_ct:ratio', 'ct_ratio must be a real finite scalar > 0 (e.g. 15000 PRIMARY, 16000 LEGACY, 2000/1 STUDY).');
end
S = struct('I_primary_A', I_primary_A, 'ct_ratio', ct_ratio, ...
    'Isec_A', I_primary_A / ct_ratio);
end
