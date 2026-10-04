# Balanced Steady-State Load Flow — Ashuganj 450 MW Combined Cycle Power Plant (South)

**Project** EEE 306 Power System Project, January 2026 · Group‑03, Section C‑1, BUET EEE
**Plant** Ashuganj 450 MW CCPP (South), APSCL — Siemens SCC5‑PAC 4000F/3000 (1S) single‑shaft unit
**Study** Balanced three‑phase steady‑state load flow, 50 Hz, four dispatch/topology cases
**Tool** MATLAB R2024a (24.1.0.2537033), Simscape Electrical 24.1, `powergui` / `power_loadflow`
**Reporting base** 100 MVA, plus engineering units and each bus's own base
**Date** 2026‑08‑18

---

## 0. What this report is, and what it is not

This is **a load flow and nothing else**. It reports solved bus voltages, branch flows,
transformer loadings and the system power balance for the South plant at 50 Hz.

It is **not** a short‑circuit study, **not** a fault analysis (3‑phase, L‑G, L‑L, L‑L‑G),
**not** a protection coordination study, **not** a relay setting exercise and **not** a
transient stability study. None of those are implemented in the model. The project title
names protection coordination and fault analysis as the eventual objective; this report is
the load‑flow foundation that must be defensible before any of that work begins.

Two of the five assumptions the model rests on are **disclosed but not approved** (A4, A5,
§11). Every per‑unit voltage below is expressed relative to A5. That is stated here rather
than in a footnote because it changes how the voltage tables should be read.

---

## 1. Provenance

Every number in this report traces to one of three places:

| Class | Meaning | Where it lives |
|---|---|---|
| **Verified** | Read from an original engineer/plant/manufacturer document | `docs/validation/verified_parameters.md`, `data/master/Ashuganj_Master_Data.csv` |
| **Derived** | Computed from verified data by a stated formula | same, `Status = DERIVED_FROM_VERIFIED_DATA` |
| **Assumed / Estimated** | Not in any source document | `docs/validation/assumptions.md`, `matlab/data/assumptions/` |

No parameter in the model was taken from a textbook, a "typical value" table, or the web.
Where a value is missing it is either reported missing, resolved by running comparative
cases, or carried as an explicitly labelled assumption. The prior CYME PSAF v2.90 network
file was **not** used as a data source — it was built at 60 Hz, its diesel reactive limits
are an untouched template, and it omits the GAT entirely
(`docs/validation/prior_psaf_model_defects.md`, defects D1–D8).

**Scope.** South plant only. The 400 kV GIS and the 400/230 kV Hyosung interbus
transformers belong to Ashuganj **North** (UTS project 7485) and appear nowhere in this
model. The South plant tops out at 230 kV. The 400 **V** auxiliary level and the 400 **kV**
transmission level are never conflated: 400 V does not appear in this study at all, because
the LV distribution transformers downstream of the 6.6 kV bus are not modelled (§13).

**Frequency.** 50 Hz, from every South document — generator nameplate, both Rev 03
drawings, the GIS data sheet and all rating plates. Confirmed present in the solved model,
not merely set: `test_topology` asserts `Frequency = 50` on the `powergui` block and on
every three‑phase source in all four case models.

---

## 2. The network that was solved

```
                       EXT GRID 230 kV  (swing, 1.000 pu, 0°)
                              │
                       ZGRID  │  X = 2.6558 Ω  (ESTIMATED)   R = 0  (ASSUMED, A1)
                              │
        ┌─────────────────────┴──────────────────────┐
        │   230 kV BUS 1        ═══[10BAY12]═══   230 kV BUS 2      Siemens 8DN9 GIS
        │   (coupler CLOSED, A3 → one solved node)                  3150 A busbar
        └──────┬──────────────────────────────┬──────┘
          [10BAY11]                      [10BAY20]
               │                              │  open in LF1/LF3, closed in LF2/LF4
        GSUT 10BAT10                     GAT 10BBT20
        230/22 kV YNd1                   230/6.9 kV YNyn0+d11
        355/460/515 MVA ONAN/ODAN/ODAF   19/25 MVA
        Z = 16 % @ 515 MVA               Z_PS = 12 % @ 25 MVA
        tap 9 = 230000 V (principal)     tap 13 = 230000 V (principal)
               │                              │
        ┌──────┴──────┐                       │
        │ 22 kV GEN BUS│                      │
        └──┬────────┬──┘                      │
           │        │                         │
          G1     UAT 10BBT10                  │
      SGen5‑2000H  22/6.9 kV Dyn11            │
      458/518 MVA  19/25 MVA ONAN/ONAF        │
      22 kV        Z = 10.5 % @ 25 MVA        │
      12019 A      tap 3 = 22000 V            │
                        │                     │
                   ┌────┴─────────────────────┴────┐
                   │      6.6 kV MV BUS            │  ← 14.000 MW / 8.676 MVAr
                   │  (+ WI‑1, WI‑2: same node)    │    at 0.85 pf
                   └───────────────────────────────┘
```

**8 registered buses → 5 solved nodes.** The solver merges zero‑impedance groups:

| Registered buses | Merged into | Why |
|---|---|---|
| `B230_1`, `B230_2` | one node | bus coupler 10BAY12 is a closed zero‑impedance breaker (A3) |
| `B6_6`, `B6_6_WI1`, `B6_6_WI2` | one node | the 6.6 kV water‑intake feeder impedances are **MISSING**, modelled at zero (treatment S7) |
| `GAT_HV` | **never merged** — distinct node in all four cases | bay 10BAY20 open: the 1e6 Ω snubber holds it at the turns ratio. Bay closed: the breaker's 0.01 Ω contact resistance keeps it 0.51 V off the busbar. Either way the solver reports it separately, so all four cases have **five** solved nodes |

Merging is reported, not hidden. `bus_results.csv` carries a `Merged_into` column and
prints the merged partners with `NaN` injections rather than repeating the group total,
because repeating it would make a group figure look like a per‑bus figure.

**Structural treatments** (S1–S11, `docs/validation/assumptions.md`) — modelling structure
taken from the documents, not invented numbers. The load‑bearing ones here: no 6.9 kV bus
is created (6.9 kV is the UAT/GAT LV *winding* rating, the plant MV bus is 6.6 kV nominal,
S3); the off‑nominal 22000/6900 ratio is modelled explicitly into a 6600 V base (S4); the
emergency diesel generators are out of service per Rev 03 SLD Note 4 (S5); there is no
shunt compensation anywhere on any drawing (S6); in‑station links are at zero impedance
because no length or impedance is documented (S7).

