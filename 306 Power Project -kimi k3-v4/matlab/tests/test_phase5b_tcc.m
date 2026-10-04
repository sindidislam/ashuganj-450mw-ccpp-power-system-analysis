function [np,nf]=test_phase5b_tcc()
% TCC evidence uses a common voltage base and actual per-device settings.
T=t_case('test_phase5b_tcc'); out=fullfile(tempdir,['phase5b_tcc_' char(java.util.UUID.randomUUID())]);
mkdir(out);cleanup=onCleanup(@()rmdir(out,'s')); %#ok<NASGU>
S=phase5b_tcc(out,ashuganj_root());
T=T.chk(isfile(S.physical_png)&&isfile(S.study_png)&&~strcmp(S.physical_png,S.study_png),'separate comparator and coordination plots are generated');
a=imfinfo(S.physical_png);b=imfinfo(S.study_png);
T=T.chk(a.Width>800&&a.Height>400&&b.Width>800&&b.Height>400,'both generated PNGs have usable dimensions');
T=T.chk(S.reference_voltage_kV==230,'coordination plot uses a shared 230 kV current reference');
ss=S.study_settings;names={ss.device_id};
g=ss(strcmp(names,'GEN-51'));h=ss(strcmp(names,'GSUT-HV-51'));q=ss(strcmp(names,'GIS-Q0-51'));
T=T.chk(numel(ss)==3&&abs(g.plot_pickup_A-1642.424347826087)<1e-8&&h.plot_pickup_A==1380&&q.plot_pickup_A==1500,'generator pickup is referred from 22 kV before plotting with HV relays');
T=T.chk(abs(g.pickup_prim-17170.8)<1e-9&&g.ct==15000&&h.ct==1600&&q.ct==1600,'plot metadata preserves original physical-side settings and CTs');
tm=[.10,.55,.80];
for k=1:numel(ss)
 x=ss(k);want=tm(strcmp({'GEN-51','GSUT-HV-51','GIS-Q0-51'},x.device_id));
 T=T.chk(abs(x.TMS-want)<1e-12&&strcmp(x.curve,'SI'),[x.device_id ' plot uses its actual TMS and SI characteristic']);
 T=T.chk(abs(S.study_times(k)-.14*want/(2^.02-1))<1e-10,[x.device_id ' plot time matches independent IEC SI equation']);
 T=T.chk(abs(x.pickup_sec-x.pickup_prim/x.ct)<1e-12,[x.device_id ' plot preserves CT conversion']);
end
T=T.chk(contains(S.study_title,'0.10')&&contains(S.study_title,'0.55')&&contains(S.study_title,'0.80'),'title identifies the actual three TMS values');
T=T.chk(contains(lower(strjoin(S.study_foot,' ')),'conditional')&&contains(strjoin(S.study_foot,' '),'230'),'plot explains common voltage reference and conditional Q0 mapping');
T=T.chk(abs(S.dt_Is_prim-17170.8)<.5&&abs(S.dt_Is_sec-S.dt_Is_prim/15000)<1e-12&&S.tdef_s==3,'DT comparator retains numerical 3 s and correct CT conversion');
T=T.chk(contains(lower(strjoin(S.physical_foot,' ')),'unverified')&&contains(lower(S.tdef_label),'study'),'comparator timing is labeled as an unverified study assumption');
T=T.chk(abs(S.pickup_87G_A-2403.8)<1e-9&&~isfield(S,'curve_87G'),'87G has its adopted threshold without an invented inverse curve');
fp=fullfile(out,'tcc_metadata.json');T=T.chk(isfile(fp),'plot metadata is persisted for verification');
J=jsondecode(fileread(fp));jg=strcmp({J.study_settings.device_id},'GEN-51');
T=T.chk(J.reference_voltage_kV==230&&sum(jg)==1&&abs(J.study_settings(jg).plot_pickup_A-g.plot_pickup_A)<1e-9,'persisted metadata preserves plotted physical conversion');
try,phase5b_tcc(42);T=T.chk(false,'invalid output path rejected');catch ME,T=T.chk(startsWith(ME.identifier,'phase5b_tcc'),'invalid output path rejected');end
[np,nf]=T.done();
end
