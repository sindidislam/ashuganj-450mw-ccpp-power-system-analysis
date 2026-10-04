# REV3_PROGRESS.md — Ashuganj South 450 MW CCPP (APSCL) · EEE 306 Rev 3

**Status:** PART A (audit) **CLOSED — A1–A6 complete, A7 terminated by user decision** · PART B (source
hierarchy) complete · PART C (registry) **next**
**Last updated:** 2026-09-13 — **PART A IS CLOSED.** Two events closed it. (1) **A5 verified by execution**:
both transformer rating plates read in full (§3.9, C-46 … C-51), every arithmetic claim in §3.9e re-derived by
`tmp/rev3_plate_numeric_checks.m` — **26 PASS · 1 documented source-document deviation · 0 FAIL** (§6.2, log at
`docs/validation/rev3/A5_plate_numeric_checks.log`); the run corrected three hand-arithmetic slips in §3.9e and
withdrew one row whose printed source was not in the record. (2) **A7 terminated on user instruction —
*"forget all psaf files, they are dead"*** (§3.10). The PSAF artefacts are struck from scope as a data source.
The audit findings made before termination are **retained, not deleted** (standing prohibition), because one of
them bears on provenance of live registry values and must be settled by B1.
**Supersedes for current work:** [`PROGRESS.md`](PROGRESS.md) (Rev1/Rev2 record — retained, not deleted).
`PROGRESS.md` states *"Do NOT reread PDFs"* and *"PROJECT COMPLETE"*. **Both are void for Rev3.** Rev3 exists
because the primary PDFs were *not* fully read in Rev1/Rev2, and re-reading them has already overturned
several parameters that Rev2 carried as settled.

> **Reading rule for a fresh session:** read THIS file first. Treat
> `Ashuganj_South_Final_Master_Data_and_Assumptions (1).md` as a **tier-4 secondary compilation**, *not* as
> source truth — §4 below documents where it silently diverges from the primary documents it claims to summarise.

---

## 0. Session constraints (factual, verified)

| Item | State | Evidence |
|---|---|---|
| MATLAB | **R2024a available and executing** `-batch` headless | all checks in §6 were run, not asserted |
| Simulink / SPS | Simulink 1, Power_System_Blocks 1, Simscape 1, Control_Toolbox 1; **SPS 24.1** | `ver` |
| Python | **NOT available** — `python` is the Microsoft Store stub, exit 49 | all arithmetic moved to MATLAB |
| `pdftotext` | available at `/mingw64/bin/pdftotext` | used with `-layout` for all 13 PDFs |
| **PDF rasteriser (external)** | **NONE** — `pdftoppm`, `pdftocairo`, `pdfimages`, ImageMagick, Ghostscript, `qpdf`, `mutool` all absent | so scanned/image rows must be cracked from the text layer (§3.2a, §3.6a) or read via the crops already in `tmp/pdfs/` |
| **Flate decompression** | **AVAILABLE — via MATLAB's JVM** (`java.util.zip.InflaterInputStream`) | `tmp/pdf_inflate_obj.m`; inflated the two 400 kB rating-plate content streams to 2.39 MB / 1.95 MB (§3.9a) |
| **Vector-PDF rendering** | **AVAILABLE — MATLAB's graphics engine *is* a rasteriser** for path-based pages | `tmp/pdf_parse_vector.m` + `tmp/pdf_draw_vector.m`: parse content-stream paths → `patch`/`line` → `exportgraphics`. **This is what closed A5** (§3.9). It renders *vector* art only — it is **not** a substitute for a raster decoder on scanned pages |
| `pdfinfo` | **NOT available** | page counts obtained by probing `pdftotext -f N -l N` until the output is empty |
| **RAR extractor** | **NONE** — `unrar`, `7z`, `7za`, `p7zip`, `bsdtar` all absent; GNU tar 1.35 cannot read RAR | **Did not matter (§3.10).** RAR5 stores its **filename table uncompressed**, so `grep -a` enumerated `psaf export (1).rar` without decoding a byte of payload: 72 entries, all present on disk, none unseen. Payload extraction is still impossible, but was not needed |
| `strings` | **NOT installed, and fails SILENTLY** — returns 0 hits rather than an error | use `grep -a` on binaries. A false negative here cost the August audit a full pass over the DBFs |
| **Subagents / Workflow** | **BLOCKED — API quota exhausted** | `403 pre-consume quota failed, user quota: $0.307896, need quota: $0.346260`; `"error":"authentication_failed"` |

**Consequence of the quota block:** the 13-agent PART A audit workflow (`rev3-part-a-audit-wf_e466954f-0b0.js`,
resumable via `resumeFromRunId: 'wf_e466954f-0b0'`) launched and **all 13 agents failed on authentication** —
`journal.jsonl` is 32 lines of `started`/`failed` pairs with every result null. This is a billing failure, **not a
script defect**. All PART A findings below were therefore produced by direct inline extraction, and every
digitised number was cross-checked arithmetically (§6) — a stronger evidence standard than the agents would
have applied. If quota is restored the workflow can be resumed for redundancy, but it is no longer on the
critical path.

**Two rows in this table were wrong for three weeks, and the cost was a closed audit item reopened.** "No
rasteriser" was recorded as "image-only pages are unreadable", and on that basis `UAT Nameplate_South.pdf`
pp. 3–4 sat in §7 as a permanent limitation. The pages are not images at all (§3.9a), and the two capabilities
needed to read them were already installed inside MATLAB. **A tool inventory is a statement about *external
binaries*; it is not a statement about what the machine can do.** Before declaring any source unreachable,
establish what the file actually *is* — here, one `/Resources` dictionary with no `/XObject` in it would have
falsified the whole chain on day one.

---

## 1. Source inventory and tiering (PART B)

Priority hierarchy in force: **(1)** as-built OEM/EPC drawings & datasheets → **(2)** official PGCB/APSCL
documents → **(3)** engineer-derived project datasets → **(4)** published secondary sources → **(5)** engineering
assumptions.

### 1.1 Tier 1 — primary OEM / as-built

| Document | Identity established | Settles |
|---|---|---|
| `Generator Data_South.pdf` | **Siemens Generator Protection Setting Report**, `BD1015 / Ashuganj South`, panel `+10CHA`, Dwg `BD1015-10CHA-&EFQ030-760522`, UNID 439 093 338, © Siemens AG 2014, 39 pp | generator ratings & reactances, **NER**, generator CT/VT, GSUT uk, grid estimate |
| `Generator Name Plate_South.pdf` | Siemens **SGen5-2000H**, stator s/n 12783, built 2013 | ratings, winding **YY**, thermal/ambient envelope |
| `GSUT Data Sheet_South.pdf` | `S009-112070-00-ELC-HD-0001 Rev 00`, Siemens Transformer Guangzhou, 24.02.14 | GSUT ratings, taps, losses, neutral, excitation |
| `UAT  Data Sheet_South.pdf` | `STWH-579UAT-0007 / STWH-580GAT-0007 Rev 00` 27.03.14, client `S009-112070-00-ELC-HD-1001`, CTI, 24 pp | **both** UAT `10BBT10` (p.4) and GAT `10BBT20` (p.14) |
| `Single Line Diagram_South.pdf` | plant SLD | plant topology, tags, CT ratios, NER tag `10BAB11` |
| `GENERATION AND TRANSFORMERS SYSTEM.pdf` | `INEL-112070-00-ELC-DE-0026` — 230 kV GIS control/protection/measurement one-line | GIS bus/bay structure, relay models, CT/VT, protection functions |
| `GSUT Nameplate_South.pdf`, `UAT Nameplate_South.pdf`, `INEL-112070-00-ELC-DE-0001-REV3.pdf` | as-built | `UAT Nameplate_South.pdf` **now FULLY READ — both plates, §3.9**; it was never image-only (it is vector line art). The other two remain partly image-only — see §7 |

### 1.1b FIVE ZIP ENTRIES WERE MISSING FROM THE WORKING FOLDER — one is a tier-1 South document

> **Correction (this session).** An earlier version of this section said these five documents were *"never
> unpacked"* and implied `Data Sheet_230KV.pdf` was a **new** source. That is wrong on the second point:
> `docs/validation/verified_parameters.md` **§5 mined this exact file in August 2026**, citing its body-page
> header and KKS number `07485-20-ADA-EHP-SIE-001 Rev 1`. What is true is narrower and still worth recording:
> the file was **absent from the working PDF folder**, so it was not available to Rev2 and had to be
> re-extracted from the zip to be re-read. The August audit had it; Rev2 lost it.

`fwdtechnicaldatasldrequestforbueteeetermproject.zip` contains **15 PDFs**. The working folder holds only
**13**. Five zip entries are not in the folder; the folder's extras are `Line data.pdf` and the two renamed
duplicates. Extracted to `tmp/rev3_newsrc/` and scope-checked by body page (**not** by cover page — the
transmittal cover is shared across both Ashuganj units and says NORTH on all five):

| Document | Body-page scope | Verdict |
|---|---|---|
| **`Data Sheet_230KV.pdf`** (1043 lines of text) | **`ASHUGANJ 450 MW COMBINED CYCLE POWER PLANT (SOUTH)`** on every body page, TSK INELECTRA | **TIER 1, IN SCOPE — recovered source, mined in §3.6; Aug had already used it** |
| `Data Sheet_400 KV.pdf` | `…PROJECT (NORTH)` on every body page | **out of scope** (North unit) |
| `SLD _400 Kv.pdf` | NORTH; title block only, no data in text layer | out of scope |
| `SLD_230 KV.pdf` | NORTH; title block only, no data in text layer | out of scope |
| `name plate_Interbus Transformer.pdf` | NORTH, `400/230KV INTERBUS TRANSFORMERS` | out of scope; noted as context for the 230/400 kV grid interface, **numbers not used** |

**Cross-plant contamination risk, now controlled.** Ashuganj hosts both a North and a South 450 MW CCPP.
Scope must be decided on **body pages**, never on the shared transmittal cover. The August registry cited
`Data Sheet_230KV.pdf` for South GIS ratings — that citation is **correct**, and the values it quoted
(`2000 A` generator-transformer module, `50 kA` short-time withstand) reproduce exactly from the body text.
August's own extraction caveat (*"pdftotext scrambles label↔value adjacency … module-current assignments carry
Medium confidence"*) is now **discharged**: §3.6 validates the alignment by counting labels against values
**and** against the units column, 19 ↔ 19 exact, so those assignments are no longer Medium-confidence.

### 1.2 Deduplication finding — md5, confirmed
```
d19211aa…  "Ahsuganj South derived from engineers (1).pdf"  ≡  "Single Line Diagram_South.pdf"
59911f5e…  "Ahsuganj South derived from engineers (2).pdf"  ≡  "GENERATION AND TRANSFORMERS SYSTEM.pdf"
```

**The two "derived from engineers" PDFs are byte-identical renamed copies of the primary as-built drawings.**
There is therefore **no independent engineer-derived PDF tier** — only the `.xlsx` files are genuinely tier 3.
Any Rev2 claim resting on "engineer-derived PDF corroboration" is circular: it is the same drawing counted twice.

### 1.3 Tier 2 — owner (APSCL)

`Google Sheet Form_Filled Up By APSCL.pdf` — the owner-completed data request. Arguably tier 1 for
operational data. Read in full; its "Verified Plant Value" column is quoted throughout §3–§4.
**Two entries are decisive because they are explicit non-answers:** `X2 → [N/A]`, `X0 → [N/A]`, and all three
grid rows → `[Contact PGCB]`.

### 1.4 Tier 4 — secondary, and the competing data stores

`Ashuganj_South_Final_Master_Data_and_Assumptions (1).md` (1004 lines) — Rev2's claimed "SourceTruth".
**Demoted to tier 4.** It is a compilation, and §4.5 documents a defect it introduced.

**Competing "master" data stores found (PART C must leave exactly one authoritative):**

1. `Ashuganj_South_Final_Master_Data_and_Assumptions (1).md` — narrative compilation
2. `data/master/Ashuganj_Master_Data.csv` — 127 rows, **17 Aug** → **see §1.5, this one is the best of them**
3. `matlab/data/*.m` — `ashuganj_master_data.m`, `ashuganj_grid.m`, …
4. `rev2/data/ashuganj_rev2_registry.m` — Rev2's registry
5. `Ashuganj_South_PSAF_Tabular_Engineer_Source.xlsx` (+ a stale `~$…Master_Data_Request (1).xlsx` lock file)
6. `rev2/results/phase1_registry_snapshot.txt` — **hardcodes a duplicate data string**, i.e. a sixth de-facto source

### 1.5 THE AUGUST REGISTRY WAS RIGHT WHERE REV2 LATER REGRESSED

`data/master/Ashuganj_Master_Data.csv` (127 rows, 17 Aug) already carries a disciplined 9-field schema —
`Component, Parameter, Value, Unit, Source_document, Source_page_sheet, Status, Confidence, Notes` — and it is
**correct on four of the five parameters Rev2 got wrong three weeks later**:

| Row | August CSV | Rev2 (10 Sep) | Who was right |
|---|---|---|---|
| 78–81 | `NER 10BAB11` — ratio `22/√3 : 500 V`, `135 kVA/20 s`, `60 Ω`, `2.62 Ω`, note *"high resistance grounding"* | `G.Earthing = 'Solidly grounded'` — comment `% supersedes old NER` | **August** |
| 25 | `Negative/zero sequence x2/x0` → value blank, `MISSING` | `X2 = 0.2242`, `X0 = 0.1280` invented | **August** |
| 115–117 | aux `14 MW`, `pf 0.85`, `Q 8.676 MVAr` `DERIVED_FROM_VERIFIED_DATA` | `12 MW + j5 MVAr` | **August** |
| 92 | `BUS 1 / BUS 2 double busbar single breaker`, `Q1 to BUS 2 / Q2 to BUS 1` | single `BAY_GRID`, 4-bus model | **August** |
| 27 | inertia `H` → `MISSING` | `H_s = 5.287` | **August** |
| 10 | `PN 389.30 MW`, note *"RATED not measured dispatch"* | operating point `354 MW` | **August** |

**Rev2 was a regression, not an advance, on the data layer.** Its comment `% supersedes old NER` shows the
correct NER record was seen and deliberately overridden. This is the single most important governance finding
of the audit: the project already contained the right answer and discarded it.

**Consequence for PART C:** the Rev3 registry is built by **extending the August CSV's schema** (adding the
missing fields: `Assumption_flag`, `Supersedes_alternative`, and machine-checkable `Status` enums), *not* by
starting from Rev2's `.m` registry. Rev2's **code architecture** is reused; its **data** is not.

### 1.6 A PRIOR VALIDATION SUITE EXISTS AND WAS BYPASSED

`docs/validation/` holds **1567 lines** of August audit work that Rev2 did not reconcile against:

`conflicting_parameters.md` (210) · `verified_parameters.md` (240) · `solver_behaviour.md` (252) ·
`assumptions.md` (177) · `prior_psaf_model_defects.md` (168) · `load_flow_readiness.md` (148) ·
`source_inventory.md` (121) · `topology_validation.md` (110) · `missing_parameters.md` (87) ·
`SOURCE_REAUDIT_2026-08-31.md` (54)

The August CSV cites `conflicting_parameters.md` conflict **C11** for the 14 MW provenance question — i.e. a
prior conflict register with its own IDs already exists. **Rev3 must reconcile its §4 register against that
file rather than renumbering over it.** Not yet done → §7.

---

## 2. THE HEADLINE FINDINGS — two independent defects, each invalidating a published Rev2 result

**§2A** breaks Rev2's **fault** study (earth faults, by ~4 orders of magnitude).
**§2B** breaks Rev2's **load flow** (aux-bus voltage, by 9.3 %) — and, with it, Rev2's FINDING F1.
They are unrelated in cause, and each is independently confirmed.

### 2A — the earth-fault model is wrong by four orders of magnitude

This is the most consequential result of the audit and it is fully sourced.

**Siemens Generator Protection Setting Report §2.3 — Neutral Earthing Transformer (BAB), tag `10BAB11`:**
primary `22 kV/√3`, secondary `500 V`, `TRU 25.4`, `135 kVA / 20 s`, `R_HV-DC = 60 Ω`, loading resistor `R1 = 2.62 Ω`.

Executed reconstruction (§6):

```
NET ratio (22kV/√3)/500 V              = 25.403      (doc TRU 25.4, +0.013%)   ← ratio confirmed
loading resistor referred to HV        = 2.62 × 25.403²  = 1690.8 Ω
total neutral resistance Rn            = 60 + 1690.8     = 1750.8 Ω
stator earth-fault current             = (22kV/√3)/Rn    =    7.25 A primary
NER duty                               = 92.1 kVA  →  68% of the 135 kVA/20 s plate   ← design confirmed
zero-sequence series term 3·Rn         = 5252.3 Ω = 1085.2 pu (100 MVA) = 4970.2 pu (458 MVA gen base)
compare GSUT X (100 MVA base)          = 0.03107 pu      →  ratio 3.49 × 10⁴
```

The generator is **high-resistance grounded**, so its zero-sequence branch is an effective open. And the
**GSUT is YNd1 — delta on the 22 kV side** — so the 230 kV network provides *no* zero-sequence path to the
22 kV bus either. Therefore:

> **A single-line-to-ground fault on the 22 kV generator bus is fed only through the NER: of order 7 A.**

**Rev2 reported `F2 B01 LG = 111.17 kA` with `Igen = 70.67 kA`.** Error factor **1.5 × 10⁴**. Root cause:
`rev2/data/ashuganj_rev2_registry.m` sets `G.Earthing = 'Solidly grounded'` with the comment
`% supersedes old NER`, and invents `G.X0 = 0.1280`. Rev2 correctly blocked the GSUT delta path
(`PROGRESS.md:89`) but then left the generator itself as a stiff zero-sequence source — so the blocking was
defeated at the one node it mattered.

**The coherent plant design, now source-confirmed on every winding:**

| Network | Earthing | Prospective earth-fault current | Source |
|---|---|---|---|
| 22 kV generator | NER `10BAB11`, high-resistance | **≈ 7.25 A** | Siemens Rpt §2.3 |
| 230 kV GSUT HV | *"Accessible to be solidly earthed"* | high (kA) — correct in Rev2 | GSUT datasheet |
| 230 kV GAT HV | *"Accessible to be solidly earthed"* | high (kA) | GAT datasheet |
| 6.9/6.6 kV UAT LV | *"earthed through impedance that limits the fault to **5 A**"* | **5 A** | UAT datasheet |
| 6.9 kV GAT LV | *"accessible to be earthed through …"* (limit truncated) | presumed 5 A → **§7** | GAT datasheet |

The plant is **deliberately low-earth-fault-current on every generator-side and auxiliary network, and solidly
earthed only at 230 kV.** This is a textbook CCPP earthing philosophy, consistent with the relay complement
found on the GIS drawing (`64G` stator earth fault **100 %**, `64R` rotor earth fault, `59N`, `87N` restricted
earth fault). Rev2 modelled the opposite. Rev3 must rebuild the zero-sequence network from scratch, and the
LG/LLG results **will** change by orders of magnitude at B01 and B11 — that is the correct outcome and must
not be forced back toward Rev2's numbers.

---

### 2B — the UAT/GAT off-nominal tap ratio is INVERTED, and it invalidates Rev2's FINDING F1

**Verified by execution**, `tmp/rev3_tap_direction_check.m`, independent implementation, reads no Rev2 code.

Rev2 codes `U.a_LV = GT.a_LV = 6.6/6.9 = 0.95652` and stamps the standard off-nominal pi-model
`Y_ii = y · Y_jj = y/a² · Y_ij = −y/a` with `a` on the 6.6 kV side. At no load that stamp yields
`V_j = a · V_i`, i.e. **0.95652 pu**. But the physical transformer is wound **22 / 6.9 kV**:

```
apply 22 kV to the HV winding  ->  LV terminal = 6.9 kV
in pu on the 6.6 kV BUS base   =  6.9 / 6.6    = 1.04545 pu     ← must be ABOVE 1.0
```

So the correct ratio is **`a = 6.9/6.6 = 1.04545`**. Rev2 used its reciprocal. The error is
`(6.9/6.6)² = 1.09298` → **9.30 % low** on the aux bus.

**Both published results reproduce exactly under their own convention — a double-blind confirmation:**

| Load | `a` | V_B11 computed | V_B11 published | Δ |
|---|---|---|---|---|
| Rev2's 12 MW + j5 MVAr | 0.95652 (Rev2) | `0.93282` | Rev2: **0.9328** | `+0.0000` |
| Rev2's 12 MW + j5 MVAr | 1.04545 (correct) | `1.01955` | — | — |
| APSCL 14 MW + j8.6764 MVAr | 0.95652 (Rev2) | `0.91620` | — | — |
| APSCL 14 MW + j8.6764 MVAr | 1.04545 (correct) | `1.00139` | Aug suite: **1.0014** | `−0.0000` |

The August suite gets a *higher* bus voltage with a *larger* load — impossible unless the two differ
structurally, which is exactly what the tap direction is.

> **Rev2's FINDING F1 — *"B11 0.9328 pu (6.16 kV) LOW in all radial cases … report as limitation"*, with its
> recommended tap/capacitor study — is a modelling artefact, not a plant undervoltage.** The aux bus actually
> sits at ≈1.001 pu. The GAT carries the same inverted constant, so Rev2's transfer case P1C (`V_B11 0.9431`,
> `UAT 97.98 % ONAN`) is corrupted too.

Note this is *not* the sign error it resembles: `6.9/6.6` is the ratio of **winding rating to bus base**, and
it belongs on the LV side precisely because the LV winding is wound *above* its bus nominal so the bus sits
near 1.0 pu under load. Rev2's own comment — *"off-nominal: 6.9kV winding onto 6.6kV bus"* — describes the
correct physics and then codes its inverse.

---

## 3. Parameters now confirmed from primary sources

All values below carry a document + section citation. Arithmetic cross-checks are in §6.

### 3.1 Generator — Siemens Rpt §2.1.1 + nameplate