---

## 3. The four cases

Two approved answers each opened a comparison rather than a choice, so the study is a 2×2
matrix. No case is "the" answer; the pair‑differences are the result.

| | Dispatch | GAT bay 10BAY20 | Topology | Approved by |
|---|---|---|---|---|
| **LF1** | Rated 389.30 MW | out of service | radial | Q2c + Q4c |
| **LF2** | Rated 389.30 MW | in service | looped | Q2c + Q4c |
| **LF3** | Site‑derated 342.01 MW | out of service | radial | Q2c + Q4c |
| **LF4** | Site‑derated 342.01 MW | in service | looped | Q2c + Q4c |

**Why two dispatches.** 389.30 MW is `DERIVED_FROM_VERIFIED_DATA` — the rated gross output.
342.01 MW is `VERIFIED_PROJECT_DATA` — the site‑derated figure stated in the project data.
Answer **Q2c** was explicit: solve both and compare. Calling either one "the actual
operating MW" would be false; neither is a measured dispatch.

**Why two GAT states.** The normal service state of the GAT is not stated in the document
set. Answer **Q4c** was to solve both. The consequence turned out to be the single most
significant finding in the study (§10.1).

---

## 4. Convergence and numerical validation

| | LF1 | LF2 | LF3 | LF4 |
|---|---|---|---|---|
| solver status | converged | converged | converged | converged |
| iterations | 2 | 2 | 2 | 2 |
| worst KCL residual (MVA) | 8.638e‑08 | 6.212e‑04 | 8.641e‑08 | 5.266e‑04 |
| checks | OK | OK | OK | OK |

The looped cases carry a residual ~7000× larger than the radial ones — 6.2e‑04 MVA against
8.6e‑08 MVA. That is not a defect: a loop closed through two transformers of very different
impedance makes the Newton–Raphson tolerance bite on a circulating quantity rather than on
a radial through‑flow. 6.2e‑04 MVA on a 390 MVA machine is 1.6 ppm. It is reported because
downstream arithmetic on LF2/LF4 closes to ~3e‑05 MW rather than ~2e‑07 MW (§8), and that
difference should be traceable to its cause rather than look like a mistake.

`power_loadflow` **does not throw on failure** — it returns `status = -1` and a `bus` struct
silently truncated to 12 fields with no `Vbus`/`Sbus` (`docs/validation/solver_behaviour.md`).
Every case in `run_load_flow_study.m` is therefore **gated on `status == 1`**: a
non‑converged case writes no results row. No number in this report comes from an
unconverged solve.

**Test suite: 434 assertions, 0 failures, 154.5 s** (`matlab/tests/run_all_tests.m`,
run 2026‑08‑18):

| Test | Passed | Failed |
|---|---|---|
| `test_bus_data` | 61 | 0 |
| `test_generator_data` | 28 | 0 |
| `test_transformer_data` | 85 | 0 |
| `test_line_data` | 47 | 0 |
| `test_load_data` | 58 | 0 |
| `test_base_conversion` | 19 | 0 |
| `test_topology` | 52 | 0 |
| `test_transformer_phase_shift` | 18 | 0 |
| `test_grid_sensitivity` | 38 | 0 |
| `test_magnetising_sensitivity` | 28 | 0 |
| **TOTAL** | **434** | **0** |

---

## 5. Bus voltages

### 5.1 Magnitudes (per unit, on each bus's own base)

| Bus | Label | Type | Base | LF1 | LF2 | LF3 | LF4 |
|---|---|---|---|---|---|---|---|
| `BGRID230` | EXT GRID 230 kV | swing | 230000 V | 1.000000 | 1.000000 | 1.000000 | 1.000000 |
| `B230_1` | 230 kV BUS 1 + BUS 2 | PQ | 230000 V | 0.998686 | 0.998502 | 0.998974 | 0.998785 |
| `B22` | 22 kV GEN BUS | **PV** | 22000 V | **1.000000** | **1.000000** | **1.000000** | **1.000000** |
| `B6_6` | 6.6 kV MV BUS | PQ | 6600 V | 1.001390 | 1.020460 | 1.001387 | 1.020998 |
| `B6_6` | *same bus, alt. base* | PQ | *6900 V* | *0.957852* | *0.976092* | *0.957848* | *0.976607* |
| `GAT_HV` | GAT HV terminal | PQ | 230000 V | 0.957864 | 0.998504 | 0.957857 | 0.998787 |

### 5.2 Magnitudes in engineering units (kV)

| Bus | LF1 | LF2 | LF3 | LF4 |
|---|---|---|---|---|
| `BGRID230` | 230.0000 | 230.0000 | 230.0000 | 230.0000 |
| `B230_1` | 229.6977 | 229.6554 | 229.7639 | 229.7206 |
| `B22` | 22.0000 | 22.0000 | 22.0000 | 22.0000 |
| `B6_6` | 6.60918 | 6.73503 | 6.60915 | 6.73859 |
| `GAT_HV` | 220.3087 | 229.6560 | 220.3071 | 229.7210 |

### 5.3 Angles (degrees, grid reference)

| Bus | LF1 | LF2 | LF3 | LF4 |
|---|---|---|---|---|
| `BGRID230` | 0 | 0 | 0 | 0 |
| `B230_1` | +1.07868 | +1.07883 | +0.94257 | +0.94272 |
| `B22` | −22.22509 | −22.32972 | −23.20951 | −23.28635 |
| `B6_6` | +4.33472 | +2.79626 | +3.35031 | +2.22362 |
| `GAT_HV` | +4.33212 | +1.07894 | +3.34773 | +0.94283 |

The 22 kV bus angle of roughly −22° to −23° is **not** a voltage‑angle problem. It is
dominated by the GSUT's **YNd1 +30° phase shift**: the true electrical angle across the
transformer is `30° − (1.07868 + 22.22509) = 6.6962°` in LF1. See the hand check in §9.2.

### 5.4 Three things the voltage table must be read with

1. **`B22` reads exactly 1.000000 pu because it was set to.** It is a PV bus and 1.00 pu is
   **assumption A5**, disclosed and *not approved*. No document gives an AVR setpoint, a
   voltage schedule, or one measured 22 kV reading. Every other per‑unit voltage in this
   study is measured relative to this datum. A5 is not an error bar on a result — it is the
   reference the results are expressed against.

