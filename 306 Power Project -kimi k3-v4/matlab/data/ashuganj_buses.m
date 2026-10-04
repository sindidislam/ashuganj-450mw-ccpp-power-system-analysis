function B = ashuganj_buses()
%ASHUGANJ_BUSES Electrical bus registry for Ashuganj South.
B = busrec('BGRID230','EXT GRID 230 kV','',230000,'GRID','swing',NaN,'NOT_APPLICABLE',NaN,'NOT_APPLICABLE',true);
B(2) = busrec('B230_1','230 kV BUS 1','10BAC01',230000,'GIS230','PQ',3150,'VERIFIED_ENGINEERING_DOCUMENT',50,'VERIFIED_ENGINEERING_DOCUMENT',true);
B(3) = busrec('B230_2','230 kV BUS 2','10BAC02',230000,'GIS230','PQ',3150,'VERIFIED_ENGINEERING_DOCUMENT',50,'VERIFIED_ENGINEERING_DOCUMENT',true);
B(4) = busrec('B22','22 kV GEN BUS','10BAC10',22000,'GEN','PV',12400,'VERIFIED_ENGINEERING_DOCUMENT',NaN,'MISSING',true);
B(5) = busrec('B6_6','6.6 kV MV BUS','10BBA10',6600,'AUX','PQ',3150,'VERIFIED_ENGINEERING_DOCUMENT',31.5,'VERIFIED_ENGINEERING_DOCUMENT',true);
B(6) = busrec('B6_6_WI1','6.6 kV WI-1','10BBW10',6600,'AUX','PQ',1250,'VERIFIED_ENGINEERING_DOCUMENT',31.5,'VERIFIED_ENGINEERING_DOCUMENT',true);
B(7) = busrec('B6_6_WI2','6.6 kV WI-2','10BBW20',6600,'AUX','PQ',1250,'VERIFIED_ENGINEERING_DOCUMENT',31.5,'VERIFIED_ENGINEERING_DOCUMENT',true);
B(8) = busrec('B0_4','400 V AUX BUS','10BFA01',400,'AUX','PQ',NaN,'MISSING',NaN,'MISSING',false);
B(9) = busrec('B3_32','3.32 kV GAT TERTIARY','10BBT20',3320,'AUX','PQ',1448.6,'VERIFIED_PLANT',NaN,'MISSING',false);
B(10) = busrec('BNER','NER SECONDARY 500 V','10BAB11',500,'GEN','PQ',NaN,'NOT_APPLICABLE',NaN,'NOT_APPLICABLE',false);
B(11) = busrec('B230_REMOTE','230 kV REMOTE','',230000,'GRID','PQ',NaN,'NOT_APPLICABLE',NaN,'NOT_APPLICABLE',true);
B(5).Notes = 'Rev 03 SLD main bus 3150 A 31.5 kA; 6.9 kV transformer winding is off nominal ratio';
B(6).Notes = 'Rev 03 water intake bus 10BBW10 1250 A 31.5 kA';
B(7).Notes = 'Rev 03 water intake bus 10BBW20 1250 A 31.5 kA';
B(9).Notes = 'Physical GAT 3.32 kV stabilizing tertiary 8.33 MVA';
assert(max([B.Vnom_V]) == 230000);
end
function b = busrec(name,label,kks,v,zone,type,rated,rstat,isc,istat,included)
b.Name=name; b.Label=label; b.KKS=kks; b.Vnom_V=v;
b.Vnom_Status='VERIFIED_ENGINEERING_DOCUMENT'; b.Vnom_Source='South engineering source set';
b.Zone=zone; b.Type=type; b.Type_Status='DERIVED_FROM_VERIFIED_DATA';
b.Rated_A=rated; b.Rated_A_Status=rstat; b.Isc_kA=isc; b.Isc_kA_Status=istat;
b.Model_included=included; b.Notes=''; b.Exclusion_reason='';
end
