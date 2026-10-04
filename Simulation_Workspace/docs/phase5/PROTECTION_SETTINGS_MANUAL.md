# Phase 5 & 6 Protection Settings Manual — Ashuganj South 450 MW CCPP

**Document Purpose:** This manual provides a complete, transparent, and easy-to-understand reference for the protection system of the Ashuganj South 450 MW Combined Cycle Power Plant (CCPP). It documents **where** each protection relay lives in the Simulink model, **how** their ratings were derived from fault current studies, **which elements were taken from the original SLD / OEM documents** versus **which ones were engineered and added by us**, and **how each setting protects the power plant across all fault scenarios**.

All figures referenced in this manual are saved in `snapshots/`. An interactive, high-definition version of this manual with zoomable figures is available at [`PROTECTION_SETTINGS_MANUAL.html`](file:///docs/phase5/PROTECTION_SETTINGS_MANUAL.html).

---

## 1. Plant Overview & Protection Philosophy

The Ashuganj South 450 MW CCPP operates in a **single-shaft (1S) configuration** where one Siemens SGT5-4000F Gas Turbine and one SST-3000 Steam Turbine sit on the same mechanical shaft driving a single synchronous generator (Siemens SGen5-2000H, rated 458 MVA nominal / 518 MVA maximum at 22 kV, power factor 0.85).

### Main Electrical Power Train
1. **22 kV Generator Bus:** Connects generator terminals to the Generator Circuit Breaker (GCB, 52G / Siemens 10BAC10, 100 kA interrupting rating).
2. **Generator Step-Up Transformer (GSUT, 10BAT10):** 515 MVA, 230/22 kV, vector group `YNd1`, 16% short-circuit impedance, stepping power up to the national 230 kV grid.
3. **230 kV GIS Switchyard:** Siemens 8DN9 Gas Insulated Switchgear rated for 50 kA symmetrical breaking and 125 kA peak making, feeding into double-circuit 230 kV overhead transmission lines.
4. **Auxiliary Systems:** Unit Auxiliary Transformer (UAT, 22/6.9 kV, Dyn11, 25 MVA) and Generator Auxiliary Transformer (GAT, 230/6.9 kV, YNyn0+d11, 25 MVA) supplying the 14 MW plant auxiliary load.
5. **Generator Grounding (NER 10BAB11):** High-resistance neutral grounding resistor (60 Ω primary + 2.62 Ω secondary via 25.4:1 transformer), restricting 22 kV single-line-to-ground fault currents to approximately **7.27 A**.

### Four Pillars of the Protection Philosophy
- **Unit Differential Protection (87G & 87T):** High-speed, selective percentage differential protection clearing internal faults in ~45 ms while restraining for through-faults.
- **High-Speed Busbar & Line Protection (87B & 87L):** 87B clears 230 kV GIS bus faults in ~90 ms total (35 ms detection + 50 ms breaker), preventing equipment destruction. 87L provides fast clearing for mid-line faults.
- **Graded Time-Overcurrent Backup (51):** Overcurrent curves follow the **IEC Standard Inverse (SI)** characteristic with a mandatory **300 ms Coordination Time Interval (CTI)**.
- **Sensitive Stator Earth Fault Protection (51N):** Solves the phase CT "blindness" problem by adding a dedicated 20/1 neutral CT to detect 7.27 A ground faults.

---

## 2. Rigorous Separation: Original SLD Data vs. Study-Added Settings

A central requirement of this manual is to clearly distinguish what equipment existed in the original drawings from what intelligence and settings were added by our fault study.

### GROUP A — From Original SLD & OEM Documents (Presence & Hardware Only)
The original project documents (GIS Single Line Diagram `INEL-112070-00-ELC-DE-0026`, Rev 03, and Siemens reports) gave the equipment topology, CT ratios, and relay model numbers. **Crucially, the original documents contained NO numerical settings** (pages 8–39 of the Siemens 7UM622 report were absent, and all pickup settings were blank/NaN).

| Ref | Original Item / Equipment | What the Original SLD / OEM Document Gave | Source Document | What Was MISSING (Filled by Us) |
|---|---|---|---|---|
| **A1** | **Transformer Differential Relay** | Siemens **7UT6331-5QB92-4BC0+L0S** relay panel in bay F12/F13 | GIS One-Line Dwg; Rev 03 SLD | Missing pickup current, restraint slopes, knee points, operating delay |
| **A2** | **Line Differential Protection** | **2 × Siemens 7SD5221** line differential relay units | SLD Rev 03; Bay 10ADA10 | Missing pickup threshold, communication channel delay allowance, slopes |
| **A3** | **Busbar Differential Protection** | Siemens **7SS523** decentralized busbar protection relay hardware | GIS One-Line Dwg | Missing differential pickup threshold, stabilization factor, operating time |
| **A4** | **Generator Protection Relay** | Siemens **7UM622** multi-function relay (Panel +10CHA) | Siemens Report BD1015 (pp. 6–7) | Setting pages 8–39 absent; missing 51 pickup, TMS, curve selection, 87G slopes |
| **A5** | **Generator CTs and VTs** | **15,000 / 1 A** phase CTs (3 cores: sys1, sys2, metering); VT ratio **22 kV/√3 : 100 V/√3** | Siemens Report §2.1.2 | Missing functional core assignment and sensitive neutral CT (see B2) |
| **A6** | **230 kV GIS Switchyard & Breakers** | Siemens **8DN9 GIS**, rated 50 kA breaking, 125 kA peak; Breakers labeled **Q0** | 230kV GIS Datasheet | Missing bay overcurrent backup settings, grading delays, mechanism timings |
| **A7** | **Neutral Earthing Resistor (NER)** | NER **10BAB11**: 60 Ω primary, 2.62 Ω secondary, transformer ratio 25.4:1 | Siemens Report §2.3 | Missing ground fault relay settings to detect the limited 7.27 A fault current |
| **A8** | **Owner Protection Requirements** | Overcurrent curve: **IEC Standard Inverse (SI)**; target CTI = **300 ms (0.3 s)** | APSCL Owner Form | Missing individual TMS multipliers to achieve the 300 ms grading |

### GROUP B — Added by Our Fault Study (Calculated Settings & Logic)
Using our Phase 4 symmetrical component fault analysis (modeling 3-phase LLL, single-line-to-ground LG, line-to-line LL, and double-line-to-ground LLG faults across the network), we calculated, graded, and implemented the following settings:

| Ref | Relay Element | Setting Chosen by Us | Derived From Which Fault Result | Engineering Rationale & Why It Was Needed |
|---|---|---|---|---|
| **B1** | **GEN-51** (Generator Overcurrent) | **17,170.8 A** primary<br>TMS = **0.10** (IEC-SI) | F1 3-phase fault = **126.21 kA** vs. Max load current = **14,309 A** | Set at $1.20 \times I_{\text{max}}$ to avoid nuisance tripping under maximum continuous load. TMS=0.10 grades 1.76 s above downstream GSUT-51. |
| **B2** | **GEN-51N** (Sensitive Stator Earth) | **4.0 A** primary<br>TMS = **0.15** (IEC-SI)<br>**+ Dedicated 20/1 CT** | F1 Ground Fault LG = **7.27 A** | Phase CTs (15,000/1 A) give 0.000485 A secondary (blind). Adding a 20/1 neutral CT yields 0.3635 A secondary, tripping in 1.75 s with 1.82× margin. |
| **B3** | **GSUT-HV-51** (Transformer HV Backup) | **1,380.0 A** primary<br>TMS = **0.55** (IEC-SI) | Nominal through-load = **1,149.7 A** at 230 kV; F1/F2 through-current | Set at $1.20 \times 1,149.7\text{ A} = 1,380\text{ A}$. TMS=0.55 mathematically solves the mandatory 300 ms CTI grading against Q0-51. |
| **B4** | **GIS-Q0-51** (Transformer Bay Backup) | **1,500.0 A** primary<br>TMS = **0.80** (IEC-SI) | F3/F4 switchyard faults (3 to 7 kA through Q0) | Set above transformer rated current (1,292.8 A) and below bay 2,000 A rating. Serves as final overcurrent backup for the 230 kV bay. |
| **B5** | **GEN-87G** (Generator Differential) | **2,403.8 A** ($0.20 \times I_{\text{nom}}$)<br>Delay = **0.045 s** | F1 generator branch fault = **55.05 kA** | High-speed instantaneous unit protection. Restrains under healthy load and external faults; trips in 45 ms for internal stator winding faults. |
| **B6** | **GSUT-87T** (Transformer Differential) | **387.84 A** ($0.30 \times I_{\text{nom,HV}}$)<br>Slopes = **30% / 60%**<br>Delay = **0.045 s** | F2 transformer LV fault = **5.27 kA** on HV base | Dual-slope percentage restraint. Compares HV and LV currents with vector group (YNd1) rotation and zero-sequence filtering. Clears internal faults in 45 ms. |
| **B7** | **GIS-87B** (Busbar Differential) | **320.0 A** ($0.20 \times 1,600\text{ A}$)<br>Slope = **30%**, Delay = **0.035 s** | F3 230 kV bus fault = **50.53 kA** | Detects bus spill current. Converts what would be a 7.28 s dangerous overcurrent delay into a clean **~90 ms total clearing** (35 ms relay + 50 ms breaker). |
| **B8** | **LINE-7SD (87L)** (Line Differential) | **320.0 A** ($0.20 \times I_n$)<br>Delay = **0.040 s** effective | F4 transmission line fault = **14.33 kA** | Compares line sending and receiving ends via optical link. Clears mid-line faults in 40 ms (35 ms detection + 5 ms communication delay). |
| **B9** | **Breaker Mechanism & DC Gating** | **50 ms** mechanism delay<br>Trip interlock at $V_{dc} \ge 88\text{ V}$ | Physical SF6 breaker opening characteristics | Models real circuit breaker opening time (contact separation + arc extinction) and verifies 110 V DC battery health before tripping. |

---

## 3. Rating Choices & Step-by-Step Mathematical Derivations

### GEN-51 Overcurrent Calculation
- **Maximum Continuous Load Current ($I_{\text{max}}$):**
  $$S_{\text{max}} = 518\text{ MVA}, \quad V_{\text{min}} = 22\text{ kV} \times 0.95 = 20.9\text{ kV}$$
  $$I_{\text{max}} = \frac{518 \times 10^6}{\sqrt{3} \times 20,900} = 14,309.28\text{ A} \approx 14,309\text{ A}$$
- **Pickup Setting:**
  $$I_{\text{pickup}} = 1.20 \times 14,309 = 17,170.8\text{ A}$$
  Secondary CT current on 15,000/1 A CT:
  $$I_{\text{sec}} = \frac{17,170.8}{15,000} = 1.14472\text{ A}$$
- **Grading & Curve:** IEC Standard Inverse ($t = \frac{0.14 \times \text{TMS}}{(I/I_p)^{0.02}-1}$), with $\text{TMS} = 0.10$. For a 126.21 kA fault at the 22 kV bus, GEN-51 operates in 0.594 s, maintaining a 1.76 s margin above downstream relays.

### GSUT-HV-51 Overcurrent Calculation
- **Nominal Full-Load Current ($I_{\text{load}}$):**
  $$S_{\text{nom}} = 458\text{ MVA}, \quad V_{\text{HV}} = 230\text{ kV}$$
  $$I_{\text{load}} = \frac{458 \times 10^6}{\sqrt{3} \times 230,000} = 1,149.68\text{ A}$$
- **Pickup Setting:**
  $$I_{\text{pickup}} = 1.20 \times 1,149.68 = 1,379.62\text{ A} \rightarrow 1,380\text{ A}$$
  Secondary CT current on 1,600/1 A CT:
  $$I_{\text{sec}} = \frac{1,380}{1,600} = 0.8625\text{ A}$$
- **Grading:** $\text{TMS} = 0.55$ mathematically satisfies the required 300 ms CTI grading against Q0-51.

### GEN-51N & NER Physics (The 7.27 A Ground Fault Story)
- **NER Impedance Calculation:**
  Single-phase grounding transformer ratio:
  $$n = \frac{22,000 / \sqrt{3}}{500} = 25.4034$$
  Secondary loading resistor $R_{\text{sec}} = 2.62\ \Omega$.
  Referred secondary resistance:
  $$R_{\text{ref}} = n^2 \times R_{\text{sec}} = (25.4034)^2 \times 2.62 = 1,690.8\ \Omega$$
  Total zero-sequence loop resistance:
  $$R_{\text{loop}} = 60\ \Omega\text{ (primary)} + 1,690.8\ \Omega = 1,750.8\ \Omega$$
  Prospective single-line-to-ground fault current:
  $$I_{\text{LG}} = \frac{22,000 / \sqrt{3}}{1,750.8} \approx 7.25\text{ A to } 7.27\text{ A}$$
- **Why Standard Phase CTs Are Blind:**
  On 15,000/1 A phase CTs, 7.27 A produces:
  $$I_{\text{sec}} = \frac{7.27}{15,000} = 0.000485\text{ A} = 0.485\text{ mA}$$
  This is far below the pickup floor of standard relays (typically 50 mA).
- **The Study Solution:**
  We introduced a dedicated **20/1 neutral CT** on the generator neutral earthing lead. With a 4.0 A pickup (0.20 A secondary setting dial), a 7.27 A fault generates:
  $$I_{\text{sec}} = \frac{7.27}{20} = 0.3635\text{ A} \quad (1.82 \times \text{pickup})$$
  Operating time is **1.746 s** at $\text{TMS} = 0.15$, clearing ground faults safely before progressive iron core burning occurs!

### Differential Elements (87G, 87T, 87B)
- **GEN-87G:** $0.20 \times I_{\text{nom}} = 0.20 \times 12,019.4\text{ A} = 2,403.8\text{ A}$ primary ($0.1603\text{ A}$ secondary). Slope = 30%, operating delay = 45 ms.
- **GSUT-87T:** $0.30 \times I_{\text{nameplate}} = 0.30 \times 1,292.8\text{ A} = 387.84\text{ A}$ primary on HV base ($0.2424\text{ A}$ secondary). Slope 1 = 30%, Slope 2 = 60%, knee = $2 \times 1,292.8\text{ A} = 2,585.6\text{ A}$. Delay = 45 ms.
- **GIS-87B & LINE-87L:** $0.20 \times 1,600\text{ A} = 320\text{ A}$ primary ($0.20\text{ A}$ secondary). Delay = 35 ms for 87B; 40 ms effective for 87L (35 ms detection + 5 ms comms).

---

## 4. Simulink Model Layout & Signal Flow

The complete system is implemented in `Phase6/model/PHASE6_ASHUGANJ_CCPP_DYNAMIC_MODEL.slx` (and its closed-loop testing twin `PHASE6_ASHUGANJ_CCPP_CLOSED_LOOP_TRIP.slx`).

### Central Relay Engine S-Function
All seven active protection relays reside within **ONE central Level-2 MATLAB S-function block**:
` <root> / Protection / Pickup and relay timing `
- **Implementation File:** `Phase6/scripts/phase6_relay_sfun.m` (parameters `R, S`).
- **Parameter Loading:** Automatically loaded from `Phase6/scripts/phase6_relay_parameters.m` reading `phase5_relay_settings.csv`.
- **Relay Evaluation Order:** `[1: GEN-51, 2: GSUT-51, 3: GEN-51N, 4: 87G, 5: 87T, 6: 87B, 7: 87L]`.

### End-to-End Trip Chain
1. **CT Sensing:** CTs in `Generator`, `Transformer`, and `Switchyard` feed instantaneous currents into `Measurements`, producing `P6_PHASORS`.
2. **Relay Engine Evaluation:** `phase6_relay_sfun` computes differential spills/restraints and overcurrent integration curves.
3. **Trip Request Dispatch:** Outputs the 6-channel vector:
   `P6_REQUESTS = [GCB, Q0, LineLocal, LineRemote, GAT, unitTrip]`.
4. **DC Supply Supervisory Check:** `&lt;root&gt;/DC Supply/Protection trip demand` and `Battery charger and DC bus` (`phase6_dc_sfun`) verify station battery voltage is healthy ($V_{dc} \ge 88\text{ V}$).
5. **Breaker Opening Mechanism Delay (50 ms):** `&lt;root&gt;/Breaker Control/DC trip path and mechanism` (`phase6_breaker_sfun`) enforces a realistic 50 ms contact separation delay ($C.\text{breakerDelay\_s} = 0.050\text{ s}$).
6. **Physical Breaker Interruption:** GCB (52G), Q0, or Line breakers open; current cessation is confirmed when $|I| < \max(1\text{ A}, 0.1\%\text{ pre-fault})$ for 20 ms.

---

## 5. Circled Snapshot Reference Guide

All figures below are located in `docs/phase5/snapshots/`.
- 🔵 **BLUE Circles & Badges:** Taken directly from the original SLD / drawings (physical breakers, CT locations, DC bus).
- 🔴 **RED Circles & Badges:** Added by our fault study (the shared relay engine, calculated settings, trip vector, DC trip gating).

| Figure File | Description | Color Callout & Significance |
|---|---|---|
| `snapshots/protection_zones_map.png` | **Fig. 0 — Protection Zones Map** | Visual zone boundary map of the 450 MW plant (Zones 1–4). |
| `snapshots/000_Plant_overview_circled.png` | **Fig. 1 — Top-Level Plant Model** | **Circle 1 (RED):** `Protection` subsystem we added.<br>**Circles 2–6 (BLUE):** GCB, Q0, Line breakers, DC bus from SLD. |
| `snapshots/336_Protection_circled.png` | **Fig. 2 — Inside &lt;root&gt;/Protection** | **Circles 1–2 (RED):** Active relay strip & S-function engine block.<br>**Circles 3–4 (BLUE):** CT phasors in, trip requests out. |
| `snapshots/339_Protection_Pickup_and_relay_timing_circled.png` | **Fig. 3 — Shared Relay Engine Block** | **Circle 1 (RED):** `phase6_relay_sfun` S-function implementing all 7 relays. |
| `snapshots/342_Protection_Trip_requests_circled.png` | **Fig. 4 — Trip Requests Output Bus** | **Circle 1 (BLUE):** Multiplexed trip request bus routing commands to breakers. |
| `snapshots/113_Generator_Breaker_circled.png` | **Fig. 5 — Generator Circuit Breaker (GCB)** | **Circle 1 (BLUE):** 22 kV GCB (10BAC10, 100 kA rating) from SLD. |
| `snapshots/375_Switchyard_GSUT_breaker_Q0_circled.png` | **Fig. 6 — Switchyard Breaker Q0** | **Circle 1 (BLUE):** 230 kV GIS breaker Q0 (52-1, 50 kA rating) from SLD. |
| `snapshots/426_Transmission_Line_Local_line_breaker_circled.png` | **Fig. 7 — Local Line Breaker** | **Circle 1 (BLUE):** 230 kV line bay breaker from SLD. |
| `snapshots/053_Breaker_Control_DC_trip_path_and_mechanism_circled.png` | **Fig. 8 — Breaker Mechanism & DC Gating** | **Circle 1 (RED):** 50 ms mechanical delay & DC interlock block we added. |
| `snapshots/095_Generator_Generator_terminal_CT_current_circled.png` | **Fig. 9a — Generator Terminal CT Sensing** | **Circle 1 (BLUE):** 15,000/1 A CT terminal measurement from SLD. |
| `snapshots/392_Transformer_HV_CT_current_circled.png` | **Fig. 9b — Transformer HV CT Sensing** | **Circle 1 (BLUE):** 1,600/1 A CT HV measurement from SLD. |
| `snapshots/073_DC_Supply_Battery_charger_and_DC_bus_circled.png` | **Fig. 10 — Station 110 V DC Battery Bus** | **Circle 1 (BLUE):** 110 V station DC battery and charger from SLD. |

---

## 6. How Each Protection Setting Helped Across All Fault Cases

### Phase 4 Prospective Bolted Fault Levels
- **F1 / F2 (22 kV Generator & GSUT LV Bus):** LLL = **126.21 kA** ($i_p = 348.3\text{ kA}$), LG = **7.27 A**, LL = **109.25 kA**, LLG = **109.25 kA**.
- **F3 (230 kV GIS Bus):** LLL = **50.53 kA** ($i_p = 129.8\text{ kA}$), LG = **45.74 kA**, LL = **43.76 kA**, LLG = **48.50 kA**.
- **F4 (230 kV Line Mid-Point, m = 0.5):** LLL = **51.06 kA**, LG = **46.12 kA**, LL = **44.22 kA**, LLG = **48.97 kA**.
- **F5 (Remote Grid Bus):** LLL = **53.09 kA**, LG = **48.47 kA**, LL = **45.97 kA**, LLG = **51.18 kA**.

### Fault Case Breakdown

#### Case F1: 22 kV Generator Bus Fault
- **3-Phase (126.21 kA):** Primary protection **GEN-87G** detects an internal differential current of 55,049 A vs. 2,403.8 A pickup. It operates instantaneously in **0.045 s (45 ms)**, initiating a complete Unit Trip (tripping GCB 52G, Q0, turbine governor, and field excitation). Backup relay GEN-51 operates in 0.594 s, and GSUT-51 operates in 2.354 s (grading margin = 1.76 s).
- **Ground Fault (7.27 A):** Phase relays (GEN-51 and 87G) cannot see 7.27 A. The dedicated **GEN-51N** relay on the added 20/1 neutral CT senses 7.27 A (secondary current 0.3635 A > 0.20 A pickup) and trips in **1.746 s**, saving the generator stator core from catastrophic melting.

#### Case F2: GSUT Low-Voltage Terminal Fault (22 kV)
- Primary protection **GSUT-87T** sees 5,265.5 A differential current on the HV base vs. 387.84 A pickup. It clears the fault in **0.045 s**. Backup GSUT-51 operates at 2.35 s.

#### Case F3: 230 kV GIS Switchyard Bus Fault
- Primary protection **GIS-87B** detects 47,370 A bus spill current vs. 320 A pickup. It trips in **0.035 s (35 ms)**, opening Q0, LineLocal, and GAT breakers in **~90 ms total**.
- **Crucial Benefit:** Without 87B, overcurrent backup relay Q0-51 would take **7.28 seconds**! A 50 kA arc for 7 seconds would destroy the switchyard. 87B avoids this catastrophe.
- **Delta-Block Verification:** For a 45.74 kA ground fault, GEN-51N sees 0 A because zero-sequence current cannot cross the GSUT delta winding.

#### Case F4: 230 kV Transmission Line Mid-Point Fault (m = 0.5)
- Line differential relay **LINE-7SD (87L)** detects 14,325 A line differential current vs. 320 A pickup. It clears in **0.040 s effective** (35 ms detection + 5 ms communication delay), tripping both local and remote line breakers. Overcurrent backup Q0-51 operates at 7.42 s.

#### Case F5: Remote Grid Substation Bus Fault
- F5 is outside plant unit protection zones. Primary clearing is handled by remote substation bus relays. Local breaker Q0 provides overcurrent backup, clearing in **4.54 s to 7.48 s** if remote breakers fail.

---

## 7. Measured Closed-Loop Simulation Event Timeline (`bus_3ph`)

The dynamic closed-loop simulation of scenario `bus_3ph` confirms the physical clearing sequence:

| Timestamp (s) | Elapsed | Physical Event | Evidence Source | Engineering Meaning |
|---|---|---|---|---|
| **0.1500 s** | 0.0 ms | **Fault Applied** | `events.csv` | 3-phase short circuit initiated on 230 kV GIS bus. |
| **0.1530 s** | +3.0 ms | **87B Pickup Detected** | `relay_times.csv` | Differential current exceeds 320 A; 35 ms timer starts. Backup relays GEN-51 (0.157s) and GSUT-51 (0.156s) pick up without tripping. |
| **0.1870 s** | +37.0 ms | **87B Trip Emitted** | `relay_times.csv` | 35 ms relay timer expires; trip signal dispatched via `P6_REQUESTS`. |
| **0.1880 s** | +38.0 ms | **Trip Coil Energized** | `events.csv` | DC supply verifies voltage healthy ($V_{dc} = 118\text{ V} \ge 88\text{ V}$) and energizes trip coils. |
| **0.2370 s** | +87.0 ms | **Breaker Mechanism Parts** | `breaker_times.csv` | Exactly **50 ms** after trip demand, Q0 and LineLocal contacts mechanically part. |
| **0.2412 – 0.2476 s** | +91 to +97 ms | **Current Cessation (Arc Out)** | `breaker_times.csv` | Current crosses zero; arc extinguished. Phase A ceases at 0.2412 s, Phase C at 0.2476 s. |
| **0.2630 – 0.2680 s** | +113 to +118 ms | **Relay Dropout & Reset** | `events.csv` | Fault current eliminated; relay drops out and resets to idle. |

---

## 8. Breaker Duty & Withstand Verification

All calculated fault currents were screened against certified breaker ratings:

| Breaker | Location / Voltage | Rated Breaking Capacity | Maximum Calculated Duty | Worst-Case Scenario | Duty Ratio | Verdict |
|---|---|---|---|---|---|---|
| **GCB (52G / 10BAC10)** | Generator Terminals (22 kV) | **100.0 kA** | 55.05 kA | F1 3-phase fault (Generator branch) | **0.550** | **PASS (< 1.0)** |
| **GSUT Bay Breaker (Q0)** | 230 kV GIS Switchyard | **50.0 kA** | 6.90 kA | F1/F2 3-phase fault (Grid backfeed) | **0.138** | **PASS (< 1.0)** |
| **GIS Line Bay Breakers** | 230 kV Line Bays | **50.0 kA** | 17.20 kA | F3 230 kV Bus fault | **0.344** | **PASS (< 1.0)** |

**Verdict:** **Zero exceedances** found across all 96 coordination and duty evaluations.

---

## 9. Academic Disclosures & Commissioning Checklist

- **Numerical Study Settings:** All settings are calculated study settings designed for selective coordination and equipment protection. Prior to physical commissioning, site setting sheets, vendor injection test files, and field CT excitation curves must be consulted.
- **CT Ratio Conflict:** The manufacturer schedule specifies 1,500/1 A, while the as-built SLD and transformer nameplate specify 1,600/1 A. Central study adopted 1,600/1 A; 1,500/1 A was verified as a sensitivity.
- **Pre-Commissioning Requirements:** Secondary injection tests on Siemens 7UM622 and 7UT6331; CT burden measurement; primary injection test of 20/1 neutral CT and NER; DC battery discharge test.

---

## 10. Reproduction Commands

To reproduce the study results, test suite, and models in MATLAB:

```matlab
cd('c:/Users/Sindid/OneDrive/Desktop/MouseWithoutBorders/306 Power Project -ekkebare f/Simulation_Workspace')

% 1. Run Phase 5b complete production study & test suite (528 tests):
addpath(genpath('matlab'));
run_phase5b_production('final-engineering', 'overwrite', true);
run_phase5b_tests();   % Expect: 528 passed, 0 failed

% 2. Run Phase 6 Relay Engine & S-Function verification:
addpath('Phase6/scripts'); addpath('Phase6/scripts/tests');
test_phase6_relays();
test_phase6_protection_sfunctions();

% 3. Open Interactive Closed-Loop Simulink Model:
START_PHASE6;
```
