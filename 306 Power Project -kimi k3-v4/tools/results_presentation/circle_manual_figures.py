"""Circle SLD-sourced vs study-added protection on manual snapshots.

RED   = WE ADDED (GROUP B study settings/logic).
BLUE  = FROM SLD (GROUP A drawing-placed hardware/positions).
Numbered badges sit on each circle; the full legend lives in empty canvas
space so no label ever covers model content. Originals untouched; writes
*_circled.png beside them in docs/phase5/snapshots/.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent.parent
SNAP = ROOT / "docs/phase5/snapshots"
RED = (200, 30, 30)
BLUE = (20, 90, 200)
NAVY = (22, 57, 78)
WHITE = (255, 255, 255)


def font(px):
    try:
        return ImageFont.truetype("C:/Windows/Fonts/arial.ttf", px)
    except Exception:
        try:
            return ImageFont.load_default(size=px)
        except Exception:
            return ImageFont.load_default()


BANNER_LONG = "RED = WE ADDED (study pickups / logic)      BLUE = FROM SLD (drawing hardware)"
BANNER_SHORT = "RED = WE ADDED   ·   BLUE = FROM SLD"


def banner(d, W, H, px, pos="top", short=False):
    f = font(px)
    txt = BANNER_SHORT if short else BANNER_LONG
    bb = d.textbbox((0, 0), txt, font=f)
    bh = (bb[3] - bb[1]) + 2 * (px // 2)
    if pos == "top":
        d.rectangle([0, 0, W, bh], fill=NAVY)
        d.text((W // 2, bh // 2), txt, font=f, fill=WHITE, anchor="mm")
    else:
        d.rectangle([0, H - bh, W, H], fill=NAVY)
        d.text((W // 2, H - bh // 2), txt, font=f, fill=WHITE, anchor="mm")
    return bh / H


def ring(d, W, H, cx, cy, w, h, color, lw):
    d.ellipse([(cx - w / 2) * W, (cy - h / 2) * H,
               (cx + w / 2) * W, (cy + h / 2) * H], outline=color, width=lw)


def badge(d, W, H, x, y, num, color, px):
    r = int(px * 0.95)
    X, Y = x * W, y * H
    d.ellipse([X - r, Y - r, X + r, Y + r], fill=color)
    f = font(int(px * 1.1))
    d.text((X, Y), str(num), font=f, fill=WHITE, anchor="mm")


def legend(d, W, H, x, y, items, px):
    f = font(px)
    lines = [f"{n}  {t}" for (n, t, _c) in items]
    widths, heights = [], []
    for t in lines:
        bb = d.textbbox((0, 0), t, font=f)
        widths.append(bb[2] - bb[0])
        heights.append(bb[3] - bb[1])
    pad, gap, dot = px // 2, int(px * 0.55), int(px * 0.42)
    bw = max(widths) + dot + 3 * pad
    bh = sum(heights) + gap * (len(lines) - 1) + 2 * pad
    X, Y = x * W, y * H
    d.rectangle([X, Y, X + bw, Y + bh], fill=WHITE, outline=NAVY, width=max(2, px // 12))
    yy = Y + pad
    for (n, t, c), wdt, hgt in zip(items, widths, heights):
        d.ellipse([X + pad, yy, X + pad + dot, yy + dot], fill=c)
        d.text((X + pad + dot + pad // 2, yy + dot / 2), f"{n}  {t}", font=f,
               fill=(20, 20, 20), anchor="lm")
        yy += hgt + gap


def process(name, circles, legend_at, legend_items, title=None, banner_pos="top",
            title_xy=None, compact=False):
    img = Image.open(SNAP / name).convert("RGB")
    W, H = img.size
    d = ImageDraw.Draw(img)
    px = max(14, int(W / 60))
    tiny = compact and W < 450
    if not tiny:
        banner(d, W, H, px, banner_pos, short=compact)
    lw = max(3, int(W / 350))
    for (cx, cy, w, h, color, num, bx, by) in circles:
        ring(d, W, H, cx, cy, w, h, color, lw)
        badge(d, W, H, bx, by, num, color, px)
    if not compact:
        legend(d, W, H, *legend_at, legend_items, px)
    if title:
        f = font(px)
        bb = d.textbbox((0, 0), title, font=f)
        if tiny:
            # full-width strip under the image content for very small figures
            th = (bb[3] - bb[1]) + px
            strip = Image.new("RGB", (W, th + px // 2), NAVY)
            img2 = Image.new("RGB", (W, H + th + px // 2), WHITE)
            img2.paste(img, (0, 0))
            img2.paste(strip, (0, H))
            img = img2
            d = ImageDraw.Draw(img)
            W, H = img.size
            d.text((W // 2, H - (th + px // 2) // 2), title, font=f, fill=WHITE, anchor="mm")
            out = SNAP / name.replace(".png", "_circled.png")
            img.save(out)
            print("WROTE", out.name, img.size)
            return
        tw = (bb[2] - bb[0]) + px
        th = (bb[3] - bb[1]) + px
        tx, ty, anch = title_xy or (0.985, 0.985, "mm")
        cxp, cyp = tx * W, ty * H
        if anch == "mm":
            box = [cxp - tw / 2, cyp - th / 2, cxp + tw / 2, cyp + th / 2]
        elif anch == "rb":
            box = [cxp - tw, cyp - th, cxp, cyp]
        else:
            box = [cxp, cyp, cxp + tw, cyp + th]
        d.rectangle(box, fill=NAVY)
        d.text(((box[0] + box[2]) / 2, (box[1] + box[3]) / 2), title, font=f,
               fill=WHITE, anchor="mm")
    out = SNAP / name.replace(".png", "_circled.png")
    img.save(out)
    print("WROTE", out.name, img.size)


A = BLUE
B = RED

# Fig.0 plant overview (legend in empty middle band)
process("000_Plant_overview.png", [
    (0.270, 0.908, 0.150, 0.075, B, 1, 0.270, 0.862),
    (0.255, 0.589, 0.075, 0.055, A, 2, 0.300, 0.589),
    (0.272, 0.133, 0.150, 0.070, A, 3, 0.360, 0.133),
    (0.495, 0.133, 0.150, 0.070, A, 4, 0.583, 0.133),
    (0.496, 0.908, 0.150, 0.075, A, 5, 0.496, 0.862),
    (0.688, 0.908, 0.120, 0.075, A, 6, 0.688, 0.862),
], (0.560, 0.400), [
    (1, "PROTECTION box: WE ADDED (7 study relays)", B),
    (2, "Generator Breaker: FROM SLD", A),
    (3, "Switchyard + Q0: FROM SLD", A),
    (4, "Line breakers: FROM SLD", A),
    (5, "DC bus hardware: plant", A),
    (6, "Mechanism blocks: SLD-placed", A),
], title="Fig.0 circled: red = added, blue = SLD")

# Fig.336 Protection subsystem (banner at bottom so the relay-name strip stays
# visible; legend in empty lower half; title top-right over empty canvas)
process("336_Protection.png", [
    (0.135, 0.030, 0.270, 0.050, B, 1, 0.285, 0.030),
    (0.510, 0.270, 0.420, 0.300, B, 2, 0.510, 0.105),
    (0.090, 0.170, 0.200, 0.120, A, 3, 0.200, 0.170),
    (0.878, 0.340, 0.220, 0.120, A, 4, 0.755, 0.340),
], (0.030, 0.640), [
    (1, "relay names strip: ALL WE ADDED (B1-B8)", B),
    (2, "engine block: WE ADDED, 7 relays in one block", B),
    (3, "P6_PHASORS in: FROM SLD CTs (A7/A8/A9)", A),
    (4, "P6_REQUESTS out: TO SLD breakers (A10)", A),
], title="Fig.2 circled", banner_pos="bottom", title_xy=(0.985, 0.060, "rb"))

# Small figures: compact mode (short banner, meaning carried by badge title)
process("339_Protection_Pickup_and_relay_timing.png", [
    (0.470, 0.430, 0.900, 0.600, B, 1, 0.060, 0.430),
], None, None, title="Fig.3 RED = added engine (7 relays)", compact=True)

process("342_Protection_Trip_requests.png", [
    (0.500, 0.470, 0.850, 0.600, A, 1, 0.080, 0.470),
], None, None, title="Fig.4 BLUE = out to SLD breakers", compact=True)

process("375_Switchyard_GSUT_breaker_Q0.png", [
    (0.500, 0.470, 0.850, 0.600, A, 1, 0.080, 0.470),
], None, None, title="Fig.6 BLUE = Q0 from SLD", compact=True)

process("053_Breaker_Control_DC_trip_path_and_mechanism.png", [
    (0.500, 0.490, 0.880, 0.600, B, 1, 0.060, 0.490),
], None, None, title="Fig.8 RED = added gate+mechanism", compact=True)

print("CIRCLES_DONE")
