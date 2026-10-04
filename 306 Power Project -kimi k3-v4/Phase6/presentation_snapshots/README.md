# V4 presentation snapshots

Open **index.html** in a browser to search and filter the 24 snapshots. No server or internet connection is needed.

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
& 'C:\Users\sindi\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' .\build_snapshot_gallery.py
```

The builder requires `manifest.json` and `metadata/provenance.json`. Every manifest area must map to provenance. A PDF-supported fact without an exact source name and page causes an error instead of silently producing an unsupported label. Raw exports and evidence inputs are not modified.
