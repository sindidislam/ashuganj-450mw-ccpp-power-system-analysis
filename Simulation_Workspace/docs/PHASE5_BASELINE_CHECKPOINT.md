# PHASE 5 BASELINE CHECKPOINT

Protected byte ledger: docs/PHASE5_PROTECTED_BASELINE.csv (created before corrections). Phase-2 data, Phase-3 results and Phase-4 code/production outputs remain unchanged.

Phase-5 numerical consumers: phase4_fault_currents.csv provides the first stable Ikpp,m=0.5 row for each case/location/type (40 rows); phase4_contributions.csv provides the archived branch |Ia| identities. phase4_ct_data.csv supplies the historical load anchors in the project context; the final pickup philosophy uses documented maximum through-load. The Phase-4 manifest and hash ledger remain input provenance.

Phase-4 branch phasors are recomputed read-only and identity-gated against the archive. Cache keys include the input bytes and source files; a clean cache can be regenerated. No Phase-4 production workflow is invoked and no upstream file is written.

Phase-3 locked line R/X differs from the new local Phase-5 line screening. The new grid 45.01 kA scenario does not overwrite the existing frozen grid model.
