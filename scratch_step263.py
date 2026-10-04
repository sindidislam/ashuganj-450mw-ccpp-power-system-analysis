python -c "
import os, shutil
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

p4_dir = Path(r'c:\Users\Sindid\OneDrive\Desktop\MouseWithoutBorders\306 Power Project -ekkebare f\306 Power Project -kimi k3-v4\docs\phase4\snapshots')
p4_ext = Path(r'c:\Users\Sindid\OneDrive\Desktop\MouseWithoutBorders\306 Power Project -ekkebare f\Phase 4 Docs\snapshots')
p4_dir.mkdir(parents=True, exist_ok=True)
p4_ext.mkdir(parents=True, exist_ok=True)

# 1. Copy individual fault block snapshots
snap_src = Path(r'c:\Users\Sindid\OneDrive\Desktop\MouseWithoutBorders\306 Power Project -ekkebare f\306 Power Project -kimi k3-v4\Phase6\presentation_snapshots\annotated')
fault_copies = {
    '087_Generator_fault.png': 'F1_generator_fault_block.png',
    '401_LV_connection_fault.png': 'F2_transformer_LV_fault_block.png',
    '371_GIS_bus_fault.png': 'F3_GIS_bus_fault_block.png',
    '417_Line_midpoint_fault.png': 'F4_line_midpoint_fault_block.png',
    '131_Remote_bus_fault.png': 'F5_remote_bus_fault_block.png'
}
for s, d in fault_copies.items():
    sp = snap_src / s
    if sp.exists():
        shutil.copy(sp, p4_dir / d)
        shutil.copy(sp, p4_ext / d)
        print('Copied', d)

# 2. Let's create simulink_fault_locations_marked.png from 000_Plant_overview.png
top_src = Path(r'c:\Users\Sindid\OneDrive\Desktop\MouseWithoutBorders\306 Power Project -ekkebare f\306 Power Project -kimi k3-v4\docs\phase5\snapshots\000_Plant_overview.png')
if top_src.exists():
    im = Image.open(top_src).convert('RGB')
    W, H = im.size
    d = ImageDraw.Draw(im)
    try:
        f_badge = ImageFont.truetype('C:/Windows/Fonts/arialbd.ttf', int(W/55))
        f_lbl = ImageFont.truetype('C:/Windows/Fonts/arialbd.ttf', int(W/70))
        f_title = ImageFont.truetype('C:/Windows/Fonts/arialbd.ttf', int(W/45))
    except:
        f_badge = f_lbl = f_title = ImageFont.load_default()
    
    # Fault targets on 000_Plant_overview:
    # F1: Generator subsystem (x=0.19, y=0.45)
    # F2: Transformer subsystem (x=0.35, y=0.45)
    # F3: Switchyard 230kV GIS (x=0.28, y=0.18)
    # F4: Transmission line (x=0.58, y=0.18)
    # F5: Remote grid interface (x=0.88, y=0.18)
    faults = [
        ('F1', 0.19, 0.45, 'F1: 22 kV Generator Bus (126.2 kA / 7.27 A)'),
        ('F2', 0.35, 0.45, 'F2: GSUT 22 kV LV Terminals (126.2 kA)'),
        ('F3', 0.28, 0.18, 'F3: 230 kV GIS Busbar (50.53 kA)'),
        ('F4', 0.58, 0.18, 'F4: 230 kV Line Mid-Point m=0.5 (51.06 kA)'),
        ('F5', 0.88, 0.18, 'F5: 230 kV Remote Grid Bus (53.09 kA)')
    ]
    
    # Draw header banner
    bh = int(H * 0.055)
    d.rectangle([0, 0, W, bh], fill=(15, 43, 60))
    d.text((W//2, bh//2), 'ASHUGANJ SOUTH 450 MW — 5 KEY FAULT STUDY LOCATIONS (F1 to F5)', font=f_title, fill=(255,255,255), anchor='mm')
    
    for f_id, xf, yf, lbl in faults:
        cx, cy = int(xf * W), int(yf * H)
        r = int(W * 0.038)
        # Outer pulsating rings
        d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=(220, 20, 20), width=max(4, int(W/300)))
        d.ellipse([cx - r - 6, cy - r - 6, cx + r + 6, cy + r + 6], outline=(255, 230, 0), width=max(2, int(W/600)))
        # Badge
        br = int(r * 0.65)
        d.ellipse([cx - br, cy - br, cx + br, cy + br], fill=(220, 20, 20))
        d.text((cx, cy), f_id, font=f_badge, fill=(255,255,255), anchor='mm')
        # Label card below/above
        ly = cy + r + int(H * 0.035) if yf < 0.3 else cy - r - int(H * 0.035)
        bb = d.textbbox((0, 0), lbl, font=f_lbl)
        tw, th = bb[2] - bb[0], bb[3] - bb[1]
        pad = int(W/180)
        d.rectangle([cx - tw//2 - pad, ly - th//2 - pad, cx + tw//2 + pad, ly + th//2 + pad], fill=(255,255,255), outline=(220,20,20), width=2)
        d.text((cx, ly), lbl, font=f_lbl, fill=(15, 23, 42), anchor='mm')

    out1 = p4_dir / 'simulink_fault_locations_marked.png'
    out2 = p4_ext / 'simulink_fault_locations_marked.png'
    im.save(out1)
    im.save(out2)
    print('Saved', out1.name)
"