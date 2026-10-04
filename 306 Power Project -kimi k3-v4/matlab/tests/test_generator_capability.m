function [np, nf] = test_generator_capability()
%TEST_GENERATOR_CAPABILITY Task-1 source, interpolation and metadata contracts.
% Literal source fixtures catch transcription, sign, interpolation, provenance
% promotion, side/base confusion and validation regressions. No model mocks.
T = t_case('test_generator_capability');
G = ashuganj_generators();
T = T.chk(isfield(G,'capabilityCurve'),'authoritative capabilityCurve exists');
if isfield(G,'capabilityCurve')
    C = G.capabilityCurve;
    T = T.eq(C.P_MW,[0 100 200 300 389.3 458],'exact six extracted P points');
    T = T.eq(C.Qmax_MVAr,[335 329 311 280 241 0],'exact extracted upper points');
    T = T.eq(C.Qmin_MVAr,[-231 -231 -220 -205 -182 0],'exact extracted lower points');
    T = T.eq(C.status,'PRIMARY_SOURCE_EXTRACTED','extraction is not tabulated manufacturer data');
    T = T.eq(C.extraction_method,'MANUAL_GRAPH_EXTRACTION','manual extraction explicit');
    T = T.eq(C.extracted_by,'USER','user supplied graph readings');
    T = T.eq(C.attachment_locally_inspected,false,'no local attachment inspection claim');
    T = T.eq(C.source_locator,'Attachment 1','attachment locator retained');
    T = T.eq(C.interpolation,'linear','piecewise-linear interpretation');
    T = T.eq(C.extrapolation,'REJECT','no extrapolation');
    T = T.eq(G.Qlim_P_MW,360,'physical compatibility limits apply at primary capacity');
    T = T.eq(G.Qlim_Source_status,'PRIMARY_SOURCE_EXTRACTED','physical limit source status separate');
end
T = T.chk(exist('generatorCapability','file') == 2,'generatorCapability function exists');
if exist('generatorCapability','file') == 2
    [lo,hi] = generatorCapability([0 100 200 300 389.3 458]);
    T = T.eq(lo,[-231 -231 -220 -205 -182 0],'all lower endpoints including zero-Q tip');
    T = T.eq(hi,[335 329 311 280 241 0],'all upper endpoints including zero-Q tip');
    [lo,hi] = generatorCapability([50 150 250 344.65 423.65]);
    T = T.near(lo,[-231 -225.5 -212.5 -193.5 -91],1e-10,'lower midpoint on every segment');
    T = T.near(hi,[332 320 295.5 260.5 120.5],1e-10,'upper midpoint on every segment');
    [lo,hi] = generatorCapability(360);
    T = T.near(lo,-205+60*23/89.3,1e-12,'360 MW lower independent formula');
    T = T.near(hi,280-60*39/89.3,1e-12,'360 MW upper independent formula');
    [lo,hi] = generatorCapability([0;100;458]);
    T = T.eq(size(lo),[3 1],'column lower shape preserved');
    T = T.eq(size(hi),[3 1],'column upper shape preserved');
    [lo,hi] = generatorCapability([0 100;200 458]);
    T = T.eq(lo,[-231 -231;-220 0],'matrix lower shape and values');
    T = T.eq(hi,[335 329;311 0],'matrix upper shape and values');
    custom = struct('P_MW',[0 458],'Qmin_MVAr',[-10 0],'Qmax_MVAr',[20 0]);
    [lo,hi] = generatorCapability(229,custom);
    T = T.near([lo hi],[-5 10],1e-12,'explicit curve honored without provider recursion');
    bad = {-eps,458+eps(458),NaN,Inf,-Inf,1+1i,[100 NaN],[], '100',true};
    for k=1:numel(bad)
        T = T.chk(throws_id(@() generatorCapability(bad{k}), ...
            'generatorCapability:InvalidP'),sprintf('invalid P input %d rejected',k));
    end
    badCurves = {struct(),struct('P_MW',[0 0 458],'Qmin_MVAr',[-1 -1 0],'Qmax_MVAr',[1 1 0]), ...
        struct('P_MW',[0 458],'Qmin_MVAr',[-1 0],'Qmax_MVAr',[1 NaN]), ...
        struct('P_MW',[0 458],'Qmin_MVAr',[2 0],'Qmax_MVAr',[1 0]), ...
        struct('P_MW',[0 458],'Qmin_MVAr',[-1 0 0],'Qmax_MVAr',[1 0]), ...
        struct('P_MW',[0 400],'Qmin_MVAr',[-1 0],'Qmax_MVAr',[1 0])};
    for k=1:numel(badCurves)
        T = T.chk(throws_id(@() generatorCapability(200,badCurves{k}), ...
            'generatorCapability:InvalidCurve'),sprintf('malformed curve %d rejected',k));
    end
