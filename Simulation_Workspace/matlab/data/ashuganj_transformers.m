function T = ashuganj_transformers()
%ASHUGANJ_TRANSFORMERS  Transformer database - Ashuganj 450 MW CCPP SOUTH.
%
%   T = ASHUGANJ_TRANSFORMERS() returns a struct array with one element per
%   power transformer, populated for the Specialized Power Systems
%   "Three-Phase Transformer (Two Windings)" block in PER-UNIT units.
%
%   Three transformers exist in the South plant:
%       GSUT 10BAT10   230/22   kV   355/460/515 MVA  ONAN/ODAN/ODAF  YNd1
%       UAT  10BBT10    22/6.9  kV    19/25     MVA  ONAN/ONAF       Dyn11
%       GAT  10BBT20   230/6.9/3.32 kV  19/25   MVA  ONAN/ONAF       YNyn0+d11
%
%   The GAT was ABSENT from the prior CYME PSAF model (defect D6).  Its
%   presence closes a loop: 230 kV -> GSUT -> 22 kV -> UAT -> 6.6 kV -> GAT ->
%   230 kV.  Approved answer Q4c keeps BOTH states (GAT in / GAT out) as
%   separate load-flow cases so the loop effect can be reported.
%
%   -------- Impedance convention -------------------------------------
%   Nameplates give the magnitude Z (%) and the resistance R (%) at a stated
%   MVA base.  The reactance is therefore DERIVED, not read:
%       X = sqrt(Z^2 - R^2)                                   [pu]
%   and is split equally between the two windings, R1 = R2 = R/2 and
%   L1 = L2 = X/2, because the nameplate gives only the total leakage
%   impedance and no winding-by-winding split exists in the source set.
%   The equal split is a REPRESENTATION CHOICE, not a claimed measurement;
%   in a two-winding load flow only the series total R + jX affects the
%   result, so the split has no numerical consequence at all.
%
%   -------- Magnetising branch ---------------------------------------
%   BOTH magnetising elements are now DERIVED from documented data.
%
%   Rm from the documented no-load LOSS:
%       Rm(pu) = S_rated / P_no-load
%   Lm from the documented no-load CURRENT, by removing the loss
%   component that Rm already carries:
%       (1/Lm)^2 = I0^2 - (1/Rm)^2        =>  Lm = 1/sqrt(I0^2 - (1/Rm)^2)
%   with I0 the datasheet excitation current at 100 % rated voltage, in pu
%   of rated current on the same MVA base as Rm and Z.
%
%   HISTORY - this replaces an earlier treatment that set Lm = 1e6 pu
%   (numerically open) on the stated ground that "no-load current is absent
%   from every nameplate in the set".  That claim was true of the rating
%   PLATES and false of the DATA SHEETS: the GSUT sheet publishes 0.13 %
%   and the UAT/GAT sheet publishes ~0.3 % and 0.3 %.  The assumption was
%   written before those two documents had been read.  It is retired, not
%   tweaked; matlab/data/assumptions/transformer_magnetising_inductance.m
%   is kept as a SUPERSEDED record of the error rather than deleted.
%
%   Effect of the correction, stated as two DIFFERENT quantities so they
%   are not confused:
%     - magnetising reactive draw now represented, which the open-circuit
%       treatment omitted entirely:  0.650 + 0.074 + 0.071 = 0.795 MVAr
%       (S_rating/Lm per unit, at 1.0 pu terminal voltage);
%     - the resulting shift in the GENERATOR's reactive output is smaller
%       than that, because the machine is a PV bus and the 230 kV swing
%       supplies part of the extra demand.  It is MEASURED, not asserted,
%       by matlab/tests/test_magnetising_sensitivity.m.  The retired
%       assumption's published worst case of +3.4406 MVAr on that same
%       generator quantity was taken at a 1 % magnetising current, i.e.
%       7.7x the GSUT's documented 0.13 %, so it bounded the error safely
%       but very loosely.
%
%   The documented load loss independently CORROBORATES the documented R:
%       GSUT  1095 kW / 515 MVA = 0.2126 %  vs nameplate 0.21 %  (+1.2 %)
%       UAT    110 kW /  25 MVA = 0.4400 %  vs nameplate 0.40 %  (+10 %)
%       GAT    116 kW /  25 MVA = 0.4640 %  vs nameplate 0.50 %  (-7.2 %)
%   The nameplate R is used; the load-loss figure is retained as the
%   cross-check and the spread is reported.
%
%   See also ASHUGANJ_MASTER_DATA, CONVERT_TO_SYSTEM_BASE.

