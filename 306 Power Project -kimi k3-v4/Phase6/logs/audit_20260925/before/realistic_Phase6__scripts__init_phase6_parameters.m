function P = init_phase6_parameters()
%INIT_PHASE6_PARAMETERS Read-only Phase 6 data assembly and model defaults.
% Raw canonical records are preserved. PHASE5_STUDY selection belongs to the
% caller; merely reading its reference table never changes the baseline.
paths = setup_phase6_workspace();
P = struct('f_Hz',50,'Sbase_VA',100e6,'TsElectrical',50e-6, ...
    'TsControl',.001,'numericalShunt_W',10);
P.generator = ashuganj_generators();
P.transformers = ashuganj_transformers();
P.lines = ashuganj_lines();
P.grid = ashuganj_grid();
P.loads = ashuganj_loads();
P.assumptions = engineering_assumptions();
P.systems = ashuganj_phase2_systems(P.generator,P.assumptions);
P.reference.summary = readref('phase3_system_summary.csv');
P.reference.buses = readref('phase3_bus_results.csv');
primary = strcmp(string(P.reference.summary.Case_ID),'LF360_GAT_OUT');
assert(nnz(primary)==1,'Phase6:PrimaryCase', ...
    'Frozen summary must contain exactly one LF360_GAT_OUT row.');
P.reference.primary = P.reference.summary(primary,:);
P.protection.settings = readref('phase5_relay_settings.csv');
P.protection.devices = readref('phase5_device_registry.csv');
P.protection.trips = readref('phase5_trip_logic.csv');
P.protection.faults = readref('phase5_fault_inputs.csv');
P.protection.currents = readref('phase5_relay_currents.csv');
P.protection.parameters = readref('phase5_parameter_values.csv');
P.scenario = struct('name','normal','networkProfile','PHASE3_BASELINE', ...
    'faultEnabled',false,'faultType','3PH','faultLocation','GIS230', ...
    'faultStart_s',1,'faultDuration_s',.15,'stopTime_s',2, ...
    'faultResistance_ohm',.01,'groundResistance_ohm',.01, ...
    'protectionEnabled',true,'batteryAvailable',true,'chargerAvailable',true, ...
    'dcLossTime_s',Inf,'dcRestoreTime_s',Inf,'GAT_in',false);
G = P.generator;
P.machine = struct('Sn_VA',G.Snom_MVA*1e6,'Vn_V',G.Vnom_V, ...
    'Rs_pu',G.Ra_ohm/(G.Vnom_kV^2/G.Snom_MVA), ...
    'reactances_pu',[G.Xd G.Xdp G.Xdpp G.Xq G.Xqp G.Xqpp G.Xl], ...
    'timeConstants_s',[G.Td0p_s G.Td0pp_s G.Tq0p_s G.Tq0pp_s], ...
    'H_s',G.H_s,'damping_pu',0,'polePairs',1, ...
    'P_W',P.reference.primary.Gen_P_MW*1e6, ...
    'Vref_pu',P.assumptions.exc_voltage_reference_pu.value);

% Values are serialized text so scalar, vector, categorical and unresolved
% source entries survive CSV export without conversion to invented numbers.
rows = cell(0,6);
put('f_Hz',P.f_Hz,'Hz','VERIFIED_SOURCE',G.f_Source,'Plant frequency.');
put('Sbase_VA',P.Sbase_VA,'VA','ENGINEERING_ASSUMPTION', ...
    'matlab/phase4/phase4_registry.m','Reporting base; machine retains its own 458 MVA base.');
put('TsElectrical',P.TsElectrical,'s','ENGINEERING_ASSUMPTION','Phase 6 scenario design', ...
    'Discrete electrical step; numerical convergence must be checked for reported transients.');
put('TsControl',P.TsControl,'s','ENGINEERING_ASSUMPTION','Phase 6 scenario design', ...
    'Control/protection execution interval, not installed relay sampling.');
