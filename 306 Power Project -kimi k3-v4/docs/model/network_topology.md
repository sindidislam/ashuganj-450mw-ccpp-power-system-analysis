# Reconstructed Electrical Topology — Ashuganj 450 MW CCPP (South)

Reconstructed **from the drawings**, primarily `INEL-112070-00-ELC-DE-0001-REV3.pdf` (main electrical SLD, Rev 03, 17.09.2014, drawing 456‑10‑D‑E‑11010), cross-checked against `GENERATION AND TRANSFORMERS SYSTEM.pdf` (INEL‑112070‑00‑ELC‑DE‑0023 Rev 03, 29.10.2014, protection & measure one-line) and the released rating plates.

**Not** taken from the target sketch in the brief, and **not** taken from the prior CYME PSAF model (see [`../validation/prior_psaf_model_defects.md`](../validation/prior_psaf_model_defects.md)).

---

## Plant configuration

Siemens single-shaft combined-cycle package **SCC5‑PAC 4000F/3000 (1S)** (ref. BD1015‑B‑&EFA010‑700506): one **SGT5‑4000F** gas turbine and one **SST‑3000** steam turbine on a **single shaft** driving **one** generator. This is why a "450 MW" plant has a single 458 MVA machine, and why the proposal's phrase "SGen5‑2000H generatorS" (plural) does not imply two machines — the drawings and the released nameplate show exactly one.

---

## As-drawn topology

```
                                     EXTERNAL 230 kV GRID  (Sk" 19 919 MVA / Ik" 50 kA — ESTIMATED)
                                                  |
                                        [230 kV outgoing circuit]
                                        R1, X1, length, identity = MISSING
                                                  |
                                            LINE BAY (2000 A)
                                                  |
    ============================================ 230 kV BUS 1 ==================================
                        |                                                 |
                  BUS COUPLER (3150 A)   <-- normal state MISSING         |
                        |                                                 |
    ============================================ 230 kV BUS 2 ==================================
              |                                                                       |
        BAY 10BAY11 / 10BAY12                                               BAY 10BAY20
        (GEN TRANSFORMER, 2000 A)                                           (2000 A)
        Q0 CB / Q1->BUS2 / Q2->BUS1 / Q9 earth                              Q0/Q1/Q2/Q9
              |                                                                       |
       XLPE CABLE 230 kV                                                      SF6 BUS DUCT
       (length/Z MISSING)                                                   (length/Z MISSING)
              |                                                                       |
       +-------------+                                                        +-------------+
       | GSUT 10BAT10|  230/22 kV, YNd1                                       | GAT 10BBT20 |  230/6.9/3.32 kV
       | 355/460/515 |  Z = 16 % @ 515 MVA                                    | 19/25 MVA   |  YNyn0+d11
       | MVA         |  OLTC 25 pos, main = 9                                 | 25/25/8.33  |  Zps = 12 % @ 25 MVA
       +-------------+                                                        | MVA         |  OLTC 25 pos, main = 13
              |                                                              +-------------+  Zpt, Zst = MISSING
              |                                                                       |
   ===================== 22 kV GENERATOR BUS =====================                     |
   (isolated-phase busbar 10BTA10/20/30/40)                                            |
        |                    |                     |                                   |
   GCB 10BAC10          UAT 10BBT10           NER 10BAB11                              |
   12.4 kA / 22 kV      22/6.9 kV, Dyn11      22/sqrt3 : 500 V                         |
   100 kA breaking      19/25 MVA             135 kVA / 20 s                           |
        |               Z = 10.5 % @ 25 MVA   60 ohm + 2.62 ohm                        |
        |               off-load 5 tap, main = 3 (22000 V)                             |
        |                    |                                                         |
   +---------+               |                                                         |
   |   G1    |               +--------------------------+   +----------------------- --+
   | SGen5-  |                                          |   |
   | 2000H   |                                    ===== 6.6 kV MV BUSBAR 10BBA10 =====
   | 458 MVA |                                    (3150 A, 31.5 kA)   <-- TWO SOURCES: UAT and GAT
   | 22 kV   |                                              |
   | pf 0.85 |            8 MV motors (9050 kW rated) ------+
   +---------+            10LAC71/72AP001  2265 kW each     |
                          10LCB11/12AP001   770 kW each     |
                          10EKH10AN001/002 1210 kW each     |
                          10PGC1S/20AP001   280 kW each     |
                                                            |
              +---------------------+---------------------+--+-----------+--------------+
              |                     |                     |              |              |
      10BFT10 (2500 kVA)   10BFT20 (2500 kVA)     10BMV10 SFC     Excitation     10BFT30/40
      6.6/0.42 kV Dyn11    6.6/0.42 kV Dyn11      6.6/2.0 kV      6.6/0.66 kV    1000/400 kVA
      Z = 10.75 %          Z = 10.75 %            3400 kVA Dy5    3560 kVA Dy5
              |                     |                Z = 4.7 %      Z = 6 %
     == 400 V 10BFA10 ==   == 400 V 10BFA20 ==
        4000 A, 50 kA         4000 A, 50 kA
              |                     |
        LV loads = MISSING    LV loads = MISSING

      -- separate 6.6 kV water-intake switchgear, fed from 10BBA10 --
      === 6.6 kV 10BBW10 (1250 A) ===        === 6.6 kV 10BBW20 (1250 A) ===
        00PAC10AP001  2220 kW                  00PAC20AP001  2220 kW
        10PCC10AP001   280 kW                  10PCC20AP001   280 kW
              |                                        |
        00BFT10 (1000 kVA)                       10BFT40 (400 kVA)
              |                                        |
      == 400 V 00BFA10 (1600 A) ==            == 400 V 10BFE (800 A) ==
        LV loads = MISSING                       LV loads = MISSING

      -- normally OUT OF SERVICE (Rev 03 Note 4) --
      EDG 10BUK01 / 10BUK02, 1000 kVA, cos phi 0.8, 400 V
      "DISCONNECTOR SWITCH WILL REMAIN OPEN WHILE EDG IS SYNCHRONIZED WITH THE GRID"
```