k = 0; T = struct([]);

% =====================================================================
% 1.  GSUT 10BAT10 - Generator Step-Up Transformer
% =====================================================================
k=k+1;
T(k).Name              = 'GSUT';
T(k).Label             = 'GSUT 10BAT10';
T(k).KKS               = '10BAT10';
T(k).Role              = 'Generator step-up';
T(k).Bus_HV            = 'B230_1';
T(k).Bus_LV            = 'B22';
T(k).Model_included    = true;

T(k).V_HV_V            = 230000;
T(k).V_HV_Status       = 'VERIFIED_PLANT';
T(k).V_LV_V            = 22000;
T(k).V_LV_Status       = 'VERIFIED_PLANT';
T(k).V_Source          = 'GSUT rating plate (3 released plates) + SLD Rev 03';

% Cooling stages.  All three are nameplate ratings of the SAME unit.
T(k).Cooling           = {'ONAN','ODAN','ODAF'};
T(k).S_MVA             = [355, 460, 515];
T(k).S_Status          = 'VERIFIED_PLANT';
T(k).S_Source          = 'GSUT rating plate - ONAN/ODAN/ODAF 355/460/515 MVA';
T(k).S_rating_MVA      = 515;      % base of the impedance data
T(k).S_rating_Note     = ['515 MVA (ODAF) is the base on which Z = 16 %% is ', ...
                          'quoted.  Transformer LOADING is reported against ', ...
                          'ALL THREE stages (approved answer Q11a), because ', ...
                          'a flow that is 89 %% of ODAF is 129 %% of ONAN.'];

T(k).f_Hz              = 50;
T(k).f_Status          = 'VERIFIED_PLANT';

T(k).VectorGroup       = 'YNd1';
T(k).VectorGroup_Status= 'VERIFIED_PLANT';
T(k).Conn_HV           = 'Yg';              % YN - solidly earthed star
T(k).Conn_LV           = 'Delta (D1)';      % d1
T(k).Conn_Note         = ['YNd1: HV star with earthed neutral, LV delta ', ...
                          'lagging the HV by 30 deg.  In SPS the LV ', ...
                          'connection "Delta (D1)" is the D1 (lagging) ', ...
                          'variant.  The phase shift is confirmed ', ...
                          'empirically by matlab/tests/test_transformer_phase_shift.m ', ...
                          'rather than assumed from the block name.  A ', ...
                          '+/-30 deg shift moves REPORTED ANGLES only; it ', ...
                          'can never change a magnitude or a power flow in ', ...
                          'a balanced load flow.'];

% Impedance data at 515 MVA
T(k).Z_pct             = 16.0;
T(k).Z_Status          = 'VERIFIED_ENGINEERING_DOCUMENT';
T(k).Z_Source          = ['Engineering document, principal tap 9.  NOTE: the ', ...
                          'impedance field on all three released GSUT ', ...
                          'RATING PLATES is genuinely BLANK - the plates do ', ...
                          'not carry it.  That blank is recorded as ', ...
                          'NOT_APPLICABLE, not as MISSING.'];
T(k).R_pct             = 0.21;
T(k).R_Status          = 'VERIFIED_ENGINEERING_DOCUMENT';
T(k).Z0_pct            = 15.8;
T(k).Z0_Status         = 'VERIFIED_ENGINEERING_DOCUMENT';
T(k).Z0_Note           = 'Zero sequence - retained for the later earth-fault study.';

