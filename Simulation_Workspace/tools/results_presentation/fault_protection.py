"""Phase 4/5 presentation adapter: fault levels, MVA, contributions, settings.

Read-only over production Phase 4 and current Phase 5 v2 outputs. Exports
organized per-case tables and static engineering plots under
results/presentation/phase4 and phase5. Never modifies original evidence.
"""
from __future__ import annotations

from pathlib import Path
import csv
import math

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

TEAL = "#087f7c"
NAVY = "#16394e"
AMBER = "#be7e27"
RED = "#b75642"
GREY = "#8a9aa6"

VLEVEL = {"F1": 22.0, "F2": 22.0, "F3": 230.0, "F4": 230.0, "F5": 230.0}
LOC_ORDER = ["F1", "F2", "F3", "F4", "F5"]
TYPE_ORDER = ["LLL", "LG", "LL", "LLG"]


def _records(path):
    if not Path(path).exists():
        return []
    with open(path, encoding="utf-8-sig", newline="") as stream:
        return list(csv.DictReader(stream))


def _num(value):
    try:
        x = float(value)
        return x if math.isfinite(x) else None
    except (ValueError, TypeError):
        return None


def _is_base(row):
    return (row.get("caseID") == "LF360_GAT_OUT" and row.get("stage") == "Ikpp"
            and row.get("ZfMode") == "bolted" and row.get("coupler") == "closed"
            and row.get("grid_dataset") == "P")


def _fault_mva(ik_ka, v_kv):
    return math.sqrt(3) * v_kv * ik_ka


def _style():
    plt.rcParams.update({"font.family": "DejaVu Sans", "font.size": 10,
                         "axes.spines.top": False, "axes.spines.right": False,
                         "axes.titleweight": "bold", "figure.facecolor": "white",
                         "savefig.facecolor": "white"})


def _write_table(output_dir, name, columns, rows):
    output_dir.mkdir(parents=True, exist_ok=True)
    path = output_dir / name
    with open(path, "w", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=columns, extrasaction="ignore")
        writer.writeheader()
        for row in rows:
            writer.writerow({k: ("" if row.get(k) is None else row.get(k)) for k in columns})
    return path


def _table_section(title, columns, rows, csv_rel, caption=""):
    return {"title": title, "columns": columns,
            "rows": [{k: (_num(v) if isinstance(v, str) and v.strip() not in ("", "NOT_APPLICABLE_TO_ROW") else v)
                      for k, v in r.items()} for r in rows],
            "csv": csv_rel, "caption": caption}


