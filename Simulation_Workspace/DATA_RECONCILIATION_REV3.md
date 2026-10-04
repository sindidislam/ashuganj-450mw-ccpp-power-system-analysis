# DATA_RECONCILIATION_REV3.md

**Ashuganj South 450 MW Combined Cycle Power Plant (APSCL, Bangladesh)**
**REV3 — Deliverable B1: Data Reconciliation**

| | |
|---|---|
| Document | `DATA_RECONCILIATION_REV3.md` |
| Deliverable | B1 (gate document for all REV3 implementation) |
| Revision | 3 |
| Status | **ISSUED — implementation gate** |
| Supersedes | Rev2 `rev2/data/reconciliation_register.csv`; `Ashuganj_South_Final_Master_Data_and_Assumptions (1).md` (partially — see §9) |
| Executed backing | [`docs/validation/rev3/B1_derivations.log`](docs/validation/rev3/B1_derivations.log) (247 lines, produced by [`matlab/studies/rev3_b1_derivations.m`](matlab/studies/rev3_b1_derivations.m)) |

---

## 0. PURPOSE, SCOPE AND HOW TO READ THIS DOCUMENT

### 0.1 What this document is

This is the **data reconciliation gate** for REV3. It establishes, for every parameter that
will enter a REV3 calculation:

1. the value that will be used,
2. the unit and the base it is expressed on,
3. the document it came from and where in that document,
4. its confidence and status classification,
5. what alternative values exist and why they were not selected,
6. what is missing and therefore cannot be modelled.

**No REV3 implementation work may consume a parameter that does not appear in this document.**

### 0.2 What this document is NOT

- It is **not** a validation report. Nothing here is validated against plant test or
  commissioning data, because no plant test or commissioning data exists in the project
  source set. Where two independently-derived quantities agree, this document says
  "cross-check closes"; it does not say "verified against the plant".
- It is **not** a results document. No load-flow, fault, protection or dynamic result
  appears here. Net export, in particular, is a **load-flow result** (deliverable D2),
  not a datum, and is deliberately absent from §1.
- It does **not** invent missing data. Where a parameter is absent from every source,
  it is listed in §5 as `MISSING` and the affected model capability is stated.

### 0.3 Source hierarchy (PART B)

| Tier | Definition | Documents in this project |
|---|---|---|
| **1** | Siemens / TSK / INEL / APSCL as-built drawings and manufacturer datasheets | `Generator Data_South.pdf` (**SIE**), `GSUT Data Sheet_South.pdf` (**CTI**), `UAT  Data Sheet_South.pdf` (**CTIU**, covers UAT *and* GAT), `INEL-112070-00-ELC-DE-0001-REV3.pdf` (**SLD**), `GSUT Nameplate_South.pdf` (**PLATE**), `UAT Nameplate_South.pdf` (no text layer) |
| **2** | Official PGCB / APSCL documents | `Google Sheet Form_Filled Up By APSCL.pdf` (**APS**) |
| **3** | Engineer-derived datasets | `Ahsuganj South (2).xlsx`, sheet `"Ashuganj South "` (**WB**) |
| **4** | Published secondary material | *(none used as a primary value in REV3)* |
| **5** | Engineering assumptions | Listed exhaustively in §6 |

**Tie-break rule used throughout:** where two sources give different values for the same
physical quantity on the same basis, the **lower tier number wins**, the alternative is
**retained** in §4.2, and the reason is recorded. Where the conflict is one of *interpretation*
rather than of value (e.g. saturated vs unsaturated), it is recorded in §3 as a resolved
non-conflict, not as a conflict.

**Standing exception — the workbook is PRIMARY for the generator.** The REV3 master
instruction designates `Ahsuganj South (2).xlsx` the **primary generator parameter source**.
That designation is honoured in §1: every generator machine parameter in §1 is the workbook
value. The tier table above governs the *rest* of the plant (transformers, grid, auxiliaries),
and it governs the workbook's **GSUT** columns (`AK3..AR3`), which are tier-3 statements about
equipment for which tier-1 manufacturer data exists — see §4.2 SC-05, SC-06, SC-07.

### 0.4 Status vocabulary (§22)