2. **The 6.6 kV bus is reported on two bases, and the difference is 4.55 %.** This is
   **conflict C13**: the UAT and GAT LV windings are rated **6.9 kV**, the plant MV busbar
   is **6.6 kV nominal** (U_m 7.2 kV). The sources do not settle which is the intended
   per‑unit base. Both are printed. Rebasing an impedance from 6.9 kV to 6.6 kV inflates it
   by **9.2975 %**, and the choice moves the reported MV bus voltage by **4.55 %** — larger
   than any other single uncertainty at that bus, and 27× larger than the whole A4
   magnetising sweep (§11). **This conflict is not resolved. It is reported.**

3. **`GAT_HV` at 0.9579 pu in LF1/LF3 is not a system voltage.** With bay 10BAY20 **open**,
   the GAT stays connected to the 6.6 kV bus and is back‑energised from the LV side. Its HV
   terminal floats at the **turns ratio**, so 0.9579 pu is `1.0014 × (6900/6600)⁻¹` — the
   ratio, not a bus. The figure `bus_voltage_profile.png` puts it in a separate panel for
   exactly this reason: drawn in line it makes an open breaker look like a 4 % voltage
   gradient, which would be the largest apparent feature on the plot and would be false.
   It only becomes a real 230 kV voltage in LF2/LF4, at 0.998504 / 0.998787 pu. Note that it
   remains a **distinct solved node** there rather than merging into the busbar: the closed
   breaker carries the block's 0.01 Ω contact resistance, so `GAT_HV` sits 0.51 V below
   `B230_1`/`B230_2` in LF2 (229655.9595 V against 229655.4483 V, a difference of 2 × 10⁻⁶ pu).
   All four cases therefore report **five** solved nodes, not four in LF1/LF3 and five in
   LF2/LF4.

**Plant voltage spread, excluding `GAT_HV`:** 0.998502 pu (`B230_1`, LF2) to 1.020998 pu
(`B6_6`, LF4) on each bus's own base — a **2.25 % total spread across the whole plant** in
the worst case. No solved voltage is reported against a pass/fail limit, because answer
**Q8a** confirmed no 230 kV voltage tolerance is available in the document set.

---

## 6. Transformer results

### 6.1 Flows and losses

| Case | Transformer | P_LV (MW) | Q_LV (MVAr) | S_LV (MVA) | P_HV (MW) | Q_HV (MVAr) | S_HV (MVA) | P_loss (kW) | Q_loss (MVAr) | I_HV (A) |
|---|---|---|---|---|---|---|---|---|---|---|
| LF1 | GSUT 10BAT10 | 375.2201 | 21.2419 | 375.8208 | 374.4861 | −22.6172 | 375.1685 | 733.94 | 43.8590 | 942.99 |
| LF1 | UAT 10BBT10 | −14.0191 | −8.6736 | 16.4853 | −14.0799 | −9.9176 | 17.2222 | 60.83 | 1.2440 | 451.97 |
| LF1 | GAT 10BBT20 | 0.0191 | −0.0028 | 0.0193 | −0.0020 | −0.0029 | 0.0035 | 21.10 | 0.0000 | 0.009 |
| LF2 | GSUT 10BAT10 | 369.3124 | 21.2266 | 369.9219 | 368.5964 | −21.2661 | 369.2094 | 716.00 | 42.4927 | 928.19 |
| LF2 | UAT 10BBT10 | −19.9047 | −3.9605 | 20.2949 | −19.9876 | −5.7761 | 20.8054 | 82.86 | 1.8156 | 546.00 |
| LF2 | GAT 10BBT20 | +5.9051 | −4.7154 | 7.5568 | +5.8707 | −5.0023 | 7.7128 | 34.37 | 0.2868 | 19.39 |
| LF3 | GSUT 10BAT10 | 327.9301 | 15.7399 | 328.3076 | 327.3324 | −17.7284 | 327.8121 | 597.73 | 33.4683 | 823.73 |
| LF3 | UAT 10BBT10 | −14.0191 | −8.6743 | 16.4857 | −14.0799 | −9.9184 | 17.2226 | 60.83 | 1.2441 | 451.98 |
| LF3 | GAT 10BBT20 | 0.0191 | −0.0021 | 0.0192 | −0.0020 | −0.0021 | 0.0029 | 21.10 | 0.0000 | 0.008 |
| LF4 | GSUT 10BAT10 | 323.5735 | 15.9635 | 323.9671 | 322.9874 | −16.6255 | 323.4150 | 586.17 | 32.5890 | 812.83 |
| LF4 | UAT 10BBT10 | −18.3635 | −4.0292 | 18.8003 | −18.4365 | −5.5857 | 19.2640 | 72.99 | 1.5564 | 505.55 |
| LF4 | GAT 10BBT20 | +4.3639 | −4.6469 | 6.3747 | +4.3329 | −4.8507 | 6.5041 | 30.94 | 0.2039 | 16.35 |

Sign convention: `From_bus → To_bus` as registered. The GSUT is registered LV→HV
(`B22 → B230_1`), the UAT and GAT are registered LV→HV from the 6.6 kV bus. **Negative
`P_LV` on the UAT therefore means power flowing INTO the 6.6 kV bus** — the auxiliary
supply direction. `P_LV` on the GAT is positive in LF2/LF4: the GAT **exports** from the
auxiliary bus (§10.1).

### 6.2 Loading against documented cooling stages