`UN 22 kV ±5%` · `SN 458 MVA` · `Smax 518 MVA` (30 °C cold gas) · `pf 0.85` · **`PN 389.30 MW`** ·
`IN 12 019 A` · `Imax 14 309 A` · `fN 50 Hz` · `t_cooldown 468 s` ·
**`xd 166.3 %`** · **`xd' 28.65 %`** · **`xd'' 22.48 %`** (all saturated) ·
`Uexc-0 122 V` · `UDC-link 2.28 kV` · `ISFC Out 1876 A` · **`I2max/IN 7.64 %`** · **`K = (I2/IN)²·t = 7.41 s`**.
Nameplate: winding **YY**, field 406 V / 3088 A, class F, IP 65, H₂ 5 bar(g), S1, 3000 rpm, 394 000 kg.

Internal consistency — all confirmed by execution:
- `458 × 0.85 = 389.30 MW` — **exact**, 0.000 % error
- `458 MVA/(√3 × 22 kV) = 12 019.4 A` vs doc 12 019 (+0.003 %)
- `Imax 14 309 A` = **518 MVA at 20.90 kV = 22 kV − 5 %** (+0.003 %) — *new finding:* `IN`/`Imax` are a
  consistent pair and `Imax` is the stator thermal limit at maximum apparent power and **minimum** voltage.
  The ±5 % band is therefore a real operating envelope, not a nameplate decoration.

**`X2` and `X0` are absent from the Siemens report** (it gives `I2max/IN` and `K` instead) and APSCL answered
**`[N/A]`** for both. Rev2's `X2 = 0.2242` / `X0 = 0.1280` have **no source of any tier** →
`ENGINEERING_ASSUMPTION`, flagged, with sensitivity range.

`Q_max`: APSCL gives `[+241 MVAR]` only. `√(458² − 389.30²) = 241.27 MVAr` (+0.11 %) — so **+241 is the derived
nameplate point, not an independent capability-curve limit**, and `Q_min` is stated nowhere →
`ASSUMPTION`. This refutes Rev2's `±200 MVAr` as sourced.

### 3.2 GSUT `10BAT10` — **Z = 16.0 % confirmed by three independent primary sources**

1. Siemens Generator Protection Report §2.2: `uk(HV-LV) = 16 %`
2. GIS drawing `INEL-…-0026`: `YNd1 Z=16% (BASE 515 MVA)`
3. APSCL form: `%Z1 [16% (main tap)]`

plus the datasheet header `Impedance voltage referred to 75 °C (base 515 MVA)`.

`230 + 8×1.25 % − 16×1.25 % / 22 kV` · `YNd1` · `355/460/515 MVA ONAN/ODAN/ODAF` ·
`R = 0.21 %` · `Z0 ≈ 15.8 %` · HV neutral *solidly earthable* · `Ck 1.1 nF` HV-LV coupling
(0.3667 nF/phase) · `IN 1292.8 / 13 515.2 A` (**both reproduce exactly** at 515 MVA) ·
losses `Cu 523/874/1095 kW` at 355/460/515 MVA, `Fe 159 kW` @100 % Un (224 @110 %), cooling 28 kW ·
excitation current `0.13 %` @100 % Un · inrush ≈ 73 000 A, decay 4.15 s · HV neutral bushing
`BRDLW1-252/1600` (Trench China).

**`R = 0.21 %` independently confirmed:** `100 × 1095 kW / 515 MVA = 0.2126 %` (+1.2 % vs datasheet). This
closes the item previously flagged for image verification — no image needed.
Loss closure: `1095 + 159 + 28 = 1282 kW` = datasheet total **exactly**.

**Rev2's 16.63 % — fairly characterised, then demoted.** IEC 60076-1 allows **±7.5 %** on `uk`, giving a
14.80–17.20 % band. 16.63 % sits **inside** it (+3.94 % of nominal), so it is *plausible* as a factory-test
value from a test report that is **not in the source set**. Per the governing instruction
(*"DO NOT use Rev2's 16.63 % as the primary value"*): **16.0 % is primary; 16.63 % is retained as a documented
sensitivity case**, not deleted.

#### 3.2a The extreme-tap impedance assignment is now CLOSED — `15.5 %` at 184 kV, `16.9 %` at 253 kV

This was the last open item on the GSUT and §7 had it queued for an image read. **No image was needed** — the
same units-column alignment method as §3.6a resolves it from the text layer. The `-layout` dump of
`GSUT Data Sheet_South.pdf` (9 pp, all with text layers) prints the value column offset one label upward, so
the rows read:

| Datasheet row | Lower tap = **min voltage = 184 kV = pos 25** | Main tap = **230 kV = pos 9** | Higher tap = **max voltage = 253 kV = pos 1** |
|---|---|---|---|
| a) Impedance voltage, % | **15.5** | **16.0** | **16.9** |
| b) Lagging (reactive) component, % | **15.5** | **16.0** | **16.9** |
| c) Resistive component, % | **0.28** | **0.21** | **0.21** |
| Zero-sequence impedance, main tap only, % | — | **15.8** | — |

The direction is not inferred — the datasheet **parenthesises it itself**: *"- Lower tap **(minimum voltage)**"*
and *"- Higher tap **(maximum voltage)**"*. And it is physically right: the minimum-voltage tap has the fewest
HV turns, hence the least leakage reactance. `Z` is monotonic with HV turns across the range.

**Why the offset reading is certain, not preferred.** Read literally, the column gives four simultaneous
absurdities: impedance at the main tap **blank** (though 16.0 % is verified three ways above), the resistive
component **16 %** (though `R = 0.21 %` is verified from the load loss), zero-sequence **blank** (though 15.8 %
is verified), and `Tolerances = 0.28` (a tolerance is not a bare 0.28). Read with the offset, **three
already-verified values land exactly on their own labels** — 16.0, 0.21, 15.8 — and `X/R` comes out **76.18**
against the verified 76.2. Executed in `tmp/rev3_gsut_tapZ_check.m`; every check PASS.

Two further confirmations from the same value column, under the same offset: the datasheet's own internal
arithmetic closes, `√(Z² − R²)` reproducing the printed lagging component at all three taps to 5 decimals; and
further down, the short-circuit rows give **9 / 43 kA** (3 s symmetrical, HV/LV) against **23 / 110 kA** peak,
a ratio of **2.556 / 2.558** — the IEC `κ√2` factor, matching each other to 0.08 % across two independent
winding sides. Alongside them `Um` 245 kV (independently verified), `Um` LV 24 kV, flux density 1.65 T, LI
1050 kV (HV) / 125 kV (LV) and AC short-duration 460 kV all land on standard values for their labels.

**Consequence for D2/D3, and it is not cosmetic.** `R` is **tap-dependent** while `X` is nearly constant, so
`X/R` swings from **≈55 at the 184 kV tap** to **≈80 at the 253 kV tap**. Since the IEC 60909 DC factor is
`exp(−2πft/(X/R))`, the asymmetrical breaking duty depends on which tap is in service. **The two permutations
that §3.7a and §7 listed as sensitivity cases are therefore resolved — but a genuine tap-position sensitivity
remains**, driven by `R`, not by `Z`.

**New verified parameters harvested from the same page** (each read under the confirmed offset):
3 s symmetrical SC withstand **9 / 43 kA** and peak withstand **23 / 110 kA** (HV/LV) — *transformer
through-fault ratings, a different rating class from breaker duty, per the §8 standing rule*; excitation
current **0.13 / 0.15 / 0.18 %** at 100 / 105 / 110 % `Un`; admissible core overexcitation **105 %** continuous
full load, **110 %** no load; max inrush **≈73 000 A** with decay constant **4.15 s**; noise **75 dB(A)**
pressure / **98 dB(A)** power; minimum life **25 years**; LV terminal overvoltage withstand **140 %** for 5 s;
bushings **IEC 60137 condenser type, OIP or RIP, oil-filled**; capacitances HV-earth **3.1×10⁻³**, LV-earth
**10.2×10⁻³**, HV-LV **4.5×10⁻³** (printed unit "F" — the magnitudes are only physical as **µF**, so recorded
with the unit flagged, not silently corrected).

**One correction to my own working, recorded because it is the standing rule's own failure mode.** I first
wrote that deriving `Lm = 791.89 pu` from `I₀ = 0.13 %` independently confirmed §6's magnetizing branch. It
does not: `I₀ = 0.13 %` was **already** recorded at §3.2 above and was the **input** to that §6 computation
(`tmp/rev3_partA_followup.m:33` carries `0.13/100` literally), so the check re-derived §6 from §6's own input —
the exact circularity C-39 and C-44 are about. What the run legitimately shows is narrower: the §6 arithmetic
reproduces from its stated inputs, and `0.13 %` was read off the correct label both before and after the
realignment. **The magnetizing branch still rests on a single source row and is not corroborated.**

### 3.3 UAT `10BBT10` and GAT `10BBT20` — CTI datasheet

| | UAT `10BBT10` | GAT `10BBT20` |
|---|---|---|
| Ratings | 19/25 MVA ONAN/ONAF, 22 / 6.9 kV | 19/25 MVA ONAN/ONAF, `230 ±12×1.25 %` / 6.9 / 3.32 kV |
| Vector group | **Dyn11** | **YNyn0+d11** |
| `Z` main tap (25 MVA base) | **10.5 %** (10.4–11.1 over taps) | **12.0 %** |
| `R` main tap | **0.4 %** | **0.5 %** ← ambiguity resolved, §6[B] |
| `Z0` main tap | **9.3 %** | **10.8 %** |
| Tolerances | IEC 60076-1 | ±7.5 % per IEC 60076-1 |
| SC withstand basis | `157 kA` @22 kV, `31.5 kA` @6.9 kV | `50 kA` @230 kV, `31.5 kA` @6.9 kV |
| Withstand 2 s / 3 s HV/LV | ≈7.0 / ≈21.5 kA | ≈0.67 / 19.8 kA |
| Peak withstood HV/LV | ≈17.8 / ≈54.9 kA | ≈1.71 / 50.4 kA |
| Losses | Cu 110 kW @25 MVA, Fe 14 kW, cooling 1.25 kW | Cu 116 kW @25 MVA, Fe **23 kW** (by closure), cooling 1.25 kW |
| Excitation @100 % Un | 0.3 % | 0.3 % (0.5 % @105, 0.8 % @110) |
| Neutrals | LV: *impedance-earthed, fault limited to* **5 A** | HV: *solidly earthable*; LV: *impedance-earthed* |
| `Um` | — | 7.2 kV |

Loss closures verified **exactly**: UAT `110 + 14 + 1.25 = 125.25` kW; GAT `116 + 23 + 1.25 = 140.25` kW
(the latter independently *establishes* GAT `Fe = 23 kW`, which is not printed as a standalone row).
Load-loss scaling to 19 MVA also closes: UAT `110 × (19/25)² = 63.5` vs `79 − 14 − 1.25 = 63.75` kW;
GAT `116 × (19/25)² = 67.0` vs `92 − 23 − 1.25 = 67.75` kW.

**Voltage-class chain — three distinct numbers, must not be conflated:**
`6.9 kV` transformer winding · `6.6 kV` plant bus (`10BBA10`, `31.5 kA 1 s, 3150 A`) · `7.2 kV` equipment
class (`Um`). **No fake 6.9 kV bus is to be created.**

> **CORRECTION (2026-09-13).** This paragraph previously read *"Off-nominal tap `a = 6.6/6.9 = 0.956522`
> (preserve from Rev2 — this part was right)"*. **That is wrong and it contradicted §2B and C-28 inside this
> same document.** The correct ratio is **`a = 6.9/6.6 = 1.04545`** — the LV winding is wound *above* its bus
> nominal, so at no load the 6.6 kV bus sits **above** 1.0 pu, not below. Rev2's constant was its reciprocal
> (9.30 % low on the aux bus, voiding Rev2 FINDING F1). Only the **voltage-class chain** above was right in
> Rev2; the tap direction was not. An internal contradiction of this kind is exactly what PART C's single
> registry exists to make impossible — until C1 lands, §2B / C-28 govern.

**Plate corroboration (§3.9, 2026-09-13).** The two rating plates independently confirm from tier-1 OEM
drawings: **Dyn11** (UAT) and **`YNyn0+d11`** (GAT) vector groups; the **19/25 MVA** dual rating, via
**ONAN/ONAF 76 %/100 %** → `0.76 × 25 = 19.0` on *both* units; the GAT's **`230 ±12 × 1.25 %`** OLTC, now with
all 25 positions on record; and the **6900 V** LV winding, closing to 25.00 MVA against its own 2091.8 A row.
The plates **cannot** corroborate the `Z`, `R`, `Z0` or loss rows — those fields are **blank by design** on
both plates (§3.9f, **C-51**), so this table stands on the CTI datasheet alone. The `Z` **base** is
independently confirmed as **25 MVA** by the plate's own column header (**C-47**).

### 3.4 Auxiliary load — **officially confirmed, refuting Rev2**

APSCL form: `Station Auxiliary Demand → [14 MW @ 0.85 pf]`.
→ `Q = 14·tan(acos 0.85) = 8.6764 MVAr`, `S = 16.4706 MVA`.
Allocation `9.018 / 2.491 / 2.491 MW` (from the `9050:2500:2500` motor-rating split) is an **ASSUMPTION**;
the 14 MW total is official.

**Rev2 used `12 MW + j5 MVAr`, which implies pf 0.9231 — not 0.85, and not the APSCL figure.** It is both
unsourced *and* internally inconsistent with the power factor it purports to use.

### 3.5 Protection, CT/VT — several items upgraded from assumption to official

| Item | Value | Source | Rev2 status |
|---|---|---|---|
| Relay trip curve | **IEC Standard Inverse** | APSCL form (form's own suggestion was *Extremely* Inverse; APSCL overrode) | assumed |
| Coordination time interval | **300 ms** | APSCL form | assumed "C" |
| Generator CT `-T1`/`-T2` | **15000/1 A**, 3 cores each (sys1 / metering / sys2), `TRI 15000` | Siemens Rpt §2.1.2 | *"OEM CTs (data req.)"* |
| Generator VT `-T5`/`-T6` | `22 kV/√3 : 100 V/√3`, **`TRU 220`** | Siemens Rpt §2.1.3 | — |
| Generator VT `-T6` residual | **`TRU 381.05`** (broken-delta, for 64G/59N) — `22000/√3 ÷ (100/3) = 381.05` ✓ | Siemens Rpt §2.1.3 | — |
| GSUT transformer CT | **1500/1 A** | SLD | — |
| GIS bay line CT | **1600/1 A** (5P20 30 VA + Cl 0.2 40 VA) | GIS drawing | 1600/1 ✓ |
| GAT CT | **500-250/1 A** | GIS drawing `63N T(86/GAT) 2 500-250/1A` | — |
| Differential relay | **Siemens `7UT6331-5QB92-4BCO+LOS`** | GIS drawing | generic |
| Line diff / busbar / bay | 2 × `7SD522`, `7SS523`, `6MD66` | GIS drawing + master md | ✓ |
| Protection panels | **`10BAY11`/`10BAY12` = GSUT & UAT**, **`10BAY20` = GAT** | GIS drawing L252/L254 | `BAY_GAT = 10BAY12` — **wrong** |

Relay functions confirmed on the GIS drawing: `64G (100 %)`, `64R`, `87N` restricted earth fault, `59N`,
`50BF`, `32R`, `25`, `27`, `50/27` inadvertent energizing, `90` OLTC regulator, `63N/63NR/63P`.

### 3.6 230 kV GIS — now fully sourced from `Data Sheet_230KV.pdf` (South) + the GIS one-line

**Equipment identity: Siemens `8DN9`** — stated on the circuit-breaker, disconnector, CT and VT sheets alike.
(So legacy's *equipment* identification was right; only its use of 50 kA as a "GIS withstand proxy for the
grid" was a provenance error — **C-07**.)

`Rated voltage 230 kV`, `max permissible 245 kV`, `50 Hz`, indoor, 3 poles, **1 interrupting chamber per pole**.

**Rated normal current — differs by module, and this settles the bus/bay rating question:**

| Module | Rated normal current |
|---|---|
| Generator transformer module | **2000 A** |
| Line module | **2000 A** |
| **Bus coupler module** | **3150 A** |

The 3150 A coupler rating matches the GIS one-line's `BUS 1 GIS SUBSTATION, 230 kV, 3150 A, 50 kA, 50 Hz`:
**busbars and coupler are 3150 A; the bays are 2000 A.** Rev2 assessed line loading against 3150 A
(`~860 A = 27 %`) — that compares a *bay* current to a *busbar* rating and must be redone against 2000 A.

**Short-circuit ratings (tier 1, verified):**

| Quantity | Value |
|---|---|
| Rated short-time withstand current | **50 kA for 1 s *and* 3 s** |
| Rated peak withstand current | **125 kA** |
| Rated peak short-circuit current | **125 kA** |
| Fault-making capacity (quick-acting earthing switch) | 50 kA |
| Interruption of loop current | 1600 A at 20 V |
| Rated capacitive breaking current | 0.5 A |

**Circuit breaker — transformer bay (6 datasheet pages):**

| Quantity | Value |
|---|---|
| Rated interrupting current | **50 kA (rms)** |
| Rated **symmetrical** interrupting current | **50 kA** |
| Rated **asymmetrical** interrupting current | **50 kA** |
| Percentage DC component | **50 %** |
| Rated short-circuit **making** current | **125 kA (peak)** |
| Rated making current | 125 kA |
| Rated duration of short circuit | **3 s** |
| Rated continuous current @40 °C | 2000 A |
| Closing/opening coil supply | **110 V DC** (max 121, min 100, −15 %/+10 %) |
| Insulation: 1-min pf to earth / across open contacts | 460 / 530 kV (rms) |
| Insulation: LI to ground / across open contacts | 1050 / 1200 kV (peak) |

#### 3.6a C-23 RESOLVED — the breaker timings were a column-alignment artefact, not a datasheet contradiction

An earlier pass in this session logged the breaker operating times as `CONFLICT_REQUIRES_CONFIRMATION`
(C-23), on the reading that *"opening time = Max 55 ms"* cannot coexist with *"total breaking time < 46 ms"*.
**That contradiction was mine, not the datasheet's.** It is now resolved from the text layer alone — no page
image needed — by aligning on the **units column** instead of on line adjacency.

**Method.** `pdftotext -layout` emits the label, unit and value columns of these sheets as three independent
streams that drift relative to one another, so same-line adjacency is unreliable. But the *unit* stream is
self-describing. Aligning label ↔ unit ↔ value **in document order** and requiring the counts to match gives a
unique solution, and the solution is locked by four independent anchors:

| Anchor | Why it can only align one way |
|---|---|
| `O-0,3s-CO-3min-CO` | can only be the **rated operating sequence** — it is a sequence, not a number |
| `-Closing time = 56 + 6 ms` vs `a) Closing time = 56 ± 6 ms` | the sheet states closing time **twice**; both land on the same row under this mapping |
| `d) Operating pressure` → `bar`; `Amount of gas` → `kg/3-phase`, `kg/1-pole`; `Length of break` → `mm`; coil → `VDC` | five **non-time** units in the same block pin the offset exactly |
| Item 7 current ratings | **6 labels ↔ 6 units ↔ 6 values**, exact, and the units are all distinct (`A`, `kA`, `kA`, `kA`, `%`, `kA(peak)`) |

Counts check out: item 10 has **15 time-valued labels ↔ 15 time values**; item 8's tail has
**3 labels ↔ 3 `ms` units ↔ 3 values**. So the resolved reading is:

| Item | Row | **Resolved value** | Previous (mis-aligned) reading |
|---|---|---|---|
| 10 a) | Closing time | **56 ± 6 ms** | 56 ± 6 ms (was already right) |
| 10 b) | **Opening time** | **33 ± 3 ms** | ~~Max 55 ms~~ ← **this was the error** |
| 10 c) | Breaking time | **Max 55 ms** | — |
| 6 | Breaking time | **54 + 6 ms** | 54 + 6 ms |
| 6 | Max operating time from trip coil — *components* / *circuit breaker* | **56 + 6 ms** / **55 ms appx.** | — |
| 8 f) | Total breaking time @ 10 / 60 / 100 % | **< 46.1 / < 45.8 / < 45.7 ms** | same |
| 10 | Total breaking time @ 10 / 30 / 60 / 100 % | **46.1 / 45.8 / 48.4 / 45.7 ms** | — |
| 10 | Maximum arc duration @ 10 / 30 / 60 / 100 % | **15.3 / 26.4 / 22.1 / 22.1 ms** | 15.3 / 26.4 / 22.1 ms |
| 10 | Rated operating sequence | **O − 0,3 s − CO − 3 min − CO** | — |
| 10 | Permissible tripping delay | As per IEC | — |

**Why this is now self-consistent.** Total breaking time = opening + arcing:
`33 ms (opening) + 22.1 ms (max arc) = 55.1 ms ≈ "Max 55 ms" ≈ "54 + 6 ms"` — the **worst-case envelope
closes to within 0.1 ms**. And `45.7 ms (offered total, @100 %) − 33 ms = 12.7 ms` arcing, a wholly normal
SF6 arcing time. So the two number families are **maximum-guaranteed (≈55 ms)** and **offered-typical
(45.7–48.4 ms)**, not a contradiction. A third, independent corroboration sits in the same block: item 10
labels the operating sequence row **`(<2.5 cycles)`** = **< 50 ms at 50 Hz**, which brackets the 45.7–48.4 ms
offered values and excludes 60 ms.

**Consequence for Rev3's breaker duty — this changes a number.** IEC 60909-0 defines `t_min` as the shortest
time from fault inception to **first contact separation**, i.e. `relay operating time + CB opening time` —
*opening*, not *breaking* (arcing is after separation). With **opening time 33 ± 3 ms**, the fast end is
**30 ms**. Rev2 assumed 60 ms and treated it as the clearing time. Since a **shorter `t_min` gives a larger
DC component**, Rev3 must report the asymmetrical breaking duty at three points:

| `t_min` | Basis | Status |
|---|---|---|
| **30 ms** | CB opening time alone, fast tolerance (33 − 3) — absolute bound, most onerous | `VERIFIED_SOURCE` for the CB part; assumes zero relay time |
| **45 ms** | 30 ms opening + ≈15 ms for a fast main protection (7SD5221 / 87G) | `ENGINEER_DERIVED` — relay time is **not** in this datasheet |
| **60 ms** | Rev2's assumption, retained for comparison | `ASSUMPTION` (Rev2), superseded but not deleted |

