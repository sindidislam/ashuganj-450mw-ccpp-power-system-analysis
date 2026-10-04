# Bus List — Ashuganj 450 MW CCPP (South)

Source of every bus: `INEL-112070-00-ELC-DE-0001-REV3.pdf` p.2 unless noted. Bus IDs follow the prior model's convention for continuity; KKS tags are the plant's own.

`Type` is the **load-flow bus type once the study case is agreed** — not yet fixed, because the slack/PV assignment depends on questions Q1 and Q2.

| # | Bus ID | KKS tag | Description | V_nom | V base | Rated A | I_sc | Tolerance | Intended type | Source |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | `B230_1` | 230 kV BUS 1 | GIS busbar 1 | 230 kV | 230 kV | 3150 A | 50 kA | not documented | PQ (or slack if grid attached here) | Rev 03 p.2; Data Sheet_230KV |
| 2 | `B230_2` | 230 kV BUS 2 | GIS busbar 2 | 230 kV | 230 kV | 3150 A | 50 kA | not documented | PQ | Rev 03 p.2; Data Sheet_230KV |
| 3 | `B22G` | 10BTA10/20/30/40 | 22 kV generator terminal / isolated-phase busbar | 22 kV | 22 kV | 12019 A (gen I_N) | 100 kA breaking (GCB) | ±5 % | **PV** (G1) | Rev 03 p.2; generator nameplate |
| 4 | `B6_6` | **10BBA10** | 6.6 kV MV switchgear busbar | 6.6 kV | 6.6 kV | **3150 A** | 31.5 kA (1 s) | ±10 % | PQ | Rev 03 p.2 |
| 5 | `B6_6_WI1` | **10BBW10** | 6.6 kV water-intake switchgear 1 | 6.6 kV | 6.6 kV | 1250 A | 31.5 kA | ±10 % | PQ | Rev 03 p.2 |
| 6 | `B6_6_WI2` | **10BBW20** | 6.6 kV water-intake switchgear 2 | 6.6 kV | 6.6 kV | 1250 A | 31.5 kA | ±10 % | PQ | Rev 03 p.2 |
| 7 | `B400_UA1` | **10BFA10** | 400 V unit auxiliary board 1 | 400 V | 0.4 kV | 4000 A | 50 kA | ±10 % | PQ | Rev 03 p.2 |
| 8 | `B400_UA2` | **10BFA20** | 400 V unit auxiliary board 2 | 400 V | 0.4 kV | 4000 A | 50 kA | ±10 % | PQ | Rev 03 p.2 |
| 9 | `B400_ST` | **10BFA30** | 400 V station board | 400 V | 0.4 kV | 1600 A | 50 kA | ±10 % | PQ | Rev 03 p.2 |
| 10 | `B400_EU` | **00BFA10** | 400 V common/external-user board | 400 V | 0.4 kV | 1600 A | 50 kA | ±10 % | PQ | Rev 03 p.2 |
| 11 | `B400_WI` | **10BFE** | 400 V LV water intake | 400 V | 0.4 kV | 800 A | 50 kA | ±10 % | PQ | Rev 03 p.2 |
| 12 | `BGRID230` | — | **Modelled** external-grid source node | 230 kV | 230 kV | — | — | — | **Slack** | not a plant bus — see note |

---

## Notes

**`BGRID230` is not a plant bus.** It is a modelling node representing the external 230 kV system. The Excel workbook's `02_BUS_PSAF` says the same: *"MODELLED external bus, not an SLD bus."* Whether it sits at the far end of an outgoing line or coincides with the GIS busbar depends on question **Q7**.

**No 6.9 kV bus.** The UAT and GAT LV windings are rated 6.9 kV, but the plant MV system is 6.6 kV nominal (U_m 7.2 kV). Three distinct concepts — winding rating, system nominal, insulation class. The Excel workbook's `13_VALIDATION_NOTES` independently concludes *"B6_9 from prior workbook → Remove as a separate plant bus by default."* The off-nominal 22000/6900 ratio is modelled on the transformer instead.

**No 400 kV bus.** South tops out at 230 kV (see [`network_topology.md`](network_topology.md)).

**Buses not created** (deliberately, because they are not network nodes): SFC 2000 V secondary, excitation 660 V secondary, NER 500 V secondary, GAT 3320 V stabilizing tertiary, 230 V lighting, 110 V DC. None carry load-flow power to a documented load.

**Transformers are not buses.** 10BAT10, 10BBT10 and 10BBT20 are branches. The Excel `13_VALIDATION_NOTES` flags the same point.

---

## Voltage limits

| Level | pu min / max | Basis |
|---|---|---|
| 22 kV | 0.95 / 1.05 | Generator nameplate 22 kV **±5 %** |
| 6.6 kV | 0.90 / 1.10 | Rev 03 SLD **Note 1**: 6.6 kV ±10 % |
| 400 V | 0.90 / 1.10 | Rev 03 SLD **Note 1**: 400 V ±10 % |
| 230 kV | **not documented** | No South document states a 230 kV operating tolerance. The Excel `13_VALIDATION_NOTES` explicitly warns *"0.9/1.1 at all buses → Not universally source-confirmed."* A limit will not be invented — see question **Q8** |

## Initial voltages

No measured or solved bus voltage exists in any source document. The prior model's 1.0 pu / 0° values are **initialisation only** — the Excel `12_PSAF_BUS_FIELD_GUIDE` states this explicitly, and `13_VALIDATION_NOTES` confirms *"no measured solved bus voltage/angle supplied."* They will be used as solver starting points and reported as such, never as results. The prior model's `B400_EU` = 1.1 pu / 1° is an anomaly and is discarded.
