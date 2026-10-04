S=readtable('C:\Users\sindi\Downloads\306 Power Project -kimi k3\Phase6\data\phase5_reference\phase5_relay_settings.csv','TextType','string');
format long g
for name={'setting_A_primary','setting_A_secondary','ct_ratio'}
v=S.(name{1}); disp(name{1}); disp(class(v)); disp(v); disp(str2double(string(v)));
end
