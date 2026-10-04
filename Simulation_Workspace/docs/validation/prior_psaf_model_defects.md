# Prior CYME PSAF Model — Defect Audit

The project contains a previous CYME PSAF network (`AUTOSAVE.nwk/.NWT`, `psaf export (1)/psaf export/ONGOING.nwk`, `AUTOSAVE.STU`, `ongoing.stu`, plus the `database/` dBASE libraries). It was audited byte-level because the Excel workbook transcribes values out of it.

**Conclusion: the prior model must not be used as a data source.** Six independent, evidence-backed defects were found. Every claim below is traceable to a literal record.

---

## D1 — Generator Q limits and grounding are un-edited library template values

`database/Gener.DBF` field order is `NPOLES, MVA, PFACTOR, PGEN, Q_CHOICE, QMAX, QMIN, Q_CURVE, SUBR, SUBX, INTR, INTX, CONN, RGROUND, XGROUND, USRCOMMENT`.

The project's record, verbatim:

```
GEN1_DATAA   2  22.000  458.0000 0.850   389.3001     0.653    -0.131{1.000000;332.299988;-228.699997;}{100.000000;326.700012;-225.199997;}{200.000000;308.799988;-213.100006;}{300.000000;278.600006;-192.500000;}{389.200012;239.399994;-167.100006;}{432.000000;152.000000 0.00300 0.22480 0.00300   0.28650 0.00300 1.66300 0.00180   0.04600Y  730.000   0.100
```

The shipped library template it was copied from, verbatim:

```
1.3MW_4.2KV_DIESEL-GENERATOR   2   4.200    1.4500 0.900     1.3050     0.653    -0.131{1.000000;1.000000;-1.000000;}   0.06640 0.16600 0.05200   0.25000 0.00652 1.95000 0.00180   0.04600YG 730.000   0.100
```

| Field | Project record | Diesel template | Verdict |
|---|---|---|---|
| QMAX | **0.653** | **0.653** | **never edited** — 0.653 MVAr for a 458 MVA machine |
| QMIN | **−0.131** | **−0.131** | **never edited** |
| RGROUND | **730.000** | **730.000** | **never edited** |
| XGROUND | **0.100** | **0.100** | **never edited** |
| trailing R/X pair | 0.00180 / 0.04600 | 0.00180 / 0.04600 | **never edited** |
| MVA | 22.000 / 458.0000 | 4.200 / 1.4500 | edited ✔ |
| PFACTOR | 0.850 | 0.900 | edited ✔ |
| PGEN | 389.3001 | 1.3050 | edited ✔ |
| SUBX | 0.22480 (= x_d″ 22.48 %) | 0.16600 | edited ✔ |
| INTX | 0.28650 (= x_d′ 28.65 %) | 0.25000 | edited ✔ |
| third X | 1.66300 (= x_d 166.3 %) | 1.95000 | edited ✔ |
| CONN | `Y ` | `YG` | edited ✔ |

**Consequences.** (a) The `AUTOSAVE.nwk` generator grounding of **730 Ω / 0.1 Ω is a library artefact, not plant data** — the real machine uses NER 10BAB11 (60 Ω + 2.62 Ω loading resistor). `ONGOING.nwk` carries 9999/9999, a placeholder. (b) The QMAX/QMIN scalars are meaningless.

---

## D2 — The Q capability curve is truncated and untraceable

The `Q_CURVE` blob above ends `{432.000000;152.000000` — the 6th point's Q_min and the entire 7th point are **cut off mid-record**. The Excel sheet `04_GEN_Q_CAPABILITY` presents all 7 points as "DIGITIZED" from "Generator Protection Setting Report, Attachment 1 / p.42 of 44".

Chain of custody: Excel ← `Gener.DBF` Q_CURVE ← a document page (p.42) that **is not in the project** (only pp. 6‑7 are, as `Generator Data_South.pdf`).

Additional red flag: Q_min/Q_max ≈ 0.688 at every point (−228.7/332.3 = 0.688, −225.2/326.7 = 0.689, −213.1/308.8 = 0.690, −192.5/278.6 = 0.691, −167.1/239.4 = 0.698). A real capability curve is bounded by three different physical limits (rotor heating, stator heating, stator end-core/steady-state stability) and does **not** hold a constant lead/lag ratio.

