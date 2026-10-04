# Ashuganj 450 MW CCPP (South) - Final Master Data for AC/DC Studies
## Context package for MATLAB/Simulink/Simscape Electrical, fault analysis and protection studies

**Purpose:** This document consolidates the current Ashuganj South CCPP data collected from the project technical documents, the newly obtained generator/transformer dataset, the current PGCB line-data PDF, the Siemens/TSK GIS as-built drawings, the PGCB/JICA grid study, and selected web references. It provides a single working dataset for the complete project.

### Data-status legend
- **A - Project/official source:** directly stated in an uploaded project/PGCB/APSCL/Siemens document or official public record.
- **B - Strong secondary/project-supplied:** technically specific data from a supplied workbook or secondary study; use, but retain source/provenance note.
- **C - Engineering assumption:** missing plant-specific value filled with a realistic non-zero value for simulation. **Never describe C-values as measured plant facts.**
- **D - Derived:** calculated from sourced values using the equation shown.

---

# 1. PROJECT SCOPE AND CURRENT MODELING APPROACH

## Recommended core model

```text
SGen5-2000H generator
      |
      | 22 kV
      |
515 MVA GSUT, 22/230 kV
      |
      |
Ashuganj South 230 kV GIS
(BB1 / BB2, Q0, Q1, Q2, Q9)
      |
      | 2-circuit 230 kV connection, ~0.7 km
      |
Ashuganj 230 kV grid
      |
      +---- Ghorasal 230 kV D/C
      +---- Comilla North 230 kV D/C
      +---- Sirajganj 230 kV D/C
      +---- Kishoreganj 230 kV D/C
      |
   400/230 kV grid transformers
      |
Ashuganj North 400 kV
      |
      | 400 kV D/C, 69 km
      |
Bhulta 400 kV
```

The physical 230-kV GIS has two busbars and detailed switching/protection. For power-flow/fault calculations, it can be reduced to one electrically equivalent 230-kV bus unless busbar switching itself is being studied.

---

# 2. PRIMARY SOURCES USED

| Ref | Source | Main use |
|---|---|---|
| F1 | Siemens/TSK/INELECTRA/APSCL project drawing `S008-112070-00-ELC-DE-1011`, revision 04/04_1, As Built Factory | 230-kV GIS, busbars, breakers, CT/VT, protection |
| F2 | Current `Line data.pdf` supplied in this project | Transmission line route length, circuits, conductor |
| F3 | `Ahsuganj South (1).xlsx` / newly supplied generator-transformer dataset | Generator and transformer electrical parameters |
| F4 | PGCB/JICA `12248464.pdf` | Historical modeled capacity and regional grid context |
| F5 | PGCB June 2019 existing 400/230/132-kV grid map | Network topology |
| F6 | APSCL/industrial-training material | Plant equipment/background |
| F7 | EEE306 project proposal + Exp3 + Exp4 | Required study workflow and fault types |

### Web references used for engineering checks
- PGCB/BPDB line information and feasibility studies.
- BPDB daily generation records.
- OPAL-RT typical transmission-line sequence parameters.
- SEL technical paper with typical 230-kV overhead-line sequence values.
- ACSR conductor manufacturer/data-sheet references.

---

# 3. BUS DATA

## 3.1 Core and regional buses

| Bus ID | Description | Nominal kV | Type | Voltage target | Status | Use |
|---|---|---:|---|---:|---|---|
| B01 | South generator terminal | **22** | PV | 1.00 pu | A/B | Generator/load flow/fault |
| B02 | Ashuganj South 230-kV GIS | **230** | PQ or PV as required | 1.00 pu | A | Plant bus |
| B03 | Ashuganj 230-kV grid bus | **230** | Slack/External Grid | 1.00 pu | A/B | Grid equivalent |
| B04 | Ashuganj North 400-kV bus | **400** | PQ | 1.00 pu | A/B | Regional network |
| B05 | Bhulta 400-kV bus | **400** | PQ / remote grid | 1.00 pu | A/B | Regional network |
| B06 | Ashuganj 132-kV bus | **132** | PQ | 1.00 pu | A/B | Optional regional model |
| B07 | Ghorasal 230-kV bus | **230** | PQ | 1.00 pu | A/B | Optional regional model |
| B08 | Comilla North 230-kV bus | **230** | PQ | 1.00 pu | A/B | Optional regional model |
| B09 | Sirajganj 230-kV bus | **230** | PQ | 1.00 pu | A/B | Optional regional model |
| B10 | Kishoreganj 230-kV bus | **230** | PQ | 1.00 pu | A/B | Optional regional model |
| B11 | Plant auxiliary bus | **6.6 kV** | PQ | 1.00 pu | C | Preliminary auxiliary model |

**Important:** The current line map confirms the 230-kV and 400-kV network topology, while the exact 6.6-kV auxiliary voltage remains an engineering assumption unless confirmed by the plant MV SLD.

---

