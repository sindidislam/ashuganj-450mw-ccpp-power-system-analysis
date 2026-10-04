# Phase 4 Fault Analysis & Equipment Protection Defense Manual
## Ashuganj South 450 MW Combined Cycle Power Plant (CCPP)
**Course / Project:** EEE 306 Power System Protection & Switchgear Design  
**Author / Engineering Team:** Ashuganj South Protection Engineering Group  
**Status:** Approved & Production-Verified (`run_phase4_production()` PASS)  
**Companion Interactive Manual:** [`FAULT_ANALYSIS_MANUAL.html`](file:///C:/Users/Sindid/OneDrive/Desktop/MouseWithoutBorders/306%20Power%20Project%20-ekkebare%20f/Phase%204%20Docs/FAULT_ANALYSIS_MANUAL.html)

---

## Table of Contents
1. [Executive Summary & Purpose of Fault Analysis](#1-why-do-we-perform-fault-analysis)
2. [The 5 Strategic Fault Locations — Engineering Justification](#2-the-5-strategic-fault-locations)
3. [Visual Positions: Marked Master SLD & Simulink Dynamic Models](#3-visual-positions-marked-master-sld--simulink-models)
4. [Phase 4 Symmetrical Fault Current Calculations & Results](#4-phase-4-symmetrical-fault-calculations--results)
5. [Comprehensive Equipment Mitigation Mapping (What Equipments & Purpose)](#5-equipment-mitigation-mapping)
6. [Catastrophic Failure Physics (Consequences if Protection Fails)](#6-catastrophic-failure-physics)
7. [Comprehensive Viva Preparation Guide (16 High-Yield Questions & Model Answers)](#7-viva-preparation-guide)
8. [MATLAB Simulation Verification & File Reference](#8-matlab-simulation-verification--file-index)

---

## 1. Why Do We Perform Fault Analysis?

Short-circuit fault analysis is not merely an academic exercise — it is the **fundamental starting point of all power plant switchgear sizing, mechanical bus bracing, grounding design, and protective relay calibration** in accordance with **IEEE C37.010, IEEE C37.102, IEC 60909, and IEC 60255**.

When an insulation failure or lightning strike occurs, prospective currents surge to dozens of times the normal rated load current. Without rigorous fault calculations, the electrical engineer cannot answer four vital questions:

```
+---------------------------------------------------------------------------------------------------+
|                                  THE 4 PILLARS OF FAULT ANALYSIS                                  |
+---------------------------------+---------------------------------+-------------------------------+
| 1. Switchgear Withstand Ratings | 2. Protective Relay Calibration | 3. Selective Time Grading     |
| • Breaking Capacity (kA RMS)    | • Overcurrent Pickup (Ip)       | • Coordination Interval (CTI) |
| • Peak Making Capacity (ip)     | • Restraint Slopes (Slope 1/2)  | • TMS Calculation (IEC Curves)|
| • Bus Electromechanical Forces  | • Differential Spill Thresholds | • Downstream vs Upstream Clear|
+---------------------------------+---------------------------------+-------------------------------+
|                                 4. Earthing & Zero-Sequence Ground Control                        |
| • Neutral Grounding Resistor (NER) limitation (Limits 22 kV stator ground current to 7.27 A)     |
| • GSUT Delta Winding isolation (Traps zero-sequence, shielding generator from 230 kV faults)      |
+---------------------------------------------------------------------------------------------------+
```

### The 4 Engineering Purposes Explained in Plain Language:

1. **Equipment Rating & Breaking Capacity Verification:**
   Circuit breakers must be able to extinguish severe electric arcs safely. If a circuit breaker with a 40 kA breaking rating is installed on a bus with a prospective 50 kA fault, attempting to open the contacts will draw an uncontrollable plasma arc that will cause the breaker arc chamber to **rupture explosively**. Fault analysis establishes the minimum certified ratings:
   - **Generator Circuit Breaker (GCB):** Certified at **100 kA breaking capacity** (actual prospective fault: 55.05 kA; duty ratio: $0.550$).
   - **230 kV GIS Bay Breaker (Q0):** Certified at **50 kA breaking capacity** (actual prospective fault: 6.90 kA; duty ratio: $0.138$).

2. **Protective Relay Setting Derivation:**
   A numerical protective relay has no "brain" until the engineer programs its mathematical pickup parameters. Fault calculations provide:
   - Maximum through-fault currents (used to set restraint slopes on differential relays 87G, 87T, 87B, and 87L to prevent false tripping).
   - Minimum internal fault currents (used to ensure pickup sensitivity and operating margins $> 1.5\times$).

3. **Selective Coordination & Grading (CTI = 300 ms):**
   If a short circuit occurs on a 230 kV transmission line, only that specific line's breaker should trip. The generator and substation bus must stay connected to feed healthy circuits. Symmetrical fault analysis provides the exact currents used to calculate the Time Multiplier Settings (TMS) of inverse-time overcurrent relays to guarantee a mandatory **300 ms Coordination Time Interval (CTI)** between downstream and upstream devices.

4. **Zero-Sequence Grounding Control:**
   Over 70% of electrical power faults start as single-line-to-ground (LG) faults. Fault analysis verifies whether neutral grounding equipment (such as the generator's Neutral Earthing Resistor) successfully restricts damage to negligible levels.

---

## 2. The 5 Strategic Fault Locations

To rigorously evaluate the complete electrical corridor of the Ashuganj South 450 MW CCPP — from energy generation to bulk grid export — five strategic electrical nodes were selected:

```
[ GENERATOR ] === 22 kV ===> [ GCB ] === 22 kV ===> [ GSUT YNd1 ] === 230 kV ===> [ GIS BUS ] ===> [ 230 kV LINE ] ===> [ REMOTE GRID ]
      |                        |                           |                           |                    |                   |
    ( F1 )                     |                         ( F2 )                      ( F3 )               ( F4 )              ( F5 )
Generator Stator Bus          GCB                      Transformer                GIS Switchyard       Transmission       Remote Substation
22 kV Node                  10BAC10                   LV Terminals                   Busbar             Mid-Point                Bus
```

| Fault Tag | Physical Node in Plant | Voltage | Why Test This Position? (Engineering Purpose) |
| :---: | :--- | :---: | :--- |
| **F1** | **Generator Bus / Stator Terminals**<br>*(Between Generator & GCB)* | **22 kV** | **1. Maximum Machine Stress:** Evaluates the absolute worst-case short-circuit current the generator can supply ($126.21\text{ kA}$ 3-phase) to verify stator bar bracing against mechanical deformation.<br>**2. Stator Ground Fault Verification:** Tests the performance of the Neutral Earthing Resistor (NER) in restricting single-line-to-ground faults to $7.27\text{ A}$ to prevent stator lamination melting.<br>**3. GCB Inward Interruption:** Verifies GCB capability when interrupting current fed from the grid into the generator. |
| **F2** | **GSUT Low-Voltage Terminals**<br>*(Between GCB & Transformer LV Delta)* | **22 kV** | **1. Transformer Unit Differential (87T):** Verifies fast 87T trip ($45\text{ ms}$) on internal LV terminal faults.<br>**2. Delta Winding Isolation:** Proves that the $YNd1$ transformer delta connection traps zero-sequence current inside the delta loop, completely preventing 230 kV ground faults from injecting ground current into the generator.<br>**3. Phase Shift Compensation:** Validates numerical relay algorithm compensation for the $+30^\circ$ vector group phase displacement. |
| **F3** | **230 kV GIS Switchyard Busbar**<br>*(Bus 1 / Bus 2 Compartments)* | **230 kV** | **1. Busbar Differential (87B) Speed:** Evaluates high-speed $35\text{ ms}$ busbar differential protection. Without 87B, backup overcurrent takes $7.28\text{ seconds}$, causing switchgear explosion.<br>**2. Solid Grounding Contrast:** Demonstrates that unlike the 22 kV bus, the 230 kV switchyard is solidly grounded, producing an enormous $45.74\text{ kA}$ single-line-to-ground fault current.<br>**3. GIS Enclosure Duty:** Confirms fault currents comply with the Siemens 8DN9 $50\text{ kA}$ breaking rating. |
| **F4** | **230 kV Transmission Line Mid-Point**<br>*(50% along the 230 kV Line 1 corridor)* | **230 kV** | **1. Line Differential (87L) Operation:** Evaluates optical fiber line current differential protection clearing mid-line faults in $40\text{ ms}$.<br>**2. Distance Relay Zone Reach:** Validates that distance Zone 1 covers 80% of the line instantaneously, while Zone 2 covers the remaining 20% with time grading ($0.30\text{ s}$).<br>**3. Dynamic Rotor Stability:** Confirms that clearing mid-line faults within $100\text{ ms}$ prevents generator loss-of-synchronism (pole-slipping). |
| **F5** | **Remote Grid Substation Bus**<br>*(External 230 kV Utility Substation)* | **230 kV** | **1. Protection Zone Boundary Selectivity:** Proves that external grid faults DO NOT cause false tripping of our plant relays (87G, 87T, 87B, and 87L properly restrain).<br>**2. Coordinated Plant Backup:** Verifies that plant breaker Q0 provides coordinated inverse-time backup tripping ($4.54\text{ s}$ to $7.48\text{ s}$) if remote substation breakers fail. |

---

## 3. Visual Positions: Marked Master SLD & Simulink Models

All 5 fault locations have been marked, circled, and verified across both the OEM Master Single Line Diagram (SLD) and the MATLAB/Simulink top-level dynamic model.

### 3.1 Master Single Line Diagram (SLD) with Fault Locations Marked
![Master Single Line Diagram with Fault Locations Marked](snapshots/sld_fault_locations_marked.png)
*Fig. 1 — Master OEM Electrical Single Line Diagram showing bold circled callouts for the 5 fault study nodes: F1 (22 kV Generator Bus), F2 (GSUT 22 kV LV Bushings), F3 (230 kV GIS Switchyard Busbars), F4 (230 kV Transmission Line Mid-Point), and F5 (Remote 230 kV Grid Substation Bus).*

### 3.2 Top-Level Simulink Dynamic Model Architecture
![Simulink Dynamic Model with Fault Locations Marked](snapshots/simulink_fault_locations_marked.png)
*Fig. 2 — Top-Level architecture of `PHASE6_ASHUGANJ_CCPP_DYNAMIC_MODEL.slx` displaying the corresponding fault blocks inside the Generator, GSUT Transformer, Switchyard, and Transmission Line subsystems.*


### 3.2b Master SLD High-Definition Close-Up Crops (1:1 Native Resolution)
To guarantee complete legibility on presentation displays and projectors from a distance, 1:1 scale high-definition crops of the OEM Master Single Line Diagram are provided below for each of the five fault zones:

| Fault Zone | High-Resolution SLD Crop | Physical Equipment & Study Parameters |
| :--- | :--- | :--- |
| **F1 — Generator Stator Bus** | ![F1 Generator Bus Detail](snapshots/sld_crop_f1_generator.png) | **Tags:** Generator `10MKA10`, GCB `10BAC10`, NER `10BAB11`<br>**Fault:** $I_k'' = 126.21\text{ kA}$, $i_p = 348.26\text{ kA}$, $I_k''\text{ LG} = 7.27\text{ A}$<br>**Primary Protection:** Relay 87G (Generator Diff), 51N (NER Earth Fault) |
| **F2 — GSUT LV Delta** | ![F2 GSUT LV Detail](snapshots/sld_crop_f2_gsut_lv.png) | **Tags:** GSUT `10BAT10` (515 MVA), UAT `10BBT10` (25 MVA), IPB<br>**Fault:** $I_k'' = 126.21\text{ kA}$, $i_p = 348.26\text{ kA}$, Vector Shift: $+30^\circ$ (YNd1)<br>**Primary Protection:** Relay 87T (Transformer Diff) |
| **F3 — 230 kV GIS Bus** | ![F3 GIS Bus Detail](snapshots/sld_crop_f3_gis_switchyard.png) | **Tags:** GIS Bus 1 `10BAC01`, Bus 2 `10BAC02`, GSUT Bay `10BAY11`<br>**Fault:** $I_k'' = 50.53\text{ kA}$, $i_p = 136.98\text{ kA}$, $I_k''\text{ LG} = 45.74\text{ kA}$<br>**Primary Protection:** Relay 87B (Busbar Diff, 35 ms high speed) |
| **F4 — 230 kV Line Mid** | ![F4 Line Midpoint Detail](snapshots/sld_crop_f4_line_midpoint.png) | **Tags:** Line 1 & Line 2 (0.7 km Mallard 795 MCM), Disconnectors<br>**Fault:** $I_k'' = 51.06\text{ kA}$, $i_p = 138.60\text{ kA}$, $I_k''\text{ LG} = 46.12\text{ kA}$<br>**Primary Protection:** Relay 87L (Line Diff, 40 ms) / Relay 21 (Distance Zone 1) |
| **F5 — Remote Grid Bus** | ![F5 Remote Bus Detail](snapshots/sld_crop_f5_remote_grid.png) | **Tags:** Remote Bus `B230_REMOTE` / `BGRID230`, PGCB National Grid Interface<br>**Fault:** $I_k'' = 53.09\text{ kA}$, $i_p = 144.11\text{ kA}$, $I_k''\text{ LG} = 48.47\text{ kA}$<br>**Relay Action:** Plant relays (87G, 87T, 87B, 87L) **RESTRAIN**; cleared by grid breakers |

### 3.3 Individual Simulink Fault Injection Subsystems
The project model injects faults via physical Three-Phase Fault blocks located inside dedicated subsystems:

| Fault Location | Simulink Subsystem Block | Snapshot Reference |
| :--- | :--- | :--- |
| **F1 — Generator Bus** | `<root>/Generator/F1_Stator_Fault` | ![F1 Generator Fault Block](snapshots/F1_generator_fault_block.png) |
| **F2 — GSUT LV Delta** | `<root>/Transformer/F2_LV_Fault` | ![F2 Transformer LV Block](snapshots/F2_transformer_LV_fault_block.png) |
| **F3 — 230 kV GIS Bus** | `<root>/Switchyard/F3_GIS_Bus_Fault` | ![F3 GIS Bus Fault Block](snapshots/F3_GIS_bus_fault_block.png) |
| **F4 — 230 kV Line Mid** | `<root>/Transmission Line/F4_Line_Fault` | ![F4 Line Midpoint Block](snapshots/F4_line_midpoint_fault_block.png) |
| **F5 — Remote Grid Bus** | `<root>/Grid Boundary/F5_Remote_Fault` | ![F5 Remote Bus Fault Block](snapshots/F5_remote_bus_fault_block.png) |

![Protection Zones Map](snapshots/protection_zones_map.png)
*Fig. 3 — Protection Zones Map indicating the overlapping boundaries for Zone 1 (Generator), Zone 2 (GSUT Transformer), Zone 3 (230 kV GIS Busbar), and Zone 4 (Transmission Lines).*

---

## 4. Phase 4 Symmetrical Fault Calculations & Results

Using IEC 60909 symmetrical component matrix equations ($I_1 = \frac{V_{\text{pre}}}{Z_1}$, $I_2 = 0$, $I_0 = 0$ for 3-phase faults; $I_0 = I_1 = I_2 = \frac{V_{\text{pre}}}{Z_1 + Z_2 + Z_0 + 3Z_f}$ for single-line-to-ground faults), the fault currents calculated across all five locations are summarized below:

| Fault Node | Voltage Level | 3-Phase (LLL) Symmetrical $I_k''$ | Peak Make Current ($i_p$) | Single-Line-to-Ground (LG) $I_k''$ | Line-to-Line (LL) $I_k''$ | Double-Line-to-Ground (LLG) $I_k''$ | Short-Circuit Fault MVA |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **F1 Generator Terminals** | **22 kV** | **126.21 kA** | **348.26 kA** | **0.00727 kA (7.27 A)** | 109.25 kA | 109.25 kA | **4,809 MVA** |
| **F2 GSUT LV Terminals** | **22 kV** | **126.21 kA** | **348.26 kA** | **0.00727 kA (7.27 A)** | 109.25 kA | 109.25 kA | **4,809 MVA** |
| **F3 230 kV GIS Bus** | **230 kV** | **50.53 kA** | **129.80 kA** | **45.74 kA** | 43.76 kA | 48.50 kA | **20,130 MVA** |
| **F4 230 kV Line Mid-Point** | **230 kV** | **51.06 kA** | **131.30 kA** | **46.12 kA** | 44.22 kA | 48.97 kA | **20,340 MVA** |
| **F5 230 kV Remote Grid** | **230 kV** | **53.09 kA** | **137.40 kA** | **48.47 kA** | 45.97 kA | 51.18 kA | **21,148 MVA** |

### The Critical Engineering Takeaways from Table 4:
1. **The Ground Fault Asymmetry:**
   - At **F1 (22 kV Bus)**, single-line-to-ground fault current is only **7.27 A** because the generator neutral is grounded through a high-resistance Neutral Grounding Resistor ($NER = 1,750.8\ \Omega$).
   - At **F3 (230 kV Bus)**, single-line-to-ground fault current explodes to **45.74 kA** because the 230 kV transmission grid and GSUT HV wye neutral are solidly grounded.
2. **Breaker Duty Ratios Show Zero Exceedances:**
   - **GCB Duty:** $55.05\text{ kA} / 100\text{ kA} = \mathbf{0.550}$ (Safety Margin: $45\%$).
   - **GIS Q0 Duty:** $6.90\text{ kA} / 50\text{ kA} = \mathbf{0.138}$ (Safety Margin: $86.2\%$).
   - Every circuit breaker in the plant operates well within certified interrupting capabilities.

---

## 5. Equipment Mitigation Mapping
### What Equipments We Use & For What Specific Purpose

To protect against, detect, limit, and isolate faults at each of the 5 positions, an entire multi-layered defense architecture is employed. Below is the comprehensive breakdown of equipment mapped to each location:

### 5.1 Defense Equipment for F1 — Generator Bus Faults (22 kV)
| Equipment Category | Specific Equipment Model / Tag | Primary Engineering Purpose |
| :--- | :--- | :--- |
| **Primary Sensing** | **15,000 / 1 A Phase CTs**<br>(Class 5P20, 30 VA, 3 cores) | Steps down high phase currents (up to 126 kA) to safe secondary levels for measurement by the 87G differential and 51 overcurrent relays without saturating during peak fault transients. |
| **Dedicated Ground Sensing** | **20 / 1 A Neutral CT**<br>(Added by Our Study) | **Solves phase CT blindness.** Steps down the tiny 7.27 A ground fault current into 0.3635 A secondary current so the sensitive ground relay (51N) can easily detect it. |
| **Primary Protection Relay** | **GEN-87G (Siemens 7UM622)**<br>Generator Percentage Differential | Detects internal stator phase faults within **0.045 s (45 ms)** by comparing inner vs. terminal CT currents. Emits an instantaneous Master Unit Trip. |
| **Backup Protection Relay** | **GEN-51 (Siemens 7UM622)**<br>Time-Overcurrent ($I_p = 17,170.8\text{ A}$) | Provides coordinated time-delayed backup protection, tripping in **0.594 s** if differential protection fails. |
| **Sensitive Ground Relay** | **GEN-51N (Siemens 7UM622)**<br>Stator Earth Fault ($I_p = 4.0\text{ A}$) | Operates on the 20/1 neutral CT current. Senses the 7.27 A ground fault and trips in **1.746 s** to prevent stator lamination melting. |
| **Current-Limiting Hardware** | **Neutral Grounding Resistor**<br>(NER 10BAB11, 60 Ω + 2.62 Ω) | **Limits prospective ground fault current from 100+ kA down to 7.27 A**, preventing catastrophic core melting during single-phase stator insulation breakdown. |
| **Power Interruption Breaker** | **Generator Circuit Breaker (GCB)**<br>(Siemens 10BAC10, 100 kA breaking) | Physically interrupts up to 100 kA, separating the generator from the 22 kV bus within 50 ms to stop inward current contribution. |
| **Machine De-energization** | **AVR Field Breaker & Turbine ESV** | A spinning generator continues to generate voltage even with the GCB open! The trip command trips the excitation field breaker (rapid demagnetization) and closes turbine Emergency Stop Valves (ESV) to shut off fuel and prevent overspeed. |

---

### 5.2 Defense Equipment for F2 — GSUT LV Connection Faults (22 kV)
| Equipment Category | Specific Equipment Model / Tag | Primary Engineering Purpose |
| :--- | :--- | :--- |
| **Primary Sensing** | **15,000/1 A LV CTs & 1,600/1 A HV CTs** | Measures currents entering the low-voltage delta side and exiting the high-voltage wye side of the GSUT. |
| **Primary Protection Relay** | **GSUT-87T (Siemens 7UT6331)**<br>Transformer Differential Relay | Detects winding/bushing faults inside the transformer zone in **0.045 s**. Features dual restraint slopes (30% / 60%) to prevent false tripping during magnetizing inrush. |
| **Backup Protection Relay** | **GSUT-HV-51 (Siemens 7UT6331)**<br>Time-Overcurrent ($I_p = 1,380\text{ A}$) | Provides backup overcurrent protection on the 230 kV side, tripping in **2.35 s** if 87T is disabled. |
| **Dual Isolation Breakers** | **GCB (22 kV) + Q0 Breaker (230 kV)** | Simultaneous tripping of both LV and HV breakers ensures the transformer is completely isolated from both generation and grid backfeeds. |
| **Mechanical Detectors** | **Buchholz Relay & Pressure Relief Device (PRD)** | Detects insulating oil decomposition gas accumulation and hydraulic shockwaves inside the transformer tank, triggering immediate electrical lockout. |

---

### 5.3 Defense Equipment for F3 — 230 kV GIS Switchyard Bus Faults
| Equipment Category | Specific Equipment Model / Tag | Primary Engineering Purpose |
| :--- | :--- | :--- |
| **Primary Sensing** | **1,600 / 1 A GIS Bay CTs** | Monitors all incoming and outgoing branch currents connected to Bus 1 and Bus 2 (GSUT bay, Line 1, Line 2, GAT bay). |
| **Primary Protection Relay** | **GIS-87B (Siemens 7SS523)**<br>Busbar Differential Protection | **The primary defense of the switchyard.** Computes Kirchhoff's Current Law ($\sum I = 0$). Trips within **0.035 s (35 ms)** for a 50.53 kA bus fault, clearing the entire bus in **~90 ms total**. |
| **Backup Protection Relay** | **GIS-Q0-51 (Overcurrent Backup)** | Backup overcurrent protection tripping in **7.28 s** if bus differential fails. |
| **Power Interruption Breakers** | **Q0, LineLocal, and GAT Bay Breakers**<br>(Siemens 8DN9 GIS, 50 kA rating) | Simultaneously opens all circuit breakers connected to the faulted bus section, isolating the busbar from all sources. |
| **Tripping & DC System** | **110 V DC Dual Battery Bank & 86 Lockout** | Provides independent, unshakeable DC trip energy to all breaker coils and locks out automatic reclosure until manual clearance. |

---

### 5.4 Defense Equipment for F4 — 230 kV Transmission Line Mid-Point Faults
| Equipment Category | Specific Equipment Model / Tag | Primary Engineering Purpose |
| :--- | :--- | :--- |
| **Primary Protection Relay** | **LINE-7SD (Siemens 7SD5221)**<br>Line Current Differential (87L) | Compares phase current vectors at the local plant and remote substation over a dedicated optical fiber communication channel. Operates in **0.040 s**. |
| **Backup Protection Relay** | **Distance Protection (ANSI 21)**<br>Zone 1 (Instantaneous) & Zone 2 (Graded) | Measures positive-sequence impedance ($Z = V/I$). Zone 1 clears faults within 80% of the line instantaneously ($0\text{ s}$ delay); Zone 2 covers the remaining 20% with a $0.30\text{ s}$ delay. |
| **Surge Protection** | **230 kV ZnO Surge Arresters** | Discharges atmospheric lightning strikes and switching surges directly to ground, protecting line insulation and terminal GIS bushings from flashover. |
| **Line Circuit Breakers** | **Local & Remote 230 kV Line Breakers** | Trips breakers at both line terminals to de-energize the faulted span and allow the power plant to continue exporting via Circuit 2. |

---

### 5.5 Defense Equipment for F5 — 230 kV Remote Grid Substation Bus Faults
| Equipment Category | Specific Equipment Model / Tag | Primary Engineering Purpose |
| :--- | :--- | :--- |
| **Primary Clearing** | **Remote Substation Bus Differential**<br>*(External Utility Scope)* | Primary high-speed fault clearance is handled by the remote grid substation's own bus differential relays. |
| **Unit Protection Restraint** | **Plant Differential Relays (87G, 87T, 87B, 87L)** | **Selective Restraint:** Plant unit differential relays see high through-current but zero spill current. They properly **restrain (do not trip)**, keeping Ashuganj generating. |
| **Local Backup Protection** | **Q0-51 Overcurrent & Distance Zone 3** | If remote substation breakers fail to clear the fault, local breaker Q0 provides backup tripping in **4.54 s to 7.48 s**, isolating Ashuganj from feeding the external fault indefinitely. |

---

## 6. Catastrophic Failure Physics
### What Physically Happens if Protection Fails?

To truly understand why protective switchgear and relays are required, consider the physical, thermodynamic, and mechanical reality of what happens if a fault occurs and the protection fails to clear it:

```
+---------------------------------------------------------------------------------------------------+
|                            CHAIN REACTION OF UNCLEARED POWER SYSTEM FAULTS                        |
|                                                                                                   |
|  [ Insulation Breakdown ]                                                                         |
|            |                                                                                      |
|            v                                                                                      |
|  [ Arc Initiation (>5,000°C) ] ===> Vaporizes Copper & Steel into Conductive Plasma               |
|            |                                                                                      |
|            +---> In Transformer Oil: Explosive Gas Generation (1,000 psi/s) ===> Tank Rupture     |
|            |                                                                                      |
|            +---> In GIS SF6 Chamber: Toxic Gas Decomposition (HF, SO2)      ===> Enclosure Blowout|
|            |                                                                                      |
|            +---> In Generator Stator: Welds Thin Laminations Solid          ===> Core Destruction |
|            |                                                                                      |
|            v                                                                                      |
|  [ Mechanical Stress (F proportional to ip^2) ] ===> Tears Heavy Busbars and Conductors Apart     |
|            |                                                                                      |
|            v                                                                                      |
|  [ Unbalance & Voltage Collapse ] ===> Generator Pole-Slipping & Nationwide Cascading Blackout    |
+---------------------------------------------------------------------------------------------------+
```

### Detailed Failure Mechanisms by Location:

#### 1. F1 Failure: Stator Core Welding & Generator Explosion
- **Electromechanical Destruction ($126.21\text{ kA}$, $i_p = 348.26\text{ kA}$):** The magnetic force between adjacent phase conductors is proportional to the square of peak current ($F \propto i_p^2$). At 348 kA, forces exceed hundreds of tons per meter. Copper stator bars bend, tear out of their laminated steel slots, and shatter the end-winding bracing rings.
- **The Stator Ground Fault Catastrophe:** If the 51N relay fails to isolate a 7.27 A ground fault, the concentrated arc burns through the thin mica varnish insulating the thousands of silicon steel laminations. The intense heat welds the thin laminations into a solid lump of molten iron. Once fused, massive eddy currents circulate inside the core, generating unquenchable internal heat that permanently destroys the core.
  - **Financial Loss:** \$15–20 million.
  - **Outage Duration:** 12 to 18 months for a complete stator rewind.

#### 2. F2 Failure: Transformer Tank Rupture & Boiling Oil Fireball
- When an electric arc of 126 kA strikes under mineral insulating oil, temperature inside the arc channel exceeds **5,000°C** (hotter than the surface of the sun).
- Liquid oil instantly cracks into volatile hydrocarbon gases (hydrogen, acetylene, ethylene). Because transformer oil is incompressible, dynamic internal tank pressure escalates at **over 1,000 psi per second**.
- If 87T does not trip within 45 ms, internal pressure exceeds the yield strength of the 12 mm welded steel tank. The tank ruptures violently, spraying thousands of gallons of boiling, vaporized oil into the atmosphere, creating a catastrophic fireball that incinerates adjacent transformers and control rooms.

#### 3. F3 Failure: GIS Enclosure Rupture & Poisonous Gas Cloud Release
- At 50.53 kA, an internal arc in the 230 kV Gas-Insulated Switchgear creates an intense plasma discharge. Without 87B, overcurrent backup takes **7.28 seconds**.
- Sustaining 50 kA for 7.28 seconds releases over 1,000 MJ of thermal energy, vaporizing aluminum bus conductors and decomposing sulfur hexafluoride ($SF_6$) into **lethal, corrosive byproducts**:
  - **Sulfur Dioxide ($SO_2$):** Choking, highly acidic toxic gas.
  - **Hydrofluoric Acid ($HF$):** Extremely corrosive acid that dissolves glass, steel, and human tissue.
  - **Disulfur Decafluoride ($S_2F_{10}$):** Deadly toxic nerve and lung toxin (toxic at parts per billion).
- Overpressure bursts rupture discs and tears aluminum enclosure seams, venting poisonous gas across the substation. 87B prevents this by clearing the fault in **35 ms** (total ~90 ms with breaker).

#### 4. F4 Failure: Transmission Line Annealing & Roadway Collapse
- Continuous passage of 51.06 kA through Aluminum Conductor Steel Reinforced (ACSR) cables raises conductor temperature above 300°C in seconds.
- Above 150°C, hard-drawn aluminum undergoes **metallurgical annealing**, losing its mechanical tensile strength. The conductors stretch permanently, sagging into roadways or trees, and snapping under tension, dropping live 230,000 V cables onto the ground.

#### 5. F5 Failure: Rotor Pole-Slipping & Cascading Grid Blackout
- A sustained three-phase fault on the 230 kV grid collapses national grid voltage to near zero.
- With zero terminal voltage, the generator cannot export electrical power ($P_e = \frac{E V}{X} \sin \delta \approx 0$). However, the gas turbine continues to inject 300+ MW of mechanical torque.
- The net accelerating torque causes the rotor to accelerate uncontrollably. Within 300 ms, the rotor angle exceeds the critical clearing angle ($\delta > \delta_{\text{crit}}$) and begins **pole-slipping** (falling out of synchronism). Each pole slip induces massive torsional shockwaves through the generator shaft, threatening shaft shear failure and causing tripping of all neighboring power plants, plunging the nation into a total blackout.

---

## 7. Viva Preparation Guide
### 16 High-Yield Questions & Complete Model Answers

Below are the 16 most important viva voce and technical defense questions asked by university examiners, project review committees, and power utility interviewers:

---

#### Q1. Why is the single-line-to-ground fault current at F1 (22 kV bus) only 7.27 A, while at F3 (230 kV bus) it is 45.74 kA?
**Model Answer:**  
It is completely determined by the **earthing (grounding) method**:
1. **At 22 kV (F1):** The generator neutral is connected to earth through a high-resistance **Neutral Earthing Resistor (NER 10BAB11)** with an effective loop resistance of $1,750.8\ \Omega$. By Ohm's law, $I_{\text{LG}} \approx \frac{V_{\text{ph}}}{R_N} = \frac{22,000 / \sqrt{3}}{1,750.8} \approx 7.27\text{ A}$. This intentional limitation restricts fault energy and completely prevents stator lamination melting.
2. **At 230 kV (F3):** The national transmission grid and the GSUT HV wye neutral are **solidly grounded** (zero intentional neutral resistance). The fault impedance consists only of tiny subtransient impedances of the generator, transformer, and grid lines, resulting in a massive $45.74\text{ kA}$ ground fault.

---

#### Q2. Why can standard 15,000/1 A phase CTs not detect the 7.27 A stator ground fault, and how did our study solve this?
**Model Answer:**  
With a 15,000/1 A phase CT ratio, a primary fault current of 7.27 A reflects onto the secondary side as:
$$I_{\text{sec}} = \frac{7.27\text{ A}}{15,000} = 0.000485\text{ A} = 0.485\text{ mA}$$
The minimum operating current and internal noise floor of modern numerical relays is typically $50\text{ mA}$ to $100\text{ mA}$. Thus, $0.485\text{ mA}$ is completely invisible to the phase CTs (the relay is blind).  
**Our Solution:** We introduced a dedicated **20/1 sensitive neutral CT** connected directly on the generator neutral earthing lead. With this CT, the 7.27 A primary current produces a robust secondary current of:
$$I_{\text{sec}} = \frac{7.27\text{ A}}{20} = 0.3635\text{ A} = 363.5\text{ mA}$$
This allows our sensitive 51N relay dial ($I_p = 4.0\text{ A}$ primary, $0.20\text{ A}$ secondary) to trip cleanly and reliably with an operating margin of **1.82×**.

---

#### Q3. Why does the GSUT YNd1 transformer block zero-sequence current from passing between the 230 kV and 22 kV sides?
**Model Answer:**  
The GSUT has a delta ($\text{d1}$) connection on its 22 kV low-voltage winding. In any delta winding:
1. Zero-sequence currents in the three phases are identical in magnitude and angle ($I_{a0} = I_{b0} = I_{c0}$).
2. At the line terminals, the line current is the difference between phase currents: $I_L = I_{ab0} - I_{ca0} = 0$.
3. Therefore, zero-sequence current can only circulate inside the closed delta winding loop and cannot flow into or out of the external 22 kV line conductors.  
Consequently, ground faults on the 230 kV grid produce exactly zero ground current in the 22 kV generator neutral earthing path, keeping the generator completely isolated from external grid ground disturbances.

---

#### Q4. What is the difference between Symmetrical RMS Current ($I_k''$) and Peak Make Current ($i_p$)?
**Model Answer:**  
- **Symmetrical Initial Short-Circuit Current ($I_k''$):** The pure AC RMS value of the fault current at the first instant ($t = 0$), determined purely by system AC subtransient reactances ($X_d''$). It is used to determine equipment thermal withstand ($I^2 t$) and breaker breaking capacity.
- **Peak Make Current ($i_p$):** The absolute instantaneous peak value of the current waveform occurring approximately $10\text{ ms}$ (half a cycle) after fault initiation. It includes the worst-case DC offset component caused by magnetic flux trapping:
  $$i_p = \kappa \sqrt{2} I_k''$$
  (where $\kappa$ is the peak factor, typically $1.8$ to $1.95$ for high $X/R$ systems). At F1, $i_p = 348.26\text{ kA}$! This value dictates the peak electromechanical forces ($F \propto i_p^2$) that attempt to rip busbars and breaker contacts apart.

---

#### Q5. What is Coordination Time Interval (CTI), why is 300 ms standard, and how was TMS calculated?
**Model Answer:**  
- **CTI (Coordination Time Interval):** The intentional safety time margin maintained between the operating time of a downstream breaker and an upstream backup relay to guarantee selectivity.
- **Why 300 ms?** In numerical relay systems, 300 ms provides safe grading:
  - Downstream circuit breaker interrupting time: $50\text{ ms}$
  - Upstream relay overtravel / overshoot time: $30\text{ ms}$
  - CT saturation & numerical calculation errors: $50\text{ ms}$
  - Safety margin for drift: $170\text{ ms}$
  - Total standard CTI: $\mathbf{300\text{ ms}}$.
- **TMS Calculation:** Using the IEC Standard Inverse curve:
  $$t = \frac{0.14 \times \text{TMS}}{(I / I_p)^{0.02} - 1}$$
  The target operating time $t_{\text{upstream}} = t_{\text{downstream}} + \text{CTI}$ is substituted to solve for $\text{TMS}$. For GSUT-HV-51, grading against the 22 kV bus backup yielded $\text{TMS} = 0.55$.

---

#### Q6. What is the fundamental difference between Unit Protection and Non-Unit Protection?
**Model Answer:**  
- **Unit Protection (e.g., Differential 87G, 87T, 87B, 87L):**
  - Protects an absolute, strictly bounded physical zone enclosed between sets of CTs.
  - It is 100% selective: trips instantaneously ($35–45\text{ ms}$) for faults inside the zone and restrains for any fault outside the zone.
  - Requires no intentional time grading with other relays.
- **Non-Unit Protection (e.g., Overcurrent 51, Ground 51N, Distance Zone 2):**
  - Has no fixed physical boundary.
  - Responds to fault current magnitude or impedance everywhere it can see.
  - Requires intentional time grading delays (CTI) to let downstream breakers clear faults first.

---

#### Q7. What is the role of the Master Trip Lockout Relay (ANSI 86)?
**Model Answer:**  
When an instantaneous unit protection relay trips (such as 87G or 87T), it does not energize the breaker trip coils directly. Instead, it energizes the **ANSI 86 Master Trip Lockout Relay**.  
The 86 relay mechanically latches in the trip state and simultaneously:
1. Trips the Generator Circuit Breaker (GCB).
2. Trips the 230 kV Bay Breaker (Q0).
3. Closes the turbine Emergency Stop Valves (ESV) to cut fuel.
4. Trips the generator excitation field breaker to demagnetize the rotor.
5. **Mechanically locks out all breaker close circuits**, preventing any human or automated control system from reclosing onto a faulted unit until maintenance engineers inspect the equipment and manually reset the 86 relay.

---

#### Q8. What would happen if busbar differential relay 87B did not exist during an F3 bus fault?
**Model Answer:**  
Without 87B, the $50.53\text{ kA}$ bus fault would have to be cleared by backup overcurrent relay Q0-51, which has a time delay of **7.28 seconds** to achieve selectivity with downstream lines.  
Sustaining a 50 kA arc inside an enclosed GIS compartment for over 7 seconds releases over 1,000 MJ of energy. This would vaporize aluminum bus conductors into plasma, decompose non-toxic $SF_6$ gas into deadly toxic gases ($HF, SO_2, S_2F_{10}$), rupture the burst discs, and blow the GIS enclosure apart. 87B prevents this by clearing the fault in **35 ms** (~90 ms total with breaker).

---

#### Q9. What is Breaker Duty Ratio and what was our study's screening verdict?
**Model Answer:**  
Breaker Duty Ratio is defined as:
$$\text{Duty Ratio} = \frac{\text{Maximum Prospective Short-Circuit Current}}{\text{Breaker Certified Rated Breaking Capacity}}$$
- For GCB (10BAC10, 100 kA rating): $\text{Duty Ratio} = \frac{55.05\text{ kA}}{100\text{ kA}} = \mathbf{0.550} < 1.0$ (Safety margin: $45\%$).
- For GIS Bay Breaker Q0 (8DN9, 50 kA rating): $\text{Duty Ratio} = \frac{6.90\text{ kA}}{50\text{ kA}} = \mathbf{0.138} < 1.0$ (Safety margin: $86.2\%$).  
Across all 96 fault scenarios evaluated, our study proved **zero duty exceedances**, confirming full compliance with IEEE C37.010.

---

#### Q10. Why must the turbine Emergency Stop Valves (ESV) trip during an electrical fault?
**Model Answer:**  
If an electrical fault causes the Generator Circuit Breaker (GCB) to open while the gas turbine is generating 300+ MW of power, the electrical counter-torque ($T_e$) drops to zero in 50 ms.  
However, high-pressure expanding gas is still rushing through the turbine blades ($T_m > 0$). With net torque $\Delta T = T_m - 0 = J \frac{d\omega}{dt}$, the rotor accelerates violently. Within 1 second, it would exceed its maximum permissible mechanical overspeed limit (>120% speed), leading to centrifugal destruction of the turbine blades. Tripping the ESV cuts off fuel gas within 100 ms to arrest turbine acceleration.

---

#### Q11. How do directional elements (ANSI 67 / 67N) prevent false tripping on parallel lines or backfeed?
**Model Answer:**  
On parallel transmission lines or interconnected networks, current can flow in either direction. A standard non-directional overcurrent relay (51) cannot distinguish between forward fault current (flowing into a faulted line) and reverse through-current (flowing from healthy lines toward a fault behind the bus).  
Directional relays (67/67N) compare the phase angle between the measured fault current and a reference polarizing voltage (from VTs) or neutral zero-sequence flux. If the phase angle indicates power is flowing backward into the source bus, the trip circuit is blocked, preventing healthy parallel lines from tripping unnecessarily.

---

#### Q12. Why does a transformer require both electrical 87T protection and mechanical Buchholz / PRD protection?
**Model Answer:**  
Because they protect against entirely different fault physics:
1. **Electrical Differential 87T:** High-speed protection (45 ms) for high-energy phase-to-phase and phase-to-ground faults that produce noticeable current imbalances. However, 87T is insensitive to incipient faults (minor turn-to-turn insulation breakdown or localized hot spots drawing negligible fault current).
2. **Mechanical Buchholz Relay:** Detects slow gas accumulation from decomposing oil caused by low-energy arcing, loose connections, or partial discharge long before it becomes a major electrical fault.
3. **Pressure Relief Device (PRD):** A mechanical spring-loaded diaphragm that vents instantaneous hydraulic shockwaves in the oil tank to prevent catastrophic structural rupture if an arc occurs.

---

#### Q13. What is the significance of the X/R ratio in short-circuit analysis and how does it affect DC offset?
**Model Answer:**  
The $X/R$ ratio determines the time constant of the DC component decay during a short-circuit fault:
$$\tau_{\text{DC}} = \frac{L}{R} = \frac{X}{2\pi f R}$$
At the generator terminals (F1), $X/R \approx 32.5$, resulting in a very long DC decay time constant ($\tau_{\text{DC}} \approx 100\text{ ms}$). A high $X/R$ ratio means:
1. The DC offset remains near 100% during the first few cycles, significantly increasing the peak make current ($i_p$) and mechanical forces.
2. The current waveform experiences "delayed current zeros", meaning the alternating current does not cross zero for several cycles. Circuit breakers rely on natural current zero crossings to extinguish the arc; therefore, breakers with high $X/R$ ratings must be selected to interrupt without restrike.

---

#### Q14. Why do we install both Line Current Differential (87L) and Distance (ANSI 21) relays on the 230 kV lines?
**Model Answer:**  
To achieve the industry-standard principle of **Primary and Autonomous Backup Protection**:
1. **Primary (87L via Optical Fiber):** 87L provides absolute unit protection. It compares current entering and leaving the line over an optical fiber link and clears 100% of the line instantaneously (40 ms). However, it relies on an external communication channel.
2. **Backup (Distance ANSI 21):** Distance relays do not require any communication channels. They measure local voltage and current to calculate apparent impedance ($Z = V/I$). If the fiber optic cable is cut or fails, the distance relay independently clears faults in Zone 1 (80% of line instantaneously) and Zone 2 (remaining 20% in 300 ms).

---

#### Q15. How does the generator AVR and de-excitation field circuit breaker protect the machine during an internal stator fault?
**Model Answer:**  
Opening the Generator Circuit Breaker (GCB) disconnects the generator from the grid, stopping grid current from entering the machine. However, the generator rotor is still spinning at 3,000 RPM with intense DC magnetic excitation.  
As long as the rotor magnetic field exists, the spinning machine acts as an independent voltage source, continuing to feed hundreds of amperes into its own internal stator arc!  
To stop internal destruction, the unit trip simultaneously trips the **Automatic Voltage Regulator (AVR) field circuit breaker**, which inserts a high-speed discharge resistor across the rotor field winding to collapse the machine's magnetic flux within hundreds of milliseconds.

---

#### Q16. In our Simulink dynamic model, how are the faults simulated and synchronized with protection tripping?
**Model Answer:**  
In `PHASE6_ASHUGANJ_CCPP_DYNAMIC_MODEL.slx`:
1. Faults are initiated by a **Three-Phase Fault Block** programmed with a transition time vector (e.g., `[0.2, 0.35]` seconds) and configurable ground impedance $R_{\text{on}}$ and $R_g$.
2. Measurement blocks (Three-Phase V-I Measurements) sample instantaneous three-phase voltages and currents at 10 kHz.
3. These signals enter our custom C-MEX S-Function and MATLAB function protection blocks (87G, 87T, 87B, 87L, 51, 51N).
4. When the relay logic satisfies pickup and time delay thresholds, it outputs a logical `1` trip signal that commands the physical circuit breaker subsystem (Simscape Three-Phase Breaker) to open its internal contacts at the next current zero, isolating the fault dynamically.

---

## 8. MATLAB Simulation Verification & File Index

All calculations, symmetrical component analyses, and dynamic protection models have been fully implemented, validated, and archived within the project repository:

### 8.1 MATLAB Verification Commands
To rerun and verify all calculations and tests in the MATLAB Command Window:

```matlab
% Set working directory to project root:
cd('c:/Users/Sindid/OneDrive/Desktop/MouseWithoutBorders/306 Power Project -ekkebare f/Simulation_Workspace')

% 1. Re-run complete Phase 4 Symmetrical Fault Analysis:
addpath(genpath('matlab'));
run_phase4_production();

% 2. Verify all Phase 5 Protection Relay Settings & Grading Margins:
run_phase5b_tests();   % PASS = 528, FAIL = 0

% 3. Run Phase 6 Dynamic Relay Engine Tests:
addpath('Phase6/scripts'); addpath('Phase6/scripts/tests');
test_phase6_relays();
test_phase6_protection_sfunctions();

% 4. Verify Emergency Auxiliary Supply System:
test_emergency_supply(); % PASS (5 cases, Qaux 8.6764 MVAr)
```

### 8.2 Deliverables File Index in `Phase 4 Docs/`
| File Name | Description | Link |
| :--- | :--- | :--- |
| **`FAULT_ANALYSIS_MANUAL.html`** | Full interactive HTML manual with zoomable lightbox gallery, animated cards, and responsive navigation. | [Open HTML](file:///C:/Users/Sindid/OneDrive/Desktop/MouseWithoutBorders/306%20Power%20Project%20-ekkebare%20f/Phase%204%20Docs/FAULT_ANALYSIS_MANUAL.html) |
| **`FAULT_ANALYSIS_MANUAL.md`** | Complete printable Markdown technical defense manual (this document). | [Open Markdown](file:///C:/Users/Sindid/OneDrive/Desktop/MouseWithoutBorders/306%20Power%20Project%20-ekkebare%20f/Phase%204%20Docs/FAULT_ANALYSIS_MANUAL.md) |
| **`snapshots/sld_fault_locations_marked.png`** | Master OEM Single Line Diagram with bold circled callouts for $F_1$ to $F_5$. | [View Image](file:///C:/Users/Sindid/OneDrive/Desktop/MouseWithoutBorders/306%20Power%20Project%20-ekkebare%20f/Phase%204%20Docs/snapshots/sld_fault_locations_marked.png) |
| **`snapshots/simulink_fault_locations_marked.png`** | Top-level plant Simulink dynamic model overview with marked fault positions. | [View Image](file:///C:/Users/Sindid/OneDrive/Desktop/MouseWithoutBorders/306%20Power%20Project%20-ekkebare%20f/Phase%204%20Docs/snapshots/simulink_fault_locations_marked.png) |
| **`snapshots/F1_generator_fault_block.png`** | Simulink F1 Generator bus fault subsystem snapshot. | [View Image](file:///C:/Users/Sindid/OneDrive/Desktop/MouseWithoutBorders/306%20Power%20Project%20-ekkebare%20f/Phase%204%20Docs/snapshots/F1_generator_fault_block.png) |
| **`snapshots/F2_transformer_LV_fault_block.png`** | Simulink F2 GSUT LV connection fault subsystem snapshot. | [View Image](file:///C:/Users/Sindid/OneDrive/Desktop/MouseWithoutBorders/306%20Power%20Project%20-ekkebare%20f/Phase%204%20Docs/snapshots/F2_transformer_LV_fault_block.png) |
| **`snapshots/F3_GIS_bus_fault_block.png`** | Simulink F3 230 kV GIS switchyard bus fault subsystem snapshot. | [View Image](file:///C:/Users/Sindid/OneDrive/Desktop/MouseWithoutBorders/306%20Power%20Project%20-ekkebare%20f/Phase%204%20Docs/snapshots/F3_GIS_bus_fault_block.png) |
| **`snapshots/F4_line_midpoint_fault_block.png`** | Simulink F4 Transmission line midpoint fault subsystem snapshot. | [View Image](file:///C:/Users/Sindid/OneDrive/Desktop/MouseWithoutBorders/306%20Power%20Project%20-ekkebare%20f/Phase%204%20Docs/snapshots/F4_line_midpoint_fault_block.png) |
| **`snapshots/F5_remote_bus_fault_block.png`** | Simulink F5 Remote grid substation bus fault subsystem snapshot. | [View Image](file:///C:/Users/Sindid/OneDrive/Desktop/MouseWithoutBorders/306%20Power%20Project%20-ekkebare%20f/Phase%204%20Docs/snapshots/F5_remote_bus_fault_block.png) |
| **`snapshots/protection_zones_map.png`** | Protection Zones map showing overlapping boundaries. | [View Image](file:///C:/Users/Sindid/OneDrive/Desktop/MouseWithoutBorders/306%20Power%20Project%20-ekkebare%20f/Phase%204%20Docs/snapshots/protection_zones_map.png) |

---
*Manual compiled and verified for Ashuganj South 450 MW CCPP EEE 306 Project Defense.*