| Status | Meaning | May be used in a calculation? |
|---|---|---|
| `VERIFIED_DIRECT` | Read literally from a source document; no arithmetic applied | Yes |
| `DERIVED_FROM_VERIFIED_DATA` | Computed by a stated equation from `VERIFIED_DIRECT` inputs only | Yes, with the equation cited |
| `ENGINEERING_ASSUMPTION` | Chosen by the engineer; no source states it | Yes, **only** if labelled as an assumption in every output |
| `SECONDARY_SENSITIVITY` | A real alternative value, retained to be run as a sensitivity case | Only in a sensitivity run, never in the base case |
| `MISSING` | Absent from every source | **No.** The dependent model feature must be disabled or declared out of scope |
| `SOURCE_CONFLICT` | Two or more sources disagree; one is selected by hierarchy | Selected value yes; alternative becomes `SECONDARY_SENSITIVITY` or is recorded only |

### 0.5 The 11-field parameter record (PART B)

Every parameter admitted to the REV3 master registry carries these fields. §1 and §8
present them in table form; the registry constructor in C1 will reject any record with a
missing field.

`Parameter` · `Value` · `Unit` · `Source` · `Source document` · `Page/section` ·
`Confidence` · `Status` · `Assumption flag` · `Notes` · `Supersedes / alternative value`

### 0.6 Provenance of derived numbers

Every derived number quoted in this document was produced by executing
`matlab/studies/rev3_b1_derivations.m` under MATLAB R2024a and is reproduced from
`docs/validation/rev3/B1_derivations.log`. **No number in this document was computed by
hand.** This rule exists because three hand-arithmetic errors were caught by execution in
earlier REV3 sessions. Section references of the form *(log §N)* point at the block of the
log that produced the figure.

Reproduce with:

```bash
matlab -batch "addpath('matlab/studies'); rev3_b1_derivations"
```

---

## 1. THE PRIMARY GENERATOR DATASET

### 1.1 Designation of the primary source

The **primary generator parameter source for REV3** is:

| | |
|---|---|
| Workbook | `Ahsuganj South (2).xlsx` |
| Sheet | `"Ashuganj South "` *(note the trailing space — it is part of the sheet name)* |
| Row | 3 (the single data row; row 1 = group headers, row 2 = column headers) |
| In-project path | `fwdtechnicaldatasldrequestforbueteeetermproject/Ahsuganj South (2).xlsx` |
| Size / mtime | 137 122 bytes, 13-Sep-2026 22:21:26 |
| Second copy supplied | `C:\Users\sindi\Desktop\MouseWithoutBorders\ScreenCaptures\Ahsuganj South (2).xlsx` — **proved byte-identical** to the in-project copy |
| Sheets present | `[1] "Ashuganj South "` (6 × 46), `[2] "Auto Transformer"` (4 × 16) |

The previous REV3 working assumption — that the `Xd = 1.783 / Xd' = 0.3256 / Xd'' = 0.2608`
dataset was "merely an unverified alternate dataset" — is **withdrawn**. That dataset is the
primary REV3 generator dataset. See §3 for why it does not conflict with the Siemens
`1.663 / 0.2865 / 0.2248` set.

### 1.2 Exact values as supplied — verbatim transcription

Transcribed cell-by-cell from the workbook with no rounding, no unit conversion and no
interpretation. The `Row 1 group header` column records the merged banner that owns each
column; this is structural evidence used in §4.2 SC-04.

#### 1.2.1 Identity and ratings

| Cell | Row 2 header | Value (verbatim) | Row 1 group header |
|---|---|---|---|
| `A3` | Name of the Generator unit | `Ashuganj 450 MW CCPP(South)` | — |
| `B3` | Capacity (MW) | `360` | — |
| `C3` | Total Rated MVA | `458` | — |
| `D3` | Generating kV | `22` | — |
| `E3` | Manufacturer/Country | `SIEMENS AG` | — |
| `F3` | Inertia Constant, H (kW-sec/kVA) | `5.287` | `Combined Inertia data of Generator and Turbine` |
| `G3` | Short circuit Ratio | `0.601` | *(within the inertia banner span)* |

Frequency is **not** a workbook column. 50 Hz is taken from SIE, CTI, CTIU, the SLD and the
GSUT nameplate, which all state it; no project document states any other value.

#### 1.2.2 Reactances — group header `H1 = "Reactance in pu"`

The group header states the unit for the whole `H..T` span, so every value below is **per
unit on the machine's own base (458 MVA, 22 kV)** with no ambiguity.