# 4. GENERATOR DATA - KEEP THIS AS A SEPARATE, HIGH-PRIORITY SECTION

## 4.1 Generator nameplate/model data

| Parameter | Value | Status |
|---|---:|---|
| Plant generator | Siemens **SGen5-2000H** | A/B |
| Gas turbine | Siemens **SGT5-4000F** | A |
| Steam turbine | Siemens **SST-3000** | A |
| Generator active rating | **360 MW** | B; also independently supported by BPDB |
| Generator MVA rating | **458 MVA** | B; supplied project dataset |
| Generator terminal voltage | **22 kV** | B; supplied project dataset |
| Frequency | **50 Hz** | C/system assumption |
| Rated current | **~12.02 kA** | D |
| Inertia H | **5.287 s** | B |
| Short-circuit ratio | **0.601** | B |
| Stator resistance Ra | **0.00089 ohm** | B |
| Excitation | **Static** | B |
| Excitation controller | **SEMIPOL** | B |

### Rated-current calculation

\[
I_{rated} = \frac{458\times10^6}{\sqrt{3}\times22\times10^3}
\approx 12.02\text{ kA}
\]

---

# 5. GENERATOR REACTANCE / SEQUENCE DATA

| Parameter | Value (pu) | Status | Recommended use |
|---|---:|---|---|
| Xd | **1.783** | B | Steady-state/dynamic |
| Xd' | **0.3256** | B | Transient |
| Xd'' | **0.2608** | B | Fault study sensitivity/base |
| Xd'' saturated | **0.2248** | B | **Primary initial fault case** |
| Xq | **1.751** | B | Dynamic |
| Xq' | **0.5087** | B | Dynamic |
| Xq'' | **0.2593** | B | Dynamic/fault model |
| Xl | **0.2027** | B | Dynamic |
| X2 saturated | **0.2242** | B | LL / LLG |
| X0 saturated | **0.1280** | B | LG / LLG |
| R1 | **~0.000843 pu** | D | From Ra |
| R2 | **~0.000843 pu** | C | Assume R2 = R1 |
| R0 | **~0.001265 pu** | C | Assume R0 = 1.5 R1 pending data |

### Time constants

| Parameter | Value |
|---|---:|
| Td0' | **7.547 s** |
| Td0'' | **0.045 s** |
| Tq0' | **0.839 s** |
| Tq0'' | **0.070 s** |
| Td' | **1.213 s** |
| Td'' | **0.035 s** |
| Tq' | **0.214 s** |
| Tq'' | **0.035 s** |
| Ta(3) | **0.704 s** |
| S(1.0) | **0.0865** |
| S(1.2) | **0.408** |

All above except the explicitly derived/assumed resistance values are taken from the newly supplied generator dataset.

### Fault-study rule

Use:
- **Xd'' = 0.2248 pu saturated** for the primary maximum initial 3-phase fault case.
- **Xd'' = 0.2608 pu** as an unsaturated/sensitivity case.
- **X2 = 0.2242 pu** for negative sequence.
- **X0 = 0.128 pu** for zero sequence.
- Solidly grounded neutral is retained per supplied dataset.

---

# 6. GENERATOR OPERATING POINT FOR BASE LOAD FLOW

Recent BPDB daily generation records show South as a **1 x 360 MW** unit, with a representative scheduled/actual value around **342.01 MW**.

### Recommended base case

| Quantity | Value | Status |
|---|---:|---|
| Net plant output target at grid | **342.01 MW** | B/A-web observed operating case |
| Auxiliary load | **12 MW + 5 MVAr** | C |
| Approx. generator gross MW | **354 MW** | D |
| Initial generator PF | **0.98 lagging** | C |
| Initial generator Q | **~72 MVAr** | D |
| Generator voltage setpoint | **1.00 pu** | C |
| Generator Pmin | **180 MW** | C |
| Generator Pmax | **360 MW** | B |
| Generator Qmin | **-200 MVAr** | C |
| Generator Qmax | **+200 MVAr** | C |

**Important:** If the 342.01 MW BPDB value is already a gross generator-terminal measurement in the source used for your final study, do not add the 12 MW auxiliary load again. For the plant-internal model, the recommended convention is approximately **354 MW gross generation -> 12 MW auxiliary -> ~342 MW export before network losses**.

---

# 7. GSUT DATA

## 7.1 South CCPP GSUT

| Parameter | Value | Status |
|---|---:|---|
| Rating | **515 MVA** | B / project dataset |
| LV/generator side | **22 kV** | B |
| HV/grid side | **230 kV** | B/A |
| Full-load losses | **1067.5 kW** | B |
| No-load losses | **155.3 kW** | B |
| Load-loss component | **912.2 kW** | D |
| Z1 magnitude | **0.1663 pu (16.63%)** | B |
| Vector group | **YNd1** | B |
| Neutral | **Solidly grounded** | B |
| Excitation-related transformer data | As supplied | B |

