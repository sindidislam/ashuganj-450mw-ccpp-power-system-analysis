function test_phase6_panel_refresh(mdl)
%TEST_PHASE6_PANEL_REFRESH Scripted edits must be visible in the open panel.
% Requires an already loaded working model; no simulation is run here.
if nargin<1,mdl='PHASE6_ASHUGANJ_CCPP_CLOSED_LOOP_TRIP';end
assert(bdIsLoaded(mdl),'Phase6:TestModel','Load the working model first.');
original=phase6_interactive_settings(mdl,'get');
cleanup=onCleanup(@()restoreSettings(mdl,original)); %#ok<NASGU>
fig=phase6_interactive_settings(mdl);
edited=original.R;edited.delay_s(3)=.123;
phase6_interactive_settings(mdl,'apply',struct('relay',edited, ...
    'scenario',struct('name','panel_refresh_regression','faultEnabled',true, ...
    'faultType','SLG','faultLocation','GEN','faultStart_s',.15,'stopTime_s',.6, ...
    'batteryAvailable',false)));
drawnow;
edits=findall(fig,'Style','edit');
names=string(get(edits,'String'));
assert(any(names=="panel_refresh_regression"),'Phase6:StalePanel', ...
    'The visible scenario name must update after a scripted apply.');
tables=findall(fig,'Type','uitable');
relay=[];meters=[];
for h=tables(:).'
    data=get(h,'Data');
    if isequal(size(data),[7 7]),relay=data;end
    if isequal(size(data),[19 6]),meters=data;end
end
assert(~isempty(relay)&&abs(relay{6,5}-.123)<1e-12,'Phase6:StalePanel', ...
    'The visible 87B delay must match the active model after a scripted apply.');
assert(all(cellfun(@isempty,relay(1:3,5:7)),'all') ...
    &&all(cellfun(@isempty,relay(4:7,4)),'all'), ...
    'Phase6:InapplicableCells','Inapplicable relay setting cells must be blank.');
assert(~isempty(meters)&&all(isnan(meters),'all'),'Phase6:StaleMeters', ...
    'Applying settings must clear measurements from the preceding run.');
battery=findall(fig,'Style','checkbox','String','Battery available');
assert(isscalar(battery)&&get(battery,'Value')==0,'Phase6:StalePanel', ...
    'The battery toggle must show the current model setting.');
menus=findall(fig,'Style','popupmenu');matchedType=false;matchedLocation=false;
for h=menus(:).'
    options=get(h,'String');selected=string(options{get(h,'Value')});
    if any(strcmp(options,'NONE')),matchedType=selected=="SLG";end
    if any(strcmp(options,'GIS230')),matchedLocation=selected=="GEN";end
end
assert(matchedType&&matchedLocation,'Phase6:StalePanel', ...
    'Visible fault selections must match the current scenario.');

% Simulate stale display text and use the normal reopen action to refresh it.
nameHandle=edits(names=="panel_refresh_regression");
set(nameHandle,'String','stale display text');
reopened=phase6_interactive_settings(mdl);drawnow;
assert(isequal(reopened,fig)&&strcmp(get(nameHandle,'String'),'panel_refresh_regression'), ...
    'Phase6:StalePanel','Reopening must refresh the existing panel from saved settings.');
fprintf('PHASE6_PANEL_REFRESH_PASS: scenario, relay, toggles, menus, cleared meters and reopen.\n');
end

function restoreSettings(mdl,c)
if bdIsLoaded(mdl)
    phase6_interactive_settings(mdl,'apply',struct('scenario',c.S,'relay',c.R));
end
end
