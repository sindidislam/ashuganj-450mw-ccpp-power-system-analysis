# PROJECT BRIEFING — Read This First

**Project:** Protection Coordination and Fault Analysis of the Ashuganj 450 MW
Combined Cycle Power Plant (South)
**Course:** BUET EEE 306, January 2026 · Group 03 · Section C-1
**This document covers:** what the project is, what has been built, what it found,
what is not done, and what you need to go and collect.
**Assumes no prior knowledge.** Every technical term is explained where it first
appears.

---

## 1. WHAT THIS PROJECT IS, IN PLAIN TERMS

Ashuganj is a power station in Bangladesh. The part we are studying is a **450 MW
combined-cycle unit** — meaning it burns gas in a gas turbine, then uses the leftover
exhaust heat to run a steam turbine as well, which is why it is called "combined
cycle" and why it is more efficient than a plain gas plant.

The whole unit is a **single-shaft** machine: one gas turbine and one steam turbine
sit on the *same shaft* driving **one single generator**. This matters — a lot of
people assume a combined-cycle plant has two or three generators. This one has one.

That generator produces electricity at **22,000 volts (22 kV)**. The national grid
runs at **230,000 volts (230 kV)**. So a very large transformer steps the voltage up
before the power leaves the site. A smaller transformer taps power *back down* to run
the plant's own equipment — pumps, fans, compressors — which is called the
**auxiliary** or **house** load.

That is the entire electrical system in one sentence:
**one generator → step-up transformer → 230 kV switchyard → national grid**, with a
side branch feeding the plant's own machinery.

### The title says "Protection Coordination and Fault Analysis". We are not there yet.

The final goal is to study **faults** (short circuits) and design the **protection**
(the relays and circuit breakers that detect a fault and disconnect it). But you
cannot study a fault in a network you have not yet built and verified.

So the current phase is the mandatory first step: **build the electrical model and
run a load flow study.** That work is what this briefing describes.

---

## 2. WHAT A "LOAD FLOW" IS, AND WHY IT COMES FIRST

A **load flow** (also called power flow) answers one question:

> If the generator produces this much power, and the plant consumes this much, **what
> voltage appears at every point in the network, and how much power flows through
> every transformer and cable?**

It is the electrical equivalent of a plumbing calculation: given the pumps and the
taps, what is the pressure at each junction and the flow in each pipe.

Three reasons it must come first:

1. **It proves the model is correct.** If power in does not equal power out plus
   losses, the model is wrong. A load flow makes that error visible immediately.
2. **Every later study needs it.** A short-circuit study starts from the pre-fault
   voltages. Protection settings depend on normal-operation currents — you cannot set
   a relay to trip on "too much current" until you know what normal current is.
3. **It finds real problems.** As it happens, this one did — see section 6.

Two terms you will see throughout:

- **MW / MVAr / MVA.** MW is *real* power — the part that does actual work. MVAr is
  *reactive* power — it does no work but is needed to magnetise motors and
  transformers, and it still causes current and losses. MVA is the two combined,
  and it is what equipment is rated for.
- **Per unit (pu).** Instead of writing "229,697 volts on a 230,000 volt system",
  engineers write **0.9987 pu** — the actual value divided by the nominal value.
  1.00 pu means exactly nominal. 0.95 pu means 5 % low. It makes every voltage level
  comparable at a glance.

---

## 3. WHAT YOU GAVE ME TO WORK WITH

- Engineering documents from the plant's construction (transformer data sheets,
  generator data, GIS switchgear specifications, rating plates)
- Single-line diagrams (SLDs) — the standard electrical schematic of the plant
- A structured Excel workbook indexing the above
- A Google Form filled in by your group
- The project proposal
- A prior study of this same plant done in **CYME PSAF** software

**Project identifiers**, useful when requesting more documents: EPC contractor
**TSK / Inelectra International**, engineering **GHESA / Empresarios Agrupados**,
equipment **Siemens**, project number **112070**, equipment tag prefix **`10B…`**.

### One critical scope boundary

Ashuganj also has a **North** plant. It is a *different unit*: project number
**7485**, with a **400 kV** switchyard and Hyosung interbus transformers. Some
North-plant material was mixed into the source set.

**Everything in this project is South-only.** No 400 kV network has been built,
because no South document requires one. This was flagged early and has been held to
throughout. If you see 400 kV anywhere in the source material, it is North scope.

### The prior CYME PSAF study has eight defects

I audited it and logged them as D1–D8. The one you must know about:

> **D2 — the prior model was built at 60 Hz.**

