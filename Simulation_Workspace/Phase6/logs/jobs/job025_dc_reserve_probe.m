clear phase6_dc_parameters phase6_dc_step
rehash
D=phase6_dc_parameters();D.dc_soc_initial=.2;
U=struct('auxVoltage_pu',1,'batteryAvailable',true,'chargerAvailable',false,'tripDemand',false);
[Y,s]=phase6_dc_step(U,[],.001,D);
U.chargerAvailable=true;
for k=1:2000
[Y,s]=phase6_dc_step(U,s,.001,D);
if any(k==[1 5 10 50 100 1000 2000]),fprintf('k=%d V=%.9f Ib=%.9f Ic=%.9f SOC=%.12f lost=%.9f stateIc=%.9f\n',k,Y.Vdc_V,Y.Ibattery_A,Y.Icharger_A,Y.SOC,Y.unservedPower_W,s.Icharger_A);end
end
