import re
from pathlib import Path

def upgrade_html_typography():
    base_dir = Path(r"c:\Users\Sindid\OneDrive\Desktop\MouseWithoutBorders\306 Power Project -ekkebare f")
    p4_ext_html = base_dir / "Phase 4 Docs" / "FAULT_ANALYSIS_MANUAL.html"
    p4_int_html = base_dir / "306 Power Project -kimi k3-v4" / "docs" / "phase4" / "FAULT_ANALYSIS_MANUAL.html"

    content = p4_ext_html.read_text(encoding="utf-8")

    # 1. Update <style> block with responsive font scaling and large presentation variables
    old_style_marker = "<style>"
    new_style_block = """<style>
:root {
  --navy: #0f2b3c;
  --navy-light: #18425d;
  --teal: #0d8b87;
  --teal-light: #e4f5f4;
  --blue: #1a73e8;
  --blue-light: #e8f0fe;
  --red: #d93025;
  --red-light: #fce8e6;
  --amber: #f2994a;
  --amber-light: #fef7ee;
  --green: #1e8e3e;
  --green-light: #e6f4ea;
  --purple: #7e22ce;
  --purple-light: #f3e8ff;
  --bg: #f8fafc;
  --card: #ffffff;
  --line: #cbd5e1;
  --text: #0f172a;
  --text-muted: #475569;
  --font-scale: 1.15; /* Presentation-optimized default scale */
}
* { box-sizing: border-box; }
body {
  margin: 0;
  font-family: 'Inter', -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
  background: var(--bg);
  color: var(--text);
  line-height: 1.7;
  font-size: calc(16.5px * var(--font-scale));
}
.shell { display: flex; min-height: 100vh; transition: all 0.25s ease; }
.sidebar {
  width: 310px;
  background: var(--navy);
  color: #fff;
  padding: 26px 20px;
  position: sticky;
  top: 0;
  height: 100vh;
  overflow-y: auto;
  box-shadow: 4px 0 16px rgba(0,0,0,0.08);
  transition: transform 0.25s ease, margin 0.25s ease;
  flex-shrink: 0;
}
.sidebar h2 { font-size: calc(17px * var(--font-scale)); margin: 0 0 6px; font-weight: 800; color: #fff; letter-spacing: -0.01em; }
.sidebar small { color: #99f6e4; font-size: calc(13px * var(--font-scale)); font-weight: 600; display: block; margin-bottom: 22px; }
.nav a {
  display: block;
  color: #cbd5e1;
  text-decoration: none;
  padding: 10px 14px;
  margin: 4px 0;
  border-radius: 8px;
  font-size: calc(14px * var(--font-scale));
  font-weight: 600;
  transition: all 0.15s ease;
}
.nav a:hover, .nav a.active { background: rgba(255,255,255,0.16); color: #fff; transform: translateX(3px); }
.sidebar-box {
  background: rgba(255,255,255,0.08);
  border: 1px solid rgba(255,255,255,0.12);
  border-radius: 10px;
  padding: 14px;
  margin-top: 24px;
  font-size: calc(13px * var(--font-scale));
  color: #cbd5e1;
  line-height: 1.6;
}

/* Presentation Toolbar (Sticky Top Bar) */
.presentation-bar {
  position: sticky;
  top: 0;
  z-index: 1000;
  background: #ffffff;
  border-bottom: 2px solid var(--teal);
  padding: 12px 24px;
  margin: -36px -44px 28px -44px;
  box-shadow: 0 4px 14px rgba(15, 43, 60, 0.08);
  display: flex;
  align-items: center;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: 12px;
}
.pbar-left {
  display: flex;
  align-items: center;
  gap: 10px;
  font-size: calc(14px * var(--font-scale));
  color: var(--navy);
  font-weight: 700;
}
.pbar-badge {
  background: var(--navy);
  color: #ffffff;
  padding: 4px 10px;
  border-radius: 6px;
  font-size: calc(12px * var(--font-scale));
  font-weight: 800;
  letter-spacing: 0.05em;
  text-transform: uppercase;
}
.pbar-actions {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
}
.pbar-btn {
  background: #f1f5f9;
  color: var(--navy);
  border: 1.5px solid #cbd5e1;
  border-radius: 8px;
  padding: 8px 14px;
  font-size: calc(13.5px * var(--font-scale));
  font-weight: 700;
  cursor: pointer;
  transition: all 0.15s ease;
  font-family: inherit;
}
.pbar-btn:hover {
  background: #e2e8f0;
  border-color: #94a3b8;
  transform: translateY(-1px);
}
.pbar-btn.active {
  background: var(--teal);
  color: #ffffff;
  border-color: var(--teal);
  box-shadow: 0 2px 8px rgba(13, 139, 135, 0.35);
}
.pbar-btn.pbar-projector {
  background: #dc2626;
  color: #ffffff;
  border-color: #b91c1c;
}
.pbar-btn.pbar-projector:hover {
  background: #b91c1c;
}
.pbar-btn.pbar-projector.active {
  background: #991b1b;
  border-color: #7f1d1d;
  box-shadow: 0 2px 10px rgba(220, 38, 38, 0.45);
}

.main { flex: 1; padding: 36px 44px; max-width: 1260px; transition: all 0.25s ease; }
html.full-width .sidebar { margin-left: -310px; }
html.full-width .main { max-width: 100%; padding: 36px 60px; }

.eyebrow {
  color: var(--teal);
  font-weight: 800;
  letter-spacing: 0.08em;
  font-size: calc(13px * var(--font-scale));
  text-transform: uppercase;
  margin-bottom: 6px;
}
h1 { color: var(--navy); font-size: calc(34px * var(--font-scale)); font-weight: 900; margin: 0 0 12px; letter-spacing: -0.025em; line-height: 1.25; }
.lead { font-size: calc(18px * var(--font-scale)); color: #334155; max-width: 1020px; margin-bottom: 28px; line-height: 1.7; font-weight: 450; }
.card {
  background: var(--card);
  border: 1.5px solid var(--line);
  border-radius: 16px;
  padding: 30px 34px;
  margin: 28px 0;
  box-shadow: 0 3px 12px rgba(15, 23, 42, 0.04);
}
.card h2 { color: var(--navy); margin-top: 0; font-size: calc(25px * var(--font-scale)); font-weight: 800; letter-spacing: -0.015em; line-height: 1.3; }
.card h3 { color: var(--navy-light); font-size: calc(19px * var(--font-scale)); margin: 22px 0 10px; font-weight: 700; }
.grid2 { display: grid; grid-template-columns: 1fr 1fr; gap: 22px; }
.grid3 { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 20px; }
@media (max-width: 1024px) {
  .grid2, .grid3 { grid-template-columns: 1fr; }
  .sidebar { display: none; }
  .main { padding: 20px; }
  .presentation-bar { margin: -20px -20px 20px -20px; padding: 10px 14px; }
}
.status-pill {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 6px 14px;
  border-radius: 20px;
  font-size: calc(13px * var(--font-scale));
  font-weight: 800;
  margin-bottom: 14px;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}
.badge {
  display: inline-block;
  padding: 4px 10px;
  border-radius: 8px;
  font-size: calc(13.5px * var(--font-scale));
  font-weight: 800;
}
.badge-f1 { background: #fee2e2; color: #b91c1c; border: 1.5px solid #fca5a5; }
.badge-f2 { background: #ffedd5; color: #c2410c; border: 1.5px solid #fdba74; }
.badge-f3 { background: #fef3c7; color: #b45309; border: 1.5px solid #fde68a; }
.badge-f4 { background: #dbeafe; color: #1d4ed8; border: 1.5px solid #bfdbfe; }
.badge-f5 { background: #f3e8ff; color: #7e22ce; border: 1.5px solid #d8b4fe; }

/* Enhanced Large Tables */
table { border-collapse: collapse; width: 100%; font-size: calc(15px * var(--font-scale)); margin: 16px 0; }
th, td { border: 1.5px solid var(--line); padding: 12px 16px; text-align: left; vertical-align: top; }
th { background: #f1f5f9; color: var(--navy); font-weight: 800; font-size: calc(15.5px * var(--font-scale)); }
tr:nth-child(even) td { background: #f8fafc; }
.num { text-align: right; font-variant-numeric: tabular-nums; font-family: 'JetBrains Mono', monospace; font-size: calc(15px * var(--font-scale)); font-weight: 700; }
.formula-box {
  background: #f8fafc;
  border-left: 5px solid var(--teal);
  border-radius: 0 10px 10px 0;
  padding: 16px 20px;
  margin: 14px 0;
  font-family: 'JetBrains Mono', monospace;
  font-size: calc(15px * var(--font-scale));
  color: #0f172a;
  line-height: 1.7;
}

/* Figures & Diagrams */
figure {
  margin: 22px 0;
  background: #ffffff;
  border: 1.5px solid var(--line);
  border-radius: 14px;
  padding: 18px;
  box-shadow: 0 4px 14px rgba(15, 23, 42, 0.05);
}
.figure-top-ctrl {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 12px;
}
.figure-tag {
  font-size: calc(13px * var(--font-scale));
  font-weight: 800;
  color: var(--navy);
  text-transform: uppercase;
  letter-spacing: 0.04em;
}
.figure-zoom-btn {
  background: #eef2ff;
  color: #3730a3;
  border: 1px solid #c7d2fe;
  border-radius: 6px;
  padding: 6px 12px;
  font-size: calc(12.5px * var(--font-scale));
  font-weight: 700;
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  gap: 6px;
  transition: all 0.15s;
}
.figure-zoom-btn:hover { background: #e0e7ff; transform: translateY(-1px); }
figure img {
  width: 100%;
  border-radius: 10px;
  border: 1px solid #cbd5e1;
  display: block;
  cursor: pointer;
  transition: transform 0.2s, box-shadow 0.2s;
}
figure img:hover { transform: scale(1.006); box-shadow: 0 8px 24px rgba(15, 43, 60, 0.12); }
figcaption {
  font-size: calc(15px * var(--font-scale));
  color: var(--text-muted);
  margin-top: 14px;
  line-height: 1.65;
}
figcaption b { color: var(--navy); font-weight: 800; font-size: calc(15.5px * var(--font-scale)); }

code {
  background: #f1f5f9;
  color: #0f172a;
  padding: 3px 8px;
  border-radius: 6px;
  font-size: calc(14px * var(--font-scale));
  font-family: 'JetBrains Mono', monospace;
  font-weight: 600;
}
pre {
  background: var(--navy);
  color: #f1f5f9;
  padding: 18px 22px;
  border-radius: 10px;
  overflow-x: auto;
  font-family: 'JetBrains Mono', monospace;
  font-size: calc(14px * var(--font-scale));
  line-height: 1.6;
}
a { color: var(--teal); text-decoration: none; font-weight: 700; }
a:hover { text-decoration: underline; }

/* Enhanced Viva Cards */
.viva-card {
  background: #ffffff;
  border: 1.5px solid #cbd5e1;
  border-left: 6px solid var(--teal);
  border-radius: 12px;
  padding: 20px 24px;
  margin: 18px 0;
  box-shadow: 0 2px 8px rgba(0,0,0,0.03);
}
.viva-q {
  font-weight: 800;
  color: var(--navy);
  font-size: calc(18px * var(--font-scale));
  margin-bottom: 12px;
  line-height: 1.45;
}
.viva-a {
  font-size: calc(16px * var(--font-scale));
  color: #1e293b;
  line-height: 1.7;
}
.viva-a p, .viva-a ul { margin: 8px 0; }
.viva-a li { margin: 6px 0; }

/* Lightbox Modal */
.lightbox {
  display: none;
  position: fixed;
  z-index: 9999;
  top: 0; left: 0; width: 100vw; height: 100vh;
  background: rgba(15, 23, 42, 0.96);
  justify-content: center;
  align-items: center;
  flex-direction: column;
  padding: 24px;
}
.lightbox-topbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  width: 95vw;
  margin-bottom: 12px;
  color: #ffffff;
  font-weight: 700;
  font-size: 16px;
}
.lightbox-btns {
  display: flex;
  align-items: center;
  gap: 12px;
}
.lightbox-btn {
  background: rgba(255,255,255,0.15);
  color: #fff;
  border: 1px solid rgba(255,255,255,0.3);
  border-radius: 6px;
  padding: 6px 14px;
  font-size: 14px;
  font-weight: 700;
  cursor: pointer;
  transition: all 0.15s;
}
.lightbox-btn:hover { background: rgba(255,255,255,0.3); }
.lightbox img {
  max-width: 96vw;
  max-height: 88vh;
  object-fit: contain;
  border-radius: 8px;
  box-shadow: 0 10px 40px rgba(0,0,0,0.8);
  transition: transform 0.2s ease;
}
</style>"""

    # Replace the <style>...</style> block
    style_pattern = re.compile(r'<style>.*?</style>', re.DOTALL)
    content = style_pattern.sub(new_style_block, content, count=1)

    # 2. Remove inline font-size overrides in paragraph tags
    content = re.sub(r'style="font-size:13px;\s*color:#475569;"', 'style="color:#475569;"', content)
    content = re.sub(r'style="font-size:13.5px;\s*color:#334155;\s*line-height:1\.6;"', 'class="viva-a"', content)
    content = re.sub(r'style="font-size:13px;\s*line-height:1\.7;"', 'style="line-height:1.7;"', content)
    content = re.sub(r'style="font-size:13px;"', '', content)
    content = re.sub(r'style="font-size:12\.5px;"', '', content)

    # 3. Add the Presentation Control Bar right after `<main class="main">`
    pbar_html = """  <main class="main">
    <!-- PRESENTATION & DISPLAY SCALING TOOLBAR -->
    <div class="presentation-bar">
      <div class="pbar-left">
        <span class="pbar-badge">Presentation Controls</span>
        <span>Display Scale for Screen & Projector:</span>
      </div>
      <div class="pbar-actions">
        <button class="pbar-btn" id="btn-scale-1" onclick="setFontScale(1.0, this)">100% Standard</button>
        <button class="pbar-btn active" id="btn-scale-2" onclick="setFontScale(1.18, this)">120% Large</button>
        <button class="pbar-btn pbar-projector" id="btn-scale-3" onclick="setFontScale(1.42, this)">📽️ 145% Projector / Viva</button>
        <button class="pbar-btn" id="btn-scale-4" onclick="setFontScale(1.65, this)">🔍 165% Extra Large</button>
        <button class="pbar-btn" id="btn-full-width" onclick="toggleFullWidth(this)">⛶ Full Width Mode</button>
      </div>
    </div>
"""
    content = content.replace('  <main class="main">', pbar_html, 1)

    # 4. Enhance Figure 1 and Figure 2 with HD Zoom Buttons
    fig1_old = '<figure>\n        <img src="snapshots/sld_fault_locations_marked.png" alt="Master Single Line Diagram with Fault Locations Marked" onclick="openLightbox(this.src)">'
    fig1_new = """<figure>
        <div class="figure-top-ctrl">
          <span class="figure-tag">Drawing 1 · Master Single Line Diagram</span>
          <button type="button" class="figure-zoom-btn" onclick="openLightbox('snapshots/sld_fault_locations_marked.png')">🔍 Full-Screen HD View</button>
        </div>
        <img src="snapshots/sld_fault_locations_marked.png" alt="Master Single Line Diagram with Fault Locations Marked" onclick="openLightbox(this.src)">"""
    content = content.replace(fig1_old, fig1_new)

    fig2_old = '<figure>\n        <img src="snapshots/simulink_fault_locations_marked.png" alt="Top-Level Simulink Model with Fault Locations Marked" onclick="openLightbox(this.src)">'
    fig2_new = """<figure>
        <div class="figure-top-ctrl">
          <span class="figure-tag">Drawing 2 · Simulink Dynamic Model Architecture</span>
          <button type="button" class="figure-zoom-btn" onclick="openLightbox('snapshots/simulink_fault_locations_marked.png')">🔍 Full-Screen HD View</button>
        </div>
        <img src="snapshots/simulink_fault_locations_marked.png" alt="Top-Level Simulink Model with Fault Locations Marked" onclick="openLightbox(this.src)">"""
    content = content.replace(fig2_old, fig2_new)

    # 5. Update Lightbox Modal HTML & JavaScript
    old_lb = """<div id="lightbox" class="lightbox" onclick="closeLightbox()">
  <span class="lightbox-close">&times;</span>
  <img id="lightbox-img" src="" alt="Zoomed snapshot">
</div>"""
    new_lb = """<div id="lightbox" class="lightbox">
  <div class="lightbox-topbar">
    <span id="lightbox-title">High-Definition Presentation Diagram Viewer</span>
    <div class="lightbox-btns">
      <button class="lightbox-btn" onclick="zoomLightbox(1.2)">➕ Zoom In</button>
      <button class="lightbox-btn" onclick="zoomLightbox(0.8)">➖ Zoom Out</button>
      <button class="lightbox-btn" onclick="resetLightboxZoom()">↺ Reset</button>
      <button class="lightbox-btn" style="background:#dc2626;" onclick="closeLightbox()">✖ Close (Esc)</button>
    </div>
  </div>
  <div style="flex:1; display:flex; align-items:center; justify-content:center; overflow:auto; width:100%;" onclick="closeLightbox(event)">
    <img id="lightbox-img" src="" alt="Zoomed snapshot" onclick="event.stopPropagation()">
  </div>
</div>"""
    content = content.replace(old_lb, new_lb)

    # 6. Update scripts at bottom
    old_script = """<script>
function openLightbox(src) {
  document.getElementById('lightbox-img').src = src;
  document.getElementById('lightbox').style.display = 'flex';
}
function closeLightbox() {
  document.getElementById('lightbox').style.display = 'none';
}
document.addEventListener('keydown', function(e) {
  if (e.key === 'Escape') closeLightbox();
});
</script>"""

    new_script = """<script>
let currentScale = 1.18;
let lbZoom = 1;

function setFontScale(scale, btn) {
  currentScale = scale;
  document.documentElement.style.setProperty('--font-scale', scale);
  document.querySelectorAll('.pbar-actions .pbar-btn').forEach(b => {
    if (b.id !== 'btn-full-width') b.classList.remove('active');
  });
  if (btn) btn.classList.add('active');
  localStorage.setItem('faultManualFontScale', scale);
}

function toggleFullWidth(btn) {
  document.documentElement.classList.toggle('full-width');
  const isFull = document.documentElement.classList.contains('full-width');
  if (btn) btn.classList.toggle('active', isFull);
  btn.textContent = isFull ? '⛶ Normal Width' : '⛶ Full Width Mode';
  localStorage.setItem('faultManualFullWidth', isFull ? '1' : '0');
}

function openLightbox(src) {
  const lb = document.getElementById('lightbox');
  const img = document.getElementById('lightbox-img');
  img.src = src;
  lbZoom = 1;
  img.style.transform = `scale(${lbZoom})`;
  lb.style.display = 'flex';
}

function closeLightbox(e) {
  if (!e || e.target.id === 'lightbox' || e.target.parentElement?.id === 'lightbox' || e.target.tagName === 'BUTTON') {
    document.getElementById('lightbox').style.display = 'none';
  }
}

function zoomLightbox(factor) {
  lbZoom = Math.min(3.0, Math.max(0.6, lbZoom * factor));
  document.getElementById('lightbox-img').style.transform = `scale(${lbZoom})`;
}

function resetLightboxZoom() {
  lbZoom = 1;
  document.getElementById('lightbox-img').style.transform = `scale(1)`;
}

document.addEventListener('keydown', function(e) {
  if (e.key === 'Escape') {
    document.getElementById('lightbox').style.display = 'none';
  }
});

// Load saved display preferences
window.addEventListener('DOMContentLoaded', () => {
  const savedScale = localStorage.getItem('faultManualFontScale');
  if (savedScale) {
    const s = parseFloat(savedScale);
    let targetBtn = document.getElementById('btn-scale-2');
    if (s <= 1.05) targetBtn = document.getElementById('btn-scale-1');
    else if (s >= 1.6) targetBtn = document.getElementById('btn-scale-4');
    else if (s >= 1.35) targetBtn = document.getElementById('btn-scale-3');
    setFontScale(s, targetBtn);
  } else {
    setFontScale(1.18, document.getElementById('btn-scale-2'));
  }
  const savedFull = localStorage.getItem('faultManualFullWidth');
  if (savedFull === '1') {
    toggleFullWidth(document.getElementById('btn-full-width'));
  }
});
</script>"""

    content = content.replace(old_script, new_script)

    # Write to both target locations
    p4_ext_html.write_text(content, encoding="utf-8")
    p4_int_html.write_text(content, encoding="utf-8")
    print("Updated FAULT_ANALYSIS_MANUAL.html in both Phase 4 locations.")

if __name__ == "__main__":
    upgrade_html_typography()
