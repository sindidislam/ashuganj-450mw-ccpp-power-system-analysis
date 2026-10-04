# Phase 6 parameter task

Implement the missing central parameter provider for the resumed Simulink study. Read this brief first. Write only the files listed below; do not spawn agents and do not modify upstream files or the existing builder.

## Deliverables

- `Phase6/scripts/init_phase6_parameters.m`
- `Phase6/scripts/phase6_write_parameter_register.m` if needed to export a register explicitly (the initializer itself must not write files)
- `Phase6/scripts/tests/test_phase6_parameters.m`
- `Phase6/docs/PARAMETER_TASK_REPORT.md`

Use the canonical read-only providers in `matlab/data` and frozen CSVs in `Phase6/data/phase5_reference`. Relevant providers: `ashuganj_generators`, `ashuganj_transformers`, `ashuganj_lines`, `ashuganj_grid`, `ashuganj_loads`, `engineering_assumptions`, `ashuganj_phase2_systems`. Inspect them. Do not regenerate upstream load flow or Phase 5 outputs. No Git repository exists, so no commit is required.

## Required API (use exact field names)

`P = init_phase6_parameters()` calls `setup_phase6_workspace` and returns a scalar struct:

- `P.f_Hz = 50`, `P.Sbase_VA = 100e6`.
- `P.generator`: unchanged canonical generator struct.
- `P.transformers`: canonical transformer struct array including derived SPS winding R/L and core/magnetizing choices.
- `P.lines`: canonical line registry, unchanged.
- `P.grid`: canonical grid struct, unchanged.
- `P.loads`: canonical load registry, unchanged.
- `P.assumptions`: canonical `engineering_assumptions()` records, unchanged.
- `P.systems`: canonical Phase 2 systems metadata, unchanged.
- `P.reference.summary`: table from phase3_system_summary.csv; `P.reference.buses`: phase3_bus_results.csv.
- `P.reference.primary`: the exactly one LF360_GAT_OUT summary table row.
- `P.protection.settings`, `.devices`, `.trips`, `.faults`, `.currents`: tables from the correspondingly named frozen Phase 5 CSVs, using preserved original variable names.
- `P.scenario`: `name='normal'`, `faultEnabled=false`, `faultType='3PH'`, `faultLocation='GIS230'`, `faultStart_s=1`, `faultDuration_s=0.15`, `stopTime_s=2`, `protectionEnabled=true`, `batteryAvailable=true`, `chargerAvailable=true`, `dcLossTime_s=Inf`, `dcRestoreTime_s=Inf`, `GAT_in=false`.
- `P.machine`: `.Sn_VA`, `.Vn_V`, `.Rs_pu`, `.reactances_pu=[Xd Xdp Xdpp Xq Xqp Xqpp Xl]`, `.timeConstants_s=[Td0p_s Td0pp_s Tq0p_s Tq0pp_s]`, `.H_s`, `.damping_pu` (explicit zero academic damping assumption, not source-backed), `.polePairs=1` (50 Hz/3000 rpm two-pole machine), `.P_W=360e6`, `.Vref_pu=1`.
- `P.register`: table with at least Parameter, Value, Unit, Classification, Source, Notes. Cover every physical value consumed by the normalized machine; network source choices; all academic assumption records; source relay settings/CTs; scenario-specific numerical settings. Use `VERIFIED_SOURCE`, `DERIVED_FROM_VERIFIED_SOURCE`, `USER_ASSERTED`, `ENGINEERING_ASSUMPTION`, `PLACEHOLDER_NOT_FOR_FINAL_RESULT` carefully; carry qualification text and source locator. Preserve Rf as unresolved and unused, not zero.

Controller code in root will use raw `P.assumptions.<key>.value`; do not invent conflicting duplicate controller or battery constants. The primary dispatch is 360 MW and the line is 0.7 km. Phase 5 grid screening alternative must never replace Phase 3 ZGRID. No 400 kV South bus.

## Verification

Write meaningful tests first for conversion/base arithmetic (known Rs), correct primary row selection, isolation of the Phase 3 grid from the Phase 5 alternative, complete provenance classifications including unresolved Rf, and preserved upstream file hashes if appropriate. Run MATLAB `-batch` only when root confirms the baseline probe has finished; otherwise prepare files and ask root to run the test. Report exact paths, tests run and failures. Send the parameter interface/source concerns early if anything cannot match this contract.