| Cell | Row 2 header | Value (pu, 458 MVA base) |
|---|---|---|
| `H3` | `Xd` | `1.783` |
| `I3` | `Xd'` | `0.3256` |
| `J3` | `Xd"` | `0.2608` |
| `K3` | `Xd"(sat)` | `0.2248` |
| `L3` | `Xq` | `1.751` |
| `M3` | `Xq'` | `0.5087` |
| `N3` | `Xq"` | `0.2593` |
| `O3` | `Xl` | `0.2027` |
| `P3` | `X2 (sat)` | `0.2242` |
| `Q3` | `X0 (sat)` | `0.128` |
| `R3` | `XD(damper)` | *(empty)* → §5 M-01 |
| `S3` | `XQ(damper)` | *(empty)* → §5 M-02 |
| `T3` | `Xf` | *(empty)* → §5 M-03 |

#### 1.2.3 Resistances — group header `U1 = "Resistance in pu or ohm"`

**The group header is deliberately unit-ambiguous.** The ambiguity is resolved *by the cell
text itself*: `U3` carries the literal string `0.00089 ohm`, while `V3` carries a bare number.

| Cell | Row 2 header | Value (verbatim cell text) | Unit as resolved |
|---|---|---|---|
| `U3` | `Ra` | `0.00089 ohm` | **ohm** — the unit is written in the cell |
| `V3` | `Rf` | `0.10631` | pu (no unit in cell; header default) |
| `W3` | `RD(damper)` | *(empty)* | → §5 M-04 |
| `X3` | `RQ(damper)` | *(empty)* | → §5 M-05 |

`0.00089` **must not** be interpreted as per unit. See §2.4 for the determination and for the
independent armature-time-constant test that supports it.

#### 1.2.4 Time constants — group header `Y1 = "Time Constants (sec)"`

| Cell | Row 2 header | Value (s) |
|---|---|---|
| `Y3` | `T'd0` | `7.547` |
| `Z3` | `T''d0` | `0.045` |
| `AA3` | `T'q0` | `0.839` |
| `AB3` | `T''q0` | `0.07` |
| `AC3` | `T'd` | `1.213` |
| `AD3` | `T''d` | `0.035` |
| `AE3` | `T'q` | `0.214` |
| `AF3` | `T''q` | `0.035` |
| `AG3` | `Ta or Ta(3)` | `0.704` |
| `AH3` | `Ta(1)` | *(empty)* → §5 M-06 |

These are the REV3 time constants. They are **not** to be replaced by generic Siemens or
model-library defaults.

#### 1.2.5 Saturation — group header `AI1 = "Saturation data"`

| Cell | Row 2 header | Value |
|---|---|---|
| `AI3` | `S(1.0)` | `0.0865` |
| `AJ3` | `S(1.2)` | `0.408` |

Two saturation coefficients are supplied. **No additional saturation coefficients are to be
invented.** Any Simulink or solver block requiring a different saturation representation must
either accept these two points or have its limitation documented (§9, D6).

#### 1.2.6 Excitation — group header `AS1 = "Excitation"`

| Cell | Row 2 header | Value |
|---|---|---|
| `AS3` | excitation system type and parameter | `Static` |
| `AT3` | excitation controllers type and their detailed description, structural scheme and settings | `SEMIPOL` |

Two **type designations** and nothing else. **No AVR gain, time constant, limiter or PSS
value exists in any project source.** These must not be fabricated — see §5 M-07 and the
consequence for the dynamic study in §7.4.

#### 1.2.7 Columns `AK3..AR3` are NOT generator data

`AK1` carries the merged banner **`Generator Step Up Transformer (GSUT) data`**. Every column
from `AK` through `AR` therefore describes the **GSUT**, not the generator:

| Cell | Row 2 header | Value | Belongs to |
|---|---|---|---|
| `AK3` | Transformer MVA | `515` | GSUT |
| `AL3` | No Load Losses PNL (kW) | `155.3` | GSUT → §4.2 SC-06 |
| `AM3` | No Load Current INL (%) | `0.00034` | GSUT → §4.2 SC-07 |
| `AN3` | Total full load losses PFL (kW) or pu | `1067.5` | GSUT → §4.2 SC-06 |
| `AO3` | Percentage of Impedance (%Z or in pu) | `0.1663` | GSUT → §4.2 SC-05 |
| `AP3` | Winding Connection Types | `YNd1` | GSUT |
| `AQ3` | Neutral modes | `Solid Ground` | **GSUT HV neutral** → §4.2 SC-04 |
| `AR3` | Onload tap changers parameters | *(empty)* | GSUT |

**This is the single most consequential structural finding in the workbook.** It is the
reason the apparent "generator is solidly earthed" conflict does not exist: the workbook has
**no generator-neutral column at all**. See §4.2 SC-04.
