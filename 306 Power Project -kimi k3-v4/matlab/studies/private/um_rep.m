function [N, S, iters] = um_rep(fn)
%UM_REP  Read a powergui load-flow report back into numbers.
%
%   [N, S, ITERS] = UM_REP(FN) parses one results/load_flow/*.rep file:
%
%     N      one element per solved node, as the tool prints it:
%            .id  ('*1*')  .V_pu  .base_kV  .ang_deg  .swing  .Pgen_MW
%     S      the SUMMARY block: .generation .PQ_load .Zshunt_load .ASM_load
%            .losses, each [P_MW Q_MVAr]
%     ITERS  the iteration count from the first line
%
%   WHY PARSE THE REPORT AT ALL
%   ---------------------------
%   The report is what an audience actually sees on the projector, and it prints
%   node names the model does not use - '*1*' to '*5*'. Reading it back lets the
%   manual show the same figures the tool shows, and lets the '*n*' labels be
%   MATCHED to real bus names instead of the mapping being retyped from memory.
%
%   Everything here is read, nothing is assumed. A field the report does not
%   contain comes back empty or NaN.

N = struct('id', {}, 'V_pu', {}, 'base_kV', {}, 'ang_deg', {}, ...
           'swing', {}, 'Pgen_MW', {});
S = struct();
iters = NaN;

if ~exist(fn, 'file'), return, end
L = readlines(fn);
cur = 0;

for k = 1:numel(L)
    s = strtrim(char(L(k)));
    if isempty(s), continue, end

    if isnan(iters)
        t = regexp(s, 'converged in\s+(\d+)\s+iterations', 'tokens', 'once');
        if ~isempty(t), iters = str2double(t{1}); end
    end

    % ---- SUMMARY block: "Total losses : P= 0.62 MW Q= 52.20 Mvar" ----------
    t = regexp(s, ['^Total\s+(generation|PQ\s+load|Zshunt\s+load|ASM\s+load|' ...
                   'losses)\s*:\s*P=\s*(-?[\d.]+)\s*MW\s*Q=\s*(-?[\d.]+)'], ...
               'tokens', 'once');
    if ~isempty(t)
        f = strrep(strtrim(t{1}), ' ', '_');
        S.(f) = [str2double(t{2}), str2double(t{3})];
        continue
    end

    % ---- node header: "1 : *1*  V= 0.957 pu/230kV 4.33 deg  ; Swing bus" ---
    t = regexp(s, ['^(\d+)\s*:\s*\*(\d+)\*\s+V=\s*([\d.]+)\s*pu/([\d.]+)\s*kV' ...
                   '\s*(-?[\d.]+)\s*deg(.*)$'], 'tokens', 'once');
    if ~isempty(t)
        cur = numel(N) + 1;
        N(cur).id      = ['*' t{2} '*'];
        N(cur).V_pu    = str2double(t{3});
        N(cur).base_kV = str2double(t{4});
        N(cur).ang_deg = str2double(t{5});
        N(cur).swing   = contains(t{6}, 'swing', 'IgnoreCase', true);
        N(cur).Pgen_MW = NaN;
        continue
    end

    % ---- per-node generation. "Total generation" is caught above, so a line
    % starting with "Generation" here can only be a node's own injection.
    t = regexp(s, '^Generation\s*:\s*P=\s*(-?[\d.]+)\s*MW', 'tokens', 'once');
    if ~isempty(t) && cur > 0
        N(cur).Pgen_MW = str2double(t{1});
    end
end
end
