# Rev3.1 Phase 2 — Task 4 Report: Operating Profile Migration & Capacity Guard

## 1. Executive Summary
Task 4 successfully established the authoritative Phase-2 operating profiles, integrating the primary 360 MW capacity cases, qualified 342.01 MW scenarios, and historical 389.30 MW reference cases while enforcing the strict active-power capacity guard. 

All 52 unit tests in `test_operating_profiles.m` passed cleanly (0 failures). Full regression across all Phase 1 and Phase 2 suites passed with **886 total assertions, 0 failures**.

---

## 2. Implemented Artifacts & Code Structure

### 2.1 Operating Profiles Provider: `matlab/data/ashuganj_operating_profiles.m`
Constructs both the 6 canonical Phase-2 profiles and the 4 historical aliases.

#### Six Canonical Profiles:
1. **`LF360_GAT_OUT`**: Primary 360.00 MW dispatch, GAT open (radial), `PRIMARY_VERIFIED`, `approved_exception = false`.
2. **`LF360_GAT_IN`**: Primary 360.00 MW dispatch, GAT closed (looped), `PRIMARY_VERIFIED`, `approved_exception = false`.
3. **`LF342_GAT_OUT`**: Qualified 342.01 MW dispatch, GAT open (radial), `PRIMARY_SOURCE_QUALIFIED`, `approved_exception = false`.
4. **`LF342_GAT_IN`**: Qualified 342.01 MW dispatch, GAT closed (looped), `PRIMARY_SOURCE_QUALIFIED`, `approved_exception = false`.
5. **`LF389P30_GAT_OUT`**: Historical OEM PF-reference 389.30 MW, GAT open (radial), `HISTORICAL`, `approved_exception = true`.
6. **`LF389P30_GAT_IN`**: Historical OEM PF-reference 389.30 MW, GAT closed (looped), `HISTORICAL`, `approved_exception = true`.

#### Four Historical Backward-Compatible Aliases:
- `LF1`: Alias for `LF389P30_GAT_OUT` ($P = 389.30\text{ MW}$, radial)
- `LF2`: Alias for `LF389P30_GAT_IN` ($P = 389.30\text{ MW}$, looped)
- `LF3`: Alias for `LF342_GAT_OUT` ($P = 342.01\text{ MW}$, radial)
- `LF4`: Alias for `LF342_GAT_IN` ($P = 342.01\text{ MW}$, looped)

#### Specification Compliance (Prompt Section 33):
Each profile stores all 14 mandatory fields:
- `case_id` & `ID`: Canonical case identifier.
- `dataset_id`: Lineage identifier (`GEN-R31-WORKBOOK-ROW3`).
- `generator_id`: Unit identifier (`G1`).
- `P_dispatch` & `P_dispatch_MW`: Active dispatch level in MW.
- `P_capacity` & `P_capacity_MW`: Primary machine capacity ($360.00\text{ MW}$).
- `GAT_status`: `'IN'` or `'OUT'`.
- `UAT_status`: `'IN'`.
- `coupler_status`: `'CLOSED'`.
- `voltage_setpoints`: Generator ($1.00\text{ pu}$) and Grid ($1.00\text{ pu}$) setpoints.
- `auxiliary_load`: $14.0\text{ MW} + j8.67642\text{ MVAr}$ (`ENGINEERING_ASSUMPTION`).
- `grid_definition`: $V_{\text{set}} = 1.00\text{ pu}$, $I_{\text{sc}} = 50\text{ kA}$, $S_{\text{sc}} = 19918.58\text{ MVA}$, $X = 2.6565\,\Omega$ (`ESTIMATED`).
- `topology`: `'radial'` or `'looped'`.
- `assumptions`: Provenance metadata for all unmeasured boundaries.
- `provenance`: Traceability to primary source.
- `Gen_Q_MVAr_limit`: Finite piecewise-linear physical capability limits $[Q_{\min}, Q_{\max}]$.

### 2.2 Capacity Guard: `matlab/data/validate_operating_profile.m`
Strictly enforces:
1. $P_{\text{dispatch}} \le P_{\text{capacity}} = 360.00\text{ MW}$ for all primary operating cases.
2. An attempt by a primary case to declare `approved_exception = true` is an illegal bypass and throws an error.
3. Over-dispatch ($> 360\text{ MW}$) without an approved exception throws an error.
4. Only historical reference cases with explicit documentation and `approved_exception = true` may dispatch above 360 MW.

### 2.3 Master Data Integration: `matlab/data/ashuganj_master_data.m`
- `D.operating_profiles`: Holds the 6 canonical Phase-2 profiles.
- `D.primary_cases`: Holds the 2 primary 360 MW cases.
- `D.qualified_cases`: Holds the 2 qualified 342.01 MW scenarios.
- `D.historical_cases`: Holds the 2 historical 389.30 MW references.
- `D.cases`: Preserves the 4 historical aliases (`LF1..LF4`), ensuring 100% backward compatibility for existing regression fixtures (`test_topology`, `test_generator_data`, `t_solve`).
- `D.builder_cases`: Exposes all 10 profiles for tools needing full coverage.

---

## 3. Test & Verification Evidence

### 3.1 RED Test Phase (`task-4-red.log`)
Expected initial failures before implementation:
- Missing `ashuganj_operating_profiles.m` and `validate_operating_profile.m`.
- Recorded in `docs/validation/rev31_phase2/task-4-red.log`.

### 3.2 GREEN Test Phase (`task-4-green.log`)
Command:
```powershell
matlab -batch "addpath(genpath('matlab')); [np,nf]=test_operating_profiles(); fprintf('TASK4 GREEN COUNTS %d %d\n', np, nf); exit;"
```
Output:
- 52 assertions executed.
- **52 passed, 0 failed**.

### 3.3 Regression Suite (`task-4-regression.log`)
Command:
```powershell
matlab -batch "addpath(genpath('matlab')); t1=test_generator_capability(); t2=test_generator_data(); t3=test_engineering_assumptions(); t4=test_phase2_systems(); t5=test_phase2_component_models(); t6=test_operating_profiles(); t7=test_topology(); exit;"
```
Results:
| Test Suite | Assertions | Passed | Failed |
|---|---|---|---|
| `test_generator_capability` | 224 | 224 | 0 |
| `test_generator_data` | 476 | 476 | 0 |
| `test_engineering_assumptions` | 9 | 9 | 0 |
| `test_phase2_systems` | 24 | 24 | 0 |
| `test_phase2_component_models` | 49 | 49 | 0 |
| `test_operating_profiles` | 52 | 52 | 0 |
| `test_topology` | 52 | 52 | 0 |
| **TOTAL** | **886** | **886** | **0** |

---

## 4. Phase 2 Task Status
- Task 1: Capability Curve & Source Data — **COMPLETE**
- Task 2: Central Assumption Registry & Subsystems — **COMPLETE**
- Task 3: Isolated Component Behavior — **COMPLETE**
- Task 4: Operating Profile Migration & Capacity Guard — **COMPLETE**
- Task 5: Load-Flow Solving, Capability Checking & Visualization — **READY TO BEGIN**
- Task 6: Suite Integration, Final Audits & Comprehensive Report — **PENDING**