### Derived GSUT resistance/reactance

Taking the difference between full-load and no-load losses as load/copper loss:

\[
R_{pu} = \frac{0.9122}{515}=0.001771
\]

Then:

\[
X_{pu}=\sqrt{0.1663^2-0.001771^2}
\approx0.16629
\]

Therefore use, provisionally:

\[
\boxed{R_1=0.001771\ pu,\quad X_1\approx0.16629\ pu}
\]

on the 515-MVA transformer base.

For initial fault studies, use the same leakage magnitude for positive/negative sequence and explicitly apply the YNd1 zero-sequence blocking/grounding behavior in the sequence model.

**Note:** `0.00034%` no-load current from the supplied workbook is not trusted until the source sheet is re-checked.

---

# 8. ASHUGANJ GRID AUTOTRANSFORMERS

The supplied workbook identifies:

| Transformer | Rating | HV | LV | Tertiary | Tertiary MVA | Tap positions | Vector group | Neutral |
|---|---:|---:|---:|---|---:|---:|---|---|
| ASHUG-1 | **300 MVA** | 400 kV | 230 kV | 13.8 kV | 75 MVA | 17 | YNa0d1 | Solid |
| ASHUG-2 | **325 MVA** | 400 kV | 230 kV | 13.8 kV | 75 MVA | 17 | YNa0d1 | Solid |
| ASHUG-3 | **325 MVA** | 400 kV | 230 kV | 13.8 kV | 75 MVA | 17 | YNa0d1 | Solid |

### Pairwise impedances supplied in workbook

| Transformer | ZHL | ZHT | ZLT |
|---|---:|---:|---:|
| ASHUG-1 | **17.02** | **48.57** | **30.57** |
| ASHUG-2 | **17.02** | **48.60** | **32.30** |
| ASHUG-3 | **17.02** | **48.60** | **32.30** |

**Caution:** The workbook does not clearly establish the units/bases for these pairwise values. Do not silently treat all three as pu. For the simplified 400/230 network representation, use **ZHL = 17.02%** as the main HV-LV leakage value and the following assumption for winding loss split:

\[
X/R=25
\]

giving approximately:

\[
R_{pu}=0.006803,\quad X_{pu}=0.170064
\]

on the transformer own base.

Convert to a 100-MVA system base as needed:

| Transformer | ZHL on 100 MVA base | Rpu | Xpu |
|---|---:|---:|---:|
| ASHUG-1, 300 MVA | **0.05673** | **0.002268** | **0.05669** |
| ASHUG-2, 325 MVA | **0.05237** | **0.002096** | **0.05227** |
| ASHUG-3, 325 MVA | **0.05237** | **0.002096** | **0.05227** |

**If the three-winding transformer model is used, retain the supplied ZHL/ZHT/ZLT values and verify their original units/base first.**

---

# 9. 230-kV SOUTH CCPP CONNECTION

| Parameter | Value | Status |
|---|---:|---|
| From | Ashuganj South CCPP | B |
| To | Ashuganj 230-kV grid | A/B |
| Voltage | **230 kV** | A |
| Circuits | **2** | B/PGCB study |
| Length | **~0.7 km** | B/PGCB study |
| Conductor | **TBD** | C |
| R1 | **0.080 ohm/km** | C |
| X1 | **0.35 ohm/km** | C |
| B1 | **4.2 uS/km** | C |
| R0 | **0.25 ohm/km** | C |
| X0 | **1.20 ohm/km** | C |
| B0 | **2.8 uS/km** | C |
| Thermal rating | **500 MVA/circuit** | C |

The 0.7-km connection is retained from the previously identified PGCB planning study; the current line list does not independently list it.

---

# 10. TRANSMISSION LINE MASTER DATA

The current PGCB line-data PDF gives route/circuit/conductor information; the electrical parameters below are engineering values where the PDF is silent.

## 10.1 400-kV Ashuganj North - Bhulta

**Source physical data:** 69 km route, 138 circuit-km, double circuit, Twin Finch 1113 MCM. The current line PDF states this directly. [F2, p.1]

| Parameter | Value | Status |
|---|---:|---|
| Voltage | **400 kV nominal** | A |
| Equipment class | **420 kV class** | A/B |
| Circuits | **2** | A |
| Route length | **69 km** | A |
| Circuit km | **138 km** | A |
| Conductor | **Twin Finch 1113 MCM** | A |
| R1 | **0.031 ohm/km** | C |
| X1 | **0.32 ohm/km** | C |
| B1 | **5.0 uS/km** | C/D |
| R2 | **0.031 ohm/km** | C |
| X2 | **0.32 ohm/km** | C |
| B2 | **5.0 uS/km** | C |
| R0 | **0.28 ohm/km** | C |
| X0 | **1.15 ohm/km** | C |
| B0 | **3.1 uS/km** | C |
| Thermal rating | **1204 MVA/circuit** | B/PGCB study |