T(k).P_noload_kW       = 159;
T(k).P_noload_Status   = 'VERIFIED_ENGINEERING_DOCUMENT';
T(k).P_load_kW         = [523, 874, 1095];   % per cooling stage
T(k).P_load_Status     = 'VERIFIED_ENGINEERING_DOCUMENT';
T(k).I_noload_pct      = 0.13;
T(k).I_noload_Status   = 'VERIFIED_ENGINEERING_DOCUMENT';
T(k).I_noload_Source   = ['GSUT Data Sheet_South.pdf (S009-112070-00-ELC-HD-0001 ', ...
                          'Rev 00, Siemens Transformer Guangzhou, 24.02.14), ', ...
                          '"Excitation current - at 100% of the rated voltage".'];
T(k).I_noload_Note     = ['Datasheet also gives 0.15 % at 105 % and 0.18 % at ', ...
                          '110 % rated voltage. The row carries the datasheet''s ', ...
                          'own *) marker: "might be subject due change after ', ...
                          'finalizing the transformer''s detailed design".'];

% Tap changer.  Q8a approved: PRINCIPAL tap, not an optimised tap.
T(k).Tap_type          = 'OLTC on HV';
T(k).Tap_positions     = 25;
T(k).Tap_principal     = 9;
T(k).Tap_V_max_V       = 253000;    % position 1
T(k).Tap_V_min_V       = 184000;    % position 25
T(k).Tap_step_V        = 2875;      % 1.25 % of 230 kV
T(k).Tap_Status        = 'VERIFIED_PLANT';
T(k).Tap_used          = 9;
T(k).Tap_V_used_V      = 230000;
T(k).Tap_Note          = ['Position n gives 253000 - (n-1)*2875 V, so ', ...
                          'position 9 = 253000 - 8*2875 = 230000 V exactly. ', ...
                          'At the principal tap the modelled ratio is ', ...
                          'therefore precisely nominal 230/22 kV and no ', ...
                          'off-nominal ratio correction is needed.  Z at ', ...
                          'the tap extremes is documented as 16.9 %% ', ...
                          '(pos 1) and 15.5 %% (pos 25); those are NOT ', ...
                          'used, because the taps are not being moved.'];

% =====================================================================
% 2.  UAT 10BBT10 - Unit Auxiliary Transformer
% =====================================================================
k=k+1;
T(k).Name              = 'UAT';
T(k).Label             = 'UAT 10BBT10';
T(k).KKS               = '10BBT10';
T(k).Role              = 'Unit auxiliary';
T(k).Bus_HV            = 'B22';
T(k).Bus_LV            = 'B6_6';
T(k).Model_included    = true;

T(k).V_HV_V            = 22000;
T(k).V_HV_Status       = 'VERIFIED_PLANT';
T(k).V_LV_V            = 6900;
T(k).V_LV_Status       = 'VERIFIED_PLANT';
T(k).V_Source          = 'UAT rating plate - 22/6.9 kV';
T(k).V_LV_Note         = ['CONFLICT C13, PRESERVED not resolved: the winding ', ...
                          'is rated 6900 V but the switchgear it feeds is ', ...
                          'nominally 6600 V (Um 7.2 kV).  Both are correct ', ...
                          'statements about different things - 6900 V is the ', ...
                          'transformer winding, 6600 V is the system ', ...
                          'nominal.  The NAMEPLATE value 6900 V is entered ', ...
                          'in the block, because that is what the ', ...
                          'transformer physically is.  Per-unit reporting at ', ...
                          'the MV bus uses 6600 V.  Entering 6600 V as the ', ...
                          'winding voltage instead would raise the modelled ', ...
                          'MV bus voltage by about 4.5 %% - a pure ', ...
                          'modelling error, not an engineering result.'];

T(k).Cooling           = {'ONAN','ONAF'};
T(k).S_MVA             = [19, 25];
T(k).S_Status          = 'VERIFIED_PLANT';
T(k).S_Source          = 'UAT rating plate - ONAN/ONAF 19/25 MVA';
T(k).S_rating_MVA      = 25;

