import os
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

def generate_all_presentation_fault_visuals():
    base_dir = Path(r"c:\Users\Sindid\OneDrive\Desktop\MouseWithoutBorders\306 Power Project -ekkebare f")
    p4_ext = base_dir / "Phase 4 Docs" / "snapshots"
    p4_int = base_dir / "Simulation_Workspace" / "docs" / "phase4" / "snapshots"
    p4_ext.mkdir(parents=True, exist_ok=True)
    p4_int.mkdir(parents=True, exist_ok=True)

    # Load Windows fonts
    font_bold = "C:/Windows/Fonts/arialbd.ttf"
    font_regular = "C:/Windows/Fonts/arial.ttf"

    # =========================================================================
    # 1. TOP-LEVEL SIMULINK DYNAMIC MODEL (3753 x 2689) — ULTRA PRESENTATION GRADE
    # =========================================================================
    sim_src = base_dir / "Simulation_Workspace" / "Phase6" / "presentation_snapshots" / "raw" / "000_Plant_overview.png"
    im_sim = Image.open(sim_src).convert("RGB")
    W1, H1 = im_sim.size
    d1 = ImageDraw.Draw(im_sim)

    # Extra-large fonts for 3.4x downscaling visibility:
    f_banner1 = ImageFont.truetype(font_bold, 78)
    f_badge_pin1 = ImageFont.truetype(font_bold, 40)
    f_badge_pill1 = ImageFont.truetype(font_bold, 38)
    f_title1 = ImageFont.truetype(font_bold, 36)
    f_sub1 = ImageFont.truetype(font_bold, 28)

    # Top Header Banner
    banner_h1 = 144
    d1.rectangle([0, 0, W1, banner_h1], fill=(15, 35, 55))
    d1.rectangle([0, banner_h1 - 6, W1, banner_h1], fill=(245, 158, 11))
    d1.text(
        (W1 // 2, banner_h1 // 2 - 2),
        "ASHUGANJ SOUTH 450 MW CCPP — 5 KEY FAULT STUDY LOCATIONS (F1 to F5)",
        font=f_banner1,
        fill=(255, 255, 255),
        anchor="mm"
    )

    sim_faults = [
        {
            "id": "F1",
            "node": (860, 1675),
            "card_center": (530, 1675),
            "card_w": 500,
            "card_h": 105,
            "align": "left",
            "title": "22 kV Generator Bus",
            "sub": "Bus B_22 | Ik'' = 126.2 kA / 7.27 A"
        },
        {
            "id": "F2",
            "node": (840, 1270),
            "card_center": (530, 1270),
            "card_w": 500,
            "card_h": 105,
            "align": "left",
            "title": "GSUT 22 kV LV Terminals",
            "sub": "Bus B_22_UNIT | Ik'' = 126.2 kA"
        },
        {
            "id": "F3",
            "node": (1180, 372),
            "card_center": (1180, 220),
            "card_w": 510,
            "card_h": 105,
            "align": "above",
            "title": "230 kV GIS Switchyard Bus",
            "sub": "Bus B_230 | Ik'' = 50.53 kA"
        },
        {
            "id": "F4",
            "node": (1915, 415),
            "card_center": (1915, 220),
            "card_w": 520,
            "card_h": 105,
            "align": "above",
            "title": "230 kV Line Mid-Point (m=0.5)",
            "sub": "2 Circuits | Ik'' = 51.06 kA"
        },
        {
            "id": "F5",
            "node": (2760, 352),
            "card_center": (2760, 220),
            "card_w": 520,
            "card_h": 105,
            "align": "above",
            "title": "230 kV Remote Grid Substation",
            "sub": "Bus BGRID_230 | Ik'' = 53.09 kA"
        }
    ]

    r_outer = 40
    r_inner = 28

    for item in sim_faults:
        nx, ny = item["node"]
        cx, cy = item["card_center"]
        bw = item["card_w"]
        bh = item["card_h"]

        b_left = cx - bw // 2
        b_right = cx + bw // 2
        b_top = cy - bh // 2
        b_bottom = cy + bh // 2

        # 1. Leader Line
        if item["align"] == "left":
            p_start = (b_right, cy)
            p_end = (nx - r_outer - 5, ny)
        elif item["align"] == "above":
            p_start = (cx, b_bottom)
            p_end = (nx, ny - r_outer - 5)

        d1.line([p_start, p_end], fill=(220, 38, 38), width=6)
        d1.ellipse([p_start[0]-6, p_start[1]-6, p_start[0]+6, p_start[1]+6], fill=(220, 38, 38))
        d1.ellipse([p_end[0]-6, p_end[1]-6, p_end[0]+6, p_end[1]+6], fill=(220, 38, 38))

        # 2. Card Shadow & Background
        shadow = 6
        d1.rectangle([b_left + shadow, b_top + shadow, b_right + shadow, b_bottom + shadow], fill=(203, 213, 225))
        d1.rectangle([b_left, b_top, b_right, b_bottom], fill=(255, 255, 255), outline=(100, 116, 139), width=3)
        d1.rectangle([b_left, b_top, b_left + 14, b_bottom], fill=(220, 38, 38))

        # Badge Pill inside card
        pill_w = 64
        pill_h = 46
        px0 = b_left + 24
        py0 = cy - pill_h // 2
        d1.rounded_rectangle([px0, py0, px0 + pill_w, py0 + pill_h], radius=10, fill=(220, 38, 38))
        d1.text((px0 + pill_w // 2, cy), item["id"], font=f_badge_pill1, fill=(255, 255, 255), anchor="mm")

        # Text inside card
        tx = px0 + pill_w + 16
        d1.text((tx, b_top + int(bh * 0.32)), item["title"], font=f_title1, fill=(15, 23, 42), anchor="lm")
        d1.text((tx, b_top + int(bh * 0.72)), item["sub"], font=f_sub1, fill=(30, 41, 59), anchor="lm")

        # 3. Target Node Highlight Ring & Pin
        d1.ellipse([nx - r_outer, ny - r_outer, nx + r_outer, ny + r_outer], outline=(220, 38, 38), width=6)
        d1.ellipse([nx - r_outer - 5, ny - r_outer - 5, nx + r_outer + 5, ny + r_outer + 5], outline=(245, 158, 11), width=3)
        d1.ellipse([nx - r_inner, ny - r_inner, nx + r_inner, ny + r_inner], fill=(220, 38, 38), outline=(255, 255, 255), width=3)
        d1.text((nx, ny), item["id"], font=f_badge_pin1, fill=(255, 255, 255), anchor="mm")

    im_sim.save(p4_ext / "simulink_fault_locations_marked.png", quality=95)
    im_sim.save(p4_int / "simulink_fault_locations_marked.png", quality=95)
    print("Presentation-Grade Simulink Overview Diagram saved.")


    # =========================================================================
    # 2. MASTER OEM SLD DIAGRAM (2263 x 1600) — EXTRA-LARGE PRESENTATION GRADE
    # =========================================================================
    sld_src = base_dir / "Simulation_Workspace" / "Phase6" / "logs" / "audit_20260925" / "source_sld.png"
    im_sld = Image.open(sld_src).convert("RGB")
    W2, H2 = im_sld.size
    d2 = ImageDraw.Draw(im_sld)

    # Scaled up typography for 2.2x downscaling visibility:
    f_banner2 = ImageFont.truetype(font_bold, 48)
    f_badge_pin2 = ImageFont.truetype(font_bold, 24)
    f_badge_pill2 = ImageFont.truetype(font_bold, 24)
    f_title2 = ImageFont.truetype(font_bold, 22)
    f_sub2 = ImageFont.truetype(font_bold, 18)

    # Top Header Banner
    banner_h2 = 94
    d2.rectangle([0, 0, W2, banner_h2], fill=(15, 35, 55))
    d2.rectangle([0, banner_h2 - 4, W2, banner_h2], fill=(245, 158, 11))
    d2.text(
        (W2 // 2, banner_h2 // 2 - 2),
        "ASHUGANJ SOUTH 450 MW — MASTER OEM SLD FAULT LOCATIONS (F1 to F5)",
        font=f_banner2,
        fill=(255, 255, 255),
        anchor="mm"
    )

    sld_faults = [
        {
            "id": "F1",
            "node": (293, 800),
            "card_center": (155, 800),
            "card_w": 220,
            "card_h": 68,
            "align": "left",
            "title": "22 kV Gen Bus",
            "sub": "10MKA10 | 126.2 kA"
        },
        {
            "id": "F2",
            "node": (293, 350),
            "card_center": (155, 350),
            "card_w": 220,
            "card_h": 68,
            "align": "left",
            "title": "GSUT 22 kV LV",
            "sub": "10BAT10 | 126.2 kA"
        },
        {
            "id": "F3",
            "node": (1680, 220),
            "card_center": (1510, 140),
            "card_w": 245,
            "card_h": 68,
            "align": "diag_down_right",
            "title": "230 kV GIS Bus",
            "sub": "Switchyard | 50.5 kA"
        },
        {
            "id": "F4",
            "node": (1820, 230),
            "card_center": (1820, 140),
            "card_w": 245,
            "card_h": 68,
            "align": "above",
            "title": "230 kV Line Mid",
            "sub": "2 Circuits | 51.1 kA"
        },
        {
            "id": "F5",
            "node": (2105, 230),
            "card_center": (2105, 140),
            "card_w": 245,
            "card_h": 68,
            "align": "above",
            "title": "230 kV Grid Bus",
            "sub": "Remote Grid | 53.1 kA"
        }
    ]

    r_outer2 = 24
    r_inner2 = 17

    for item in sld_faults:
        nx, ny = item["node"]
        cx, cy = item["card_center"]
        bw = item["card_w"]
        bh = item["card_h"]

        b_left = cx - bw // 2
        b_right = cx + bw // 2
        b_top = cy - bh // 2
        b_bottom = cy + bh // 2

        # 1. Leader Lines
        if item["align"] == "left":
            p_start = (b_right, cy)
            p_end = (nx - r_outer2 - 4, ny)
            d2.line([p_start, p_end], fill=(220, 38, 38), width=5)
            d2.ellipse([p_start[0]-5, p_start[1]-5, p_start[0]+5, p_start[1]+5], fill=(220, 38, 38))
            d2.ellipse([p_end[0]-5, p_end[1]-5, p_end[0]+5, p_end[1]+5], fill=(220, 38, 38))
        elif item["align"] == "diag_down_right":
            p_start = (b_right, cy + 10)
            p_mid = (b_right + 30, cy + 10)
            p_end = (nx - r_outer2 - 4, ny)
            d2.line([p_start, p_mid, (nx - r_outer2 - 4, ny)], fill=(220, 38, 38), width=5)
            d2.ellipse([p_start[0]-5, p_start[1]-5, p_start[0]+5, p_start[1]+5], fill=(220, 38, 38))
            d2.ellipse([p_end[0]-5, p_end[1]-5, p_end[0]+5, p_end[1]+5], fill=(220, 38, 38))
        elif item["align"] == "above":
            p_start = (cx, b_bottom)
            p_end = (nx, ny - r_outer2 - 4)
            d2.line([p_start, p_end], fill=(220, 38, 38), width=5)
            d2.ellipse([p_start[0]-5, p_start[1]-5, p_start[0]+5, p_start[1]+5], fill=(220, 38, 38))
            d2.ellipse([p_end[0]-5, p_end[1]-5, p_end[0]+5, p_end[1]+5], fill=(220, 38, 38))

        # 2. Card Shadow & Background
        shadow = 5
        d2.rectangle([b_left + shadow, b_top + shadow, b_right + shadow, b_bottom + shadow], fill=(203, 213, 225))
        d2.rectangle([b_left, b_top, b_right, b_bottom], fill=(255, 255, 255), outline=(100, 116, 139), width=2)
        d2.rectangle([b_left, b_top, b_left + 10, b_bottom], fill=(220, 38, 38))

        # Badge Pill inside card
        pill_w = 46
        pill_h = 34
        px0 = b_left + 16
        py0 = cy - pill_h // 2
        d2.rounded_rectangle([px0, py0, px0 + pill_w, py0 + pill_h], radius=7, fill=(220, 38, 38))
        d2.text((px0 + pill_w // 2, cy), item["id"], font=f_badge_pill2, fill=(255, 255, 255), anchor="mm")

        # Text inside card
        tx = px0 + pill_w + 12
        d2.text((tx, b_top + int(bh * 0.32)), item["title"], font=f_title2, fill=(15, 23, 42), anchor="lm")
        d2.text((tx, b_top + int(bh * 0.72)), item["sub"], font=f_sub2, fill=(30, 41, 59), anchor="lm")

        # 3. Target Node Highlight Ring & Pin
        d2.ellipse([nx - r_outer2, ny - r_outer2, nx + r_outer2, ny + r_outer2], outline=(220, 38, 38), width=5)
        d2.ellipse([nx - r_outer2 - 3, ny - r_outer2 - 3, nx + r_outer2 + 3, ny + r_outer2 + 3], outline=(245, 158, 11), width=2)
        d2.ellipse([nx - r_inner2, ny - r_inner2, nx + r_inner2, ny + r_inner2], fill=(220, 38, 38), outline=(255, 255, 255), width=2)
        d2.text((nx, ny), item["id"], font=f_badge_pin2, fill=(255, 255, 255), anchor="mm")

    im_sld.save(p4_ext / "sld_fault_locations_marked.png", quality=95)
    im_sld.save(p4_int / "sld_fault_locations_marked.png", quality=95)
    print("Presentation-Grade Master SLD Diagram saved.")


    # =========================================================================
    # 3. FIVE HIGH-DEFINITION CLOSE-UP CROPPED SLD SNAPSHOTS (F1 TO F5)
    # =========================================================================
    # Re-open fresh source SLD so the crops are clean before drawing per-crop details
    sld_raw = Image.open(sld_src).convert("RGB")

    crop_defs = [
        {
            "id": "F1",
            "filename": "sld_crop_f1_generator.png",
            "box": (30, 560, 680, 1220), # (650 x 660)
            "node_abs": (293, 800),
            "title_banner": "SLD DETAIL · FAULT F1 (22 kV GENERATOR BUS & STATOR)",
            "equip_tag": "10MKA10 (Stator) · 10BAC10 (GCB) · 10BAB11 (NER)",
            "card_pos": (20, 80), # top-left in crop
            "card_w": 280,
            "card_h": 140,
            "specs": [
                ("Voltage Level", "22.0 kV AC"),
                ("3-Phase Fault (Ik'')", "126.21 kA LLL"),
                ("Peak Current (ip)", "348.26 kA"),
                ("Ground Fault (LG)", "7.27 A (NER Limited)"),
                ("Primary Protection", "87G Stator Diff / 51N NER")
            ]
        },
        {
            "id": "F2",
            "filename": "sld_crop_f2_gsut_lv.png",
            "box": (30, 90, 680, 700), # (650 x 610)
            "node_abs": (293, 350),
            "title_banner": "SLD DETAIL · FAULT F2 (GSUT 22 kV LV DELTA TERMINALS)",
            "equip_tag": "10BAT10 (515 MVA GSUT) · 10BBT10 (25 MVA UAT)",
            "card_pos": (20, 80), # top-left in crop
            "card_w": 285,
            "card_h": 140,
            "specs": [
                ("Voltage Level", "22.0 kV AC"),
                ("3-Phase Fault (Ik'')", "126.21 kA LLL"),
                ("Peak Current (ip)", "348.26 kA"),
                ("Vector Group Shift", "+30 deg (YNd1)"),
                ("Primary Protection", "87T Transformer Diff")
            ]
        },
        {
            "id": "F3",
            "filename": "sld_crop_f3_gis_switchyard.png",
            "box": (1260, 40, 1900, 580), # (640 x 540)
            "node_abs": (1680, 220),
            "title_banner": "SLD DETAIL · FAULT F3 (230 kV GIS SWITCHYARD BUSBAR)",
            "equip_tag": "10BAC01 (Bus 1) · 10BAC02 (Bus 2) · 10BAY11 (GSUT Bay)",
            "card_pos": (25, 80), # top-left in crop
            "card_w": 290,
            "card_h": 140,
            "specs": [
                ("Voltage Level", "230.0 kV AC"),
                ("3-Phase Fault (Ik'')", "50.53 kA LLL"),
                ("Ground Fault (LG)", "45.74 kA (Solid Earth)"),
                ("GIS Breaking Rating", "50.0 kA / 125 kA Peak"),
                ("Primary Protection", "87B Busbar Diff (35 ms)")
            ]
        },
        {
            "id": "F4",
            "filename": "sld_crop_f4_line_midpoint.png",
            "box": (1580, 40, 2140, 580), # (560 x 540)
            "node_abs": (1820, 230),
            "title_banner": "SLD DETAIL · FAULT F4 (230 kV TRANSMISSION CORRIDOR)",
            "equip_tag": "Line 1 & Line 2 (0.7 km Mallard 795 MCM D/C)",
            "card_pos": (20, 370), # bottom-left in crop
            "card_w": 290,
            "card_h": 140,
            "specs": [
                ("Voltage Level", "230.0 kV AC"),
                ("3-Phase Fault (Ik'')", "51.06 kA LLL (m=0.5)"),
                ("Ground Fault (LG)", "46.12 kA LG"),
                ("Optical Relay Link", "Siemens 7SD5221 FO"),
                ("Primary Protection", "87L Line Diff (40 ms) / 21 Z1")
            ]
        },
        {
            "id": "F5",
            "filename": "sld_crop_f5_remote_grid.png",
            "box": (1800, 40, 2263, 580), # (463 x 540)
            "node_abs": (2105, 230),
            "title_banner": "SLD DETAIL · FAULT F5 (230 kV REMOTE GRID SUBSTATION)",
            "equip_tag": "B230_REMOTE / BGRID230 · PGCB National Grid Bus",
            "card_pos": (20, 370), # bottom-left in crop
            "card_w": 275,
            "card_h": 140,
            "specs": [
                ("Voltage Level", "230.0 kV AC"),
                ("3-Phase Fault (Ik'')", "53.09 kA LLL"),
                ("Ground Fault (LG)", "48.47 kA LG"),
                ("Plant Relays Action", "87G, 87T, 87B RESTRAIN"),
                ("Grid Clearing Duty", "Remote Substation Breakers")
            ]
        }
    ]

    f_crop_banner = ImageFont.truetype(font_bold, 17)
    f_crop_equip = ImageFont.truetype(font_bold, 13)
    f_crop_badge = ImageFont.truetype(font_bold, 12)
    f_crop_spec_k = ImageFont.truetype(font_bold, 12)
    f_crop_spec_v = ImageFont.truetype(font_bold, 12)
    f_crop_pin = ImageFont.truetype(font_bold, 16)

    for item in crop_defs:
        bx0, by0, bx1, by1 = item["box"]
        crop_img = sld_raw.crop((bx0, by0, bx1, by1))
        cw, ch = crop_img.size
        d_crop = ImageDraw.Draw(crop_img)

        # 1. Header Banner
        banner_h = 52
        d_crop.rectangle([0, 0, cw, banner_h], fill=(15, 35, 55))
        d_crop.rectangle([0, banner_h - 3, cw, banner_h], fill=(245, 158, 11))
        d_crop.text((14, 15), item["title_banner"], font=f_crop_banner, fill=(255, 255, 255))
        d_crop.text((14, 35), item["equip_tag"], font=f_crop_equip, fill=(153, 246, 228))

        # 2. Target Node Pin on Crop
        nx_abs, ny_abs = item["node_abs"]
        nx_rel = nx_abs - bx0
        ny_rel = ny_abs - by0

        r_out = 20
        r_in = 14
        # Pulsing target rings
        d_crop.ellipse([nx_rel - r_out, ny_rel - r_out, nx_rel + r_out, ny_rel + r_out], outline=(220, 38, 38), width=4)
        d_crop.ellipse([nx_rel - r_out - 3, ny_rel - r_out - 3, nx_rel + r_out + 3, ny_rel + r_out + 3], outline=(245, 158, 11), width=2)
        d_crop.ellipse([nx_rel - r_in, ny_rel - r_in, nx_rel + r_in, ny_rel + r_in], fill=(220, 38, 38), outline=(255, 255, 255), width=2)
        d_crop.text((nx_rel, ny_rel), item["id"], font=f_crop_pin, fill=(255, 255, 255), anchor="mm")

        # 3. Floating Spec Card on Crop
        cx0, cy0 = item["card_pos"]
        cw_card = item["card_w"]
        ch_card = item["card_h"]
        cx1 = cx0 + cw_card
        cy1 = cy0 + ch_card

        # Drop shadow & card body
        sh = 4
        d_crop.rectangle([cx0 + sh, cy0 + sh, cx1 + sh, cy1 + sh], fill=(203, 213, 225))
        d_crop.rectangle([cx0, cy0, cx1, cy1], fill=(255, 255, 255), outline=(100, 116, 139), width=2)
        d_crop.rectangle([cx0, cy0, cx0 + 6, cy1], fill=(220, 38, 38))

        # Card header badge
        d_crop.rectangle([cx0 + 12, cy0 + 8, cx1 - 12, cy0 + 28], fill=(241, 245, 249))
        d_crop.text((cx0 + 18, cy0 + 18), f"{item['id']} ELECTRICAL STUDY DATA", font=f_crop_badge, fill=(15, 23, 42), anchor="lm")

        # Data rows
        y_text = cy0 + 40
        for label, val in item["specs"]:
            d_crop.text((cx0 + 16, y_text), label + ":", font=f_crop_spec_k, fill=(71, 85, 105))
            d_crop.text((cx1 - 16, y_text), val, font=f_crop_spec_v, fill=(15, 23, 42), anchor="ra")
            y_text += 19

        # Leader line from card to pin
        # Determine closest edge
        card_center_x = (cx0 + cx1) // 2
        card_center_y = (cy0 + cy1) // 2
        if nx_rel > cx1:
            p_card = (cx1, cy0 + ch_card // 2)
            p_pin = (nx_rel - r_out - 2, ny_rel)
        elif nx_rel < cx0:
            p_card = (cx0, cy0 + ch_card // 2)
            p_pin = (nx_rel + r_out + 2, ny_rel)
        elif ny_rel > cy1:
            p_card = (card_center_x, cy1)
            p_pin = (nx_rel, ny_rel - r_out - 2)
        else:
            p_card = (card_center_x, cy0)
            p_pin = (nx_rel, ny_rel + r_out + 2)

        d_crop.line([p_card, p_pin], fill=(220, 38, 38), width=3)
        d_crop.ellipse([p_card[0]-3, p_card[1]-3, p_card[0]+3, p_card[1]+3], fill=(220, 38, 38))
        d_crop.ellipse([p_pin[0]-3, p_pin[1]-3, p_pin[0]+3, p_pin[1]+3], fill=(220, 38, 38))

        # Save to both locations
        crop_img.save(p4_ext / item["filename"], quality=95)
        crop_img.save(p4_int / item["filename"], quality=95)
        print(f"Saved close-up detail snapshot: {item['filename']} ({cw}x{ch})")

if __name__ == "__main__":
    generate_all_presentation_fault_visuals()
