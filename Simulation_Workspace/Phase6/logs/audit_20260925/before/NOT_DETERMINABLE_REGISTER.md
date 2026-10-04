# CENTRAL STUDY VALUES AND INSTALLED-DOCUMENT VERIFICATION

No required central numerical parameter is left unresolved. The complete numeric value/status/source/derivation register is PHASE5_ASSUMPTIONS.csv. Actual installed settings remain unverified where indicated; this does not leave the study model numerically open.

7UM622 I>/time: GEN-51 17170.8 A, IEC SI, TMS 0.10 central; historical DT 17171 A / 3 s numerical sensitivity. 7UT6331 87T: 387.84 A / 0.045 s proxy; 7SS523: 320 A / 0.035 s; 7SD5221: 320 A / 0.035 s and 0.050 s scheme. Distance 21, 50BF, 64G, NER, grid and motors all have numerical ledger entries.

Other inventory functions (for example rotor-earth, reverse-power or turbine mechanical trips) are outside the short-circuit coordination calculations and are not assigned fabricated commissioning settings.

Verification-only items:
- Installed relay setting files, CT protection core/tap schedule, excitation curves and actual burdens.
- Current PGCB positive/negative/zero-sequence equivalent, fault-level date and operating topology.
- Q0 exact installed transformer-bay breaker/nameplate mapping, contact-parting time, DC capability and TRV.
- GEN neutral CT ratio and commissioning test, NGT/loading-resistor interpretation and measured resistance.
- 87T/87B/7SD bias, vector compensation, communication and remote-end settings; actual 86/50BF wiring.
- 7UM62 64G manual/settings pages and primary injection adjustment; the supplied default values are study values.
- South route/conductor geometry and individual motor test data. The numerical study already contains practical substitutes.

## v4 closure (2026-09-25, isolated v4 only)
- Q0 duty: CONDITIONALLY CLOSED. 230 kV actual branch max 6.90 kA / 50 kA = 13.8% (conditional mapping). 400 kV PGCB envelope: 50 kA design -> 53.03 kA total / 63 kA = 84.2%, 15.8% margin (results/phase5_protection_v2/q0_breaker_duty_matrix.csv). South has no 400 kV GIS; 400 kV is the regional envelope. Installed Q0 nameplate/TRV/contact times stay verification-only.
- 87G/87T: study settings closed (87G 0.20pu/20%/50%/HS 5pu; 87T 0.30pu/25%/50%/HS 8pu, 2nd 15% + 5th 30% block). Installed bias/commissioning values stay verification-only.
- Missing R0/X0/B0, tower/soil, CT burdens, breaker times: practical finite substitutes in Phase6/data/assumptions/HARDWARE_SELECTION_v4.md, tagged ENGINEERING_ASSUMPTION. Nothing left as ideal 0.
- No open NOT_DETERMINABLE remains in the study model. Only installed-document verification items above.
