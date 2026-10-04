clear phase6_dc_parameters phase6_dc_step
rehash
D=phase6_dc_parameters();
U=struct('auxVoltage_pu',.79,'batteryAvailable',false,'chargerAvailable',true,'tripDemand',false);
[Y,s]=phase6_dc_step(U,[],.001,D);
format long g
disp(Y); fprintf('unserved_minus_2400=%.17g\n',Y.unservedPower_W-2400);