end
T = T.chk(exist('phase2_parameter','file') == 2,'normalized parameter helper exists');
if exist('phase2_parameter','file') == 2
    r = phase2_parameter(122,'V','source','section','VERIFIED_ENGINEERING_DOCUMENT','High','No-load only');
    required = {'value','unit','source','source_locator','status','confidence','rationale', ...
        'assumption_basis','reasonable_range','assumed_range','selected_value', ...
        'source_status','derivation','interpretation_status'};
    T = T.chk(all(isfield(r,required)),'lowercase parameter schema complete');
    T = T.eq(r.value,122,'source value retained');
    T = T.eq(r.source_status,'VERIFIED_ENGINEERING_DOCUMENT','source classification defaults honestly');
    T = T.eq(r.assumption_basis,'NOT_APPLICABLE','source record not presented as assumption');
    T = T.eq(r.selected_value,122,'selected value explicit');
    a = phase2_parameter(200,'pu/pu','Academic assumption','AVR','ENGINEERING_ASSUMPTION','Assumed','Illustration', ...
        'assumption_basis','Generic academic AVR','reasonable_range',[50 400],'assumed_range',[100 300]);
    T = T.eq(a.assumed_range,[100 300],'assumed range retained');
    T = T.eq(a.source_status,'ENGINEERING_ASSUMPTION','assumption never promoted');
    T = T.chk(throws_id(@() phase2_parameter(200,'pu','a','b','ENGINEERING_ASSUMPTION','c','d'), ...
        'phase2_parameter:InvalidAssumption'),'assumptions require basis and finite ranges');
    T = T.chk(throws_id(@() phase2_parameter(500,'pu','a','b','ENGINEERING_ASSUMPTION','c','d', ...
        'assumption_basis','test','reasonable_range',[0 400],'assumed_range',[0 300]), ...
        'phase2_parameter:InvalidAssumption'),'out-of-range assumption rejected');
    r = phase2_parameter(NaN,'UNRESOLVED','source','blank','MISSING','Missing','No evidence');
    T = T.isnan(r.value,'missing source is not a finite assumed parameter');
