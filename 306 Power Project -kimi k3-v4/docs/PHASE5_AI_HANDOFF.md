# PHASE 5 FINAL HANDOFF

Status: READY_FOR_REVIEW

Final production command: `matlab -batch "addpath(genpath('matlab')); run_phase5b_production('final-engineering','overwrite',true);"`

Final test result: run_phase5b_tests() PASS = 528; FAIL = 0

Files modified: matlab/phase5 Phase-5b registry, pickup, coordination, duty, effectiveness, sensitivity, validation, TCC, writer and runner; updated Phase-5b regression suites. No Phase-2/3/4 files modified.

Exact code/test change inventory: docs/PHASE5_CHANGE_INVENTORY.csv, compared against tmp/phase5_final_audit/pre_final_correction.zip. Generated reports and output CSVs/plots are enumerated in the final manifest.

Files created: numerical parameter, physical-current, independent-arithmetic, cache, baseline/hash, artifact-finalization and final-report helpers; source audit/evidence; parameter/trip/TCC metadata outputs and final documentation.

Central engineering assumptions: GEN/GSUT/Q0/neutral TMS 0.10/0.55/0.80/0.15; CTs 15000/1600/1600/20; pickups 17170.8/1380/1500/4 A. Q0 remains conditional at 50 kA. Differential timing is a study proxy; no installed-setting claim.

Derived values: GSUT 1292.8 A nameplate and 1149.680101 A through-load anchor; 87G 2403.8 A; 87T 387.84 A; grid 2.950246 ohm from 45.01 kA; 188 numerical parameters generated from phase5b_parameters.

Sensitivity cases executed: GEN_NEUTRAL_CT, GEN_NEUTRAL_PICKUP, NER, GSUT_CT, GSUT_CT_FIXED_DIAL, GRID_STRENGTH, GRID_XR, GRID_ZERO, GRID_REPORTED_Z, GSUT_IMPEDANCE, GSUT_COPPER_LOSS, MOTOR, CT_SATURATION, BREAKER_RATING; 1793 numerical metric rows.

Important documentary conflicts:
- GSUT CT: manufacturer protection schedule indicates 1500/1; as-built SLD and later nameplate indicate 1600/1. Central study uses 1600/1 as ENGINEERING_ASSUMPTION. The installed function-to-core assignment remains unverified. 1500/1 is a calculated documentary sensitivity.
- GSUT impedance/loss: workbook study data give 16.63% and copper loss 912.2 kW (1067.5 minus 155.3 kW); manufacturer design sheet gives 16% and 1095 kW. The workbook-derived profile is the requested local Phase-5 study profile, not a claim that the OEM design sheet states those numbers.
- Grid: the secondary historical 45.01 kA, X/R 10.99 result implies |Z| about 2.9502 ohm at voltage factor c=1. Its reported 3.25 ohm uses an unverified convention; an implied c about 1.102 could explain the discrepancy. The requested c=1 derivation is central and 3.25 ohm is a numerical sensitivity. Neither is an official current PGCB equivalent.
- Grounding: the report marks 60 ohm as HV-winding DC resistance with a question mark and 2.62 ohm as the LV loading resistor with qualification. The frozen effective neutral resistance is 60 + n^2*2.62 ohm, where n=(22000/sqrt(3))/500. Treating 60 ohm alone as the effective neutral resistance would contradict the approximately 7.27 A central stator-earth fault.
- Regional line identity: the original 52 km Ashuganj-Kishoreganj row is in the 132-kV table. North-Bhulta is 400 kV. Regional values are reference/screening records and are not injected into the frozen South network.
- Breaker identity: Q0 is a repeated device label, not a globally unique breaker name. The central conditional mapping is the GSUT GIS bay 10ADA10/D07, 52-1(Q0). Q1/Q2 are bus-selector disconnectors, Q9 a line-side disconnector; none is invented as a circuit breaker. Line protection trips functional local/remote line-end breaker equivalents; a direct trip of the transformer-bay Q0 is not assigned without an established intertrip route.

