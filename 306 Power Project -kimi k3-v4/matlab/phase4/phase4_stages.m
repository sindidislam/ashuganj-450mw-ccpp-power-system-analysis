function R = phase4_stages(caseID, ds, XoR_P, loc, type, stageReq, t_break, ZfMode)
%PHASE4_STAGES  Stage wrapper with normalized Zf probes.
%
%   R = PHASE4_STAGES(caseID, ds, XoR_P, loc, type, stageReq, t_break, ZfMode)
%   maps a stage request plus a normalized probe onto PHASE4_SOLVE.
%
%   stageReq : 'Ikpp' / 'ip' / 'Ib' / 'Isteady' ('ip' reuses the Ikpp
%     solution with its ip fields; no separate solution).
%   t_break  : input only for 'Ib' (no default, no decay model); ignored
%     for every other stage. Missing/empty t_break with 'Ib' errors.
%   ZfMode   : 'bolted' / 'earth' / 'phase', purely resistive.
%     Level base from loc: F1/F2 -> 22 kV -> 4.84 ohm;
%     F3/F4/F5 -> 230 kV -> 529 ohm. bolted -> 0; earth -> 0.01 pu x base
%     (LG/LLG earth path, solver applies 3x); phase -> 0.002 pu x base
%     (LL/LLL undivided). Fixed-ohm cross-level inputs are impossible by
%     construction (no such argument).
%
%   Stage physics (positive-sequence-only engine):
%   - Ib: APPROXIMATION fallback E' = Vt + (Ra + j*Xd')*It,
%     Z' = Ra + j*Xd' (Xd' = 0.3256 machine base, same transfer as Zpp
%     path). Constant-E' reference approximation at specified t_break.
%     No mu/q post-processing. Two-axis sensitivity downstream (D5).
%   - Isteady: constant-field synchronous reference Esync =
%     Vt + (Ra + j*Xd)*It, Zsync = Ra + j*Xd (Xd = 1.7830). No
%     AVR/governor. Two-axis (Edp/Eqp) and field (Eq) values are NOT
%     injected (single-sequence engine); they remain reported diagnostics
%     from phase4_sources.
%
%   Ifault is the governing fault current: LG -> complex Ia; LL/LLG ->
%   complex phase (Ib or Ic) with larger magnitude; LLL -> I1.
%
%   Output fields (exact names): stage, t_break (NaN unless Ib), Ifault
%   (complex governing fault current), Zf_ohm, Zf_pu, footnote.

if isstring(caseID), caseID = char(caseID); end
if isstring(ds), ds = char(ds); end
if isstring(loc), loc = char(loc); end
if isstring(type), type = char(type); end
if isstring(stageReq), stageReq = char(stageReq); end
if isstring(ZfMode), ZfMode = char(ZfMode); end

if ~(ischar(stageReq) && isrow(stageReq) && any(strcmp(stageReq, {'Ikpp','ip','Ib','Isteady'})))
    error('phase4_stages:badStage', 'Unknown stageReq: use ''Ikpp''/''ip''/''Ib''/''Isteady''.');
end
if ~(ischar(ZfMode) && isrow(ZfMode) && any(strcmp(ZfMode, {'bolted','earth','phase'})))
    error('phase4_stages:badZfMode', 'Unknown ZfMode ''%s'': use ''bolted''/''earth''/''phase''.', ZfMode);
end
Rst = phase4_registry();  % C8 canonical level bases (never literals)
if any(strcmp(loc, {'F1','F2'}))
    Zbase_level = Rst.frozen.Zbase_22_ohm.value;  % 4.84
elseif any(strcmp(loc, {'F3','F4','F5'}))
    Zbase_level = Rst.frozen.Zbase_ohm.value;  % 529
else
    error('phase4_stages:badLoc', 'Unknown fault location ''%s'': use F1/F2/F3/F4/F5.', loc);
end
if ~any(strcmp(type, {'LLL','LG','LL','LLG'}))
    error('phase4_stages:badType', 'Unknown fault type ''%s'': use LLL/LG/LL/LLG.', type);
end

if strcmp(stageReq, 'Ib')
    if nargin < 7 || isempty(t_break) || ~(isnumeric(t_break) && isscalar(t_break) && isfinite(t_break) && t_break >= 0)
        error('phase4_stages:missingTbreak', 'Ib requires a finite scalar t_break >= 0 (input only, never defaulted).');
    end
    t_out = t_break;
else
    t_out = NaN;
end

switch ZfMode
    case 'bolted'
        Zf_ohm = 0;
    case 'earth'
        Zf_ohm = 0.01*Zbase_level;
    case 'phase'
        Zf_ohm = 0.002*Zbase_level;
end
Zf_pu = Zf_ohm/Zbase_level;  % level-base pu (mirrors Zbase_level map in phase4_solve fault insertion).

if strcmp(stageReq, 'ip') || strcmp(stageReq, 'Ikpp')
    solverStage = 'Ikpp';
elseif strcmp(stageReq, 'Ib')
    solverStage = 'Ib';
else
    solverStage = 'Isteady';
end

F = phase4_solve(caseID, ds, XoR_P, loc, type, solverStage, Zf_ohm);

switch type
    case 'LG'
        Ifault = F.Ia;
    case {'LL','LLG'}
        if abs(F.Ib) >= abs(F.Ic)
            Ifault = F.Ib;
        else
            Ifault = F.Ic;
        end
    case 'LLL'
        Ifault = F.I1;
end

if strcmp(stageReq, 'Ib')
    footnote = 'constant-E'' reference approximation at specified t_break';
    if strcmp(type, 'LLG')
        footnote = [footnote '; LLG single-earth path'];
    end
    footnote = [footnote '; ZfMode=' ZfMode];
elseif strcmp(type, 'LLG')
    footnote = ['LLG single-earth path; bolted-baseline comparison; ZfMode=' ZfMode];
else
    footnote = ['bolted-baseline reference; ZfMode=' ZfMode];
end

R = struct('stage', stageReq, 't_break', t_out, 'Ifault', Ifault, ...
    'Zf_ohm', Zf_ohm, 'Zf_pu', Zf_pu, 'footnote', footnote);
end
