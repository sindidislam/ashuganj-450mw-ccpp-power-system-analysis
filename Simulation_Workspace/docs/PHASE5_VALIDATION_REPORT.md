# PHASE 5 VALIDATION REPORT

run_phase5b_tests() PASS = 528; FAIL = 0

12 PRIMARY PASS; 12 CONDITIONAL-PASS; 0 FAIL; 24 NO-TRIP; 48 NO-PAIR (96 total matrix rows).

Q0: maximum 6.897015 kA / 50 kA = 0.137940. 52G: maximum 55.048710 kA / 100 kA = 0.550487. 0 duty exceedances.

40 central rows: 28 CONDITIONAL-DETECTABILITY, 4 NO-TRIP, 8 NO-PAIR/OUT-OF-ZONE; 8 separate DT sensitivity rows.

The suite validates numerical calculations, current bases, scope segregation, provenance and artifact integrity. Passing tests do not certify installed relay performance.

Live implementation validation: 14/14 legs.

Independent direct-formula checks, including every finite matrix operating time: PHASE5_INDEPENDENT_ARITHMETIC.csv.

Final production verifies the protected baseline and every manifest/sha256 entry after output generation.

Reproduce: `matlab -batch "addpath(genpath('matlab')); run_phase5b_production('final-engineering','overwrite',true);"`