Primary coordination result: 12 PRIMARY PASS; 0 total FAIL across all scopes.

Conditional coordination result: 12 CONDITIONAL-PASS. Complete matrix: 12 PRIMARY PASS; 12 CONDITIONAL-PASS; 0 FAIL; 24 NO-TRIP; 48 NO-PAIR (96 total matrix rows).

Breaker-duty result: Q0: maximum 6.897015 kA / 50 kA = 0.137940. 52G: maximum 55.048710 kA / 100 kA = 0.550487. 0 duty exceedances.

Effectiveness result: 40 central rows: 28 CONDITIONAL-DETECTABILITY, 4 NO-TRIP, 8 NO-PAIR/OUT-OF-ZONE; 8 separate DT sensitivity rows.

Remaining actual-document verification items:
- Installed relay setting files, CT protection core/tap schedule, excitation curves and actual burdens.
- Current PGCB positive/negative/zero-sequence equivalent, fault-level date and operating topology.
- Q0 exact installed transformer-bay breaker/nameplate mapping, contact-parting time, DC capability and TRV.
- GEN neutral CT ratio and commissioning test, NGT/loading-resistor interpretation and measured resistance.
- 87T/87B/7SD bias, vector compensation, communication and remote-end settings; actual 86/50BF wiring.
- 7UM62 64G manual/settings pages and primary injection adjustment; the supplied default values are study values.
- South route/conductor geometry and individual motor test data. The numerical study already contains practical substitutes.

Current study limitation:
- The 40-row coordination input is the locked Phase-4 Ikpp backbone. Grid, motor and GSUT alternatives have separate PHASE-5 ANALYTICAL SCREENING SENSITIVITY calculations. South line impedance also determines backup distance reaches. Updated generator sequence values and regional line totals are reference profile data; they have not regenerated the full Phase-4 network or its prefault solution.
- The Phase-4 contribution CSV stores |Ia| on the fault voltage base. Phase-5 recovers faulted B/C phasors, verifies their |Ia| identity against that archive, and converts physical current by Vfault/Vdevice. No upstream fault current is edited.
- The legacy matrix columns I_down_A and I_up_A contain CT-secondary amperes. Their ct_down/ct_up columns give the ratios. phase5_relay_currents.csv explicitly provides both primary and secondary amperes and branch-specific zero-sequence current.
- Breaker duty uses maxABC physical branch Ikpp as a screening comparison. It is not an interrupting-time Ib, asymmetric DC, making-current, short-time thermal or TRV compliance study.
- 87G/87T/87B/7SD results establish study observability only. CT matching, vector-group compensation, differential/restraint current, through-fault stability and CT saturation are not a manufacturer relay algorithm. Timing values are explicit proxies.
- F1 and F2 LG map to the same 22-kV fault node. Their raw terminal branches contain circulating/load current, not differential current. The earth-fault proxy uses the approximately 7.27-A neutral residual; 87G remains below its 2403.8-A start, and the HV-referred 87T proxy is about 0.696 A versus 387.84 A. Both are NO-TRIP. Dedicated 51N/64G provide the study earth-protection representation.
- NO-TRIP times are infinity: a resolved non-operation, not an unresolved parameter. NOT_APPLICABLE_TO_ROW marks structurally irrelevant heterogeneous columns, such as TMS for a differential pickup or an upstream time when no relay pair exists. Installed-value verification is separate from the fully specified study value.

Closeout evidence: docs/PHASE5_CLOSEOUT_CHECKLIST.md records the final acceptance review and resumed verification. The student manual Phase-5 section is synchronized with the final results; both manuals and the completed engineering plan are included in the artifact hashes.

Exact next action: review PHASE5_FINAL_REPORT.md, PHASE5_SOURCE_AUDIT.md and the closeout checklist. For a fresh reproduction, run the final command above. Replace study assumptions only when actual setting/CT/grid documents are obtained. Commissioning requires a separate validated relay and breaker-duty study. Phase 6 is a separate task and is not part of this handoff.