Bangladesh runs at **50 Hz**. A model at the wrong frequency gets every reactance
wrong, because reactance is proportional to frequency. **This model is built and
verified at 50 Hz.** Another defect, D6, is that the prior study omitted one
transformer (the GAT) entirely.

This matters for your presentation: if an examiner has seen the earlier study, you
need to be able to say what was wrong with it and that you did not inherit it.

---

## 4. WHAT I DID — THE METHOD

The work followed a fixed sequence, deliberately slow at the start:

| Phase | What happened |
|---|---|
| 0–1 | Inventoried every file, then read every document — data sheets, SLDs, rating plates, the Excel workbook, the Form, the prior study |
| 2 | Reconciled them against each other. **Found 18 contradictions** between documents (logged C1–C18) |
| 3 | Built a **master parameter registry**: one row per number, 126 rows, each carrying where it came from, its status, and a confidence level |
| 4 | Built the network topology — the bus and branch list |
| 5 | Identified everything missing, uncertain, assumed or conflicting |
| 6 | **Stopped and asked you 11 questions** that I could not answer from documents |
| 7 | Finalised the dataset using your 11 answers |
| 8 | Inspected your MATLAB installation to confirm what was actually available |
| 9–10 | Built the Simulink model **programmatically** — by script, not by dragging blocks |
| 11 | Validation: 434 automated checks |
| 12 | Ran the balanced load flow, four cases |
| 13 | Validated the results with independent cross-checks |
| 14 | Produced tables, plots and the report |

### The single most important rule I worked under

**No electrical parameter was ever invented.** Not one number was filled in because
it "looked reasonable" or was a textbook typical value. Every number in the model is
one of:

| Status | Meaning | Count |
|---|---|---|
| `VERIFIED_ENGINEERING_DOCUMENT` | read from a named document, with page reference | 62 |
| `VERIFIED_PLANT` | from plant/manufacturer data | 39 |
| `MISSING` | **absent, and recorded as absent** | 15 |
| `DERIVED_FROM_VERIFIED_DATA` | calculated from verified numbers, with the arithmetic shown | 4 |
| `ESTIMATED` | explicitly an estimate, labelled as such | 3 |
| `VERIFIED_PROJECT_DATA` | from project-level data | 2 |
| `NOT_APPLICABLE` | genuinely does not apply | 1 |

Where a number was genuinely needed and did not exist, it became a **declared
assumption** stored in a *separate* directory — never mixed with plant data — with
its own file recording the value, the reason, your approval status, and **how much
the answer would move if the assumption is wrong**.

There are **five** such assumptions. Three you approved. **Two are still awaiting
your decision** (section 9).

---

## 5. WHAT IS BUILT AND WORKING

### The model

A MATLAB / Simulink / Simscape Electrical model of the plant, built by script so it
can be regenerated from scratch at any time. It is laid out to read like an
engineering diagram, left to right:

```
   G1  ──  22 kV GEN BUS  ──  GSUT 10BAT10  ──  230 kV BUS 1 ══ BUS 2  ──  EXT GRID
           (generator)         (step-up            (switchyard,            (national
                                transformer)        gas-insulated)          grid)
                │                                        │
           UAT 10BBT10                              GAT 10BBT20
           (unit aux xfmr)                          (station aux xfmr)
                │                                        │
                └──────────  6.6 kV MV BUS  ─────────────┘
                                  │
                            400 V AUX BUS
```

The real equipment behind those labels:

| Item | What it is |
|---|---|
| **G1** | Siemens SGen5-2000H generator, 22 kV, 458 MVA continuous / 518 MVA maximum, driven by an SGT5-4000F gas turbine + SST-3000 steam turbine on one shaft |
| **GSUT 10BAT10** | Generator step-up transformer. 230/22 kV, three cooling stages **355 / 460 / 515 MVA**, impedance 16 % |
| **UAT 10BBT10** | Unit auxiliary transformer, taps off the generator terminals. 22/6.9 kV, **19 / 25 MVA**, impedance 10.5 % |
| **GAT 10BBT20** | Station auxiliary transformer, fed from the 230 kV side. 230/6.9 kV, **19 / 25 MVA**, impedance 12 % |
| **230 kV switchyard** | Siemens 8DN9 gas-insulated switchgear, busbars rated **3150 A**, fault withstand 50 kA for 1 second |

A **transformer with three cooling stages** means it can carry more load when its
fans and oil pumps are running. 355 MVA with natural cooling only, up to 515 MVA
with full forced cooling. This becomes important in section 6.

### Verification performed