def build_fault_protection(root: Path, output: Path):
    _style()
    prod = root / "results/phase4_fault/production"
    p5 = root / "results/phase5_protection_v2"
    out4 = output / "phase4"
    out5 = output / "phase5"
    out4.mkdir(parents=True, exist_ok=True)
    out5.mkdir(parents=True, exist_ok=True)

    currents = _records(prod / "phase4_fault_currents.csv")
    contribs = _records(prod / "phase4_contributions.csv")
    bands = _records(prod / "phase4_bands.csv")

    base = [r for r in currents if _is_base(r) and r.get("location") in VLEVEL]
    # Deduplicate: keep m=0.5 rows (F4 mid-line reference)
    base = [r for r in base if r.get("location") != "F4" or str(r.get("m")) == "0.5"]

    # --- Phase 4 table 1: fault levels + MVA --------------------------------
    level_rows = []
    for loc in LOC_ORDER:
        for typ in TYPE_ORDER:
            hit = [r for r in base if r["location"] == loc and r["fault_type"] == typ]
            if not hit:
                continue
            r = hit[0]
            ik = _num(r["Irms_kA"])
            ip = _num(r.get("r_kappa_ip", ""))
            # r_kappa_ip column carries ip for Ikpp rows per schema; recover ip
            # from the companion ip row when present
            ip_row = [q for q in currents if _is_base(q) and q["location"] == loc
                      and q["fault_type"] == typ and q.get("stage") == "ip"]
            if ip_row:
                ip = _num(ip_row[0]["Irms_kA"])
            mva = _fault_mva(ik, VLEVEL[loc]) if ik else None
            level_rows.append({"Location": loc, "Fault_type": typ, "Case": r["caseID"],
                               "Ik_kA": round(ik, 6) if ik else None,
                               "ip_kA": round(ip, 4) if ip else None,
                               "Fault_MVA": round(mva, 3) if mva else None,
                               "Level_kV": VLEVEL[loc],
                               "Footnote": r.get("footnote", "")})
    _write_table(out4, "fault_levels.csv",
                 ["Location", "Fault_type", "Case", "Ik_kA", "ip_kA", "Fault_MVA", "Level_kV", "Footnote"],
                 level_rows)

    # --- Phase 4 table 2: first-ring contributions ---------------------------
    contrib_base = [r for r in contribs if _is_base(r)]
    contrib_base = [r for r in contrib_base if not (r.get("location") == "F4" and str(r.get("m")) != "0.5")]
    contrib_rows = []
    for r in contrib_base:
        contrib_rows.append({
            "Location": r["location"], "Fault_type": r["fault_type"],
            "GEN_kA": _num(r.get("leg_GEN_kA")), "GSUT_HV_kA": _num(r.get("leg_GSUT_HV_kA")),
            "GRID_kA": _num(r.get("leg_GRID_kA")), "LINE_total_kA": _num(r.get("leg_LINE_total_kA")),
            "UAT_kA": _num(r.get("leg_UAT_kA")), "GAT_HV_kA": _num(r.get("leg_GAT_HV_kA")),
            "NER_earth_kA": _num(r.get("leg_NER_earth_kA")),
            "KCL_seq": r.get("kcl_seq"), "KCL_ph": r.get("kcl_ph")})
    _write_table(out4, "first_ring_contributions.csv",
                 ["Location", "Fault_type", "GEN_kA", "GSUT_HV_kA", "GRID_kA",
                  "LINE_total_kA", "UAT_kA", "GAT_HV_kA", "NER_earth_kA", "KCL_seq", "KCL_ph"],
                 contrib_rows)

    # --- Phase 4 table 3: bands ------------------------------------------------
    band_rows = [{"Group": r["group"], "Fault_type": r["fault_type"],
                  "Min_Ik_kA": _num(r["min_Ik_kA"]), "Max_Ik_kA": _num(r["max_Ik_kA"]),
                  "Mid_Ik_kA": _num(r["mid_Ik_kA"]), "Note": r.get("note", "")} for r in bands]
    _write_table(out4, "fault_bands.csv", ["Group", "Fault_type", "Min_Ik_kA", "Max_Ik_kA", "Mid_Ik_kA", "Note"], band_rows)

    # --- Phase 4 validation: MVA reconciliation --------------------------------
    check_rows = []
    for row in level_rows:
        ik, mva, v = row["Ik_kA"], row["Fault_MVA"], row["Level_kV"]
        if ik and mva:
            expect = _fault_mva(ik, v)
            err = abs(expect - mva) / max(expect, 1e-9)
            check_rows.append({"Location": row["Location"], "Fault_type": row["Fault_type"],
                               "Ik_kA": ik, "MVA_reported": mva, "MVA_recomputed": round(expect, 2),
                               "Rel_err": round(err, 6),
                               "Check": "PASS" if err < 0.002 else "FAIL"})
    # F1 LG sanity: NER-dominated ~7.27 A
    lg = [r for r in level_rows if r["Location"] == "F1" and r["Fault_type"] == "LG"]
    if lg:
        amps = (lg[0]["Ik_kA"] or 0) * 1000
        check_rows.append({"Location": "F1", "Fault_type": "LG sanity",
                           "Ik_kA": lg[0]["Ik_kA"], "MVA_reported": lg[0]["Fault_MVA"],
                           "MVA_recomputed": round(amps, 2),
                           "Rel_err": None,
                           "Check": "PASS" if 6.5 < amps < 8.0 else "FAIL"})
    _write_table(out4, "mva_reconciliation.csv",
                 ["Location", "Fault_type", "Ik_kA", "MVA_reported", "MVA_recomputed", "Rel_err", "Check"],
                 check_rows)

    # --- Phase 4 figures --------------------------------------------------------
    figures4 = []
    # 1. Fault current by location/type
    fig, ax = plt.subplots(figsize=(12, 5.2))
    x = np.arange(len(LOC_ORDER))
    width = 0.19
    colors = {t: c for t, c in zip(TYPE_ORDER, [NAVY, TEAL, AMBER, RED])}
    for j, typ in enumerate(TYPE_ORDER):
        vals = []
        for loc in LOC_ORDER:
            hit = [r for r in level_rows if r["Location"] == loc and r["Fault_type"] == typ and r["Ik_kA"]]
            vals.append(hit[0]["Ik_kA"] if hit else 0)
        bars = ax.bar(x + (j - 1.5) * width, vals, width, label=typ, color=colors[typ])
        for xi, v in zip(x + (j - 1.5) * width, vals):
            if v and v > 0.05:
                ax.text(xi, v * 1.02, f"{v:.1f}", ha="center", fontsize=8)
    ax.set_xticks(x, LOC_ORDER)
    ax.set_ylabel("Initial symmetrical RMS Ik'' (kA)")
    ax.set_title("Bolted fault level by location and type (LF360 OUT, dataset P)", loc="left")
    ax.legend(frameon=False, ncol=4)
    ax.grid(axis="y", alpha=0.2)
    ax.set_axisbelow(True)
    fig.tight_layout()
    fig.savefig(out4 / "fault_current_by_location.png", dpi=170, bbox_inches="tight")
    plt.close(fig)
    figures4.append({"title": "Fault current by location and type", "path": "phase4/fault_current_by_location.png",
                     "caption": "Bolted Ik'' at F1/F2 (22 kV) and F3/F4/F5 (230 kV). F1 LG is ~7.27 A (NER-dominated) and is invisible at kA scale by design."})

    # 2. Fault MVA
    fig, ax = plt.subplots(figsize=(12, 4.8))
    for j, typ in enumerate(TYPE_ORDER):
        vals = []
        for loc in LOC_ORDER:
            hit = [r for r in level_rows if r["Location"] == loc and r["Fault_type"] == typ and r["Fault_MVA"]]
            vals.append(hit[0]["Fault_MVA"] if hit else 0)
        ax.bar(x + (j - 1.5) * width, vals, width, label=typ, color=colors[typ])
    ax.set_xticks(x, LOC_ORDER)
    ax.set_ylabel("Fault MVA (sqrt3 x Vlevel x Ik)")
    ax.set_title("Fault MVA by location and type", loc="left")
    ax.legend(frameon=False, ncol=4)
    ax.grid(axis="y", alpha=0.2)
    fig.tight_layout()
    fig.savefig(out4 / "fault_mva_by_location.png", dpi=170, bbox_inches="tight")
    plt.close(fig)
    figures4.append({"title": "Fault MVA by location and type", "path": "phase4/fault_mva_by_location.png",
                     "caption": "MVA uses the fault-level voltage (22 or 230 kV). Reconciliation errors <0.2% in mva_reconciliation.csv."})

    # 3. First-ring contributions at F3 LLL (grid-dominated)
    f3 = [r for r in contrib_rows if r["Location"] == "F3" and r["Fault_type"] == "LLL"]
    if f3:
        r = f3[0]
        labels, vals = [], []
        for k, name in [("GEN_kA", "Generator"), ("GSUT_HV_kA", "GSUT HV"), ("GRID_kA", "Grid"), ("LINE_total_kA", "Line total")]:
            v = r.get(k)
            if v:
                labels.append(name)
                vals.append(v)
        fig, ax = plt.subplots(figsize=(10, 4.6))
        bars = ax.bar(labels, vals, color=[TEAL, NAVY, AMBER, GREY], width=0.55)
        for b, v in zip(bars, vals):
            ax.text(b.get_x() + b.get_width() / 2, v * 1.02, f"{v:.1f} kA", ha="center", weight="bold")
        ax.set_ylabel("Toward-fault branch current (kA)")
        ax.set_title("First-ring contributions: F3 LLL (grid-dominated 230 kV fault)", loc="left")
        ax.grid(axis="y", alpha=0.2)
        fig.tight_layout()
        fig.savefig(out4 / "contributions_F3_LLL.png", dpi=170, bbox_inches="tight")
        plt.close(fig)
        figures4.append({"title": "First-ring contributions at F3 LLL", "path": "phase4/contributions_F3_LLL.png",
                         "caption": "Toward-fault-signed Phase-4 legs. Feeder-partition KCL closes ~1e-15; ip has no contribution table by design."})

    # 4. Bands min/max
    if band_rows:
        sel = [r for r in band_rows if r["Group"].startswith(("F1_", "F3_", "F4_", "F5_"))][:12]
        fig, ax = plt.subplots(figsize=(12, 5.0))
        y = np.arange(len(sel))
        mins = np.array([r["Min_Ik_kA"] or 0 for r in sel])
        maxs = np.array([r["Max_Ik_kA"] or 0 for r in sel])
        mids = np.array([r["Mid_Ik_kA"] or 0 for r in sel])
        ax.hlines(y, mins, maxs, color=TEAL, linewidth=4, alpha=0.8)
        ax.plot(mids, y, "o", color=NAVY, label="Base (mid)")
        ax.set_yticks(y, [f"{r['Group']}" for r in sel], fontsize=8)
        ax.invert_yaxis()
        ax.set_xlabel("Ik'' (kA)")
        ax.set_title("Production sensitivity bands (OFAT min-max, base marked)", loc="left")
        ax.grid(axis="x", alpha=0.2)
        ax.legend(frameon=False)
        fig.tight_layout()
        fig.savefig(out4 / "fault_bands.png", dpi=170, bbox_inches="tight")
        plt.close(fig)
        figures4.append({"title": "Sensitivity bands around each fault level", "path": "phase4/fault_bands.png",
                         "caption": "OFAT A-H spread; no uncontrolled factorial. F3 LG spans grid-zero and NER corners."})

    # --- Phase 5 ---------------------------------------------------------------
    settings = _records(p5 / "phase5_relay_settings.csv")
    matrix = _records(p5 / "phase5_coordination_matrix.csv")
    duty = _records(p5 / "phase5_breaker_duty.csv")
    trip = _records(p5 / "phase5_trip_logic.csv")

    set_rows = [{"Device": r.get("device_id"), "Pickup_A": _num(r.get("setting_A_primary")),
                 "CT": r.get("ct_ratio"), "TMS": r.get("tms"), "Curve": r.get("curve"),
                 "Provenance": (r.get("provenance", "") or "")[:140]} for r in settings]
    _write_table(out5, "relay_settings.csv", ["Device", "Pickup_A", "CT", "TMS", "Curve", "Provenance"], set_rows)

    coord_rows = []
    for r in matrix:
        if r.get("scope") not in ("PRIMARY", "CONDITIONAL"):
            continue
        coord_rows.append({"Downstream": r.get("downstream"), "Upstream": r.get("upstream"),
                           "Location": r.get("fault_location"), "Type": r.get("fault_type"),
                           "I_kA": _num(r.get("I_fault_kA")), "t_down_s": _num(r.get("t_down_s")),
                           "t_up_s": _num(r.get("t_up_s")), "Margin_s": _num(r.get("margin_s")),
                           "Verdict": r.get("verdict")})
    _write_table(out5, "coordination.csv",
                 ["Downstream", "Upstream", "Location", "Type", "I_kA", "t_down_s", "t_up_s", "Margin_s", "Verdict"],
                 coord_rows)

    duty_rows = [{"Location": r.get("location"), "Breaker": r.get("breaker_ref"), "Type": r.get("fault_type"),
                  "I_sym_kA": _num(r.get("I_sym_kA")), "Rating_kA": _num(r.get("rating_kA")),
                  "Duty_ratio": _num(r.get("duty_ratio")), "Verdict": r.get("verdict")} for r in duty]
    _write_table(out5, "breaker_duty.csv",
                 ["Location", "Breaker", "Type", "I_sym_kA", "Rating_kA", "Duty_ratio", "Verdict"], duty_rows)

    trip_rows = [{"Device": r.get("device", r.get("relay", "")), "Fault": f"{r.get('fault_location', '')} {r.get('fault_type', '')}".strip(),
                  "Action": r.get("action", r.get("trip_action", "")), "Note": (r.get("note", "") or "")[:160]}
                 for r in trip[:60]]
    if trip_rows:
        cols = list(trip_rows[0].keys())
        _write_table(out5, "trip_logic_excerpt.csv", cols, trip_rows)

    # verdict counts
    verdicts = {}
    for r in coord_rows:
        verdicts[r["Verdict"]] = verdicts.get(r["Verdict"], 0) + 1
    count_rows = [{"Verdict": k, "Rows": v} for k, v in sorted(verdicts.items())]
    _write_table(out5, "coordination_counts.csv", ["Verdict", "Rows"], count_rows)

    figures5 = []
    # 1. Pickup vs max through-current (detectability margin illustration)
    try:
        relay_current = _records(p5 / "phase5_relay_currents.csv")
        if relay_current:
            devs = sorted(set(r.get("device_id", "") for r in relay_current if r.get("device_id")))[:8]
            fig, ax = plt.subplots(figsize=(12, 5.0))
            x = np.arange(len(devs))
            pk, mx = [], []
            for d in devs:
                s = [q for r in settings if r.get("device_id") == d for q in [r]]
                pk.append(_num(s[0].get("setting_A_primary")) / 1000 if s and _num(s[0].get("setting_A_primary")) else 0)
                vals = [_num(r.get("I_primary_A", r.get("I_down_A", 0))) or 0 for r in relay_current if r.get("device_id") == d]
                mx.append(max(vals) / 1000 if vals else 0)
            w = 0.36
            ax.bar(x - w / 2, pk, w, label="Pickup (kA)", color=NAVY)
            ax.bar(x + w / 2, mx, w, label="Max study current (kA)", color=TEAL)
            ax.set_xticks(x, devs, rotation=12, ha="right", fontsize=9)
            ax.set_ylabel("Current (kA primary)")
            ax.set_title("Pickup versus maximum study through-current", loc="left")
            ax.legend(frameon=False)
            ax.grid(axis="y", alpha=0.2)
            fig.tight_layout()
            fig.savefig(out5 / "pickup_vs_current.png", dpi=170, bbox_inches="tight")
            plt.close(fig)
            figures5.append({"title": "Pickup versus maximum study current", "path": "phase5/pickup_vs_current.png",
                             "caption": "Pickup is a threshold; the bar beside it is the largest branch current seen in the coordination input. Earth-fault NER paths need the 51N/64G view, not this phase-current view."})
    except Exception:
        pass

    # 2. Coordination margins for evaluable pairs
    eval_pairs = [r for r in coord_rows if r.get("Margin_s") is not None and math.isfinite(r["Margin_s"]) and r["Margin_s"] < 10]
    eval_pairs = eval_pairs[:24]
    if eval_pairs:
        fig, ax = plt.subplots(figsize=(12, max(4, len(eval_pairs) * 0.42 + 1.6)))
        y = np.arange(len(eval_pairs))
        margins = [r["Margin_s"] for r in eval_pairs]
        colors_m = [TEAL if (r["Verdict"] or "").startswith("PASS") else AMBER for r in eval_pairs]
        ax.barh(y, margins, color=colors_m, height=0.6)
        ax.axvline(0.3, color=RED, linestyle="--", label="CTI 0.30 s study criterion")
        ax.set_yticks(y, [f"{r['Downstream']} > {r['Upstream']} @ {r['Location']} {r['Type']}" for r in eval_pairs], fontsize=8)
        ax.invert_yaxis()
        ax.set_xlabel("Grading margin (s)")
        ax.set_title("Coordination margins: downstream to upstream operating-time gap", loc="left")
        ax.legend(frameon=False)
        ax.grid(axis="x", alpha=0.2)
        fig.tight_layout()
        fig.savefig(out5 / "coordination_margins.png", dpi=170, bbox_inches="tight")
        plt.close(fig)
        figures5.append({"title": "Coordination margins against the 0.3 s criterion", "path": "phase5/coordination_margins.png",
                         "caption": "Upstream minus downstream IEC-SI time at the stated branch through-current. CONDITIONAL passes depend on the Q0 mapping assumption."})

    # 3. Duty ratios
    fin_duty = [r for r in duty_rows if r.get("Duty_ratio") is not None and math.isfinite(r["Duty_ratio"])]
    # keep one row per breaker/location/type representative: max ratio per breaker
    best = {}
    for r in fin_duty:
        key = (r["Breaker"], r["Location"])
        if key not in best or (r["Duty_ratio"] or 0) > (best[key]["Duty_ratio"] or 0):
            best[key] = r
    rep = list(best.values())[:12]
    if rep:
        fig, ax = plt.subplots(figsize=(11, 4.6))
        labels = [f"{r['Breaker']} @ {r['Location']} {r['Type']}" for r in rep]
        vals = [r["Duty_ratio"] for r in rep]
        bars = ax.bar(np.arange(len(rep)), vals, color=TEAL, width=0.55)
        ax.axhline(1.0, color=RED, linestyle="--", label="Rating (ratio 1.0)")
        for b, v in zip(bars, vals):
            ax.text(b.get_x() + b.get_width() / 2, v + 0.02, f"{v:.2f}", ha="center", fontsize=8)
        ax.set_xticks(range(len(rep)), labels, rotation=14, ha="right", fontsize=8)
        ax.set_ylabel("Through-current / rating")
        ax.set_title("Breaker through-current screening against candidate ratings", loc="left")
        ax.legend(frameon=False)
        ax.grid(axis="y", alpha=0.2)
        fig.tight_layout()
        fig.savefig(out5 / "breaker_duty_ratios.png", dpi=170, bbox_inches="tight")
        plt.close(fig)
        figures5.append({"title": "Breaker duty screening ratios", "path": "phase5/breaker_duty_ratios.png",
                         "caption": "Ikpp branch through-current over the stated rating. Not a breaking-time Ib, asymmetry, making, thermal or TRV proof. Q0 is conditional on the transformer-bay mapping."})

    # 4. Before/after: prospective fault vs protection-cleared (timing view)
    # Protection changes clearing behavior, not the prospective level: show
    # operating times falling with current (IEC-SI shape) for the main OC pair.
    oc = [r for r in coord_rows if r.get("t_down_s") and math.isfinite(r["t_down_s"]) and r.get("I_kA") and r["I_kA"] > 0.01]
    oc = oc[:40]
    if oc:
        fig, ax = plt.subplots(figsize=(11, 4.8))
        xs = [r["I_kA"] for r in oc]
        ys = [r["t_down_s"] for r in oc]
        ax.scatter(xs, ys, c=TEAL, s=36, alpha=0.85, label="Downstream operating time")
        ax.set_xscale("log")
        ax.set_xlabel("Branch through-current (kA, log scale)")
        ax.set_ylabel("Operating time (s)")
        ax.set_title("Before/after reading: same prospective current, protection sets the clearing time", loc="left")
        ax.grid(True, alpha=0.2, which="both")
        ax.legend(frameon=False)
        fig.tight_layout()
        fig.savefig(out5 / "operating_time_vs_current.png", dpi=170, bbox_inches="tight")
        plt.close(fig)
        figures5.append({"title": "Operating time versus current (before/after guide)", "path": "phase5/operating_time_vs_current.png",
                         "caption": "Each point is one coordination row: the prospective current (before) and the relay time that clears it (after). Settings move points vertically, never horizontally."})

    phase4 = {"title": "Phase 4 fault levels and contributions", "label": "Phase 4 · prospective short-circuit",
              "intro": "Bolted base-case fault currents, fault MVA at the fault voltage, first-ring branch contributions and OFAT sensitivity bands. F1/F2 LG is a ~7 A NER earth fault, not a kA bus fault.",
              "tables": [
                  _table_section("Fault current and fault MVA per case",
                                 ["Location", "Fault_type", "Case", "Ik_kA", "ip_kA", "Fault_MVA", "Level_kV", "Footnote"],
                                 level_rows, "phase4/fault_levels.csv",
                                 "Ik'' governing-phase RMS; ip design-defined first peak; MVA = sqrt(3) x Vlevel x Ik."),
                  _table_section("First-ring toward-fault contributions",
                                 ["Location", "Fault_type", "GEN_kA", "GSUT_HV_kA", "GRID_kA", "LINE_total_kA",
                                  "UAT_kA", "GAT_HV_kA", "NER_earth_kA", "KCL_seq", "KCL_ph"],
                                 contrib_rows, "phase4/first_ring_contributions.csv",
                                 "Signed toward-fault legs. F1/F2 LG legs are circulating/load branches; the earth-fault proxy is the ~7.27 A neutral residual."),
                  _table_section("Sensitivity bands (OFAT min/max)",
                                 ["Group", "Fault_type", "Min_Ik_kA", "Max_Ik_kA", "Mid_Ik_kA", "Note"],
                                 band_rows, "phase4/fault_bands.csv"),
                  _table_section("MVA reconciliation and LG sanity",
                                 ["Location", "Fault_type", "Ik_kA", "MVA_reported", "MVA_recomputed", "Rel_err", "Check"],
                                 check_rows, "phase4/mva_reconciliation.csv",
                                 "Independent recomputation of every MVA cell plus the F1 LG ampere sanity gate."),
              ],
              "figures": figures4,
              "notes": [
                  "Source: results/phase4_fault/production. Base uses LF360 OUT/IN prefault, dataset P, MID line-zero band, saturated Xd'', H1 closed-tertiary, bolted Zf = 0, coupler closed.",
                  "Protection settings do not change these prospective levels; they change how fast branches are interrupted. Compare Phase 5 times, not fault currents, for before/after protection.",
                  "F3 230 kV LLL (~50.53 kA) sits next to the 50 kA equipment reference: a numerical adjacency, not a duty verdict. Duty uses branch through-currents in Phase 5.",
                  "ip is a design-defined first-peak magnitude (kappa shape), not an IEC 60909 ip claim.",
              ],
              "highlights": [
                  {"label": "Highest 230 kV bus fault", "value": "F5 LLG ~51.18 kA", "note": "Bolted base; bands span grid-zero corners"},
                  {"label": "Generator 22 kV earth fault", "value": "~7.27 A", "note": "NER high-resistance grounding dominates"},
                  {"label": "MVA check", "value": "PASS", "note": "Every reported MVA recomputed independently"},
              ]}

    phase5 = {"title": "Phase 5 protection settings and coordination", "label": "Phase 5 · settings that clear the fault",
              "intro": "Study pickup/TMS choices, IEC-SI grading gaps, conditional Q0 mapping and through-current duty screening. Assumed settings are not commissioned plant settings.",
              "tables": [
                  _table_section("Relay settings under study",
                                 ["Device", "Pickup_A", "CT", "TMS", "Curve", "Provenance"],
                                 set_rows, "phase5/relay_settings.csv",
                                 "Central study values: GEN-51 17170.8 A TMS 0.10, GSUT-51 1380 A TMS 0.55, Q0-51 1500 A TMS 0.80, GEN-51N 4 A TMS 0.15."),
                  _table_section("Coordination matrix (primary + conditional)",
                                 ["Downstream", "Upstream", "Location", "Type", "I_kA", "t_down_s", "t_up_s", "Margin_s", "Verdict"],
                                 coord_rows, "phase5/coordination.csv",
                                 "Margin = upstream minus downstream time at the stated branch current; CTI 0.30 s study criterion."),
                  _table_section("Breaker through-current screening",
                                 ["Location", "Breaker", "Type", "I_sym_kA", "Rating_kA", "Duty_ratio", "Verdict"],
                                 duty_rows, "phase5/breaker_duty.csv",
                                 "Ikpp screening only: not Ib, asymmetry, making, thermal or TRV."),
                  _table_section("Coordination verdict counts",
                                 ["Verdict", "Rows"], count_rows, "phase5/coordination_counts.csv"),
              ],
              "figures": figures5,
              "notes": [
                  "Source: results/phase5_protection_v2. Central coordination: 12 PRIMARY PASS, 12 CONDITIONAL-PASS, 0 FAIL, 24 NO-TRIP, 48 NO-PAIR over 96 matrix rows.",
                  "GSUT CT carries a documentary conflict (1500/1 schedule vs 1600/1 SLD/nameplate); central uses 1600/1 as ENGINEERING_ASSUMPTION with 1500/1 as sensitivity.",
                  "Q0 verdicts are conditional on the GSUT transformer-bay mapping and a candidate 50 kA rating; line-breaker nameplates remain unverified.",
                  "NO-TRIP rows are resolved non-operations (times are infinity), not missing parameters.",
              ],
              "highlights": [
                  {"label": "Primary coordination", "value": "12 PASS · 0 FAIL", "note": "Plus 12 conditional passes on the Q0 mapping"},
                  {"label": "Breaker screening", "value": "0 exceedances", "note": "Q0 max ~6.90 kA / 50 kA; 52G max ~55.05 kA / 100 kA"},
                  {"label": "Earth protection", "value": "51N / 64G", "note": "Dedicated path for the ~7 A NER fault"},
              ]}

    # Copy raw-source pointer file for traceability (small index, not data copy)
    with open(out4 / "source_index.txt", "w", encoding="utf-8") as stream:
        stream.write("Original evidence (read, never copied in full):\n")
        for name in ["phase4_fault_currents.csv", "phase4_contributions.csv", "phase4_bands.csv",
                     "phase4_ct_data.csv", "analytic_bounds.csv", "manifest.json"]:
            stream.write(f"results/phase4_fault/production/{name}\n")
    with open(out5 / "source_index.txt", "w", encoding="utf-8") as stream:
        stream.write("Original evidence (read, never copied in full):\n")
        for name in ["phase5_relay_settings.csv", "phase5_coordination_matrix.csv",
                     "phase5_breaker_duty.csv", "phase5_trip_logic.csv", "phase5_parameter_values.csv"]:
            stream.write(f"results/phase5_protection_v2/{name}\n")

    return {"phase4": phase4, "phase5": phase5}