C-23 therefore moves from `CONFLICT_REQUIRES_CONFIRMATION` → **`VERIFIED_SOURCE` for the CB timings**, with
the residual `ENGINEER_DERIVED` element being the **relay operating time**, which no document in the set gives.

#### 3.6b SCOPE LIMIT — the CB datasheet covers ONE bay, and Rev2's FINDING F5 rests on the extension

All **six** circuit-breaker pages carry the identical header **`230 KV CIRCUIT BREAKERS - TRANSFORMER BAY`**
(text-layer lines 556, 621, 683, 771, 868, 986), and the item numbers run **1 → 46 monotonically** across
them. So this is **one continuous 46-item datasheet for the transformer-bay breaker** — not six per-bay
sheets. Verified by enumerating both the headers and the item numbers.

**Therefore:** `50 kA` symmetrical/asymmetrical interrupting, `125 kA` making, `3 s`, `2000 A` continuous and
the timings above are **source-verified for the generator-transformer bay breaker (`Q0`) only.** Applying them
to the **line breakers (`Q1`, `Q2`)** and the **bus-coupler breaker** is an **extension by inference**. The
inference is well-supported — the GIS-level short-circuit ratings in the same document are 50 kA / 125 kA for
the whole switchgear, and the breaker population row names all three classes together — but it is an
inference, and it must be labelled one.

**This directly qualifies Rev2's FINDING F5** (*"Q1/Q2 margin only 3.9 % — confirm real interrupting nameplate
before claiming adequacy"*). Rev2 was right to flag it: **the line-breaker interrupting nameplate is still not
in the document set.** Rev3 must state the Q1/Q2 verdict as *"adequate against the transformer-bay breaker's
verified 50 kA, extended to the line bays by inference from the GIS short-circuit rating"* — never as
*"verified against the line breaker's nameplate"*.

**Non-electrical rows recovered in passing** (they matter only as alignment anchors, and are recorded so the
alignment can be re-audited): SF₆ operating pressure `6.1 / 6.9 bar`; SF₆ mass `80 kg/3-phase` for the largest
compartment and `1500 kg/1-pole` for a complete gas change; total length of break per phase `Internal data`
(withheld by the vendor).

**Breaker population confirmed:** *"Generator transformer, Line & Bus coupler breakers"* — three breaker
classes, so the GIS is **double-busbar single-breaker with a coupler bay**, exactly as the August registry
recorded. `BUS 2 = 10ADA10`. Disconnector mapping: **`89B2-1(Q1)` → BUS 2**, **`89B1-1(Q2)` → BUS 1**.
`Q51`/`Q52` earthing switches, `Q9` line disconnector, `Q8` high-speed fault-making earthing switch
(its own datasheet section confirms `230 KV High Speed Fault Making Earthing Switch`).

**VT — transformer bays (tier 1):** primary **230/√3 kV**; secondary **100/√3 − 100/√3 − 100/√3 V**
(*three* secondary windings); rated output **30 − 30 − 30 VA**; accuracy **0.2** measuring / **3P** protection;
rated burden 30 VA measuring and 30 VA commercial metering; **voltage factor 1.5 for 30 s**; 50 Hz;
1-min pf withstand 460 kV; LI 1050 kV. This refines the master md's bare `230/√3 : 0.1/√3 kV, Cl 3P 30 VA`.

**CT — transformer bay (tier 1):** the datasheet gives `1 s overcurrent factor = 50 kA` and
`rated dynamic (peak) current = 125 kA`, but for the **ratio** it says *"Please refer SLD"*, and for the core
burden/class *"Shall be furnished after approval of CT parameters"*. So:
**CT ratios and core data come from the GIS one-line drawing, not the datasheet** — which is why the drawing's
`1600/1 A`, `5P20 30 VA`, `Cl 0.2 40 VA` are the governing values, and why no better source exists.

---

### 3.7 A4 COMPLETE — harvest from the seven remaining `docs/validation/*.md` files

All **10** August validation documents have now been read (1567 lines). The three read earlier
(`conflicting_parameters`, `verified_parameters`, `assumptions`) went into §4.9. This section records what the
remaining seven add. Every arithmetic claim below was re-derived independently in
[`tmp/rev3_a4_numeric_checks.m`](tmp/rev3_a4_numeric_checks.m) and executed — see §6.

> **How this was done, and a correction to my own method.** I first launched a 17-agent extract → adversarially
> verify → critique workflow over these seven files. It produced **zero** completions in 14 minutes across 18
> agent launches: six distinct keys, each restarted 2–4 times, every one ending `[Request interrupted by user]`.
> I killed it and read the files directly. 940 lines is simply not enough work to justify a fan-out, and the
> serial read was both cheaper and higher-fidelity. Recorded here because the failure is mine and repeating it
> would cost the same again.

**New verified plant parameters** (all from Rev 03 SLD / nameplates / datasheets via the August audit, each now
arithmetically cross-checked by me):

| Parameter | Value | Why it matters to Rev3 |
|---|---|---|
| MV bus `10BBA10` | 6.6 kV, **3150 A, 31.5 kA**, 3-ph, 50 Hz | **the switchgear fault rating B11 duty must be tested against in D3.** Rev2 never named a B11 rating |
| Water-intake buses `10BBW10/20` | 6.6 kV, **1250 A, 31.5 kA** | same |
| GIS **bus-coupler** module | **3150 A** | ≠ the transformer bay's 2000 A — see C-43 |
| GIS **transformer bay** | **2000 A** | the only documented bay rating; matches CB datasheet item 7 |
| GCB `10BAC10` | 22 kV, **12.4 kA cont., 100 kA sym rms breaking** | C-37; 12019 A / 12400 A = **96.93 %**, a deliberate 3 % margin |
| Generator | I_N **12019 A**, SGen5-2000H **S/N 12783** | `458e6/(√3·22e3) = 12019.4 A` ✔ |
| Generator, negative sequence | **I₂max/I_N = 7.64 %**, **K = 7.41 s** | **enables a real 46 element in D4** — this is machine capability, not the X₂ impedance, which stays an assumption |
| Generator excitation | `Uexc0 = 122 V`; SFC DC link 2.28 kV, SFC max 1876 A | D5 context |
| NER `10BAB11` | **60 Ω + 2.62 Ω loading resistor** | the actual grounding datum §2A needs. **Still to be read from the primary** — recorded from the August audit, not yet from `Generator Data_South.pdf` myself |
| GSUT | Z₀ **15.80 %**, (X/R)₀ **75.0** → R₀ **0.2107 %**; Siemens Guangzhou **S/N 881264** | zero-sequence network, D3 |
| GSUT tap table | 25 pos, **pos 1 = 253 kV, pos 9 = 230 kV (principal), pos 25 = 184 kV**, step 2875 V = 1.25 % | **closed to the volt** — see §3.7a |
| GAT tap table | 25 pos, **pos 1 = 264.5 kV, pos 13 = 230 kV (principal), pos 25 = 195.5 kV**, step 2875 V | closed to the volt; tap 14 = **227125 V** (the OCR "227275" is refuted by the printed 63.5 A) |
| UAT | principal tap **pos 3** (22000 V); LV I_N **2091.8 A**; **S/N 100579** | |
| GAT | windings **25 / 25 / 8.33 MVA**; tertiary **3.32 kV, 1448.6 A**; no-load loss **23 kW**; HV I_N **62.8 A**; Siemens Wuhan **TLSN7A54 S/N 100580** | `√3·3320·1448.6 = 8.33 MVA` ✔. The 23 kW is what makes the B9 iron-loss check possible |
| X/R, all three | GSUT **76.18**, UAT **26.23**, GAT **23.98** | I re-derived each from `X = √(Z²−R²)`; all three match the quoted values |
| Insulation classes | 230 kV Um = **245 kV**; MV equipment class **7.2 kV** | **not bus bases** — Excel `11_NOMINAL_VS_RATED` agrees ("Not bus kV Base") |
| GIS type | Siemens **8DN9**; datasheet KKS `07485-20-ADA-EHP-SIE-001 Rev 1`, 14 pp | |
| Transformer differential relay | **7UT6331** (F12/F13) | D4 |
| Plant configuration | **SCC5-PAC 4000F/3000 1S** — single-shaft SGT5-4000F + SST5-3000 + one SGen5-2000H | confirms the single-generator topology |
| EDG `10BUK01/02` | disconnector **normally open** (Rev 03 **Note 4**) | not a load-flow source, verified — not assumed |
| MV motors | **12 motors, 9050 + 2500 + 2500 = 14 050 kW** | the basis of C-39 |

**Three things that are genuinely absent, now bounded rather than open-ended:**

- `Generator Data_South.pdf` is **pp. 6–7 of a 39-page** report (`S001-112070-00-ELC-CL-0002`). The Q-capability
  curve lives on **p. 42 of Attachment 1**, which is not in the workspace. That is the single highest-value
  missing page in the project.
- ~~`psaf export (1).rar` **cannot be opened** … the extracted folder is *presumed* to be its contents;
  **that presumption is unverified** and bounds what A7 can conclude.~~ → **RESOLVED 2026-09-13 (§3.10).**
  The extractors are indeed all absent, but none was required: **RAR5 stores its filename table
  uncompressed**, so `grep -a` listed all **72** entries directly. Every one is on disk and byte-identical;
  *in-rar-but-not-on-disk* = **∅**. The presumption is now **verified**, and the store is out of scope anyway.
- Eight drawings cited by the Rev 03 SLD's own reference list are absent, including
  `INEL-112070-00-ELC-DE-0026` (the 230 kV GIS control/protection one-line — would settle line identity, coupler
  state and per-bay busbar selection in one stroke) and `INEL-112070-00-ELC-DS-0001` (Electrical Design
  Criteria — would settle the grid assumption, tap philosophy and study bases).

#### 3.7a The GSUT and GAT tap tables are now closed to the volt

Both were verified three independent ways and every check passed exactly:

| Check | GSUT | GAT |
|---|---|---|
| span ÷ step = positions − 1 | `(253000−184000)/2875 = 24` ✔ | `(264500−195500)/2875 = 24` ✔ |
| principal tap lands on 230 kV | `253000 − 8×2875 = 230000` ✔ | `264500 − 12×2875 = 230000` ✔ |
| far extreme lands on the nameplate value | `253000 − 24×2875 = 184000` ✔ | `264500 − 24×2875 = 195500` ✔ |
| printed current corroborates | `515 MVA/(√3·184 kV) = 1615.95 A` vs printed **1616 A** ✔ | `25 MVA/(√3·230 kV) = 62.76 A` vs printed **62.8 A** ✔ |
| range | **+10 % / −20 %, asymmetric** | **±15 %, symmetric** |

The asymmetry is real, not a transcription slip: both transformers use the same 1.25 % step and the same 25
positions, and each set closes exactly on its own nameplate extremes. CYME's `TAPMN = 88.00 %` implies
`22/24 = 0.9167 %/step`, which matches nothing on either plate — August's D4 is confirmed.

**What is still NOT closed:** ~~the GSUT datasheet gives Z at three taps~~ → **CLOSED later the same day by
§3.2a / C-45**: `15.5 %` at 184 kV (pos 25), `16.0 %` at 230 kV (pos 9), `16.9 %` at 253 kV (pos 1), read from
the datasheet text layer under the same units-column realignment, with the min/max direction parenthesised in
the source. The two-permutation sensitivity case proposed here is superseded — but `R` turns out to be
tap-dependent (`0.28 / 0.21 / 0.21 %`) while `X` is not, so a **genuine** tap sensitivity survives in `X/R`.
UAT and GAT have main-tap impedance only.

### 3.8 SOLVER AND TOOLCHAIN BEHAVIOUR REV3 INHERITS — measured, not assumed

`solver_behaviour.md` is the highest-value document in the project for the implementation phases. Every item in
it was established by a probe script that is still in the repository, with captured output alongside. Several
are the opposite of what the block dialogs imply. These are **hard requirements on D6 and E2**, not notes:

| # | Measured behaviour | Consequence for Rev3 |
|---|---|---|
| B1 | `powergui` carries a **second, hidden** `frequencyindice` parameter that indexes a frequency list; setting `Frequency = 50` alone leaves it at the **60 Hz default**, and the load-flow engine reads the *index* | Every build must set **both**. The grid equivalent is a pure inductance, so a silent 60 Hz solve uses **1.2×** the intended reactance while every dialog still reads 50. **Fail-loud condition for `run_all_rev3.m`** |
| B2 | The LF voltage setpoint comes from **`BaseVoltage`**, not `Voltage`; `LF.vsrc(i).Vnom` reads `BaseVoltage` | Setting the physically-labelled parameter is not enough |
| B3 | `power_loadflow(SYS,'solve')` **mutates the model** — solving twice does not repeat the computation | Fresh build per case; `bdclose` immediately after; deliverable `.slx` saved from clean builds |
| B4 | `'report'` is a **suffix to `'solve'`**, not a standalone command, and `.rep` is **appended** to the filename given | Two separate calls can describe two different networks (B3) |
| B5 | **`LF.status` is a `double` 1 / −1. Non-convergence does NOT throw**, and returns a **truncated 12-field** `LF.bus` with `Vbus` and `Sbus` absent entirely | Gate convergence **before** any post-processing. Record `NaN`, never `0` — `0` reads as "measured zero loss". **Fail-loud condition** |
| B6 | An "open" Three-Phase Breaker is a **1 MΩ snubber**, not an open circuit — a real galvanic path | Measured artefact **1.68e−4 MVA**; solver floor ≈1.5e−5 MVA. Set tolerances **above the measured artefact**, never tune until the test passes |
| B7 | The solver **merges zero-impedance nodes**: 8 register buses → **5 solved nodes** | Never copy a merged injection onto every member — doing so totals **42 MW** of auxiliary load in a plant that has 14. Keep allocated-input columns strictly separate from solver-output columns, and skip merged members in the KCL residual list rather than NaN-filling them |
| B8 | Bus numbering is **not** creation order and **not** stable across cases | Identify buses by **block handle** (`LF.bus(k).blocks`, `LF.vsrc(i).busNumber`), never by predicted voltage. Handles are per-build — compare `bdroot` against `LF.model` |
| B9 | `.rep` reports **"Total Zshunt load"** (iron) separately from series (copper) losses | Gives an independent loss decomposition — but see **C-44**, the three-way agreement does not actually close |
| B10 | `BranchType = 'L'` makes `Resistance` **silently inert**; `'RL'` is required for non-zero R. `bdclose` ≠ `close_system(mdl,0)`. Rebasing is `Y_new = Y_old × (S_old/S_new)`. Loading an SPS library **wipes the base workspace** | The first of these is **C-40** — it silently nullified Rev2's grid resistance |
| B11 | `Phases = 'ABC'` on a Load Flow Bus **silently switches the study off the balanced positive-sequence formulation onto the unbalanced per-phase one** (`Ybus` not `Ybus1`, `LF.bus` drops to 12 fields, 5 nodes → 15) while still reporting `status = 1` in 2 iterations | A change of **study type** presenting as a labelling change. **Fail-loud condition** |

Two further toolchain facts recorded by the August audit and worth keeping: **`strings` is not installed and
produced a silent false negative** (0 project-tag hits in every DBF) until replaced with `grep -a`; and
`pdftotext -layout` on large-format drawings emits multi-thousand-character lines, so `-raw` with bounded
windows is the working method there. Both are consistent with my own §8 standing rule on suspecting the layout.

---

### 3.9 THE TWO RATING PLATES — `UAT Nameplate_South.pdf` pp. 3–4, READ IN FULL (A5 CLOSED)

**This section supersedes every statement in §7 and §8 that called these pages unreachable.** Both plates are
now transcribed from the document itself, not inferred.

#### 3.9a Why they were previously thought unreadable — and what they actually are

The failure chain was: pages 3–4 return **1 character** from `pdftotext` → assumed to be scans → hunted for
image XObjects → found only six small DCT/CCITT **logos** → concluded "image-only, needs a rasteriser we do
not have". Every step followed from the first wrong inference.

The real structure, established by parsing the page objects directly:

| | Finding |
|---|---|
| Page objects | **7** (p3) and **8** (p4); `/MediaBox [0 0 1684 2384]` |
| `/Resources` | `<< /ProcSet [/PDF /ImageC] >>` — **no `/XObject` entry at all**, so there was never an image to extract |
| Contents | `22 0 R` / `23 0 R`, `/Filter [/FlateDecode]`, `/Length` 411 322 / 432 202, zlib header `78 9C` |
| Inflated size | **2 391 139** / **1 946 204** bytes of content stream |
| Operator census | **340 `re`**, 19 `BI…ID…EI` inline images, and **zero `BT/ET/Tj/TJ/Tf`** |
| The 19 inline images | all `/CS /RGB /W 1243 /H 1 /BPC 8 /F /Fl` — 1-pixel-tall **gradient strips**, decoration only |

So the pages are ~2.4 MB of **vector line art with no text operators**: every character is AutoCAD **SHX
stroked text**, drawn as paths. `pdftotext` returning 1 character is *correct behaviour*, not a defect — there
is no text layer to extract. The two tools presumed absent existed in disguise: **MATLAB's JVM inflates
Flate** (`java.util.zip.InflaterInputStream`) and **MATLAB's graphics engine rasterises paths**
(`patch`/`line` + `exportgraphics`). Tooling and method are recorded in §0; the three MATLAB↔Java traps and
the subpath defect that made the first render unreadable are in §5.

**Shared provenance block — identical on both sheets, and itself a tier-1 result:**

| Field | Value |
|---|---|
| CLIENT | **ASHUGANJ POWER STATION COMPANY LTD. (APSCL)** |
| PROJECT | **ASHUGANJ 450 MW COMBINED CYCLE POWER PLANT (SOUTH)** |
| Contractors | **TSK** (Energía y Plantas Industriales) + **INELECTRA INTERNATIONAL** (a TIGER Company) |
| Manufacturer | **SIEMENS TRANSFORMER (WUHAN) CO., LTD. — MADE IN WUHAN CHINA** |
| CAD FILE Nº | `S009-1120700-00-ELC-PE-1003_001` |
| DRAWING Nº | `S009-112070-00-ELC-PE-1003 **REV 03**` |
| Sheet | ORIGINAL SIZE A-3, SCALE 1:1, SHEET 1 OF 1 |

This is the **first direct documentary proof of plant identity and SOUTH scope inside a tier-1 OEM drawing**
— everywhere else in the project that binding rests on the file name or on the August inventory.

#### 3.9b UAT `10BBT10` — page 3 (Siemens S/N 100579)

| Field | Plate value |
|---|---|
| Drawing (client) Nº | `STWH-579UAT-0008 REV 03` |
| Siemens W.D. / Dwg. No. | `V100579` / `V03 07 333 Rev 03`, Sheet 1, **2014-04-08**, Distr. team STWH T MD |
| Signatures | Des'd `ch.c` · Chk'd `zhou` · Approved `ZYX` |
| Revisions | 01 *"Revised drawing following customers' comment"* Cheng 2014.04.30 · **02 *"Revised CT code"*** 2014.05.16 · **03 *"Revised CT code"*** 2014.06.11 |
| Transformer type | **`TLUM7444`** · Serial **100579** · Year **2014** · Spec **IEC 60076** |
| Rated power | **25 MVA** · Oil immersed · Outdoor · Three phases · **50 Hz** |
| Vector group | **Dyn11** |
| Cooling | **ONAN/ONAF (76 % / 100 %)** → `0.76 × 25 =` **19.0 MVA ONAN** |
| Max. system short-circuit power | **HV / LV = 6600 / 500 MVA** |
| HV taps (off-load, 5 pos.) | 23100 / 22550 / **22000** / 21450 / 20900 V @ 624.8 / 640.0 / **656.1** / 672.9 / 690.6 A; links 6-5, 5-7, 7-4, 4-8, 8-3 |
| HV tap **direction** | arrows on the table label **pos 1 = "Max."**, **pos 3 = "Rated"**, **pos 5 = "Min."** — read at 3× (`tmp/p3_taptbl_hi.png`), **not inferred** |
| LV | fixed **6900 V / 2091.8 A** |
| Insulation (Um / BIL / AC, kV) | HV **24 / 125 / 50** · LV **7.2 / 60 / 20** · LV-N **7.2 / 60 / 20** |
| Off-load tap changer | **`DU III 600-36-06050ME`**, 600 A, Um 36 kV |
| Oil / masses | total oil **5720 L** · active part **21.8 t** · shipping **31.5 t** · total **38.7 t** |
| Plate size | 267 × 297 mm |
| Terminals | HV delta **U-V-W**; LV star **R-S-T** with **N brought out** |

**Current transformers (IEC 61869-2):**

| Tag | Type | Ratio | Taps | Burden / class | Location |
|---|---|---|---|---|---|
| T1, T2, T3 | `LRB-24` | **1000/1** | S1-S2 | **30 VA 5P20** | HV U, V, W |
| T4 | `LR-24` | **750/1** | S1-S2 | 5 VA **Cl 0.2 Fs10** | HV U, V, W |
| T5 | `LR-7.2` | **2300/2** | S1-S2 | 20 VA **`ATR3`** | LV S |

**The UAT tap direction is now *read*, not inferred (2026-09-13).** The re-read that settled the 640.0 digit
(§6.2) also brought the tap-table arrows into view: the HV rows are annotated **Max.** at position 1
(23100 V), **Rated** at position 3 (22000 V) and **Min.** at position 5 (20900 V), with the left column marked
`HV` and the bottom row `LV`. So *"`22000 V` is the rated/nominal tap and the highest tap number is the lowest
voltage"* is a **plate statement**, not an engineering inference from the ordering — exactly the situation
already recorded for the GSUT in **C-45**. This matters to D1: the off-nominal ratio `a` must be built from the
**rated** tap, and getting the direction backwards is the defect §2B exists to prevent.

#### 3.9c GAT `10BBT20` — page 4 (Siemens S/N 100580)

