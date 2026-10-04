function s = gui_symbols(name)
%GUI_SYMBOLS  Canonical symbol, unit and gloss for every quantity in the study.
%
%   s = GUI_SYMBOLS(name) takes one quantity name - a result-CSV column header
%   such as P_gen_MW, or a register field such as xdpp_pct - and returns a
%   scalar struct: .name, .latex ('$V$', for Interpreter 'latex'), .html
%   ('\(V\)', for the exported report), .units ('pu', bare text for a table
%   header) and .desc. GUI_SYMBOLS() returns the catalogue as a table.
%
%   WHY ONE CATALOGUE. The project already shows what happens without one: the
%   titles inside make_load_flow_plots hard-code UAT 109.50 % where the CSV now
%   says 109.60, and three different numbers circulate for one GAT bar. A
%   figure a caller retypes drifts; a symbol and a unit read from here cannot.
%
%   WHY THREE RENDERINGS. uihtml cannot reach a CDN, so MathJax never runs
%   in-window and equations there must go through a uilabel with Interpreter
%   'latex' (.latex). The standalone file GUI_HTML_REPORT writes is opened in a
%   real browser, where MathJax does run, so it wants the inline form (.html).
%
%   WHY IT NEVER THROWS. Callers ask for symbols inside the loop that builds a
%   table header, so a renamed column must degrade to a plain label rather than
%   kill the tab. An unknown name returns its own escaped text as the symbol,
%   with the unit recovered from the name suffix when the register naming
%   convention allows it (S12) and empty when it does not. Nothing here errors.
%
%   See also GUI_TEXTIFY, GUI_TABLE_TO_HTML, GUI_HTML_REPORT.

% =====================================================================
if nargin < 1 || isempty(name)
    s = full_map();
    return
end
if isstring(name)
    if ~isscalar(name), name = name(1); end
    name = char(name);
end
if ~ischar(name)
    s = pack('', '', '', 'Not a quantity name, so no symbol is available.');
    return
end
name = strtrim(name);

C = catalogue();
k = find(strcmp(C(:,1), name), 1);
if isempty(k), k = find(strcmpi(C(:,1), name), 1); end
if ~isempty(k)
    s = pack(name, C{k,2}, C{k,3}, C{k,4});
    return
end

% A provenance sibling (Vnom_Status, Z_Source, Lm_Derivation, ...) is prose
% about its base quantity, so it borrows that symbol and carries no unit.
% Every numeric in the registers has two or three of them; enumerating them
% would treble the catalogue and add no information.
tag = regexp(name, '_(Status|Source|Note|Notes|Derivation|Warning|Reason)$', ...
             'tokens', 'once');
if ~isempty(tag) && numel(name) > numel(tag{1}) + 1
    base = name(1:end-numel(tag{1})-1);
    q    = gui_symbols(base);
    s    = pack(name, q.latex, '', sprintf('%s prose for %s, not a number.', ...
                                           lower(tag{1}), base));
    return
end

s = infer(name);
end

