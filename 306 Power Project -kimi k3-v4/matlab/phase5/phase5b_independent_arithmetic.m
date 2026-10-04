function A=phase5b_independent_arithmetic(M)
%PHASE5B_INDEPENDENT_ARITHMETIC Explicit-equation cross-check of study data.
% This audit intentionally uses the equations/constants directly rather
% than reusing phase5b_parameters derivation helpers or phase5_curve.
% With M supplied, each coordination-side operating time is independently
% checked on its exported secondary current. Nontrip is a numeric trip flag
% check; a fictitious finite operating time is never assigned to nontrip.
[P,~]=phase5b_parameters();rows=cell(0,8);
check('GEN_51_pickup_A',P.GEN_51_pickup_A,1.20*14309,1e-9,'A','1.20*14309');
check('GSUT_maximum_load_anchor_A',P.GSUT_maximum_load_anchor_A,458e6/(sqrt(3)*230e3),1e-9,'A','458e6/(sqrt(3)*230e3)');
check('GSUT_rated_exact_A',P.GSUT_rated_exact_A,515e6/(sqrt(3)*230e3),1e-9,'A','515e6/(sqrt(3)*230e3)');
check('GSUT_rated_A',P.GSUT_rated_A,round(515e6/(sqrt(3)*230e3),1),1e-9,'A','nameplate-current equation rounded to 0.1 A');
check('GSUT_51_pickup_A',P.GSUT_51_pickup_A,round((1.2*458e6/(sqrt(3)*230e3))/10)*10,1e-9,'A','1.2 times maximum-load anchor rounded to 10 A');
check('GSUT_51_secondary_A',P.GSUT_51_secondary_A,1380/1600,1e-12,'A','1380/1600');
check('Q0_51_secondary_A',P.Q0_51_secondary_A,1500/1600,1e-12,'A','1500/1600');
check('GEN_87G_pickup_A',P.GEN_87G_pickup_A,0.20*12019,1e-9,'A','0.20*12019');
check('GSUT_87T_pickup_A',P.GSUT_87T_pickup_A,0.30*1292.8,1e-9,'A','0.30*1292.8');
check('GEN_51N_pickup_A',P.GEN_51N_pickup_A,0.20*20,1e-12,'A','0.20*20');
check('GEN_51_secondary_A',P.GEN_51_secondary_A,17170.8/15000,1e-12,'A','17170.8/15000');
check('SOUTH_R1_total_ohm',P.SOUTH_R1_total_ohm,0.7*0.08,1e-12,'ohm','0.7*0.08');
check('SOUTH_X1_total_ohm',P.SOUTH_X1_total_ohm,0.7*0.35,1e-12,'ohm','0.7*0.35');
check('SOUTH_R0_total_ohm',P.SOUTH_R0_total_ohm,0.7*0.25,1e-12,'ohm','0.7*0.25');
check('SOUTH_X0_total_ohm',P.SOUTH_X0_total_ohm,0.7*1.20,1e-12,'ohm','0.7*1.20');
z=230000/(sqrt(3)*45010);r=z/sqrt(1+10.99^2);x=10.99*r;
check('GRID_Zth_ohm',P.GRID_Zth_ohm,z,1e-12,'ohm','230000/(sqrt(3)*45010)');
check('GRID_Rth_ohm',P.GRID_Rth_ohm,r,1e-12,'ohm','Zth/sqrt(1+10.99^2)');
check('GRID_Xth_ohm',P.GRID_Xth_ohm,x,1e-12,'ohm','10.99*Rth');
check('GRID_Ssc_GVA',P.GRID_Ssc_GVA,sqrt(3)*230e3*45010/1e9,1e-12,'GVA','sqrt(3)*230000*45010/1e9');
check('CT_accuracy_boundary_A',P.CT_accuracy_boundary_A,20*1600,1e-9,'A','20*1600');
check('GEN_R1_pu',P.GEN_R1_pu,0.00089*458/(22^2),1e-12,'pu','0.00089/(22^2/458)=0.0008421900826; not rounded 0.000843');
check('GEN_R2_pu',P.GEN_R2_pu,0.00089*458/(22^2),1e-12,'pu','assumption R2=R1 exact derivation');
check('GEN_R0_pu',P.GEN_R0_pu,1.5*0.00089*458/(22^2),1e-12,'pu','assumption R0=1.5*R1 exact derivation');
check('GSUT_R1_pu',P.GSUT_R1_pu,(1067.5-155.3)/1000/515,1e-12,'pu','(workbook AN3-AL3)/1000/AK3');
check('GSUT_X1_pu',P.GSUT_X1_pu,sqrt(0.1663^2-(0.9122/515)^2),1e-12,'pu','sqrt(0.1663^2-(0.9122/515)^2)');
check('NGT_ratio',P.NGT_ratio,(22000/sqrt(3))/500,1e-12,'1','(22000/sqrt(3))/500');
check('NER_effective_HV_ohm',P.NER_effective_HV_ohm,60+(22000/sqrt(3)/500)^2*2.62,1e-9,'ohm','60+(22000/sqrt(3)/500)^2*2.62');
specs={'GEN_51',17170.8,15000,0.10;'GSUT_51',1380,1600,0.55;'Q0_51',1500,1600,0.80;'GEN_51N',4,20,0.15};
for k=1:size(specs,1)
 prefix=specs{k,1};pickup=specs{k,2};ct=specs{k,3};tms=specs{k,4};
 check([prefix '_TMS'],P.([prefix '_TMS']),tms,1e-12,'1','user central coordination starting TMS');
 for multiple=[2 5 10]
  runtime=phase5_time(multiple*pickup/ct,pickup/ct,P.([prefix '_TMS']),'SI');
  independent=0.14*tms/(multiple^0.02-1);
  check(sprintf('%s_SI_TIME_%gx',prefix,multiple),runtime,independent,1e-9,'s',sprintf('0.14*%.12g/(%.12g^0.02-1)',tms,multiple));
 end
