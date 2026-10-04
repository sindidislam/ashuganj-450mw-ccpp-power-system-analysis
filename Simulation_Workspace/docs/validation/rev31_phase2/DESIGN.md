# Rev3.1 Phase 2 design

## Authorization and boundary

Implement only the user's Phase-2 specification. The user approved the registry-extension architecture and confirmed on 2026-09-15 that the six capability points were manually extracted from the source graph and supplied by the user. Their classification is PRIMARY_SOURCE_EXTRACTED, not directly tabulated manufacturer data. The local two-page generator PDF does not contain the attachment; independent attachment inspection is not claimed.

No fault, sequence-network, protection, breaker-duty, IEC 60909, final machine simulation, final AVR/PSS tuning, or dynamic Simulink integration. No Rev2 changes. No source workbook/PDF or historical output changes.

## Architecture

Extend the existing authoritative generator provider and master rather than creating a competing machine registry. Preserve all Phase-1 primary values, raw provenance, legacy values, resistance conversions, and separate unqualified/saturated subtransient fields. Add a normalized provenance view without discarding the original metadata.

Six canonical profiles form the current operating registry: two primary 360 MW cases, two qualified 342.01 MW cases, and two historical 389.30 MW references. Preserve LF1–LF4 as explicitly historical compatibility aliases, including their original dispatch/topology. Default new Phase-2 execution selects the two primary profiles; an explicit all-profiles selection runs all six. The old runner remains available only as a historical workflow; Phase-2 results go to a new directory and saved historical models are not rebuilt.

Every profile carries generator/dataset identity, active capacity, dispatch, historical exception, switch/topology states, voltage setpoints, auxiliary allocation, grid definition, assumptions and provenance. The primary capacity guard cannot be bypassed by setting a historical exception on a primary case. Both voltage setpoints remain 1.00 pu. UAT stays in service. GAT OUT means its HV bay is open while its LV remains connected and back-energizes the transformer, matching the historical network.

## Capability and solver freeze

Store exactly the six user-supplied points: P = 0, 100, 200, 300, 389.3, 458 MW; upper Q = 335, 329, 311, 280, 241, 0 MVAr; lower Q = -231, -231, -220, -205, -182, 0 MVAr. Preserve the 458 MW endpoint without implying dispatch authorization. Use piecewise-linear interpolation and reject nonfinite, complex or out-of-domain inputs. At 360 MW, compute limits rather than storing check values.

Physical generator and case reactive limits are finite and curve-derived. The existing balanced-LF PV block's ideal source, grounded-star mathematical representation and unbounded solver Q settings are explicitly grandfathered by the user's design approval, solely to preserve the frozen unconstrained solve and avoid PV-to-PQ switching or artificial Q clipping. They are not physical capability or grounding data. Generator grounding remains the high-resistance NER; no fault model may reuse the PV block as a grounding model.

Do not change solver equations, convergence, branch reconstruction, transformer/tap physics, grid impedances, or load allocation. A separate post-solve validator reports actual P/Q/S/PF, capability and MVA margins, dispatch validity, voltage, loading, convergence, KCL and independent active/reactive balances. Sum independently reconstructed branch losses for both balances, with a documented 0.001 MW/MVAr tolerance; retain the existing 0.05 MVA KCL criterion and report actual residuals. Violations remain visible and are never corrected by modifying the solved point. MVA or primary dispatch exceedance stops acceptance.

## Provenance and assumptions

Normalized parameter records carry value, unit, source, source locator, status, confidence and rationale. Engineering assumptions additionally carry assumption basis, reasonable/assumed range and selected value. Preserve source status separately from derivation and interpretation qualification. Capability extraction has its own specific status within the source-qualified hierarchy. Missing source evidence is distinct from a finite assumed model parameter. No field-resistance base is invented; unused detailed rotor and GAT tertiary gaps remain explicitly unresolved.