---

## Voltage levels present in the South plant

| Level | Where | Note |
|---|---|---|
| 230 kV | GIS BUS 1 / BUS 2, GSUT HV, GAT HV | highest level in the South plant |
| 22 kV | generator terminal, IPB, GSUT LV, UAT HV | ±5 % per generator nameplate |
| 6.6 kV | MV busbar 10BBA10, water-intake 10BBW10/20 | ±10 % per Rev 03 Note 1 |
| 400 V | 10BFA10/20/30, 00BFA10, 10BFE | ±10 % per Rev 03 Note 1 |
| 2000 V | SFC transformer 10BMV10 secondary | drive supply, not a network bus |
| 660 V | excitation transformer secondary | not a network bus |
| 500 V | NER 10BAB11 secondary | grounding circuit |
| 3320 V | GAT stabilizing tertiary | not externally connected |
| 230 V / 110 V DC | control/lighting/DC | not network buses |

**There is no 400 kV level in the South plant.** The 400 kV GIS, the 400/230 kV Hyosung interbus transformers and the 400 kV data in the Google Form belong to the Ashuganj **North** unit (UTS project 7485) and are excluded — user confirmation 2026‑08‑17.

**6.9 kV is a transformer winding rating, not a bus.** The UAT and GAT LV windings are rated 6.9 kV; the plant MV bus is 6.6 kV nominal with U_m 7.2 kV. No 6.9 kV bus is created — the off-nominal 22000/6900 ratio into a 6600 V base is modelled explicitly instead. (The Excel workbook's own `13_VALIDATION_NOTES` independently reaches this conclusion.)

---

## Differences from the target sketch in the brief

| Item | Brief's sketch | As drawn |
|---|---|---|
| GSUT MVA | "515 MVA max" | ✔ correct, but three cooling stages 355/460/515 must be preserved; Z = 16 % is on 515 MVA |
| GSUT → GIS | direct | via **XLPE cable 230 kV** |
| **GAT 10BBT20** | **absent** | **present** — 230/6.9/3.32 kV from the 230 kV GIS to the 6.6 kV MV bus via SF₆ bus duct. Creates a second source and a loop |
| Water-intake switchgear | absent | 6.6 kV 10BBW10 / 10BBW20 with 4 motors totalling 5000 kW rated |
| 400 V buses | one "400 V AUX BUS" | five: 10BFA10, 10BFA20, 10BFA30, 00BFA10, 10BFE |
| NER 10BAB11 | absent | present (high-resistance generator grounding) |
| EDG | absent | present but normally open (Rev 03 Note 4) |

The sketch is otherwise a faithful skeleton: G1 → 22 kV → GSUT → 230 kV GIS (BUS 1 / BUS 2) → grid, with a 22 kV → UAT → 6.6 kV → 400 V auxiliary branch.

---

## Topology decisions that cannot be made from the documents

1. **GAT in service or standby?** Determines whether the 6.6 kV bus is singly or doubly fed and whether the network has a loop.
2. **Bus coupler closed or open?** Determines whether BUS 1 and BUS 2 are one electrical node or two.
3. **Which busbar does each bay select** (Q1 → BUS 2, Q2 → BUS 1) in normal service?
4. **Outgoing 230 kV circuit** — is it modelled as a line (needs R₁/X₁/length, all missing) or is the external grid attached directly at the GIS busbar?

These are asked as questions Q4, Q9, Q10 and Q7 respectively. Until they are answered, the topology above is the *documented physical* arrangement, not a *study* topology.