end
if nargin>0 && ~isempty(M)
 R=phase5b_registry();d=R.devices;ids={d.device_id};
 for i=1:height(M)
  for side={'down','up'}
   s=side{1};if strcmp(s,'down'),id=char(string(M.downstream(i)));else,id=char(string(M.upstream(i)));end
   current=double(M.(['I_' s '_A'])(i));runtime=double(M.(['t_' s '_s'])(i));
   ct=double(M.(['ct_' s])(i));
   label=sprintf('M%03d_%s_%s',i,s,id);
   if ~isfinite(current)||~isfinite(ct)||ct<=0
    check([label '_finite_time_present'],double(isfinite(runtime)),0,0,'boolean','No represented current/CT side has no finite relay operating time');
    continue;
   end
   pos=find(strcmp(ids,id),1);
   if isempty(pos),error('phase5b_arithmetic:device','Cannot independently audit %s',id);end
   pickup=d(pos).pickup_A/ct;tms=d(pos).tms;
   if current<=pickup
    check([label '_trip_enabled'],double(isfinite(runtime)),0,0,'boolean','Isecondary <= pickup/CT implies no finite SI trip');
   else
    independent=0.14*tms/((current/pickup)^0.02-1);
    check([label '_operating_time_s'],runtime,independent,1e-8,'s','0.14*TMS/((Isecondary/(pickupPrimary/CT))^0.02-1)');
   end
  end
 end
end
A=cell2table(rows,'VariableNames',{'parameter','runtime_value','independent_value','absolute_error','tolerance','unit','verdict','equation'});
A.runtime_value=cell2mat(rows(:,2));A.independent_value=cell2mat(rows(:,3));A.absolute_error=cell2mat(rows(:,4));A.tolerance=cell2mat(rows(:,5));
 function check(name,runtime,independent,tol,unit,equation)
  err=abs(runtime-independent);
  if isfinite(err)&&err<=tol,verdict='PASS';else,verdict='FAIL';end
  rows(end+1,:)={name,runtime,independent,err,tol,unit,verdict,equation};
 end
end
