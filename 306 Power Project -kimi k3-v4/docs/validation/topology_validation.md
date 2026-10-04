# Topology Validation — Ashuganj 450 MW CCPP (South)

Checks run against the reconstructed topology in [`../model/network_topology.md`](../model/network_topology.md) **before** any model is built.

---

## 1. Connectivity

| Check | Result |
|---|---|
| Every plant bus reachable from a source | ✔ **conditional** — reachable, but `B400_UA1`, `B400_UA2`, `B400_ST`, `B400_EU`, `B400_WI` are reachable only through LV transformers that carry **no documented load** |
| Orphaned buses | ✔ **none in the new topology.** (The prior PSAF model had 9 orphans — see `prior_psaf_model_defects.md` D7) |
| Junk / malformed bus records | ✔ none. (`B0`, `B1` and the malformed `0.00000` row from the prior model are discarded) |
| Duplicate bus IDs | ✔ none |
| Every branch has both endpoints defined | ✔ yes |
| Dangling branches | ✔ none. NER 10BAB11, SFC 2000 V, excitation 660 V and the GAT 3320 V tertiary are deliberately not modelled as network branches (see `assumptions.md` — they connect to no documented load) |

## 2. Voltage-level consistency

| Check | Result |
|---|---|
| Both ends of every branch match a declared bus voltage | ✔ yes |
| **400 V never confused with 400 kV** | ✔ verified. The five 400 V boards (10BFA10/20/30, 00BFA10, 10BFE) are at 0.4 kV base. **No 400 kV bus exists in the model** |
| Voltage levels present | ✔ 230 kV, 22 kV, 6.6 kV, 400 V only (plus non-network 2000 V, 660 V, 500 V, 3320 V, 230 V, 110 V DC) |
| 6.9 kV treated as a winding rating, not a bus | ✔ yes — no `B6_9` created |
| Transformer ratios consistent with bus bases | ⚠ **intentional off-nominal**: UAT 22000/6900 and GAT 230000/6900 feed a **6600 V** base bus. This is real plant design, must be modelled explicitly, and is flagged in `conflicting_parameters.md` C7 |
| GSUT ratio 230000/22000 against 230 kV / 22 kV bases | ✔ nominal, ratio 1.0 |

## 3. Loops and radiality

| Check | Result |
|---|---|
| Is the network radial? | **Depends on Q4 and Q9** |
| Loop if GAT in service | ⚠ **YES** — 22 kV → GSUT → 230 kV GIS → GAT → 6.6 kV → UAT → back to 22 kV. A genuine closed loop |
| Loop if bus coupler closed **and** two bays select different busbars | ⚠ **YES** — BUS 1 and BUS 2 become parallel paths |
| Radial if GAT out of service and coupler open | ✔ fully radial |

This is the single most consequential open topology question. A loop is perfectly solvable, but it changes the auxiliary-system flow direction and the loading of both UAT and GAT, and it means the 6.6 kV bus voltage is set by *two* transformers with *different* tap changers.

## 4. Source count and slack consistency

| Check | Result |
|---|---|
| Number of active sources | 2 — G1 (PV) and the external 230 kV grid (slack) |
| EDG counted as a source? | ✔ **no** — Rev 03 Note 4 keeps its disconnector open |
| Exactly one slack bus | ✔ yes, `BGRID230` — but its impedance is incomplete (**Q1**) |
| Islanding risk | ✔ none in the base case |

## 5. Transformer parameter integrity

| Check | Result |
|---|---|
| Every transformer Z quoted **on its own base** | ✔ GSUT 16 %@515 MVA · UAT 10.5 %@25 MVA · GAT 12 %@25 MVA. No premature base conversion |
| X/R derivable from Z and R | ✔ 76.2 / 26.2 / 24.0 (arithmetic shown in `../model/transformer_list.md`) |
| Vector groups and phase shifts consistent | ✔ GSUT YNd1 (30° lag), UAT Dyn11 (30° lead), GAT YNyn0+d11 (0° HV→LV) |
| Tap tables internally consistent | ✔ all three verified against printed voltages **and** printed currents |
| Principal taps identified | ✔ GSUT pos 9, GAT pos 13, UAT pos 3 |
| Three-winding data complete | ✘ **GAT Z_PT and Z_ST missing** (**Q5**) |

