function B = sps_blocks()
%SPS_BLOCKS  Verified Specialized Power Systems library paths, MATLAB R2024a.
%
%   B = SPS_BLOCKS() returns a struct of library paths for every block used
%   by this project.
%
%   WHY THIS FILE EXISTS
%   --------------------
%   In R2024a the classic 'powerlib' library is an EMPTY NAVIGATION STUB: its
%   sublibraries are masked SubSystem blocks with LinkStatus 'none' and no
%   contents, so find_system('powerlib', ...) returns only seven objects and
%   every documented path of the form
%       powerlib/Fundamental Blocks/Elements/Three-Phase Transformer ...
%   fails with "Invalid Simulink object name".  The real library is
%       matlabroot/toolbox/physmod/powersys/library/sps_lib.slx
%   and the paths below were established EMPIRICALLY against the installed
%   version (see matlab/env/probe_powerlib5.m and its output), not taken from
%   documentation.
%
%   Several leaf names contain EMBEDDED NEWLINES, which is why char(10)
%   appears below.  Omitting them makes add_block fail.
%
%   Verified in: MATLAB 24.1.0.2537033 (R2024a), Simscape Electrical 24.1.

nl = char(10); %#ok<CHARTEN>

B.source        = 'sps_lib/Sources/Three-Phase Source';
B.tx2           = ['sps_lib/Power Grid Elements/Three-Phase' nl 'Transformer' nl '(Two Windings)'];
B.tx3           = ['sps_lib/Power Grid Elements/Three-Phase' nl 'Transformer' nl '(Three Windings)'];
B.load          = ['sps_lib/Passives/Three-Phase' nl 'Parallel RLC Load'];
B.series        = ['sps_lib/Passives/Three-Phase' nl 'Series RLC Branch'];
B.parallel      = ['sps_lib/Passives/Three-Phase' nl 'Parallel RLC Branch'];
B.breaker       = 'sps_lib/Power Grid Elements/Three-Phase Breaker';
B.fault         = 'sps_lib/Power Grid Elements/Three-Phase Fault';
B.pisection     = ['sps_lib/Power Grid Elements/Three-Phase' nl 'PI Section Line'];
B.vimeas        = ['sps_lib/Sensors and Measurements/Three-Phase' nl 'V-I Measurement'];
B.powergui      = 'sps_lib/powergui';
B.ground        = 'sps_lib/Utilities/Ground';
B.syncmachine   = ['sps_lib/Electrical Machines/Synchronous Machine' nl 'pu Standard'];

% Blocks deliberately NOT used, recorded so the reason is not lost:
B.NOT_USED.syncmachine = ['Requires x_q, armature resistance, inertia H and ', ...
    'four open-circuit time constants, all MISSING from the source set. A ', ...
    'balanced load flow needs none of them, so the generator is an ideal ', ...
    'PV source instead (treatment S1).'];
B.NOT_USED.tx3 = ['Would require Z_PT and Z_ST for the GAT tertiary, both ', ...
    'MISSING. Approved answer Q5a uses the documented positive-sequence ', ...
    'two-winding representation instead (treatment S2).'];
B.NOT_USED.pisection = ['Approved answer Q7a forbids inventing a ', ...
    'transmission line; the grid equivalent sits at the plant boundary.'];
B.NOT_USED.fault = 'Fault studies are out of scope in the current phase.';
end