### Total series impedance per circuit

\[
Z_1=69(0.031+j0.32)
=\boxed{2.139+j22.08\ \Omega}
\]

---

## 10.2 230-kV Ghorasal - Ashuganj

Physical data: 44 km, double circuit, Mallard 795 MCM. fileciteturn13file0L62-L67

| Parameter | Value | Status |
|---|---:|---|
| Voltage | **230 kV** | A |
| Circuits | **2** | A |
| Route length | **44 km** | A |
| Conductor | **Mallard 795 MCM** | A |
| R1 | **0.0855 ohm/km** | C/D |
| X1 | **0.40 ohm/km** | C |
| B1 | **4.2 uS/km** | C |
| R2 | **0.0855 ohm/km** | C |
| X2 | **0.40 ohm/km** | C |
| B2 | **4.2 uS/km** | C |
| R0 | **0.25 ohm/km** | C |
| X0 | **1.45 ohm/km** | C |
| B0 | **2.8 uS/km** | C |
| Thermal rating | **400 MVA/circuit** | C |

\[
Z_1\approx\boxed{3.762+j17.60\ \Omega}
\]

---

## 10.3 230-kV Ashuganj - Comilla North

Physical data: 79 km, double circuit, Finch 1113 MCM. fileciteturn13file0L62-L67

| Parameter | Value |
|---|---:|
| Voltage | **230 kV** |
| Circuits | **2** |
| Length | **79 km** |
| Conductor | **Finch 1113 MCM** |
| R1/R2 | **0.062 ohm/km** |
| X1/X2 | **0.40 ohm/km** |
| B1/B2 | **4.0 uS/km** |
| R0 | **0.25 ohm/km** |
| X0 | **1.45 ohm/km** |
| B0 | **2.8 uS/km** |
| Thermal rating | **500 MVA/circuit** |

\[
Z_1\approx\boxed{4.898+j31.60\ \Omega}
\]

All electrical values in this table are C-values.

---

## 10.4 230-kV Ashuganj - Sirajganj

Physical data: 144 km, double circuit, Twin AAAC 37/4.176 mm. fileciteturn13file0L72-L79

| Parameter | Value |
|---|---:|
| Voltage | **230 kV** |
| Circuits | **2** |
| Length | **144 km** |
| Conductor | **Twin AAAC 37/4.176 mm** |
| R1/R2 | **0.065 ohm/km** |
| X1/X2 | **0.34 ohm/km** |
| B1/B2 | **4.2 uS/km** |
| R0 | **0.24 ohm/km** |
| X0 | **1.25 ohm/km** |
| B0 | **2.7 uS/km** |
| Thermal rating | **500 MVA/circuit** |

\[
Z_1\approx\boxed{9.36+j48.96\ \Omega}
\]

All electrical values are C-values.

---

## 10.5 230-kV Ashuganj - Kishoreganj

Physical data: 52 km, double circuit, ACCC Grosbeak 636 MCM. [F2, pp.4-5]

| Parameter | Value |
|---|---:|
| Voltage | **230 kV** |
| Circuits | **2** |
| Length | **52 km** |
| Conductor | **ACCC Grosbeak 636 MCM** |
| R1/R2 | **0.083 ohm/km** |
| X1/X2 | **0.38 ohm/km** |
| B1/B2 | **4.0 uS/km** |
| R0 | **0.25 ohm/km** |
| X0 | **1.45 ohm/km** |
| B0 | **2.8 uS/km** |
| Thermal rating | **400 MVA/circuit** |

\[
Z_1\approx\boxed{4.316+j19.76\ \Omega}
\]

All electrical values are C-values.

---

## 10.6 132-kV Brahmanbaria - Ashuganj

Physical data: 16.5 km, double circuit, Grosbeak 636 MCM. [F2, p.4]

| Parameter | Value |
|---|---:|
| Voltage | **132 kV** |
| Circuits | **2** |
| Length | **16.5 km** |
| Conductor | **Grosbeak 636 MCM** |
| R1/R2 | **0.105 ohm/km** |
| X1/X2 | **0.40 ohm/km** |
| B1/B2 | **2.8 uS/km** |
| R0 | **0.30 ohm/km** |
| X0 | **1.10 ohm/km** |
| B0 | **2.0 uS/km** |
| Thermal rating | **180 MVA/circuit** |

All electrical values are C-values.

---

## 10.7 132-kV Ashuganj - Ghorasal

Physical data: 45.3 km, double circuit, ACCC Grosbeak 636 MCM. [F2, p.4]

| Parameter | Value |
|---|---:|
| Voltage | **132 kV** |
| Circuits | **2** |
| Length | **45.3 km** |
| Conductor | **ACCC Grosbeak 636 MCM** |
| R1/R2 | **0.095 ohm/km** |
| X1/X2 | **0.40 ohm/km** |
| B1/B2 | **2.8 uS/km** |
| R0 | **0.28 ohm/km** |
| X0 | **1.10 ohm/km** |
| B0 | **2.0 uS/km** |
| Thermal rating | **200 MVA/circuit** |

