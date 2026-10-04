"""Build presentation cards around exported Simulink PNGs and verified provenance.

Run after manifest.json and metadata/provenance.json have been exported. Source
images are preserved. The evidence map supplies every PDF fact and source page.
"""
from __future__ import annotations

import argparse
import html
import json
import math
import re
from functools import lru_cache
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont, ImageOps


ROOT = Path(__file__).resolve().parent
NAVY = "#12273F"
INK = "#172E45"
MUTED = "#53667A"
LINE = "#DAE3EC"
PAPER = "#FFFFFF"
BACK = "#F0F4F8"
TEAL = "#006B67"
TEAL_BG = "#EDF8F6"
AMBER = "#855A00"
AMBER_BG = "#FFF5DD"
VOLTAGES = [("230 kV", "#C73336"), ("22 kV", "#206CB4"),
            ("6.6 kV", "#21824C"), ("110 V DC", "#7753B1")]


@lru_cache(maxsize=40)
def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    candidates = [Path("C:/Windows/Fonts") / ("segoeuib.ttf" if bold else "segoeui.ttf"),
                  Path("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf" if bold
                       else "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf")]
    for candidate in candidates:
        if candidate.exists():
            return ImageFont.truetype(str(candidate), size)
    return ImageFont.load_default(size=size)


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8-sig"))


def clean(value) -> str:
    if value is None:
        return ""
    if isinstance(value, list):
        return "; ".join(clean(x) for x in value)
    return str(value).replace("\r", "").strip()


def wrap(text: str, face, width: int) -> list[str]:
    """Pixel-measured wrapping, including paths and long PDF filenames."""
    out = []
    for paragraph in clean(text).split("\n"):
        if not paragraph:
            out.append("")
            continue
        line = ""
        for word in paragraph.split():
            proposed = f"{line} {word}".strip()
            if face.getlength(proposed) <= width:
                line = proposed
                continue
            if line:
                out.append(line)
                line = ""
            while face.getlength(word) > width:
                take = 1
                while take < len(word) and face.getlength(word[:take + 1]) <= width:
                    take += 1
                out.append(word[:take])
                word = word[take:]
            line = word
        if line:
            out.append(line)
    return out or [""]


def text_height(text: str, face, width: int, line_gap: int = 9) -> int:
    return len(wrap(text, face, width)) * (face.size + line_gap)


def draw_text(draw, xy, text, face, fill, width, line_gap=9):
    x, y = xy
    for line in wrap(text, face, width):
        draw.text((x, y), line, font=face, fill=fill)
        y += face.size + line_gap
    return y


def slug(value: str) -> str:
    value = re.sub(r"[^A-Za-z0-9._-]+", "_", clean(value)).strip("_.")
    return value or "snapshot"


def evidence_for(record: dict, provenance: dict) -> dict:
    areas = provenance.get("areas", provenance)
    snapshots = provenance.get("snapshots", {})
    explicit = snapshots.get(str(record.get("id"))) or snapshots.get(record.get("system"))
    if explicit:
        return explicit
    keys = [record.get("provenance_area"), record.get("area"), record.get("title")]
    for key in keys:
        if key in areas and isinstance(areas[key], dict):
            return areas[key]
    normalized = {re.sub(r"[^a-z0-9]", "", k.lower()): v
                  for k, v in areas.items() if isinstance(v, dict)}
    for key in keys:
        match = re.sub(r"[^a-z0-9]", "", clean(key).lower())
        if match in normalized:
            return normalized[match]
    raise ValueError(f"No provenance entry for snapshot {record.get('id')!r}, area {record.get('area')!r}")


def source_items(evidence: dict) -> list[dict]:
    items = evidence.get("supported", evidence.get("source_facts", []))
    if isinstance(items, str):
        items = [items]
    output = []
    for item in items:
        item = {"fact": item} if isinstance(item, str) else item
        fact = clean(item.get("fact", item.get("text", "")))
        pdf = clean(item.get("pdf", item.get("source", "")))
        pages = item.get("pages", item.get("page", ""))
        if isinstance(pages, list):
            page_text = ", ".join(str(x) for x in pages)
            page_label = "p." if len(pages) == 1 else "pp."
        else:
            page_text = clean(pages)
            page_label = "pp." if re.search(r"[,\-–]", page_text) else "p."
        reference = pdf
        if page_text:
            if re.match(r"^(p\.|pp\.|page)", page_text, re.I):
                reference += f" · {page_text}"
            else:
                reference += f" · {page_label} {page_text}"
        if not fact:
            continue
        if not pdf or not page_text:
            raise ValueError(f"Supported fact lacks exact PDF/page reference: {fact}")
        output.append({"fact": fact, "reference": reference})
    return output


