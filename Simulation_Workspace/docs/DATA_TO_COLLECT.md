# DATA TO COLLECT — Prioritised Request List

**Project:** Protection Coordination and Fault Analysis of the Ashuganj 450 MW
Combined Cycle Power Plant (South) · BUET EEE 306, Jan 2026, Group 03, Sec C-1
**Purpose:** this document lists exactly what is missing from the source material,
who can supply it, and what each item would change. **Section 6 is a ready-to-send
request letter** — copy it, fill in the addressee, send it.

**Plant identifiers to quote in any request:**

| | |
|---|---|
| Plant | Ashuganj 450 MW Combined Cycle Power Plant, **South** unit |
| Owner | APSCL (Ashuganj Power Station Company Ltd) |
| EPC contractor | TSK / Inelectra International |
| Engineering | GHESA / Empresarios Agrupados |
| Equipment | Siemens |
| **Project number** | **112070** |
| Equipment tag prefix | `10B…` |

> **Do not accept North-plant documents.** The North unit is project **7485** and has
> a **400 kV** switchyard. If a document shows 400 kV or quotes project 7485, it is
> the wrong plant for this study. South is **230 kV**.

---

## HOW TO USE THIS DOCUMENT

Items are graded by what they unlock, not by how hard they are to get:

| Grade | Meaning |
|---|---|
| **🔴 CRITICAL** | Currently an assumption or an estimate. Getting it converts a *decision* into a *fact* |
| **🟠 HIGH** | Currently worked around by running multiple cases. Getting it collapses four cases to one |
| **🟡 USEFUL** | Improves accuracy or completeness; the study stands without it |
| **⚪ LATER** | Not needed for load flow. Needed for the protection phase that follows |

Everything requested here is **already referenced by the plant's own drawings** or is
a number **only plant staff can know**. Nothing on this list is speculative.

---

## 1. DOCUMENTS THE DRAWINGS CITE BUT WHICH ARE NOT IN THE SOURCE SET

These eight documents are **named in the material you already have** — a drawing says
"see document X" and document X is absent. They exist; they were simply not included
in what was handed over. This is the highest-value section of this list.

### 🔴 1.1 — `INEL-112070-00-ELC-DS-0001` · Electrical Design Criteria

**Ask for:** the complete document, all revisions.

**Why it matters most:** a Design Criteria document is where the project records the
*basis* of every electrical calculation — the assumed grid strength, the study base
MVA, the voltage limits, the transformer tap philosophy, the load factors. Four
parameters currently carried as assumptions or estimates are almost certainly stated
in it explicitly.

**Resolves:** grid short-circuit basis (M-B2) · tap positions in service (M-B15) ·
system base MVA (M-B18) · GSUT cooling stage in service (M-B19)

---

### 🔴 1.2 — `INEL-112070-00-ELC-DE-0026` · 230 kV GIS Control & Protection One-Line

**Ask for:** the drawing at the latest revision, all sheets.

**Why it matters:** this is the drawing that shows how the switchyard is *operated* —
which busbar each bay normally selects, whether the bus coupler is normally open or
closed, and where the outgoing 230 kV circuit actually goes. Right now the bus coupler
state is an **assumption you approved (A3)**, and that single assumption is what
creates the loop producing the study's main finding.

**Resolves:** 230 kV line impedance basis (M-B6) · line identity and endpoints
(M-B7) · **bus coupler normal state (M-B16)** · busbar selection per bay (M-B17)

---

### 🔴 1.3 — `S001-112070-00-ELC-CL-0002` · Generator Protection Setting Report — **complete, 39 pages**

**Ask for:** the full 39-page report, and specifically **Attachment 1, page 42**.