T(k).f_Hz              = 50;
T(k).f_Status          = 'VERIFIED_PLANT';

T(k).VectorGroup       = 'Dyn11';
T(k).VectorGroup_Status= 'VERIFIED_PLANT';
T(k).Conn_HV           = 'Delta (D1)';
T(k).Conn_LV           = 'Yg';
T(k).Conn_Note         = ['Dyn11: HV delta, LV star with earthed neutral, LV ', ...
                          'LEADING the HV by 30 deg.  SPS expresses the ', ...
                          'shift on the delta winding, so a Dyn11 is built ', ...
                          'as HV = "Delta (D1)" with LV = "Yg".  This ', ...
                          'reading of the SPS convention is CONFIRMED ', ...
                          'EMPIRICALLY by matlab/tests/test_transformer_phase_shift.m; ', ...
                          'it is not taken on trust from the block name.'];

T(k).Z_pct             = 10.5;
T(k).Z_Status          = 'VERIFIED_PLANT';
T(k).Z_Source          = 'UAT rating plate, principal tap 3, at 25 MVA';
T(k).R_pct             = 0.4;
T(k).R_Status          = 'VERIFIED_PLANT';
T(k).Z0_pct            = 9.3;
T(k).Z0_Status         = 'VERIFIED_PLANT';
T(k).Z0_Note           = 'Zero sequence - retained for the later earth-fault study.';

T(k).P_noload_kW       = 14;
T(k).P_noload_Status   = 'VERIFIED_PLANT';
T(k).P_load_kW         = 110;
T(k).P_load_Status     = 'VERIFIED_PLANT';
T(k).I_noload_pct      = 0.3;
T(k).I_noload_Status   = 'VERIFIED_ENGINEERING_DOCUMENT';
T(k).I_noload_Source   = ['UAT  Data Sheet_South.pdf (S009-112070-00-ELC-HD-1001 ', ...
                          'Rev 00 / Siemens STWH-579UAT-0007, Wuhan, 27.03.14) ', ...
                          'section 1.1, "Excitation current - at 100% of the ', ...
                          'rated voltage", p.5.'];
T(k).I_noload_Note     = ['Datasheet prints "~0.3", i.e. approximate in the ', ...
                          'source. Also ~0.4 % at 105 % and ~0.5 % at 110 %.'];

T(k).Tap_type          = 'Off-circuit on HV';
T(k).Tap_positions     = 5;
T(k).Tap_principal     = 3;
T(k).Tap_V_max_V       = 23100;     % +5 %
T(k).Tap_V_min_V       = 20900;     % -5 %
T(k).Tap_step_V        = 550;       % 2.5 % of 22 kV
T(k).Tap_Status        = 'VERIFIED_PLANT';
T(k).Tap_used          = 3;
T(k).Tap_V_used_V      = 22000;
T(k).Tap_Note          = ['Principal tap 3 = 22000 V, i.e. nominal ratio. ', ...
                          'Off-circuit tap: it CANNOT be moved under load, ', ...
                          'so treating it as a fixed nominal ratio is not ', ...
                          'merely an approved choice (Q8a) but a physical ', ...
                          'fact of the equipment.'];

% =====================================================================
% 3.  GAT 10BBT20 - Grid / Station Auxiliary Transformer
% =====================================================================
k=k+1;
T(k).Name              = 'GAT';
T(k).Label             = 'GAT 10BBT20';
T(k).KKS               = '10BBT20';
T(k).Role              = 'Grid (station) auxiliary';
T(k).Bus_HV            = 'B230_2';
T(k).Bus_LV            = 'B6_6';
T(k).Model_included    = true;      % switched per case - see ashuganj_master_data

T(k).V_HV_V            = 230000;
T(k).V_HV_Status       = 'VERIFIED_PLANT';
T(k).V_LV_V            = 6900;
T(k).V_LV_Status       = 'VERIFIED_PLANT';
T(k).V_TV_V            = 3320;      % tertiary - NOT modelled, see Q5a
T(k).V_TV_Status       = 'VERIFIED_PLANT';
T(k).V_Source          = 'GAT rating plate - 230/6.9/3.32 kV';