| Case | Transformer | Loading basis (MVA) | vs lowest stage | vs highest stage | Documented stages |
|---|---|---|---|---|---|
| LF1 | GSUT | 375.8208 | **105.87 %** of 355 | 72.97 % of 515 | 355 / 460 / 515 ONAN/ODAN/ODAF |
| LF2 | GSUT | 369.9219 | **104.20 %** of 355 | 71.83 % of 515 | 355 / 460 / 515 |
| LF3 | GSUT | 328.3076 | 92.48 % of 355 | 63.75 % of 515 | 355 / 460 / 515 |
| LF4 | GSUT | 323.9671 | 91.26 % of 355 | 62.91 % of 515 | 355 / 460 / 515 |
| LF1 | UAT | 17.2222 | 90.64 % of 19 | 68.89 % of 25 | 19 / 25 ONAN/ONAF |
| LF2 | UAT | 20.8054 | **109.50 %** of 19 | 83.22 % of 25 | 19 / 25 |
| LF3 | UAT | 17.2226 | 90.65 % of 19 | 68.89 % of 25 | 19 / 25 |
| LF4 | UAT | 19.2640 | **101.39 %** of 19 | 77.06 % of 25 | 19 / 25 |
| LF1 | GAT | 0.0193 | 0.10 % of 19 | 0.08 % of 25 | 19 / 25 |
| LF2 | GAT | 7.7128 | 40.59 % of 19 | 30.85 % of 25 | 19 / 25 |
| LF3 | GAT | 0.0192 | 0.10 % of 19 | 0.08 % of 25 | 19 / 25 |
| LF4 | GAT | 6.5041 | 34.23 % of 19 | 26.02 % of 25 | 19 / 25 |

Answer **Q11a** required loading to be reported against **all** documented ratings rather
than one chosen cooling stage. Both columns are given, and the basis column states the MVA
the percentage was taken on.

### 6.3 A definition difference between two of the result files — read this before quoting a loading

`transformer_results.csv` computes `Loading_pct_lowest_stage` on
**`max(S_from, S_to)`** — the more heavily loaded terminal. That is the correct definition
and it is **not always the HV end**.

`system_summary.csv` columns `S_GSUT_MVA`, `S_UAT_MVA`, `S_GAT_MVA` carry the
**from‑end (LV) value only**.

For the GSUT the LV end happens to be the larger, so the two agree. **For the UAT they do
not**: in LF1 the HV end carries 17.2222 MVA against 16.4853 MVA at the LV end, and the
90.64 % figure comes from the HV end. Quoting `S_UAT_MVA` from `system_summary.csv` and
dividing by 19 gives 86.76 %, understating the loading by 3.88 percentage points.

**Use `transformer_results.csv` for loading. Use `system_summary.csv` for the per‑case
one‑line overview.** This is stated because the discrepancy is real, small, and exactly the
kind that survives into a report unnoticed.

### 6.4 Taps

All three transformers are at their **documented principal tap** (answer **Q8a** — documented
taps, not optimised):

| Transformer | Tap range | Tap used | Voltage at that tap | Off‑nominal ratio in the model |
|---|---|---|---|---|
| GSUT 10BAT10 | OLTC, 25 taps | **9** (principal) | 230000 V | 1.000000 |
| UAT 10BBT10 | off‑circuit HV, 5 taps | **3** (principal) | 22000 V | 0.956522 (= 6600/6900) |
| GAT 10BBT20 | OLTC, 25 taps | **13** (principal) | 230000 V | 0.956522 (= 6600/6900) |

The 0.956522 ratios are treatment **S4** made explicit: the 6.9 kV winding is modelled into
a 6600 V base rather than a 6.9 kV bus being invented (S3). Without this the MV bus voltage
would be misplaced by ~4.5 %. `test_transformer_phase_shift` (18 assertions) confirms the
vector groups YNd1 / Dyn11 / YNyn0 produce +30° / −30° / 0° in the solved model.

---

## 7. 230 kV branch and boundary results

### 7.1 The grid equivalent

| Case | V_from (pu) | V_to (pu) | I (A) | P_from (MW) | Q_from (MVAr) | S_from (MVA) | P_loss (MW) | Q_loss (MVAr) |
|---|---|---|---|---|---|---|---|---|
| LF1 | 1.000000 | 0.998686 | 942.99 | −374.4839 | +29.7049 | 375.6602 | 0 | 7.0849 |
| LF2 | 1.000000 | 0.998502 | 943.72 | −374.4667 | +33.3646 | 375.9502 | 0 | 7.0958 |
| LF3 | 1.000000 | 0.998974 | 823.72 | −327.3302 | +23.1365 | 328.1468 | 0 | 5.4060 |
| LF4 | 1.000000 | 0.998785 | 824.41 | −327.3199 | +26.8917 | 328.4227 | 0 | 5.4151 |

`P_from` is signed from the grid into the plant, so a negative value means **the plant
exports**. The plant exports MW and **absorbs** MVAr in all four cases.

`P_loss = 0` exactly, in every case, because **R = 0 is assumption A1** — not because the
grid connection is lossless. §10.3 quantifies what that omission costs.

### 7.2 Currents against the one documented 230 kV limit

The only continuous rating the source set states for the 230 kV switchgear is the
**Siemens 8DN9 busbar rating, 3150 A**. There is no outgoing transmission line in this
model: answer **Q7a** placed the grid equivalent at the plant boundary and forbade
inventing a 70 km line. Loading at 230 kV is therefore reported as **current against
3150 A**, which is a documented comparison, rather than as MVA against a line rating that
does not exist.

| Path | LF1 | LF2 | LF3 | LF4 | Max | % of 3150 A |
|---|---|---|---|---|---|---|
| ZGRID, plant boundary | 942.99 A | 943.72 A | 823.72 A | 824.41 A | **943.72 A** | **30.0 %** |
| GSUT bay 10BAY11 | 942.99 A | 928.19 A | 823.73 A | 812.83 A | **942.99 A** | **29.9 %** |
| GAT bay 10BAY20 | 0.009 A | 19.39 A | 0.008 A | 16.35 A | **19.39 A** | **0.6 %** |

**Every 230 kV bay runs at or below 30 % of the documented busbar continuous rating in
every case.** The 230 kV switchgear is nowhere near a thermal limit in this study. Whether
it is adequate for **fault** duty is a different question that this study does not address —
the 50 kA/1 s and 125 kA peak withstand figures are documented but no short‑circuit
calculation has been run.

### 7.3 Two branches that carry no flow number, and why

| Branch | Cases | Reported as | Reason |
|---|---|---|---|
| BUS COUPLER 10BAY12 | all four | **all NaN** | Closed zero‑impedance breaker. The solver merges BUS 1 and BUS 2 into one node, so the coupler flow is **not observable from bus voltages**. NaN means *unobservable*, not *zero*. |
| GAT BAY CB 10BAY20 | LF1, LF3 only | 0.009 A / 0.008 A through a 1e6 Ω path | The Simscape snubber. It exists so the open breaker leaves the GAT HV terminal at a **defined** voltage instead of a floating node. It is a **numerical artefact of the block, not plant equipment**, and its 0.25 kW / 0.18 kW is retained in the loss balance only so the balance closes exactly. |

