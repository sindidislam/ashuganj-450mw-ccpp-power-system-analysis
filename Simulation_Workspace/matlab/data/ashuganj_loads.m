function Ld = ashuganj_loads()
%ASHUGANJ_LOADS  Load database - Ashuganj 450 MW CCPP SOUTH.
%
%   Ld = ASHUGANJ_LOADS() returns a struct array of the auxiliary loads.
%
%   TOTAL AUXILIARY LOAD: 14 MW at 0.85 power factor.
%   ------------------------------------------------------------------
%   A WARNING about this number, carried from the audit: 14 MW happens to be
%   numerically equal to the UAT no-load loss expressed in kW (14 kW) and to
%   3.60 % of the 389.30 MW rated output.  Those are COINCIDENCES.  The 14 MW
%   is the documented plant auxiliary load; the 14 kW is the UAT iron loss.
%   They are unrelated quantities that share two digits, and the resemblance
%   was checked and dismissed during the audit rather than being allowed to
%   propagate as a transcription error.
%
%   ALLOCATION (approved answer Q6B): the load is DISTRIBUTED across three
%   6.6 kV nodes in the ratio 9050 : 2500 : 2500, which comes from the
%   documented motor ratings (kW) of the main auxiliary group and the two
%   water-intake / large-motor groups.  The RATIO is grounded in documented
%   motor ratings; the ALLOCATION OF THE 14 MW TOTAL ACROSS THAT RATIO IS AN
%   APPROVED ASSUMPTION, because no per-node metered demand exists.  The user
%   required this to be labelled an assumption and it is:
%       matlab/data/assumptions/aux_load_allocation_split.m
%
%   Because the 6.6 kV feeder impedances are MISSING (see ASHUGANJ_LINES),
%   the three nodes are joined with zero impedance.  The split therefore
%   segregates the load for REPORTING and for the later protection study; it
%   does not produce feeder voltage drop.  Total P and Q drawn from the UAT
%   are identical to the single-bus case - that is a correctness property,
%   not a defect, and it is stated in the report.
%
%   POWER FACTOR: 0.85 lagging is applied to every node.  A per-node power
%   factor is NOT documented; using one figure for all three nodes avoids
%   inventing three.
%
%   LOAD MODEL: constant PQ.  A load flow that used constant impedance would
%   silently reduce the auxiliary demand whenever the solved voltage sagged,
%   which would flatter the result.  Constant PQ holds the documented demand.
%
%   See also ASHUGANJ_MASTER_DATA, ASHUGANJ_BUSES.

% ---- Documented totals -------------------------------------------------
P_total_MW  = 14.0;
P_Status    = 'VERIFIED_PROJECT_DATA';
P_Source    = 'Project data set - plant auxiliary load 14 MW';
pf          = 0.85;
pf_Status   = 'VERIFIED_PROJECT_DATA';
pf_Source   = 'Project data set - auxiliary load power factor 0.85 lagging';

Q_total_MVAr = P_total_MW*tan(acos(pf));

% ---- Allocation ratio from documented motor ratings (kW) ---------------
alloc_kW    = [9050, 2500, 2500];
alloc_nodes = {'B6_6', 'B6_6_WI1', 'B6_6_WI2'};
alloc_label = {'MV BUS aux group', 'Water intake / motor group 1', ...
               'Water intake / motor group 2'};
share       = alloc_kW/sum(alloc_kW);

