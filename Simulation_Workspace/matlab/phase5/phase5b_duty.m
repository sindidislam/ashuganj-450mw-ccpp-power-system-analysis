function D = phase5b_duty(Tthrough, ratings52G, B)
%PHASE5B_DUTY Conditional breaker screening on each breaker's physical base.
%   Existing first 12 output columns and the separate system-reference NOTE
%   are retained. The frozen phase5_duty engine is used only for that NOTE;
%   its fault-level-current convention is not a physical breaker duty.
%   Q0 is CONDITIONALLY mapped to the GSUT 230 kV transformer-bay breaker:
%   50 kA interrupting, 2000 A continuous, 125 kA making, 3 s withstand.
%   52G retains the documentary-verified 100 kA comparison on its 22 kV side.
%   Every duty uses maxABC of the actual branch, not a fault-point total.
%   B uses the frozen handoff's FAULT-location base for every branch; convert
%   by Vfault/Vbreaker before comparing ratings. Ikpp is an initial-current
%   screening quantity, not a calculated breaking-time Ib or making duty.
%   Optional B reuses the identity-gated phase5b_branch_phasors table.
if nargin < 1 || ~istable(Tthrough) || isempty(Tthrough)
    error('phase5b_duty:args','Tthrough must be a non-empty imported table.');
end
required = {'fault_location','fault_type','caseID','leg_GEN_kA'};
if ~all(ismember(required,Tthrough.Properties.VariableNames))
    error('phase5b_duty:schema','Tthrough requires fault_location, fault_type, caseID and leg_GEN_kA.');
end
if nargin < 2 || isempty(ratings52G)
    ratings52G = struct('breaker_ref','52G','rating_kA',100, ...
        'source','DOCUMENTARY_VERIFIED:GENERATION AND TRANSFORMERS SYSTEM.pdf p2; INEL-112070-00-ELC-DE-0023 Rev03 sheet1; GCB10BAC10 22kV 100kA sym rms');
end
[rating52,source52] = parse52(ratings52G);
if nargin < 3 || isempty(B)
    if exist('phase5b_cached_branches','file') == 2
        B = phase5b_cached_branches(Tthrough);
    else
        B = phase5b_branch_phasors(Tthrough);
    end
end
if ~istable(B) || ~all(ismember({'caseID','location','fault_type','leg','Ia_A','Ib_A','Ic_A'},B.Properties.VariableNames))
    error('phase5b_duty:schema','B must be a complete identity-gated branch table.');
end
legacy = phase5_duty(Tthrough,[]);
N = legacy(strcmp(legacy.verdict,'NOTE'),:);
if height(N)~=1, error('phase5b_duty:engine','Frozen engine must supply one NOTE row.'); end
n = height(Tthrough);
location = [cellstr(string(Tthrough.fault_location));cellstr(string(Tthrough.fault_location))];
breaker_ref = [repmat({'Q0'},n,1);repmat({'52G'},n,1)];
fault_type = [cellstr(string(Tthrough.fault_type));cellstr(string(Tthrough.fault_type))];
caseID = [cellstr(string(Tthrough.caseID));cellstr(string(Tthrough.caseID))];
I_sym_kA=zeros(2*n,1); I_peak_kA=NaN(2*n,1);
rating_kA=[50*ones(n,1);rating52*ones(n,1)];
basis=cell(2*n,1); verdict=cell(2*n,1); note=cell(2*n,1);
equipment_rating_kA=[50*ones(n,1);NaN(n,1)];
equipment_basis=[repmat({'CONDITIONAL:EQUIPMENT WITHSTAND 50 kA for 3 s; transformer-bay physical mapping'},n,1); ...
    repmat({'NOT-APPLICABLE-TO-THIS-COMPARISON:52G separate equipment withstand not evaluated'},n,1)];
