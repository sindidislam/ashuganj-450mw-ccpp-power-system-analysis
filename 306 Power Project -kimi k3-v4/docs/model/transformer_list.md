# Transformer List — Ashuganj 450 MW CCPP (South)

All impedances are quoted **on the manufacturer's own base**, exactly as documented. Conversion to a system base happens only in `matlab/utilities/convert_to_system_base.m`, never by editing the source value.

---

## Main transformers

| Item | GSUT **10BAT10** | UAT **10BBT10** | GAT **10BBT20** |
|---|---|---|---|
| Function | Generator step-up | Unit auxiliary | Station/grid auxiliary |
| From bus | `B22G` (22 kV) | `B22G` (22 kV) | `B230_1`/`B230_2` (230 kV) |
| To bus | `B230_1`/`B230_2` (230 kV) | `B6_6` (6.6 kV) | `B6_6` (6.6 kV) |
| Manufacturer | Siemens Transformer (Guangzhou) | Siemens Transformer (Wuhan) | Siemens Transformer (Wuhan) |
| Type / serial | S/N 881264 (2014) | TLUMTA44 / S/N 100579 | TLSN7A54 / S/N 100580 |
| Windings | 2 | 2 | **3** (HV, LV, stabilizing delta) |
| Rated voltages | 230 / 22 kV | 22 / **6.9** kV | 230 / **6.9** / **3.32** kV |
| Vector group | **YNd1** | **Dyn11** | **YNyn0+d11** |
| Phase shift | LV lags HV 30° | LV leads HV 30° | 0° HV→LV |
| Rated power | **355 / 460 / 515 MVA** (ONAN/ODAN/ODAF) | **19 / 25 MVA** (ONAN/ONAF) | **19 / 25 MVA** (ONAN/ONAF) |
| Winding MVA | — | — | 25 / 25 / **8.33** MVA |
| **Z (main tap)** | **16.0 %** @ **515 MVA** | **10.5 %** @ **25 MVA** | **12.0 %** @ **25 MVA** (HV‑LV) |
| Z (min/max tap) | 15.5 % / 16.9 % @ 515 MVA | not documented | not documented |
| R | 0.21 % @ 515 MVA (75 °C) | ≈0.4 % @ 25 MVA | ≈0.5 % @ 25 MVA |
| X/R (derived) | **76.2** | **26.2** | **24.0** |
| Z₀ | 15.8 % @ 515 MVA | ≈9.3 % @ 25 MVA | ≈10.8 % @ 25 MVA |
| Z_PT | n/a | n/a | **MISSING** |
| Z_ST | n/a | n/a | **MISSING** |
| Tap changer | OLTC VACUTAP 3×VRF I 1601Y‑72.6/C | **Off-load** DU III 600‑36‑6605(M)E | OLTC VM III 350Y‑123/C |
| Tap range | 230 **+8×1.25 % / −16×1.25 %** | 22 ±2.5 % ±5 % | 230 **±12×1.25 %** |
| Tap positions | **25** (253000 … 184000 V) | **5** (23100 … 20900 V) | **25** (264500 … 195500 V) |
| **Principal tap** | **position 9 = 230000 V** | **position 3 = 22000 V** | **position 13 = 230000 V** |
| No-load loss | 159 kW | 14 kW | 23 kW |
| Load loss | 523 / 874 / 1095 kW at 355/460/515 MVA, 75 °C | 110 kW @ 25 MVA | 116 kW @ 25 MVA |
| BIL HV | LI 1050 / AC 460 kV | 24 / 125 / 50 kV | 245 / 1050 / 460 kV |
| BIL LV | LI 125 / AC 50 kV | 7.2 / 60 / 20 kV | 7.2 / 60 / 20 kV |
| Neutral BIL | HV‑N LI 250 / AC 95 kV | LV‑N 7.2/60/20 | HV‑N 52/250/95; LV‑N 7.2/60/20 |
| SC withstand duration | 3 s | not stated on plate | 3 s |
| HV connection | **XLPE cable 230 kV** | 22 kV IPB from `B22G` | **SF₆ bus duct** |
| Temp rise oil / winding | 60 / 65 K | not on plate extract | not on plate extract |
| Oil | Nytro Gemini X, 108 t | 5720 L | 22857 L |
| Total mass | 442 t (transport 267 t, untanking 225 t) | 38.1 t | 68 t |
| Cooling plant | 4 × 1.4 kW pumps, 18 × 2.2 kW fans | ONAF fans | ONAF fans |
| **Z on rating plate** | **blank** | **blank** | **blank** |

