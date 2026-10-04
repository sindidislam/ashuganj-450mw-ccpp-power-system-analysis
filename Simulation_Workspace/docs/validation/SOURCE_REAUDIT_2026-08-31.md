# South Engineering Source Re-audit — 2026-08-31

## Status

The existing load-flow solution is **provisional** until the corrected source registry is fully tested and all generated reports are rebuilt. Software convergence does not by itself validate engineering transcription.

## Directly confirmed from technical PDFs currently present

| Item | Confirmed value | Primary evidence |
|---|---:|---|
| Main MV bus `10BBA10` | 6.6 kV, **3150 A, 31.5 kA**, 3-phase, 50 Hz | Rev 03 main SLD, explicit MV BUSBAR line |
| Water-intake MV buses | 6.6 kV, **1250 A, 31.5 kA**, 50 Hz | Rev 03 main SLD, water-intake busbar labels |
| GAT physical topology | **230/6.9/3.32 kV**, `YNyn0+d11`, 19/25 MVA, tertiary 8.33 MVA | Rev 03 SLD; Siemens UAT/GAT datasheet |
| GAT load-flow equivalent | HV–LV `Z_PS = 12%` on 25 MVA; unloaded tertiary omitted only for balanced positive-sequence LF | Siemens UAT/GAT datasheet and current modelling rationale |
| UAT | 22/6.9 kV, 19/25 MVA, `Dyn11`, main-tap impedance 10.5% on 25 MVA | Siemens UAT/GAT datasheet |
| GSUT | 230/22 kV, 355/460/515 MVA, `YNd1`, main-tap impedance 16% on 515 MVA | Siemens GSUT datasheet/nameplate |
| Generator | 458 MVA, 22 kV, 12019 A, 0.85 PF, 50 Hz | Siemens generator nameplate |
| Generator additional data | `Uexc0=122 V`, SFC DC link 2.28 kV, SFC max 1876 A, `I2max/IN=7.64%`, `K=7.41 s` | Generator protection-report pages in `Generator Data_South.pdf` |
| DC/excitation existence | Static excitation equipment plus 110 Vdc and 220 Vdc systems are shown | Rev 03 main SLD and protection one-line |
| MV motors | Individual 12-motor rated-kW schedule is present | Rev 03 main SLD MV MOTOR TABLE |

## Important interpretation corrections

1. **6.6 kV versus 6.9 kV is not an unresolved source conflict.** The 6.6 kV value is the plant MV-bus nominal; 6.9 kV is the UAT/GAT winding rating. The load-flow model must preserve the off-nominal ratio.
2. **The GAT is physically three-winding.** A two-winding representation is only the present balanced-load-flow equivalent; it must not replace the physical topology in the master register.
3. **DC systems exist.** What remains missing is battery/charger rating, autonomy, detailed distribution, and the exact normal/emergency field-flashing and excitation DC path.
4. **Individual MV motor ratings exist.** Motor electrical-input PF/efficiency, sequence/subtransient data, starting data, and running/standby status remain missing.
5. **The external grid remains provisional.** The 50 kA/19,919 MVA figure aligns with GIS withstand arithmetic and is not accepted as verified PGCB grid strength. `R=0` remains a provisional study assumption, not practical grid data.

## Generator capability curve

A newer complete Siemens protection-report package and its Attachment 1 were reported as present in a broader project library, but the current workspace folder exposed to this audit contains only `Generator Data_South.pdf`, pages 6–7 of 39. Therefore the MATLAB registry now records the capability curve as `AVAILABLE_NOT_DIGITIZED`, but **no numerical curve points are enabled** until the full PDF is physically added to this workspace and independently transcribed.

The old CYME scalar `QMAX/QMIN` values remain invalid diesel-template data and must not be reused.

## GIS package and line identity

A Siemens GIS control/protection package `S008-112070-00-ELC-DE-1011` and the identity **Line Ghorasal 2** were reported from a wider source library. That package is not currently visible among the technical PDFs in this workspace. The identity should therefore be retained as newly reported source information, while normal switching state, circuit count, exact length, and positive/negative/zero-sequence line constants remain pending direct ingestion.

## Still requiring plant/PGCB confirmation

- Actual generator terminal-voltage/AVR setpoint
- Actual dispatch snapshot in MW/MVAr and ambient conditions
- Actual GSUT/UAT/GAT tap positions
- Normal GAT and UAT incomer state and parallel-transfer interlock logic
- Normal GIS coupler and bay-selector positions
- PGCB short-circuit level and Thevenin `R+jX` or X/R at the 230 kV point of connection
- Project-specific line length and R1/X1/B1/R0/X0/B0
- Actual auxiliary MW/MVAr and motor running/standby status
- Battery and charger ratings, autonomy, DC distribution, and excitation/field-flashing supply path

## Validation consequence

The previous 434/447-test claims establish software consistency for the then-current registry, not independent source transcription. The load-flow numerical results must be labelled provisional until updated data tests pass and the four cases, CSVs, plots, and reports are regenerated from the corrected registry.
