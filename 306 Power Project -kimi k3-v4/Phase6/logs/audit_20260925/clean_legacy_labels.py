"""Apply exact annotation-only replacements and verify all other ZIP content."""
from pathlib import Path
import csv
import hashlib
import json
import re
import shutil
import zipfile
import xml.etree.ElementTree as ET
from xml.sax.saxutils import escape

audit = Path(__file__).resolve().parent
project = audit.parents[2]
plan = json.loads((audit / 'legacy_caption_plan.json').read_text(encoding='utf-8-sig'))
allowed = {'simulink/main/Ashuganj_South_Main.slx', 'simulink/studies/Load_Flow.slx',
           'simulink/studies/Load_Flow_V2.slx'}
allowed.update(f'simulink/studies/Load_Flow_LF{k}{suffix}.slx' for k in range(1,5)
               for suffix in ['', '_Annotated'])
models = list(dict.fromkeys(p['Model'] for p in plan))
assert all(m.replace('\\','/') in allowed for m in models)
prepared = []
for model in models:
    src = project / model
    assert src.is_file()
    dst = audit / 'before' / 'legacy_models_zip' / model
    dst.parent.mkdir(parents=True, exist_ok=True)
    if not dst.exists():
        shutil.copy2(src, dst)
    assert hashlib.sha256(src.read_bytes()).digest() == hashlib.sha256(dst.read_bytes()).digest(), str(src)
    prepared.append((model, src, dst))

report = []
for model, src, backup in prepared:
    rows = [p for p in plan if p['Model'] == model]
    changed = 0
    with zipfile.ZipFile(src) as zin:
        original = {i.filename: zin.read(i.filename) for i in zin.infolist()}
        revised = dict(original)
        for xmlname in dict.fromkeys(p['Xml'] for p in rows):
            raw = original[xmlname].decode('utf-8')
            source_raw = raw
            for row in (p for p in rows if p['Xml'] == xmlname):
                pattern = r'(<Annotation\b[^>]*\bSID="' + re.escape(str(row['Sid'])) + r'"[^>]*>)(.*?)(</Annotation>)'
                found = list(re.finditer(pattern, raw, flags=re.S))
                assert len(found) == 1, (model, row['Sid'])
                match = found[0]
                body = match.group(2)
                name = re.search(r'(<P\b[^>]*\bName="Name"[^>]*>)(.*?)(</P>)', body, flags=re.S)
                assert name, (model, row['Sid'])
                parsed = ET.fromstring(name.group(0)).text or ''
                assert parsed == row['OldText'], (model, row['Sid'], parsed)
                replacement = name.group(1) + escape(row['NewText']) + name.group(3)
                body = body[:name.start()] + replacement + body[name.end():]
                raw = raw[:match.start()] + match.group(1) + body + match.group(3) + raw[match.end():]
                changed += 1
            # Preserve every byte outside the annotation Name field.
            def stripped(text):
                return re.sub(r'(<Annotation\b[^>]*>)(.*?)(</Annotation>)',
                    lambda m: m.group(1) + re.sub(r'(<P\b[^>]*\bName="Name"[^>]*>).*?(</P>)',
                    r'\1\2',m.group(2),flags=re.S) + m.group(3), text, flags=re.S)
            assert stripped(source_raw) == stripped(raw), (model, xmlname)
            ET.fromstring(raw)
            revised[xmlname] = raw.encode('utf-8')
        temp = src.with_suffix('.captions.tmp')
        with zipfile.ZipFile(temp, 'w') as zout:
            for info in zin.infolist():
                zout.writestr(info, revised[info.filename])
    with zipfile.ZipFile(temp) as check:
        assert set(check.namelist()) == set(original)
        for name in original:
            assert check.read(name) == revised[name], (model, name)
    unchanged = sum(original[n] == revised[n] for n in original)
    temp.replace(src)
    report.append({'Model':model,'Captions':changed,'UnchangedZipMembers':unchanged,
                   'TotalZipMembers':len(original),'OutsideAnnotationText':'IDENTICAL',
                   'Backup':str(backup)})
    print(f'{model}: {changed} captions; all other bytes verified')
(audit/'legacy_zip_cleanup_verification.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print(f'COMPLETE: {sum(r["Captions"] for r in report)} captions in {len(report)} models')