T(k).Cooling           = {'ONAN','ONAF'};
T(k).S_MVA             = [19, 25];
T(k).S_Status          = 'VERIFIED_PLANT';
T(k).S_Source          = 'GAT rating plate - ONAN/ONAF 19/25 MVA';
T(k).S_rating_MVA      = 25;
T(k).S_windings_MVA    = [25, 25, 8.33];   % HV / LV / tertiary
T(k).S_windings_Status = 'VERIFIED_PLANT';

T(k).f_Hz              = 50;
T(k).f_Status          = 'VERIFIED_PLANT';

T(k).VectorGroup       = 'YNyn0+d11';
T(k).VectorGroup_Status= 'VERIFIED_PLANT';
T(k).Conn_HV           = 'Yg';
T(k).Conn_LV           = 'Yg';
T(k).Conn_Note         = ['YNyn0: both HV and LV star with earthed neutral, ', ...
                          'zero phase shift.  The +d11 stabilising tertiary ', ...
                          'is OMITTED - approved answer Q5a.'];

T(k).Z_pct             = 12.0;      % positive sequence HV-LV
T(k).Z_Status          = 'VERIFIED_PLANT';
T(k).Z_Source          = 'GAT rating plate - Z_PS = 12 % at 25 MVA, principal tap 13';
T(k).R_pct             = 0.5;
T(k).R_Status          = 'VERIFIED_PLANT';
T(k).Z0_pct            = 10.8;
T(k).Z0_Status         = 'VERIFIED_PLANT';
T(k).Z_PT_pct          = NaN;       % HV-tertiary
T(k).Z_PT_Status       = 'MISSING';
T(k).Z_ST_pct          = NaN;       % LV-tertiary
T(k).Z_ST_Status       = 'MISSING';
T(k).Tertiary_Note     = ['Q5a approved: use the documented positive-', ...
                          'sequence two-winding representation and OMIT the ', ...
                          'unloaded stabilising tertiary.  Z_PT and Z_ST are ', ...
                          'MISSING, so a three-winding SPS block could only ', ...
                          'be filled by inventing two impedances.  The ', ...
                          'omission is exact for a BALANCED load flow: an ', ...
                          'unloaded delta tertiary carries no positive-', ...
                          'sequence current.  It is NOT exact for the later ', ...
                          'earth-fault study, and that limitation is ', ...
                          'recorded in the readiness document.'];

T(k).P_noload_kW       = 23;
T(k).P_noload_Status   = 'VERIFIED_PLANT';
T(k).P_load_kW         = 116;
T(k).P_load_Status     = 'VERIFIED_PLANT';
T(k).I_noload_pct      = 0.3;
T(k).I_noload_Status   = 'VERIFIED_ENGINEERING_DOCUMENT';
T(k).I_noload_Source   = ['UAT  Data Sheet_South.pdf (S009-112070-00-ELC-HD-1001 ', ...
                          'Rev 00 / Siemens STWH-580GAT-0007, Wuhan, 27.03.14) ', ...
                          'section 2.1, "Excitation current - at 100% of the ', ...
                          'rated voltage", p.16.'];
T(k).I_noload_Note     = ['Printed as a firm 0.3 % at 100 % (the 105 % and ', ...
                          '110 % figures ~0.5 % and ~0.8 % are approximate).'];