| Check | Result |
|---|---|
| Automated data and topology tests | **434 of 434 pass** |
| Frequency | **50 Hz**, confirmed in the solved output, not just the setting |
| Power balance (does power in = power out + losses?) | Closes to **0.000000086 MVA** in the radial cases |
| Solver convergence | All four cases converge in **2 iterations** |
| Model regenerates from script | Yes, bit-identical |

### Deliverables on disk

126-row master registry · 7 MATLAB data files · 6 build scripts · 13 test files ·
5 Simulink models (1 main + 4 cases) · 5 result spreadsheets · 4 plots ·
a full load-flow report · a run-and-demonstrate manual · 7 model backups ·
a measured record of solver behaviour

---

## 6. WHAT THE STUDY FOUND

### Why there are four cases, not one

Two questions could not be settled from documents, so instead of guessing, both
possibilities were carried through. Two questions × two answers = **four cases**:

- **How much power is the generator actually producing?** The nameplate says
  **389.30 MW**. A site-derated figure (accounting for Bangladesh's ambient
  temperature, which reduces gas-turbine output) says **342.01 MW**. Nobody supplied
  a measured dispatch figure.
- **Is the GAT transformer in service or not?** No South document states its normal
  operating state.

| Case | Generator output | GAT | Network shape |
|---|---|---|---|
| **LF1** | 389.30 MW | out of service | radial (one path) |
| **LF2** | 389.30 MW | in service | looped (two paths) |
| **LF3** | 342.01 MW | out of service | radial |
| **LF4** | 342.01 MW | in service | looped |

### Headline results

| | LF1 | LF2 | LF3 | LF4 |
|---|---|---|---|---|
| Generator output (MW) | 389.30 | 389.30 | 342.01 | 342.01 |
| Generator reactive (MVAr) | 31.16 | 27.00 | 25.66 | 21.55 |
| Plant's own consumption (MW) | 14.00 | 14.00 | 14.00 | 14.00 |
| Total losses (MW) | 0.816 | 0.833 | 0.680 | 0.690 |
| **Exported to grid (MW)** | **374.48** | **374.47** | **327.33** | **327.32** |
| Losses as % of generation | 0.21 % | 0.21 % | 0.20 % | 0.20 % |
| 230 kV busbar voltage (pu) | 0.9987 | 0.9985 | 0.9990 | 0.9988 |
| 6.6 kV bus voltage (pu) | 1.0014 | 1.0205 | 1.0014 | 1.0210 |

**All voltages are within normal operating limits in all four cases.** Losses under
0.25 % are entirely reasonable for a plant this size — there is almost no
transmission distance inside the site.

### FINDING 1 — The GSUT exceeds its natural-cooling rating at full output

At rated output the step-up transformer carries **375.17 MVA**, which is
**105.87 %** of its 355 MVA natural-cooling stage.

**This is not a fault.** It means forced cooling — fans and oil pumps — is *required*
at full load, which is precisely why the transformer was specified with three cooling
stages. Against its top stage (515 MVA) it is at 73 %.

Say this out loud before anyone reads "105 %" as a violation.

### FINDING 2 — The auxiliary transformer is overloaded in the looped cases, and it is not because of load

| Case | UAT loading | GAT flow |
|---|---|---|
| LF1 | 90.6 % of 19 MVA | 0.02 MVA (magnetising only) |
| **LF2** | **109.5 %** | 7.71 MVA |
| LF3 | 90.7 % | 0.02 MVA |
| **LF4** | **101.4 %** | 6.50 MVA |

The plant's own consumption is **14.00 MW in every case** — it does not change. So
what overloads the transformer?

In LF2, the UAT brings **19.91 MW down** from the generator while the GAT sends
**5.87 MW back up** to the 230 kV system. The arithmetic closes:
19.91 − 14.00 − 5.89 ≈ 0.

Both transformers feed the same 6.6 kV bus from different sources, creating a **loop**
— and power circulates around that loop uselessly, heating both transformers while
doing no work. **The overload is circulating power, not demand.**

**This is why real plants interlock these two supplies** so both cannot be closed
onto the same bus at once. The correct engineering reading is that LF2 and LF4 are a
*diagnostic of a configuration the plant almost certainly prohibits*, not a design
defect. But we cannot state that as fact, because **the document that would confirm
the interlock is not in the source set** — which is exactly why both cases were run.

This is the most valuable finding in the study, and it exists *only* because the
uncertainty was carried through instead of guessed away.

### FINDING 3 — The switchyard is lightly loaded

The 230 kV busbars are rated **3150 A**. The measured current at full output is
**943 A** — **30 %**. No thermal concern anywhere in the switchyard.

### FINDING 4 — A contradiction that moves a reported voltage by 4.55 %