In LF2/LF4 the GAT bay has **no row at all** in `line_results.csv`. This is a reporting
choice, not a merge: `ashuganj_branch_flows.m` emits a bay row only when the breaker is
**open**, because the only thing worth recording in that state is the snubber artefact.
Closed, the bay's flow is fully observable — it is the GAT transformer's HV terminal flow in
§6.1 (5.87 MW / −5.00 MVAr, 19.39 A in LF2) — and the node either side of it stays distinct,
separated by the breaker's 0.01 Ω contact resistance. Nothing is hidden; the number is simply
reported once, on the transformer, rather than twice.

---

## 8. Power balance

### 8.1 Real power

| | LF1 | LF2 | LF3 | LF4 |
|---|---|---|---|---|
| Generator output P (MW) | 389.3000 | 389.3000 | 342.0100 | 342.0100 |
| less auxiliary load (MW) | 14.0000 | 14.0000 | 14.0000 | 14.0000 |
| less total losses (MW) | 0.816124 | 0.833262 | 0.679838 | 0.690119 |
| **= exported at boundary (MW)** | **374.4839** | **374.4667** | **327.3302** | **327.3199**  |
| closure residual (MW) | 5.68e‑14 | −4.55e‑13 | 5.68e‑13 | −5.68e‑13 |
| losses as % of generation | 0.20964 % | 0.21404 % | 0.19878 % | 0.20178 % |

### 8.2 Where the losses are

| Element | LF1 (kW) | LF2 (kW) | LF3 (kW) | LF4 (kW) |
|---|---|---|---|---|
| GSUT 10BAT10 | 733.942 | 715.995 | 597.726 | 586.165 |
| UAT 10BBT10 | 60.829 | 82.857 | 60.831 | 72.989 |
| GAT 10BBT20 | 21.102 | 34.375 | 21.102 | 30.936 |
| GAT bay snubber (artefact) | 0.251 | — | 0.179 | — |
| ZGRID (**0 by assumption A1**) | 0 | 0 | 0 | 0 |
| **sum of components** | **816.124** | **833.227** | **679.838** | **690.090** |
| reported system total | 816.124 | 833.262 | 679.838 | 690.119 |
| unexplained remainder | 2.6e‑04 | 0.035 | 1.7e‑04 | 0.029 |

The remainder tracks the KCL residual of §4 — negligible in the radial cases, ~0.03 kW in
the looped ones. Nothing is unaccounted for.

**Iron/copper split, independently checked.** `test_magnetising_sensitivity` reconstructs
LF1's total loss from nameplate data alone: **0.1937 MW iron** (the documented no‑load
losses 159 + 14 + 23 kW, at the solved voltages) **+ 0.6194 MW copper** (nameplate R at the
solved loadings) **= 0.8131 MW**, reproducing the solved 0.8161 MW to **0.37 %**. That is
independent confirmation that both R and Rm entered the model correctly.

### 8.3 Reactive power — a check that is not in any result file

Reactive balance is arithmetic on solved outputs, computed here rather than read from a CSV:

| | LF1 | LF2 | LF3 | LF4 |
|---|---|---|---|---|
| Generator Q output (MVAr) | +31.15946 | +27.00274 | +25.65834 | +21.54914 |
| plus Q imported from grid (MVAr) | +29.70489 | +33.36461 | +23.13655 | +26.89174 |
| less auxiliary Q load (MVAr) | −8.67642 | −8.67642 | −8.67642 | −8.67642 |
| **= net Q supplied (MVAr)** | **52.18793** | **51.69093** | **40.11846** | **39.76445** |
| GSUT Q absorbed (MVAr) | 43.85901 | 42.49272 | 33.46833 | 32.58901 |
| UAT Q absorbed (MVAr) | 1.24403 | 1.81557 | 1.24409 | 1.55644 |
| GAT Q absorbed (MVAr) | 0.0000239 | 0.28682 | 0.0000239 | 0.20388 |
| ZGRID Q absorbed (MVAr) | 7.08487 | 7.09581 | 5.40602 | 5.41512 |
| **= total Q absorbed (MVAr)** | **52.18793** | **51.69092** | **40.11846** | **39.76445** |
| residual (MVAr) | 1.3e‑06 | 4.0e‑06 | 9e‑07 | 4.9e‑06 |

**The reactive balance closes in all four cases to better than 5e‑06 MVAr.** Note where
the reactive power goes: the GSUT alone absorbs **43.86 MVAr** in LF1, more than the
generator produces. The plant is a net **importer** of ~24–33 MVAr from the grid in every
case, entirely because of transformer reactive absorption — there is **no shunt
compensation anywhere in the plant** (treatment S6, no capacitor bank appears on any
drawing).

### 8.4 Generator terminal quantities

Derived from the solved P and Q at exactly 22.000 kV (A5):

| | LF1 | LF2 | LF3 | LF4 |
|---|---|---|---|---|
| S at generator terminals (MVA) | 390.545 | 390.235 | 342.971 | 342.688 |
| terminal current (A) | 10249.2 | 10241.0 | 9000.7 | 8993.2 |
| power factor (lagging) | 0.99681 | 0.99760 | 0.99720 | 0.99802 |
| % of S_nom 458 MVA | 85.27 % | 85.20 % | 74.88 % | 74.82 % |
| % of S_max 518 MVA | 75.39 % | 75.34 % | 66.21 % | 66.16 % |
| % of I_nom 12019 A | 85.27 % | 85.21 % | 74.90 % | 74.83 % |

The nameplate is internally consistent: 12019 A at 22 kV is 457.99 MVA, agreeing with the
458 MVA `S_nom` to 0.003 %.

**The unit runs at ~0.997 lagging power factor, far above its 0.85 rated pf.** At 458 MVA
and 0.85 pf the machine would produce 241.3 MVAr (derived from the nameplate); it produces
21.5–31.2 MVAr here, i.e. **9–13 %** of that. This is a direct consequence of two approved
answers: **Q7a** put the grid equivalent at the plant boundary with no line to charge, and
**A1/Q1a** made that equivalent purely inductive and stiff. The machine has almost nothing
to supply MVAr to. It is not evidence about how the plant is actually excited — no measured
Q dispatch exists, and the reactive capability curve is **not verified** (conflict C4: the
Excel transcription comes from a truncated PSAF record citing an absent page).

