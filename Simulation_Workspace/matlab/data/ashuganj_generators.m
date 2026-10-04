function G = ashuganj_generators()
%ASHUGANJ_GENERATORS Generator registry for Ashuganj South.
G.Name='G1'; G.Label='G1 SGen5-2000H'; G.KKS='10MKA10'; G.Bus='B22';
G.Manufacturer='Siemens'; G.Model='SGen5-2000H'; G.Train='SCC5-PAC 4000F/3000 1S single shaft'; G.Train_Status='VERIFIED_ENGINEERING_DOCUMENT';
%% REV3.1 workbook-primary registry. Legacy retained; LF physics unchanged.
[P, provenance] = primary_workbook();
G.Primary=P; G.Provenance=provenance; G.Dataset_ID='GEN-R31-WORKBOOK-ROW3'; G.Designation='PRIMARY';
names=fieldnames(P); for k=1:numel(names), G.(names{k})=P.(names{k}); end
G.Vnom_V=G.Vnom_kV*1000; G.Vnom_Status='VERIFIED_PROJECT_DATA'; G.Vnom_Source='Ahsuganj South (2).xlsx D3';
G.Snom_Status='VERIFIED_PROJECT_DATA'; G.Snom_Source='Ahsuganj South (2).xlsx C3';
G.Smax_MVA=518; G.Smax_Status='VERIFIED_ENGINEERING_DOCUMENT'; G.Smax_Source='Generator protection report'; G.Smax_Note='Maximum at 30 C cold gas';
G.pf=0.85; G.pf_Status='VERIFIED_PLANT'; G.pf_Source='Generator nameplate';
G.Inom_A=12019; G.Inom_Status='VERIFIED_PLANT'; G.Inom_Source='Generator nameplate';
G.f_Hz=50; G.f_Status='VERIFIED_PLANT'; G.f_Source='Generator nameplate';
G.Winding='YY'; G.Winding_Status='VERIFIED_PLANT'; G.Earthing='High resistance through NER 10BAB11'; G.Earthing_Status='VERIFIED_PLANT'; G.H2_pressure_barg=5; G.H2_Status='VERIFIED_PLANT';
G.PF_rated=G.pf; G.P_pf_reference_MW=G.Snom_MVA*G.PF_rated;
G.P_capacity_MW=360.00; G.P_capacity=360.00; G.P_capacity_Status='PRIMARY_VERIFIED'; G.P_capacity_Source='Verified Project Active Power Capacity (360 MW)';
G.P_owner_derated_MW=342.01; G.P_owner_derated_Boundary_status='QUALIFIED';
G.P_owner_derated_Note='Owner Site De-rated Active Power (P_net); exact boundary unresolved, not established net export or generator-terminal power.';
G.Machine_base=struct('S_MVA',G.Snom_MVA,'V_kV',G.Vnom_kV,'Status','QUALIFIED','Note','Base interpreted from row rating; no separate literal base declaration.');
G.Reactance_base='Own rating 458 MVA 22 kV (selected interpretation)'; G.Reactance_base_Status='QUALIFIED';
names={'Xd','Xdp','Xdpp','Xdpp_sat','Xq','Xqp','Xqpp','Xl','X2','X0'};
for k=1:numel(names), n=names{k}; G.([lower(n) '_pct'])=100*G.(n); G.([lower(n) '_Status'])='VERIFIED_PROJECT_DATA'; end
G.System_base=struct('S_MVA',100,'V_kV',G.Vnom_kV,'Status','ENGINEERING_ASSUMPTION');
G.Zbase_machine_ohm=G.Vnom_kV^2/G.Snom_MVA; G.Zbase_100MVA_ohm=G.Vnom_kV^2/G.System_base.S_MVA;
G.Ra_pu_machine=G.Ra_ohm/G.Zbase_machine_ohm; G.Ra_pu_100MVA=G.Ra_ohm/G.Zbase_100MVA_ohm;
G.Xdpp_100MVA=G.Xdpp*G.System_base.S_MVA/G.Snom_MVA; G.Xdpp_sat_100MVA=G.Xdpp_sat*G.System_base.S_MVA/G.Snom_MVA;
G.Ra_pu=G.Ra_pu_machine; G.Ra_Status='DERIVED_FROM_VERIFIED_DATA';
G.H_MWs_per_MVA=G.H_s; G.H_Status='VERIFIED_PROJECT_DATA'; G.Td0p_Status='VERIFIED_PROJECT_DATA';
G.Rf_Interpretation_status='QUALIFIED'; G.Rf_Field_base='UNRESOLVED';
G.Controller_parameters_Status='MISSING'; G.OCC_Status='MISSING';
G.Missing=struct('XD_damper',NaN,'XQ_damper',NaN,'Xf',NaN,'RD_damper',NaN,'RQ_damper',NaN,'Ta1_s',NaN,'Damping',NaN);
G.Missing_Source_cells=struct('XD_damper','R3','XQ_damper','S3','Xf','T3','RD_damper','W3','RQ_damper','X3','Ta1_s','AH3','Damping','NOT_SUPPLIED');
G.Legacy=struct('Dataset_ID','GEN-LEGACY-SIEMENS-SATURATED','Designation','LEGACY / SATURATED SOURCE DATA','Selected_primary',false,'Xd',1.663,'Xdp',0.2865,'Xdpp',0.2248);
G.Legacy.Source_document='Generator Data_South.pdf'; G.Legacy.Source_locator='PDF p.1 / report p.6 section 2.1.1'; G.Legacy.Saturation_condition='SATURATED';
for n={'Xd','Xdp','Xdpp'}, r=record(G.Legacy.Source_document,G.Legacy.Source_locator,G.Legacy.(n{1}),'pu',G.Legacy.Dataset_ID); r.Raw_value=100*G.Legacy.(n{1}); r.Raw_unit='%'; r.Base=G.Reactance_base; r.Designation=G.Legacy.Designation; r.Saturation_condition='SATURATED'; r.Interpretation_note='Explicit (sat.) source label; traceability only, not primary.'; G.Legacy.Provenance.(n{1})=r; end
G.LF_BusType='PV'; G.Vset_pu=1.00; G.Vset_Status='ENGINEERING_ASSUMPTION'; G.Vset_Note='AVR setpoint not documented';
% Physical capability only: frozen PV builder solver settings stay unbounded
% by explicit user approval. They are neither physical Q nor grounding data.
G.capabilityCurve=struct('P_MW',[0 100 200 300 389.3 458], ...
    'Qmax_MVAr',[335 329 311 280 241 0], 'Qmin_MVAr',[-231 -231 -220 -205 -182 0], ...
    'status','PRIMARY_SOURCE_EXTRACTED', 'source_status','PRIMARY_SOURCE_EXTRACTED', ...
    'source','Siemens Generator Protection Setting Report', 'source_locator','Attachment 1', ...
    'extraction_method','MANUAL_GRAPH_EXTRACTION', 'extracted_by','USER', ...
    'confirmation_date','2026-09-15', 'attachment_locally_inspected',false, ...
    'confidence','User-confirmed graph extraction; graphical uncertainty not quantified', ...
    'rationale','Six user-supplied graph readings, not directly tabulated manufacturer values; original attachment not locally inspected.', ...
    'P_unit','MW', 'Q_unit','MVAr', 'interpolation','linear', 'extrapolation','REJECT', ...
    'interpretation_status','QUALIFIED', ...
    'applicability','Source envelope through 458 MW is not dispatch authorization; primary active capacity remains 360 MW.');