| Field | Plate value |
|---|---|
| Drawing (client) Nº | `STWH-580UAT-0008 REV 03` — the package is named *"UAT"* even for the GAT; **the KKS number, not the file name, identifies the machine** |
| Siemens W.D. / Dwg. No. | `V100580` / `V03 07 549 Rev 03`, Sheet 1, **2014-05-20** |
| Signatures | Des'd **`ZZQ`** · Chk'd **`ZTF`** · Approved `ZYX` · title *"Rating Plate 数据铭牌"* |
| Project (Siemens internal) | *"Bangladesh EFIE Ashuganj UAT Project"* |
| Revisions | **blank** — issued at Rev 03 with no recorded revision history |
| Transformer type | **`TLSN7454`** · Serial **100580** · Year **2014** · Spec **IEC 60076** |
| Rated power | **25 / 25 + 8.33 MVA** (the spec's *"+"* is confirmed correct) → ONAN **19 / 19 + 6.33 MVA** |
| Vector group | **`YNyn0+d11`** — confirmed at magnification; my first-pass *"−d11"* was a lost-stroke artefact |
| Cooling | **ONAN/ONAF (76 % / 100 %)** · Three phases · Outdoor · **50 Hz** |
| Duration of short-circuit | **3 s** |
| Insulation (Um / BIL / AC, kV) | HV **245 / 1050 / 460** · **HV-N 52 / 250 / 95** (graded neutral) · LV **7.2 / 60 / 20** · LV-N **7.2 / 60 / 20** · **Stabilizing winding 3.6 / 40 / 10** |
| LV | **6900 V / 2091.8 A** |
| Stabilizing winding | **3320 V / 1448.6 A** |
| On-load tap changer | **`VM III 350Y-123/C-14273W`**, 350 A, **Um 123 kV** — a **neutral-end, star-connected** OLTC (`…Y-123…`), which is exactly what the graded HV-N insulation and the reversing switch imply |
| Oil / masses | total oil **22 857 L** · active part **31 t** · shipping **65 t** · total **68 t** |
| Bushings | top row **N, n, R, S, T, cw1, aw2** · bottom row **OLTC, U, V, W** |
| Phasors | HV star U-V-W-N · LV star R-S-T-n · tertiary **delta aw-bw-cw** |

**HV OLTC — all 25 positions now on record** (previously only the tap *voltages* were proved, §3.7a):

| Pos | kV | A | | Pos | kV | A |
|---|---|---|---|---|---|---|
| 1 (Max) | 264.500 | 54.6 | | 14 | 227.125 | 63.5 |
| 12 | 232.875 | 62.0 | | 25 (Min) | 195.500 | 73.8 |
| **13A / 13B (Rated) / 13C** | **230.000** | **62.8** | | | | |

Selector numbers run **16 → 4** with a **reversing switch `K+` (positions 1–12) / `K−` (14–25)**; arrow labels
`3-4` and `16-3`. Step = **2875 V = exactly 1.25 %**, ±12 steps = **±15 %**, confirming the datasheet's
`230 ±12×1.25 %`.

**Current transformers:**

| Tag | Type | Ratio | Taps | Burden / class | Location |
|---|---|---|---|---|---|
| T1 | `LRB-245` | **500, 250/1** | S1-S2, S1-S3 | **30 VA 5P20** | HV U, V, W |
| T2 | `LR-245` | **100/1** | S1-S2 | 5 VA **Cl 0.2S Fs10** | HV U, V, W |
| T3 | `LR-245` | **80/2** | S1-S2 | 20 VA **`ATR3`** | HV V |
| **T6** | **`LRB-126`** | **250/1** | S1-S2 | **15 VA 5P20** | **HV-N (neutral)** |
| T5 | `LRB-24` | **2300/2** | S1-S2 | 20 VA **`ATR3`** | LV S |

**T6 is new to the project** — a dedicated 250/1 5P20 **neutral CT** on the GAT HV star point. It is the
correct source for the GAT `51N` and for restricted earth fault (`87N`), and D4 must use it instead of
deriving neutral current from the phase CTs.

#### 3.9d THE DECISIVE FINDING — the GAT 8.33 MVA winding is a *stabilizing* winding, proved by its wiring

Read at 2× line width (`tmp/p4_tertbox.png`), the tertiary terminal box shows three winding bars with ends
`aw1/aw2`, `bw1/bw2`, `cw1/cw2`, joined by **external links `aw1–bw2`, `bw1–cw2`, `cw1–aw2`**, and the
**`cw1`/`aw2` node carries an earth symbol**. Only **`cw1` and `aw2`** appear in the bushing list.

```
 aw1 ---- winding a ---- aw2 --+-- [EARTH]
   |                           |
   +--- bw2 -- winding b -- bw1 |
                            |   |
                        cw2 -+  |
                             |  |
                  winding c  |  |
                            cw1-+
        => closed delta, made by links in the terminal box,
           earthed at ONE corner, with no three-phase take-off.
```

Three consequences, all binding on **D3**:

1. The winding is a **stabilizing winding, not a loaded tertiary** — the spec's treatment is now
   **source-proven** rather than assumed. There is physically no way to draw a three-phase load from it.
2. It **must** appear in the zero-sequence network as a **real closed-delta circulating path** (a delta
   winding short-circuits zero-sequence mmf whether or not it is loaded). Omitting it would overstate the
   GAT's zero-sequence impedance.
3. Its single earthed corner is a **potential reference only**. A closed delta earthed at one corner carries
   **no steady-state zero-sequence return current**, so it must **not** be modelled as an earth-fault current
   source at 3.32 kV. This distinction is the whole point of recording the wiring rather than the rating.

#### 3.9e Arithmetic cross-checks — now EXECUTED, and one of them genuinely independent

All figures below are **computed output** from `tmp/rev3_plate_numeric_checks.m`, logged verbatim at
`docs/validation/rev3/A5_plate_numeric_checks.log` — **26 PASS · 1 documented source-document deviation ·
0 FAIL**. See §6.2 for the run, the source-pairing of every block, and what the run corrected in this section.

| Check | Arithmetic | Computed vs printed | Pairing |
|---|---|---|---|
| GAT taps vs datasheet | `230 000 × (1 + (13−pos)×1.25 %)` | **exact** at pos 1 / 12 / 13 / 14 / 25; step **2875 V = 1.2500 %**, range **±15.0 %** | **INDEPENDENT** (plate ↔ CTI datasheet) |
| GAT tap currents | constant **25 MVA** throughput | 54.5700 / 61.9807 / 62.7555 / 63.5498 / 73.8300 vs printed 54.6 / 62.0 / 62.8 / 63.5 / 73.8 ✔ | INTERNAL |
| UAT tap voltages | `22 000 × (1 ± {2,1,0}×2.5 %)`, 550 V step | **exact**, all five | **INDEPENDENT** (plate ↔ datasheet rule) |
| UAT tap currents | constant **25 MVA** | 624.8380 / **640.0779** / 656.0799 / 672.9024 / 690.6104 vs printed 624.8 / **640.0** / 656.1 / 672.9 / 690.6 | INTERNAL — **one 0.012 % source-document rounding slip**, see §6.2 |
| LV rating, both plates | `√3 × 6900 × 2091.8` | **24.9994 MVA** ✔ | INTERNAL, but printed identically on two separately-drawn plates |
| **Stabilizing winding** | `√3 × 3320 × 1448.6` | **8 330 042 VA = 8.3300 MVA** ✔ | **INDEPENDENT** (two different plate fields) |
| Cooling class | `0.76 × 25` | **19.0 MVA** on both units; stabilizing winding `0.76 × 8.33 =` **6.33 MVA** | **INDEPENDENT** (plate ↔ CTI datasheet) |
| GAT OLTC ratio span | `kV(pos)/230` | **0.8500 … 1.1500 pu** — the range D1 must implement | INTERNAL (consequence check) |

The stabilizing-winding check is the one that carries real evidential weight: the **voltage/current row** and
the **rated-power header** are two *different fields of the plate*, populated from different design
quantities, so their agreement is a genuine independent confirmation and not a restatement (§8 standing
rule). It also fixes the value precisely — **8.333 MVA would require 1449.1 A**, and the plate prints 1448.6 A,
so the design figure is **8.33 exactly**.

**UAT HV design short-circuit power, 6600 MVA at 22 kV → `Ik = 173.2 kA`.** Plausibility against the plant's
own machines: generator `458 / 0.2248 =` **2037.4 MVA** (53.5 kA) + GSUT `460 / 0.16 =` **2875.0 MVA**
(75.4 kA) = **4912.4 MVA = 128.9 kA**; at `c = 1.10`, **141.8 kA**. So Siemens specified a **design envelope
22.1 % above** the computed level. That is a valuable *independent corroboration of the order of magnitude* of
the 22 kV bus fault level for D3 — and it is a **manufacturer design basis, not a measured plant fault level**
(→ **C-48**). The LV figure **500 MVA** is exactly the IEC 60076-5 Table 1 standard value for Um 7.2 kV; the
HV 6600 MVA is **not** the table value for Um 24 kV, so it is project-specific rather than boilerplate.

> **CORRECTION (2026-09-13) — three numbers in this section were hand-arithmetic and three were wrong.**
> The executed run superseded them, and they are recorded here rather than quietly overwritten:
> `√3 × 3320 × 1448.6` was written **8 330 246 VA**; it is **8 330 042 VA** (204 VA, 0.002 %).
> The 8.333 MVA counterfactual current was written **1449.2 A**; it is **1449.1 A**.
> The machine sum was written **≈4915 MVA ≈ 129 kA … roughly 20 % above**; it is **4912.4 MVA, 128.9 kA,
> 22.1 % above**. None of the three changes a conclusion, and that is precisely why they survived
> three drafts of proof-reading — which is the argument for executing the arithmetic instead of checking it
> by eye.
>
> **One row is withdrawn as unsupported.** The earlier table quoted a GAT tap current pair
> *"69.73 computed / 69.7 printed"*. `69.73 A` is the correct constant-25-MVA current for **207 kV = position
> 21**, but position 21 is **not** in the §3.9c transcription, so the *printed* 69.7 has no record behind it.
> The arithmetic is sound; the source citation is not, so the row is removed rather than kept as a number with
> unknown provenance (§8 standing rule).

#### 3.9f A significant NEGATIVE result — the impedance and loss columns are blank by design

On **both** plates the following fields are **printed as empty boxes** (confirmed at zoom,
`tmp/p3_zcols.png` / `tmp/p4_zcols.png`):

> **Load loss (kW)** · **HV-LV Impedance (%)** · **No-load loss** · **No-load current** ·
> **Type of insulating oil** · **Temperature rise of top oil / winding (K)**

These are rating-plate **drawings**; the test-dependent values are stamped after factory test. So the plates
**cannot** corroborate or contradict the CTI datasheet's `Z` and loss figures — §3.3 stands on the datasheet
alone, and that is now a documented fact rather than an untested hope.

Two consequences that do change the study:

- The UAT column headers read **"Load loss (at 25 MVA)"** and **"HV-LV Impedance (at 25 MVA)"**. The base
  qualifier is explicit on the plate, which **corroborates §3.3's statement that `Z = 10.5 %` is on the
  25 MVA (ONAF) base, not the 19 MVA ONAN base** — a 1.32× error if taken the other way (→ **C-47**).
- The GAT plate has **exactly one impedance column, "HV-LV"**. There are **no HV-Stab or LV-Stab columns at
  all.** The GAT pairwise `Z_PT` / `Z_ST` are therefore **not on the plate**, and §7's `MISSING` status is
  converted from an untested assumption into a **positively evidenced finding**.

#### 3.9g Two items recorded verbatim, not interpreted

- **`ATR3`** is exactly as printed — verified at 2× zoom on both plates, and it is **not** an IEC 61869-2
  accuracy class. It appears only on the **single-phase, `/2`-secondary, 20 VA** cores (GAT HV-V and LV-S;
  UAT LV-S), a placement consistent with thermal-image / winding-temperature-indicator duty rather than
  protection or metering. It is logged `UNKNOWN` (manufacturer designation) and these cores are **excluded
  from the D4 protection CT registry** (→ **C-49**).
- The two plates deliberately differ in accuracy class: UAT T4 = **`Cl 0.2 Fs10`**, GAT T2 = **`Cl 0.2S Fs10`**
  (0.2 vs **0.2S**). Both are read at magnification; this is a real difference, not a transcription slip.

**Plate-layout asymmetry worth a registry note:** the UAT plate carries *"Max. system short-circuit power
HV/LV"* but **no** *"Duration of short-circuit"* field; the GAT plate carries *"Duration of short-circuit
3 s"* but **no** max-system-short-circuit-power field. Neither absence is evidence about the other machine.

**And one provenance note for D4:** UAT revisions **02 and 03 were both *"Revised CT code"***. The CT table in
§3.9b is therefore the twice-revised Rev 03 content — the D4 CT registry depends on exactly this revision, and
any earlier-revision CT data found elsewhere in the document set is superseded by it.

---

### 3.10 A7 TERMINATED BY USER DECISION — the PSAF artefacts are struck from scope (2026-09-13)

**User instruction, verbatim: *"forget all psaf files, they are dead."*** A7 was the audit of the prior CYME
PSAF 2.81 model — `AUTOSAVE.NWT/.nwk/.STU`, `psaf export (1)/`, the root `.DBF`/`.dbt`/`.ntx` tables, the
`.rar`, and `Ashuganj_South_PSAF_Tabular_Engineer_Source.xlsx`. **That audit is stopped.** No PSAF file is a
source for REV3, at any tier. They are not tier-3 `ENGINEER_DERIVED` either — they are **out of scope**.

This is a sound engineering call, and the partial audit had already shown why: the prior model is
**not a model of this plant**. Before termination, the following were established by md5 / byte / dBASE-header
evidence, and they are kept here as the **justification for the exclusion**, not as data to be used.

| # | Established (byte-verified) | Why it disqualifies the PSAF set |
|---|---|---|
| 1 | `[Tcul Txfo] GSUT 10BAT10` runs `B22G → B230_1` with **`Pcon = Y` (22 kV), `Scon = D` (230 kV)** | The real GSUT is **230/22 kV YNd1** — star on 230 kV, delta on 22 kV. The model has it **reversed**. The control is in the same file: `[FixedTap Txfo] T1` has `Pcon = D, Scon = Y`, correctly matching the UAT's Dyn11. One sibling right, one wrong ⇒ a **specific error**, not a convention difference. Direct ancestor of headline defect **2A** |
| 2 | `T1` runs `B22G → B6_6` | The UAT's **6.9 kV winding is absent from the prior model entirely**. Ancestor of **§2B / C-28** (inverted tap) |
| 3 | No `[Line]`, no `[Load]`, no shunt, **no three-winding section** | The **GAT does not exist** in the model and the **14 MW aux load is not connected**. `B230_2` and `BGRID230` are **isolated islands** — the double busbar is declared but has no coupler and no circuits |
| 4 | `PSAF.INI` → `FREQUENCY=60.000000`; both `.STU` → `Version 125, Base Power 100, Freq 60` | **60 Hz.** Bangladesh is **50 Hz**. Confirms **C-18 / D6** from *three* independently-written files, where August had only the `.STU` |
| 5 | `PSAF.INI` → **`DEFAULTZ0=CYMFAULT`** | Zero-sequence data was **never entered** — left at CYME's built-in default. This is the *mechanism* behind 2A, not merely a correlate of it |
| 6 | `G1`: `PSol = 0, QSol = 0`; every bus `Volt Sol`/`Angle Sol` flat | **The model was never successfully solved.** No result in it was ever load-flow-validated |
| 7 | `G1 Ground R = 730, Ground X = 0.1` (`AUTOSAVE`) vs **`9999 / 9999`** (`ONGOING`) | Neither is the NER. Two different library artefacts for the same machine in two copies of the same file |
| 8 | All 62 `.DBF` tables identical across root, `psaf export/`, `psaf export/database/`; **dBASE `lastUpd` headers read 1999-03-02 … 2005-12-13** | These are **CYME factory library tables**, vendor-dated 1999–2005. The 2026-08-13 filesystem stamp is a copy artefact. `twinding.dbf` holds `TRANSFO1…TRANSFO5` demo records (69/13.8 kV, 735/215/138 kV) — **CYME sample data** |
| 9 | `AUTOSAVE.NWT` **≡** `psaf export/ONGOING.NWT` (md5 `e7ebeb7c…`), the "export" copy written **17 Aug 00:55**, three minutes after the root autosave | A folder named *"export"* containing a **copy of the root file made four days after the export**. Treating them as two models double-counts one file |
| 10 | The `.NWT`/`.nwk` were **hand-edited in a text editor**: CR=79 vs LF=69 ⇒ **10 embedded CRs**, sitting inside the Extra-ID field and immediately after bus IDs (`B400_WI␍`, `BGRID230␍`), co-located with `Zone = NONE` (not `0`) and `pu Min = 0` (not `0.9`), plus a bus row whose ID is literally `0.00000` | The file was edited by hand, malformed, and the malformation is **co-located with wrong field values**. Not a trustworthy machine-written artefact |

**On the `.rar` — the residual risk is closed, not merely "stated".** The standing concern was that
`psaf export (1).rar` (47 721 B) could not be opened, since this machine has no extractor. It did not need
one: **RAR5 stores its filename table uncompressed**, so `grep -a` enumerates the archive without decoding a
byte of payload. It holds **72 entries**, every one of which is present on disk and byte-identical
(`comm` over the two name lists: *in rar but not on disk* = **∅**). The only on-disk items *not* in the archive
are `ongoing.nwk` and the `database/` subfolder. So the archive contains **no unseen file**, and the residual
risk that motivated the item is **zero**, not "bounded". This is a second instance of the §8 rule
*"no tool installed" does not mean "cannot be done"* — and the general lesson is sharper than the PDF case:
**a container's index is usually plaintext even when its contents are not.**

> **CORRECTION (2026-09-13) — an earlier reading of the `UpdateDBF` logs in this session was wrong, and it
> pointed the opposite way.** I recorded that the 475 French lines *"Suppression d'un champs non existant"*
> proved "the DBFs were rewritten locally in August, so they are not as-delivered engineer data."
> **That is backwards.** The phrase means *"deletion of a non-existent field"* — under the log's own header
> `In Script / Found in Database`, it is a schema **comparison report** listing fields the migration script
> looked for and **did not find**. Nothing was written. The dBASE `lastUpd` headers prove it independently:
> they still read **2003-01-07 / 2004-05-04 / 2005-08-26 / 2005-12-13**, and `val.DBF` reads **1999-03-02**,
> matching its filesystem mtime exactly. Had August's run rewritten the tables, every `lastUpd` would read
> 2026-08. The logs prove the libraries are **untouched vendor data** — which is *why* they contain no plant
> data, and is a cleaner reason to exclude them than the one I first gave.

**The one finding that survives termination, because it is about REV3's own numbers rather than about PSAF.**
The library record `txvar.DBF → 10BAT10` carries:

```
10BAT10   515.000 MVA   230.000 / 22.000 kV   Z1 0.1600  X/R 76.200
                                              Z0 0.1580  X/R 75.000
          taps 88.00–110.00, 25 positions     Pcon Y  Scon D  +30.00°   "POWER STATION, AT 50 HZ"
```

Every one of those figures is **already in the REV3 master dataset** (GSUT 515 MVA ONAF, Z = 16.0 %,
Z₀ ≈ 15.8 %, 25 tap positions), and `X/R = 76.2` is the exact value §3.9 / D3 uses for the DC decay factor.
**This does not make the PSAF file a source, and REV3 will not cite it.** It raises a provenance question
about values REV3 already holds: were 16.0 % / 15.8 % / 76.2 taken from the Siemens and CTI datasheets, or
**inherited from this library record and later attributed to the datasheets?** §3.2 answers this for
**Z = 16.0 %**, which is confirmed by **three independent primary sources** — that one is safe. The others are
not yet closed. **B1 must confirm `Z₀ ≈ 15.8 %` and `X/R = 76.2` against a primary document**, and if no
primary document carries them they are **`ENGINEER_DERIVED` at best**, not `VERIFIED_SOURCE`. Note also that
this record says **"AT 50 HZ"** while the study it feeds ran at **60 Hz** — the prior model contradicted its
own library.

**Not audited, and now never will be:** `Ashuganj_South_PSAF_Tabular_Engineer_Source.xlsx` (14 sheets). August
recorded **C-16** against it — *Rev 00 values cited as Rev 03*. **C-16 stands as an unverified August finding**
and is marked as such; no REV3 parameter may depend on it. `.ntx` index files carry zero independent data and
were never in scope for content.

---

## 4. CONFLICT REGISTER (PART A deliverable)

Every row records **both** values, identifies the higher-priority source, and states why. Nothing is silently
chosen; nothing is deleted.

| # | Parameter | Rev2 / legacy | Primary source | REV3 decision | Status |
|---|---|---|---|---|---|
| C-01 | **Generator earthing** | `'Solidly grounded'`, status B, *"supersedes old NER"* | Siemens Rpt §2.3: NER `10BAB11`, 22 kV/√3:500 V, TRU 25.4, 135 kVA/20 s, R_HV-DC 60 Ω, R1 2.62 Ω | **high-resistance grounded via NER**, Rn ≈ 1750.8 Ω, I_f ≈ 7.25 A | `VERIFIED_SOURCE` |
| C-02 | Generator `X2`, `X0` | `0.2242`, `0.1280` | **absent** from Siemens Rpt; APSCL → `[N/A]` | `ENGINEERING_ASSUMPTION` + sensitivity; **never** labelled Siemens-verified | `ASSUMPTION` |
| C-03 | **GSUT `Z`** | `16.63 %` | 16.0 % × **3 independent primary sources** | **16.0 % primary**; 16.63 % retained as sensitivity (inside IEC ±7.5 % band → possibly a factory test not in the source set) | `VERIFIED_SOURCE` |
| C-04 | **Auxiliary load** | `12 MW + j5 MVAr` (pf 0.923) | APSCL: `14 MW @ 0.85 pf` | **14 MW + j8.6764 MVAr**; 3-way split = assumption | `OFFICIAL_SECONDARY` |
| C-05 | **Grid equivalent** | `R = 0.268`, `X = 2.940 Ω` (‖Z‖ 2.9522) | 2019 dataset: `Ik'' 45.01 kA`, `‖Z‖ 3.25 Ω`, `X/R 10.99` | **`R = 0.29451`, `X = 3.23663 Ω`** — see §4.5 | `OFFICIAL_SECONDARY` (corrected) |
| C-06 | Grid `Ik''` basis | 45.01 kA (Rev2) / 50 kA (`matlab/data/ashuganj_grid.m`) | two different documents, two different meanings | **BASE = 45.01 kA** (2019 compilation, c=1.10); **SENSITIVITY = 50 kA** (Siemens *estimate*) | both retained |
| C-07 | Provenance of 50 kA | `'Siemens 8DN9 GIS short-time withstand, USED AS A PROXY ONLY'` | Siemens Rpt §2.4 gives it as *"Maximum apparent three phase short circuit current **of the grid**"*, *"Grid impedance (**estimated**)"* | legacy label is a **provenance error**; the number is right, the attribution is wrong | corrected |
| C-08 | **`342.01 MW`** | absent from Rev2 LF (which used 354 MW) | APSCL row: symbol `P_net`, description *"Site De-rated Active Power"*, located in §1 *Synchronous Generator Parameters* | **site-derated generator active power** (section placement + row description govern); net-export reading retained as an explicit alternative case | `CONFLICT_REQUIRES_CONFIRMATION` |
| C-09 | Generator operating point | `354 MW` base, `360 MW` upper | **no source states either** | both → `ASSUMPTION`; case matrix built on 389.30 (rated) and 342.01 (derated) | `ASSUMPTION` |
| C-10 | Generator `Qmax/Qmin` | `±200 MVAr` | APSCL `+241` only (= √(S²−P²), derived) | `Qmax = +241` `ENGINEER_DERIVED`; `Qmin` `ASSUMPTION` | mixed |
| C-11 | GAT `R` main tap | 0.5 % (legacy) | layout dump ambiguous 0.4/0.5 | **0.5 %** — resolved arithmetically: `100×116/25000 = 0.464 %` rounds to 0.5, not 0.4 | `VERIFIED_SOURCE` |
| C-12 | GSUT `R` | 0.21 % | datasheet 0.21 % with an unexplained `*)` footnote | **0.21 % confirmed** by a second route: `100×1095/515000 = 0.2126 %` (+1.2 %) | `VERIFIED_SOURCE` |
| C-13 | Generator `xd`, `xd'` | `1.783`, `0.3256` | Siemens Rpt: `166.3 %`, `28.65 %` | **1.663, 0.2865** | `VERIFIED_SOURCE` |
| C-14 | GSUT `Z1_pu_own` | `0.1663` | 0.16 | **0.16** (the `0.1663` looks like `xd`'s 166.3 % mis-keyed into the transformer record) | `VERIFIED_SOURCE` |
| C-15 | Zn (generator) | — | APSCL wrote `[(60) Low-Reactance]` | **value 60 Ω agrees with Siemens `R_HV-DC`; the "Low-Reactance" tick conflicts with the tier-1 high-resistance NER → tier 1 wins** | resolved, both recorded |
| C-16 | GSUT OLTC | `+8×1.25 % −16×1.25 %` (drawing) | APSCL wrote `+8*1.25% -16*1.15%` | **drawing wins** (`1.15` is a typo; the datasheet tap set is uniform 1.25 %) | resolved |
| C-17 | `BAY_GAT` | `10BAY12` | GIS drawing: `10BAY20 GAT TRANSFORMER PROTECTION PANEL`; `10BAY11/12` = GSUT & UAT | **`10BAY20`** | `VERIFIED_SOURCE` |
| C-18 | GSUT `Fe` loss / `Rm` | Rev2 V2 mask `Rm 3316.5` pu → implies `Fe ≈ 155.3 kW` | datasheet `159 kW` @100 % Un | **`Rm = 3238.99` pu** own base; immaterial to results (≈4 kW) but the datasheet governs | `VERIFIED_SOURCE` |
| C-19 | UAT HV CT | `800/1` (Rev2 protection) | not yet located in a source | → **§7**, currently `ASSUMPTION` | open |
| C-20 | Bus coupler normal state | `Coupler_closed = true` everywhere | **Existence** now tier-1 confirmed (`Bus coupler module`, 3150 A; *"Generator transformer, Line & Bus coupler breakers"*). **Normal state still stated nowhere.** | coupler **exists** = `VERIFIED_SOURCE`; its **operating state** remains `ASSUMPTION` → run **BUS-CLOSED** *and* **BUS-OPEN** | partly closed |
| C-21 | GIS bay rated normal current | Rev2 compared line loading to **3150 A** (*"~860 A = 27 % of 3150 A"*) | DS datasheet: **Generator Transformer module 2000 A · Line module 2000 A · Bus coupler module 3150 A** | **3150 A is the busbar/coupler rating; the bays are 2000 A.** Line loading must be restated against 2000 A → 859 A = **43 %**, not 27 % | `VERIFIED_SOURCE` |
| C-22 | Breaker interrupting rating | `50 kA interrupting **ASSUMED (C)**` | CB datasheet: rated interrupting 50 kA, **rated symmetrical interrupting 50 kA**, rated asymmetrical interrupting 50 kA, **% DC component 50 %** | Rev2's guess was **right but unsourced** — now tier 1. Answers Rev2's own FINDING F5 (*"confirm real interrupting nameplate before claiming adequacy"*) | `VERIFIED_SOURCE` |
| C-23 | **Breaker clearing time `t_min`** | `60 ms (C)` assumed | CB datasheet, aligned on the **units column** (§3.6a): **opening 33 ± 3 ms**, breaking max ≈55 ms (`54 + 6`), total breaking time offered **45.7–48.4 ms**, max arc duration 15.3–26.4 ms, sequence row labelled **`(<2.5 cycles)`** = <50 ms | **RESOLVED — it was my column misalignment, not a datasheet contradiction.** `33 + 22.1 = 55.1 ms` closes the envelope to 0.1 ms. IEC 60909 `t_min` = relay + **opening** time ⇒ report duty at **30 / 45 / 60 ms**; Rev2's 60 ms was the **least onerous** | `VERIFIED_SOURCE` (CB); relay time `ENGINEER_DERIVED` |
| C-24 | Short-time withstand duration | `50 kA / **1 s**` | DS datasheet: rated short time current **50 kA for 1 s *and* 3 s**; CB: rated duration of short circuit **3 s** | **3 s** — the equipment is more capable than Rev2 credited | `VERIFIED_SOURCE` |
| C-25 | Peak withstand | `125 kA-**class** peak capability` (inferred, Rev2 report note) | DS: **rated peak withstand 125 kA**, rated peak short-circuit 125 kA; CB: **rated short-circuit making 125 kA (peak)** | **125 kA verified.** Rev2's peaks 115.6–120.8 kA ⇒ margin only **3.4–7.5 %** — now a *sourced* constraint, and the **binding** one (tighter than the rms margin) | `VERIFIED_SOURCE` |
| C-26 | 230 kV VT secondary | master md: `230/√3 : 0.1/√3 kV, Cl 3P 30 VA` (single winding implied) | VT datasheet: **three** secondaries `100/√3 − 100/√3 − 100/√3 V`, **30 − 30 − 30 VA**, **Cl 0.2** measuring *and* **3P** protection, voltage factor **1.5 / 30 s** | **refinement, not conflict** — the md quoted one winding of three | `VERIFIED_SOURCE` |
| C-27 | 230 kV CT ratio & cores | taken from the GIS one-line (`1600/1`, `5P20 30 VA`, `Cl 0.2 40 VA`) | CT datasheet **declines to give them**: ratio → *"Please refer SLD"*; cores → *"Shall be furnished after approval of CT parameters"* | **one-line drawing is the correct and only source** — provenance now closed, previously an unexamined assumption | `VERIFIED_SOURCE` (provenance) |
| C-28 | **UAT/GAT off-nominal tap ratio** | `a_LV = 6.6/6.9 = 0.95652` | physical winding ratio 22/**6.9** kV onto a **6.6** kV bus base ⇒ `a = 6.9/6.6 = 1.04545` | **INVERTED in Rev2** — §2B, verified by execution. 9.30 % error on the aux bus; **voids Rev2 FINDING F1** | `VERIFIED_SOURCE` |
| C-29 | **Generator CT `16000/1 A`** | I judged it an **OCR artefact of `1600/1`** (§7) | Aug `conflicting_parameters.md` **C3**: Rev 00 SLD generator CT = **16000/1 A**, Rev 03 = **15000/1 A** | **my hypothesis was wrong.** It is a real Rev 00 value, superseded by Rev 03. Not an OCR error | `VERIFIED_SOURCE` (corrected) |
| C-30 | **UAT HV CT ratio** | Rev2 protection used `800/1` (C-19, source not located) | Aug `verified_parameters.md` §9: UAT CTs **T1–T3 = 1000/1, 30 VA 5P20**; T4 = 750/1 Cl 0.2; T5 = 2300/2 | **`1000/1`** — C-19 is now **closed**. Every Rev2 UAT-HV 51 setting (pickup 409 A, TMS 0.318) must be recomputed | `VERIFIED_SOURCE` |
| C-31 | **Grid Thevenin — a THIRD representation** | Rev2: `R 0.268 / X 2.940` (Ref A at c=1.0). Rev3 §4.5: `R 0.29451 / X 3.23663` (Ref A at c=1.10) | Aug suite: **`R = 0` exactly, `X = 2.6558 Ω`** (Ref B), **user-approved as Q1a on 2026-08-17** with a stated reason | **three live candidates** — must be resolved with the user, not silently. See §4.8 | `CONFLICT_REQUIRES_CONFIRMATION` |
| C-32 | **Generator V setpoint** | Rev2: `G.Vset_pu = 1.00`, status `C`, treated as settled | Aug `assumptions.md` **A5**: *"❌ NOT APPROVED"* — no document gives an AVR setpoint, schedule, or measured 22 kV reading | **still unapproved.** Every pu voltage in the study is relative to it. Rev3 must carry it as an open user decision, not bury it | `ASSUMPTION` (unapproved) |
| C-33 | Aux 3-way load split | my spec split `9.018 / 2.491 / 2.491 MW` (I logged the split itself as an assumption) | Rev 03 SLD **MV MOTOR TABLE**: 12 motors, subtotals **9050 / 2500 / 2500 kW**, total **14 050 kW** | the **ratio is documented**, not invented — upgrade to `DERIVED_FROM_VERIFIED_DATA`; only the *method* (scaling rated kW to the 14 MW total) stays an assumption | upgraded |
| C-34 | Generator `Qmax/Qmin` — stronger finding | C-10 above: `Qmax +241` derived, `Qmin` assumption | Aug **C4**: the Excel Q-curve was transcribed from a **truncated** PSAF record citing a page **absent** from the project; the PSAF `QMAX/QMIN` scalars (`0.653 / −0.131 MVAr`) are a verbatim **1.3 MW diesel-generator template** artefact | Q limits are **`MISSING`, not derived.** Aug ran unconstrained with `Qlim_Status = NOT_APPLICABLE` — the honest treatment. Supersedes C-10 | `MISSING` |
| C-35 | GSUT max system short-circuit power | datasheet basis `95 kA @22 kV`, `50 kA @230 kV` (§4.7) | GSUT **rating plate**: *"Max. system short-circuit power HV/LV = 21 218 / 3950 MVA"* → 53.3 kA @230 kV, 103.7 kA @22 kV | datasheet-vs-rating-plate drift (the C15 pattern). Both retained; §4.7's cross-check is unaffected in conclusion | both recorded |
| C-36 | **Which breakers the CB datasheet actually covers** | Rev2 (and my §3.6 first pass) applied the CB ratings to `Q0`, `Q1`, `Q2` and the coupler alike | all **six** CB pages are headed `230 KV CIRCUIT BREAKERS - **TRANSFORMER BAY**` with item numbers running **1 → 46 monotonically** — one 46-item sheet for **one** bay. No line-bay or coupler CB datasheet exists in the set | 50 kA / 125 kA / 3 s / 2000 A / the §3.6a timings are `VERIFIED_SOURCE` **for `Q0` only**; their use on `Q1`/`Q2`/coupler is an **extension by inference** from the GIS-level 50 kA / 125 kA short-circuit rating. **Rev2's FINDING F5 was right** — the line-breaker nameplate is still absent | `VERIFIED_SOURCE` (Q0) + `ENGINEER_DERIVED` (extension) |
| C-37 | **Generator breaker `10BAC10` rating and duty basis** | Rev2 FINDING F4: *"B01 106–122 kA @22 kV (gen 52–71 kA share) exceeds typical **63 kA** gen-breaker class — report limitation"* | Aug `verified_parameters.md`: GCB **`10BAC10`, 22 kV, 12.4 kA continuous, 100 kA symmetrical rms breaking** | **F4 is wrong twice over.** (i) The rating is **100 kA verified**, not a 63 kA *typical class* — Rev2 compared against a textbook figure while the nameplate was in the project. (ii) A breaker's duty is the current **through it**, not the bus total: at a 22 kV bus fault the GCB carries *either* the machine contribution *or* the system contribution, not their sum, so the ≈122 kA bus figure is an **IPB/bus withstand** quantity, not a breaker duty. On Rev2's own split the through-current is ≈55 kA (machine side) or ≈69 kA (system side, `6.59 kA × 230/22`) — both inside 100 kA. Corroboration that the nameplate reads right: `458 MVA / (√3 × 22 kV) = 12.02 kA` ≈ the stated 12.4 kA continuous | `VERIFIED_SOURCE` (rating); through-currents **to be recomputed in D3** — the Rev2 numbers above are indicative only |
| C-38 | **Generator Q-capability curve — is the CYME record template junk?** | Aug **D1/D2**: the whole `GEN1_DATAA` record is diesel-template contamination; Aug **C4**: the Q-curve is *"transcribed from a truncated PSAF record"* with a *"constant lead/lag ratio"* red flag | The `Q_CURVE` blob holds **six plant-scale points**: `(1, 332.3, −228.7) (100, 326.7, −225.2) (200, 308.8, −213.1) (300, 278.6, −192.5) (389.2, 239.4, −167.1) (432, 152, —)`. The diesel template's curve is a single trivial point `{1.0; 1.0; −1.0}` | **Split the verdict — Aug conflated two different fields.** The **scalars** `QMAX 0.653 / QMIN −0.131 / RGROUND 730 / XGROUND 0.100` are byte-identical to the template and confirmed junk (0.653 MVAr = **0.143 %** of a 458 MVA machine). The **curve is not**: `hypot(389.2, 239.4) = 456.93 MVA` and `hypot(432, 152) = 457.96 MVA` sit on the 458 MVA stator circle to **0.23 %** and **0.01 %**, and the lower-P points fall progressively *inside* it (332 → 409 MVA) — the signature of a **rotor field-current limit**, which a one-point template cannot produce. Aug's "constant ratio" flag is also overstated: the ratio drifts 0.6882 → 0.6980 (**1.42 %**). **Treatment:** Q limits stay **`MISSING`** as the primary case (the source page is absent, so the curve is a transcription of something I cannot see); the 6-point curve is retained as a **documented sensitivity case** per the spec's *"retain the alternative as a sensitivity case where useful"* | `ENGINEER_DERIVED` (curve) + `ASSUMPTION-JUNK` (scalars); primary treatment `MISSING` |
| C-39 | **Auxiliary load 14 MW — the validation is circular** | Aug `load_flow_readiness.md` validation table: *"MV motor table sum: 9050 + 2500 + 2500 ✔ = 14 050 kW ≈ the form's 14 MW"*, listed under **"checks already performed and passed"** | The two sides are **not independent**: the MV motor table is Tier-1 (Rev 03 SLD); the 14 MW is Tier-3 (engineer-filled Google Form) which Aug's **own** `source_inventory.md` says contains *"several transcription errors"*. They agree to **0.36 %** | **This is the same error class Aug correctly identified for the 50 kA grid figure** (§4.6) — one datum checked against a copy of itself. Three consequences, all of which matter to D2: (i) if the form copied the table, 14 MW is **rated shaft power**, so electrical input is **14.485–14.789 MW** at η 0.97–0.95; (ii) it is a **nameplate sum**, not a running demand — actual load is lower and motor running/standby status is unknown; (iii) **all 400 V board load is excluded** (five boards, no documented load). Record 14 MW as a **`ENGINEER_DERIVED` aggregate with an explicit ±6 % band**, never as a measured plant demand | `ENGINEER_DERIVED` — supersedes Aug's ✔ |
| C-40 | **Rev2's grid series resistance was almost certainly inert** | Rev2 grid equivalent entered as `R 0.268 Ω / X 2.940 Ω`; Aug assumption file `grid_series_resistance_zero.m` records R = 0 as an **approved active assumption** | Aug **B1**: the grid equivalent is a **pure inductance**. Aug **B10**: on a Series RLC Branch, `BranchType = 'L'` makes the `Resistance` field **silently inert** — `'RL'` is required | **Whatever R was typed, the solved network enforced R = 0.** So Rev2's stated grid R and the approved R = 0 assumption produce the *same* model, and Rev2's R was never a modelling choice — it was a dialog entry with no effect. This is not cosmetic: at the boundary the flow is **+3.745 pu P against −0.297 pu Q, i.e. 12.6 : 1**, so in `ΔV ≈ (RP + XQ)/V` the **R·P term dominates X·Q**. The *assumed* R therefore has more leverage on boundary voltage than the *estimated* \|Z\|. **D1 must set `BranchType = 'RL'` and assert it after every build** | Rev3 **fail-loud condition**; feeds the §4.8 decision |
| C-41 | **`generator_voltage_setpoint.m` reaches the model through an unregistered path** | Aug `load_flow_readiness.md`: the file is *"disclosed, not approved — **not registered in `D.assumptions`**"* | …*"the value the model uses comes from **`D.gen(1).Vset_pu`**"* — i.e. the number enters the solver from the data struct while the assumption record sits outside the registry | **This is precisely the failure mode PART C exists to prevent**: an assumed value with no registry record steering every voltage in the study, because the generator setpoint is the datum every other bus voltage is measured against. In Rev3 the param-record constructor must **reject any solver input lacking a registry record** — this specific case is the regression test for that check. Note this is *also* C-32 (the setpoint's *value* awaits the user); C-41 is the separate defect that its *provenance path* is broken | `ASSUMPTION`, unregistered — **blocking for C1** |
| C-42 | **The GAT closes a loop Rev2 never exercised** | Rev2 **FINDING F1**: 6.6 kV bus voltage *"LOW in **all radial cases**"* | Aug `topology_validation.md` §3: *"Loop if GAT in service — **YES** — 22 kV → GSUT → 230 kV GIS → GAT → 6.6 kV → UAT → back to 22 kV. A genuine closed loop"*; and *"the 6.6 kV bus voltage is set by **two** transformers with **different** tap changers"* | **F1's scope is narrower than it reads** — it is a property of the radial subset, not of the plant. Two independent corrections push the same way: (i) the **inverted tap** (§2B) — the correct ratio is `a = 6.9/6.6 = 1.04545`, which alone moves the bus to ≈1.0014 pu; (ii) in the **looped** configuration the bus is supported from both sides. **F1 may vanish entirely.** Per the spec — *"when a result changes after a correction, do not force it back toward the old answer"* — the loop case is a first-class LF case, not a variant. GAT in-service state is **Q4, still open**, so **both** configurations run | Rev2 F1 **scope-limited**; loop case mandatory in D2 |
| C-43 | **Bus-coupler rating vs transformer-bay rating — independent confirmation of C-36** | Rev2 **FINDING F3**: coupler loading = `860 A / 3150 A = 27.3 %` | Aug: **coupler module = 3150 A**; **transformer bay = 2000 A** — two *different* module ratings in the same GIS | **A rating mismatch proves C-36 by a second route**: the CB datasheet is headed `TRANSFORMER BAY` and its item 7 reads 2000 A, so it **cannot** be describing a 3150 A coupler module — the sheet and the coupler are different equipment. This also undercuts F3's arithmetic: against the only *documented* bay rating the same 860 A is **43.0 %**, and the **line-bay rating remains undocumented**. F3's *conclusion* (the coupler is lightly loaded) survives; its *number* does not | `VERIFIED_SOURCE` (both ratings); F3 figure superseded |
| C-44 | **Aug B9's loss decomposition is a two-way agreement presented as three-way** | Aug **B9** offers three routes to the same iron/copper split: `.rep` (0.19 + 0.64 = 0.83), hand split (iron 0.1937 + copper 0.6194), study `Ploss = 0.83326 MW` | Re-derived independently: **`0.1937 + 0.6194 = 0.8131`, not 0.83326 — a gap of 0.02016 MW = 20.16 kW (2.4 %)**. The `.rep` route agrees **only because `.rep` prints to 2 dp**, which can resolve no better than ±5 kW | **Two of the three routes are the same route.** The independent leg does hold: GAT-de-energised `23 kW × 0.958² = 21.109 kW` vs the stated **21.1 kW** ✔ — so **B9's conclusion stands (Rm *is* in the network; spec OPTION A is already implemented and must not be rebuilt)**, while **B9's arithmetic does not close**. Working hypothesis, flagged as a hypothesis and **not** asserted: a third-transformer iron term near **0.9362 pu** (`√(20.16/23)`); substituting the quoted 21.10 kW overshoots by 0.94 kW. **D2 must re-derive the full split from the solved network and print all three terms**, not inherit this one | **defect in the August document**, found by my own numeric check — see §6 |
| C-45 | **GSUT extreme-tap impedance assignment** | Open in both Rev2 and the August set: the datasheet's three values `{15.5, 16.0, 16.9 %}` were known, but **which extreme carried which** was stated nowhere, and §7 had it queued for an image read. §3.7a (earlier today) listed **both permutations as sensitivity cases** | `GSUT Data Sheet_South.pdf` text layer, realigned on the units column (§3.2a): **lower tap (minimum voltage, 184 kV, pos 25) = 15.5 %**; main tap 230 kV = 16.0 %; **higher tap (maximum voltage, 253 kV, pos 1) = 16.9 %**. Resistive component **0.28 / 0.21 / 0.21 %**. The min/max direction is **parenthesised in the datasheet itself**, not inferred | **CLOSED — no image needed**, by the same method as C-23. The literal column reading is rejected on **four** simultaneous absurdities (main-tap Z blank, R = 16 %, Z₀ blank, tolerance = 0.28); the offset reading lands **three already-verified values** (16.0, 0.21, 15.8) on their own labels and reproduces `X/R = 76.18` vs the verified 76.2. The datasheet's own `√(Z²−R²)` closes at all three taps to 5 dp. **This supersedes §3.7a's two-permutation sensitivity case** — but substitutes a real one: `R` is tap-dependent while `X` is not, so **`X/R` swings ≈55 (184 kV tap) to ≈80 (253 kV tap)** and the IEC 60909 asymmetrical duty depends on tap position | `VERIFIED_SOURCE` |
| C-46 | **GAT 3.32 kV winding — stabilizing winding or loaded tertiary?** | §7 carried it as *"the GAT tertiary must be **explicitly marked unavailable** in the zero-sequence model"*; the master md lists the GAT as `230/6.9/3.32 kV`, a three-winding form that reads as a **loaded tertiary** | **Rating plate p. 4 terminal box** (§3.9d): ends `aw1/aw2 bw1/bw2 cw1/cw2` joined by external links **aw1–bw2, bw1–cw2, cw1–aw2**, with an **earth symbol on the cw1/aw2 node**; only `cw1` and `aw2` are brought out as bushings. Insulation row **"Stabilizing winding, Um 3.6 / BIL 40 / AC 10"** names it outright | **SOURCE-PROVEN stabilizing winding.** Three binding consequences for D3: (i) it is **not** a load-carrying tertiary — there is no three-phase take-off; (ii) it **must** be modelled as a **real closed-delta circulating path** in the zero-sequence network, because a delta short-circuits zero-sequence mmf whether loaded or not — "marking it unavailable" would **overstate** the GAT's `Z0`; (iii) the single earthed corner is a **potential reference only** and carries **no steady-state zero-sequence return current**, so it must **never** appear as an earth-fault current source at 3.32 kV. §7's instruction is superseded in its *modelling* part while its *impedance* part stands (C-51) | `VERIFIED_SOURCE` |
| C-47 | **What base is the UAT `Z = 10.5 %` on?** | §3.3 states *"`Z` main tap (**25 MVA base**) = 10.5 %"* — correct, but resting on the CTI datasheet's own header alone, with the 19/25 dual rating making the other reading available | **Rating plate p. 3 column headers**, read verbatim: **"Load loss (at 25 MVA)"** and **"HV-LV Impedance (at 25 MVA)"** | **Corroborated by a second tier-1 document.** The qualifier is printed on the plate, so `10.5 %` is unambiguously on the **25 MVA ONAF** base. Reading it as a 19 MVA quantity would scale `Z` by `25/19 = 1.316` — a **31.6 % error** on the UAT branch. Registry must store `S_base_own = 25 MVA` explicitly, never "rated" | `VERIFIED_SOURCE` |
| C-48 | **UAT plate "Max. system short-circuit power HV/LV = 6600 / 500 MVA"** | Nothing in Rev2 or the August set records a 22 kV design fault level; the 22 kV bus fault level exists only as a *computed* quantity | Rating plate p. 3. **6600 MVA @ 22 kV → `Ik = 173.2 kA`.** Computed plant level: generator `458/0.2248 = 2037 MVA` + GSUT `460/0.16 = 2875 MVA` ≈ **4915 MVA ≈ 129 kA**, ≈142 kA at `c = 1.10` | **A manufacturer DESIGN ENVELOPE, ~20 % above the computed level — not a measured plant fault level.** Recorded as an *order-of-magnitude corroboration* for D3's B01 result and as a **transformer through-fault design basis**, never as a source value for the 22 kV bus. Same class of quantity as C-35 (GSUT plate, 21 218 / 3950 MVA) and as §4.7 — this is now the **third** instance, so the §8 rating-class rule applies verbatim. The **LV 500 MVA** figure is exactly the **IEC 60076-5 Table 1** standard value for Um 7.2 kV; the HV 6600 MVA is **not** the table value for Um 24 kV and is therefore project-specific | `VERIFIED_SOURCE` (as a design basis) |
| C-49 | **CT accuracy class `ATR3`** | No prior registry carries it; the August CT list gives only the 5P20 and Cl 0.2 cores | Both plates, read at 2× zoom: **`ATR3`** appears on the GAT HV-V (`LR-245 80/2`), GAT LV-S (`LRB-24 2300/2`) and UAT LV-S (`LR-7.2 2300/2`) cores — **every one of them single-phase, `/2` secondary, 20 VA**. It is **not** an IEC 61869-2 accuracy class | Recorded **verbatim** with status `UNKNOWN` (manufacturer designation). The placement is consistent with **thermal-image / winding-temperature-indicator** duty rather than protection or metering, but that is an **inference and is labelled as one**. **These cores are excluded from the D4 protection CT registry** — an unknown class must not be assigned an ALF. Note also the deliberate UAT `Cl 0.2 Fs10` vs GAT `Cl 0.2S **Fs10**` difference, confirmed at magnification | `UNKNOWN` |
| C-50 | **GAT HV neutral CT — absent from every prior registry** | Rev2 and the August CT list have **no GAT neutral CT**; GAT neutral current would have to be derived from the three phase CTs | Rating plate p. 4 CT table: **`T6`, type `LRB-126`, ratio `250/1`, S1-S2, `15 VA 5P20`, location HV-N**. The GAT HV CT row is also refined: **`T1 LRB-245`, `500, 250/1`, taps `S1-S2` / `S1-S3`** — a dual-ratio CT, which is what the GIS drawing's `500-250/1A` (C-17 vintage) was recording in compressed form | **New verified protection CT.** D4 must set GAT `51N` and restricted earth fault (`87N`) from **T6** rather than from a residual connection of the phase CTs — a dedicated neutral CT has no phase-CT mismatch error and a different ALF. The dual-ratio T1 also means the GAT `87T` HV-side ratio is a **selectable** 500/1 or 250/1; the selected tap is **not stated on the plate** and stays `UNKNOWN` pending a relay setting record | `VERIFIED_SOURCE` (CT data); tap selection `UNKNOWN` |
| C-51 | **GAT pairwise `Z_PT` / `Z_ST` — is the plate a source for them?** | §7 *"Known `MISSING`"*: *"GAT pairwise `Z_PT`/`Z_ST` — Rev2 honestly flagged these; **no source found**"*. Until the plate was read, this was an **absence of search**, not an established absence | Rating plate p. 4 carries **exactly one impedance column, "HV-LV"** — there are **no HV-Stab or LV-Stab columns at all** — and even that column is **blank** (§3.9f), as are Load loss, No-load loss, No-load current, oil type and temperature rise, on **both** plates. These are rating-plate *drawings*; test-dependent values are stamped after factory test | **`MISSING` is now POSITIVELY EVIDENCED, not merely unfound.** The last plausible source in the document set has been checked and does not carry them. D3 must therefore derive the GAT three-winding star equivalent from `Z_PS` alone plus a **declared assumption** for the stabilizing-winding leg, and say so in the same sentence as the result. A second consequence: the plates **cannot corroborate or contradict** the CTI datasheet's `Z` and loss figures at all, so §3.3 stands on the datasheet alone — a fact now documented rather than assumed | `MISSING` (evidenced) |

### 4.5 C-05 in detail — the IEC 60909 voltage-factor defect (new, previously undetected)

The 2019 secondary dataset reports three numbers for ASHUGANJ S 230 kV: `Ik'' = 45.01 kA`, `‖Z‖ = 3.25 Ω`,
`X/R = 10.99`. Rev2 and the master md treated the first two as mutually contradictory and logged the
discrepancy without resolving it. **They are not contradictory — they are consistent under IEC 60909 with the
HV voltage factor `c_max = 1.10`:**

```
‖Z‖ implied by Ik'' at c = 1.0        = 2.9502 Ω
c required to reconcile ‖Z‖ = 3.25    = 1.1016      ←  IEC 60909 HV c_max = 1.10
Ik'' from ‖Z‖ = 3.25 at c = 1.10      = 44.944 kA   (reported 45.01, −0.15 %)
```

The master md silently applied **c = 1.0** — producing `R = 0.268`, `X = 2.940` (‖Z‖ = 2.9522 Ω) —
**while its own text says "use source-reported value Z = 3.25 Ω"**. Rev2 inherited this
(`D.grid.Rth_ohm = 0.268`, `Xth_ohm = 2.94`, with `Zmag_reported_ohm = 3.25` sitting unused alongside).

**Net effect: grid impedance understated by 10.09 % — the grid was modelled ~10 % too stiff.**

Correct decomposition at `X/R = 10.99`:

```
R = 0.29451 Ω    X = 3.23663 Ω     (‖Z‖ = 3.25000, X/R = 10.990)
pu on 100 MVA / 230 kV (Zbase 529 Ω):   R = 0.000557    X = 0.006118
```

Reference B (Siemens Rpt §2.4) is internally consistent at c = 1.0 and verifies to the digit:
`XN = 230000/(√3 × 50000) = 2.6558 Ω` (report: 2.66); `Sk'' = √3 × 230 kV × 50 kA = 19 918.6 MVA`
(report: 19 919). It is a **stiffer** grid than Reference A by a factor **1.224** on ‖Z‖ → ideal
sensitivity case.

### 4.6 "50 kA" appears in FIVE distinct roles — keep them apart

| Role | Document | Meaning |
|---|---|---|
| 1 | Siemens Gen Prot Rpt §2.4 | **estimated grid** `Ik''` — explicitly *"estimated"*, *"of the grid"* |
| 2 | GIS drawing `BUS 1 … 230kV, 3150A, 50kA` + DS datasheet | **equipment short-time withstand** (now known to be **1 s *and* 3 s**) |
| 3 | GSUT datasheet | *"50 kA short circuit maximum current for 230 kV"* — **transformer design basis** |
| 4 | GAT datasheet | same — transformer design basis |
| 5 | **CB datasheet (new)** | **rated symmetrical / asymmetrical interrupting current** of the breaker — an *interrupting* duty, not a withstand |

Roles 2 and 5 are the pair most easily conflated and were conflated in Rev2's duty table
(*"50kA withstand (B) / 50kA interrupting ASSUMED (C)"*). They are numerically equal here but are
**different ratings under different standards** — short-time withstand is thermal (IEC 62271-1), rated
symmetrical interrupting is a switching duty (IEC 62271-100). Rev3 must state which one each verdict is against.

Per the governing instruction, Rev3 must **not** say "50 kA is the GIS withstand rating" when quoting the
Siemens grid estimate, and must not say the grid estimate is a measured PGCB commissioning level.
**Reportable inference (as inference, not fact):** the coincidence suggests the Siemens grid estimate was
taken at the switchgear design ceiling rather than from a network study.

**APSCL answered `[Contact PGCB]` for `S_sc`, `Z_grid1` and `Z_grid0`** — documentary proof that **no official
PGCB fault level exists in the source set.** This vindicates treating 45.01 kA as the best available
*secondary* equivalent, and forbids calling any grid figure "measured".

### 4.7 Independent design-basis cross-check for the fault study

The transformer datasheets give short-circuit design bases that bracket the calculated 22 kV fault level:

- GSUT: `95 kA` @22 kV. Reconstruction — grid through GSUT with an infinite 230 kV source at c = 1.1:
  `1.1/0.03107 × 2624.3 A = 92.9 kA`. **Agrees within 2.2 %.**
- UAT: `157 kA` @22 kV ≈ **prospective bus fault** = generator (≈58.8 kA at c = 1.1) + grid through GSUT
  (≈92.9 kA) ≈ 152 kA.

These are complementary, not contradictory: one is a **through-fault** basis, the other a **prospective
bus-fault** basis. **Rev2's `B01 LLL ≈ 122.36 kA` is therefore credible and sits inside the 157 kA design
basis** — the three-phase result survives the audit even though the earth-fault result does not.

### 4.8 C-31 — the grid equivalent now has THREE live candidates, one of them user-approved

This is the single most important thing the August reconciliation changes, because **the user already made a
decision here that Rev2 silently overrode and that my §4.5 analysis would override again.**

| # | R (Ω) | X (Ω) | ‖Z‖ (Ω) | Basis | Standing |
|---|---|---|---|---|---|
| 1 | **0** | **2.6558** | 2.6558 | Ref B — Siemens Rpt §2.4, `Ik'' = 50 kA` *estimated*, at c = 1.0 | **user-approved 2026-08-17 as answer Q1a**, enforced by `assert(G.R_ohm == 0)` |
| 2 | 0.268 | 2.940 | 2.9522 | Ref A — 2019 compilation, `Ik'' = 45.01 kA`, at **c = 1.0** | Rev2's value. Contradicts its own source text (§4.5) |
| 3 | **0.29451** | **3.23663** | 3.2500 | Ref A at **c = 1.10** (IEC 60909 HV `c_max`) | my §4.5 reconstruction — internally consistent, but **not yet put to the user** |

The user's stated reason for #1: *"We don't have verified PGCB grid strength. Use the available 2.656 Ω only
as an explicitly labelled estimate, not as verified data."* August then **declined a later instruction** to
substitute an IEEE-standard X/R, on the grounds that it would overwrite an explicit approval and that the
citation could not be verified in-session — and published an X/R sweep (∞, 20, 10, 5) instead.

**Why this cannot be resolved silently:** August's own executed sensitivity shows the *assumed* R matters more
than the *estimated* ‖Z‖ at this plant —

- moving X/R from ∞ to 10 shifts the boundary voltage `1.62e-03 pu`; **doubling** ‖Z‖ shifts it `1.27e-03 pu`
- at X/R = 10 the Thevenin equivalent dissipates **0.704 MW**, comparable to the plant's entire 0.816 MW loss
- `Qgen` falls **16.8 %** (X/R = 10) to **33.3 %** (X/R = 5) versus R = 0

Mechanism (August's, verified): the plant delivers `+3.745 pu` of P against `−0.297 pu` of Q at the boundary,
a **12.6 : 1** ratio, so the `R·P` term dominates `X·Q` and the usual mostly-reactive intuition inverts.

**Consequence for Rev3, and it is a governance point, not a numerical one:** adopting #3 means *superseding a
user approval*. Per the governing instruction — *"If two sources conflict: do NOT silently choose one"* — Rev3
will carry **#1 as the approved base**, present **#3 as the IEC-consistent reconstruction with its arithmetic**,
retain **#2 only as the Rev2 historical value**, and put the choice to the user. It also forces the
**OPTION A / OPTION B loss-accounting decision**: grid-equivalent dissipation is *not* a plant loss, so if any
non-zero R is adopted, "total system loss" must be reported in separate categories or it stops meaning anything.

### 4.9 ID mapping — Rev3 `C-nn` ↔ August `Cn` (no renumbering of the older scheme)

| Rev3 | August | Topic | Relationship |
|---|---|---|---|
| C-01 | **C5** | generator earthing | **independent agreement** — both reach high-resistance NER; Aug additionally proves Rev2's `730/0.1 Ω` is a byte-for-byte **diesel-library template** artefact |
| C-04, C-33 | **C11** | auxiliary demand | Aug is **stronger**: 14 MW coincides with the 14 050 kW rated motor sum to 0.4 %, so its provenance is *ambiguous* (measured? rated sum? baseline?) and must not be called measured. **Refined 2026-09-12 → C-39:** `conflicting_parameters.md` draws exactly the right inference from that coincidence, but `load_flow_readiness.md` lists the *same* comparison as a **passed validation check** ✔. The two August documents disagree with each other; C-11's reading is the correct one |
| C-05, C-31 | **C14** | grid strength | Aug reached the same *"50 kA = the GIS withstand, not a measurement"* inference **first** |
| C-06/C-07 | **C14** | the 50 kA roles | same conclusion, independently |
| C-08 | **C2** | 389.30 vs 342.01 MW | **identical treatment** — different quantities, both preserved, neither measured |
| C-10 | **C4** | generator Q limits | Aug **supersedes** mine → C-34 |
| C-11, C-12 | — | GAT/GSUT R% | mine, resolved arithmetically; Aug carries the datasheet values only |
| C-16 | **C1** | GSUT tap step | **identical** — 1.25 %/step proved from the plate; form's 1.15 % is a typo |
| C-17 | — | `10BAY20` | mine |
| C-19 | — | UAT HV CT | **closed by Aug §9** → C-30 |
| C-20 | **A3** | bus coupler | Aug records it as a **user-approved assumption (Q9a)**, with the *same* qualifier I derived independently |
| C-21 | — | bay vs busbar rating | mine |
| C-22…C-27 | Aug §5 | GIS datasheet | **Aug mined this file in August** — see §1.1b correction |
| C-23 | Aug §5 | breaking time | Aug recorded `54 + 6 ms` as *"CB total breaking time"*. **Mine refines Aug**: the units-column alignment shows `54 + 6` is the *maximum* breaking time, the *offered* total is 45.7–48.4 ms, and the **opening** time is 33 ± 3 ms — which is the quantity IEC 60909 `t_min` actually needs |
| C-36 | — | CB datasheet covers only the transformer bay | **mine, new** — neither Aug §5 nor Rev2 noticed that all six CB pages are one transformer-bay sheet |
| C-28 | — | **inverted tap ratio** | **mine, new** — Aug's model has it right but never states the direction as a finding |
| C-29 | **C3** | generator CT 16000/1 | **Aug corrects me** |
| C-32 | **A5** | generator V setpoint | Aug flags it **unapproved**; Rev2 buried it as status `C` |
| C-35 | **C15** | plate-vs-datasheet drift | same pattern |
| C-38 | **C4 / D1 / D2** | Q-capability curve vs the `QMAX/QMIN` scalars | **mine refines Aug, and partly disagrees.** Aug treats the whole `GEN1_DATAA` record as template contamination; the *scalars* are (byte-identical), but the *curve* carries six plant-scale points whose top two land on the 458 MVA stator circle to 0.23 % / 0.01 %. Aug's "constant lead/lag ratio" red flag is overstated — it drifts 1.42 %. Primary treatment is unchanged (`MISSING`); the curve becomes a sensitivity case |
| C-39 | **C11 vs `load_flow_readiness.md`** | the aux-load check is circular | **mine, new** — and it is an **internal inconsistency between two August documents** (see the C-04/C-33 row above). Same error class Aug itself identified for the 50 kA figure |
| C-40 | **B1 + B10 combined** | Rev2's grid R was silently inert | **mine, new** — both halves are Aug's measured facts, but Aug never joins them. The join is what shows Rev2's entered `R = 0.268 Ω` never reached the solved network, and that the §4.8 decision bites hardest exactly where R·P dominates X·Q (12.6 : 1) |
| C-41 | **A5** | `Vset_pu` bypasses the assumption registry | **mine, new, from Aug's own text.** Aug discloses the file is unregistered *and* that the model reads `D.gen(1).Vset_pu`; the **defect is the conjunction**. Distinct from C-32, which is about the *value* |
| C-42 | **`topology_validation.md` §3** | the GAT loop vs Rev2 FINDING F1 | Aug **identifies the loop**; the consequence for F1 is **mine** — F1 is scoped to the radial subset and may vanish once the loop and the corrected tap direction (C-28) are both applied |
| C-43 | **C-36 (mine) + Aug ratings** | coupler 3150 A vs transformer bay 2000 A | **mine, new** — a rating mismatch that confirms C-36 by a second, independent route and supersedes Rev2 F3's 27.3 % figure |
| C-44 | **B9** | the iron/copper loss split does not close | **mine, new — a defect in the August document**, located by re-deriving B9's own arithmetic: 20.16 kW short, with the `.rep` leg agreeing only to the 2 dp it prints. B9's *conclusion* survives on the independent GAT-out leg; its *numbers* must be re-derived in D2 |
| — | **C8, C12, C18** | prior-PSAF defects (wrong UAT type, orphan buses, **60 Hz**) | Aug only; not re-derived here. Rev3 inherits S10: PSAF is not a data source |
| — | **C9** | GAT exists but is absent from the prior model | Aug only; Rev3 models GAT explicitly |
| — | **C16** | Excel workbook carries Rev 00 values while citing Rev 03 | Aug only; **pre-empts my planned xlsx audit (A7)** |
| — | **C13** | 400 kV block is North | Aug only; scope already excluded, and this **corroborates §1.1b** |

**Governance:** the August IDs are the *older* scheme and are cited by `data/master/Ashuganj_Master_Data.csv`.
Rev3 keeps both and maps them; it does **not** renumber August's.

---

## 5. Defects confirmed in existing code (preserve what is right, fix what is not)

**`rev2/data/ashuganj_rev2_registry.m`**
- `G.Earthing = 'Solidly grounded'` → **C-01, fatal to all earth-fault results**
- `G.X0 = 0.1280`, `G.X2 = 0.2242` invented → **C-02**
- `T.Z1_pu_own = 0.1663` → **C-14**
- `D.aux.P_MW = 12; D.aux.Q_MVAr = 5` → **C-04**
- `D.grid.Rth_ohm/Xth_ohm` at c = 1.0 → **C-05**
- `D.br023.R_pu = D.line07.R_pu + D.grid.R_pu` — line and Thevenin **lumped into one branch**, so B02 and B03
  collapse to the same node. Rev3 needs them separate (this is also why Rev2's Simulink had to treat B03 ≡ B02).
- **Preserve:** `GT.Zpt_Status = GT.Zst_Status = 'MISSING'` (honest and correct — and now **positively
  evidenced** by the rating plate, **C-51**).
- **Do NOT preserve `U.a_LV = GT.a_LV = 6.6/6.9`.** An earlier draft of this line said to preserve it; that was
  wrong and contradicted §2B / C-28 two sections above it. The constant is **inverted** — Rev3 uses
  `a = 6.9/6.6 = 1.04545`. What is worth preserving is the *stamp*, `Y_ii = y, Y_jj = y/a², Y_ij = −y/a`,
  which is correct (see `run_phase1_loadflow.m` below); only the value of `a` is wrong.

**`rev2/run_phase1_loadflow.m`** — architecture is sound (polar NR, 4-bus, off-nominal tap handled correctly as
`Y_ii = y`, `Y_jj = y/a²`, `Y_ij = −y/a`; converges in 5 iterations, mismatch < 6e-14). Defects:
- **No magnetizing/shunt branches anywhere** (only line charging `1j·Bln/2`) — so any core-loss figure added
  during reporting is **phantom**. Rev3 adopts **OPTION A**: model the branches (data now available, §6[C]).
- Branch currents (`Igs_HV`, UAT, GAT) computed with **nominal kV instead of the solved `V(b)`**
- `pfgen` computed but never used; generator Q limits never enforced; B04/B05 dead
- `phase1_registry_snapshot.txt` **hardcodes a duplicate data string** — a second source of truth
- only 4 buses → no BB1/BB2, no coupler, no separate circuits

**`rev2/run_phase2_fault.m` / `seq_networks.m`** — sequence architecture is reusable; the **zero-sequence
network must be rebuilt** (C-01/C-02). Also a reporting defect: contributions are printed in one column at
**mixed voltages** — `Igen 54.82 kA` is at 22 kV while `Igrid 6.59 kA` is at 230 kV
(`6.59 × 230/22 = 68.9 kA`; `54.82 + 68.9 ≈ 123.7 ≈` the 122.36 kA total). **Rev3 must report all
contributions at the fault-point voltage.**

**`matlab/data/ashuganj_grid.m`** — `G.Isc_Source` provenance claim is wrong (**C-07**); `G.XR_ratio = inf`,
`G.R_ohm = 0` discards the available `X/R`. Its assertions *force* `Isc_Status = 'ESTIMATED'`, which is
honest and worth keeping in spirit.

**Dynamic study** — **none exists anywhere in the project.** The changelog must therefore say Rev3 **built**
it, not that Rev3 *fixed* it.

### 5.1 Defects in the Rev3 extraction tooling itself (`tmp/`) — all found by reading the output, none by an error

These are recorded because the tools are reusable and every one of these failures was **silent**: the code
returned successfully with wrong data. They are the reason §3.9's transcription was done **twice**.

| # | Defect | Why it was silent | Fix |
|---|---|---|---|
| T1 | `java.nio.file.Paths.get` → *"No method with matching signature found"* | not silent — but the method is **varargs**, which MATLAB's Java bridge cannot dispatch at all | abandon `java.nio.file`; use plain `java.io` streams |
| T2 | **Inflate produced 2 391 139 bytes of pure zeros** | a `byte[]` from `java.lang.reflect.Array.newInstance` is **auto-converted to a MATLAB `int8` array**, so `iis.read(buf)` filled a *copy* on the Java side while the MATLAB-side buffer stayed zero. No error, no warning, correct byte count | keep the whole transfer **inside Java**; plus a permanent guard in `pdf_inflate_obj.m` that **hard-errors** if the first 64 kB inflate to all-zero |
| T3 | `InputStream.transferTo` undefined | Java 9+; this JVM is older | two-level fallback: `com.mathworks.mlwidgets.io.InterruptibleStreamCopier` → `FileChannel.transferFrom` |
| T4 | Page-4 geometry bbox exploded to `x 9.0 … 6.69e9` | the inline-image excision searched for the literal `'BI '` and matched **zero** occurrences, because this producer writes `BI\n`. Inline-image **binary** was then tokenised as junk *numbers*, and one of them reached `cm` and corrupted the CTM | anchor on `ID`/`EI` with lookaround regex. Both pages now give bbox `x 9.0…1674.6, y 14.4…2370.1`; `Q`-underflow fell 8/7 → **0** |
| T5 | **~64 % of all strokes silently dropped** — *"Transf Type"* rendered *"⁻ransf ⁻ype"*, *"HV"* as *"IV"*, *"Rated"* as *"Pa ed"* | a PDF path may hold **many subpaths**: `m` starts a new one **without painting the previous**, and one paint operator paints them all. AutoCAD SHX stroked text is exactly this — one path per glyph, one **subpath per pen stroke**, a single `S`. Resetting `cur` on `m` therefore kept only the last stroke of every glyph | accumulate subpaths; verify by **exact accounting**: strokes 5 680 → **15 827** (p3) and 6 002 → **16 019** (p4), and `strokes + fills = subpaths` exactly (15 827 + 3 594 = 19 421; 16 019 + 3 594 = 19 613) |
| T6 | All 12 renders failed: *"Unable to create output file `tmp\p3_full.png`"* | **MATLAB's `run()` changes the current folder to the script's folder**, so `fullfile('tmp', name)` resolved to `tmp/tmp/`. The give-away was an `addpath` warning naming `…\tmp\tmp` | derive `outdir = fileparts(mfilename('fullpath'))`; **never** use a relative path inside a script invoked via `run()` |

**T5 is the important one, and it is the reason for a rule, not just a fix.** A dropped pen stroke does not
produce a blank or a glyph-not-found box — it produces **a different, perfectly legible character**. An `8`
can render as a `3`, a `6` as a `5`. Nothing in the pipeline can detect this; only reading the output and
noticing that a *word* is misspelt reveals that the *digits* are untrustworthy. Every value transcribed from
the first render was therefore discarded and re-read from the corrected one — including values that happened
to be right. **Where a renderer is in the evidence path, a legibility check on known text is mandatory before
any number is transcribed.**

One hypothesis of mine was **refuted** along the way and is recorded so it is not re-adopted: I attributed the
first render's spill to an ignored AutoCAD **viewport clip** and implemented clipping (`W`/`W*`). The corrected
parse reports **`nClip = 0`** — there are **no `W` operators in these files at all**. The clip code is
harmless, but its stated justification was wrong; the real cause was T4. **The stale justification survived in
`pdf_parse_vector.m`'s own header for two weeks after the parse had refuted it, and was corrected on
2026-09-13** — a refuted hypothesis has to be removed from the *code comment* as well as the write-up, or the
next reader of the file re-adopts it.

---

## 6. Executed verification

Scripts: `tmp/rev3_partA_checks.m`, `tmp/rev3_partA_followup.m`, `tmp/rev3_grid_check.m`,
`tmp/rev3_a4_numeric_checks.m` (§6.1), `tmp/rev3_plate_numeric_checks.m` (§6.2).
Run with `matlab -batch`. **Every number quoted in §2–§4 is computed output, not assertion.**

> **`tmp/` is not scratch and must not be swept while PART A is open.** It holds the only working PDF
> vector-extraction toolchain on this machine (`pdf_inflate_obj.m`, `pdf_parse_vector.m`, `pdf_draw_vector.m`),
> the cached page geometry (`geom_p3.mat`, `geom_p4.mat`), the render scripts, the ~40 PNG crops that are the
> *evidence* behind §3.6 / §3.9, and all five verification scripts above. Deleting it would make every plate and
> datasheet finding unreproducible. Durable *outputs* are copied to `docs/validation/rev3/`; the tooling itself
> stays here until the audit phase is closed and E1 gives it a permanent home.

Closures that passed exactly or within stated tolerance:

| Check | Result |
|---|---|
| `458 × 0.85` vs `PN 389.30 MW` | **exact** |
| `458/(√3×22)` vs `IN 12 019 A` | +0.003 % |
| `518/(√3×20.9)` vs `Imax 14 309 A` | +0.003 % → **explains the −5 % offset** |
| `√(458²−389.3²)` vs `Q 241 MVAr` | +0.11 % → Q is derived, not a capability limit |
| NER `(22k/√3)/500` vs `TRU 25.4` | +0.013 % |
| NER duty 92.1 kVA vs 135 kVA plate | 68 % → design confirmed |
| GSUT `IN` HV & LV at 515 MVA | **both exact** (1292.8 / 13 515.2 A) |
| GSUT loss closure `1095+159+28` | **= 1282 kW exact** |
| GSUT `R` from load loss vs 0.21 % | +1.2 % → **C-12 closed** |
| GSUT 22 kV through-fault vs `95 kA` basis | 92.9 kA, −2.2 % |
| UAT loss closure `110+14+1.25` | **= 125.25 kW exact** |
| GAT loss closure `116+23+1.25` | **= 140.25 kW exact** → establishes `Fe = 23 kW` |
| UAT/GAT load-loss scaling to 19 MVA | 63.5 vs 63.75; 67.0 vs 67.75 kW |
| GAT `R` from load loss | 0.464 % → **rounds to 0.5 %, C-11 closed** |
| Generator VT residual `22000/√3 ÷ (100/3)` | **= 381.05 = `TRU`** |
| Grid `Ik''` from ‖Z‖3.25 at c=1.1 | 44.944 vs 45.01 kA, −0.15 % → **C-05 resolved** |
| Siemens `XN`, `Sk''` | 2.6558 vs 2.66; 19 918.6 vs 19 919 |

Magnetizing branches for **OPTION A** (`Rm = S/P_noload`, `Lm = 1/√(I0² − (1/Rm)²)`, own base):

| | `Rm` (pu) | `Lm` (pu) | own base |
|---|---|---|---|
| GSUT | 3238.99 | 791.89 | 515 MVA |
| UAT | 1785.71 | 339.30 | 25 MVA |
| GAT | 1086.96 | 350.21 | 25 MVA |

UAT matches Rev2's V2 mask exactly (1785.7 / 339.3); GSUT `Lm` matches (791.9) but Rev2's `Rm = 3316.5`
implies `Fe ≈ 155.3 kW` against the datasheet's 159 kW → **C-18**.

### 6.1 A4 verification run — `tmp/rev3_a4_numeric_checks.m` (2026-09-12)

Every claim raised while reconciling the seven remaining validation documents was re-derived from typed-in
source text, never by calling project code, so the check is independent rather than a re-run. Ten blocks:
Q-capability geometry · template scalars · GSUT taps · GAT taps · transformer X/R · aux-load provenance · grid
circularity · equipment ratings · iron-loss branch · IEC 60909 `t_min`.

**Result: every check passed except one, and the exception is a defect in the source document, not in the
arithmetic.**

| Block | Outcome |
|---|---|
| [1] Q-curve on the 458 MVA stator circle | **PASS** — 456.93 and 457.96 MVA (0.23 % / 0.01 %); low-P points inside it → rotor limit → **C-38** |
| [2] `QMAX/QMIN` vs diesel template | **PASS** — byte-identical; 0.653 MVAr = 0.143 % of rating |
| [3] GSUT tap table, 7 checks incl. printed 1616 A | **all PASS**, exact |
| [4] GAT tap table, 5 checks | **all PASS**, exact |
| [5] X/R for all three transformers + GSUT R₀ | **all PASS** (76.19 / 26.24 / 23.98; R₀ 0.2107 %) |
| [6] aux-load provenance and η-corrected input | **PASS** (sum 14.050 MW; S 16.4706 MVA; Q 8.6764 MVAr) → **C-39** |
| [7] grid triple collapses to one datum | **PASS** — `√3·230·50 = 19918.6 MVA`, `230²/S = 2.6558 Ω` → confirms §4.6 |
| [8] generator / GCB / bus / bay ratings, 9 checks | **all PASS** → **C-37**, **C-43** |
| [9] iron + copper vs study `Ploss` | **FAIL — 0.8131 vs 0.83326 MW.** Quantified at **20.16 kW (2.4 %)** in a follow-up run. The independent GAT-out leg passes (`23 × 0.958² = 21.109` vs 21.1 kW) → **C-44** |
| [10] IEC 60909 `t_min` DC decay at X/R = 76.2 | **PASS** — 0.8837 (30 ms) / 0.8307 (45 ms) / 0.7809 (60 ms); shorter `t_min` ⇒ larger DC ⇒ more onerous |

Block [9] is the one that mattered. It was written to *confirm* August's B9 and instead falsified its
arithmetic while leaving its conclusion standing — which is the outcome an independent check exists to produce.
Had the check been built by calling the project's own loss function it would have agreed with itself and found
nothing.

### 6.2 A5 rating-plate verification run — `tmp/rev3_plate_numeric_checks.m` (2026-09-13)

**Result: `26 PASS · 1 DOCUMENTED DEVIATION · 0 FAIL`.** Full log:
`docs/validation/rev3/A5_plate_numeric_checks.log`.

Every input is **typed in from the plate render**; the script reads no project data file, no registry, nothing
under `rev2/` or `matlab/data/`. It therefore verifies §3.9 rather than re-running it.

The §8 standing rule — *"every validation table entry must name the two sources and their tiers, so a
same-source pair is visible on the page rather than buried in the arithmetic"* — is enforced by the script
itself: each block prints its A/B sources and whether the pair is **INDEPENDENT** or **INTERNAL**.

| # | Block | Pairing (A vs B) | Outcome |
|---|---|---|---|
| [1] | GAT tap **voltages** vs `230 ±12×1.25 %` | plate p.4 (tier 1) vs **CTI datasheet** (tier 1, **different document**) → **INDEPENDENT** | **5 PASS**, exact; step 2875 V = 1.2500 %, range ±15.0 % |
| [2] | GAT tap **currents** | plate current column vs plate 25 MVA header + plate voltage column → **INTERNAL** | **5 PASS** (≤0.05 A) |
| [3] | UAT tap voltages | plate vs `22 kV ±2×2.5 %` rule → **INDEPENDENT** | **5 PASS**, exact |
| [3] | UAT tap currents | **INTERNAL** | **4 PASS, 1 DOC** — see below |
| [4] | LV winding `√3·6900·2091.8` | **INTERNAL** (but identical on two separately-drawn plates) | **PASS** — 24.9994 MVA |
| [5] | **Stabilizing winding** `√3·3320·1448.6` | plate winding row vs plate rated-power header — two different fields from different design quantities → **INDEPENDENT** | **PASS** — 8 330 042 VA = 8.3300 MVA |
| [6] | ONAN/ONAF 76 % → 19/25 MVA | plate cooling row vs **CTI datasheet** *"19/25 MVA ONAN/ONAF"* → **INDEPENDENT** | **2 PASS** |
| [7] | UAT `6600/500 MVA` design envelope | 6600 MVA vs machines computed from Siemens Rpt + GSUT datasheet → **INDEPENDENT**; 500 MVA vs **IEC 60076-5 Table 1, Um 7.2 kV** → **INDEPENDENT** | **PASS** — envelope 22.1 % above the `c = 1.10` level (→ **C-48**); LV = the Table 1 value exactly |
| [8] | UAT `Z` base consequence | — | consequence check: `10.50 % @ 25 MVA ≡ 7.980 % @ 19 MVA`; the wrong base **overstates `Z` by 31.6 %** (→ **C-47**) |
| [9] | GAT OLTC span for D1 | — | **2 PASS** — 0.8500 … 1.1500 pu |

**Five of the nine blocks are genuinely INDEPENDENT.** Four are INTERNAL and are labelled as such in the log;
they prove the plate is arithmetically self-consistent, which is evidence that the transcription is right, and
they must **never** be quoted as corroboration of the plate's truth. That distinction is printed on the page
because burying it is how circular validation gets published (cf. §6.1 and the `rev3_gsut_i0_check` near-miss).

**The one exceedance was resolved by re-reading the plate, not by adjusting the number.** UAT tap 2 computes
**640.0779 A** against a printed **640.0 A**; the tolerance is ±0.05 A, half the plate's own printed
resolution, so it failed. The response was to re-render the tap column at 3× line width
(`tmp/rev3_uat_tapcol_zoom2.m` → `tmp/p3_taptbl.png`, `tmp/p3_taptbl_hi.png`) and read the digit again. **The
plate unambiguously prints 640.0, so the transcription is correct and the defect is in the source document:**
640.0779 should print as 640.1. A plate-wide truncate-instead-of-round convention is **ruled out**, because
656.0799 prints as **656.1** on the same table. Deviation **0.078 A = 0.012 %** — immaterial to every
downstream calculation, but it is now carried as a `[DOC ]` outcome with its justification printed inline,
rather than absorbed by widening a tolerance until the check went green.

Two by-products of that re-read are folded back into §3.9:

- the UAT tap-table **`Max.` / `Rated` / `Min.` arrows** at positions 1 / 3 / 5 — so the UAT rated tap and tap
  direction are **read from the plate**, not inferred from the ordering (the C-45 situation, now for the UAT);
- **three hand-arithmetic errors in §3.9e itself**, all found by the run, none of which changed a conclusion —
  which is exactly why eye-checking had not caught them (the CORRECTION block in §3.9e).

The script's summary line reports all three counters (`PASS / DOCUMENTED DEVIATION / FAIL`) and still `error`s
on any `FAIL`, so a documented deviation cannot be used as a hiding place for a real failure.

---

## 7. Open items

**Needs image reading** (text layer absent or ambiguous; `Read` renders images):
- ~~`UAT Nameplate_South.pdf` pp. 3–4 — rating data is **image-only**~~ → **CLOSED 2026-09-13, §3.9.**
  The pages are **not images**: they carry **no `/XObject` resource at all** and **zero text operators** —
  2.4 MB of AutoCAD SHX **vector line art**, which is why `pdftotext` returns 1 character. Both plates are now
  transcribed in full (UAT `10BBT10` S/N 100579 p. 3; GAT `10BBT20` S/N 100580 p. 4), including the complete
  25-position GAT OLTC table, both CT tables, both insulation tables, the OLTC/off-load tap-changer type
  strings and the **earthed closed-delta stabilizing winding** (**C-46**). New rows **C-46 … C-51**
- GAT LV secondary neutral fault limit (**truncated** in the text dump; presumed 5 A) — **the rating plate was
  checked and does not carry it.** The plate gives LV-N *insulation* (`Um 7.2 / BIL 60 / AC 20 kV`) only; no
  neutral-earthing resistor or fault-current-limit field exists on either plate. Still open, and the plausible
  remaining source is the NER/earthing datasheet, not the nameplate
- ~~GSUT extreme-tap impedances `{15.5, 16.0, 16.9}` — confirm assignment to tap positions~~ → **FULLY CLOSED,
  no image needed** (§3.2a / **C-45**): **184 kV pos 25 = 15.5 %**, 230 kV pos 9 = 16.0 %, **253 kV pos 1 =
  16.9 %**, with the resistive component **0.28 / 0.21 / 0.21 %**. The min/max direction is parenthesised in
  the datasheet itself. All 25 **tap voltages** were already proved to the volt for both GSUT and GAT (§3.7a).
  **`X/R` is therefore tap-dependent (≈55 → ≈80) while `X` is not** — a real sensitivity for D3's asymmetrical
  duty, replacing the two-permutation placeholder
- The two unexplained GSUT loss values `498` / `621` → currently `AVAILABLE_NOT_DIGITIZED`
- ~~Repeated `16000/1 A` token in the SLD dump — judged an OCR artefact of `1600/1`, confirm~~ →
  **CLOSED by Aug C3**: it is a real Rev 00 value superseded by Rev 03's `15000/1`, not an OCR error → **C-29**
- ~~**`Data Sheet_230KV.pdf` CB items 6 / 8f / 10 — the breaking-time contradiction (C-23).**~~ →
  **CLOSED from the text layer, no image needed** (§3.6a). Aligning on the **units column** rather than line
  adjacency gives a unique, quadruply-anchored solution: opening **33 ± 3 ms**, breaking max **≈55 ms**,
  total breaking **45.7–48.4 ms**. The contradiction was my misalignment. Duty now reports at 30 / 45 / 60 ms
- Crops already staged in `tmp/pdfs/`: `crop3_gat_ner.png`, `crop3_uat_ner.png`, `crop_ipb_and_ct.png`,
  `crop_mv_motor_table.png`, plus the 230 kV GIS bay-layout crops
- ~~**No rasteriser is installed** — so remaining image reads depend on crops or on `Read` rendering the page~~
  → **corrected, §0 / §3.9a.** No *external* rasteriser is installed, but **MATLAB's JVM inflates Flate and
  MATLAB's graphics engine rasterises paths**, so any **vector** PDF page is now readable at arbitrary zoom
  via `tmp/pdf_inflate_obj.m` → `tmp/pdf_parse_vector.m` → `tmp/pdf_draw_vector.m`. This does **not** extend to
  genuinely **scanned raster** pages, which still need a decoder this machine does not have. Where the text
  layer exists, still prefer the units-column alignment method of §3.6a — it is cheaper and it is exact

**Topology questions still unanswered by any source:**
- Do the two 230 kV circuits leave from **BB1 and BB2 respectively**, or both from one bus? (legacy shows a
  single `BAY_GRID` on `B230_1`)
- Does **any** document state the **bus coupler's normal operating state**? → **C-20**. Its *existence* is now
  tier-1 confirmed, but no source states whether it is normally closed; both BUS-CLOSED and BUS-OPEN cases
  stay mandatory and the state stays flagged `ASSUMPTION`
- ~~UAT HV CT ratio (Rev2 used 800/1 — source not yet located) → **C-19**~~ → **CLOSED**: Aug
  `verified_parameters.md` §9 gives UAT T1–T3 = **1000/1, 30 VA 5P20** → **C-30**
- **Line-bay and bus-coupler breaker nameplates are absent from the document set** → **C-36**. The CB
  datasheet is a single 46-item sheet for the **transformer bay** only

**Still to mine in `Data Sheet_230KV.pdf`** (1043 lines, only partly worked):
- Disconnector sheets, lines 105–293 (operating mechanism, contact, interlock data)
- `230 KV High Speed Fault Making Earthing Switch` sheet, line 297 — relevant to C-25 (making duty)
- ~~Remaining CB sheets at lines 768, 865, 983~~ → these are **pages 4–6 of the same transformer-bay sheet**
  (items 11–46: temperature rise, arc data, mechanism, SF₆ monitoring, testing). Electrically material rows
  already extracted; the remainder is mechanism/test data. **Low priority, not a gap** → **C-36**

**Data stores — STRUCK FROM SCOPE 2026-09-13 by user decision (*"forget all psaf files, they are dead"*), §3.10:**
- ~~`Ashuganj_South_PSAF_Tabular_Engineer_Source.xlsx` — tier 3~~ → **OUT OF SCOPE, never audited.** Its 14
  sheets were the basis of August's **C-16** (*Rev 00 values cited as Rev 03*). **C-16 therefore stands as an
  unverified August finding** and no REV3 parameter may depend on it. Note Rev2 had recorded this workbook as
  *superseded* (389 MW / 166.3 % / blanks), and the primary documents independently corroborate `PN` and `xd`,
  so nothing of value is lost by the exclusion
- ~~`psaf export (1)/` and the ~200 root-level `.ntx`/`.DBF` PSAF database files~~ → **OUT OF SCOPE.** Partial
  audit before termination established these are **CYME factory library tables** (dBASE `lastUpd` headers
  1999-03-02 … 2005-12-13, `twinding.dbf` holding `TRANSFO1…TRANSFO5` demo records), triplicated byte-identical
  across three folders, containing **no plant data**. `.ntx` files carry zero independent data by construction
- ~~**`psaf export (1).rar` cannot be opened** … A7 must state this as bounded residual risk~~ → **CLOSED
  2026-09-13, and closed properly rather than accepted as risk (§3.10).** No extractor was needed: **RAR5
  stores its filename table uncompressed**, so `grep -a` enumerated the archive directly. **72 entries, every
  one present on disk and byte-identical; `comm` shows *in-rar-but-not-on-disk* = ∅.** The presumption that the
  extracted folder is the archive's contents is now **verified**, not presumed, and the residual risk is
  **zero** rather than bounded. (Moot in any case — the whole store is now out of scope)

**Escalated to B1 — the one PSAF finding that is about REV3's own numbers (O-12):**
- The CYME library record `txvar.DBF → 10BAT10` contains **`Z0 = 0.1580, X/R = 75.0`** and **`X/R = 76.200`**
  for `Z1` — i.e. GSUT `Z₀ ≈ 15.8 %` and the `X/R = 76.2` that §3.9/D3 uses for the DC decay factor appear
  **verbatim in a library file**. REV3 will not cite that file. The question it raises is about REV3:
  **are these values datasheet-sourced, or inherited from this record and later attributed to a datasheet?**
  `Z = 16.0 %` is safe — three independent primary sources (§3.2). `Z₀` and `X/R` are **not yet confirmed
  against any primary document**. B1 must either find a primary source or **downgrade both to
  `ENGINEER_DERIVED`**. Until then they must not be written as `VERIFIED_SOURCE`

**Documents cited by the sources but absent from the workspace** (bounded, not open-ended — each is named by a
document number, so a future request to APSCL can be specific):
- `S001-112070-00-ELC-CL-0002` **pp. 1–5 and 8–39** — only pp. 6–7 are present. **Attachment 1 p. 42 carries the
  generator Q-capability curve**: the single highest-value missing page in the project (it would convert C-38
  from `ENGINEER_DERIVED` to `VERIFIED_SOURCE` and settle C-34)
- `INEL-112070-00-ELC-DE-0026` — 230 kV GIS control/protection one-line. Would settle **C-20** (coupler state),
  **Q10** (per-bay busbar selection) and **Q7** (line identity) in one stroke
- `INEL-112070-00-ELC-DS-0001` — **Electrical Design Criteria**. Would settle the grid assumption (§4.8), the
  tap philosophy (Q8) and the study bases (Q11)
- `INEL-112070-00-ELC-DE-0009` / `-0010` — MV and LV one-lines (the 400 V load Q-39 says is missing)
- `S008-112070-00-ELC-DE-1011` — Siemens GIS control/protection package; reported in a wider library with the
  line identity **"Line Ghorasal 2"**, but **not in this workspace**, so the identity stays *reported*, not verified
- `BD1015-B-&EFA010-700506` — turbine package (`SCC5-PAC 4000F/3000 1S`)

**Reconciliation debt:**
- ~~§4's `C-nn` IDs were assigned independently of `docs/validation/conflicting_parameters.md`~~ → **CLEARED
  2026-09-12.** All 10 August documents are read and mapped in §4.9; the older `Cn` scheme is preserved, not
  renumbered. Two items found along the way are recorded as findings rather than as debt: the August set
  **disagrees with itself** on the aux-load check (C-39) and **B9's arithmetic does not close** (C-44).

**Decisions that need the user before the load flow can be called final** (both are recorded with all options
and their arithmetic; neither will be resolved by picking silently):
- **§4.8 / C-31 — the 230 kV grid equivalent.** Three candidates: Rev2's `R 0.268 / X 2.940 Ω`; the §4.5
  IEC-consistent reconstruction `R 0.29451 / X 3.23663 Ω`; and the previously-approved `R 0, X 2.6558 Ω`, which
  August itself labels *provisional*. C-40 raises the stakes: R has **more** leverage here than |Z|
- **C-32 / C-41 — the generator terminal-voltage setpoint.** August marks it ❌ NOT APPROVED, and C-41 shows it
  currently reaches the solver through an unregistered path

**Known `MISSING` — now *evidenced* missing, not merely unfound:** GAT pairwise `Z_PT` / `Z_ST` (stabilizing-
winding impedances). Rev2 honestly flagged these; the rating plate was the last plausible source in the
document set and **it carries no HV-Stab or LV-Stab impedance column at all** — only a single "HV-LV" column,
itself left blank because these are pre-test rating-plate *drawings* (§3.9f, **C-51**). D3 must therefore
derive the three-winding star equivalent from `Z_PS` plus a **declared assumption** for the stabilizing leg,
and state that in the same sentence as the result. **Note the earlier §7 instruction to "mark the GAT tertiary
unavailable" is now split in two by C-46:** its *impedance* is unavailable, but the winding itself is a
**source-proven closed delta** and **must** appear in the zero-sequence network as a circulating path —
omitting it would overstate `Z0`.
CT core VA/class in the CT datasheet is likewise genuinely absent by the vendor's own statement (C-27) — but
the two rating plates **do** carry full CT tables (§3.9b/§3.9c), including a previously unknown GAT **HV-N
250/1 15 VA 5P20 neutral CT** (**C-50**), so the D4 CT registry is materially better supplied than C-27 alone
implies.

---

## 8. Plan — where Rev3 goes next

Sequence is fixed: **AUDIT → RECONCILE → DESIGN → IMPLEMENT → TEST → REGENERATE → REVIEW.** No giant
destructive rewrite; correct existing code is preserved.

| # | Step | State |
|---|---|---|
| A1 | Source extraction — 13 working-folder PDFs **+ the 5 missing from the folder** (§1.1b); 14 South documents now in scope | **done** |
| A2 | Conflict register (§4) | **done** — **45 rows** (C-01…C-45) |
| A3 | Code-defect audit (§5) | **done** |
| A4 | Reconcile §4 against the 10 `docs/validation/*.md` files (map IDs, do not renumber) | **done** — all 10 read (1567 lines); §4.9 maps both schemes with no renumbering; harvest in §3.7, inherited solver behaviours in §3.8, new rows **C-38…C-44**, all arithmetic independently re-derived in §6.1 |
| A5 | Close image-only gaps (§7) | **DONE 2026-09-13.** C-23 closed without an image (§3.6a); tap voltages closed for GSUT and GAT (§3.7a); GSUT extreme-tap Z closed without an image (§3.2a → C-45); C-19/C-29 closed by the August docs. **The last item — `UAT Nameplate_South.pdf` pp. 3–4 — is now closed with a positive result (§3.9):** the pages are **vector line art, not images**, and both rating plates are transcribed in full → **C-46 … C-51**. Residue is two genuinely-absent items, each now *evidenced* absent rather than unfound: GAT `Z_PT`/`Z_ST` (**C-51**) and the GAT LV neutral fault limit (not a nameplate field); plus the low-value GSUT `498`/`621`. **Every arithmetic claim in §3.9e is now executed output** (`tmp/rev3_plate_numeric_checks.m`, §6.2): **26 PASS · 1 documented source-document deviation · 0 FAIL**, with each block labelled INDEPENDENT or INTERNAL |
| A6 | Mine the rest of `Data Sheet_230KV.pdf` | CB sheets **done** (one 46-item transformer-bay sheet, §3.6a/§3.6b, → C-36). Remaining: disconnector sheets 105–293, earthing switch 297 — mechanism/test data, low priority |
| A7 | Audit `Ashuganj_South_PSAF_Tabular_Engineer_Source.xlsx` + `psaf export (1)/` + root `.ntx`/`.DBF` | **TERMINATED 2026-09-13 by user decision — *"forget all psaf files, they are dead"*** (§3.10). All PSAF artefacts struck from scope as a data source at every tier. Findings made before termination are retained as the **justification for exclusion**: the prior model has the **GSUT connections reversed** (`Pcon=Y/Scon=D` against a correct `Dyn11` sibling in the same file), the **UAT at 6.6 kV**, **no GAT, no load, no lines**, **60 Hz**, `DEFAULTZ0=CYMFAULT` (zero-sequence never entered), and **was never solved** (`PSol=QSol=0`). The `.rar` residual risk is **closed, not stated**: RAR5 filename tables are plaintext, so the archive was enumerated without an extractor — 72 entries, **zero** files not already on disk. **One item escalates to B1**, being about REV3's own numbers: `Z₀ ≈ 15.8 %` and `X/R = 76.2` appear verbatim in a CYME library record, so their attribution to a primary datasheet must be confirmed or downgraded (§3.10, **O-12**). `.xlsx` unaudited ⇒ **C-16 stands unverified**; nothing may depend on it |
| B1 | `DATA_RECONCILIATION_REV3.md` with the full 11-field parameter table | **next — PART A is closed, this is the active step.** Must additionally resolve **O-12** (§3.10): confirm GSUT `Z₀ ≈ 15.8 %` and `X/R = 76.2` against a primary document, or downgrade them from `VERIFIED_SOURCE` to `ENGINEER_DERIVED`. `Z = 16.0 %` is already safe (three independent primary sources, §3.2). Also carry **C-16 as an unverified August finding** — the `.xlsx` behind it is now out of scope, so no parameter may depend on it |
| C1 | `data/master/{master_registry,source_registry,assumptions,validation_registry}.m` + param-record constructor enforcing all 11 fields, **extending the August CSV schema** rather than replacing it | pending |
| C2 | Archive (**not delete**) competing registries; remove the hardcoded snapshot string | pending |
| C3 | Base-conversion library, explicit own-base vs system-base, with verification | pending |
| D1 | Network builder: BB1/BB2 + coupler node-merge, two explicit 0.7 km circuits, Thevenin behind the grid bus, NER, magnetizing branches, **corrected tap `a = 6.9/6.6`** (C-28) | pending — **plus** the **GAT loop configuration** (C-42), and `BranchType = 'RL'` asserted after every build (C-40). **Add from §3.9c:** the GAT OLTC is now fully specified — **25 positions, ±12 × 1.25 % about 230 kV, nominal position 13, constant 25 MVA throughput**, so tap cases use real plate values; and the UAT `Z` is confirmed **on the 25 MVA base** (**C-47**), which the base-conversion library (C3) must carry explicitly |
| D2 | Load flow LF-01…LF-10, analytic Jacobian + numerical cross-check, Q limits **reported as `MISSING`** (C-34), **OPTION A** loss accounting | pending — **OPTION A is already implemented, not to be rebuilt** (§3.8 B9): the task is to **re-derive the iron/copper split** whose 20.16 kW gap is C-44, print all three terms, and run the 6-point Q-curve (C-38) as a sensitivity case. GSUT tap Z is now **verified per position** (C-45), so tap cases use real values, not permutations |
| D3 | Rebuild zero-sequence network; LLL/LL/LG/LLG at B01/B02/B03/B11 with IEC 60909 κ, peak, MVA, contributions **at fault-point voltage**, X/R, breaker duty vs the **verified** 50 kA sym. interrupting / 125 kA peak / 50 kA·3 s withstand — asymmetrical duty at **`t_min` = 30 / 45 / 60 ms** (§3.6a), and the `Q1`/`Q2`/coupler verdict labelled an **extension by inference** (C-36) | pending — **add**: GCB duty as **through-current** against the **100 kA** verified rating, not the bus total (C-37); B11 duty against the **31.5 kA** `10BBA10` switchgear rating (§3.7), a limit Rev2 never tested; the GSUT **9 / 43 kA 3 s** and **23 / 110 kA peak** through-fault ratings as a *separate rating class* (§3.2a); and **tap-dependent `X/R` ≈55→≈80** in the asymmetrical duty (C-45). **Add from §3.9:** the GAT stabilizing winding enters the zero-sequence network as a **real closed-delta circulating path** whose single earthed corner carries **no** zero-sequence return current (**C-46**) — this replaces §7's "mark the tertiary unavailable"; its leg impedance stays a **declared assumption** (**C-51**); and the B01 22 kV result is cross-checked for order of magnitude against the UAT plate's **6600 MVA / 173.2 kA design envelope**, labelled a manufacturer design basis and **never** a measured fault level (**C-48**) |
| D4 | Protection: CT registry (gen 15000/1, GSUT 1600/1, GIS bay 1600/1, GAT 500-250/1, **UAT HV 1000/1**), 51/51N/TMS/87G/87T/87B/87L/BF at the confirmed 300 ms CTI, IEC-SI TCCs — all labelled **preliminary** | pending — **add a real 46 (negative-sequence) element**: `I₂max/I_N = 7.64 %` and `K = 7.41 s` are verified machine capability (§3.7), so 46 can be set from source data rather than from the X₂ assumption. **Add from §3.9b/§3.9c:** both plates' full CT tables, notably the new **GAT HV-N `250/1` 15 VA 5P20 neutral CT `T6`** — `51N`/`87N` are set from it, not from a phase-CT residual (**C-50**); the GAT HV `T1` is **dual-ratio `500,250/1`** with the selected tap `UNKNOWN`; the UAT CT table is the **twice-revised Rev 03** content (revisions 02 and 03 were both *"Revised CT code"*); and the three **`ATR3`** cores are **excluded** from the protection registry as an unknown, non-IEC class (**C-49**) |
| D5 | Dynamic study — **new build**, AVR fed the actual faulted terminal voltage | pending |
| D6 | Simulink re-parameterised from the registry; label/clean unused ideal-source mask values; executable cross-check with stated tolerances | pending — must honour **every** B1–B11 behaviour in §3.8: set `frequencyindice` *and* `Frequency`; write `BaseVoltage`; fresh build per solve then `bdclose`; `'report'` as a suffix to `'solve'`; treat `LF.status` as a double; keep tolerances above the measured **1.68e−4 MVA** snubber artefact; identify buses by **handle**; keep `Phases` off `'ABC'`; use `BranchType = 'RL'` |
| E1 | `results/rev3/{load_flow,fault,protection,dynamic,simulink,validation}/`; archive old results | pending |
| E2 | `run_all_rev3.m` — must **fail loudly** on: missing source data · unit mismatch · invalid impedance · conflicting registry · unknown grounding · unsupported transformer configuration | pending — **plus four conditions measured in §3.8, not hypothesised**: `frequencyindice` ≠ 50 Hz (B1) · non-convergence returning a truncated 12-field `LF.bus` (B5) · `Phases = 'ABC'` silently switching the study to the unbalanced formulation (B11) · any solver input with no registry record (C-41) |
| E3 | 17 REV3 outputs + acceptance checklist | pending |
| E4 | **REV3 CHANGELOG** — OLD / NEW / SOURCE / ENGINEERING REASON / EFFECT ON RESULTS | pending |

### Standing rules for this revision
- Results are **expected to change**. When a correction moves a number, it stays moved — no reconciling back
  toward Rev2. The B01/B11 earth-fault results in particular will change by ~4 orders of magnitude.
- Simulink agreement is an **independent implementation cross-check**, never evidence that plant data is right.
- Protection settings are **"preliminary protection coordination settings for the academic model"** — never
  commissioning-ready.
- No number with unknown provenance may appear as a verified plant parameter.
- Every percentage impedance conversion goes through `Z_new = Z_old × (S_new/S_old) × (V_old/V_new)²`.
- **Keep equipment rating classes apart. Never let one number serve two roles.** A single figure — 50 kA is the
  worked example (§4.6 lists five distinct roles for it) — can be a *thermal withstand* (IEC 62271-1,
  short-time current for a stated duration), a *switching duty* (IEC 62271-100, rated symmetrical breaking
  current), a *peak/dynamic* rating, a *CT* overcurrent-factor limit, or an *estimated grid fault level*. These
  are different standards, different physics and different pass/fail tests. Every duty table must name the
  rating class and the clause it is tested against, and a *prospective fault level* must never be compared
  against a *withstand* rating as if that proved switching adequacy.
- **A rating verified for one device is not verified for its neighbours.** Datasheets in this set are per-bay
  (C-36). Extending a rating across bays is `ENGINEER_DERIVED`, and must say so in the same sentence that
  quotes the number.
- **When a `pdftotext -layout` dump looks self-contradictory, suspect the layout before the document.** Align
  on the **units column** and require label ↔ unit ↔ value counts to match; look for definitional anchors
  (a value whose form admits only one label) and for rows the sheet states twice. §3.6a is the worked example —
  it dissolved an apparent datasheet contradiction that had been logged as blocking.
- **A check between two quantities is a validation only if they were derived independently.** Two restatements
  of one datum agreeing to 0.4 % proves arithmetic, not truth. Three instances are now on record: the 50 kA
  grid figure wearing five hats (§4.6), the 14 MW aux load checked against the motor table it was probably
  copied from (C-39), and B9's loss split where two of three "independent" routes were the same route (C-44).
  **Every validation table entry must name the two sources and their tiers**, so a same-source pair is visible
  on the page rather than buried in the arithmetic.
- **A verification script must not call the code it is verifying.** Type the inputs in from the quoted source
  text. §6.1 block [9] is the reason this is a rule: written to confirm an existing result, it falsified that
  result's arithmetic while leaving its conclusion standing. Had it imported the project's loss function it
  would have agreed with itself and reported PASS.
- **Prefer reading a document to orchestrating agents to read it.** A 17-agent fan-out over these seven files
  produced zero completions across 18 launches; the serial read took one pass (§3.7). Fan-out earns its cost
  on breadth (many files, shallow reads), not on depth over a handful of documents that must be reconciled
  against each other — reconciliation needs one context holding all of them at once.
- **"No text layer" does not mean "scanned image", and "no tool installed" does not mean "cannot be done".**
  §3.9a is the worked example: pages that returned 1 character from `pdftotext` were logged as image-only and
  unreadable for three weeks. They contained **no images at all** — they were vector line art with no text
  operators, and the two capabilities needed to read them (Flate inflate, path rasterisation) were already
  inside MATLAB. Before declaring a source unreachable, **establish what the file actually is** — one
  `/Resources` dictionary would have falsified the whole chain on day one — and check what the installed
  *runtimes* can do, not just what is on `PATH`.
- **For a winding, read the wiring, not only the rating.** A rating tells you the size of a thing; the
  connection tells you what it *is*. The GAT's 8.33 MVA winding is indistinguishable from a loaded tertiary on
  every ratings row of every document in this project; the terminal-box links and the earth symbol on one
  delta corner (§3.9d, **C-46**) settle it in one glance, and they change the zero-sequence network in two
  opposite directions at once — the delta **must** be present as a circulating path, and the earth **must not**
  be present as a current source. Ratings alone would have got both wrong.
- **A blank field on a source document is itself a finding, and it must be recorded as one.** Both rating
  plates leave impedance, losses, no-load current, oil type and temperature rise **empty by design** — they are
  pre-test drawings (§3.9f). That converts `MISSING` from *"we did not find it"* into *"the last plausible
  source has been checked and does not carry it"* (**C-51**), which is a materially stronger statement and the
  only one that justifies an assumption downstream. Never silently re-file a checked blank as "not yet
  searched", and never let it become a generic assumption without the check being on the page.
- **When a check fails, go back to the source before you touch the tolerance or the number.** A failing check
  has exactly three possible causes, and they must be distinguished, not averaged: the *arithmetic* is wrong,
  the *transcription* is wrong, or the *source document* is wrong. §6.2 is the worked example — UAT tap 2
  computed 640.0779 A against a printed 640.0 A. The cheap response is to widen the tolerance to 0.1 A and
  watch the suite go green; the correct response was to re-render the column at 3× and read the digit again,
  which showed the transcription was right and the plate rounds 640.0779 down where it rounds 656.0799 up.
  Deviations that survive that test are carried as **documented deviations with the justification printed
  inline** and counted separately from `PASS`, never absorbed — and the suite must still `error` on a genuine
  `FAIL` so the documented-deviation path cannot become a hiding place. Re-reading a source to settle a 0.012 %
  discrepancy also pays for itself: that re-read is what surfaced the UAT `Max./Rated/Min.` tap arrows (§3.9b).
- **Execute the arithmetic; do not proof-read it.** The A5 verification run found **three** wrong
  hand-computed numbers inside §3.9e (see its CORRECTION block) — none of which changed a conclusion, which is
  exactly why several passes of careful reading had left them standing. A number that is *nearly* right is
  invisible to the eye and obvious to a script.
- **A container's index is usually plaintext even when its contents are not.** The `.rar` sat on the open-items
  list for a month as unopenable, and the mitigation written for it was *"state the bounded residual risk"*.
  **RAR5 stores its filename table uncompressed**, so one `grep -a` enumerated all 72 entries and proved the
  archive held no unseen file — risk **zero**, not bounded (§3.10). This is the second instance of the
  *"no tool installed" ≠ "cannot be done"* rule (the first was the vector PDFs, §3.9a), and it sharpens it:
  before accepting an opaque container as residual risk, **ask what part of it is required by format to be
  readable.** Archive indexes, PDF `/Resources` dictionaries and dBASE headers are all plaintext by design.
- **A file's own header outranks its filesystem timestamp, and often contradicts it.** All 62 `.DBF` tables
  carried a 2026-08-13 mtime, which reads as *"engineer data prepared last month"*. Their dBASE `lastUpd`
  headers read **1999–2005**: CYME factory libraries, copied with timestamps preserved (§3.10). The mtime
  described the **copy**, the header described the **content**. Where a format records its own provenance —
  dBASE `lastUpd`, PDF `/CreationDate`, drawing revision blocks — that field is the evidence; the filesystem
  stamp is an artefact of whoever last moved the file.
- **Read a foreign-language log before concluding what it proves.** *"Suppression d'un champs non existant"*
  was read as *"a field was deleted"* and written up as proof the libraries had been **rewritten** locally.
  It means *"deletion of a **non-existent** field"* — a schema **comparison** report of fields the script looked
  for and did not find, under the log's own `In Script / Found in Database` header. **Nothing was written**, and
  the unchanged 1999–2005 `lastUpd` stamps prove it independently. The corrected reading supports the *opposite*
  conclusion — untouched vendor data — and happens to be the stronger reason for the same decision. A
  mistranslation that lands on a convenient conclusion is the hardest kind to catch: **corroborate the reading
  against a second, non-linguistic signal** before building on it.
- **A value appearing in a discarded model does not become false, but its *provenance* becomes a question.**
  Striking the PSAF set from scope (§3.10) does not invalidate `Z₀ ≈ 15.8 %` or `X/R = 76.2`. It reveals that
  those figures exist in a library record REV3 never cited, which means their attribution to a primary
  datasheet is **unproven rather than wrong**. The correct response is neither to keep them as
  `VERIFIED_SOURCE` nor to delete them, but to **re-derive the citation** — and if none exists, downgrade to
  `ENGINEER_DERIVED` and say so (**O-12**). Deleting a superseded artefact can silently orphan numbers that
  were quietly depending on it.
