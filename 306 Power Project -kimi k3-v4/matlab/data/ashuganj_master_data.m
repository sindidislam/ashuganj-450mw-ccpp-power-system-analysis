function D = ashuganj_master_data()
%ASHUGANJ_MASTER_DATA Master data entry point for Phase 2.
D.meta.Project='Ashuganj South 450 MW CCPP'; D.meta.Owner='APSCL'; D.meta.Project_no='112070';
D.meta.Study='Balanced steady state load flow provisional'; D.meta.Dataset_date='2026-08-31';
D.meta.Toolchain='MATLAB R2024a Simscape Electrical'; D.meta.LF_engine='power_loadflow'; D.meta.Course='BUET EEE 306 Group 03';
D.meta.Source_sync='Rev 03 engineering source re-audit'; D.meta.Out_of_scope={'short-circuit','protection coordination'};
D.base.Sbase_MVA=100; D.base.Sbase_Status='ENGINEERING_ASSUMPTION'; D.base.Sbase_Note='Reporting base';
D.base.f_Hz=50; D.base.f_Status='VERIFIED_PLANT'; D.base.f_Note='South documents confirm 50 Hz';
D.buses=ashuganj_buses(); D.gen=ashuganj_generators(); D.tx=ashuganj_transformers();
D.lines=ashuganj_lines(); D.loads=ashuganj_loads(); D.grid=ashuganj_grid();
D.assumptions.grid_series_resistance_zero=grid_series_resistance_zero();
D.assumptions.aux_load_allocation_split=aux_load_allocation_split();
D.assumptions.gis_bus_coupler_closed=gis_bus_coupler_closed();
D.superseded.transformer_magnetising_inductance=transformer_magnetising_inductance();
D.structural={'S1','Physical GAT three winding; load flow two winding equivalent';'S2','Rev 03 MV ratings corrected'};

% Attach Phase-2 isolated component systems
S_sys = ashuganj_phase2_systems(D.gen, engineering_assumptions());
D.excitation = S_sys.excitation;
D.sfc = S_sys.sfc;
D.stationDC = S_sys.stationDC;
D.governor = S_sys.governor;
D.pss = S_sys.pss;
D.dynamicReadiness = S_sys.dynamicReadiness;

% Attach Phase-2 operating profiles (6 canonical + 4 historical aliases)
P = ashuganj_operating_profiles(D);
D.operating_profiles = P.canonical;
D.primary_cases = P.primary;
D.qualified_cases = P.qualified;
D.historical_cases = P.historical;
D.cases = P.aliases;
D.builder_cases = P.builder_cases;
D.case_matrix_note = 'Four historical regression cases in .cases; six canonical profiles in .operating_profiles';

D.status_vocabulary={'VERIFIED_PLANT','VERIFIED_ENGINEERING_DOCUMENT','VERIFIED_PROJECT_DATA', ...
    'DERIVED_FROM_VERIFIED_DATA','PRIMARY_VERIFIED','PRIMARY_SOURCE_QUALIFIED', ...
    'ENGINEERING_ASSUMPTION','HISTORICAL','LEGACY','ESTIMATED','MISSING','NOT_APPLICABLE','AVAILABLE_NOT_DIGITIZED'};
D.weakest_link='External grid data';
assert(numel(D.operating_profiles)==6);
assert(numel(D.cases)==4);
end
