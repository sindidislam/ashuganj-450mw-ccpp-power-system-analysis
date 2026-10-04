function out = convert_to_system_base(value, from_base_MVA, to_base_MVA, ...
                                     from_base_kV, to_base_kV)
%CONVERT_TO_SYSTEM_BASE  Per-unit base conversion for impedances.
%
%   Zpu_new = CONVERT_TO_SYSTEM_BASE(Zpu_old, Sold_MVA, Snew_MVA)
%       Converts a per-unit impedance from one MVA base to another at the
%       SAME voltage base:
%           Zpu_new = Zpu_old * (Snew/Sold)
%
%   Zpu_new = CONVERT_TO_SYSTEM_BASE(Zpu_old, Sold_MVA, Snew_MVA, Vold_kV, Vnew_kV)
%       Converts across both bases:
%           Zpu_new = Zpu_old * (Snew/Sold) * (Vold/Vnew)^2
%
%   Both forms follow directly from Z_base = V_base^2 / S_base.
%
%   WHY THIS MATTERS HERE
%   ---------------------
%   Every transformer impedance in this project is quoted on its OWN rating:
%       GSUT  16.0 %  at 515 MVA
%       UAT   10.5 %  at  25 MVA
%       GAT   12.0 %  at  25 MVA
%   and the generator reactances are on the machine's own 458 MVA / 22 kV
%   base.  The reporting base is 100 MVA (approved answer Q11a).  Mixing
%   these silently is one of the classic ways a load flow produces confident
%   nonsense: 10.5 % on 25 MVA is 42 % on 100 MVA, a factor of four.
%
%   NOTE ON THE SIMULINK MODEL
%   --------------------------
%   The Specialized Power Systems transformer block is given its impedance in
%   per unit ON ITS OWN NOMINAL POWER, which is exactly how the nameplates
%   quote it, so NO conversion is applied when populating the blocks.  This
%   function exists for REPORTING - producing the 100 MVA figures quoted in
%   the tables - and for the independent Newton-Raphson cross-check, which
%   does need a single common base.  Applying it to the block parameters
%   would double-convert and is guarded against by the tests.
%
%   EXAMPLES
%       convert_to_system_base(0.105, 25, 100)          % UAT -> 100 MVA
%       ans = 0.4200
%       convert_to_system_base(0.16, 515, 100)          % GSUT -> 100 MVA
%       ans = 0.03107
%
%   See also ASHUGANJ_MASTER_DATA, ASHUGANJ_TRANSFORMERS.

narginchk(3,5);

validateattributes(value, {'numeric'}, {'real','finite'}, mfilename, 'value', 1);
validateattributes(from_base_MVA, {'numeric'}, {'real','positive','finite','scalar'}, ...
    mfilename, 'from_base_MVA', 2);
validateattributes(to_base_MVA, {'numeric'}, {'real','positive','finite','scalar'}, ...
    mfilename, 'to_base_MVA', 3);

out = value * (to_base_MVA/from_base_MVA);

if nargin == 5
    validateattributes(from_base_kV, {'numeric'}, {'real','positive','finite','scalar'}, ...
        mfilename, 'from_base_kV', 4);
    validateattributes(to_base_kV, {'numeric'}, {'real','positive','finite','scalar'}, ...
        mfilename, 'to_base_kV', 5);
    out = out * (from_base_kV/to_base_kV)^2;
elseif nargin == 4
    error('convert_to_system_base:voltageBasePair', ...
        ['A voltage base conversion needs BOTH the old and the new voltage ', ...
         'base. Supplying only one silently drops the (V_old/V_new)^2 ', ...
         'factor, which is precisely the error this function exists to ', ...
         'prevent. Pass 3 arguments for an MVA-only conversion, or 5 for both.']);
end
end