The central assumption register feeds separate excitation, SFC, station DC, governor/turbine and optional generic PSS objects. No academic control/DC parameter is presented as commissioned or manufacturer data. Existing frozen grid idealizations remain documented exceptions, not a reason to introduce ideal components in the new subsystems.

## Excitation and dynamic readiness

Static and SEMIPOL remain workbook source data. Use a generic academic two-lag static exciter with AVR gain 200, AVR time constant 0.02 s, field-response lag 0.5 s, and command ceiling/lower bound +5/-5 pu. Document the abstract per-unit equations and bases; do not map 122 V or unresolved field resistance onto an invented physical field base.

Prepare finite OEL, UEL and stator-current limiter thresholds and responses. OEL uses a separately declared academic rated-field reference; no claim of measured field current. UEL derives its operating boundary from the source capability curve with a declared academic inset and finite response. A stator limiter must not attempt to repair active-current overload by changing excitation; report that condition as requiring dispatch action. Include anti-windup/limited-state behavior where the simple component equations require it. These component calculations are testable in isolation and are not final tuning or a closed-loop plant stability claim.

Keep no-load excitation voltage 122 V separate from controller parameters. The SFC has its own 2.28 kV DC-link and 1876 A maximum starting OUTPUT current records; never multiply those incompatible-side ratings to claim verified converter power. Any simplified power bound is separately assumed with defined units/side. Use 0.97 efficiency and 0.03 s response as academic assumptions.

Prepare sixth-order input data from the exact primary machine values, including unqualified subtransient reactance 0.2608 pu. Preserve 0.2248 pu separately and declare the selection. Governor droop 5%, governor lag 0.2 s and turbine lag 0.75 s are assumptions. A generic finite PSS profile may be stored but remains disabled and untuned. Readiness is not final dynamic validation.

## Station DC, battery and charger

Model an isolated academic 110 VDC system, 55 two-volt cells and 200 Ah nominal capacity, with 0.05 ohm whole-bank internal resistance. Use a finite SOC-dependent open-circuit voltage, explicit terminal sag and finite discharge/charge capacity. Document cutoff/end-of-discharge behavior; reject invalid state/time inputs instead of silently producing nonphysical outputs. The simplified model is not electrochemical or a DC fault study.

Two 100%-rated 20 kW chargers use finite current and power bounds, finite response and 92.5% efficiency. Nominal system voltage and assumed float regulation target must be explicitly distinguished to avoid a 110 V ideal charger being unable to maintain a realistic lead-acid bank. Define duty/standby behavior so redundancy does not silently double normal output. Report both DC power and AC input accounting; do not add either to the existing 14 MW LF demand, because overlap is unresolved.

Create nonzero continuous relay, control, instrumentation, communications and excitation-control electronics loads, plus separate trip, close and emergency demands and pulse durations. All are assumptions. The excitation-control load denotes auxiliary electronics only, not generator field power. No electrical connection is inferred between station battery, generator field and SFC.

## Verification and deliverables

Baseline: complete current ten-file test suite and four fresh unsaved historical solves. SHA-256 inventory covers every original file. Post-change: generator/base/master/topology tests; source curve endpoints/interpolation/domain errors; capacity/exception misuse; capability violations without clipping; six fresh LF cases and historical alias comparisons; independently reconstructed P/Q balance; parameter metadata/ranges; component finite response, battery sag/depletion and charger saturation; complete suite.

New evidence includes baseline/post logs, result tables, historical comparisons, a capability plot distinguishing primary/qualified/historical dispatch, full assumption and source-vs-assumption tables, an occurrence audit with coverage limitations, and exact changed/unchanged-file hash manifests. Reports include all requested sections A–AF. Preserve transformer numerical records and independently verify 28 kW cooling loss as 1282 minus 159 minus 1095, without changing LF accounting.

## Review

No Git repository exists, so no commit can be made. File hashes provide change tracking. The design intentionally separates physical limit validation from frozen solver controls, and missing source data from finite academic model assumptions. Implementation begins only after written-design approval and successful baseline completion.
