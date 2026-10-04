from pathlib import Path

def run_checks():
    base = Path(r"c:\Users\Sindid\OneDrive\Desktop\MouseWithoutBorders\306 Power Project -ekkebare f")
    dirs = [
        base / "Phase 4 Docs",
        base / "Simulation_Workspace" / "docs" / "phase4"
    ]

    images = [
        "simulink_fault_locations_marked.png",
        "sld_fault_locations_marked.png",
        "sld_crop_f1_generator.png",
        "sld_crop_f2_gsut_lv.png",
        "sld_crop_f3_gis_switchyard.png",
        "sld_crop_f4_line_midpoint.png",
        "sld_crop_f5_remote_grid.png"
    ]

    print("=== 1. VERIFYING SNAPSHOT FILES IN BOTH DIRECTORIES ===")
    all_ok = True
    for d in dirs:
        snap_dir = d / "snapshots"
        print(f"Checking {snap_dir}:")
        for img in images:
            p = snap_dir / img
            if p.exists() and p.stat().st_size > 0:
                print(f"  [OK] {img} ({p.stat().st_size:,} bytes)")
            else:
                print(f"  [FAIL] {img} missing or empty!")
                all_ok = False

    print("\n=== 2. VERIFYING HTML FILES CONTENT & TAGS ===")
    for d in dirs:
        html_file = d / "FAULT_ANALYSIS_MANUAL.html"
        content = html_file.read_text(encoding="utf-8")
        assert 'id="sld-detail"' in content, f"Missing sld-detail in {html_file}"
        for img in images:
            assert img in content, f"Missing {img} reference in {html_file}"
        assert 'class="presentation-bar"' in content, f"Missing presentation bar in {html_file}"
        print(f"  [OK] {html_file.name} in {d.name} verified: {len(content):,} chars, all images referenced.")

    print("\n=== 3. VERIFYING MARKDOWN FILES CONTENT ===")
    for d in dirs:
        md_file = d / "FAULT_ANALYSIS_MANUAL.md"
        content = md_file.read_text(encoding="utf-8")
        assert "3.2b Master SLD High-Definition Close-Up Crops" in content, f"Missing Section 3.2b in {md_file}"
        for img in images:
            assert img in content, f"Missing {img} in {md_file}"
        print(f"  [OK] {md_file.name} in {d.name} verified: {len(content):,} chars, all images referenced.")

    if all_ok:
        print("\nALL VERIFICATIONS PASSED SUCCESSFULLY!")

if __name__ == "__main__":
    run_checks()