T(k).Tap_type          = 'OLTC on HV';
T(k).Tap_positions     = 25;
T(k).Tap_principal     = 13;
T(k).Tap_V_max_V       = 264500;    % position 1
T(k).Tap_V_min_V       = 195500;    % position 25
T(k).Tap_step_V        = 2875;      % 1.25 % of 230 kV
T(k).Tap_Status        = 'VERIFIED_PLANT';
T(k).Tap_used          = 13;
T(k).Tap_V_used_V      = 230000;
T(k).Tap_Note          = ['Position n gives 264500 - (n-1)*2875 V, so ', ...
                          'position 13 = 264500 - 34500 = 230000 V exactly. ', ...
                          'CONFLICT C10 lives in this tap table: the OCR of ', ...
                          'position 14 read "227275 V", but the printed tap ', ...
                          'current 63.5 A implies 227125 V, which is also ', ...
                          'what the 2875 V step gives.  227125 V is used and ', ...
                          'the OCR artefact is recorded.  Position 14 is not ', ...
                          'the operating tap, so this conflict does not ', ...
                          'affect any load-flow result.'];

% =====================================================================
% Derived quantities - computed here, never typed in by hand
% =====================================================================
for i = 1:numel(T)
    Zpu = T(i).Z_pct/100;
    Rpu = T(i).R_pct/100;

    assert(Rpu < Zpu, ['ashuganj_transformers: %s has R >= Z, so X would be ', ...
        'imaginary. Check the nameplate transcription.'], T(i).Name);

    T(i).X_pu               = sqrt(Zpu^2 - Rpu^2);
    T(i).X_pct              = 100*T(i).X_pu;
    T(i).X_Status           = 'DERIVED_FROM_VERIFIED_DATA';
    T(i).X_Derivation       = 'X = sqrt(Z^2 - R^2) from nameplate Z and R';
    T(i).R_pu               = Rpu;
    T(i).Z_pu               = Zpu;
    T(i).XR_ratio           = T(i).X_pu/Rpu;
    T(i).XR_Status          = 'DERIVED_FROM_VERIFIED_DATA';

    % Equal winding split for the SPS two-winding block.
    T(i).R1_pu              = Rpu/2;
    T(i).R2_pu              = Rpu/2;
    T(i).L1_pu              = T(i).X_pu/2;
    T(i).L2_pu              = T(i).X_pu/2;
    T(i).Split_Status       = 'DERIVED_FROM_VERIFIED_DATA';
    T(i).Split_Note         = ['Equal split. Only the series total R + jX ', ...
                               'affects a two-winding load flow, so the ', ...
                               'split is numerically inconsequential.'];

    % Magnetising resistance from the documented no-load loss.
    T(i).Rm_pu              = T(i).S_rating_MVA*1000/T(i).P_noload_kW;
    T(i).Rm_Status          = 'DERIVED_FROM_VERIFIED_DATA';
    T(i).Rm_Derivation      = 'Rm(pu) = S_rated / P_no-load, both documented';

    % Magnetising inductance from the documented no-load CURRENT.
    % I0 is the total excitation current; Rm already accounts for its
    % loss component, so the magnetising component is what is left after
    % removing it in quadrature.
    I0_pu = T(i).I_noload_pct/100;
    T(i).Lm_pu              = 1/sqrt(I0_pu^2 - (1/T(i).Rm_pu)^2);
    T(i).Lm_Status          = 'DERIVED_FROM_VERIFIED_DATA';
    T(i).Lm_Derivation      = 'Lm(pu) = 1/sqrt(I0^2 - (1/Rm)^2), I0 = datasheet excitation current at 100% Un';
    T(i).Lm_Note            = ['Derived from the datasheet excitation current ', ...
                               '(GSUT 0.13 %, UAT ~0.3 %, GAT 0.3 % of rated ', ...
                               'current at 100 % rated voltage), NOT assumed. ', ...
                               'The only reading applied is the IEC convention ', ...
                               'that "excitation current" is the total RMS ', ...
                               'no-load current at rated voltage on the rated ', ...
                               'MVA base - the same base as Rm and Z. ', ...
                               'SUPERSEDES the retired assumption Lm = 1e6 pu; ', ...
                               'see matlab/data/assumptions/transformer_magnetising_inductance.m'];

    % Sanity guard: the loss component can never exceed the total current.
    if ~isreal(T(i).Lm_pu) || ~isfinite(T(i).Lm_pu) || T(i).Lm_pu <= 0
        error('ashuganj_transformers:LmDerivation', ...
            ['%s: no-load current %.3f %% is not larger than the loss ', ...
             'component 1/Rm = %.5f pu, so Lm cannot be derived. Check ', ...
             'that I_noload_pct and P_noload_kW share one MVA base.'], ...
            T(i).Name, T(i).I_noload_pct, 1/T(i).Rm_pu);
    end

    % Zero-sequence inductance for the SPS block (L0). Documented as Z0 %.
    % Not used by a balanced load flow; carried so the block is complete
    % and the later fault study inherits it.
    T(i).L0_pu              = T(i).Z0_pct/100;
    T(i).L0_Status          = 'VERIFIED_PLANT';
    T(i).L0_Note            = ['Entered from the documented Z0. Has NO effect ', ...
                               'on a balanced positive-sequence load flow.'];

    % Load-loss cross-check on R.
    Pl = T(i).P_load_kW(end);           % highest cooling stage
    T(i).R_from_loadloss_pct = 100*Pl/(T(i).S_rating_MVA*1000);
    T(i).R_crosscheck_err_pct = 100*(T(i).R_from_loadloss_pct - T(i).R_pct)/T(i).R_pct;
    T(i).R_crosscheck_Status  = 'DERIVED_FROM_VERIFIED_DATA';
    T(i).R_crosscheck_Note    = ['Independent check: R(%%) = P_load / S_rated. ', ...
                                 'The NAMEPLATE R is the value used; this ', ...
                                 'figure only tests it.'];

    % SPS block wiring
    T(i).Model_block        = 'sps_lib/Power Grid Elements/Three-Phase Transformer (Two Windings)';
    T(i).Model_units        = 'pu';
    T(i).Model_coretype     = 'Three single-phase transformers';
    T(i).Model_coretype_Note= ['The physical core construction is NOT ', ...
                               'documented for any of the three units. The ', ...
                               'SPS default "Three single-phase ', ...
                               'transformers" is retained because it is the ', ...
                               'only choice that does NOT impose an ', ...
                               'undocumented magnetic coupling between ', ...
                               'phases. It is IRRELEVANT to a balanced load ', ...
                               'flow (all three phases are identical and ', ...
                               'symmetric); it would matter for the later ', ...
                               'unbalanced-fault study.'];
    T(i).Model_saturation   = 'off';
