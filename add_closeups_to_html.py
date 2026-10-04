import re
from pathlib import Path

def update_manual_with_closeups():
    base_dir = Path(r"c:\Users\Sindid\OneDrive\Desktop\MouseWithoutBorders\306 Power Project -ekkebare f")
    p4_ext_html = base_dir / "Phase 4 Docs" / "FAULT_ANALYSIS_MANUAL.html"
    p4_int_html = base_dir / "Simulation_Workspace" / "docs" / "phase4" / "FAULT_ANALYSIS_MANUAL.html"

    content = p4_ext_html.read_text(encoding="utf-8")

    # 1. Update sidebar navigation to include the close-up section
    old_nav_marker = '<a href="#visuals">3 · Marked SLD & Simulink</a>'
    new_nav_marker = '<a href="#visuals">3 · Marked SLD & Simulink</a>\n      <a href="#sld-detail">3b · Master SLD Close-Ups (F1–F5)</a>'
    
    if old_nav_marker in content and '<a href="#sld-detail">' not in content:
        content = content.replace(old_nav_marker, new_nav_marker)
        print("Updated sidebar navigation.")

    # 2. Section 3 Detail Crops HTML Block
    closeup_html = r"""
      <!-- SECTION 3B: HIGH-DEFINITION SLD CLOSE-UP DETAIL VIEWS -->
      <div id="sld-detail" style="margin-top: 40px; padding-top: 20px; border-top: 2px dashed var(--line);">
        <div style="display:flex; align-items:center; justify-content:space-between; flex-wrap:wrap; gap:12px; margin-bottom:18px;">
          <div>
            <h3 style="margin:0; color:var(--navy); font-size:calc(22px * var(--font-scale)); font-weight:800; letter-spacing:-0.015em;">
              🔍 Master SLD Close-Up Inspection — 1:1 Scale Views of Zones F1 to F5
            </h3>
            <p style="margin:6px 0 0; color:var(--text-muted); font-size:calc(15px * var(--font-scale)); max-width:850px;">
              To ensure 100% legibility on projectors and from a distance, below are high-definition 1:1 scale crops from the OEM Master Single Line Diagram. Each crop highlights the exact physical busbar, circuit breaker numbers, instrument transformers, and IEC 60909 fault currents. <i>Click any image to expand full-screen.</i>
            </p>
          </div>
          <span class="status-pill" style="background:#fef3c7; color:#b45309; font-size:calc(13px * var(--font-scale)); font-weight:800; margin-bottom:0;">
            1:1 Native Resolution Crops
          </span>
        </div>

        <div class="grid2">
          <!-- CARD F1 -->
          <figure style="margin: 10px 0;">
            <div class="figure-top-ctrl">
              <span class="figure-tag"><span class="badge badge-f1">F1</span> Generator Bus Detail · 10MKA10</span>
              <button type="button" class="figure-zoom-btn" onclick="openLightbox('snapshots/sld_crop_f1_generator.png')">🔍 HD View</button>
            </div>
            <img src="snapshots/sld_crop_f1_generator.png" alt="F1 Generator Bus SLD Detail" onclick="openLightbox(this.src)" style="cursor:zoom-in;">
            <figcaption>
              <b>Fig. 2a — F1 Generator Stator & Breaker Zone.</b> Shows Generator <code>10MKA10</code> stator terminals, Generator Circuit Breaker <code>10BAC10</code> (100 kA rating), and Neutral Earthing Resistor <code>10BAB11</code>.
              <div style="margin-top:8px; font-size:calc(13px * var(--font-scale)); background:#f8fafc; padding:8px 12px; border-radius:6px; border:1px solid var(--line);">
                <b>Study Values:</b> $I_k'' = 126.21\text{ kA}$ (3-Ph) · $i_p = 348.26\text{ kA}$ · $I_k''\text{ LG} = 7.27\text{ A}$ (NER limited) · <b>Primary Relay:</b> 87G (Generator Diff).
              </div>
            </figcaption>
          </figure>

          <!-- CARD F2 -->
          <figure style="margin: 10px 0;">
            <div class="figure-top-ctrl">
              <span class="figure-tag"><span class="badge badge-f2">F2</span> GSUT LV Terminals Detail · 10BAT10</span>
              <button type="button" class="figure-zoom-btn" onclick="openLightbox('snapshots/sld_crop_f2_gsut_lv.png')">🔍 HD View</button>
            </div>
            <img src="snapshots/sld_crop_f2_gsut_lv.png" alt="F2 GSUT LV Terminals SLD Detail" onclick="openLightbox(this.src)" style="cursor:zoom-in;">
            <figcaption>
              <b>Fig. 2b — F2 GSUT Low-Voltage Delta Terminals.</b> Shows 515 MVA GSUT <code>10BAT10</code> LV delta connection (22 kV side), Unit Auxiliary Transformer <code>10BBT10</code> (25 MVA) take-off, and IPB busduct.
              <div style="margin-top:8px; font-size:calc(13px * var(--font-scale)); background:#f8fafc; padding:8px 12px; border-radius:6px; border:1px solid var(--line);">
                <b>Study Values:</b> $I_k'' = 126.21\text{ kA}$ (3-Ph) · $i_p = 348.26\text{ kA}$ · Vector Shift: $+30^\circ$ (YNd1) · <b>Primary Relay:</b> 87T (Transformer Diff).
              </div>
            </figcaption>
          </figure>

          <!-- CARD F3 -->
          <figure style="margin: 10px 0;">
            <div class="figure-top-ctrl">
              <span class="figure-tag"><span class="badge badge-f3">F3</span> 230 kV GIS Bus Detail · 10BAC01/02</span>
              <button type="button" class="figure-zoom-btn" onclick="openLightbox('snapshots/sld_crop_f3_gis_switchyard.png')">🔍 HD View</button>
            </div>
            <img src="snapshots/sld_crop_f3_gis_switchyard.png" alt="F3 230 kV GIS Bus SLD Detail" onclick="openLightbox(this.src)" style="cursor:zoom-in;">
            <figcaption>
              <b>Fig. 2c — F3 230 kV GIS Switchyard Busbars.</b> Shows Siemens 8DN9 Gas-Insulated Switchgear Bus 1 <code>10BAC01</code> and Bus 2 <code>10BAC02</code>, GSUT Bay <code>10BAY11</code>, and Disconnectors Q1/Q2.
              <div style="margin-top:8px; font-size:calc(13px * var(--font-scale)); background:#f8fafc; padding:8px 12px; border-radius:6px; border:1px solid var(--line);">
                <b>Study Values:</b> $I_k'' = 50.53\text{ kA}$ (3-Ph) · $i_p = 136.98\text{ kA}$ · $I_k''\text{ LG} = 45.74\text{ kA}$ · <b>Primary Relay:</b> 87B Busbar Diff (35 ms high speed).
              </div>
            </figcaption>
          </figure>

          <!-- CARD F4 -->
          <figure style="margin: 10px 0;">
            <div class="figure-top-ctrl">
              <span class="figure-tag"><span class="badge badge-f4">F4</span> 230 kV Line Corridor Detail · Line 1/2</span>
              <button type="button" class="figure-zoom-btn" onclick="openLightbox('snapshots/sld_crop_f4_line_midpoint.png')">🔍 HD View</button>
            </div>
            <img src="snapshots/sld_crop_f4_line_midpoint.png" alt="F4 Transmission Line Corridor SLD Detail" onclick="openLightbox(this.src)" style="cursor:zoom-in;">
            <figcaption>
              <b>Fig. 2d — F4 230 kV Transmission Line Mid-Point ($m = 0.5$).</b> Shows dual-circuit overhead lines (0.7 km Mallard 795 MCM), line disconnectors, and optical current differential relay interface.
              <div style="margin-top:8px; font-size:calc(13px * var(--font-scale)); background:#f8fafc; padding:8px 12px; border-radius:6px; border:1px solid var(--line);">
                <b>Study Values:</b> $I_k'' = 51.06\text{ kA}$ (3-Ph) · $i_p = 138.60\text{ kA}$ · $I_k''\text{ LG} = 46.12\text{ kA}$ · <b>Primary Relay:</b> 87L Line Diff (40 ms) / 21 Distance Zone 1.
              </div>
            </figcaption>
          </figure>
        </div>

        <!-- CARD F5 WIDE -->
        <figure style="margin: 16px 0;">
          <div class="figure-top-ctrl">
            <span class="figure-tag"><span class="badge badge-f5">F5</span> 230 kV Remote Grid Substation Bus Detail · B230_REMOTE / BGRID230</span>
            <button type="button" class="figure-zoom-btn" onclick="openLightbox('snapshots/sld_crop_f5_remote_grid.png')">🔍 HD View</button>
          </div>
          <div style="display:flex; gap:20px; align-items:center; flex-wrap:wrap;">
            <div style="flex:1; min-width:320px;">
              <img src="snapshots/sld_crop_f5_remote_grid.png" alt="F5 Remote Grid Substation SLD Detail" onclick="openLightbox(this.src)" style="cursor:zoom-in; max-height:360px; object-fit:contain;">
            </div>
            <div style="flex:1; min-width:300px; font-size:calc(14.5px * var(--font-scale)); line-height:1.7;">
              <b>Fig. 2e — F5 Remote Grid Substation & External Interface.</b><br>
              Shows the receiving-end 230 kV utility busbar (PGCB national grid node), tie breakers, and external grid Thévenin source equivalent ($|Z| = 2.656\ \Omega$).<br><br>
              <div style="background:#f8fafc; padding:12px 16px; border-radius:8px; border:1.5px solid var(--line);">
                <b>• 3-Phase Symmetrical Fault Current:</b> $I_k'' = 53.09\text{ kA}$<br>
                <b>• Peak Asymmetrical Current:</b> $i_p = 144.11\text{ kA}$<br>
                <b>• 1-Phase-to-Ground Fault Current:</b> $I_k''\text{ LG} = 48.47\text{ kA}$<br>
                <b>• Relay Action:</b> Plant differential relays (87G, 87T, 87B, 87L) <b>RESTRAIN</b>; fault is cleared exclusively by remote grid utility breakers.
              </div>
            </div>
          </div>
        </figure>
      </div>
"""

    # Look for insertion point right before `<h3>Individual Simulink Fault Injection Subsystems:</h3>`
    target_marker = "<h3>Individual Simulink Fault Injection Subsystems:</h3>"
    if target_marker in content:
        if 'id="sld-detail"' not in content:
            content = content.replace(target_marker, closeup_html + "\n\n      " + target_marker)
            print("Inserted close-up section before Simulink subsystem section.")
        else:
            print("Close-up section already present, refreshing content...")
            # If already present, replace the old sld-detail block
            pattern = r'<!-- SECTION 3B: HIGH-DEFINITION SLD CLOSE-UP DETAIL VIEWS -->.*?<h3>Individual Simulink Fault Injection Subsystems:</h3>'
            repl_text = closeup_html + "\n\n      <h3>Individual Simulink Fault Injection Subsystems:</h3>"
            content = re.sub(pattern, lambda m: repl_text, content, flags=re.DOTALL)
    else:
        print("Warning: target_marker not found, looking for end of Section 3...")
        # fallback before Section 4
        fallback_marker = '<!-- SECTION 4: FAULT RESULTS -->'
        if fallback_marker in content:
            content = content.replace(fallback_marker, closeup_html + "\n    </section>\n\n    " + fallback_marker)

    # Write out to both Phase 4 HTML locations
    p4_ext_html.write_text(content, encoding="utf-8")
    p4_int_html.write_text(content, encoding="utf-8")
    print(f"Successfully saved updated HTML to:\n  - {p4_ext_html}\n  - {p4_int_html}")

if __name__ == "__main__":
    update_manual_with_closeups()