## 6. Load balance sanity

| Quantity | Value |
|---|---|
| Generator rated output | 389.30 MW (458 MVA at pf 0.85) |
| Station auxiliary demand (only stated figure) | 14 MW @ 0.85 pf → 8.676 MVAr |
| Auxiliary share of rated output | 14 / 389.30 = **3.60 %** |
| Implied net export at rated dispatch | 389.30 − 14 = **375.30 MW** (before transformer losses) |
| GSUT loading at rated dispatch, ODAF | ≈458 MVA / 515 MVA = **88.9 %** — plausible ✔ |
| UAT loading carrying 16.47 MVA | 16.47 / 25 = **65.9 %** ONAF, or 16.47 / 19 = **86.7 %** ONAN — plausible ✔ |
| Sum of GSUT + UAT LV current vs generator I_N | consistency depends on dispatch; will be checked after the load flow |

A 3.6 % auxiliary share is at the low end but within normal range for a large combined-cycle unit (typical 2–5 % for CCGT, higher for coal). No red flag.

## 7. Rating-vs-loading pre-checks

| Item | Rating | Expected duty | Verdict |
|---|---|---|---|
| GSUT ODAF | 515 MVA | ≈458 MVA at rated generator output | ✔ 89 % |
| GSUT ONAN | 355 MVA | would be **exceeded** at rated output | ⚠ the in-service cooling stage matters (**Q11**) |
| UAT ONAF | 25 MVA | 16.47 MVA | ✔ 66 % |
| GAT ONAF | 25 MVA | 0 if out of service; shares MV load if in | depends on **Q4** |
| GCB 10BAC10 | 12.4 kA | gen I_N 12019 A = 12.0 kA | ✔ 97 % — tight but correct by design |
| 230 kV GIS gen-transformer module | 2000 A | 458 MVA/(√3×230 kV) = 1150 A | ✔ 57 % |
| MV busbar 10BBA10 | 3150 A | 16.47 MVA/(√3×6.6 kV) = 1441 A | ✔ 46 % |
| MV motor feeder CBs | 1250 A | 2265 kW motor ≈ 232 A at 6.6 kV, pf/η unknown | ✔ ample |
| Water-intake busbars 10BBW10/20 | 1250 A | 2500 kW rated ≈ 256 A | ✔ ample |
| GSUT tap 25 (184 kV) HV current, ODAF | 1616 A | vs GIS module 2000 A | ✔ within |

The GCB at 97 % of rating is worth noting: it is normal for a generator breaker to be sized just above I_N, and 12.4 kA vs 12.019 kA is a deliberate 3 % margin, not an error.

## 8. Frequency and base consistency

| Check | Result |
|---|---|
| System frequency | ✔ **50 Hz** from every South document |
| Prior model frequency | ✘ **60 Hz** — a defect, not a data source (`prior_psaf_model_defects.md` D6) |
| System base MVA | ✘ **undecided** (**Q11**). Prior study used 100 MVA |
| Base voltages per bus | ✔ 230 / 22 / 6.6 / 0.4 kV, matching Excel `11_NOMINAL_VS_RATED` |
| Um values kept out of the base set | ✔ 245 kV and 7.2 kV are insulation classes, not bases — Excel `11_NOMINAL_VS_RATED` agrees ("Not bus kV Base") |

## 9. Unresolved topology items

| Item | Question |
|---|---|
| GAT in service or standby | **Q4** |
| GIS bus coupler closed or open | **Q9** |
| Which busbar each bay selects (Q1 → BUS 2 / Q2 → BUS 1) | **Q10** |
| Outgoing 230 kV line modelled or grid attached at the busbar | **Q7** |

Until these are answered, the topology above is the **documented physical arrangement**, not a study case. No model will be built on a guessed switching state.