def added_items(evidence: dict) -> list[dict]:
    items = evidence.get("added", evidence.get("added_facts", []))
    if isinstance(items, str):
        items = [items]
    result = []
    for item in items:
        item = {"fact": item} if isinstance(item, str) else item
        fact = clean(item.get("fact", item.get("text", "")))
        reason = clean(item.get("reason", ""))
        if fact:
            result.append({"fact": fact, "reason": reason})
    return result


TYPE_ROLES = {
    "From": "Receives a named signal routed from a matching Goto block.",
    "Goto": "Publishes a named signal for matching From blocks elsewhere in the model.",
    "PMIOPort": "Provides a physical electrical connection through the subsystem boundary.",
    "Outport": "Exposes an output signal at the subsystem boundary.",
    "Inport": "Receives an input signal at the subsystem boundary.",
    "Selector": "Selects elements from a vector or array for downstream calculations or displays.",
    "BusSelector": "Selects named signals from a bus for downstream use.",
    "Display": "Shows the current numerical value of its input signal during simulation.",
    "Gain": "Scales the incoming signal by the gain configured in this model.",
    "Reshape": "Changes the signal dimensions to match the connected calculation or output.",
    "Mux": "Combines input signals into a vector.",
    "ToWorkspace": "Records the connected simulation signal in the MATLAB workspace.",
    "M-S-Function": "Runs the project MATLAB S-function for this modeled calculation or control.",
    "Fcn": "Evaluates the mathematical expression configured for the input signal.",
    "Scope": "Plots connected signals against simulation time.",
    "Constant": "Supplies a constant value configured in the simulation model.",
}


def component_role(record: dict) -> tuple[str, dict | None]:
    if record.get("kind") != "component":
        return "", None
    kind = clean(record.get("block_type"))
    name = clean(record.get("block_name", record.get("title")))
    reference = clean(record.get("reference_block")).replace("\n", " ")
    if kind in TYPE_ROLES:
        return TYPE_ROLES[kind], {"fact": f"This {kind} block is project implementation for simulation, signal handling or display.",
                                   "reason": "The source PDFs describe the plant; they do not specify this Simulink block implementation."}
    ref_roles = [
        ("VIMeasurement", "Measures three-phase voltages and currents at this model location.", "This measurement block and its routed outputs are simulation instrumentation."),
        ("CurrentMeasurement", "Measures the branch current for use by the simulation.", "This current-sensing block is simulation instrumentation."),
        ("ThreePhaseFault", "Injects a configurable three-phase network fault for the protection study.", "The fault injection block, fault schedule and fault parameters are study additions."),
        ("ThreePhaseBreaker", "Connects or interrupts the three electrical phases according to its control input.", "The breaker model and its simulation control implementation are project additions."),
        ("SynchronousMachine", "Represents the generator's three-phase electromechanical behavior.", "The dynamic machine implementation and unreferenced simulation parameters are project additions."),
        ("TransformerTwoWindings", "Transfers three-phase power between the modeled transformer windings.", "The equivalent-circuit transformer implementation and unreferenced parameters are project additions."),
        ("PISectionLine", "Represents a transmission-line section using a lumped pi-section equivalent.", "The pi-section approximation and study impedance settings are project additions."),
        ("MutualInductance", "Represents coupled three-phase impedance using sequence parameters.", "The sequence-impedance network implementation is a project modeling choice."),
        ("ParallelRLCLoad", "Represents the connected three-phase load with an equivalent RLC load.", "The lumped RLC implementation and study load allocation are project additions."),
        ("ThreePhaseSource", "Provides the modeled three-phase source at the grid connection.", "The grid-equivalent source implementation and unreferenced settings are project additions."),
        ("GroundingTransformer", "Provides the modeled grounding or neutral connection.", "The grounding model implementation and unreferenced settings are project additions."),
        ("SeriesRLCBranch", "Represents a configurable electrical resistance, inductance or capacitance branch.", "This equivalent RLC branch and its simulation settings are project additions."),
        ("Ground", "Defines the electrical reference connection in this model.", "This electrical reference block is part of the simulation implementation."),
        ("powergui", "Configures the Specialized Power Systems simulation and analysis environment.", "The numerical simulation setup is a project addition."),
    ]
    for pattern, role, fact in ref_roles:
        if pattern.lower() in reference.lower():
            return role, {"fact": fact, "reason": "Documented plant equipment and ratings, where supported, remain identified in the source context above."}
    if kind == "SubSystem":
        return f"Groups the model blocks used for {name}.", {"fact": "The subsystem organization and its internal Simulink implementation are project additions.", "reason": "The source context identifies any documented equipment or function."}
    return f"Represents {name} as a {kind} model component.", {"fact": "This model component's implementation is a project addition.", "reason": "Its role is inferred from the exported model metadata; see source context for documented plant facts."}