### X/R derivations (arithmetic shown)
- GSUT: X = √(16.0² − 0.21²) = 15.99862 % → X/R = 76.19. Independently corroborated by the prior model's `txvar.DBF` value **76.200**.
- UAT: X = √(10.5² − 0.4²) = 10.49238 % → X/R = 26.23.
- GAT: X = √(12.0² − 0.5²) = 11.98958 % → X/R = 23.98.

### Off-nominal ratio — must be modelled explicitly
UAT and GAT LV windings are wound for **6.9 kV** while the plant MV bus is **6.6 kV** nominal. Modelling 22/6.6 instead of 22/6.9 into a 6.6 kV base would misplace the MV bus voltage by roughly (6.9/6.6 − 1) = **+4.5 %**. See [`../validation/conflicting_parameters.md`](../validation/conflicting_parameters.md) **C7**.

### GAT three-winding limitation
Only Z_PS is documented. Building the star equivalent (Z_P, Z_S, Z_T) needs Z_PS, Z_PT and Z_ST. The tertiary is a **stabilizing** delta with no external load, so a two-winding 230/6.9 kV representation at Z = 12 % is defensible — but that is a modelling choice requiring approval (**Q5**), not a data value.

---

## Auxiliary / LV transformers (Rev 03 SLD p.2)

Recorded for completeness. **None is load-flow blocking, because no LV load data exists to flow through them.**

| Tag | From | To | Rating | Ratio | Group | Z | Cooling |
|---|---|---|---|---|---|---|---|
| **10BFT10** | `B6_6` | `B400_UA1` | 2500 kVA | 6600 ±2.5 ±5 % / 420 V | Dyn11 | **10.75 %** | ONAN |
| **10BFT20** | `B6_6` | `B400_UA2` | 2500 kVA | 6600 ±2.5 ±5 % / 420 V | Dyn11 | **10.75 %** | ONAN |
| **10BFT30** | `B6_6` | `B400_ST` | 1000 kVA | 6600 / 420 V | Dyn11 | 6 % | — |
| **00BFT10** | `B6_6_WI1` | `B400_EU` | 1000 kVA | 6600 / 420 V | Dyn11 | 6 % | — |
| **10BFT40** | `B6_6_WI2` | `B400_WI` | 400 kVA | 6600 / 420 V | Dyn11 | 4 % | AN |
| **10BMV10** (SFC) | `B6_6` | 2000 V drive | 3400 kVA | 6600 ±2.5 ±5 % / **2000 V** | Dy5 | 4.7 % | AN |
| Excitation transformer | `B6_6` | 660 V exciter | **3560 kVA** | 6600 ±2.5 ±5 % / **660 V** | Dy5 | 6 % | AN |
| 10BTL10/20/30/40 | 400 V boards | control | **30 kVA** each | 400 ±2.5 ±5 % V | — | — | — |
| 10BLA10, 10BLA20 | 400 V boards | lighting | **400 kVA** each | — | — | — | AN |
| 00BLA10 | `B400_EU` | lighting | 100 kVA | — | — | — | AN |
| **10BAB11** (NER) | `B22G` neutral | earth | 135 kVA / 20 s | 22/√3 : 500 V | — | R_HV 60 Ω + 2.62 Ω | — |

⚠ The Excel workbook sheet `06_AUX_TRANSFORMERS` marks Rev **00** values for several of these rows as "CONFIRMED" while citing the Rev **03** drawing (10BFT10/20 as 6 % instead of 10.75 %; excitation as 2.5 kV/3550 kVA instead of 660 V/3560 kVA; SFC as 2.5 kV instead of 2.0 kV; control as 40 kVA instead of 30 kVA; Dyn1 instead of Dyn11). The table above follows the **Rev 03 drawing**. See conflict **C16**.

## Emergency diesel generators — not transformers, recorded here for completeness
10BUK01 and 10BUK02, 1000 kVA, cos φ 0.8, 400 V. Rev 03 **Note 4**: *"DISCONNECTOR SWITCH WILL REMAIN OPEN WHILE EDG IS SYNCHRONIZED WITH THE GRID"* → normally out of service, **not** load-flow sources.