% =====================================================================
function C = catalogue()
%CATALOGUE  name, LaTeX, unit, one-line gloss. Derived from the six result-CSV
%   headers and the register field names, not from imagination. A name earns a
%   row only when INFER would get its symbol or its unit wrong, or when it
%   carries a trap - a sign convention, a deliberate NaN, a base that is not
%   the system base - that a reader has to be told about.
C = { ...
'V_pu',           '$V$',       'pu',  'Bus voltage magnitude on the register nominal base'
'V_kV',           '$V$',       'kV',  'Bus voltage magnitude, line to line'
'V_pu_nom',       '$V$',       'pu',  'Voltage on the register nominal base, which is what the CSV column V_pu actually holds'
'V_pu_alt',       '$V^{*}$',   'pu',  'Voltage on the alternative 6900 V winding base, conflict C13'
'V_pu_alt_base',  '$V^{*}$',   'pu',  'Voltage on the alternative base named in Alt_base_V, populated on the 6.6 kV bus only'
'Alt_base_V',     '$V_{\mathrm{base}}^{*}$','V','Alternative base voltage: 6900 V on the 6.6 kV bus, NaN everywhere else'
'V_6p6kV_pu_6600base','$V_{6.6}$','pu','6.6 kV bus voltage on the 6600 V reporting base'
'V_6p6kV_pu_6900base','$V_{6.6}^{*}$','pu','The same node on the 6900 V winding base, the second half of conflict C13'
'Gen_Vset_pu',    '$V_{\mathrm{set,gen}}$','pu','Generator terminal setpoint for the case, an unapproved engineering assumption'
'Grid_Vset_pu',   '$V_{\mathrm{set,grid}}$','pu','Swing-bus voltage setpoint for the case'
'Angle_deg',      '$\theta$',  'deg', 'Bus voltage angle referred to the swing bus'
'Ang_deg',        '$\theta$',  'deg', 'Bus voltage angle referred to the swing bus'
'PhaseAngle_deg', '$\theta_{\mathrm{grid}}$','deg','Reference angle of the external grid source'
'P_inj_MW',       '$P_{\mathrm{inj}}$','MW','Real power injected at the bus, generation-positive, NaN on a merged bus'
'Q_inj_MVAr',     '$Q_{\mathrm{inj}}$','MVAr','Reactive power injected at the bus, generation-positive, NaN on a merged bus'
'P_load_alloc_MW','$P_{\mathrm{load}}$','MW','Allocated auxiliary load, load-positive, a dataset input and not a solver output'
'Q_load_alloc_MVAr','$Q_{\mathrm{load}}$','MVAr','Allocated auxiliary reactive load, load-positive dataset input'
'Gen_P_MW',       '$P_{\mathrm{gen}}$','MW','Commanded generator real power for the case: 389.30 rated, 342.01 derated'
'Gen_Q_MVAr_limit','$[Q_{\min},Q_{\max}]$','MVAr','Reactive limits on the machine; -Inf and Inf mean unconstrained, not missing data'
'Export_P_MW',    '$P_{\mathrm{exp}}$','MW','Real power leaving the plant at the boundary, positive when exporting'
'Export_Q_MVAr',  '$Q_{\mathrm{exp}}$','MVAr','Reactive power at the boundary, negative in all four cases because the plant absorbs'
'P_export_MW',    '$P_{\mathrm{exp}}$','MW','Real power leaving the plant at the boundary, positive when exporting'
'Load_P_MW',      '$P_{\mathrm{aux}}$','MW','Total auxiliary real load for the case, 14.000 in all four'
'Load_Q_MVAr',    '$Q_{\mathrm{aux}}$','MVAr','Total auxiliary reactive load, the total load taken at 0.85 power factor'
'Loss_P_MW',      '$P_{\mathrm{loss}}$','MW','System real loss, defined as generation minus auxiliary load minus export, not as a branch sum'
'Branch_Loss_MW', '$\Sigma P_{\mathrm{loss}}$','MW','Sum of the individual branch real losses, which need not equal Loss_P_MW'
'Loss_pct_of_gen','$P_{\mathrm{loss}}/P_{\mathrm{gen}}$','%','Real loss as a percentage of generation, already multiplied by 100'
'S_GAT_MVA',      '$S_{\mathrm{GAT}}$','MVA','Apparent power through the GAT; non-zero even with the bay open, because the magnetising current still flows'
'Rating_stages_MVA','$S_{\mathrm{rat}}$','MVA','Cooling-stage ratings written as bracketed text such as [355 460 515], so readtable returns text and not a number'
'Z_base_MVA',     '$S_{Z}$',   'MVA', 'Rating the impedance percentage is referred to: the transformer own rating, never the 100 MVA system base'
'dP_MW',          '$\Delta P$','MW',  'Solver injection minus the branch sum, real part'
'dQ_MVAr',        '$\Delta Q$','MVAr','Solver injection minus the branch sum, imaginary part'
'Residual_MVA',   '$|\Delta S|$','MVA','KCL residual at the bus; the study fails a case above 0.05'
'Worst_KCL_residual_MVA','$|\Delta S|_{\max}$','MVA','Largest KCL residual over the buses of the case'
'Worst_Residual_MVA','$|\Delta S|_{\max}$','MVA','Largest KCL residual over the buses of the case'
'Rated_A',        '$I_{\mathrm{rat}}$','A','Continuous current rating of the bus or bay, rms'
'Isc_kA',         '$I_{\mathrm{sc}}$','kA','On the 230 kV buses this is the 1 s withstand rating, not a fault level; on the grid record it is an estimate'
'Z_pct',          '$Z$',       '%',   'Short-circuit impedance on the transformer own rating, not on the system base'
'XR_ratio',       '$X/R$',     '-',   'Reactance to resistance ratio; Inf on the grid equivalent, whose resistance is assumed zero'
'Lm_pu',          '$L_{m}$',   'pu',  'Magnetising inductance derived from the no-load current; it replaced a superseded 1e6 pu open circuit'
'xdp_pct',        '$x_{d}^{\prime}$','%','Transient reactance on the own 458 MVA and 22 kV base, held for the later fault study'
'xdpp_pct',       '$x_{d}^{\prime\prime}$','%','Subtransient reactance on the own base; the load flow disables the machine internal impedance'
'xqpp_pct',       '$x_{q}^{\prime\prime}$','%','Quadrature subtransient reactance, missing from the dataset'
'H_MWs_per_MVA',  '$H$',  'MW s/MVA','Inertia constant, missing and needed only by a dynamic study'
'Td0p_s',         '$T_{d0}^{\prime}$','s','Open-circuit transient time constant, missing from the dataset'
'Loading_pct',    '$\lambda$', '%',   'Loading against the branch rating, NaN where no rating is documented'
'Loading_pct_lowest_stage','$\lambda_{\mathrm{ONAN}}$','%','Loading against the lowest, unforced cooling stage: the number that carries the GSUT and UAT overloads'
'Loading_pct_highest_stage','$\lambda_{\max}$','%','Loading against the highest cooling stage'
'PowerFactor',    '$\cos\varphi$','-','Power factor at the generator terminal'
'pf',             '$\cos\varphi$','-','Nameplate power factor, lagging'
'Share',          '$\alpha$',  '-',   'Fraction of the total auxiliary load allocated to this node'
'Iterations',     '$n_{\mathrm{it}}$','-','Newton iterations the solver needed, two in every case'
'Alloc_kW',       '$P_{\mathrm{alloc}}$','kW','Allocation figure the load split is taken from; a ratio only, so its sum is not the plant load'
'Tap_used',       '$n_{\mathrm{tap}}$','-','Tap position the model is set to'
'Merged_into',    '$\mathrm{merged}$','','Representative bus this one collapses into over a zero-impedance tie; such a row reports NaN injection by design'
'Model_included', '$\mathrm{in\,model}$','','True when the item is in the Simulink model; the GAT is switched by the case flag GAT_in instead of by this'
'Verdict',        '$\mathrm{Verdict}$','','Study verdict for the case: OK, or the non-convergence message'
};
end