def resolve_image(record: dict) -> Path:
    value = clean(record.get("image", record.get("raw_image", "")))
    p = Path(value)
    candidates = [p] if p.is_absolute() else [ROOT / p, ROOT / "raw" / p]
    for candidate in candidates:
        if candidate.is_file():
            return candidate.resolve()
    raise FileNotFoundError(f"Missing snapshot image: {value}")


def relative_url(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def section_height(items, width, source=False):
    fact_face, ref_face = font(29), font(23)
    height = 98
    if not items:
        height += text_height("No direct source fact is claimed for this view." if source
                              else "No separate addition is listed for this area.", fact_face, width - 64)
    for i, item in enumerate(items):
        height += text_height(item["fact"], fact_face, width - 64)
        detail = item.get("reference", item.get("reason", ""))
        if detail:
            height += 10 + text_height(detail, ref_face, width - 64, 7)
        height += 28 if i < len(items) - 1 else 0
    return height + 32


def draw_section(draw, x, y, width, items, source=False, component=False):
    height = section_height(items, width, source)
    color, background = (TEAL, TEAL_BG) if source else (AMBER, AMBER_BG)
    draw.rounded_rectangle((x, y, x + width, y + height), radius=20, fill=background)
    badge = ("SUBSYSTEM SOURCE CONTEXT" if component else "PDF-SUPPORTED FACTS") if source else "ADDED BY US"
    draw.rounded_rectangle((x + 28, y + 26, x + 28 + font(25, True).getlength(badge) + 32,
                            y + 72), radius=9, fill=color)
    draw.text((x + 44, y + 32), badge, font=font(25, True), fill=PAPER)
    yy = y + 98
    if not items:
        draw_text(draw, (x + 32, yy), "No direct source fact is claimed for this view." if source
                  else "No separate addition is listed for this area.", font(29), INK, width - 64)
    for i, item in enumerate(items):
        yy = draw_text(draw, (x + 32, yy), item["fact"], font(29), INK, width - 64)
        detail = item.get("reference", item.get("reason", ""))
        if detail:
            yy = draw_text(draw, (x + 32, yy + 10), detail, font(23), color, width - 64, 7)
        if i < len(items) - 1:
            yy += 28
    return y + height


def title_height(title, width):
    return text_height(title, font(56, True), width, 5)


def build_card(record: dict, provenance: dict, output_dir: Path, width: int) -> dict:
    evidence = evidence_for(record, provenance)
    supported = source_items(evidence)
    added = added_items(evidence)
    title = clean(record.get("title", record.get("id")))
    area = clean(record.get("area"))
    system = clean(record.get("system"))
    component = record.get("kind") == "component"
    role, component_addition = component_role(record)
    if component_addition:
        added = [component_addition] + added
    label_meta = provenance.get("block_labels", {}).get(system, {})
    if isinstance(label_meta, str):
        label_meta = {"label": label_meta}
    classification = clean(label_meta.get("classification", evidence.get("classification", "")))
    provenance_label = clean(label_meta.get("label"))
    image_path = resolve_image(record)
    with Image.open(image_path) as im:
        raw = ImageOps.exif_transpose(im).convert("RGBA")
        base = Image.new("RGBA", raw.size, PAPER)
        base.alpha_composite(raw)
        raw = base.convert("RGB")
    # Fix the card layout and retain the complete exported image, without crops.
    side_w = 856
    margin, gap = 54, 42
    main_x = margin + side_w + gap
    main_w = width - main_x - margin
    head_h = max(206, 72 + title_height(title, width - 320))
    path_lines = wrap(system, font(22), width - 2 * margin)
    path_h = len(path_lines) * 28 + 34 if system else 0
    content_y = head_h + path_h + 26
    summary = clean(record.get("description")) or clean(evidence.get("summary", evidence.get("brief")))
    if not summary:
        summary = f"Actual Simulink view of {title}."
    if component and not clean(record.get("description")):
        summary = role
    if component and record.get("block_type"):
        summary = f"{summary}\nBlock type: {clean(record['block_type'])}."
    summary_h = text_height(summary, font(31), side_w - 12, 10) + 28
    label_h = text_height(provenance_label, font(27), side_w - 64, 8) + 82 if provenance_label else 0
    context = ("Source context for this subsystem: these PDF facts describe the plant area, not necessarily this individual simulation block." if component else
               "Source facts below describe this area. The exported model view also includes the simulation additions listed here.")
    context_h = text_height(context, font(23), side_w - 12, 7) + 27
    sections_h = section_height(supported, side_w, True) + section_height(added, side_w) + 24
    notes = record.get("notes", [])
    if isinstance(notes, str):
        notes = [notes]
    note_text = " ".join(clean(x) for x in notes)
    note_h = text_height(note_text, font(23), side_w - 12, 7) + 20 if note_text else 0
    side_h = summary_h + label_h + context_h + sections_h + note_h
    # Portrait exports gain height; wide exports keep a useful 16:9 canvas.
    desired_image_h = min(3300, math.ceil(main_w * raw.height / raw.width))
    body_h = max(1320, side_h, desired_image_h + 120)
    footer_h = 150
    height = content_y + body_h + footer_h
    canvas = Image.new("RGB", (width, height), PAPER)
    draw = ImageDraw.Draw(canvas)
    draw.rectangle((0, 0, width, head_h), fill=NAVY)
    draw.text((margin, 25), "POWER PLANT MODEL  /  V4", font=font(24, True), fill="#A8C8E1")
    draw_text(draw, (margin, 71), title, font(56, True), PAPER, width - 320, 5)
    identifier = clean(record.get("id"))
    badge_w = max(94, font(27, True).getlength(identifier) + 40)
    draw.rounded_rectangle((width - margin - badge_w, 33, width - margin, 84), radius=10, fill="#29445E")
    draw.text((width - margin - badge_w + 20, 41), identifier, font=font(27, True), fill=PAPER)
    if system:
        draw.rectangle((0, head_h, width, head_h + path_h), fill=BACK)
        draw_text(draw, (margin, head_h + 14), system, font(22), MUTED, width - 2 * margin, 6)
    yy = draw_text(draw, (margin + 2, content_y), summary, font(31), INK, side_w - 12, 10) + 28
    if provenance_label:
        fill = AMBER_BG if classification == "ADDED BY US" else BACK
        color = AMBER if classification == "ADDED BY US" else INK
        draw.rounded_rectangle((margin, yy, margin + side_w, yy + label_h - 20), radius=14, fill=fill)
        draw.text((margin + 28, yy + 14), "THIS COMPONENT" if component else "THIS SYSTEM", font=font(21, True), fill=MUTED)
        draw_text(draw, (margin + 28, yy + 45), provenance_label, font(27), color, side_w - 64, 8)
        yy += label_h
    yy = draw_text(draw, (margin + 2, yy), context, font(23), MUTED, side_w - 12, 7) + 27
    yy = draw_section(draw, margin, yy, side_w, supported, source=True, component=component) + 24
    yy = draw_section(draw, margin, yy, side_w, added)
    if note_text:
        draw_text(draw, (margin + 2, yy + 20), note_text, font(23), MUTED, side_w - 12, 7)
    # White image area is intentionally neutral: provenance uses sidebar badges.
    draw.rounded_rectangle((main_x, content_y, width - margin, content_y + body_h), radius=20,
                           fill=PAPER, outline=LINE, width=2)
    draw.text((main_x + 28, content_y + 22), "ACTUAL SIMULINK EXPORT", font=font(24, True), fill=INK)
    capture = clean(record.get("capture_type", ""))
    if component:
        capture = "Component view"
    elif not capture:
        capture = "Detail view" if any(word in title.lower() for word in ["detail", "region", "part"]) else "System view"
    caption = f"{capture}  ·  {raw.width:,} × {raw.height:,} px source"
    draw.text((main_x + 28, content_y + 57), caption, font=font(21), fill=MUTED)
    image_box = (main_x + 22, content_y + 102, width - margin - 22, content_y + body_h - 22)
    fitted = ImageOps.contain(raw, (image_box[2] - image_box[0], image_box[3] - image_box[1]),
                              method=Image.Resampling.LANCZOS)
    px = image_box[0] + (image_box[2] - image_box[0] - fitted.width) // 2
    py = image_box[1] + (image_box[3] - image_box[1] - fitted.height) // 2
    canvas.paste(fitted, (px, py))
    fy = height - footer_h + 34
    draw.line((margin, fy - 15, width - margin, fy - 15), fill=LINE, width=2)
    draw.text((margin, fy), "VOLTAGE COLORS", font=font(22, True), fill=MUTED)
    vx = margin + 235
    for label, color in VOLTAGES:
        draw.rounded_rectangle((vx, fy + 4, vx + 22, fy + 26), radius=5, fill=color)
        draw.text((vx + 34, fy - 1), label, font=font(24, True), fill=INK)
        vx += 230
    draw.text((margin, fy + 47), "Teal = PDF-supported context   ·   Amber = project additions   ·   PDF page numbers refer to the supplied source files.",
              font=font(22), fill=MUTED)
    filename = f"{slug(identifier)}_{slug(title)}.png"
    destination = output_dir / filename
    canvas.save(destination, compress_level=4)
    print(f"  {filename}  {width}x{height}", flush=True)
    return {**record, "title": title, "area": area, "system": system,
            "annotated": relative_url(destination), "raw": relative_url(image_path),
            "width": width, "height": height, "summary": summary,
            "supported": supported, "added": added, "classification": classification,
            "provenance_label": provenance_label}


HTML_TEMPLATE = r'''<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>V4 Power Plant — Presentation snapshots</title>
<style>
:root{font-family:Segoe UI,Arial,sans-serif;color:#172e45;background:#f0f4f8;font-synthesis:none}*{box-sizing:border-box}
body{margin:0}header{background:#12273f;color:white;padding:38px max(24px,calc((100vw - 1660px)/2));}
.eyebrow{color:#a8c8e1;letter-spacing:.1em;font-size:12px;font-weight:700}h1{font-size:clamp(26px,3vw,40px);margin:10px 0}header p{max-width:860px;line-height:1.6;color:#dbe7f2}
main{max-width:1712px;margin:auto;padding:26px}.toolbar{display:flex;flex-wrap:wrap;gap:12px;align-items:center;margin:0 0 14px}
input,select{font:inherit;padding:12px 15px;border:1px solid #c7d5e2;border-radius:9px;background:white;color:#172e45}input{min-width:260px;flex:1}select{min-width:210px}
a{color:#086575;text-underline-offset:3px}.links{display:flex;gap:20px;flex-wrap:wrap;margin:20px 0 0}.links a{color:#cbe7f5}
.legend{display:flex;flex-wrap:wrap;gap:10px;line-height:1.5;margin:15px 0 22px}.badge{border-radius:5px;padding:4px 9px;font-size:12px;font-weight:700}.source{background:#dcefeb;color:#006b67}.added{background:#ffefc9;color:#855a00}
.legend-note{font-size:13px;color:#53667a;align-self:center}.grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:24px}
article{background:white;border:1px solid #dae3ec;border-radius:13px;overflow:hidden;box-shadow:0 3px 10px #12273f08;scroll-margin-top:20px}
.card-image{display:block;background:white;border-bottom:1px solid #e5ecf2}.card-image img{display:block;width:100%;height:auto;aspect-ratio:16/10;object-fit:contain}
.card-body{padding:20px}article h2{font-size:21px;margin:8px 0 9px}article p{font-size:14px;line-height:1.6;margin:0 0 14px;color:#53667a}.meta{font-size:12px;color:#53667a;display:flex;justify-content:space-between;gap:16px}.buttons{display:flex;gap:10px;flex-wrap:wrap}.button{border:1px solid #c6d6e4;border-radius:6px;text-decoration:none;padding:9px 12px;font-size:13px;font-weight:600}.button.primary{background:#12273f;color:white;border-color:#12273f}
details{margin-top:16px;border-top:1px solid #e6edf3;padding-top:12px;font-size:13px}summary{cursor:pointer;font-weight:600;color:#405971}details ul{padding-left:18px;line-height:1.6}details li{margin:8px 0}details small{display:block;color:#53667a}code{font-size:11px;overflow-wrap:anywhere}.count{color:#53667a;font-size:14px;margin:14px 0}.empty{display:none;padding:45px;text-align:center;color:#53667a}
footer{max-width:1660px;margin:28px auto;padding:24px 0 42px;font-size:13px;color:#53667a;line-height:1.7;border-top:1px solid #d4dfe9}.volt{display:inline-block;width:10px;height:10px;border-radius:3px;margin-right:5px}
@media(max-width:900px){.grid{grid-template-columns:1fr}main{padding:16px}.card-image img{aspect-ratio:auto}header{padding:28px 20px}footer{margin:20px}}
@media print{header{color:#172e45;background:white}.toolbar,.count,.buttons,.links,details,.legend{display:none}.grid{display:block}article{break-inside:avoid;margin:0 0 24px}.card-image img{aspect-ratio:auto}.card-body p{display:none}}
</style></head><body>
<header><div class="eyebrow">POWER PLANT MODEL / V4 · WHOLE SLD & SUBSYSTEMS</div><h1>Plant SLD & Subsystem Snapshots</h1>
<p>Actual Simulink plant SLD overview and subsystem views, with source PDF facts and project additions identified on each image. Exported at the system level (individual block-by-block cards omitted).</p>
<div class="links"><a href="manual.html">Model manual</a><a href="README.md">How to use</a><a href="SOURCES_AND_ADDITIONS.md">Sources and additions</a><a href="contact_sheet.png">All snapshots at a glance</a><a href="manifest.json">Export manifest</a></div></header>
<main><div class="toolbar"><input id="search" type="search" placeholder="Search SLD, subsystem, area or relay…" aria-label="Search snapshots"><select id="area" aria-label="Filter by system area"><option value="">All areas</option>__OPTIONS__</select></div>
<div class="legend"><span class="badge source">PDF-SUPPORTED FACTS</span><span class="badge added">ADDED BY US</span><span class="legend-note">The provenance badges are separate from the model’s voltage colors.</span></div>
<div class="count" id="count">__COUNT__ system snapshots</div><div class="grid" id="grid">__CARDS__</div><div class="empty" id="empty">No snapshots match. Try a subsystem name or clear the filter.</div>
<footer>Voltage colors: <span class="volt" style="background:#c73336"></span>230 kV &nbsp; <span class="volt" style="background:#206cb4"></span>22 kV &nbsp; <span class="volt" style="background:#21824c"></span>6.6 kV &nbsp; <span class="volt" style="background:#7753b1"></span>110 V DC.<br>Source facts describe the corresponding plant area. Numerical settings, simulation logic and visualization choices are identified as additions in the evidence map. PDF page references are reproduced from that map. These snapshots are design documentation; they are not a claim of commissioned relay settings.</footer></main>
<script>const q=document.querySelector('#search'),area=document.querySelector('#area'),cards=[...document.querySelectorAll('article')];function filter(){const s=q.value.trim().toLowerCase();let n=0;for(const card of cards){const show=(!area.value||card.dataset.area===area.value)&&(!s||card.dataset.search.includes(s));card.hidden=!show;if(show)n++}document.querySelector('#count').textContent=n+' of '+cards.length+' snapshots';document.querySelector('#empty').style.display=n?'none':'block'}q.addEventListener('input',filter);area.addEventListener('change',filter);</script></body></html>'''


def build_html(cards: list[dict]):
    esc = html.escape
    options = "".join(f'<option value="{esc(a, quote=True)}">{esc(a)}</option>'
                      for a in sorted({c["area"] for c in cards}))
    entries = []
    for c in cards:
        search = " ".join([c["title"], c["area"], c["system"], c["summary"], c["provenance_label"],
                           " ".join(i["fact"] for i in c["supported"] + c["added"])]).lower()
        supported = "".join(f'<li>{esc(x["fact"])}<small>{esc(x["reference"])}</small></li>' for x in c["supported"])
        additions = "".join(f'<li>{esc(x["fact"])}' + (f'<small>{esc(x["reason"])}</small>' if x["reason"] else '') + '</li>' for x in c["added"])
        entries.append(f'''<article id="{esc(slug(c['id']))}" data-area="{esc(c['area'], quote=True)}" data-kind="{esc(clean(c.get('kind')), quote=True)}" data-search="{esc(search, quote=True)}">
<a class="card-image" href="{esc(c['annotated'], quote=True)}" target="_blank" rel="noopener"><img src="{esc(c['annotated'], quote=True)}" alt="Annotated Simulink snapshot: {esc(c['title'], quote=True)}" loading="lazy" width="{c['width']}" height="{c['height']}"></a>
<div class="card-body"><div class="meta"><span>{esc(clean(c['id']))} · {esc(c['area'])}</span><span>{c['width']:,} × {c['height']:,} px</span></div><h2>{esc(c['title'])}</h2><p>{esc(c['summary'])}</p><p><strong>{esc(c['provenance_label'])}</strong></p><div class="buttons"><a class="button primary" href="{esc(c['annotated'], quote=True)}" target="_blank" rel="noopener">Open annotated PNG</a><a class="button" href="{esc(c['raw'], quote=True)}" target="_blank" rel="noopener">Open raw PNG</a></div>
<details><summary>Source details and model path</summary><p><code>{esc(c['system'])}</code></p><span class="badge source">PDF-SUPPORTED FACTS</span><ul>{supported or '<li>No direct source fact is claimed for this view.</li>'}</ul><span class="badge added">ADDED BY US</span><ul>{additions or '<li>No separate addition is listed for this area.</li>'}</ul></details></div></article>''')
    page = HTML_TEMPLATE.replace("__OPTIONS__", options).replace("__CARDS__", "\n".join(entries)).replace("__COUNT__", str(len(cards)))
    (ROOT / "index.html").write_text(page, encoding="utf-8")


def build_contact_sheet(cards: list[dict]):
    cols, tile_w, tile_h, gap = (8, 390, 300, 18) if len(cards) > 120 else (4, 730, 540, 24)
    rows = math.ceil(len(cards) / cols)
    sheet = Image.new("RGB", (cols * tile_w + (cols + 1) * gap, 150 + rows * (tile_h + gap) + gap), BACK)
    draw = ImageDraw.Draw(sheet)
    draw.rectangle((0, 0, sheet.width, 118), fill=NAVY)
    draw.text((gap, 26), "V4 POWER PLANT  /  SNAPSHOT INDEX", font=font(40, True), fill=PAPER)
    draw.text((gap, 81), f"{len(cards)} actual Simulink exports · Open index.html to search and view full-resolution cards", font=font(20), fill="#C8DCEA")
    for i, c in enumerate(cards):
        x, y = gap + (i % cols) * (tile_w + gap), 150 + (i // cols) * (tile_h + gap)
        draw.rounded_rectangle((x, y, x + tile_w, y + tile_h), radius=12, fill=PAPER)
        with Image.open(ROOT / c["raw"]) as im:
            fitted = ImageOps.contain(im.convert("RGB"), (tile_w - 28, tile_h - 127), method=Image.Resampling.LANCZOS)
            sheet.paste(fitted, (x + (tile_w - fitted.width) // 2, y + 14 + (tile_h - 127 - fitted.height) // 2))
        draw.text((x + 20, y + tile_h - 94), f"{clean(c['id'])}  ·  {c['area']}", font=font(16 if cols == 8 else 19), fill=MUTED)
        draw_text(draw, (x + 20, y + tile_h - 64), c["title"], font(17 if cols == 8 else 25, True), INK, tile_w - 40, 3)
    sheet.save(ROOT / "contact_sheet.png", compress_level=4)


def write_readme(cards: list[dict]):
    content = f'''# V4 presentation snapshots

Open **index.html** in a browser to search and filter the {len(cards)} snapshots. No server or internet connection is needed.

## Use in a presentation

1. Find the relevant system or detail in the gallery.
2. Open its **annotated PNG** and insert it into your slide. Each card contains the actual Simulink export, an explanation, PDF-supported facts, exact PDF/page references and additions made for this model.
3. Use the **raw PNG** when you need the complete unannotated model view, or want to crop a specific block for a slide.
4. Use **contact_sheet.png** to see the full collection at a glance.

The annotated images are at least 3,200 pixels wide. Tall systems and longer evidence lists receive taller cards so source text is not omitted. The entire raw image is retained inside each annotated card; it is never cropped by the builder.

## Reading the labels

- **Teal — PDF-supported facts:** plant facts stated in the supplied PDFs. References identify the exact supplied PDF and page.
- **Amber — Added by us:** model implementation, study assumptions, relay settings, algorithms, controls or display choices identified by the evidence map as project additions.
- **Voltage colors:** red = 230 kV, blue = 22 kV, green = 6.6 kV, purple = 110 V DC. These describe electrical levels, not provenance.

Source facts provide context for the corresponding area. An area-level source fact does not imply that every numerical parameter or algorithm in the snapshot came from that PDF. Consult **SOURCES_AND_ADDITIONS.md** and **metadata/provenance.json** for the complete evidence map. Snapshot annotations do not claim that study settings are commissioned plant settings.

## Files

- `annotated/` — presentation-ready PNG cards.
- `raw/` — actual Simulink PNG exports.
- `manifest.json` — exported system/detail records and their image paths.
- `block_inventory.json` — model block metadata, where supplied by the export.
- `metadata/provenance.json` — verified source facts and project additions.
- `SOURCES_AND_ADDITIONS.md` — source audit and interpretation notes.
- `build_snapshot_gallery.py` — repeatable Pillow builder.

## Rebuild

From this folder, run:

```powershell
& 'C:\\Users\\sindi\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe' .\\build_snapshot_gallery.py
```

The builder requires `manifest.json` and `metadata/provenance.json`. Every manifest area must map to provenance. A PDF-supported fact without an exact source name and page causes an error instead of silently producing an unsupported label. Raw exports and evidence inputs are not modified.
'''
    (ROOT / "README.md").write_text(content, encoding="utf-8")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", type=Path, default=ROOT / "manifest.json")
    parser.add_argument("--provenance", type=Path, default=ROOT / "metadata" / "provenance.json")
    parser.add_argument("--width", type=int, default=3200)
    parser.add_argument("--only", help="Build a single id for visual review; does not replace the full gallery")
    parser.add_argument("--workers", type=int, default=3, help="Parallel image builders (default: 3)")
    args = parser.parse_args()
    if args.width < 2560:
        parser.error("Card width must be at least 2560 pixels")
    manifest = load_json(args.manifest)
    records = manifest if isinstance(manifest, list) else manifest.get("snapshots", manifest.get("records", []))
    if not records:
        raise ValueError("The export manifest contains no snapshots")
    provenance = load_json(args.provenance)
    records = [r for r in records if not args.only or str(r.get("id")) == args.only]
    if not records:
        raise ValueError(f"Snapshot id not found: {args.only}")
    ids = [slug(r.get("id")) for r in records]
    if len(ids) != len(set(ids)):
        raise ValueError("Snapshot ids must be unique after filename normalization")
    # Validate all evidence and files before writing any output card.
    for r in records:
        source_items(evidence_for(r, provenance))
        resolve_image(r)
    out = ROOT / "annotated"
    out.mkdir(exist_ok=True)
    with ThreadPoolExecutor(max_workers=max(1, args.workers)) as pool:
        cards = list(pool.map(lambda r: build_card(r, provenance, out, args.width), records))
    if not args.only:
        build_html(cards)
        build_contact_sheet(cards)
        write_readme(cards)
    print(f"Built {len(cards)} annotated snapshot(s)." + (" Gallery: index.html" if not args.only else ""))


if __name__ == "__main__":
    main()