k = 0; Ld = struct([]);
for i = 1:numel(alloc_nodes)
    k=k+1;
    Ld(k).Name             = ['LOAD_' alloc_nodes{i}];
    Ld(k).Label            = alloc_label{i};
    Ld(k).Bus              = alloc_nodes{i};
    Ld(k).Vnom_V           = 6600;
    Ld(k).Vnom_Status      = 'VERIFIED_ENGINEERING_DOCUMENT';
    Ld(k).Vnom_Note        = ['The load NOMINAL voltage is the 6.6 kV system ', ...
                              'nominal, not the 6.9 kV UAT winding voltage. ', ...
                              'These are different things (conflict C13) and ', ...
                              'both are used, each in its correct place.'];
    Ld(k).f_Hz             = 50;

    Ld(k).Alloc_kW         = alloc_kW(i);
    Ld(k).Alloc_Status     = 'VERIFIED_PROJECT_DATA';
    Ld(k).Alloc_Source     = 'Documented motor ratings, project data set';
    Ld(k).Share            = share(i);
    Ld(k).Share_Status     = 'DERIVED_FROM_VERIFIED_DATA';

    Ld(k).P_MW             = P_total_MW*share(i);
    Ld(k).P_Status         = 'ENGINEERING_ASSUMPTION';
    Ld(k).P_Source         = ['14 MW documented total apportioned by the ', ...
                              'documented motor-rating ratio ', ...
                              '9050:2500:2500. Approved answer Q6B.'];
    Ld(k).Q_MVAr           = Q_total_MVAr*share(i);
    Ld(k).Q_Status         = 'DERIVED_FROM_VERIFIED_DATA';
    Ld(k).Q_Source         = 'P * tan(acos(0.85)) with P as above';

    Ld(k).pf               = pf;
    Ld(k).pf_Status        = pf_Status;
    Ld(k).pf_Source        = pf_Source;

    Ld(k).Model_included   = true;
    Ld(k).Model_block      = 'sps_lib/Passives/Three-Phase Parallel RLC Load';
    Ld(k).LoadType         = 'constant PQ';
    Ld(k).Configuration    = 'Y (grounded)';
    Ld(k).Config_Status    = 'ENGINEERING_ASSUMPTION';
    Ld(k).Config_Note      = ['The 6.6 kV auxiliary system earthing ', ...
                              'arrangement is not documented in the ', ...
                              'available set. Y(grounded) is used. It has ', ...
                              'NO effect on a balanced load flow (no ', ...
                              'zero-sequence current flows in a balanced ', ...
                              'network); it WOULD matter for the later ', ...
                              'earth-fault study, and it is flagged there.'];
    Ld(k).C_MVAr           = 0;
    Ld(k).C_Status         = 'VERIFIED_PROJECT_DATA';
    Ld(k).C_Note           = ['No power-factor correction or capacitor bank ', ...
                              'appears anywhere in the source set, so none ', ...
                              'is modelled.'];
end

% ---- Documented loads NOT modelled ------------------------------------
k=k+1;
Ld(k).Name             = 'LOAD_B0_4';
Ld(k).Label            = '400 V LV board load';
Ld(k).Bus              = 'B0_4';
Ld(k).Vnom_V           = 400;              % FOUR HUNDRED VOLTS
Ld(k).Vnom_Status      = 'VERIFIED_ENGINEERING_DOCUMENT';
Ld(k).f_Hz             = 50;
Ld(k).P_MW             = NaN;
Ld(k).P_Status         = 'MISSING';
Ld(k).Q_MVAr           = NaN;
Ld(k).Q_Status         = 'MISSING';
Ld(k).Model_included   = false;
Ld(k).Exclusion_reason = ['The 6.6/0.4 kV unit-substation transformers are ', ...
                          'not characterised (C16), and the LV board demand ', ...
                          'is not separately documented. The LV load is ', ...
                          'already inside the 14 MW total and is therefore ', ...
                          'represented AT 6.6 kV. Nothing is lost from the ', ...
                          'power balance; what is lost is the LV voltage ', ...
                          'profile, which this study does not claim to ', ...
                          'produce.'];
Ld(k).Notes            = '400 V. FOUR HUNDRED VOLTS. Not 400 kV.';

% ------------------------------------------------------------------------
% Integrity assertions - the power balance must be exact
% ------------------------------------------------------------------------
inm = [Ld.Model_included];
assert(abs(sum([Ld(inm).P_MW]) - P_total_MW) < 1e-9, ...
    ['ashuganj_loads: allocated P (%.9f MW) does not sum to the documented ', ...
     'total (%.9f MW). The split must conserve the documented load.'], ...
     sum([Ld(inm).P_MW]), P_total_MW);
assert(abs(sum([Ld(inm).Q_MVAr]) - Q_total_MVAr) < 1e-9, ...
    'ashuganj_loads: allocated Q does not sum to the documented total.');
assert(abs(sum(share) - 1) < 1e-12, 'ashuganj_loads: shares do not sum to 1.');
assert(all([Ld(inm).P_MW] > 0), 'ashuganj_loads: non-positive load allocated.');
% Guard the 400 V / 400 kV rule at the point of entry.
assert(~any([Ld.Vnom_V] > 231000), ...
    'ashuganj_loads: a load above 231 kV was defined. 400 V is not 400 kV.');
end
