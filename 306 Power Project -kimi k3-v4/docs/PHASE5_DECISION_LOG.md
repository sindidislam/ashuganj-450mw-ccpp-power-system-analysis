# PHASE 5 FINAL DECISION LOG

1. Preserve the original Phase-2/3/4 bytes and frozen 40-row fault backbone.
2. Resolve required numerical study parameters; retain installed-document verification as a separate obligation.
3. Correct fault-base to physical CT/breaker-base conversion and LL/LLG faulted-phase selection. This changes the coordination counts for a physical reason.
4. Keep starting TMS values 0.10/0.55/0.80/0.15; no adjustment was needed.
5. Q0 uses the conditional GSUT transformer-bay path, 50-kA rating; 63 kA is equipment sensitivity only.
6. Use analytical screening for new grid/line/motor/sequence inputs; do not label it a regenerated Phase-4 network.
7. Use a 20/1 neutral CT and 4-A central pickup; all alternatives are fenced as SENSITIVITY.
8. Replace stale report constants with live generated values; finalize hashes after plots/docs.

12 PRIMARY PASS; 12 CONDITIONAL-PASS; 0 FAIL; 24 NO-TRIP; 48 NO-PAIR (96 total matrix rows).

run_phase5b_tests() PASS = 528; FAIL = 0

Documentary decisions:
- GSUT CT: manufacturer protection schedule indicates 1500/1; as-built SLD and later nameplate indicate 1600/1. Central study uses 1600/1 as ENGINEERING_ASSUMPTION. The installed function-to-core assignment remains unverified. 1500/1 is a calculated documentary sensitivity.
- GSUT impedance/loss: workbook study data give 16.63% and copper loss 912.2 kW (1067.5 minus 155.3 kW); manufacturer design sheet gives 16% and 1095 kW. The workbook-derived profile is the requested local Phase-5 study profile, not a claim that the OEM design sheet states those numbers.
- Grid: the secondary historical 45.01 kA, X/R 10.99 result implies |Z| about 2.9502 ohm at voltage factor c=1. Its reported 3.25 ohm uses an unverified convention; an implied c about 1.102 could explain the discrepancy. The requested c=1 derivation is central and 3.25 ohm is a numerical sensitivity. Neither is an official current PGCB equivalent.
- Grounding: the report marks 60 ohm as HV-winding DC resistance with a question mark and 2.62 ohm as the LV loading resistor with qualification. The frozen effective neutral resistance is 60 + n^2*2.62 ohm, where n=(22000/sqrt(3))/500. Treating 60 ohm alone as the effective neutral resistance would contradict the approximately 7.27 A central stator-earth fault.
- Regional line identity: the original 52 km Ashuganj-Kishoreganj row is in the 132-kV table. North-Bhulta is 400 kV. Regional values are reference/screening records and are not injected into the frozen South network.
- Breaker identity: Q0 is a repeated device label, not a globally unique breaker name. The central conditional mapping is the GSUT GIS bay 10ADA10/D07, 52-1(Q0). Q1/Q2 are bus-selector disconnectors, Q9 a line-side disconnector; none is invented as a circuit breaker. Line protection trips functional local/remote line-end breaker equivalents; a direct trip of the transformer-bay Q0 is not assigned without an established intertrip route.