[G.Qmin_MVAr,G.Qmax_MVAr]=generatorCapability(G.P_capacity_MW,G.capabilityCurve);
G.Qlim_P_MW=G.P_capacity_MW;
G.Qlim_Status='DERIVED_FROM_PRIMARY_SOURCE_EXTRACTED'; G.Qlim_Source_status=G.capabilityCurve.status;
G.Qlim_Note='Physical compatibility bounds at Qlim_P_MW only; interpolate at actual dispatch. Frozen unconstrained solver is an approved exception, not physical capability.';
G.Qcurve_Status=G.capabilityCurve.status; G.Qcurve_Source='Siemens Generator Protection Setting Report Attachment 1';
G.Qcurve_Note='User-supplied manual graph extraction; attachment not locally inspected. Old PSAF scalar limits remain invalid.';
G.Uexc0_V=122; G.Uexc0_Status='VERIFIED_ENGINEERING_DOCUMENT'; G.Uexc0_Source='Generator Data South page 6';
G.SFC_DC_link_kV=2.28; G.SFC_DC_link_Status='VERIFIED_ENGINEERING_DOCUMENT'; G.SFC_Imax_A=1876; G.SFC_Imax_Status='VERIFIED_ENGINEERING_DOCUMENT';
G.I2max_pct=7.64; G.I2max_Status='VERIFIED_ENGINEERING_DOCUMENT'; G.K_negative_seq_s=7.41; G.K_negative_seq_Status='VERIFIED_ENGINEERING_DOCUMENT';
G.Dispatch.Rated.P_MW=G.P_pf_reference_MW; G.Dispatch.Rated.Status='DERIVED_FROM_VERIFIED_DATA'; G.Dispatch.Rated.Source='458 MVA times 0.85'; G.Dispatch.Rated.Label='Legacy PF reference, not capacity'; G.Dispatch.Rated.Designation='LEGACY_CASE_REFERENCE';
G.Dispatch.Derated.P_MW=G.P_owner_derated_MW; G.Dispatch.Derated.Status='VERIFIED_PROJECT_DATA'; G.Dispatch.Derated.Source='Project data derated reference'; G.Dispatch.Derated.Label='Qualified owner/site scenario'; G.Dispatch.Derated.Boundary_status='QUALIFIED';
G.Dispatch_Note='Neither case is measured. LF1-LF4 frozen in Phase 1; capacity guard/case migration requires Phase 2 authorization.';
G.Model_block='sps_lib/Sources/Three-Phase Source'; G.Model_treatment='ideal'; G.Model_treatment_Note='Balanced load flow PV representation';
assert(abs(sqrt(3)*G.Vnom_V*G.Inom_A/1e6-G.Snom_MVA)/G.Snom_MVA < 0.005);
assert(abs(G.Snom_MVA*G.pf-G.Dispatch.Rated.P_MW) < 0.01);
G=additional_provenance(G);
end

