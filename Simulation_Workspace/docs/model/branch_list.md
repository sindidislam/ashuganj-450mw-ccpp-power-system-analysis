# Branch List — Ashuganj 450 MW CCPP (South)

Every physical branch shown on `INEL-112070-00-ELC-DE-0001-REV3.pdf` p.2, cross-checked against `GENERATION AND TRANSFORMERS SYSTEM.pdf` (INEL‑…‑DE‑0023 Rev 03).

**Impedance-bearing branches are transformers only.** No line or cable impedance exists anywhere in the project data.

---

## 1. Transformer branches (impedances documented)

| ID | Tag | From | To | Ratio | MVA | Z | Base | Group | Tap (principal) |
|---|---|---|---|---|---|---|---|---|---|
| `T_GSUT` | 10BAT10 | `B22G` | `B230_1`/`B230_2` | 230/22 kV | 355/460/**515** | **16.0 %** | 515 MVA | YNd1 | 25 pos, **9** |
| `T_UAT` | 10BBT10 | `B22G` | `B6_6` | 22/**6.9** kV | 19/**25** | **10.5 %** | 25 MVA | Dyn11 | 5 pos, **3** |
| `T_GAT` | 10BBT20 | `B230_1`/`B230_2` | `B6_6` | 230/**6.9**/3.32 kV | 19/**25** | **12.0 %** (Z_PS) | 25 MVA | YNyn0+d11 | 25 pos, **13** |

Auxiliary LV transformers (`10BFT10/20/30/40`, `00BFT10`, `10BMV10`, excitation, `10BTL*`, `10BLA*`) are listed in [`transformer_list.md`](transformer_list.md). They are physically present but carry **no documented load**, so they are recorded and not energised in the base load flow.

---

## 2. Conductive links (zero or unknown impedance)

| ID | Description | From | To | Documented as | Impedance |
|---|---|---|---|---|---|
| `IPB_GEN` | Isolated-phase busbar 10BTA10/20/30/40 | G1 terminals | `B22G` | "IPB" on Rev 03 | **not documented** — physically negligible |
| `CBL_GSUT_HV` | **XLPE cable 230 kV** | GSUT HV | GIS gen-transformer bay | "XLPE CABLE 230 kV → To 230 kV GIS" | **MISSING** (no length, no cross-section, no Z) |
| `DUCT_GAT_HV` | **SF₆ bus duct** | GAT HV | GIS bay 10BAY20 | "SF₆ BUS DUCT → To 230 kV GIS" | **MISSING** (no length, no Z) |
| `BUSDUCT_MV` | 6.6 kV switchgear busbar 10BBA10 | — | — | 3150 A, 31.5 kA | negligible; not documented |
| `FDR_WI1` | 6.6 kV feeder to water intake 1 | `B6_6` | `B6_6_WI1` | Rev 03 p.2 | **MISSING** (cable data not supplied) |
| `FDR_WI2` | 6.6 kV feeder to water intake 2 | `B6_6` | `B6_6_WI2` | Rev 03 p.2 | **MISSING** |

**How these will be handled:** the GSUT XLPE cable and the GAT SF₆ duct are short in-station links whose impedance is genuinely negligible against a 16 % / 12 % transformer. They will be modelled as **direct connections with zero impedance**, and that fact will be stated in the results — *not* filled with a "typical cable per-km value*. The 6.6 kV water-intake feeders are the same case. If you want real values, the missing documents are INEL‑112070‑00‑ELC‑DE‑0009 (MV one-line) and the cable schedules.

---

## 3. Switching devices (breakers / disconnectors — status matters, impedance does not)

| Tag | Type | Location | Rating | Normal state |
|---|---|---|---|---|
| **10BAC10** | Generator circuit breaker | 22 kV, between G1 and `B22G` tee | 12.4 kA cont., 100 kA sym rms breaking | closed when generating |
| GIS bay **10BAY11** Q0 | SF₆ CB | 230 kV gen-transformer module | 2000 A, 50 kA | closed |
| GIS bay **10BAY11** Q1 / Q2 | Disconnectors | → BUS 2 / → BUS 1 | — | **MISSING** — which busbar is selected |
| GIS bay **10BAY12** Q0/Q1/Q2/Q9 | CB + disconnectors + earth switch | 230 kV | 2000 A, 50 kA | **MISSING** |
| GIS bay **10BAY20** Q0/Q1/Q2/Q9 | CB + disconnectors + earth switch | 230 kV | 2000 A, 50 kA | **MISSING** |
| GIS **bus coupler** | CB module between BUS 1 and BUS 2 | 230 kV | **3150 A**, 50 kA | **MISSING** |
| Line bay | CB module, outgoing circuit | 230 kV | 2000 A, 50 kA | **MISSING** |
| MV incomers from UAT / GAT to 10BBA10 | 6.6 kV CBs | `B6_6` | 3150 A busbar, 31.5 kA | **MISSING** — determines whether the MV bus is doubly fed |
| MV motor feeders | 6.6 kV CBs | `B6_6` | 1250 A each | closed (per MV MOTOR TABLE) |
| EDG disconnector | 400 V | 10BUK01/02 | — | **OPEN** — Rev 03 Note 4 |

The bus-coupler state (**Q9**), per-bay busbar selection (**Q10**) and the UAT/GAT incomer states (**Q4**) are the four switching unknowns that change the network graph.

---

## 4. Outgoing 230 kV circuit — the one true line

| Parameter | Status |
|---|---|
| Existence | **CONFIRMED** — `Data Sheet_230KV.pdf` lists a **Line module, 2000 A**; both Rev 03 drawings end at "To 230 kV GIS" |
| Identity / destination substation | **MISSING** |
| Length | **MISSING** |
| Number of circuits | **MISSING** |
| R₁, X₁ | **MISSING** |
| B₁ | **MISSING** for 230 kV |
| R₀, X₀ | **MISSING** for 230 kV |

The only line-like numbers in the entire project (R₀ 0.06667 Ω/km, X₀ 0.39472 Ω/km, B₁ 3.4011 µS/km, 70 km) appear in the Google Form under a **400 kV** heading, which belongs to the Ashuganj **North** interconnection and is out of scope. Even there, **R₁ and X₁ are blank** and fault capacity / Z₁ / Z₀ are answered "Contact PGCB". The Excel sheet `07_LINES_CABLES_PSAF` reaches the same conclusion for both rows: status **PARTIAL**, *"Length and electrical impedance data not supplied in reviewed plant documents."*

The document that would fix this is **INEL‑112070‑00‑ELC‑DE‑0026** ("230 kV GIS control, protection & measurement one-line diagram"), cited by the Rev 03 drawings but **not present in the project**.

Decision required — question **Q7**.

---

## 5. Branches deliberately NOT created

| Not created | Reason |
|---|---|
| Any 400 kV branch | South plant has no 400 kV level; the 400 kV GIS is North scope |
| A 6.9 kV bus and its branches | 6.9 kV is a winding rating, not a system bus |
| GAT stabilizing-tertiary branch to anything | The delta is stabilizing only, not externally connected |
| NER 10BAB11 as a series branch | Neutral grounding path; carries no balanced current |
| EDG connections | Normally open per Rev 03 Note 4 |
| Arbitrary PGCB grid buses beyond the single external source | Not in any source document |
