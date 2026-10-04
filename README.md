# Ashuganj 450 MW Combined Cycle Power Plant (South) — Power System Analysis, Fault Calculation & Protection Coordination

[![MATLAB](https://img.shields.io/badge/MATLAB-R2024a%2B-blue.svg?logo=mathworks&logoColor=white)](https://www.mathworks.com/products/matlab.html)
[![Simulink](https://img.shields.io/badge/Simulink-Simscape%20Electrical-orange.svg?logo=mathworks&logoColor=white)](https://www.mathworks.com/products/simulink.html)
[![BUET](https://img.shields.io/badge/Institution-BUET%20EEE-green.svg)](https://eee.buet.ac.bd/)
[![Standards](https://img.shields.io/badge/Standards-IEC%2060909%20%7C%20IEEE%20242%20%7C%20IEEE%20C37-lightgrey.svg)](https://standards.ieee.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

An exhaustive, industry-grade grid interconnection, steady-state power flow, symmetrical/unsymmetrical fault analysis, switchgear duty assessment, protection coordination, and closed-loop dynamic simulation of the **Ashuganj 450 MW (South) Combined Cycle Power Plant (CCPP)** located in Brahmanbaria, Bangladesh.

Developed for **EEE 306: Power System I Laboratory**, Department of Electrical and Electronic Engineering (EEE), **Bangladesh University of Engineering and Technology (BUET)**.

---

## 👥 Authors & Contributors (Group 03, Section C-1)

1. **S. M. Sindid Islam Mahodi** (Student ID: **2206147**) — *Fault Analysis & Symmetrical Components*
2. **Sasshata Talukder** (Student ID: **2206136**) — *Power Flow & Protection Coordination*
3. **Rajib Khan** (Student ID: **2206152**) — *Network Modeling & Data Verification*
4. **Iftekhar-E-Islam** (Student ID: **2206153**) — *Simulink Dynamic Model & Relay Logic*
5. **Abu Mohammed Ibn Julker Nahin** (Student ID: **2206155**) — *Breaker Duty & Station DC System*

### Faculty Supervision & Course Information
- **Course**: EEE 306: Power System I Laboratory (January 2026 Term)
- **Course Instructors**:
  - **Md. Kamrul Hasan**, Lecturer, Department of EEE, BUET
  - **Md. Mahadi Jaman**, Part-Time Lecturer, Department of EEE, BUET
- **Institution**: Department of Electrical and Electronic Engineering (EEE), Bangladesh University of Engineering and Technology (BUET)

---

## 📑 Executive Summary & Plant Specifications

The **Ashuganj South 450 MW Combined Cycle Power Plant (CCPP)**, operated by Ashuganj Power Station Company Limited (APSCL), represents one of Bangladesh's premier baseload power generation facilities. This project establishes an authentic, engineering-grade computational model of the generating unit, generator step-up transformer (GSUT), 230 kV Gas-Insulated Substation (GIS), auxiliary systems, and multi-circuit transmission links to the national grid.

```text
========================================================================================
                                 PLANT ONE-LINE TOPOLOGY
========================================================================================
   [ Siemens SGen5-2000H ]
       458 MVA, 22 kV
              |
       [ GCB 10BAC10 ]  (22 kV, 12.4 kA cont., 100 kA sym. breaking)
              |
              +--------------------------+
              |                          |
       [ 515 MVA GSUT ]          [ UAT 25 MVA ] & [ GAT 25 MVA ]
       22 kV / 230 kV            22 kV / 6.6 kV Station Auxiliaries
              |                          |
    [ 230 kV GIS Switchyard ]     [ 6.6 kV Switchboard ]
      (Double Busbar BB1/BB2)      Station Auxiliary Loads (14 MW)
              |
      2x 230 kV D/C Links (Mallard 795 MCM ACSR, 0.7 km)
              |
     [ National Grid Yard ]
        +-- Ghorasal 230 kV D/C
        +-- Comilla North 230 kV D/C
        +-- Sirajganj 230 kV D/C
        +-- Kishoreganj 230 kV D/C
        +-- 400/230 kV Intertie Autotransformers -> Bhulta 400 kV D/C (69 km)
========================================================================================
```

### Primary Equipment Ratings
| Equipment | Nameplate / Design Rating | Key Parameters | Data Status / Source |
|---|---|---|---|
| **Turbogenerator** | Siemens SGen5-2000H, 458 MVA, 360 MW | 22 kV, 12.02 kA rated, pf 0.85, $H = 5.287\text{ s}$, $X_d'' = 0.169\text{ pu}$ | Official Project Datasheet |
| **GSUT** | 515 MVA (ODAF) / 355 MVA (ONAN), 22/230 kV | $Z = 16.0\%$, vector group YNd11, neutral solidly grounded | Rating Plate & Factory Test Report |
| **Generator Breaker (GCB)** | ABB/Siemens 10BAC10, 22 kV | 12.4 kA continuous, 100 kA symmetrical rms breaking | As-built SLD Rev 03 |
| **230 kV GIS Switchgear** | Siemens SF6 GIS (BB1 & BB2, Coupler 10BAY13) | 2000 A bay / 3150 A coupler, 50 kA sym., 125 kA peak withstand | Siemens GIS Drawing S008-112070 |
| **Auxiliary Transformers** | UAT & GAT: 25 MVA each, 22/6.6 kV | $Z_{UAT} = 10.5\%$, $Z_{GAT} = 12.0\%$, Dy11 | Project Datasheet |
| **Generator Neutral Grounding** | Distribution Transformer with NER | $R_{NER} = 1750.8\ \Omega$ primary equivalent, limits ground fault to 7.27 A | IEEE C37.102 Standard Sizing |
| **Station DC System** | Lead-acid battery 110 V, 200 Ah | Dual 20 kW redundant chargers, 180 A ceiling | IEEE 485 / IEC 60896 |

---

## 🔬 Core Engineering Studies & Key Results

### 1. Balanced Steady-State Load Flow Analysis
- **Scenarios Investigated**:
  1. *Full Base Load Export (345 MW at 230 kV Grid Boundary)*
  2. *Summer Peak Stressed Grid Export*
  3. *Winter Off-Peak Light Load Scenario*
  4. *Generator Islanding / Station Blackstart Condition*
- **Findings**:
  - GSUT operating point sits comfortably at **72.98% of ODAF** (515 MVA rating) and 105.87% of ONAN base, validating continuous forced-oil directed-air cooling operation.
  - Apparent 109.60% auxiliary loading identified as circulating reactive power flow between paralleled UAT and GAT 6.6 kV secondaries rather than thermal overload; resolved by establishing designated inter-bus section open tie operating policy.
  - Voltage profiles at 230 kV GIS busbars maintained strictly within $0.985\text{--}1.025\text{ pu}$.

### 2. Symmetrical & Unsymmetrical Short-Circuit Analysis (IEC 60909)
Comprehensive fault analysis evaluated across four fault topologies: Three-Phase Bolted (LLL), Single Line-to-Ground (SLG), Line-to-Line (LL), and Double Line-to-Ground (LLG).

| Fault Location | Nominal Voltage | 3-Phase Fault ($I_{k}''$) | SLG Fault ($I_{k1}''$) | LL Fault ($I_{k2}''$) | LLG Fault ($I_{k2E}''$) | Critical Design Implication |
|---|---|---|---|---|---|---|
| **Bus 01 (Gen Terminal)** | 22 kV | **126.21 kA** | **7.27 A** | 109.30 kA | 114.15 kA | Machine + Grid backfeed; NER limits SLG to 7.27 A |
| **Bus 02 (230 kV GIS Bay 1)** | 230 kV | **50.53 kA** | 46.12 kA | 43.76 kA | 48.91 kA | Within 50 kA / 125 kA GIS rating envelope |
| **Bus 03 (230 kV GIS Bay 2)** | 230 kV | **50.53 kA** | 46.12 kA | 43.76 kA | 48.91 kA | Bus coupler normally-closed tie balance |
| **Bus 11 (6.6 kV Auxiliary)** | 6.6 kV | **28.45 kA** | 22.10 kA | 24.64 kA | 27.80 kA | Cleared by 31.5 kA 10BBA10 switchgear |

### 3. Circuit Breaker Duty & Switching Equipment Assessment
- **GCB (10BAC10)**: Through-current during terminal fault separates into generator contribution (~55 kA) and backfeed through GSUT (~71 kA). Because fault current flows *either* towards the generator or towards the transformer, the actual through-breaker duty never exceeds the **100 kA verified breaking capability**.
- **230 kV Breakers (`10BAY11-Q0`, `Q1`, `Q2`)**: Total asymmetrical breaking duty calculated per IEC 60909 accounting for DC component decay at minimum contact parting time ($t_{min} = 45\text{ ms}$). All GIS circuit breakers operate well within their 50 kA sym. / 125 kA making limits.

### 4. Protection Coordination & Relay Grading
- **Coordination Time Interval (CTI)**: Set uniformly to **300 ms** ($0.30\text{ s}$) between successive stages, accommodating 60 ms breaker clearing time, 50 ms CT saturation margin, and relay overshoot.
- **Generator Differential (87G)**: Dual-slope biased differential relay ($I_s = 0.20\text{ pu}$, Slope 1 = 30%, Slope 2 = 60%) configured with 15000/1 A CTs.
- **Transformer Differential (87T)**: Biased differential relay ($I_s = 0.30\text{ pu}$) configured with 1600/1 A CTs on 230 kV side and 15000/1 A CTs on 22 kV side with zero-sequence current filtering.
- **Ground Fault Protection**:
  - `GEN-51N`: Definite-time neutral overcurrent set at $0.20\text{ A}$ secondary ($7.27\text{ A}$ primary) with $1.75\text{ s}$ delay.
  - `64G` 100% Stator Ground: 20 Hz sub-harmonic voltage injection detection for 100% winding coverage including the neutral point.
- **Backup Inverse Overcurrent (51/51N)**: IEC Standard Inverse (SI) curves with TMS = 0.20 for generator, transformer HV, and GIS feeder bays.

### 5. Closed-Loop Simulink Dynamic Stability Simulation
- Developed in MATLAB / Simulink / Simscape Specialized Power Systems (SPS).
- Evaluates full electro-mechanical transient response following a bolted 3-phase fault on the 230 kV GIS busbar.
- Closed-loop relay logic triggers trip signal within **27 ms**, and circuit breaker clears the fault completely at **87 ms**.
- Rotor angle, terminal voltage, and frequency traces confirm rapid stabilization without pole-slipping or excitation loss.

---

## 🌐 Interactive HTML Documentation & Engineering Manuals

This repository includes a suite of standalone, publication-grade interactive HTML engineering manuals. Open any file in modern web browsers:

| Interactive Document | File Path | Description & Contents |
|---|---|---|
| **Project Final Report** | `EEE_306_Final_Project_Report_Ashuganj_450MW.docx` | Full 100+ page formal academic final project report submitted to BUET EEE. |
| **Interactive Report Writing Manual** | [`PROJECT_REPORT_WRITING_MANUAL.html`](PROJECT_REPORT_WRITING_MANUAL.html) | Complete interactive guide to academic formatting, derivations, figures, and data. |
| **Relays & Settings Manual** | [`PROTECTION_RELAYS_AND_SETTINGS_MANUAL.html`](PROTECTION_RELAYS_AND_SETTINGS_MANUAL.html) | Interactive relay setting tables, CT/VT ratios, pickup calculations, and TCC plots. |
| **Project Assumptions Manual** | [`PROJECT_ASSUMPTIONS_MANUAL.html`](PROJECT_ASSUMPTIONS_MANUAL.html) | Master parameters audit, IEEE standards traceability, and engineering justification. |
| **Results & Findings Manual** | [`PROJECT_RESULTS_AND_FINDINGS.html`](PROJECT_RESULTS_AND_FINDINGS.html) | Full numerical summaries, fault currents, voltage profiles, and contingency analyses. |
| **Presentation & Defense Portal** | [`PRESENTATION_VIDEO_SCRIPT_AND_DEFENSE.html`](PRESENTATION_VIDEO_SCRIPT_AND_DEFENSE.html) | Slide-by-slide presentation script, defense preparation guide, and technical Q&A. |
| **Video Cover Studio** | [`VIDEO_COVER_STUDIO.html`](VIDEO_COVER_STUDIO.html) | Broadcast-quality presentation title cards and project cover photo studio. |
| **Phase 4 Fault Analysis Manual** | [`Phase 4 Docs/FAULT_ANALYSIS_MANUAL.html`](Phase%204%20Docs/FAULT_ANALYSIS_MANUAL.html) | Detailed sequence network diagrams, impedance matrices, and IEC 60909 derivations. |
| **Phase 5 Protection Manual** | [`Phase 5 Docs/PROTECTION_SETTINGS_MANUAL.html`](Phase%205%20Docs/PROTECTION_SETTINGS_MANUAL.html) | Secondary relay grading, coordinating time intervals, and zone selectivity. |

---

## 📂 Repository Directory Structure

```text
.
├── EEE_306_Final_Project_Report_Ashuganj_450MW.docx    <- Official BUET Final Project Report
├── LICENSE                                             <- MIT Open Source License (S M Sindid Islam Mahodi)
├── README.md                                           <- Master Project Documentation
├── PROJECT_REPORT_WRITING_MANUAL.html                  <- Interactive Report Writing Manual
├── PROJECT_ASSUMPTIONS_MANUAL.html                     <- Master Parameters & Assumptions Registry
├── PROTECTION_RELAYS_AND_SETTINGS_MANUAL.html          <- Protection Relays & Settings Dashboard
├── PROJECT_RESULTS_AND_FINDINGS.html                   <- Detailed Fault & Flow Results Manual
├── PRESENTATION_VIDEO_SCRIPT_AND_DEFENSE.html          <- Video Presentation & Defense Guide
├── VIDEO_COVER_STUDIO.html                             <- Presentation Title & Cover Studio
├── PROJECT_DEMO_VIDEO_COVER_PHOTO.jpg                  <- Project Cover Artwork
├── Phase 4 Docs/                                       <- Phase 4 Fault Analysis Manual & Figures
│   └── FAULT_ANALYSIS_MANUAL.html
├── Phase 5 Docs/                                       <- Phase 5 Protection Coordination Manual
│   └── PROTECTION_SETTINGS_MANUAL.html
├── Simulation_Workspace/                      <- Complete MATLAB / Simulink / PSAF Workspace
│   ├── RUN_ME.m                                        <- One-command Master Simulation Runner
│   ├── RUN_EMERGENCY_SUPPLY.m                          <- Station DC & Emergency Power Simulation
│   ├── simulink/                                       <- Simulink Models & Subsystem Blocks
│   ├── matlab/                                         <- Automated Scripts, Calculations & Plotters
│   ├── Phase6/                                         <- Closed-Loop Dynamic Simulation & Trip Logic
│   ├── data/                                           <- Sourced Machine, Transformer & Line Datasets
│   ├── results/                                        <- Generated CSV Reports, Figures & Curves
│   └── docs/                                           <- Archival Technical Notes & Phase Reports
└── tools/ & scripts/                                   <- Automation & Figure Generation Scripts
```

---

## 🚀 Quick Start Guide: Running the MATLAB Simulation

### Prerequisites
- **MATLAB R2024a or higher**
- **Simulink**
- **Simscape Electrical** (*Specialized Power Systems*)

### Execution Steps
1. Clone or download this repository:
   ```bash
   git clone https://github.com/sindidislam/ashuganj-450mw-ccpp-power-system-analysis.git
   cd ashuganj-450mw-ccpp-power-system-analysis
   ```
2. Open MATLAB and navigate into the project workspace:
   ```matlab
   cd('Simulation_Workspace')
   ```
3. Run the automated environment self-check:
   ```matlab
   RUN_ME check
   ```
4. Solve the complete power-flow and protection study:
   ```matlab
   RUN_ME
   ```
   *Available commands*:
   - `RUN_ME open` — Launch the interactive Simulink system diagram
   - `RUN_ME solve` — Run steady-state load flow solver
   - `RUN_ME figures` — Redraw all fault oscillograms and TCC curves
   - `RUN_ME tests` — Execute the automated numeric validation test suite

---

## 📜 Academic Honesty & Citation

This repository represents original research, modeling, and analysis conducted by the authors for **EEE 306 Power System I Laboratory** at BUET. All manufacturer datasheets, PGCB grid codes, Siemens as-built diagrams, and literature references have been cited in the report.

If you utilize this model, codebase, or documentation in academic work, please cite:

```bibtex
@misc{mahodi2026ashuganj,
  author       = {Mahodi, S M Sindid Islam and Talukder, Sasshata and Khan, Rajib and Islam, Iftekhar-E and Nahin, Abu Mohammed Ibn Julker},
  title        = {Fault Analysis, Protection Coordination, and Dynamic Stability Analysis of Ashuganj South 450 MW Combined Cycle Power Plant},
  year         = {2026},
  howpublished = {BUET EEE 306 Final Project Report, Department of Electrical and Electronic Engineering, Bangladesh University of Engineering and Technology (BUET)},
  url          = {https://github.com/sindidislam/ashuganj-450mw-ccpp-power-system-analysis}
}
```

---

## 📄 License
This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.  
Copyright (c) 2026 **S M Sindid Islam Mahodi**.