duty_ratio=zeros(2*n,1); scope=repmat({'CONDITIONAL'},2*n,1);
current_basis=cell(2*n,1); source_voltage_kV=zeros(2*n,1);
breaker_voltage_kV=[230*ones(n,1);22*ones(n,1)];
continuous_rating_A=[2000*ones(n,1);12400*ones(n,1)];
making_rating_kA=[125*ones(n,1);NaN(n,1)];
short_time_duration_s=[3*ones(n,1);NaN(n,1)];
raw_branch_kA=zeros(2*n,1);
for j=1:2*n
    i=mod(j-1,n)+1; loc=location{j}; typ=fault_type{j}; cs=caseID{j};
    if any(strcmp(loc,{'F1','F2'})), v=22; else, v=230; end
    if j<=n, leg='GSUT_HV'; else, leg='GEN'; end
    hit=strcmp(B.caseID,cs)&strcmp(B.location,loc)&strcmp(B.fault_type,typ)&strcmp(B.leg,leg);
    if sum(hit)~=1
        error('phase5b_duty:branch','Expected one %s branch for %s %s %s.',leg,cs,loc,typ);
    end
    phases=double(B{hit,{'Ia_A','Ib_A','Ic_A'}});
    if any(~isfinite(phases)) || any(phases<0)
        error('phase5b_duty:branch','Nonfinite or negative required branch current.');
    end
    raw_branch_kA(j)=max(phases)/1000;
    source_voltage_kV(j)=v;
    I_sym_kA(j)=raw_branch_kA(j)*v/breaker_voltage_kV(j);
    duty_ratio(j)=I_sym_kA(j)/rating_kA(j);
    if duty_ratio(j)<=1
        verdict{j}='CONDITIONAL-PASS'; comparison='does not exceed';
    else
        verdict{j}='FAIL'; comparison='exceeds';
    end
    current_basis{j}=sprintf('Ikpp maxABC branch %s; physical-side %.0f kV; raw handoff %.0f kV base',leg,breaker_voltage_kV(j),v);
    if j<=n
        rateSource='CONDITIONAL:Q0 mapped to 230 kV transformer-bay breaker; 50 kA interrupting, 2000 A continuous, 125 kA making, 3 s';
    else
        rateSource=['52G GCB-10BAC10 symmetrical rating comparison; ' source52];
    end
    basis{j}=sprintf('%s; identity-gated Phase-4 %s branch; %.9g kA x %.0f/%.0f = %.9g kA',rateSource,leg,raw_branch_kA(j),v,breaker_voltage_kV(j),I_sym_kA(j));
    note{j}=sprintf('%s: %.9g kA %s %.9g kA; duty ratio %.9g. Ikpp through-current screening, not breaking-time Ib verification; DC decrement, contact-parting time and asymmetry not evaluated. Fault-point total is never a duty basis.', ...
        verdict{j},I_sym_kA(j),comparison,rating_kA(j),duty_ratio(j));
    if ismember('r_kappa_ip',Tthrough.Properties.VariableNames)
        I_peak_kA(j)=Tthrough.r_kappa_ip(i);
    elseif ismember('I_peak_kA',Tthrough.Properties.VariableNames)
        I_peak_kA(j)=Tthrough.I_peak_kA(i);
    end
    note{j}=[note{j} ' I_peak_kA is a fault-system borrowed-shape reference only; no branch making-duty verdict.'];
end
D=table(location,breaker_ref,fault_type,caseID,I_sym_kA,I_peak_kA,rating_kA,basis,verdict,note, ...
    equipment_rating_kA,equipment_basis,duty_ratio,scope,current_basis,source_voltage_kV,breaker_voltage_kV, ...
    continuous_rating_A,making_rating_kA,short_time_duration_s,raw_branch_kA);
N.equipment_rating_kA=50;
N.equipment_basis={'CONDITIONAL:EQUIPMENT WITHSTAND 50 kA / 3 s transformer-bay reference'};
N.duty_ratio=N.I_sym_kA/50; N.scope={'REFERENCE-ONLY'};
N.current_basis={'Ikpp system fault reference; not a breaker branch'};
N.source_voltage_kV=230; N.breaker_voltage_kV=230;
N.continuous_rating_A=2000; N.making_rating_kA=125; N.short_time_duration_s=3;
N.raw_branch_kA=N.I_sym_kA;
N.note={[N.note{1} '; I_fault_system_reference versus equipment_short_circuit_rating; no branch duty verdict.']};
D=[D;N];
end

function [rating,source]=parse52(ratings)
if istable(ratings), ratings=table2struct(ratings); end
if ~isstruct(ratings) || numel(ratings)~=1 || ~all(isfield(ratings,{'breaker_ref','rating_kA','source'}))
    error('phase5b_duty:ratings','Provide one 52G rating with breaker_ref, rating_kA and source.');
end
if ~strcmp(strtrim(char(ratings.breaker_ref)),'52G')
    error('phase5b_duty:rating','Only 52G may be overridden; Q0 is the fixed conditional transformer-bay case, disconnectors never interrupt.');
end
rating=double(ratings.rating_kA); source=strtrim(char(ratings.source));
if ~isscalar(rating) || ~isfinite(rating) || rating<=0 || isempty(source)
    error('phase5b_duty:rating','52G comparison requires a positive finite rating and its exact evidence label.');
end
end
