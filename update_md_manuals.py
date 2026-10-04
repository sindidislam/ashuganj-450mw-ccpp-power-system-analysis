from pathlib import Path

def update_markdown_manuals():
    base_dir = Path(r"c:\Users\Sindid\OneDrive\Desktop\MouseWithoutBorders\306 Power Project -ekkebare f")
    p4_ext_md = base_dir / "Phase 4 Docs" / "FAULT_ANALYSIS_MANUAL.md"
    p4_int_md = base_dir / "Simulation_Workspace" / "docs" / "phase4" / "FAULT_ANALYSIS_MANUAL.md"

    md_block = """
### 3.2b Master SLD High-Definition Close-Up Crops (1:1 Native Resolution)
To guarantee complete legibility on presentation displays and projectors from a distance, 1:1 scale high-definition crops of the OEM Master Single Line Diagram are provided below for each of the five fault zones:

| Fault Zone | High-Resolution SLD Crop | Physical Equipment & Study Parameters |
| :--- | :--- | :--- |
| **F1 — Generator Stator Bus** | ![F1 Generator Bus Detail](snapshots/sld_crop_f1_generator.png) | **Tags:** Generator `10MKA10`, GCB `10BAC10`, NER `10BAB11`<br>**Fault:** $I_k'' = 126.21\\text{ kA}$, $i_p = 348.26\\text{ kA}$, $I_k''\\text{ LG} = 7.27\\text{ A}$<br>**Primary Protection:** Relay 87G (Generator Diff), 51N (NER Earth Fault) |
| **F2 — GSUT LV Delta** | ![F2 GSUT LV Detail](snapshots/sld_crop_f2_gsut_lv.png) | **Tags:** GSUT `10BAT10` (515 MVA), UAT `10BBT10` (25 MVA), IPB<br>**Fault:** $I_k'' = 126.21\\text{ kA}$, $i_p = 348.26\\text{ kA}$, Vector Shift: $+30^\\circ$ (YNd1)<br>**Primary Protection:** Relay 87T (Transformer Diff) |
| **F3 — 230 kV GIS Bus** | ![F3 GIS Bus Detail](snapshots/sld_crop_f3_gis_switchyard.png) | **Tags:** GIS Bus 1 `10BAC01`, Bus 2 `10BAC02`, GSUT Bay `10BAY11`<br>**Fault:** $I_k'' = 50.53\\text{ kA}$, $i_p = 136.98\\text{ kA}$, $I_k''\\text{ LG} = 45.74\\text{ kA}$<br>**Primary Protection:** Relay 87B (Busbar Diff, 35 ms high speed) |
| **F4 — 230 kV Line Mid** | ![F4 Line Midpoint Detail](snapshots/sld_crop_f4_line_midpoint.png) | **Tags:** Line 1 & Line 2 (0.7 km Mallard 795 MCM), Disconnectors<br>**Fault:** $I_k'' = 51.06\\text{ kA}$, $i_p = 138.60\\text{ kA}$, $I_k''\\text{ LG} = 46.12\\text{ kA}$<br>**Primary Protection:** Relay 87L (Line Diff, 40 ms) / Relay 21 (Distance Zone 1) |
| **F5 — Remote Grid Bus** | ![F5 Remote Bus Detail](snapshots/sld_crop_f5_remote_grid.png) | **Tags:** Remote Bus `B230_REMOTE` / `BGRID230`, PGCB National Grid Interface<br>**Fault:** $I_k'' = 53.09\\text{ kA}$, $i_p = 144.11\\text{ kA}$, $I_k''\\text{ LG} = 48.47\\text{ kA}$<br>**Relay Action:** Plant relays (87G, 87T, 87B, 87L) **RESTRAIN**; cleared by grid breakers |
"""

    for target in [p4_ext_md, p4_int_md]:
        text = target.read_text(encoding="utf-8")
        if "3.2b Master SLD High-Definition Close-Up Crops" not in text:
            marker = "### 3.3 Individual Simulink Fault Injection Subsystems"
            if marker in text:
                text = text.replace(marker, md_block + "\n" + marker)
                target.write_text(text, encoding="utf-8")
                print(f"Updated {target}")
            else:
                print(f"Marker not found in {target}")
        else:
            print(f"Already present in {target}")

if __name__ == "__main__":
    update_markdown_manuals()
