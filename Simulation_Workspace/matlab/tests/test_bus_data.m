function [np, nf] = test_bus_data()
%TEST_BUS_DATA  Structural checks on the bus list.
%
%   The 400 V / 400 kV check is not busywork. Writing 400 kV where 400 V was
%   meant is a thousand-fold error that a solver will happily converge on, and
%   the Ashuganj site genuinely has BOTH a 400 V auxiliary board (South) and a
%   400 kV switchyard (North plant, out of scope). This test makes the
%   distinction machine-checked rather than a matter of care.
T = t_case('test_bus_data');
B = ashuganj_buses();

T = T.chk(~isempty(B), 'bus list is not empty');
T = T.eq(numel(unique({B.Name})), numel(B), 'bus names are unique');

for i = 1:numel(B)
    T = T.chk(~isempty(B(i).Name)  && ischar(B(i).Name),  sprintf('bus %d has a Name', i));
    T = T.chk(~isempty(B(i).Label) && ischar(B(i).Label), sprintf('%s has a Label', B(i).Name));
    T = T.chk(isfinite(B(i).Vnom_V) && B(i).Vnom_V > 0, ...
              sprintf('%s Vnom is a positive finite number', B(i).Name));
    T = T.chk(~isempty(B(i).Zone), sprintf('%s has a Zone', B(i).Name));
end

% ---- the 400 V / 400 kV guard ------------------------------------------
k = find(strcmp({B.Name}, 'B0_4'), 1);
T = T.chk(~isempty(k), '400 V auxiliary bus exists');
if ~isempty(k)
    T = T.eq(B(k).Vnom_V, 400, '400 V board is 400 V (NOT 400 kV)');
end
T = T.eq(sum([B.Vnom_V] == 400e3), 0, ...
         'no 400 kV bus anywhere - the 400 kV GIS belongs to the North plant');
T = T.eq(max([B.Vnom_V]), 230e3, 'highest voltage in the South model is 230 kV');

% ---- the documented voltage set -----------------------------------------
allowed = [230000 22000 6600 3320 500 400];
for i = 1:numel(B)
    T = T.chk(any(B(i).Vnom_V == allowed), ...
        sprintf('%s Vnom %g V is one of the documented plant voltages', ...
                B(i).Name, B(i).Vnom_V));
end

% ---- buses the load flow actually needs ---------------------------------
needed = {'BGRID230','B230_1','B230_2','B22','B6_6'};
for i = 1:numel(needed)
    T = T.chk(any(strcmp({B.Name}, needed{i})), ...
              sprintf('load-flow bus %s is defined', needed{i}));
end

[np, nf] = T.done();
end