**Reactive limits were not enforced.** Answer **Q3a** confirmed the PSAF diesel Q‑limit
values are a template defect (D4), not data. The generator is solved unconstrained with
`Qlim_Status = NOT_APPLICABLE`. The 21.5–31.2 MVAr solved output is comfortably inside any
plausible capability for a 458 MVA machine, so this is unlikely to matter here — but it is
an unenforced limit and is recorded as such.

---

## 9. Independent hand checks

These were computed by hand from documented impedances and compared against the solver.
They are not tests inside the model; they are external arithmetic.

### 9.1 Grid equivalent reactance, recovered from the solution

Q absorbed by ZGRID in LF1 is `3 I² X = 3 × 942.989² × X = 7.084868 MVAr`
→ **X = 2.65582 Ω**, against the documented‑estimate 2.6558 Ω. Agreement to **6 significant
figures**. The impedance in the model is the one intended.

### 9.2 GSUT angle across the transformer

X_GSUT = 16 % on 515 MVA = 3.1068 % on the 100 MVA base = 0.031068 pu.
δ ≈ asin(P·X / V₁V₂) = asin(3.7522 × 0.031068 / (1.000 × 0.998686)) = **6.7025°**.
Solved: `30° − (1.07868 + 22.22509)` = **6.6962°**. Agreement to **0.006°**.

### 9.3 UAT angle across the transformer

X_UAT = 10.5 % on 25 MVA = 42 % on the 100 MVA base = 0.42 pu.
δ ≈ asin(0.14 × 0.42 / (1.00139 × 1.000)) = **3.3672°**.
Solved: `−22.22509 − (−30) − 4.33472` = **3.4402°**. Agreement to 0.073°, the residue being
the off‑nominal ratio and the R term the approximation drops.

### 9.4 GAT iron loss with its bay open — the strongest single check in the study

With bay 10BAY20 **open**, the GAT carries **magnetising current only**, so its entire loss
should be its documented no‑load loss scaled by V².

- Documented GAT no‑load loss: **23 kW**
- 6.6 kV bus voltage in LF1 on the 6900 V winding base: **0.957852 pu**
- Predicted: 23 × 0.957852² = **21.1020 kW**
- Solved: **21.1023 kW**

**Agreement to 0.0003 kW.** This single check simultaneously confirms that (a) the
documented iron loss is present in the model, (b) the off‑nominal 22000/6900‑into‑6600 ratio
of treatment **S4** is implemented as intended, and (c) an open bay genuinely leaves the GAT
carrying no‑load loss alone. LF3 reproduces it: 23 × 0.957848² = 21.1018 kW against a solved
21.1021 kW.

---

## 10. Findings that require engineering attention

### 10.1 The UAT is overloaded in both looped cases — and it is circulating power, not load

**UAT loading rises from 90.64 % to 109.50 % of its 19 MVA ONAN rating (LF1 → LF2), and
from 90.65 % to 101.39 % (LF3 → LF4).** Both looped cases exceed the natural‑cooling
rating. Against the 25 MVA ONAF stage it is 83.22 % and 77.06 %.

**The mechanism is not what it looks like.** Closing bay 10BAY20 with the bus coupler
already closed (A3) completes a loop: 22 kV → GSUT → 230 kV → GAT → 6.6 kV → UAT → 22 kV.
The two paths have very different impedances (16 % on 515 MVA against 12 % on 25 MVA), so
their angles differ and a **circulating export flow** appears. The auxiliary load does not
divide between the UAT and the GAT. Instead:

- In LF2 the 6.6 kV bus settles **1.72° ahead** of the 230 kV bus.
- ≈**5.9 MW of export detours** through the UAT and the GAT instead of going out through
  the GSUT. The GAT **exports** from the auxiliary bus rather than feeding it — `P_LV` is
  **+5.9051 MW**, positive, out of the bus.
- The UAT therefore carries the 14 MW auxiliary load **plus** that circulating 5.9 MW.
  Opposing signs make it explicit: UAT `P_LV` = **−19.9047 MW** against GAT `P_LV` =
  **+5.9051 MW**, differing by **13.9996 MW** — the 14.000 MW auxiliary load, to within the
  KCL residual of §4.
- Confirmed independently on the GSUT: HV throughput falls **374.486 → 368.596 MW**, a
  5.890 MW reduction matching the 5.871 MW arriving via the GAT.
- **Total export barely moves**: 374.4839 → 374.4667 MW. Only the *routing* changes. The
  detour costs about **17 kW**.

**Operational caveat — recorded, not acted on.** Paralleling the UAT and the GAT onto one
6.6 kV bus from two different sources is normally an **interlocked transfer** condition —
momentary, during changeover — not a steady state, precisely because it parallels two
sources through the auxiliary system. The measured overload is consistent with that reading.
**The source set contains no interlock schedule.** LF2 and LF4 are therefore solved and
reported exactly as approved answer **Q4c** specifies, and this is flagged rather than used
as grounds to quietly drop them. **If an interlock schedule is later found and forbids the
parallel, LF2 and LF4 become transfer‑transient cases and must be re‑described as such —
their steady‑state UAT loadings would then not represent any continuous operating state.**

### 10.2 The GSUT runs above its ONAN rating at rated dispatch

**105.87 % of 355 MVA in LF1, 104.20 % in LF2.** This is normal for a generator step‑up
transformer, which is specified to run on forced cooling at full load — that is what the
460 MVA ODAN and 515 MVA ODAF stages are for, and against 515 MVA the loading is only
72.97 %. It is reported because a "105.87 %" figure must not be quoted without the cooling
stage it belongs to, and because it means **the GSUT's ONAN stage is not a valid rating for
continuous rated‑dispatch operation** — a fact relevant to any later cooling‑failure or
overload‑protection study.

### 10.3 The grid data is the weakest part of the model — and the *assumed* half matters more than the *estimated* half

Two separate weaknesses sit on the same branch:

- **|Z| = 2.6558 Ω is `ESTIMATED`**, back‑calculated from a GIS withstand rating. Answer
  **Q1a** was explicit that no verified PGCB grid strength exists and this must be labelled
  an estimate, never verified data.
- **X/R = ∞ (R = 0) is `ENGINEERING_ASSUMPTION` A1.**

`test_grid_sensitivity` holds |Z| at 2.6558 Ω and sweeps only the R/X split:

