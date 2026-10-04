function S = phase2_source_data(G)
%PHASE2_SOURCE_DATA Read-only normalized Task-1 source/provenance view.
% S = phase2_source_data() uses ashuganj_generators(); S=phase2_source_data(G)
% accepts that scalar generator record, never an assembled master dataset.
% No provider is modified. S.generator has one parameter record per field
% in G.Provenance, each with raw_provenance retaining the full original.
% Other groups: capabilityCurve (same authoritative object), excitation,
% sfc, ner, grid and cooling. Group leaves are phase2_parameter records;
% S.dataset_id identifies the generator. Units are explicit at every leaf.
% Source status, derivation and interpretation are distinct. Additional
% records are contextual only: no grid/transformer/grounding model changes,
% no conversion of field resistance and no inferred SFC power or DC wiring.
if nargin < 1
    G = ashuganj_generators();
end
S.dataset_id = G.Dataset_ID;
names = fieldnames(G.Provenance);
for k=1:numel(names)
    n = names{k}; old = G.Provenance.(n);
    locator = old.Source_locator;
    if ~strcmp(old.Source_sheet,'NOT_APPLICABLE')
        locator = [locator '; sheet "' old.Source_sheet '"'];
    end
    if ~strcmp(old.Source_cell,'NOT_APPLICABLE')
        locator = [locator '; cell ' old.Source_cell];
    end
    r = phase2_parameter(old.Normalized_value,old.Normalized_unit, ...
        old.Source_document,locator,old.Source_status,old.Confidence, ...
        old.Interpretation_note,'source_status',old.Source_status, ...
        'derivation',old.Derivation,'interpretation_status',old.Interpretation_status);
    r.raw_provenance = old;
    S.generator.(n) = r;
end
S.capabilityCurve = G.capabilityCurve;
S.excitation.type = S.generator.Excitation_type;
S.excitation.designation = S.generator.Excitation_designation;
doc = 'Generator Data_South.pdf';
loc = 'PDF p.1 / report p.6 section 2.1.1';
verified = 'VERIFIED_ENGINEERING_DOCUMENT';
S.excitation.no_load_voltage_V = phase2_parameter(G.Uexc0_V,'V',doc,loc, ...
    G.Uexc0_Status,'High','No-load excitation voltage only; not a controller parameter or a defined per-unit field base.');
S.sfc.dc_link_kV = phase2_parameter(G.SFC_DC_link_kV,'kV',doc,loc, ...
    G.SFC_DC_link_Status,'High','SFC DC-link voltage, separate from generator field and station DC.');
S.sfc.dc_link_kV.side = 'DC_LINK';
S.sfc.max_starting_output_A = phase2_parameter(G.SFC_Imax_A,'A',doc,loc, ...
    G.SFC_Imax_Status,'High','Maximum starting OUTPUT current; not DC-link current. Do not multiply by DC-link voltage to claim verified power.');
S.sfc.max_starting_output_A.side = 'OUTPUT';
loc = 'PDF p.2 / report p.7 section 2.3 Neutral Earthing Transformer (BAB), 10BAB11';
S.ner.primary_kV = phase2_parameter(22/sqrt(3),'kV',doc,loc,verified,'High', ...
    'Source 22/sqrt(3) kV primary phase voltage; not a line-line 22 kV winding rating.', ...
    'derivation','22 / sqrt(3)');
S.ner.secondary_V = phase2_parameter(500,'V',doc,loc,verified,'High','NER secondary rating.');
S.ner.rating_kVA = phase2_parameter(135,'kVA',doc,loc,verified,'High','Short-time rating, valid for 20 s, not continuous.');
S.ner.duration_s = phase2_parameter(20,'s',doc,loc,verified,'High','Duration associated with 135 kVA rating.');
S.ner.hv_dc_resistance_ohm = phase2_parameter(60,'ohm',doc,loc,verified,'Qualified / approximate', ...
    'HV-winding DC resistance approximately 60 ohm; source carries a question mark. Not a verified zero-sequence equivalent.', ...
    'interpretation_status','QUALIFIED');
S.ner.loading_resistance_ohm = phase2_parameter(2.62,'ohm',doc,loc,verified,'Qualified / approximate', ...
    'Secondary loading resistor approximately 2.62 ohm; source carries question marks. Do not add directly to HV resistance across different sides.', ...
    'interpretation_status','QUALIFIED');
S.ner.grounding = S.generator.Earthing;
loc = 'PDF p.2 / report p.7 section 2.4 High voltage network (GRID)';
S.grid.estimate_Isc_kA = phase2_parameter(50,'kA',doc,loc,'ESTIMATED','Estimated', ...
    'Report estimated grid context; frozen provider uses 50 kA GIS withstand proxy, not verified PGCB fault strength.');
S.grid.estimate_Ssc_GVA = phase2_parameter(19.919,'GVA',doc,loc,'ESTIMATED','Estimated', ...
    'Source rounded 19,919 MVA = 19.919 GVA; not a replacement for frozen sqrt(3)*230*50 MVA arithmetic.', ...
    'derivation','19919 MVA / 1000');
secondary = 'Secondary 2019 fault-level compilation, ASHUGANJ S 230 kV';
locator = 'Existing project reconciliation: matlab/studies/rev3_b1_derivations.m secondary sensitivity; original secondary attachment not re-inspected';
S.grid.sensitivity_Isc_kA = phase2_parameter(45.01,'kA',secondary,locator, ...
    'SECONDARY_SOURCE_CONTEXT','Qualified secondary context','Sensitivity only, not selected frozen grid strength.');
S.grid.sensitivity_XR = phase2_parameter(10.99,'dimensionless',secondary,locator, ...
    'SECONDARY_SOURCE_CONTEXT','Qualified secondary context','Sensitivity only; frozen grid R=0 and infinite X/R remain untouched.');
doc = 'GSUT Data Sheet_South.pdf';
loc = 'CTI 1.7 loss table, 515 MVA ODAF stage; existing rev3_b1_derivations source transcription';
S.cooling.gsut_total_kW = phase2_parameter(1282,'kW',doc,loc,verified,'High','Total source loss at 515 MVA cooling stage; contextual accounting only.');
S.cooling.gsut_no_load_kW = phase2_parameter(159,'kW',doc,loc,verified,'High','Source no-load loss; numerical transformer provider unchanged.');
S.cooling.gsut_load_kW = phase2_parameter(1095,'kW',doc,loc,verified,'High','Source load loss at 515 MVA; numerical transformer provider unchanged.');
cooling = S.cooling.gsut_total_kW.value-S.cooling.gsut_no_load_kW.value-S.cooling.gsut_load_kW.value;
S.cooling.gsut_cooling_kW = phase2_parameter(cooling,'kW',doc,loc, ...
    'DERIVED_FROM_VERIFIED_DATA','High arithmetic / source-qualified', ...
    'Residual source cooling loss, not added to frozen LF demand or transformer losses; auxiliary overlap unresolved.', ...
    'source_status',verified,'derivation','1282 - 159 - 1095','interpretation_status','QUALIFIED');
end