% =====================================================================
function T = full_map()
%FULL_MAP  The catalogue as a table, sorted by name, with both renderings.
C  = catalogue();
lx = strings(size(C,1), 1);
hm = lx;
for i = 1:size(C,1)
    q     = pack(C{i,1}, C{i,2}, C{i,3}, C{i,4});
    lx(i) = string(q.latex);
    hm(i) = string(q.html);
end
T = table(string(C(:,1)), lx, hm, string(C(:,3)), string(C(:,4)), ...
    'VariableNames', {'Name', 'LaTeX', 'HTML', 'Units', 'Description'});
T = sortrows(T, 'Name');
end

% =====================================================================
function s = pack(name, latex, units, desc)
%PACK  Assemble the return struct. The MathJax form is derived from the LaTeX
%   one rather than stored twice, so the two can never disagree.
lx = char(latex);
if isempty(lx)
    hm = '';
else
    hm = ['\(' strrep(lx, '$', '') '\)'];
end
s = struct('name', char(name), 'latex', lx, 'html', hm, ...
           'units', char(units), 'desc', char(desc));
end

% =====================================================================
function s = infer(name)
%INFER  Last resort for a name the catalogue does not carry. Because every
%   register field names its unit in the field itself, the unit is usually
%   still recoverable even when the quantity is unknown here.
tok = strsplit(name, '_');
tok = tok(~cellfun(@isempty, tok));
if isempty(tok)
    s = pack(name, '', '', 'Empty quantity name, so no symbol is available.');
    return