The auxiliary transformers' low-voltage windings are specified at **6.9 kV**. The
plant bus they feed is called the **6.6 kV** bus. That is a genuine inconsistency in
the source documents (logged as conflict **C13**).

It is not cosmetic. Rebasing an impedance from 6.9 to 6.6 kV inflates it by
**9.30 %**, and the choice moves the reported MV bus voltage by **4.55 %** —
the difference between:

- **1.0014 pu** (on a 6600 V base) — comfortably normal, and
- **0.9579 pu** (on a 6900 V base) — noticeably low.

**Every MV voltage in this study is therefore reported on both bases.** I did not
choose for you, because the choice changes the conclusion.

---

## 7. WHAT IS NOT DONE

### Deliverables outstanding

| # | Item | Effort |
|---|---|---|
| 1 | `Ashuganj_Master_Data.xlsx` — the multi-sheet Excel workbook. The 126-row `.csv` is complete; the formatted workbook is not built | ~1 h |
| 2 | `docs/model/block_architecture.md` — the only mandated document not yet written | ~1 h |
| 3 | Independent cross-check: solve the network with a hand-coded Newton-Raphson routine outside the Simulink toolbox and confirm identical voltages | ~2 h |
| 4 | Comparison of "GAT breaker open" against "GAT physically absent", to prove a numerical artefact changes nothing real | ~1 h |

### A deviation from your requested layout — your call

You asked for the model split into five subsystem files (`Generator_System`,
`GSUT_System`, `230kV_GIS`, `Auxiliary_System`, `External_Grid`). I built **one flat
diagram of 12 blocks** instead, because the network reduces to five electrical nodes
and subsystems would have added navigation depth without adding clarity.

That was my judgment applied to your specification. `simulink/subsystems/` is empty
as a result. It is reversible — say so and I will split it.

### Later phases, deliberately not started

Short-circuit calculation, three-phase / line-ground / line-line / double-line-ground
fault analysis, relay modelling, protection coordination, and transient stability.
These are the project's eventual goal but were explicitly held back until the load
flow is signed off.

---

## 8. THE HONEST LIMITS OF WHAT YOU HAVE

Read this section before presenting. Every item here is something an examiner could
reasonably ask about.

**Two assumptions are awaiting your decision.** They are in use because the model
could not be built without them, and both are flagged unapproved in their own files:

| | Assumption | Consequence if wrong |
|---|---|---|
| **A4** | Transformer magnetising branch treated as open (`Lm = 1e6 pu`) | Reactive absorption understated by up to **3.44 MVAr**, which is 11.04 % of the generator's reactive output |
| **A5** | Generator voltage setpoint **1.00 pu** at the 22 kV bus | **This is the voltage datum for the entire study.** Every per-unit voltage in every table is relative to this one chosen number |

A5 is not one parameter among 126. It is the reference everything else is measured
against, and it was chosen because **no measured bus voltage exists anywhere in the
source material.**

**Three approved assumptions carry consequences you should be able to state:**

- **A1** — grid resistance taken as zero (your answer Q1a). Understates generator
  reactive output by up to 17 %.
- **A2** — auxiliary load split 9050 : 2500 : 2500 kW across three 6.6 kV nodes
  (your answer Q6B). No effect on any solved voltage, because those three nodes are
  electrically one node.
- **A3** — 230 kV bus coupler closed (your answer Q9a). **This is what creates the
  loop that produces Finding 2.**

**Fifteen parameters are recorded as MISSING**, nineteen of them blocking in the
strict sense. **Eighteen contradictions** between documents are logged, unresolved by
design — both values preserved, both sources named.

**The largest unchecked surface in the whole project:** the 62 rows marked
`VERIFIED_ENGINEERING_DOCUMENT` are only as reliable as my reading of the PDFs.
Nobody has independently verified my transcription. If you check one thing, check
that.

---

## 9. WHAT YOU NEED TO COLLECT

This is the single highest-value action available, and it is set out in full in
**[DATA_TO_COLLECT.md](DATA_TO_COLLECT.md)** — a document written to be sent
directly to APSCL, PGCB or the EPC contractor.

The short version. **Eight documents are cited by the plant's own drawings but are
not in the source set.** If you obtain even three of them, roughly ten currently
"decided" parameters become verified facts:

| Priority | Document | Would resolve |
|---|---|---|
| 1 | `INEL-112070-00-ELC-DE-0026` — 230 kV GIS control & protection one-line | Outgoing line identity, busbar selection, coupler normal state |
| 2 | `INEL-112070-00-ELC-DS-0001` — Electrical Design Criteria | Grid assumptions, tap philosophy, study bases |
| 3 | `S001-112070-00-ELC-CL-0002` full 39 pages (we have only pp. 6–7) | Generator reactive capability curve |
| 4 | `INEL-112070-00-ELC-DE-0009` — MV one-line | The 6.6 kV load allocation |