**Verdict: generator Q limits are `MISSING`, not verified.**

---

## D3 — The wrong transformer is installed in the UAT position

`AUTOSAVE.nwk` branch `T1` runs B22G → B6_6 and references `txfix.DBF` type `10/126_0500`, with Pcon = D / Scon = Y. That library record reads:

```
10/126_0500   500.000  10.000 120.000    0.0192   36.000    0.0000    0.0192   36.000    0.0000D Y   30.00   0.00 500.000 1000.000100.00   0.000   0.000
```

→ a generic **500 MVA, 10/120 kV step-UP transformer, Z = 1.92 %, X/R = 36**.

The actual UAT 10BBT10 is **25 MVA, 22/6.9 kV, Dyn11, Z = 10.5 % on 25 MVA**.

**Consequence:** a 20× rating error and a 5.5× impedance error in the single branch that determines every auxiliary-system voltage and every MV/LV loading. `txfix.DBF` contains **no project-specific entry at all** — only the shipped library types (`10/126_0500, 16/75, 210/735_0400, 230/115_120, 230/13, 230/69_120, 240/120_200, 308/4, 308/735_0450, 308/735_0700, 345/230_200, 4/30, 8/2, 8/308_175, 8/69_0050, 8_130`).

---

## D4 — GSUT tap minimum is wrong in the equipment database

`txvar.DBF` contains exactly one project record, `10BAT10`:

```
10BAT10   515.000 230.000  22.000    0.1600   76.200    0.0000    0.1580   75.000    0.0000 88.00110.00 25Y   D       30.00  -7.50 515.000  515.000        0.000   0.000   0.000
```

| Field | Value | Check against nameplate |
|---|---|---|
| MVA / kV / kV | 515.000 / 230.000 / 22.000 | ✔ |
| Z₁ / (X/R)₁ | 0.1600 / 76.200 → R = 0.20997 % | ✔ matches data sheet 16 % and 0.21 % |
| Z₀ / (X/R)₀ | 0.1580 / 75.000 | ✔ matches data sheet 15.8 % |
| **TAPMN** | **88.00 %** | ✘ nameplate min tap = 184000 V = **80.00 %** of 230000 |
| TAPMX | 110.00 % | ✔ 253000/230000 = 110 % |
| NBRTAP | 25 | ✔ |
| PCON / SCON / PHSHIFT | Y / D / 30.00 | ✔ YNd1 |
| LLIM / LLIM2 | 515.000 / 515.000 | ✔ |
| GRD/GRX, Z-vs-tap arrays | all 0.000 | data sheet has 15.5/16.0/16.9 % — not entered |

**Proof the 88 % is wrong:** 80 → 110 % over 24 steps = **1.25 %/step exactly**, matching the nameplate's stated ±1.25 % steps and every tap voltage in its table. 88 → 110 % over 24 steps = 0.9167 %/step, which matches nothing.

**Consequence:** the modelled tap range is truncated by 8 percentage points on the buck side.

---

## D5 — GAT 10BBT20 was never modelled

`twinding.DBF` (3412 bytes) contains **field descriptors only** (`KVPRIM, MVAPRIM, KVSEC, MVASEC, KVTER, MVATER, ZPS, XRPS, ZPT, XRPT, ZST, XRST, TAPMN, TAPMX, NBRTAP, KVDES, PCON, SCON, TCON, PHSHIFT, ZZ_PHSHIFT, PHSHIFT2, LLIM, LLIM2, KVRAN, GRD1, GRX1, GRD2, GRX2, GRD3`) and **no data records**. The `.nwk` files contain no three-winding branch.

The GAT is a real, released transformer (Siemens Wuhan TLSN7A54, S/N 100580) shown on both Rev 03 drawings, feeding the 6.6 kV MV bus from the 230 kV GIS. Omitting it removes a second source and a network loop.

---

## D6 — Both studies are configured at 60 Hz

`AUTOSAVE.STU`:
```
[GENERAL_STUDY]
NETWORK_FILE_NAME  F:\LOCAL DISK E\IDM\COMPRESSED\ LEVEL 3 TERM 1\306 POWER PROJECT\\AUTOSAVE.NWT
STUDY_NAME         ModelGrid1
PARAMETERS         // Version, Base Power, Freq, Sub Title
                   125, 100, 60, UNTITLED
```
`psaf export (1)/psaf export/ongoing.stu` carries identical parameters `125, 100, 60, UNTITLED`.