| X/R | Boundary V (pu) | Boundary angle (°) | Q_gen (MVAr) | Grid loss (MW) |
|---|---|---|---|---|
| ∞ (as built) | 0.998686 | +1.0787 | +31.1595 | 0 |
| 20 | 0.999497 | +1.0801 | +28.5344 | 0.3535 |
| 10 | **1.000304** | +1.0795 | **+25.9209** | **0.7040** |
| 5 | 1.001889 | +1.0729 | +20.7928 | 1.3862 |

Three consequences, all measured:

1. **R = 0 makes the model pessimistic on voltage, not optimistic.** The boundary voltage
   *rises* as R is introduced. An earlier version of the assumption record claimed the
   opposite; the measurement corrected it, and the wrong wording is preserved in
   `docs/validation/assumptions.md` so the correction is auditable.
2. **Q_gen is understated by up to 16.8 % at X/R = 10, 33.3 % at X/R = 5.** MW is
   unaffected (389.30 MW is a dispatch setpoint, spread 4.3e‑08 MW).
3. **"System loss" changes meaning, not just value.** At X/R = 10 the grid equivalent would
   dissipate 0.704 MW — comparable to the plant's own 0.816 MW. The 0.21 % loss figure in
   §8.1 is *plant* loss, not system loss.

**The most consequential result is a comparison.** Moving X/R from ∞ to 10 shifts the
boundary voltage by **1.62e‑03 pu**. *Doubling* the estimated |Z| shifts it by only
**1.27e‑03 pu**. The number that is merely **assumed** matters *more* than the
acknowledged‑weakest **estimated** number. The mechanism: this plant delivers **+3.745 pu
of P against −0.297 pu of Q** at the boundary, a ratio of **12.6 : 1**, so the R·P term
dominates the X·Q term and the usual "transmission is mostly reactive" intuition inverts.
Hand check: R = 0.2643 Ω = 4.995e‑04 pu on the 529 Ω base, × 3.738 pu = **+1.867e‑03 pu** —
right sign, slightly above the measured 1.619e‑03 pu rise, the balance being the smaller
X·Q term moving the other way.

**Therefore both grid numbers must be flagged as limiting.** Flagging the 2.6558 Ω estimate
alone understates the uncertainty at the plant boundary.

### 10.4 Nothing else is loaded

Away from the UAT in the looped cases and the GSUT's ONAN stage, the plant is comfortable:
230 kV bays at ≤30 % of the documented busbar rating, the generator at ≤85.3 % of `S_nom`
and ≤75.4 % of `S_max`, plant voltage spread ≤2.25 %, plant losses ≤0.214 % of generation.

---

## 11. The data‑integrity register that applies to these results

### 11.1 Assumptions in the model

| # | Assumption | Approved | Effect on the numbers above |
|---|---|---|---|
| **A1** | External grid R = 0 (X/R = ∞) | ✅ Q1a | §10.3 — Q_gen understated up to 16.8 %; boundary voltage pessimistic by 0.16 %; grid loss reported as 0 |
| **A2** | Auxiliary load split 9050 : 2500 : 2500 kW | ✅ Q6B | **None on any solved quantity** — the three 6.6 kV nodes are one electrical node (S7). It changes which row a number is printed on |
| **A3** | 230 kV bus coupler closed | ✅ Q9a | Closes the loop in LF2/LF4 → §10.1. Also makes per‑bay busbar selection (Q10a) immaterial — **reverse A3 and that becomes first‑order** |
| **A4** | Transformer magnetising inductance L_m = 1e6 pu (open) | ❌ **NOT APPROVED** | Reactive absorption **understated by up to +3.4406 MVAr = 11.04 % of Q_gen**; everything else ≤0.0015 MW / ≤1.7e‑03 pu |
| **A5** | Generator voltage setpoint 1.00 pu at the 22 kV bus | ❌ **NOT APPROVED** | **The datum for every per‑unit voltage in §5.** The 22 kV bus reads 1.000000 pu *because it was set to* |

**A4 and A5 need your decision.** Neither was ever put to you as a Phase‑6 question — the
need for both appeared only when the blocks were parameterised. They are surfaced here
rather than buried.

- **A4** is bounded by measurement. Closing L_m to 500/200/100 pu (≈0.2/0.5/1.0 %
  magnetising current) raises Q_gen monotonically to +31.85/+32.88/+34.60 MVAr. Worst case
  **+3.4406 MVAr**, at a 1 % magnetising current well above what units of this class show.
  It moves the 6.6 kV bus by at most 1.66e‑03 pu — **27× less than conflict C13 moves the
  same bus.** *What would close it:* the no‑load current or excitation curve from any of the
  three transformer test reports. Note that the no‑load **loss** is documented and already
  in the model (§9.4); only the no‑load **current** is missing.
- **A5 cannot be bounded the same way.** 0.98 and 1.02 pu are equally defensible operating
  points. It is not an error bar — it is the reference. *What would close it:* the AVR
  setpoint, a voltage schedule, or one measured 22 kV reading.

### 11.2 The conflict that affects a reported number

**C13 — UAT/GAT LV winding 6.9 kV against plant MV bus 6.6 kV nominal.** Both values are
preserved, both sources identified, neither silently chosen. Consequence: the 6.6 kV bus
voltage is reported on **both** bases in §5.1, differing by **4.55 %**. Rebasing an
impedance across the same gap inflates it by **9.2975 %**. Structural treatments S3 and S4
state how the model handles it (no 6.9 kV bus; the ratio modelled explicitly) — that is a
*modelling* decision, and it does not resolve the *source* conflict.

### 11.3 Missing parameters that this study did **not** need

Reported for completeness, and because the next phase will need most of them:

| Missing | Status | Consequence for this load flow |
|---|---|---|
| Generator x_q, x_q″, x₂, x₀, R_a, H, T_d0′ | MISSING | **None** — a balanced load flow uses none of them. **All are required for fault analysis and stability.** |
| Generator Q_max / Q_min | NOT_APPLICABLE (Q3a) | Solved unconstrained; see §8.4 |
| Transformer no‑load current | MISSING | A4 |
| GAT Z_PT, Z_ST | MISSING | **None** — the unloaded stabilising tertiary is omitted per Q5a; documented Z_PS = 12 % is used |
| 6.6 kV water‑intake feeder impedances | MISSING | Merges three nodes into one (S7); makes A2 inconsequential |
| Outgoing 230 kV line R₁/X₁ | Declined (Q7a) | No line invented; grid equivalent sits at the plant boundary |
| Verified PGCB grid strength | ESTIMATED only | §10.3 |
| 230 kV voltage tolerance band | MISSING | Voltages reported without a pass/fail limit (Q8a) |
| Bus coupler normal state | MISSING | A3 |
| Measured operating dispatch | MISSING | Two dispatches compared instead (Q2c) |