end

% ------------------------------------------------------------------------
% Integrity assertions
% ------------------------------------------------------------------------
names = {T.Name};
assert(numel(unique(names)) == numel(T), 'ashuganj_transformers: duplicate name.');
for i = 1:numel(T)
    % Recover Z from the split to prove the algebra is self-consistent.
    Zback = hypot(T(i).R1_pu+T(i).R2_pu, T(i).L1_pu+T(i).L2_pu);
    assert(abs(Zback - T(i).Z_pu) < 1e-12, ...
        'ashuganj_transformers: %s impedance algebra is inconsistent.', T(i).Name);
    assert(T(i).V_HV_V > T(i).V_LV_V, ...
        'ashuganj_transformers: %s HV/LV voltages look swapped.', T(i).Name);
    assert(T(i).V_HV_V <= 230000, ...
        'ashuganj_transformers: %s exceeds 230 kV. No 400 kV in South scope.', T(i).Name);
    assert(T(i).f_Hz == 50, ...
        'ashuganj_transformers: %s is not at 50 Hz.', T(i).Name);
    assert(T(i).Tap_used == T(i).Tap_principal, ...
        ['ashuganj_transformers: %s is not on its principal tap. Approved ', ...
         'answer Q8a requires the documented principal tap.'], T(i).Name);
    % Principal tap must reproduce the nominal HV voltage.
    Vtap = T(i).Tap_V_max_V - (T(i).Tap_principal-1)*T(i).Tap_step_V;
    assert(abs(Vtap - T(i).V_HV_V) < 1, ...
        ['ashuganj_transformers: %s principal tap %d gives %g V but nominal ', ...
         'HV is %g V.'], T(i).Name, T(i).Tap_principal, Vtap, T(i).V_HV_V);
end
end