All electrical values are C-values.

---

## 10.8 132-kV Ashuganj - Shahjibazar

Physical data: 53 km, single circuit, Grosbeak 636 MCM. [F2, p.5]

| Parameter | Value |
|---|---:|
| Voltage | **132 kV** |
| Circuits | **1** |
| Length | **53 km** |
| Conductor | **Grosbeak 636 MCM** |
| R1/R2 | **0.105 ohm/km** |
| X1/X2 | **0.40 ohm/km** |
| B1/B2 | **2.8 uS/km** |
| R0 | **0.30 ohm/km** |
| X0 | **1.10 ohm/km** |
| B0 | **2.0 uS/km** |
| Thermal rating | **180 MVA** |

All electrical values are C-values.

---

# 11. LINE-ASSUMPTION BASIS

The assumptions are deliberately non-zero and are constrained by published examples.

- A 400-kV benchmark line has typical values near **R1 = 0.0209 ohm/km, X1 = 0.3192 ohm/km, B1 = 5.19 uS/km; R0 = 0.303 ohm/km, X0 = 1.189 ohm/km, B0 = 3.17 uS/km**. Our 400-kV Twin-Finch values are chosen close to this range while reflecting the actual high-capacity bundle. (OPAL-RT typical 400-kV benchmark.)
- A published 230-kV overhead-line example gives approximately **Z1 = 0.060 + j0.472 ohm/km** and **Z0 = 0.230 + j1.590 ohm/km**. (SEL technical paper.)
- Conductor references give approximately **0.0509 ohm/km at 20 C for Finch 1113 MCM** and approximately **0.0715-0.0719 ohm/km at 20 C for Mallard 795 MCM**. Published Grosbeak 636 data are around **0.0899 ohm/km at 20 C for ACSR**. These support the resistance scale used above.

**Engineering rule:** if a PGCB line-parameter report is later obtained, replace all C-values immediately and retain the current values only for preliminary/sensitivity analysis.

---

# 12. EXTERNAL GRID EQUIVALENT

A secondary 2019 fault-level dataset reports for **ASHUGANJ S 230 kV**:

- 3-phase fault current = **45.01 kA**
- source impedance magnitude = **3.25 ohm**
- X/R = **10.99**

This is useful but is not treated as an official current PGCB study result.

### Recommended preliminary 230-kV external equivalent

Using 45.01 kA:

\[
S_{SC}=\sqrt3VI
\approx17.93\text{ GVA}
\]

Using X/R = 10.99:

\[
Z=3.25\Omega\text{ (use source-reported value)}
\]

and approximately:

\[
\boxed{R_{th}=0.268\Omega,\quad X_{th}=2.94\Omega}
\]

for the 230-kV grid equivalent.

Use:

- 230 kV
- 1.0 pu voltage
- 0 degree angle
- R = **0.268 ohm**
- X = **2.94 ohm**
- X/R ~= **10.99**
- 3-phase fault level ~= **17.93 GVA**

**Status: B/C - preliminary external-grid equivalent.**

Source: secondary 2019 fault-level compilation; use for modelling until an official PGCB fault-level study is obtained.

---

# 13. OPTIONAL 400-kV REMOTE GRID EQUIVALENT

For the regional 400-kV branch only, if a remote grid must be represented and no PGCB fault level is available, use:

| Parameter | Value | Status |
|---|---:|---|
| Voltage | **400 kV** | A |
| Assumed 3-phase fault current | **30 kA** | C |
| Fault level | **20.78 GVA** | D |
| X/R | **10** | C |
| Rth | **0.766 ohm** | D |
| Xth | **7.660 ohm** | D |

This is **not a plant fact** and is only a temporary regional-network assumption.

---

# 14. LOAD DATA

No authoritative complete South-plant AC load schedule has yet been found in the public/project set.

## Recommended preliminary plant auxiliary load

| Load | Bus | P | Q | Status |
|---|---|---:|---:|---|
| Plant auxiliaries - pumps, fans, motors, balance of plant | B11 (6.6 kV) | **12 MW** | **5 MVAr** | C |
| Equivalent 400-V auxiliaries | B11/LV subsystem | **3 MW** | **1.2 MVAr** | C |
| Remaining MV auxiliaries | B11 | **9 MW** | **3.8 MVAr** | C |

Use the **12 MW + 5 MVAr** aggregate only in the first plant-level load-flow case.

Do **not** use the earlier artificial `250 MW + 80 MVAr Ghorashal load` or `40 MW + 18 MVAr Bhairab load` as real plant loads. They were not source-supported.

---

# 15. LOAD-FLOW CASE

## Base Case A - Representative current operating condition

