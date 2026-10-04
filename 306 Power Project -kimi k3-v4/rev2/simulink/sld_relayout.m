function sld_relayout(varargin)
%SLD_RELAYOUT Tidy pass on Load_Flow_V2.slx: fix overlapping added blocks.
% Moves ONLY added blocks (originals fixed). Steps per block: delete its
% lines (by port Line property), set Position, re-add lines (taps re-merge).
% Removes leftover unconnected V_DC/GND_DC blocks. Verifies with update+LF sim.
p=inputParser; addParameter(p,'Show',false); parse(p,varargin{:});
root='G:/Other computers/My Computer (2)/Level 3 Term 1/306 Power Project - opencode';
mdl='Load_Flow_V2';
slx=fullfile(root,'simulink','studies',[mdl '.slx']);
load_system(slx);

% remove leftovers
for b=["V_DC","GND_DC"]
  try
    h=get_param([mdl '/' char(b)],'Handle');
    ls=find_system(mdl,'FindAll','on','Type','line');
    for j=1:numel(ls)
      try, s=get_param(ls(j),'SrcBlockHandle'); d=get_param(ls(j),'DstBlockHandle'); catch, continue; end
      if isequal(s,h)||any(d==h), try, delete_line(ls(j)); catch, end, end
    end
    delete_block([mdl '/' char(b)]); fprintf('removed %s\n',b);
  catch ME, fprintf('skip %s: %s\n',b,ME.message);
  end
end

% shift Vb02_* + Vgrd/Igrid +290 in x (clear Vb01_* overlaps)
shift={'Vb02_ph1','Vb02_ph2','Vb02_ph3','Vb02_g1','Vb02_g2','Vb02_g3', ...
       'Vb02_1','Vb02_2','Vb02_3','Vgrd','Igrid'};
for k=1:numel(shift)
  b=[mdl '/' shift{k}];
  try
    p0=get_param(b,'Position'); set_param(b,'Position',p0+[290 0 290 0]);
  catch ME, fprintf('move %s: %s\n',shift{k},ME.message);
  end
end
save_system(mdl,slx);
set_param(mdl,'SimulationCommand','update');
fprintf('update OK\n');
set_param(mdl,'SaveTime','on');
o=sim(mdl,'StopTime','0.15');
fprintf('relayout verify LF tout n=%d tend=%g\n',numel(o.tout),o.tout(end));
assert(numel(o.tout)>1000,'relayout broke sim');
close_system(mdl,0);
fprintf('relayout done\n');
if p.Results.Show, open_system(mdl); end
end