put('numericalShunt_W',P.numericalShunt_W,'W','ENGINEERING_ASSUMPTION','Phase 6 scenario design', ...
    'Small numerical shunt at nominal voltage; not an installed plant load.');

keys = fieldnames(G.Provenance);
for k=1:numel(keys)
    n=keys{k}; r=G.Provenance.(n);
    cl=classify(r.Source_status);
    note=[r.Interpretation_note ' Original status: ' r.Source_status ...
        '; base: ' r.Base '; saturation: ' r.Saturation_condition '.'];
    if strcmp(n,'Rf_numeric')
        cl='PLACEHOLDER_NOT_FOR_FINAL_RESULT';
        note=[note ' UNRESOLVED unit and field base; raw numeric retained, unused by the machine.'];
    end
    put(['generator.' n],r.Normalized_value,r.Normalized_unit,cl, ...
        [r.Source_document ' | ' r.Source_sheet ' | ' r.Source_cell ' | ' r.Source_locator],note);
end
machineRows = {
    'Sn_VA','VA','DERIVED_FROM_VERIFIED_SOURCE','C3','458 MVA converted to VA; qualified machine base.';
    'Vn_V','V','DERIVED_FROM_VERIFIED_SOURCE','D3','Line-to-line RMS nominal voltage converted from kV.';
    'Rs_pu','pu','DERIVED_FROM_VERIFIED_SOURCE','U3,C3,D3','0.00089 ohm / (22^2/458); temperature unspecified; one stator-base conversion.';
    'reactances_pu','pu','VERIFIED_SOURCE','H3,I3,J3,L3,M3,N3,O3','Order Xd Xdp Xdpp Xq Xqp Xqpp Xl; raw unqualified Xdpp 0.2608 retained as unsaturated study interpretation. Saturated 0.2248 remains separate; source is project workbook, not an OEM validated model.';
    'timeConstants_s','s','VERIFIED_SOURCE','Y3,Z3,AA3,AB3','Open-circuit order Td0p Td0pp Tq0p Tq0pp; use round rotor and open-circuit block options.';
    'H_s','s','VERIFIED_SOURCE','F3','Combined turbine-generator inertia on selected 458 MVA train base.';
    'damping_pu','pu','ENGINEERING_ASSUMPTION','Phase 6 machine design','Zero academic viscous damping; no measured damping coefficient available.';
    'polePairs','count','DERIVED_FROM_VERIFIED_SOURCE','Generator Data_South.pdf / SCC5-PAC 4000F/3000','50 Hz and 3000 rpm imply 60*f/n = 1 pole pair (two poles).';
    'P_W','W','DERIVED_FROM_VERIFIED_SOURCE','phase3_system_summary.csv LF360_GAT_OUT','Frozen primary 360 MW dispatch, converted to W; no upstream load flow rerun.';
    'Vref_pu','pu','ENGINEERING_ASSUMPTION','engineering_assumptions.exc_voltage_reference_pu','Canonical academic voltage reference; not a commissioned AVR setting.'};
for k=1:size(machineRows,1)
    n=machineRows{k,1};
    put(['machine.' n],P.machine.(n),machineRows{k,2},machineRows{k,3}, ...
        ['Canonical machine mapping | ' machineRows{k,4}],machineRows{k,5});
end
keys=fieldnames(P.assumptions);
for k=1:numel(keys)
    r=P.assumptions.(keys{k});
    put(['assumptions.' keys{k}],r.value,r.unit,'ENGINEERING_ASSUMPTION', ...
        [r.source ' | ' r.source_locator], ...
        [r.rationale ' Reasonable range=' serial(r.reasonable_range) ...
        '; assumed range=' serial(r.assumed_range) '.']);
