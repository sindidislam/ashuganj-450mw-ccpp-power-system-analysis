# Source facts and project additions

Audit: 25 September 2026. Page references below are **PDF pages including cover sheets**, not drawing sheet numbers. The thirteen supplied PDFs in `fwdtechnicaldatasldrequestforbueteeetermproject` were text-extracted; the key protection sheet was rendered and its generator/transformer relay columns visually checked. Existing data providers, parameter scripts and source-audit records were used to identify model choices, not as independent evidence of manufacturer facts.

**SOURCE PDF** means only the stated equipment, topology, rating or function is present in the cited document. **ADDED BY US** means a simulation block, numerical method, selected setting or study assumption. **MIXED** combines source context and a project implementation. A source-backed area does not make every child sensor, wire, calculation or setting source backed. Every snapshot path has a specific classification in `provenance.json`.

## Which protection existed in the supplied drawings?

| Model function | Original source evidence | Added implementation/settings |
|---|---|---|
| Generator 51 | `GENERATION AND TRANSFORMERS SYSTEM.pdf`, p.2, generator F11/F21 TRIP columns explicitly list 51. | Measured maximum phase current, inverse-time duty integration; 17170.8 A primary, TMS 0.10. |
| GSUT 51 | Same PDF p.2, F12/F26 lists 50-51. | 1380 A primary, TMS 0.55 and executable timing. |
| Generator 51N | Same PDF p.2, **both F11 and F21 explicitly list 51N**. | Selected 20/1 current scaling, neutral-resistor RMS-current path, 4 A pickup, TMS 0.15. The function is documented; these study values are not installed settings. |
| 87G | Same PDF p.2, F11/F21 lists 87G; `Generator Data_South.pdf`, p.1 identifies T1/T2 15000/1 protection CTs. | Ideal inner/terminal current comparison, 2403.8 A pickup, 30% half-sum restraint, 45 ms delay. |
| 87T | `GENERATION AND TRANSFORMERS SYSTEM.pdf`, p.2, GSUT F12/F26 lists **87**, identified by the legend as differential protection. | Model name 87T, YNd1 compensation, HV zero-sequence removal, 387.84 A HV-side pickup, 30%/60% restraint, 45 ms delay. |
| 87B | Same PDF pp.2-3, GIS interface explicitly shows **87B - 50BF**. | Three-branch equivalent bus zone, 320 A pickup, 35 ms delay, simplified breaker request set. |
| 87L | **No explicit 87L, 7SD or line-differential function was identified in the supplied thirteen PDFs.** Detailed South GIS drawing INEL-112070-00-ELC-DE-0026 is referenced but absent. | Added functional line-protection scheme: end-phasor comparison, 320 A pickup, 35 ms local delay plus 5 ms allowance, equivalent local/remote breaker sets. |

The only loose text-search match resembling “87 L” is a row-number/line-name adjacency in `Line data.pdf` p.6, an inventory table; it is not a relay function. The source-backed 87B/50BF interface does not prove installed line differential. No commissioned relay setting file was supplied. `Generator Data_South.pdf` contains only report pages 6-7 of 39, not the complete settings report.

`Google Sheet Form_Filled Up By APSCL.pdf`, p.3, specifies **IEC Standard Inverse** as an owner response; p.4 specifies **300 ms** coordination interval. These support the stated preference/criterion, not our computed relay pickups, TMS or final grading results. Other functions shown in the drawing (including 64G, 21, 40, 46, 50BF, 59 and 81) must not be described as implemented merely because they are documented.

## Equipment and model boundary