end
[u, iu] = unit_of(tok);
sub = tok(setdiff(2:numel(tok), iu));
tex = head_symbol(tok{1});
if ~isempty(sub)
    tex = ['$' strrep(tex, '$', '') '_{\mathrm{' ...
           escape_tex(strjoin(sub, ',')) '}}$'];
end
if isempty(u)
    g = 'Not in the symbol catalogue: name shown as written, unit unknown.';
else
    g = sprintf(['Not in the symbol catalogue: unit %s read from the ' ...
                 'name suffix.'], u);
end
s = pack(name, tex, u, g);
end

% =====================================================================
function [u, iu] = unit_of(tok)
%UNIT_OF  Scan the name tokens from the right for a unit token. Right to left
%   because the unit is a suffix, and because V_230kV_pu and
%   Loading_pct_458MVA_50C both contain an earlier token that looks like a unit
%   but belongs to the quantity name. MVAr is tested before MVA before MW.
D = { 'MVAr','MVAr'; 'MVA','MVA'; 'MW','MW'; 'kVA','kVA'; 'kW','kW'
      'kV','kV';     'kA','kA';   'pu','pu'; 'pct','%';   'deg','deg'
      'Hz','Hz';     'ohm','ohm'; 'barg','barg'; 'km','km'
      'V','V';       'A','A';     'H','H';   'F','F';     's','s' };
u  = '';
iu = 0;
for i = numel(tok):-1:1
    j = find(strcmpi(D(:,1), tok{i}), 1);
    if ~isempty(j)
        u  = D{j,2};
        iu = i;
        return
    end
end
end

% =====================================================================
function tex = head_symbol(h)
%HEAD_SYMBOL  Symbol for the leading token. Handles the compound heads the
%   registers use (Vnom, Vbase, Sbase, Snom, Smax, Qmin, Qmax, Isc, Inom) and
%   the letter-plus-index ones (Rm, R1, L0, Z0, xd, xq, x2, Ra), so none of
%   those needs a catalogue row of its own.
m = regexp(h, '^([A-Za-z])(nom|base|set|min|max|rat|sc|inj|tot)$', ...
           'tokens', 'once');
if ~isempty(m)
    if any(strcmp(m{2}, {'min', 'max'}))
        tex = ['$' m{1} '_{\' m{2} '}$'];
    else
        tex = ['$' m{1} '_{\mathrm{' m{2} '}}$'];
    end
    return
end
m = regexp(h, '^([A-Za-z])([0-9a-z])$', 'tokens', 'once');
if ~isempty(m)
    tex = ['$' m{1} '_{' m{2} '}$'];
    return
end
if numel(h) == 1 && isletter(h)
    tex = ['$' h '$'];
    return
end
tex = ['$\mathrm{' escape_tex(h) '}$'];
end

% =====================================================================
function t = escape_tex(x)
%ESCAPE_TEX  Make arbitrary text safe inside a math-mode \mathrm{}: a word gap
%   becomes a thin space, because a plain space collapses in math mode and an
%   underscore would be read as a subscript.
t = regexprep(char(x), '[^A-Za-z0-9.,]+', '\\,');
t = regexprep(t, '^(\\,)+|(\\,)+$', '');
if isempty(t), t = '?'; end
end