| Parameter | Value |
|---|---:|
| Generator gross P | **354 MW** |
| Generator voltage | **1.00 pu** |
| Initial generator Q | **~72 MVAr** |
| Plant auxiliary load | **12 + j5 MVA** |
| External grid | 230 kV Thevenin/slack |
| Grid V | **1.00 pu** |
| System MVA base | **100 MVA** |
| Frequency | **50 Hz** |
| Transformer taps | Mid/nominal position unless source tap position is available |

### Suggested validation target

BPDB records show South as a **360-MW** unit with recent representative actual/scheduled generation around **342.01 MW**. citeturn289760search0turn289760search4

---

# 16. FAULT STUDY CASES

Run the following at minimum:

| Fault | Location | Main parameters |
|---|---|---|
| LLL | Generator terminal B01 | Xd'' |
| LLL | South 230-kV GIS B02 | Grid + generator contributions |
| LG | B01 | Xd'', X2, X0, solid grounding |
| LG | B02 | Transformer/vector-group/grid zero sequence |
| LL | B01 | X2 |
| LL | B02 | X1/X2 |
| LLG | B01 | X2/X0 |
| LLG | B02 | X2/X0 |
| 3-phase | B03 | External-grid fault |
| 3-phase | B04/B05 | Optional regional fault |

### Fault-study generator values

Use:

\[
X_d''=0.2248\ pu
\]

primary saturated case,

\[
X_d''=0.2608\ pu
\]

sensitivity case,

\[
X_2=0.2242\ pu
\]

and

\[
X_0=0.128\ pu.
\]

---

# 17. GIS / SWITCHGEAR DATA

The Siemens/TSK as-built project drawing confirms a 230-kV GIS arrangement with two busbars, breaker/disconnector/earthing-switch equipment and protection/control devices. [F1, GIS SLD sheets]

| Parameter | Value | Status |
|---|---|---|
| GIS nominal voltage | **230 kV** | A |
| Equipment voltage class | **245 kV** | B |
| Busbars | **BB1, BB2** | A |
| Main breaker | **Q0** | A |
| Bus disconnectors | **Q1, Q2** | A |
| Line disconnector | **Q9** | A |
| Earth switches | **Q51/Q52** | A |
| High-speed earth switch | **Q8** | A |
| GIS short-time withstand | **50 kA** | B |
| Control voltage | **110 V DC** | A/B |

**Do not equate 50 kA equipment withstand with actual calculated fault current.**

---

# 18. CT DATA

The actual Siemens project drawing gives:

| Parameter | Value |
|---|---|
| CT ratio | **1600/800/400 : 1 A** |
| Protection Core 1 | **30 VA, 5P20** |
| Protection Core 2 | **30 VA, 5P20** |
| Measuring Core | **40 VA, Class 0.2** |
| Metering Core | **40 VA, Class 0.2** |

Source: Siemens/TSK project drawing.

Use the **appropriate 1600/1, 800/1, or 400/1 connection depending on the actual bay/application**; do not automatically assume 1600/1 for every relay.

---

# 19. VT DATA

| Parameter | Value |
|---|---|
| Primary | **230/sqrt(3) kV** |
| Secondary | **0.1/sqrt(3) kV** |
| Protection | **30 VA, Class 3P** |
| Measuring | **30 VA, Class 0.2** |
| Metering | **30 VA, Class 0.2** |

Source: Siemens/TSK project drawing.

---

# 20. PROTECTION SYSTEM

| Function | Equipment | Status |
|---|---|---|
| Line differential 87L | **2 x Siemens 7SD5221** | A |
| Busbar differential 87B | **Siemens 7SS523** | A |
| Bay control | **Siemens 6MD66** | A |
| Main GIS breaker | **Q0** | A |
| Auto-reclosure | Provided | A |
| Synchrocheck | Provided | A |
| Breaker-failure/lockout logic | Present in drawings | A |

Source: Siemens/TSK As-Built Factory drawings.

---

# 21. PROTECTION SETTINGS - STARTING ASSUMPTIONS ONLY

Actual relay setting files are not currently available, so use the following only as **initial engineering settings** and then coordinate against the calculated fault currents.

| Protection | Starting value | Status |
|---|---:|---|
| OC 51 pickup | **1.20 x maximum load current** | C |
| OC curve | **IEC Standard Inverse** | C |
| OC TMS initial | **0.20** | C |
| Earth-fault 51N pickup | **0.20 A secondary** | C |
| Earth-fault TMS | **0.15** | C |
| Grading margin | **0.30 s** | C |
| Transformer differential bias/start | **0.30 pu** | C |
| Transformer differential slope 1 | **30%** | C |
| Transformer differential slope 2 | **60%** | C |
| Generator differential start | **0.20 pu** | C |

Final protection settings must be derived after fault-current calculation and CT ratio selection.

---

# 22. DC / BATTERY / UPS SYSTEM

This section is for **control/protection-system representation**, not the AC load-flow network.

The Siemens bay-control equipment is documented with **110 V DC** control supply. [F1, bay-unit device list]