end
registry('transformers',P.transformers,'matlab/data/ashuganj_transformers.m');
registry('lines',P.lines,'matlab/data/ashuganj_lines.m');
registry('grid',P.grid,'matlab/data/ashuganj_grid.m');
registry('loads',P.loads,'matlab/data/ashuganj_loads.m');
put('network.baselineProfile','PHASE3_BASELINE','profile','ENGINEERING_ASSUMPTION', ...
    'PHASE3_FINAL_REPORT.md; Phase6/docs/PARAMETER_TASK_BRIEF.md', ...
    'Canonical positive-sequence baseline preserved. Grid R=0 is balanced-LF-only; no finite X/R or DC-offset validation is implied. Missing canonical zero sequence remains missing.');
put('network.phase5Profile','PHASE5_STUDY','profile','ENGINEERING_ASSUMPTION', ...
    'PHASE5_AI_HANDOFF.md; phase5_parameter_values.csv', ...
    'Optional revised screening profile, applied only on explicit caller selection. Reference table does not replace canonical grid or line values; frozen fault CSV still retains Phase 4 backbone.');
T=P.protection.parameters;
for k=1:height(T)
    st=char(string(T.status(k)));
    cl=classify(st);
    if strcmp(st,'DERIVED')
        % Several derived Phase 5 values inherit assumed inputs. Keep their
        % confidence conservative; exact original status/derivation is kept.
        cl='ENGINEERING_ASSUMPTION';
    elseif strcmp(st,'MANUFACTURER_DEFAULT_STUDY_VALUE')
        cl='USER_ASSERTED';
    end
    put(['phase5.' char(string(T.parameter(k)))],T.value(k),char(string(T.unit(k))),cl, ...
        [char(string(T.source_file(k))) ' | ' char(string(T.source_section(k)))], ...
        ['Original status: ' st '. ' char(string(T.basis(k))) ...
        ' Derivation: ' char(string(T.derivation(k))) ...
        ' Verification: ' char(string(T.verification_required(k))) ...
        ' Installed value verified: ' char(string(T.actual_installed_value_verified(k))) '.']);
end
S=P.protection.settings;
for k=1:height(S)
    for fn={'setting_A_primary','setting_A_secondary','ct_ratio','tms','tdef_s','operate_proxy_s'}
        n=fn{1}; v=S.(n)(k,:);
        put(['protection.' char(string(S.device_id(k))) '.' n],v,'as frozen', ...
            'ENGINEERING_ASSUMPTION',[char(string(S.source(k))) ' | phase5_relay_settings.csv'], ...
            [char(string(S.provenance(k))) ' ' char(string(S.validation(k))) ...
            ' Individual source CT classifications are preserved in phase5.* rows.']);
    end
end
keys=fieldnames(P.scenario);
for k=1:numel(keys)
    n=keys{k};
    note='Default academic simulation scenario control; not an installed plant setting.';
    if any(strcmp(n,{'faultResistance_ohm','groundResistance_ohm'}))
        note='Finite low-resistance fault switch parameter; engineering numerical assumption, distinct from unresolved generator field Rf and from the neutral resistor.';
    elseif any(strcmp(n,{'dcLossTime_s','dcRestoreTime_s'}))
        note='Inf means no scheduled DC event in the normal scenario; not a physical time constant.';
    elseif strcmp(n,'networkProfile')
        note='Default retains Phase 3 baseline; root scenario runner may explicitly select PHASE5_STUDY.';
    end
    put(['scenario.' n],P.scenario.(n),unitof(n),'ENGINEERING_ASSUMPTION', ...
        'Phase6/docs/PARAMETER_TASK_BRIEF.md; Phase 6 scenario design',note);