Plus **six operational questions only plant staff can answer** — actual dispatch,
actual auxiliary load, transformer tap positions in service, GAT normal state, bus
coupler normal state, GSUT cooling stage in service — and **one grid figure from
PGCB**: the real short-circuit level at the 230 kV connection point.

That last one matters more than it sounds. The only short-circuit figure in the
source set is 19,919 MVA / 50 kA — and **that number is exactly √3 × 230 × 50**,
i.e. it is the *switchgear's withstand rating*, not a measurement of the grid. Using
it makes the grid look infinitely strong. It is currently carried as an explicit
estimate (your answer Q1a).

---

## 10. HOW TO CHECK MY WORK

Start where an error would be most expensive, not where the work looks most
impressive. **Do not start with the results** — they are arithmetic, and correct
arithmetic on wrong inputs is worthless.

| Order | Read this | Looking for |
|---|---|---|
| 1 | `docs/validation/assumptions.md` | The five assumptions. Two need your signature |
| 2 | `docs/validation/conflicting_parameters.md` | 18 conflicts. Go straight to **C13** — it moves the MV voltage by 4.55 % |
| 3 | `docs/validation/missing_parameters.md` | Is any "missing" item actually obtainable from a document I never saw? |
| 4 | `data/master/Ashuganj_Master_Data.csv` | Spot-check four rows only: GSUT impedance 16 % @ 515 MVA · UAT rating 19/25 MVA · generator 458 MVA @ 0.85 pf · the 9050:2500:2500 split. These four drive every headline number |
| 5 | Run it yourself | See section 11 |
| 6 | `results/load_flow/system_summary.csv` | Four rows — the entire study on one screen |
| 7 | `results/reports/load_flow_report.md` | The full narrative with every number sourced |

---

## 11. HOW TO RUN AND DEMONSTRATE IT

Full click-by-click instructions, including a ten-minute presentation script and the
traps to mention *before* an examiner spots them, are in
**[HOW_TO_RUN.md](HOW_TO_RUN.md)**.

The whole study reproduces from four commands:

```matlab
cd 'F:\LOCAL DISK E\idm\compressed\ Level 3 Term 1\306 Power Project\matlab'
ashuganj_setup
run_all_tests
run_load_flow_study
make_load_flow_plots
```

That runs 434 checks, solves all four cases, and regenerates every table and plot
from source. Nothing is hand-edited.

**One trap worth knowing now, because it looks damning:** the powergui dialog
displays a field reading `60`. That is the FFT analysis tool's default frequency —
its own label reads `Fundamental (PSBFFTSCOPE)`. The system frequency is the separate
`Frequency (Hz): 50`. Mention it before anyone spots it, because 60 Hz was defect D2
of the prior study and an examiner who notices a stray 60 will assume you repeated
it. You did not.

---

## 12. THE ONE-PARAGRAPH VERSION

A Simulink/Simscape model of the Ashuganj South 450 MW single-shaft combined-cycle
unit has been built entirely from plant documents at 50 Hz, with every one of 126
parameters carrying its source and status and not one value invented. A balanced
load flow was solved across four cases spanning the two genuine uncertainties
(dispatch level, and whether the station auxiliary transformer is in service). All
434 validation checks pass and power balance closes to nine decimal places. Voltages
are acceptable everywhere; losses are 0.21 % of generation. The study found that the
step-up transformer requires forced cooling at rated output (105.87 % of its natural
stage), and — more significantly — that closing both auxiliary supplies onto the
6.6 kV bus drives circulating power that overloads the unit auxiliary transformer to
109.5 % of rating without any increase in plant load, a condition real plants
interlock against but which no available document confirms for this plant. Fifteen
parameters are recorded as missing, eighteen document contradictions are preserved
unresolved with both sources named, and two assumptions await sign-off — one of which
is the voltage datum for the entire study. Eight documents cited by the plant's own
drawings are absent from the source set; obtaining them is the highest-value action
available.

---

*Related: [HOW_TO_RUN.md](HOW_TO_RUN.md) · [DATA_TO_COLLECT.md](DATA_TO_COLLECT.md) ·
[load_flow_report.md](../results/reports/load_flow_report.md) ·
[assumptions.md](validation/assumptions.md) ·
[missing_parameters.md](validation/missing_parameters.md) ·
[conflicting_parameters.md](validation/conflicting_parameters.md)*