| Area | Source PDF evidence | Project addition or qualification |
|---|---|---|
| Generator | `Generator Name Plate_South.pdf`, p.2: Siemens SGen5-2000H, 458 MVA, 22 kV, 50 Hz, 3000 rpm. `Generator Data_South.pdf`, p.1: CTs, VTs and saturated reactances. | Dynamic machine mapping also uses the engineer workbook; F=0.001 pu loss coefficient, numerical shunt, selected dispatch and fault equivalent are study choices. |
| Neutral grounding | `Generator Data_South.pdf`, p.2: 22 kV/sqrt(3):500 V NGT, 135 kVA/20 s; 60 ohm HV-winding DC resistance and 2.62 ohm loading resistor both carry question marks. | The referred neutral resistance is a conditional interpretation. Do not call 60 ohm an independently verified effective generator grounding resistance. |
| GSUT | `GSUT Nameplate_South.pdf`, p.3: 355/460/515 MVA, 230/22 kV, YNd1. `GSUT Data Sheet_South.pdf`, p.3: 16% main-tap impedance. | Active PHASE5_STUDY uses the separately selected workbook 16.63%/loss route. The plate impedance boxes are blank; 912.2 kW is a workbook-derived loss, not a manufacturer test value. |
| Switchyard | `GENERATION AND TRANSFORMERS SYSTEM.pdf`, p.2: two 230 kV GIS buses; 3150 A/50 kA; GSUT bay 52-1(Q0). | Model uses a reduced bus zone. Q1/Q2 on the source are selector disconnectors, not outgoing line breakers. Detailed installed bus/line zones are unavailable. |
| UAT / GAT | `INEL-112070-00-ELC-DE-0001-REV3.pdf`, p.2: UAT 19/25 MVA, 22/6.9 kV Dyn11; GAT 19/25 MVA, 230/6.9/3.32 kV YNyn0d11. | Two-winding equivalents, GAT-out state, grounding reductions and fault points are simulation choices. |
| Auxiliaries / LV | Same Rev 03 p.2: MV/LV switchboards, transformers, motors, MCCs and lighting. Owner form p.2: 14 MW at 0.85 PF. | Lumped constant-PQ load groups on the 6.6 kV equivalent. Individual LV feeders and motor dynamics are not recreated. |
| Transmission line | Rev 03 p.2 identifies the 230 kV GIS connection; `Line data.pdf`, p.2 lists regional 230 kV routes. | The 0.7 km two-circuit South equivalent, R/X/B choices, PI sections, midpoint fault and endpoint breaker sets are study assumptions. Regional routes do not establish that 0.7 km connection. |
| Grid | `Generator Data_South.pdf`, p.2 has an estimated 230 kV/2.66 ohm/50 kA grid basis; owner form p.3 says Contact PGCB. | Present finite-R source uses the separately selected 45.01 kA study basis and zero-sequence assumptions. It is not an official current PGCB equivalent. |
| Turbine / AVR | `GENERATION AND TRANSFORMERS SYSTEM.pdf`, p.2 shows turbine trips and excitation equipment including AVR/PSS/UEL/V-Hz labels. | Generic governor, turbine and AVR dynamics/limits; not a validated Siemens controller replica. |
| DC supply | Rev 03 p.1 specifies 110 Vdc +10%/-20%; p.2 shows 110/220/24 V DC branches. Protection drawing p.2 shows 110 V controls and 220 V Siemens controls. | One 110 V lumped model; 55 cells, 200 Ah, battery/charger characteristics, load/coil pulses and health logic are chosen assumptions. Detailed DC drawing INEL-112070-00-ELC-DE-0011 is referenced but absent. |
| Breaker control | Protection drawing pp.2-3 shows 52G, transformer-bay 52-1(Q0), trip coils, lockout and trip outputs. | DC gating, latch behavior, 50 ms mechanism delay and simplified command matrix. |
| Measurements / Results | Source CT/VT topology is shown in the protection drawing pp.2-3 and generator report p.1. | Ideal sensors, phasor estimator, routing, logs, scopes, calculated displays and export tools are entirely simulation implementation. |

The preliminary `Single Line Diagram_South.pdf` is Rev 00; its Note 3 states that equipment ratings are preliminary. Prefer the later Rev 03 drawing when the two disagree. `Ahsuganj South derived from engineers (1).pdf` duplicates the preliminary SLD text; `(2).pdf` duplicates the protection drawing text, so these are not independent corroboration.

## Busbar labels and component-level reading

B01 generator 22 kV, B02 unit 22 kV, B03 GIS 230 kV, B04 remote-grid 230 kV and B05 auxiliary 6.6 kV express model electrical nodes using source voltage/topology context. The names, shapes and voltage colors are new presentation aids. B06 DC 110 V represents a computed DC state, not an added physical conserving-port DC network. Signal tags, ports, gains, selectors, scopes, display blocks and S-functions are project implementation even when their parent area has source facts.

The machine zero-sequence grounding-transformer block is an added equivalent representation; it must not be counted as a second installed transformer. Fault blocks are study test devices, not plant equipment. Ideal CT/VT blocks do not model saturation, connected burden or actual relay input filtering. The 5 ms 87L allowance does not model sample transport, channel faults or communications commissioning.

Implementation cross-checks: `Phase6/scripts/phase6_add_network.m`, `phase6_add_controls.m`, `init_phase6_parameters.m`, `phase6_electrical_profile.m`, `phase6_relay_parameters.m`, `phase6_control_parameters.m`; `Phase6/docs/RELAY_TASK_REPORT.md`, `DC_TASK_REPORT.md`; and `docs/PHASE5_SOURCE_AUDIT.md`. The machine-readable evidence map is `metadata/provenance.json`.