end
P.register=cell2table(rows,'VariableNames', ...
    {'Parameter','Value','Unit','Classification','Source','Notes'});

    function T=readref(name)
        T=readtable(fullfile(paths.reference,name),'VariableNamingRule','preserve');
    end
    function put(n,v,u,c,s,note)
        rows(end+1,:)={n,serial(v),u,c,s,note};
    end
    function registry(prefix,objects,source)
        for ii=1:numel(objects)
            obj=objects(ii); fields=fieldnames(obj);
            if numel(objects)>1, base=[prefix '.' obj.Name]; else, base=prefix; end
            for jj=1:numel(fields)
                n=fields{jj}; v=obj.(n);
                categorical=any(strcmp(n,{'Name','Conn_HV','Conn_LV','VectorGroup', ...
                    'Model_coretype','Model_saturation','Model_representation','Bus_from','Bus_to'}));
                if ~(isnumeric(v)||islogical(v)||categorical), continue; end
                cl='ENGINEERING_ASSUMPTION';
                note='Canonical value retained unchanged; source file contains full provenance and qualifications.';
                rootname=regexprep(n,'_(ohm|MVA|kV|V|A|Hz|H|F|pu|pct|MW|MVAr|kW)$','');
                for candidate={[n '_Status'],[rootname '_Status']}
                    if isfield(obj,candidate{1}) && ~isempty(obj.(candidate{1}))
                        cl=classify(obj.(candidate{1}));
                        note=[note ' Original status: ' obj.(candidate{1}) '.'];
                        break;
                    end
                end
                if isnumeric(v)&&any(isnan(v(:)))
                    cl='PLACEHOLDER_NOT_FOR_FINAL_RESULT';
                    note=[note ' Missing source value remains NaN; not silently filled or usable for final results.'];
                end
                if strcmp(prefix,'grid') && any(strcmp(n,{'Isc_kA','Ssc_MVA','Z_ohm','X_ohm','L_H'}))
                    cl='ENGINEERING_ASSUMPTION';
                    note=[note ' Inherits estimated 50 kA source confidence; not verified PGCB fault data.'];
                end
                if any(strcmp(n,{'Model_coretype','Model_saturation','R1_pu','R2_pu','L1_pu','L2_pu'}))
                    note=[note ' Core/saturation and equal winding allocation are representation choices; do not imply measured winding or magnetic details.'];
                end
                put([base '.' n],v,unitof(n),cl,source,note);
            end
        end
    end
end

function s=serial(v)
if iscell(v), s=char(strjoin(string(v),'; '));
elseif isnumeric(v)||islogical(v), s=mat2str(v,17);
else, s=char(strjoin(string(v),'; ')); end
end

function cl=classify(status)
s=upper(char(string(status)));
if contains(s,'MISSING')||contains(s,'UNRESOLVED')
    cl='PLACEHOLDER_NOT_FOR_FINAL_RESULT';
elseif contains(s,'DERIVED_FROM_VERIFIED')
    cl='DERIVED_FROM_VERIFIED_SOURCE';
elseif startsWith(s,'VERIFIED')||strcmp(s,'PRIMARY_VERIFIED')
    cl='VERIFIED_SOURCE';
elseif strcmp(s,'USER_ASSERTED')||strcmp(s,'MANUFACTURER_DEFAULT_STUDY_VALUE')
    cl='USER_ASSERTED';
else
    cl='ENGINEERING_ASSUMPTION';
end
end

function u=unitof(n)
if endsWith(n,'_s')||startsWith(n,'Ts'), u='s';
elseif endsWith(n,'_ohm'), u='ohm';
elseif endsWith(n,'_MVAr'), u='MVAr';
elseif endsWith(n,'_MW'), u='MW';
elseif endsWith(n,'_kW'), u='kW';
elseif endsWith(n,'_MVA'), u='MVA';
elseif endsWith(n,'_kV'), u='kV';
elseif endsWith(n,'_V'), u='V';
elseif endsWith(n,'_A'), u='A';
elseif endsWith(n,'_Hz'), u='Hz';
elseif endsWith(n,'_H'), u='H';
elseif endsWith(n,'_F'), u='F';
elseif endsWith(n,'_pu'), u='pu';
elseif endsWith(n,'_pct'), u='%';
elseif endsWith(n,'_km'), u='km';
else, u='as documented'; end
end