function [P, records]=primary_workbook()
% Verified read-only workbook transcription. Raw numeric serialization retained.
rows={
'Snom_MVA',458,'C3','Total Rated MVA','458','MVA','MVA';
'P_capacity_MW',360,'B3',[' Capacity ' char(10) '(MW)'],'360','MW','MW';
'Vnom_kV',22,'D3',['Generating' char(10) ' kV'],'22','kV','kV';
'H_s',5.2869999999999999,'F3',['Inertia Constant, H' char(10) '(kW-sec/kVA)'],'5.2869999999999999','kW-sec/kVA','s';
'SCR',0.60099999999999998,'G3','Short circuit Ratio','0.60099999999999998','dimensionless','dimensionless';
'Xd',1.7829999999999999,'H3','Xd','1.7829999999999999','pu','pu';
'Xdp',0.3256,'I3','Xd''','0.3256','pu','pu';
'Xdpp',0.26079999999999998,'J3','Xd"','0.26079999999999998','pu','pu';
'Xdpp_sat',0.2248,'K3','Xd"(sat)','0.2248','pu','pu';
'Xq',1.7509999999999999,'L3','Xq','1.7509999999999999','pu','pu';
'Xqp',0.50870000000000004,'M3','Xq''','0.50870000000000004','pu','pu';
'Xqpp',0.25929999999999997,'N3','Xq"','0.25929999999999997','pu','pu';
'Xl',0.20269999999999999,'O3','Xl','0.20269999999999999','pu','pu';
'X2',0.22420000000000001,'P3','X2 (sat)','0.22420000000000001','pu','pu';
'X0',0.128,'Q3','X0 (sat)','0.128','pu','pu';
'Ra_ohm',0.00089,'U3','Ra','0.00089 ohm','ohm','ohm';
'Rf_numeric',0.10631,'V3','Rf','0.10631','pu or ohm (unresolved)','UNRESOLVED';
'Td0p_s',7.5469999999999997,'Y3','T''d0','7.5469999999999997','sec','s';
'Td0pp_s',4.4999999999999998E-2,'Z3','T''''d0','4.4999999999999998E-2','sec','s';
'Tq0p_s',0.83899999999999997,'AA3','T''q0','0.83899999999999997','sec','s';
'Tq0pp_s',7.0000000000000007E-2,'AB3','T''''q0','7.0000000000000007E-2','sec','s';
'Tdp_s',1.2130000000000001,'AC3','T''d','1.2130000000000001','sec','s';
'Tdpp_s',3.5000000000000003E-2,'AD3','T''''d','3.5000000000000003E-2','sec','s';
'Tqp_s',0.214,'AE3','T''q','0.214','sec','s';
'Tqpp_s',3.5000000000000003E-2,'AF3','T''''q','3.5000000000000003E-2','sec','s';
'Ta_s',0.70399999999999996,'AG3','Ta or Ta(3)','0.70399999999999996','sec','s';
'S10',8.6499999999999994E-2,'AI3','S(1.0)','8.6499999999999994E-2','dimensionless','dimensionless';
'S12',0.40799999999999997,'AJ3','S(1.2)','0.40799999999999997','dimensionless','dimensionless';
'Excitation_type','Static','AS3','excitation system type and parameter  ','Static ','text','text';
'Excitation_designation','SEMIPOL','AT3','excitation controllers type and their detailed description, structural scheme and settings','SEMIPOL ','text','text';
};
P=struct(); records=struct();
for k=1:size(rows,1)
    n=rows{k,1}; P.(n)=rows{k,2};
    r=record('Ahsuganj South (2).xlsx','row 3',P.(n),rows{k,7},'GEN-R31-WORKBOOK-ROW3');
    r.Source_sheet='Ashuganj South '; r.Source_cell=rows{k,3}; r.Raw_heading=rows{k,4};
    r.Raw_value=rows{k,5}; r.Raw_unit=rows{k,6}; r.Source_status='VERIFIED_PROJECT_DATA';
    r.Source_SHA256='6D4286B9D0B771CEE80FB305F3C0AE7B9D34CC1EA8A3B8F2F022BA0D07240A60';
    if startsWith(n,'X')
        r.Raw_group_heading='Reactance in pu'; r.Base='458 MVA / 22 kV machine (interpreted)';
        r.Interpretation_status='QUALIFIED'; r.Saturation_condition='UNQUALIFIED_IN_SOURCE';
        r.Interpretation_note='Machine base selected from C3/D3; unqualified reactance is not a literal unsaturated declaration.';
        if ismember(n,{'Xdpp_sat','X2','X0'}), r.Saturation_condition='SATURATED'; end
    elseif startsWith(n,'T')
        r.Raw_group_heading='Time Constants (sec)';
    elseif ismember(n,{'S10','S12'})
        r.Raw_group_heading='Saturation data'; r.Interpretation_note='Source coefficients only, not a full measured OCC.';
    elseif startsWith(n,'Excitation')
        r.Raw_group_heading='Excitation'; r.Interpretation_note='Type/designation only; not verified controller parameters or a validated controller model.';
    end
    if strcmp(n,'H_s')
        r.Raw_group_heading='Combined Inertia data of Generator and Turbine'; r.Base='458 MVA selected train base';
        r.Interpretation_note='H is combined turbine-generator inertia; kW-sec/kVA equals seconds.';
    elseif strcmp(n,'Ra_ohm')
        r.Raw_group_heading='Resistance in pu or ohm'; r.Interpretation_note='Cell explicitly states ohm; temperature/test conditions not supplied.';
    elseif strcmp(n,'Rf_numeric')
        r.Raw_group_heading='Resistance in pu or ohm'; r.Base='UNRESOLVED FIELD BASE'; r.Interpretation_status='QUALIFIED';
        r.Confidence='High numeric / qualified unit'; r.Interpretation_note='Numeric preserved; unit and field base unresolved. Never use stator-base conversion or identify a detailed rotor circuit.';
    elseif strcmp(n,'Ta_s')
        r.Interpretation_note='Ta or Ta(3) retained; Ta(1) is separately blank at AH3.';
    end
    records.(n)=r;
