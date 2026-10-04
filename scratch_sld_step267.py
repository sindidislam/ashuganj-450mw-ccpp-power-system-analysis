python -c "
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

p4_dir = Path(r'c:\Users\Sindid\OneDrive\Desktop\MouseWithoutBorders\306 Power Project -ekkebare f\306 Power Project -kimi k3-v4\docs\phase4\snapshots')
p4_ext = Path(r'c:\Users\Sindid\OneDrive\Desktop\MouseWithoutBorders\306 Power Project -ekkebare f\Phase 4 Docs\snapshots')

sld_src = Path(r'c:\Users\Sindid\OneDrive\Desktop\MouseWithoutBorders\306 Power Project -ekkebare f\306 Power Project -kimi k3-v4\Phase6\logs\audit_20260925\source_sld.png')
im = Image.open(sld_src).convert('RGB')
W, H = im.size
d = ImageDraw.Draw(im)

try:
    f_badge = ImageFont.truetype('C:/Windows/Fonts/arialbd.ttf', int(W/45))
    f_lbl = ImageFont.truetype('C:/Windows/Fonts/arialbd.ttf', int(W/65))
    f_title = ImageFont.truetype('C:/Windows/Fonts/arialbd.ttf', int(W/40))
except:
    f_badge = f_lbl = f_title = ImageFont.load_default()

# Header banner
bh = int(H * 0.055)
d.rectangle([0, 0, W, bh], fill=(15, 43, 60))
d.text((W//2, bh//2), 'ASHUGANJ SOUTH 450 MW — MASTER SLD FAULT LOCATIONS (F1 to F5)', font=f_title, fill=(255,255,255), anchor='mm')

# Fault targets on source_sld.png (2263 x 1600):
# F1: Generator Stator Terminals (x=0.14, y=0.68)
# F2: GSUT 22 kV LV Terminals (x=0.22, y=0.32)
# F3: 230 kV GIS Switchyard Busbar (x=0.48, y=0.16)
# F4: 230 kV Transmission Line Mid-Point (x=0.74, y=0.16)
# F5: 230 kV Remote Grid Substation Bus (x=0.92, y=0.16)
faults = [
    ('F1', 0.14, 0.68, 'F1: 22 kV Gen Bus (126.2 kA / 7.27 A)'),
    ('F2', 0.22, 0.32, 'F2: GSUT 22 kV LV Terminals (126.2 kA)'),
    ('F3', 0.48, 0.16, 'F3: 230 kV GIS Bus (50.53 kA)'),
    ('F4', 0.74, 0.16, 'F4: 230 kV Line Mid-Point m=0.5 (51.06 kA)'),
    ('F5', 0.92, 0.16, 'F5: 230 kV Remote Grid Bus (53.09 kA)')
]

for f_id, xf, yf, lbl in faults:
    cx, cy = int(xf * W), int(yf * H)
    r = int(W * 0.035)
    # Double ring
    d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=(220, 20, 20), width=max(4, int(W/300)))
    d.ellipse([cx - r - 5, cy - r - 5, cx + r + 5, cy + r + 5], outline=(255, 230, 0), width=max(2, int(W/600)))
    # Central badge
    br = int(r * 0.65)
    d.ellipse([cx - br, cy - br, cx + br, cy + br], fill=(220, 20, 20))
    d.text((cx, cy), f_id, font=f_badge, fill=(255,255,255), anchor='mm')
    # Label card
    ly = cy + r + int(H * 0.035) if yf < 0.4 else cy - r - int(H * 0.035)
    bb = d.textbbox((0, 0), lbl, font=f_lbl)
    tw, th = bb[2] - bb[0], bb[3] - bb[1]
    pad = int(W/180)
    d.rectangle([cx - tw//2 - pad, ly - th//2 - pad, cx + tw//2 + pad, ly + th//2 + pad], fill=(255,255,255), outline=(220,20,20), width=2)
    d.text((cx, ly), lbl, font=f_lbl, fill=(15, 23, 42), anchor='mm')

out1 = p4_dir / 'sld_fault_locations_marked.png'
out2 = p4_ext / 'sld_fault_locations_marked.png'
im.save(out1)
im.save(out2)
print('Saved', out1.name)
"