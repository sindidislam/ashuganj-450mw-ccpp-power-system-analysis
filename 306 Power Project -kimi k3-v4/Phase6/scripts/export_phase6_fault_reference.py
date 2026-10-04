"""Compare saved Phase 6 phasors with frozen fault references; no simulation."""
from __future__ import annotations

import cmath
import csv
import hashlib
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REFERENCE = ROOT / "data/phase5_reference/phase5_fault_inputs.csv"
CASES = (
    ("generator_3ph", "F1", "LLL", "GEN", "ABC"),
    ("generator_slg", "F1", "LG", "GEN", "A"),
    ("transformer_lv_ll", "F2", "LL", "GSUT_LV", "BC"),
    ("transformer_hv_llg", "F3", "LLG", "GSUT_HV", "BC"),
    ("bus_3ph", "F3", "LLL", "GIS230", "ABC"),
    ("line_slg", "F4", "LG", "LINE230", "A"),
    ("grid_external_ll", "F5", "LL", "GRID230", "BC"),
)


def read_csv(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8-sig") as stream:
        return list(csv.DictReader(stream))


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> None:
    references = read_csv(REFERENCE)
    rows, summary = [], []
    alpha = cmath.exp(2j * math.pi / 3)
    formulas = {
        "LLL": "mean(abs((Ia + a*Ib + a^2*Ic)/3)); a=exp(j*2*pi/3)",
        "LG": "mean(abs(Ia))",
        "LL": "mean(max(abs(Ib),abs(Ic)))",
        "LLG": "mean(max(abs(Ib),abs(Ic)))",
    }
    for scenario, location, kind, physical, active in CASES:
        matches = [r for r in references if r["fault_location"] == location
                   and r["fault_type"] == kind and r["caseID"] == "LF360_GAT_OUT"
                   and float(r["m"]) == 0.5 and r["stage"] == "Ikpp"]
        assert len(matches) == 1, (scenario, "ambiguous/missing reference")
        reference = matches[0]
        reference_a = float(reference["I_primary_A"])
        directory = ROOT / "results" / scenario
        fault_path, phasor_path = directory / "fault_summary.csv", directory / "phasors_timeseries.csv"
        fault = read_csv(fault_path)
        assert [r["Phase"] for r in fault] == ["A", "B", "C"]
        assert all(r["Fault_location"] == physical for r in fault)
        sensor = fault[0]["Fault_branch_sensor"]
        start = float(fault[0]["Fundamental_window_start_s"])
        end = float(fault[0]["Fundamental_window_end_exclusive_s"])
        samples = [r for r in read_csv(phasor_path) if start <= float(r["Time_s"]) < end]
        assert len(samples) == int(fault[0]["Fundamental_samples"]) > 0
        phase_values, governing = [[], [], []], []
        for sample in samples:
            currents = [complex(float(sample[f"{sensor}_I{p}_Re_A"]),
                                float(sample[f"{sensor}_I{p}_Im_A"])) for p in "abc"]
            assert all(math.isfinite(x.real) and math.isfinite(x.imag) for x in currents)
            for i, value in enumerate(currents):
                phase_values[i].append(abs(value))
            if kind == "LLL":
                value = abs((currents[0] + alpha * currents[1] + alpha**2 * currents[2]) / 3)
            elif kind == "LG":
                value = abs(currents[0])
            else:
                value = max(abs(currents[1]), abs(currents[2]))
            governing.append(value)
        phase_means = [sum(v) / len(v) for v in phase_values]
        for i, value in enumerate(phase_means):
            exported = float(fault[i]["Full_window_fundamental_current_RMS_A"])
            assert math.isclose(value, exported, rel_tol=1e-11, abs_tol=1e-8), (scenario, i)
        value = sum(governing) / len(governing)
        mapping = "Adjacent HV/GIS electrical reference; protection zone differs" if physical == "GSUT_HV" else "Corresponding named electrical location"
        common = {
            "Scenario": scenario, "Phase6_location": physical, "Fault_sensor": sensor,
            "Reference_location": location, "Reference_fault_type": kind,
            "Reference_case": reference["caseID"], "Reference_line_fraction": 0.5,
            "Reference_stage": "Ikpp", "Phase6_profile": "PHASE3_BASELINE",
            "Window_start_s": start, "Window_end_exclusive_s": end, "Samples": len(samples),
            "Mapping_qualification": mapping,
            "Comparison_qualification": "Later DFT window versus initial symmetrical Ikpp; different dynamic/network assumptions; no accuracy pass/fail",
            "Measured_source": str(phasor_path.relative_to(ROOT)).replace("\\", "/"),
            "Measured_source_sha256": sha256(phasor_path),
            "Reference_source": str(REFERENCE.relative_to(ROOT)).replace("\\", "/"),
            "Reference_source_sha256": sha256(REFERENCE),
        }
        for phase, measured in zip("ABC", phase_means):
            rows.append(dict(common, Quantity=f"Phase_{phase}", Phase_faulted=int(phase in active),
                             Measured_fundamental_A=measured, Frozen_governing_Ikpp_A="",
                             Difference_A="", Difference_percent="", Formula=f"mean(abs(I{phase.lower()}))",
                             Status="MEASURED_PHASE_NO_PHASE_SPECIFIC_REFERENCE"))
        difference = 100 * (value / reference_a - 1)
        rows.append(dict(common, Quantity="Governing", Phase_faulted="",
                         Measured_fundamental_A=value, Frozen_governing_Ikpp_A=reference_a,
                         Difference_A=value-reference_a, Difference_percent=difference,
                         Formula=formulas[kind], Status="QUALIFIED_DIFFERENT_STAGE_AND_MODEL"))
        summary.append(f"| {scenario} | {location} {kind} | {value:.6f} | {reference_a:.6f} | {difference:+.3f}% |")
    output = ROOT / "results/fault_reference_comparison.csv"
    with output.open("w", newline="", encoding="utf-8") as stream:
        writer = csv.DictWriter(stream, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)
    text = """# Fault-current reference comparison

This comparison was recomputed from the saved September 23 Phase 6 complex
phasors. It does not rerun MATLAB or alter the model. The CSV contains the three
measured phase currents and one governing comparison for each of seven cases.

| Scenario | Frozen location/type | Phase 6 fundamental (A) | Frozen initial Ikpp (A) | Difference |
|---|---|---:|---:|---:|
""" + "\n".join(summary) + """

## Meaning of the comparison

The Phase 6 column uses the mean of 39 complete post-fault phasor windows,
0.171 <= t < 0.210 s, before any breaker open command. The governing quantity
follows `matlab/phase4/phase4_solve.m`: positive-sequence |I1| for 3PH, |Ia| for
SLG, and max(|Ib|, |Ic|) for LL/LLG. Each quantity is calculated at every sample
before averaging. The CSV retains the individual A/B/C means, without inventing
phase-specific frozen references. All currents are RMS amperes; waveform peaks
and waveform RMS containing DC offset are excluded from the comparison.

The reference is `data/phase5_reference/phase5_fault_inputs.csv`, selected by
LF360_GAT_OUT, m=0.5 and stage Ikpp. It preserves the locked Phase 4 initial
symmetrical fault calculation. F1 is the generator 22 kV bus, F2 the GSUT LV
interface, F3 the GIS bus, F4 the midpoint of one South circuit, and F5 the
remote bus. GSUT HV uses the adjacent F3 electrical reference with an explicit
protection-boundary qualification.

Every governing comparison is **QUALIFIED_DIFFERENT_STAGE_AND_MODEL**. No
accuracy tolerance or PASS is asserted. Phase 6 uses a synchronous machine and
a later measurement window in which subtransient current is already decaying.
Its selected PHASE3_BASELINE retains Rgrid=0 and adds declared zero-sequence
assumptions; the frozen fault backbone uses finite grid resistance and its own
sequence assumptions. Phase 6 has 0.01 ohm fault/ground resistances. The later
PHASE5_STUDY grid, line and GSUT alternatives are a separate profile and were
not used to regenerate the frozen fault CSV. The larger generator/LV deltas
therefore require this qualification; no parameter was adjusted to force agreement.

Source paths and SHA-256 hashes, exact windows, sample counts, formulas and
signed differences are retained in `results/fault_reference_comparison.csv`.
Regenerate it with `scripts/export_phase6_fault_reference.py` using Python 3.
The generator checks unique reference keys and independently reconstructs all
21 phase means against the existing `fault_summary.csv` values before writing.

## Interruption and internal generator faults

`breaker_times.csv` measures current cessation at the opened breaker branch.
It does not prove extinction of a generator-side internal fault. In the saved
generator 3PH run, GCB opens at 0.247 s, yet faultGEN still carries about
27.1-27.5 kA waveform RMS at 0.400 s. In the timed generator SLG run, GCB opens
at 1.971 s, yet faultGEN carries 6.863 A at 2.200 s. These faults are scheduled
off at 0.450 s and 2.300 s respectively. The model commands field/prime-mover
shutdown and retains stored machine energy; these records demonstrate external
branch isolation and source-input decay, not a verified full internal-fault
extinction time or long-duration post-fault stability.
"""
    (ROOT / "docs/FAULT_REFERENCE_COMPARISON.md").write_text(text, encoding="utf-8")
    assert len(read_csv(output)) == 28
    print(f"FAULT_REFERENCE_EXPORT_PASS: {len(rows)} rows, seven governing comparisons, 21 phase means verified")
    for row in rows:
        if row["Quantity"] == "Governing":
            print(f"{row['Scenario']}: {row['Measured_fundamental_A']:.6f} A; delta {row['Difference_percent']:+.3f}% QUALIFIED")


if __name__ == "__main__":
    main()
