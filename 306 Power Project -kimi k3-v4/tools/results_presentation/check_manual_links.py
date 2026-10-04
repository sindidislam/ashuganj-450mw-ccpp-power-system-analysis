"""One-off link check for docs/phase5 manual (additive, not part of build)."""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent
D = ROOT / "docs/phase5"
h = (D / "PROTECTION_SETTINGS_MANUAL.html").read_text(encoding="utf-8")
imgs = re.findall(r'src="(snapshots/[^"]+)"', h)
csvs = re.findall(r'href="(tables/[^"]+)"', h)
missing = [p for p in imgs + csvs if not (D / p).exists()]
print("imgs:", len(imgs), "csvs:", len(csvs), "missing:", missing if missing else "NONE")
md = (D / "PROTECTION_SETTINGS_MANUAL.md").read_text(encoding="utf-8")
print("md_lines:", len(md.splitlines()))
for fig in ["protection_zones_map.png", "336_Protection_circled.png",
            "339_Protection_Pickup_and_relay_timing_circled.png",
            "342_Protection_Trip_requests_circled.png",
            "375_Switchyard_GSUT_breaker_Q0_circled.png",
            "053_Breaker_Control_DC_trip_path_and_mechanism_circled.png"]:
    assert fig in h, fig
print("FIGREFS_OK (circled twins wired into HTML)")
snaps = list((D / "snapshots").glob("*.png"))
print("snapshots_on_disk:", len(snaps))
assert not missing, missing
print("MANUAL_LINKS_OK")