**Why it matters:** only **pages 6–7** are in the source set (as
`Generator Data_South.pdf`). Attachment 1 carries the generator's **reactive
capability curve** — the chart defining how much MVAr the machine can produce or
absorb at each MW output. Without it, the generator's reactive limits are recorded as
`NOT_APPLICABLE` (your answer Q3a, taken deliberately rather than importing the prior
study's corrupted diesel-template limits).

**Resolves:** generator Qmax / Qmin (M-B5)

**Bonus:** the same report contains the relay settings you will need for the
protection-coordination phase. Getting this one document serves both phases.

---

### 🟠 1.4 — `INEL-112070-00-ELC-DE-0009` · Medium-Voltage (6.6 kV) One-Line

**Ask for:** the drawing at the latest revision.

**Why it matters:** the plant's 14 MW auxiliary load is currently split
**9050 : 2500 : 2500 kW** across three 6.6 kV nodes as an approved assumption (A2,
your answer Q6B). This drawing gives the real feeder-by-feeder allocation.

**Resolves:** per-bus load allocation (M-B12)

**Honest note:** this changes almost nothing in the *present* study, because the three
nodes merge into one electrically (the 6.6 kV feeder impedances are also missing).
It becomes important the moment feeder impedances arrive or a fault study begins.

---

### 🟡 1.5 — `INEL-112070-00-ELC-DE-0010` · Low-Voltage (400 V) One-Line

**Ask for:** the drawing at the latest revision, plus the **400 V load list**.

**Why it matters:** resolves the 400 V distribution split and — importantly — settles
a live contradiction. Documents at **Rev 00 and Rev 03 disagree** about the LV
transformers `10BFT10/20/30/40` and `00BFT10` (logged as conflict **C16**).

**Also ask:** are the emergency diesel generators `10BUK01` / `10BUK02` normally in
service or out? Rev 03 Note 4 says out of service; no other document confirms it.

---

### 🟡 1.6 — `BD1015-B-&EFA010-700506` · Turbine Package Performance Data

**Ask for:** the gas-turbine and steam-turbine performance curves versus ambient
temperature.

**Why it matters:** this is the document that would settle **how much power the unit
actually produces at Ashuganj's ambient conditions**. Nameplate says 389.30 MW; a
derated figure says 342.01 MW. Both are currently carried as separate cases because
no document decides between them.

**Resolves:** generator dispatch basis (M-B3) — collapses four cases to two

---

### ⚪ 1.7 — `INEL-112070-00-ELC-DE-0011` and `-DE-0012` · UPS and 110 V DC One-Lines

Not needed for load flow. Needed for the protection phase, because relay and trip-coil
supplies come from the DC system.

---

### ⚪ 1.8 — `INEL-112070-00-ELC-DE-0030` · Symbology and Legend

Not needed numerically. Useful for confirming that symbols on the SLDs have been read
correctly — a cheap independent check on document interpretation.

---

## 2. QUESTIONS ONLY PLANT OPERATIONS STAFF CAN ANSWER

No document can answer these. They describe how the plant is *actually run*, which is
knowledge held by the control-room and electrical-maintenance staff. **Ask for these
in writing, with a date and a name attached**, so the answers can be logged as
verified plant data rather than hearsay.

| | Question | Grade | Currently |
|---|---|---|---|
| **Q1** | What is the unit's **actual measured gross output** on a normal full-load day? Please state MW, MVAr and the ambient temperature at the time. | 🟠 HIGH | Two cases: 389.30 / 342.01 MW |
| **Q2** | What **voltage is actually held at the 22 kV generator terminals**? A single typical reading in kV is enough. | 🔴 CRITICAL | Assumed 1.00 pu (**A5, unapproved**) |
| **Q3** | Is the **GAT (10BBT20) normally in service or normally out**? If in service, is it ever paralleled with the UAT onto the 6.6 kV bus, or are the two **interlocked**? | 🔴 CRITICAL | Two cases; the loop is what causes the study's main finding |
| **Q4** | Is the **230 kV GIS bus coupler normally closed or normally open**? | 🔴 CRITICAL | Assumed closed (**A3**, your Q9a) |
| **Q5** | What **tap positions** are the GSUT, UAT and GAT actually running on today? | 🟠 HIGH | Documented principal taps assumed (your Q8a) |
| **Q6** | At full load, which **GSUT cooling stage** is running — ONAN, ODAN or ODAF (i.e. are the fans and oil pumps on)? | 🟠 HIGH | Not stated; drives whether 105.87 % is normal |
| **Q7** | What is the **actual measured auxiliary load** of the unit in MW and MVAr? | 🟡 USEFUL | 14.00 MW from the load list, not a measurement |
| **Q8** | Is the **6.6 kV bus** actually 6.6 kV or 6.9 kV? The transformer windings are specified 6.9 kV and the bus is called 6.6 kV. | 🟠 HIGH | Conflict **C13** — worth **4.55 %** on reported MV voltage |
| **Q9** | Are the **emergency diesel generators (10BUK01/02) normally in service or out**? | 🟡 USEFUL | Rev 03 Note 4 says out; unconfirmed |

**Q2, Q3, Q4 and Q8 are the four that most change the study.** If you can only get
four answers, get those.

---

## 3. ONE REQUEST TO PGCB

**Addressee:** Power Grid Company of Bangladesh — System Planning / System Operation

**Request:** the **three-phase short-circuit level and X/R ratio at the Ashuganj 230 kV
busbar**, i.e. at the point where this plant connects to the national grid. Ideally
also the single-phase-to-ground level.

**Format wanted:** either short-circuit MVA and X/R, or the Thevenin equivalent
impedance R + jX in ohms or per unit on a stated base.

### 🔴 Why this one matters more than it looks

The only short-circuit figure anywhere in the source set is **19,919 MVA / 50 kA**.
Check the arithmetic:

```
√3 × 230 kV × 50 kA = 19,919 MVA
```

That is not a measurement of grid strength. **It is the switchgear's own fault-withstand
rating restated as an MVA number** — the maximum the equipment can survive, which is by
design *above* anything the grid will ever deliver. Using it as the grid's strength
makes the grid look effectively infinite, which is optimistic in the wrong direction.

It is currently carried as an **explicit estimate** (your answer Q1a), with grid
resistance assumed zero (**A1**) — an assumption that understates the generator's
reactive output by up to **17 %**.

**Resolves:** grid impedance R and X/R (M-B1) · actual short-circuit level (M-B2)

**This item is mandatory before any fault study.** A short-circuit calculation against
a grid strength that is really a switchgear rating is not a fault study — it is a
description of the switchgear catalogue. Whatever else is or is not obtained, **get
this one before the protection phase starts.**

---

## 4. TWO DECISIONS THAT REQUIRE YOUR SIGNATURE, NOT MORE DATA

These cannot be collected. They are engineering judgments that must be made and owned
before the study can be called final. Both are currently marked **disclosed but not
approved** in `docs/validation/assumptions.md`.

### 🔴 A5 — Generator voltage setpoint = 1.00 pu at the 22 kV bus

**What it means:** the generator is modelled as holding its terminal voltage at exactly
nominal.

**Why it needs your signature:** this is not one parameter among 126. **It is the
voltage datum for the entire study.** Every per-unit voltage in every table in every
result file is measured relative to this one chosen number. It was chosen because *no
measured bus voltage exists anywhere in the source material.*

**If plant Q2 above is answered, this assumption disappears** and becomes verified
data. That is the preferred outcome. If Q2 cannot be answered, approve 1.00 pu
explicitly and it will be reported as an approved assumption.

### 🟠 A4 — Transformer magnetising inductance `Lm = 1e6 pu`

**What it means:** the transformers' magnetising branches are treated as effectively
open-circuit on the reactive side. Iron **loss** is modelled correctly from the
documented no-load losses; the magnetising **current** is not.

**Consequence if wrong:** reactive absorption understated by up to **3.44 MVAr**,
which is **11.04 %** of the generator's reactive output in LF1.

**How to remove it properly:** the transformer test reports include a **no-load /
excitation current** measurement, usually as a percentage of rated current. If you can
obtain the **factory test certificates** for GSUT `10BAT10`, UAT `10BBT10` and GAT
`10BBT20`, this assumption is replaced by measured data. Worth adding to the section-1
request.

**Also worth requesting with the test certificates:** the **as-tested stamped
impedances**. The rating plates in the source set have the impedance field **blank** —
correctly recorded as `NOT_APPLICABLE`, because that field is stamped only after
factory testing. The tested values may differ slightly from the design values now in
use.

---

## 5. WHAT HAPPENS IF YOU GET NONE OF THIS

The study **still stands, and stands honestly.** That was the design intent: every gap
is recorded as a gap rather than filled with an invented number, and the two genuine
uncertainties are carried through as four solved cases instead of one guessed case.

What you lose without the data:

- Results must be presented as **four cases**, not one operating point
- Every MV voltage must be quoted on **two bases** (6.6 kV and 6.9 kV)
- The grid remains an **explicit estimate**, so the eventual fault currents will be
  upper bounds rather than expected values
- Two assumptions must be **declared in the presentation** as unapproved
- The transformer overload finding must be stated as **conditional** on a switching
  configuration that no available document confirms

That is a defensible piece of engineering work with clearly stated limits — which is
worth considerably more than a single confident-looking answer built on guesses. But
every item collected moves a line from "assumed" to "verified", and section 1 items
1.1, 1.2 and 1.3 move roughly **ten lines** between them.

---

## 6. READY-TO-SEND REQUEST LETTER

Copy from here. Fill in the addressee, your names, and the date.

---

> **Subject:** Request for electrical design documentation — Ashuganj 450 MW CCPP
> (South), Project 112070 — BUET EEE 306 academic study
>
> Dear Sir/Madam,
>
> We are final-year Electrical and Electronic Engineering students at BUET
> (Course EEE 306, Group 03, Section C-1) carrying out an academic power-system
> study of the **Ashuganj 450 MW Combined Cycle Power Plant (South unit)**. We have
> built a validated load-flow model of the plant from the documentation available to
> us and are now extending the work to fault analysis and protection coordination.
>
> Our model is complete and verified, but several parameters are recorded as missing
> because the documents that contain them are **referenced by the drawings we hold
> but were not included in the set provided to us**. We would be grateful for any of
> the following, for **project 112070 (South unit only)**:
>
> **A. Documents cited by the drawings in our possession**
>
> 1. `INEL-112070-00-ELC-DS-0001` — Electrical Design Criteria
> 2. `INEL-112070-00-ELC-DE-0026` — 230 kV GIS control and protection one-line diagram
> 3. `S001-112070-00-ELC-CL-0002` — Generator Protection Setting Report, **complete
>    39 pages including Attachment 1** (we currently hold only pages 6–7)
> 4. `INEL-112070-00-ELC-DE-0009` — 6.6 kV medium-voltage one-line diagram
> 5. `INEL-112070-00-ELC-DE-0010` — 400 V low-voltage one-line diagram and load list
> 6. `BD1015-B-&EFA010-700506` — turbine package performance data versus ambient
>    temperature
> 7. `INEL-112070-00-ELC-DE-0011` and `-DE-0012` — UPS and 110 V DC one-line diagrams
>
> **B. Factory test certificates** for transformers `10BAT10` (GSUT), `10BBT10` (UAT)
> and `10BBT20` (GAT) — specifically the **as-tested impedance** and the **no-load
> excitation current**. The rating plates available to us have the impedance field
> blank, as it is stamped only after testing.
>
> **C. Nine operational questions** that no document can answer, and for which a
> typical value from operating staff would be sufficient:
>
> 1. Actual measured gross output at full load (MW, MVAr) and the ambient temperature
> 2. Voltage normally held at the 22 kV generator terminals
> 3. Whether the GAT (`10BBT20`) is normally in service, and whether it is
>    **interlocked against** the UAT on the 6.6 kV bus
> 4. Whether the 230 kV GIS bus coupler is normally closed or open
> 5. Tap positions currently in service on the GSUT, UAT and GAT
> 6. Which GSUT cooling stage (ONAN / ODAN / ODAF) runs at full load
> 7. Actual measured auxiliary load (MW, MVAr)
> 8. Whether the plant medium-voltage bus is 6.6 kV or 6.9 kV — the transformer
>    windings are specified at 6.9 kV while the bus is labelled 6.6 kV
> 9. Whether the emergency diesel generators (`10BUK01`, `10BUK02`) are normally in
>    service or out
>
> We wish to emphasise that this is a **purely academic study**. No parameter has been
> invented or substituted: where data is absent, our model records it as absent and
> presents multiple cases rather than a single assumed answer. Any material you are
> able to provide will be used solely for this coursework and cited to APSCL.
>
> We are glad to share our completed model and findings with your engineering staff.
>
> Yours faithfully,
>
> [names, roll numbers, date, contact]
> Department of Electrical and Electronic Engineering, BUET

---

## 7. AND THE SAME LETTER, SHORTENED, FOR PGCB

> **Subject:** Request for 230 kV short-circuit data at Ashuganj — BUET EEE 306
> academic study
>
> Dear Sir/Madam,
>
> We are BUET EEE students (Course EEE 306) carrying out an academic fault-analysis
> and protection-coordination study of the Ashuganj 450 MW Combined Cycle Power Plant
> (South unit), which connects to the grid at **230 kV**.
>
> We request the **grid equivalent at the Ashuganj 230 kV busbar**:
>
> - three-phase short-circuit level (MVA or kA) and **X/R ratio**, or equivalently
>   the Thevenin impedance R + jX on a stated base
> - if available, the single-phase-to-ground short-circuit level
>
> The only figure available to us is 19,919 MVA / 50 kA, which we have determined is
> the switchgear's fault-**withstand rating** (√3 × 230 × 50) rather than a measured
> system strength, and which we are therefore carrying only as a labelled estimate. An
> actual system figure would let us report expected fault currents rather than upper
> bounds.
>
> This is an academic study and the data will be cited to PGCB.
>
> Yours faithfully,
>
> [names, roll numbers, date, contact]

---

## 8. ONE-PAGE CHECKLIST — TAKE THIS TO THE PLANT

```
DOCUMENTS                                                       got it?
 [ ] INEL-112070-00-ELC-DS-0001   Electrical Design Criteria       🔴
 [ ] INEL-112070-00-ELC-DE-0026   230 kV GIS protection one-line   🔴
 [ ] S001-112070-00-ELC-CL-0002   Gen protection report, ALL 39 pp 🔴
 [ ] INEL-112070-00-ELC-DE-0009   6.6 kV one-line                  🟠
 [ ] INEL-112070-00-ELC-DE-0010   400 V one-line + load list       🟡
 [ ] BD1015-B-&EFA010-700506      Turbine performance vs ambient   🟡
 [ ] INEL-112070-00-ELC-DE-0011/12  UPS + 110 V DC one-lines       ⚪
 [ ] Factory test certs: 10BAT10, 10BBT10, 10BBT20                 🟠

PLANT STAFF — nine questions
 [ ] 1  Actual MW / MVAr at full load + ambient temp               🟠
 [ ] 2  Voltage held at the 22 kV generator terminals              🔴
 [ ] 3  GAT normally in or out? Interlocked with UAT?              🔴
 [ ] 4  230 kV bus coupler normally closed or open?                🔴
 [ ] 5  Tap positions in service: GSUT / UAT / GAT                 🟠
 [ ] 6  GSUT cooling stage at full load: ONAN / ODAN / ODAF        🟠
 [ ] 7  Actual measured auxiliary load MW / MVAr                   🟡
 [ ] 8  Is the MV bus 6.6 kV or 6.9 kV?                            🟠
 [ ] 9  Emergency diesels 10BUK01/02 normally in or out?           🟡

PGCB — one request
 [ ] 230 kV short-circuit MVA + X/R at Ashuganj                    🔴

YOUR OWN SIGN-OFF — no data needed
 [ ] A5  Approve generator setpoint 1.00 pu  (or supersede w/ Q2)  🔴
 [ ] A4  Approve Lm = 1e6 pu  (or supersede w/ test certs)         🟠
 [ ] Decide the 6.6 / 6.9 kV reporting base (or keep reporting both)
 [ ] Decide whether to split the model into 5 subsystem files
```

---

*Sources for every "currently" claim in this document:
[missing_parameters.md](validation/missing_parameters.md) (items M-B1…M-B19 and
Part C) · [assumptions.md](validation/assumptions.md) (A1–A5) ·
[conflicting_parameters.md](validation/conflicting_parameters.md) (C1–C18).
Background: [PROJECT_BRIEFING.md](PROJECT_BRIEFING.md).*