end
end

function r=record(doc,locator,value,unit,dataset)
r=struct('Source_document',doc,'Source_sheet','NOT_APPLICABLE','Source_cell','NOT_APPLICABLE', ...
    'Source_locator',locator,'Source_SHA256','NOT_RECORDED','Raw_value',value,'Raw_unit',unit, ...
    'Raw_heading',locator,'Raw_group_heading','','Normalized_value',value,'Normalized_unit',unit, ...
    'Base','NOT_APPLICABLE','Source_status','VERIFIED_ENGINEERING_DOCUMENT','Confidence','High', ...
    'Dataset_ID',dataset,'Designation','PRIMARY','Interpretation_status','DIRECT', ...
    'Interpretation_note','Verified source data; no physical model validation implied.', ...
    'Saturation_condition','NOT_APPLICABLE','Derivation','');
end

function G=additional_provenance(G)
r=record('Generator Name Plate_South.pdf','p.2',G.PF_rated,'dimensionless',G.Dataset_ID); r.Source_status='VERIFIED_PLANT'; r.Interpretation_note='Rated/reference PF, not operating PF control.'; G.Provenance.PF_rated=r;
r=record('Generator Data_South.pdf','PDF p.1 / report p.6 section 2.1.1',G.P_pf_reference_MW,'MW',G.Dataset_ID); r.Source_status='DERIVED_FROM_VERIFIED_DATA'; r.Derivation='Snom_MVA * PF_rated'; r.Interpretation_note='PF-derived/OEM reference, NOT primary active-power capacity.'; G.Provenance.P_pf_reference_MW=r;
r=record('Google Sheet Form_Filled Up By APSCL.pdf','Site De-rated Active Power / P_net',G.P_owner_derated_MW,'MW',G.Dataset_ID); r.Source_status='VERIFIED_PROJECT_DATA'; r.Interpretation_status='QUALIFIED'; r.Interpretation_note=G.P_owner_derated_Note; G.Provenance.P_owner_derated_MW=r;
r=record('Generator Data_South.pdf','PDF p.1 / report p.6 NER',G.Earthing,'text',G.Dataset_ID); r.Interpretation_note='High-resistance NER 10BAB11; workbook AQ3 Solid Ground belongs to GSUT, not generator.'; G.Provenance.Earthing=r;
spec={'Zbase_machine_ohm','C3,D3','ohm','Vnom_kV^2 / Snom_MVA','458 MVA / 22 kV';
'Zbase_100MVA_ohm','D3','ohm','Vnom_kV^2 / 100','100 MVA / 22 kV';
'Ra_pu_machine','U3,C3,D3','pu','Ra_ohm / Zbase_machine_ohm','458 MVA / 22 kV';
'Ra_pu_100MVA','U3,D3','pu','Ra_ohm / Zbase_100MVA_ohm','100 MVA / 22 kV';
'Xdpp_100MVA','J3,C3,D3','pu','Xdpp * 100 / Snom_MVA','100 MVA / 22 kV';
'Xdpp_sat_100MVA','K3,C3,D3','pu','Xdpp_sat * 100 / Snom_MVA','100 MVA / 22 kV'};
for k=1:size(spec,1)
    n=spec{k,1}; r=G.Provenance.Ra_ohm; r.Source_cell=spec{k,2};
    r.Raw_value='DERIVED: see source cells and equation'; r.Raw_unit='source units';
    r.Raw_heading='Derived view'; r.Raw_group_heading='';
    r.Normalized_value=G.(n); r.Normalized_unit=spec{k,3}; r.Base=spec{k,5};
    r.Source_status='DERIVED_FROM_VERIFIED_DATA'; r.Interpretation_status='QUALIFIED'; r.Derivation=spec{k,4};
    r.Interpretation_note='Single conversion from primary machine data; 100 MVA reporting base is an assumption.';
    G.Provenance.(n)=r;
end
G.Provenance.Xdpp_100MVA.Saturation_condition=G.Provenance.Xdpp.Saturation_condition;
G.Provenance.Xdpp_sat_100MVA.Saturation_condition=G.Provenance.Xdpp_sat.Saturation_condition;
end