## Preliminary DC system assumptions

| Parameter | Value | Status |
|---|---:|---|
| Station DC nominal voltage | **110 V DC** | A/B |
| Battery bank | **55 x 2-V cells** | C |
| Battery nominal voltage | **110 V** | C/D |
| Battery capacity | **200 Ah** | C |
| Charger arrangement | **2 x 30 A** chargers, N+1 | C |
| Battery autonomy | **2 h** | C |
| DCDB | One main DC distribution board | C |
| Protection supply | Dedicated DC feeders | C |
| Breaker trip supply | 110 V DC | A/B + C |
| Breaker close supply | 110 V DC | C |
| Relay supply | 110 V DC | A/B |
| DC grounding | Single-point/system-specific | C |

These are **engineering assumptions only** because the actual station battery/charger datasheet has not been located.

---

# 23. EXCITATION / AVR / DYNAMIC DATA

## Source-provided

| Parameter | Value | Status |
|---|---:|---|
| Excitation | Static | B |
| Controller | SEMIPOL | B |
| H | 5.287 s | B |
| Xd/Xd'/Xd'' | Available | B |
| Xq/Xq'/Xq'' | Available | B |
| Generator time constants | Available | B |

## Still assumed if dynamic simulation is required

| Parameter | Temporary model |
|---|---|
| AVR structure | Generic static excitation model |
| AVR nominal voltage reference | 1.0 pu |
| Initial AVR gain | **200 pu/pu** |
| AVR time constant | **0.02 s** |
| Exciter upper/lower limits | **+5 / -5 pu** equivalent |
| PSS | Disabled initially |
| Governor | Generic gas-turbine speed governor |
| Speed droop | **5%** |
| Governor time constant | **0.5 s** |

These are optional dynamic-study assumptions and should not be represented as actual Siemens settings.

---

# 24. TRANSFORMER AUXILIARIES / GAT / UAT

Use the following only until the plant MV SLD confirms them:

| Item | Temporary value | Status |
|---|---:|---|
| Auxiliary bus | **6.6 kV** | C |
| UAT rating | **25 MVA** | C |
| UAT impedance | **8%** | C |
| UAT X/R | **15** | C |
| GAT | Include only if plant SLD confirms separate generator auxiliary arrangement | C |
| UAT/GAT parallel operation | **No - unless plant documentation confirms** | C |

---

# 25. 400/230-KV ASHUGANJ GRID BRANCH

The current line/network data and PGCB studies support the following regional topology:

```text
Ashuganj 230 kV
      |
      | 400/230 kV
      |
Ashuganj North 400 kV
      |
      | 400 kV D/C
      | 69 km
      |
Bhulta 400 kV
```

The current line-data PDF confirms Ashuganj(N)-Bhulta as **69 km, double circuit, Twin Finch 1113 MCM**. [F2, p.1]

A PGCB study gives an Ashuganj-Bhulta study-case flow of approximately **141.3 MW per circuit** and a **1204 MVA/circuit** rating, useful as a validation point.

---

# 26. 230/132-KV ASHUGANJ GRID TRANSFORMERS

The PGCB study indicates:

| Transformer | Rating | Voltage | Study loading |
|---|---:|---:|---:|
| Ashuganj 230/132 T1 | **150 MVA** | 230/132 kV | ~51.2 MVA |
| Ashuganj 230/132 T2 | **150 MVA** | 230/132 kV | ~51.2 MVA |

Use the supplied project workbook's more detailed 400/230-kV autotransformers for the 400-kV interface; do not mix those with the 150-MVA 230/132-kV transformers.

---

# 27. FINAL MASTER STATUS

## A. Can be treated as source-backed project data

- 360 MW South unit
- 458 MVA generator
- 22 kV generator
- Siemens SGen5-2000H
- SGT5-4000F
- SST-3000
- H = 5.287 s
- Xd = 1.783 pu
- Xd' = 0.3256 pu
- Xd'' = 0.2608 pu
- saturated Xd'' = 0.2248 pu
- Xq = 1.751 pu
- Xq' = 0.5087 pu
- Xq'' = 0.2593 pu
- X2 = 0.2242 pu
- X0 = 0.128 pu
- generator Ra = 0.00089 ohm
- GSUT 515 MVA
- GSUT 22/230 kV
- GSUT Z = 16.63%
- GSUT YNd1
- solid grounding
- static excitation / SEMIPOL
- 230-kV GIS
- BB1/BB2
- Q0/Q1/Q2/Q9/Q51/Q52/Q8
- CT 1600/800/400-1 A
- VT 230/sqrt(3) / 0.1/sqrt(3) kV
- 2 x 7SD522 line differential
- 7SS523 busbar protection
- 6MD66 bay controller
- 400-kV Ashuganj(N)-Bhulta: 69 km, D/C, Twin Finch 1113
- 230-kV Ghorasal-Ashuganj: 44 km, D/C, Mallard 795
- 230-kV Ashuganj-Comilla(N): 79 km, D/C, Finch 1113
- 230-kV Ashuganj-Sirajganj: 144 km, D/C, Twin AAAC 37/4.176
- 230-kV Ashuganj-Kishoreganj: 52 km, D/C, ACCC Grosbeak 636
- 132-kV Ashuganj-Ghorasal: 45.3 km, D/C, ACCC Grosbeak 636
- 132-kV Brahmanbaria-Ashuganj: 16.5 km, D/C, Grosbeak 636
- 132-kV Ashuganj-Shahjibazar: 53 km, S/C, Grosbeak 636