Full register: `docs/validation/missing_parameters.md`, `conflicting_parameters.md`,
`verified_parameters.md`.

---

## 12. Figures

`results/plots/`

| Figure | Shows |
|---|---|
| `bus_voltage_profile.png` | The four true busbars in **electrical path order** (grid → 230 kV → 22 kV → 6.6 kV), all four cases, annotated with A5 and C13. `GAT_HV` is in a **separate panel** because with its bay open it sits at the turns ratio, not a system voltage |
| `transformer_loading.png` | Two panels: absolute MVA on a **log axis** so a 375 MVA GSUT and a 0.02 MVA GAT are legible together, and per cent of the **lowest documented cooling stage** on a linear axis with a 100 % line — which is where the UAT overload is actually visible |
| `line_loading.png` | Bay currents against the documented **3150 A** 8DN9 rating, and the signed boundary flow showing MW exported / MVAr absorbed. States that the bus coupler is unobservable rather than zero |
| `power_balance.png` | Generation → auxiliary → losses → export, per case |

The scale choices are not cosmetic. A 375 MVA GSUT bar on a linear axis compresses a
109.5 % UAT overload into an invisible sliver while the title announces that overload; the
GAT HV terminal drawn in line makes an open breaker look like the largest voltage gradient
in the plant. Both were caught by looking at the rendered figures.

---

## 13. What this study does not establish

1. **No fault or short‑circuit result of any kind.** No 3‑phase, L‑G, L‑L or L‑L‑G fault has
   been applied. The 50 kA / 1 s and 125 kA peak GIS withstand figures are documented but
   uncompared to any calculated fault current. Negative‑ and zero‑sequence generator data is
   **MISSING** and would be required.
2. **No protection coordination, no relay model, no time–current curve, no CT/VT ratio.**
3. **No dynamics.** H and T_d0′ are MISSING; no stability, no swing curve, no governor or
   AVR response. The 0.997 pf in §8.4 is a steady‑state solution, not an excitation study.
4. **No unbalanced solution.** This is a balanced positive‑sequence load flow. Zero‑sequence
   impedances are in the dataset (GSUT 15.8 %, UAT 9.3 %, GAT 10.8 %) but are unused here.
5. **No LV auxiliary distribution.** The 14.000 MW / 8.676 MVAr at 0.85 pf is a lumped
   6.6 kV load. Individual motors, the 400 V boards and the LV transformers are not
   modelled — answer **Q6** declined a per‑motor model. **400 V appears nowhere in this
   study.**
6. **No measured validation.** Not one solved voltage, flow or loss in this report has been
   compared against a plant reading, because the document set contains no measured operating
   data. Every "verified" label in this study refers to a **verified input**, never a
   verified result.
7. **No operating dispatch.** 389.30 MW is rated and 342.01 MW is site‑derated. Neither is
   an observed output.
8. **No tap optimisation.** All transformers sit on documented principal taps (Q8a).
9. **Loading percentages are thermal‑rating comparisons only** — no ambient temperature, no
   loading guide, no time‑varying load cycle.

---

## 14. Reproducing these numbers

Full click‑by‑click instructions, including how to display results inside `powergui` and a
suggested demonstration order, are in **`docs/HOW_TO_RUN.md`**.

The short version, from `matlab/`:

```matlab
ashuganj_setup                 % put the project on the MATLAB path
run_all_tests                  % 434 assertions, must be 0 failed
run_load_flow_study            % builds 4 models, solves, writes every CSV
make_load_flow_plots           % writes the 4 PNGs
```

**Outputs**

| Path | Content |
|---|---|
| `results/load_flow/bus_results.csv` | 32 rows — 8 buses × 4 cases, with `Merged_into` and both 6.6 kV bases |
| `results/load_flow/transformer_results.csv` | 12 rows — 3 transformers × 4 cases, loading on `max(S_from, S_to)` |
| `results/load_flow/line_results.csv` | 10 rows — branches present per case (closed breakers have no row) |
| `results/load_flow/system_summary.csv` | 4 rows — one per case; `S_*` columns are **from‑end**, see §6.3 |
| `results/plots/*.png` | the four figures of §12 |
| `simulink/studies/Load_Flow_LF{1,2,3,4}.slx` | the four solved models, openable and inspectable |
| `simulink/main/Ashuganj_South_Main.slx` | the readable SLD |

Everything is regenerated from `matlab/data/*.m` on every run. **No result file is edited by
hand**, and `simulink/backups/` holds the versioned model history — no working model is
overwritten in place.

---

## 15. Bottom line

The South plant solves cleanly at 50 Hz in all four approved cases, in 2 Newton–Raphson
iterations, with the real balance closing to ~1e‑13 MW and the reactive balance to
~5e‑06 MVAr. Plant losses are 0.199–0.214 % of generation. The 230 kV switchgear runs at no
more than 30 % of its documented continuous current rating. Plant voltage spread is at most
2.25 %.

Three things a reader must carry away with the numbers:

1. **Closing the GAT bay overloads the UAT** — 109.50 % of its 19 MVA ONAN rating in LF2 —
   and it is **circulating power, not auxiliary load**. The parallel this creates is
   normally an interlocked‑transfer condition, and the document set contains no interlock
   schedule to confirm it is a permitted steady state.
2. **The grid equivalent carries two weaknesses, not one**, and the *assumed* X/R matters
   more at the plant boundary than the *estimated* |Z|.
3. **Two assumptions the model cannot run without are disclosed and unapproved** — A4 and
   A5 — and A5 is the datum every per‑unit voltage in §5 is measured against.

---

*Generated from `results/load_flow/*.csv`, which are generated by
`matlab/studies/run_load_flow_study.m`. Cross‑references:
`docs/validation/assumptions.md` · `verified_parameters.md` · `missing_parameters.md` ·
`conflicting_parameters.md` · `solver_behaviour.md` · `topology_validation.md` ·
`load_flow_readiness.md` · `prior_psaf_model_defects.md` · `docs/model/*.md`*