**Frequency = 60 Hz on a plant that every South document rates at 50 Hz.** Every reactance-derived result from the prior model is therefore invalid.

---

## D7 — Network topology is incomplete and contains junk

| Finding | Evidence |
|---|---|
| No `[Line]` section | Neither `.nwk` file has one → no cables/lines modelled at all |
| No `[Load]` section | → **no load was ever applied**; `load.DBF` holds only PSAF's five generic load models (`DEFAULT`, `CONSTANT_Z`, `CONSTANT_I`, `ACONSTANT_S`, `CONSTANT_S`) and no project loads |
| No shunt section | → no reactive compensation modelled |
| `line.DBF` | field descriptors only, no project records |
| Orphaned buses | `B230_2`, `BGRID230`, `B400_UA1`, `B400_UA2`, `B400_ST`, `B400_EU`, `B400_WI`, `B6_6_WI1`, `B6_6_WI2` — declared, never connected |
| Junk bus rows | `B0`, `B1`, and a malformed `0.00000` row (the latter also appears in `[Bus OPF Model]`) |
| Anomalous initialisation | `B400_EU` VoltSol = 1.1 pu, Angle = 1° |
| Inconsistent duplicates | G1 grounding 730/0.1 Ω in `AUTOSAVE` vs 9999/9999 in `ONGOING` |

Effectively the prior model consisted of a generator, a mis-specified auxiliary transformer, the GSUT, and a set of disconnected bus stubs — with no loads, no lines, and no grid source branch, at the wrong frequency.

---

## D8 — Version and housekeeping inconsistencies (informational)

| File | Content |
|---|---|
| `EXPORT.LOG` | "PSAF Version 2.81 / PSAF Revision 2.8" |
| `dbf.ver` | `[UPDATE] Date=16\8\2026 Version=2.90` |
| `.STU` PARAMETERS | Version 125 |
| `UpdateDBF.log` | dated "13 August 2026 2:3:13"; French entries *"Suppression d'un champs non existant"* removing `REFCOUNTER`, `ASSOCIATE`, `SPARE1` |
| `PSAF.INI` | `DATABASE=D:\ACADEMICS\L-3 T-1\EEE 306\PROJECT\PROJECT PSAF`, `BUS_DEFAULT_BASE_OPERATING_VOLTAGE=13.800000`, `UNITLENGTH=FALSE`, `UNITS_IN_NA=1` |
| `.cgp` files | 5–12 byte stubs holding only the table name (`Gener.cgp` = "GENER") |
| `tmp7D1.tmp` | 0 bytes |
| `psaf export (1).rar` | 47 721 bytes — **could not be opened**; no RAR extractor available on this machine (`unrar`, `7z`, `7za`, `p7zip` all absent). The extracted `psaf export (1)/psaf export/` folder is present on disk and is *presumed* to be its contents, but **this is unverified** |

The `BUS_DEFAULT_BASE_OPERATING_VOLTAGE = 13.8 kV` default and `UNITS_IN_NA = 1` confirm the installation was left on North-American defaults, consistent with the 60 Hz study setting.

---

## What is salvageable from the prior model

Only these, and only because each is independently corroborated by an original document:

| Item | Value | Corroboration |
|---|---|---|
| GSUT Z₁ / X/R | 16.00 % / 76.2 on 515 MVA | GSUT Data Sheet 16 % + R 0.21 % → X/R = 76.19 ✔ |
| GSUT Z₀ / (X/R)₀ | 15.80 % / 75.0 | GSUT Data Sheet Z₀ = 15.8 % ✔ |
| GSUT ratio / MVA / group / phase shift | 230/22 kV, 515 MVA, Y‑D, 30° | Rating plate ✔ |
| Generator MVA / kV / pf / x_d / x_d′ / x_d″ | 458 MVA, 22 kV, 0.85, 166.3/28.65/22.48 % | Name plate + Generator Data ✔ |
| Bus naming convention | B230_1, B230_2, B22G, B6_6, … | reused for readability |

Everything else is either un-edited library data, wrong, truncated, or absent.