end
T = T.chk(exist('phase2_source_data','file') == 2,'normalized source view exists');
if exist('phase2_source_data','file') == 2
    S = phase2_source_data(G);
    T = T.chk(isequaln(S,phase2_source_data()),'default and injected provider yield same source view');
    names = fieldnames(G.Provenance);
    for k=1:numel(names)
        n = names{k}; r = S.generator.(n); old = G.Provenance.(n);
        T = T.chk(isequaln(r.value,old.Normalized_value),[n ' normalized value follows original provenance']);
        T = T.eq(r.source_status,old.Source_status,[n ' original source status retained']);
        T = T.chk(isequaln(r.raw_provenance,old),[n ' full original provenance retained']);
    end
    T = T.eq(S.generator.Rf_numeric.unit,'UNRESOLVED','field-resistance unit not invented');
    T = T.eq(S.generator.Rf_numeric.interpretation_status,'QUALIFIED','unit qualification separate');
    T = T.eq(S.generator.Xdpp.value,0.2608,'unqualified reactance not replaced by saturated');
    T = T.eq(S.generator.Xdpp_sat.value,0.2248,'saturated reactance separate');
    T = T.eq(S.excitation.type.value,'Static','workbook excitation type');
    T = T.eq(S.excitation.designation.value,'SEMIPOL','workbook excitation designation');
    T = T.eq(S.excitation.no_load_voltage_V.value,122,'source no-load excitation voltage');
    T = T.eq(S.sfc.dc_link_kV.value,2.28,'SFC DC link not field voltage');
    T = T.eq(S.sfc.max_starting_output_A.value,1876,'SFC output current not DC-link current');
    T = T.eq(S.sfc.max_starting_output_A.side,'OUTPUT','output side explicit');
    T = T.eq(S.sfc.dc_link_kV.side,'DC_LINK','DC link side explicit');
    T = T.near(S.ner.primary_kV.value,22/sqrt(3),1e-12,'NER phase voltage');
    T = T.eq(S.ner.secondary_V.value,500,'NER secondary voltage');
    T = T.eq(S.ner.rating_kVA.value,135,'NER short-time rating');
    T = T.eq(S.ner.duration_s.value,20,'NER rating duration');
    T = T.eq(S.ner.hv_dc_resistance_ohm.value,60,'approximate HV DC resistance');
    T = T.eq(S.ner.loading_resistance_ohm.value,2.62,'approximate secondary loading resistor');
    T = T.eq(S.ner.hv_dc_resistance_ohm.interpretation_status,'QUALIFIED','source question mark not erased');
    T = T.eq(S.ner.loading_resistance_ohm.interpretation_status,'QUALIFIED','secondary uncertainty retained');
    T = T.eq(S.grid.estimate_Isc_kA.value,50,'frozen grid estimate context');
    T = T.eq(S.grid.estimate_Ssc_GVA.value,19.919,'source rounded 19.919 GVA retained');
    T = T.eq(S.grid.estimate_Ssc_GVA.status,'ESTIMATED','grid estimate not promoted to verified');
    T = T.eq(S.grid.sensitivity_Isc_kA.value,45.01,'secondary sensitivity current separate');
    T = T.eq(S.grid.sensitivity_XR.value,10.99,'secondary sensitivity X/R separate');
    T = T.eq(S.grid.sensitivity_XR.status,'SECONDARY_SOURCE_CONTEXT','secondary source not selected grid');
    T = T.eq(S.cooling.gsut_total_kW.value,1282,'source total loss');
    T = T.eq(S.cooling.gsut_no_load_kW.value,159,'source no-load loss');
    T = T.eq(S.cooling.gsut_load_kW.value,1095,'source full-load loss');
    T = T.eq(S.cooling.gsut_cooling_kW.value,28,'cooling closure 1282-159-1095');
    T = T.eq(S.cooling.gsut_cooling_kW.derivation,'1282 - 159 - 1095','cooling arithmetic explicit');
    T = T.eq(S.cooling.gsut_cooling_kW.source_status,'VERIFIED_ENGINEERING_DOCUMENT','derived cooling keeps input provenance');
    % I1: document verification does not resolve the marked design caveat.
    T = T.eq(S.cooling.gsut_total_kW.status,'VERIFIED_ENGINEERING_DOCUMENT','total source classification retained');
    T = T.eq(S.cooling.gsut_total_kW.source_status,'VERIFIED_ENGINEERING_DOCUMENT','total source status retained');
    T = T.eq(S.cooling.gsut_cooling_kW.status,'DERIVED_FROM_VERIFIED_DATA','cooling remains a derived record');
    marked = {'gsut_total_kW','gsut_cooling_kW'};
    for k=1:numel(marked)
        n = marked{k}; r = S.cooling.(n);
        T = T.eq(r.source,'GSUT Data Sheet_South.pdf',[n ' source document retained']);
        T = T.eq(r.interpretation_status,'QUALIFIED',[n ' provisional design interpretation']);
        T = T.chk(all(cellfun(@(token) contains(lower(r.confidence),token),{'qualified','design-finalization'})), ...
            [n ' confidence retains design-finalization caveat']);
        T = T.chk(all(cellfun(@(token) contains(r.source_locator,token),{'section 1.7','technical p.4','PDF p.6'})), ...
            [n ' marked loss table located']);
        T = T.chk(all(cellfun(@(token) contains(r.source_locator,token),{'*)','design-finalization','technical p.7','PDF p.9'})), ...
            [n ' asterisk footnote located']);
        T = T.chk(all(cellfun(@(token) contains(lower(r.rationale),token), ...
            {'marked *)','subject to change','detailed design','not finalized/as-built'})), ...
            [n ' rationale retains provisional source meaning']);
        T = T.chk(isempty(r.reasonable_range) && isempty(r.assumed_range), ...
            [n ' design caveat does not invent uncertainty ranges']);
    end
    T = T.eq(S.capabilityCurve,G.capabilityCurve,'source view uses authoritative curve');
    altered = G; altered.Provenance.Snom_MVA.Normalized_value = 459;
    view = phase2_source_data(altered);
    T = T.eq(view.generator.Snom_MVA.value,459,'injected provenance is normalized, not independently hard-coded');
end
[np,nf] = T.done();
end

function ok = throws_id(f,id)
ok = false;
try
    f();
catch ME
    ok = strcmp(ME.identifier,id);
end
end