## B. Strong study/secondary values

- 230-kV South -> Ashuganj connection ~0.7 km, 2 circuits
- 2019 Ashuganj South 230-kV fault level 45.01 kA
- X/R 10.99 and source Z ~3.25 ohm
- 1204 MVA/circuit Ashuganj-Bhulta study rating
- 2 x 150 MVA Ashuganj 230/132-kV transformers
- 141.3 MW/circuit Ashuganj-Bhulta study flow

## C. Engineering assumptions to use only until actual values are obtained

- line R/X/B and zero-sequence values
- line thermal limits where not stated
- generator R2/R0
- generator Q limits
- operating generator PF if not measured
- auxiliary load
- 6.6-kV auxiliary voltage
- UAT values
- 400-kV external equivalent
- relay starting settings
- DC battery/charger capacity
- AVR/governor parameters

---

# 28. STUDY EXECUTION ORDER

1. Build the **core 22/230-kV South plant model**.
2. Add **12 MW + 5 MVAr auxiliary load**.
3. Add the **230-kV external Thevenin equivalent**.
4. Run base-case load flow at approximately **354 MW gross generation**.
5. Verify the approximate net export target of **342 MW**.
6. Add the 400/230-kV Ashuganj grid transformers.
7. Add the **400-kV Ashuganj North-Bhulta** line and regional network.
8. Run LLL, LG, LL and LLG faults at B01 and B02.
9. Calculate breaker duty from the largest fault currents.
10. Add CT/VT data.
11. Add 7SD522 / 7SS523 functional protection representation.
12. Calculate backup OC/EF coordination and TMS/PS.
13. Add DC/battery/control representation where required by the report.
14. Run sensitivity cases by varying line impedance and external-grid strength.
15. Clearly label all C-values in the final report as **engineering assumptions**.

---

# 29. IMPORTANT MODELING RULES FOR THE NEXT AI

**Do not replace source-backed values with generic textbook values.**

**Do not use the old 15.75-kV generator assumption. Use 22 kV.**

**Do not use the old 0.14-pu generator Xd'' assumption. Use 0.2248 pu saturated as the primary fault-study value and 0.2608 pu as a sensitivity value.**

**Do not model "Ghorashal export" as a fixed 250-MW load. Let export emerge from the power-flow solution.**

**Do not combine the 230-kV Ghorasal-Ashuganj 44-km line with the separate 132-kV Ashuganj-Ghorasal 45.3-km line.**

**Do not interpret the 400-kV GIS equipment class as a 420-kV nominal system bus. Use 400 kV nominal with 420-kV-class equipment where appropriate.**

**Do not present any C-value as an actual PGCB/APSCL/OEM value.**

---

# 30. KEY WEB REFERENCES FOR ENGINEERING ASSUMPTIONS

1. OPAL-RT, Typical Electrical Parameters - includes a 400-kV benchmark with approximately R1=0.0209 ohm/km, X1=0.3192 ohm/km, B1=5.1949 uS/km, R0=0.3030 ohm/km, X0=1.1892 ohm/km, B0=3.1743 uS/km:
https://opal-rt.atlassian.net/wiki/spaces/PDOCHS/pages/150307736/Typical%2BElectrical%2BParameters

2. SEL, typical transmission-line sequence parameters - includes a 230-kV overhead-line example:
https://cdn.selinc.com/assets/Literature/Publications/Technical%20Papers/6221_ProtectionACCables_DT_20160425_Web.pdf

3. Conductor reference, Finch 1113 MCM and related ACSR data:
https://www.mega-ex.com/product_general/Phelps_dodge/ALUMINIUM-BARE%20CONDUCTORS/ACSR.pdf

4. BPDB daily generation records - South unit listed as 1 x 360 MW, representative values around 342.01 MW:
https://misc.bpdb.gov.bd/daily-generation?date=11-06-2026

5. PGCB feasibility-study source - Ashuganj-Bhulta study loading/rating and Ashuganj 230/132-kV transformer study data:
https://www.scribd.com/document/875427300/Final-Report-v5-iifc-Pgcb-1

6. Secondary 2019 fault-level compilation used only as preliminary source for Ashuganj South 230-kV fault level:
https://www.scribd.com/document/900735010/Emailing-2019-Fault-Level

---

## END OF MASTER DATA PACKAGE
