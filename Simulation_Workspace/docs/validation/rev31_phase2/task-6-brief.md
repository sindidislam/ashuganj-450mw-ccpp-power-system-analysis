# Phase-2 task 6
## Global constraints

- Phase 2 only; no fault/protection/sequence/final dynamic integration.
- No implementation until the complete baseline has passed and the four baseline LF solves are captured.
- Preserve all source documents, historical outputs, Rev2 and original network physics byte-for-byte.
- Preserve primary generator 458 MVA/360 MW, distinct subtransient values 0.2608/0.2248 pu, raw resistance and base conversions, and high-resistance NER.
- Source curve is PRIMARY_SOURCE_EXTRACTED: user supplied manual graphical extraction; no independent attachment inspection claim.
- Both LF voltage setpoints stay 1.00 pu. Auxiliary demand remains 14 MW at 0.85 PF. Grid/transformer/load numerical providers stay unchanged.
- No Git repository: use original-file SHA-256 inventory and scoped backups rather than commits.
- MATLAB file formatting previously corrupted edits: verify written MATLAB text and run parser/tests before accepting changes.


## Task 6 â€” Integration, audit and final report

**Files:** extend [suite runner](../../../matlab/tests/run_all_tests.m); create Phase-2 documentation, audit/evidence/result tables under the new Phase-2 locations. No original historical reports are modified.

- [ ] Add all new data and component/LF test files to the complete suite with a separate fast data selection.
- [ ] Run generator, base, master/data, topology, capability, capacity, assumptions, subsystem and response tests, then complete suite. Save actual counts and logs; require zero failures.
- [ ] Run all six fresh LF cases and exact historical baseline comparison, plus plot generation and source/assumption table export.
- [ ] Scan requested numeric/text patterns repository-wide; classify text matches as PRIMARY LIVE CODE, PRIMARY DATA, ENGINEERING_ASSUMPTION, HISTORICAL, LEGACY, DOCUMENTATION, COMMENT, TEST EXPECTATION or UNUSED/DEAD. Inventory binary coverage; inspect workbook/container text read-only where feasible, clearly state PDF/image/database limitations. Exclude generated audit recursion.
- [ ] Rehash all 937 original files. Produce exact modified/unchanged paths, reason/type ledger and new-file manifest; verify protected files unchanged. Verify generator primary structure and transformer/grid/load numerical identity against baseline.
- [ ] Independently review implementation scope, provenance, limiter bases, battery conservation, source-vs-assumption distinctions and test assertions; fix only Phase-2 issues, rerun impacted/full tests.
- [ ] Produce report sections Aâ€“AF, complete source and engineering-assumption tables, all LF results and regression discrepancies, exception treatment, Rev2 readiness only, and recommended Phase-3 scope without implementing it.
