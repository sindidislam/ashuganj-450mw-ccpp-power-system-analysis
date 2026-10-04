import re
from pathlib import Path
from collections import Counter

html_path = Path("Phase 4 Docs/FAULT_ANALYSIS_MANUAL.html")
content = html_path.read_text(encoding="utf-8")

matches = re.findall(r'font-size:\s*[^;\"]+', content)
print("Font sizes in HTML:")
for k, v in Counter(matches).most_common():
    print(f"  {k}: {v}")
