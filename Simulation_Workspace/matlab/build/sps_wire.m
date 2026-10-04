function varargout = sps_wire(varargin)
%SPS_WIRE  Helpers for building a Specialized Power Systems model in code.
%
%   Usage (dispatch on the first argument, a command string):
%
%     sps_wire('reset')
%            Reset the annotation name counter. Call once per model build.
%
%     blk  = sps_wire('add', mdl, libpath, name, pos, orientation)
%            Add a block. POS is [left top right bottom]. ORIENTATION is
%            'right' (default), 'left', 'up' or 'down'.
%
%     h    = sps_wire('port', blk, side)
%            Return the 1x3 array of physical port handles on SIDE, which is
%            'L' or 'R'. For an orientation of 'down' the L ports are on top
%            and the R ports on the bottom; the labels L and R refer to the
%            block's own winding order, not to the screen.
%
%     sps_wire('link', mdl, srcHandles, dstHandles)
%     sps_wire('link', mdl, srcHandles, dstHandles, ytier)
%            Draw the three phase lines between two 1x3 port-handle arrays.
%            Blocks in one column are joined by single straight segments;
%            blocks on one busbar are joined by a three-segment orthogonal
%            path whose long run lies on the bar. YTIER names that bar and is
%            inferred when the two ports sit on it; pass it for a tap that
%            comes up from a lower tier, such as a load feeder.
%
%     an   = sps_wire('note', mdl, text, pos, fontsize, weight)
%     an   = sps_wire('note', mdl, text, pos, fontsize, weight, colour)
%            Add a text annotation. POS is [left top right bottom]. COLOUR
%            sets the text colour and may be a name or an RGB-triplet string.
%
%     an   = sps_wire('bar', mdl, pos)
%     an   = sps_wire('bar', mdl, pos, colour)
%            Draw a busbar as a thin filled rectangle, black unless COLOUR is
%            given. POS is [left top right bottom].
%
%     an   = sps_wire('panel', mdl, pos, fill)
%            Draw a filled rectangular ZONE PANEL in colour FILL. Used to
%            shade the background of a functional area of the one-line, the way
%            the plant drawing boxes its ISOLATED PHASE BUSBARS and WATER
%            INTAKE AREA. See the case body for the z-order rule: every panel
%            must be created BEFORE the blocks it sits behind.
%
%   WHY PORT HANDLES AND NOT 'blk/1' STRINGS
%   ----------------------------------------
%   Specialized Power Systems three-phase blocks expose their terminals as
%   LConn/RConn physical connection ports, not as ordinary Simulink in/out
%   ports, so the 'block/portnumber' string form of add_line does not address
%   them. Handles from get_param(blk,'PortHandles') do.
%
%   HOW A BUSBAR NODE IS MADE
%   -------------------------
%   Verified empirically (matlab/env/probe_ports.m): a single SPS physical
%   port accepts MORE THAN ONE line. A busbar with N connections is therefore
%   built by designating one device's port trio as the node and linking every
%   other device to it. No junction block is needed and none exists in SPS.

persistent noteCount
if isempty(noteCount), noteCount = 0; end

cmd = varargin{1};
switch lower(cmd)

    case 'reset'
        noteCount = 0;

    case 'add'
        % ORDER MATTERS, AND IT IS NOT OBVIOUS.
        % Setting Orientation to 'up' or 'down' rotates the block 90 degrees
        % about its centre, which SWAPS its width and height. Do it after
        % Position and the box comes out transposed: a requested
        % [420 240 500 340] (80 wide, 100 tall) becomes [410 250 510 330]
        % (100 wide, 80 tall). That is not cosmetic. Port spacing is a
        % function of the extent of the edge the ports sit on, so a
        % transposed transformer puts its port trio at cx+-35 while a
        % transposed breaker puts its at cx+-30, and the three phase wires
        % between them fan out instead of running parallel.
        % So: orientate first, then position, then CHECK. POS is always the
        % final on-screen box.
        [mdl, libpath, name, pos] = deal(varargin{2}, varargin{3}, varargin{4}, varargin{5});
        if nargin >= 6, orient = varargin{6}; else, orient = 'right'; end
        blk = [mdl '/' name];
        add_block(libpath, blk);
        set_param(blk, 'Orientation', orient);
        set_param(blk, 'Position', pos);
        % Hide the printed block name. Simulink puts it below a 'right' block
        % and BESIDE a rotated one, where it lands on top of the caption
        % annotation that carries the real plant tag and ratings - measured:
        % "GSUT 10BAT10" printed across its own data note. Every block in this
        % model is captioned by an annotation whose position we control, so the
        % printed name adds nothing but collisions. The block name itself is
        % unchanged and still addresses the block from code.
        set_param(blk, 'ShowName', 'off');
        got = get_param(blk, 'Position');
        if ~isequal(got(:)', pos(:)')
            error('sps_wire:position', ...
                ['Block %s would not take its Position: asked for [%s], got ', ...
                 '[%s] at orientation ''%s''. Positions must be exact or the ', ...
                 'port trios stop lining up and the one-line becomes ', ...
                 'unreadable.'], blk, num2str(pos), num2str(got), orient);
        end
        varargout{1} = blk;

    case 'setopt'
        % Set a COSMETIC parameter only if this block version has it.
        % Used for things like 'Measurements','None' whose absence must not
        % abort a build. Never use this for an electrical parameter: a
        % silently skipped impedance is exactly the failure this project
        % cannot tolerate.
        [blk, name, val] = deal(varargin{2}, varargin{3}, varargin{4});
        if isfield(get_param(blk, 'DialogParameters'), name)
            set_param(blk, name, val);
            varargout{1} = true;
        else
            varargout{1} = false;
        end

    case 'port'
        [blk, side] = deal(varargin{2}, varargin{3});
        ph = get_param(blk, 'PortHandles');
        switch upper(side)
            case 'L', h = ph.LConn;
            case 'R', h = ph.RConn;
            otherwise
                error('sps_wire:side','Side must be ''L'' or ''R'', got ''%s''.', side);
        end
        if numel(h) ~= 3
            error('sps_wire:portCount', ...
                ['Block %s side %s has %d physical ports, expected 3. This is ', ...
                 'not a three-phase terminal.'], blk, side, numel(h));
        end
        varargout{1} = h;

    case 'link'
        % sps_wire('link', mdl, a, b)          - infer the busbar tier
        % sps_wire('link', mdl, a, b, ytier)   - route along tier YTIER
        %
        % ROUTING, AND WHY IT IS DONE BY HAND
        % -----------------------------------
        % add_line's autorouter is a dataflow router: it makes a line leave
        % every port PERPENDICULAR to the block edge, then works around
        % obstacles. For a one-line diagram that is the wrong instinct. Two
        % devices sitting on the same busbar have to be joined by a wire that
        % runs ALONG the bar, but the router insists on leaving each port
        % vertically first, so it produced five-segment paths that climbed
        % above the bar, crossed the page and came back down - measured in
        % matlab/env/probe_line_points.m:
        %
        %     [275 185; 275 180; 560 180; 560 220; 575 220; 575 204]
        %
        % Those wandering rectangles above the 230 kV and 22 kV bars, and the
        % apparent strike-through of their captions, were all this one effect.
        %
        % set_param(line,'Points',...) overrides the router and does NOT break
        % the netlist (probe_bus_route.m: 6 of 6 lines kept both a source and a
        % destination port). Simulink appends one snap point if the last point
        % is not exactly on the port, and leaves the shape otherwise intact.
        % So each connection is drawn as one of two deliberate shapes:
        %
        %   same column (|dx| = 0)  ->  plain add_line, ONE straight segment.
        %       Verified: [275 295; 275 316]. This is the vertical drop from a
        %       busbar into a transformer, and it needs no help.
        %
        %   different columns       ->  forced [port; (port_x, tier);
        %                                       (other_x, tier); other port]
        %       Three segments, fully orthogonal, and the long middle one lies
        %       exactly ON the tier - so it is drawn inside the 6-unit black
        %       busbar and disappears into it. What the reader sees is two
        %       short stubs touching a bus, which is the correct one-line
        %       symbol for "both of these are connected to this bus".
        %
        % No diagonals: forcing only the two endpoints DOES draw a diagonal
        % (probe_line_points.m), which no power one-line uses.
        [mdl, a, b] = deal(varargin{2}, varargin{3}, varargin{4});
        if nargin >= 5, ytier = varargin{5}; else, ytier = []; end
        if numel(a) ~= 3 || numel(b) ~= 3
            error('sps_wire:linkCount', ...
                'Both ends must be 3 port handles; got %d and %d.', numel(a), numel(b));
        end
        for k = 1:3
            pa = get_param(a(k), 'Position');
            pb = get_param(b(k), 'Position');
            if abs(pa(1) - pb(1)) < 1
                add_line(mdl, a(k), b(k));
                continue
            end
            if isempty(ytier), y = bus_tier(pa, pb); else, y = ytier; end
            h  = add_line(mdl, a(k), b(k), 'autorouting', 'on');
            % Re-read the ports: connecting a line lengthens the port stub, so
            % the reported Position moves (measured: 4 units outside the block
            % edge unconnected, 15 connected). Forcing points computed from the
            % pre-connection coordinates would leave a visible kink.
            qa = get_param(a(k), 'Position');
            qb = get_param(b(k), 'Position');
            set_param(h, 'Points', [qa; qa(1) y; qb(1) y; qb]);
        end

    case 'note'
        % Annotations are named objects, so each one needs a unique name or
        % the second call silently overwrites the first.
        noteCount = noteCount + 1;
        [mdl, txt, pos] = deal(varargin{2}, varargin{3}, varargin{4});
        if nargin >= 5, fs = varargin{5}; else, fs = 12; end
        if nargin >= 6, wt = varargin{6}; else, wt = 'normal'; end
        if nargin >= 7, fg = varargin{7}; else, fg = ''; end
        % Simulink.Annotation takes name/value pairs after the path, so the
        % two-argument (path, text) form does NOT set the text - it fails
        % with "Not enough input arguments". Construct, then assign.
        an = Simulink.Annotation(sprintf('%s/note%03d', mdl, noteCount));
        an.Text       = txt;
        an.Position   = pos;
        an.FontSize   = fs;
        an.FontWeight = wt;
        an.HorizontalAlignment = 'left';
        if ~isempty(fg), an.ForegroundColor = fg; end
        % Transparent, so a caption can never blank out a busbar or a wire it
        % happens to overhang. Simulink auto-fits an annotation's right and
        % bottom edges to its text, so its true extent is not knowable in
        % advance; with an opaque background that means an unpredictable white
        % hole in the diagram - measured as a gap punched through the 230 kV
        % BUS 2 bar by the GAT bay breaker caption.
        % 'transparent' is the accepted spelling in R2024a; 'none' is rejected,
        % and the default is an opaque 'white'.
        an.BackgroundColor = 'transparent';
        varargout{1} = an;

    case 'bar'
        % A busbar, drawn as a thin filled rectangle. This is the correct
        % one-line symbol: the model carries three phase wires per bus, the
        % diagram carries one bus symbol.
        %
        % Specialized Power Systems has no busbar block, so the bar is an
        % annotation. Simulink AUTO-FITS an annotation to its text and silently
        % ignores Position unless BOTH FixedWidth and FixedHeight are on -
        % measured in matlab/env/probe_export.m, where a requested
        % [200 400 600 407] came back as [200 400 204 415] with them off and
        % verbatim with them on. Order matters: set the two flags first, then
        % Position.
        %
        % The text is a single space. An annotation with genuinely empty text
        % is discarded, and any visible character would print on top of the
        % bar; a space gives a named, persistent object that renders as
        % nothing but its own background.
        noteCount = noteCount + 1;
        [mdl, pos] = deal(varargin{2}, varargin{3});
        if nargin >= 4, col = varargin{4}; else, col = 'black'; end
        an = Simulink.Annotation(sprintf('%s/bar%03d', mdl, noteCount));
        an.Text            = ' ';
        an.FixedWidth      = 'on';
        an.FixedHeight     = 'on';
        an.Position        = pos;
        an.BackgroundColor = col;
        an.ForegroundColor = col;
        if ~isequal(an.Position, pos)
            error('sps_wire:barPosition', ...
                ['Busbar annotation would not take its Position: asked for ', ...
                 '[%s], got [%s]. The FixedWidth/FixedHeight mechanism has ', ...
                 'changed in this MATLAB release - re-measure before building, ', ...
                 'because without it the bar is drawn at text size and the ', ...
                 'diagram silently loses its busbars.'], ...
                num2str(pos), num2str(an.Position));
        end
        varargout{1} = an;

    case 'panel'
        % A ZONE PANEL: a large filled rectangle shading the background of one
        % functional area, so that GENERATION, the 230 kV SWITCHYARD,
        % TRANSFORMATION and the AUXILIARY SYSTEM read as blocks of the page
        % rather than as a uniform scatter of symbols. The plant drawing does
        % the same thing with dashed boxes around its isolated phase busbars,
        % its Siemens LV system and its water intake area.
        %
        % It is built the same way as a busbar - FixedWidth/FixedHeight then
        % Position, text a single space - because Simulink offers nothing else.
        % Simulink.Annotation has NO BorderColor and NO BorderWidth, and
        % AnnotationType is READ-ONLY, so the canvas's own resizable "Area"
        % object cannot be created from code at all: every attempt with
        % 'area_annotation', 'area', 'note_annotation' or 'image_annotation'
        % fails with "annotation parameter 'AnnotationType' is read-only"
        % (measured, matlab/env/probe_area.m). A filled panel is what is left,
        % and it is enough.
        %
        % Z-ORDER - THE RULE THAT MAKES THIS SAFE, AND IT IS INVERTED
        % -----------------------------------------------------------
        % Among ANNOTATIONS the one created FIRST renders ON TOP. That is the
        % opposite of the obvious guess, and it was measured the hard way:
        % find_system(...,'Type','annotation') returns handles in REVERSE
        % creation order and the print path draws them in that order, so the
        % last handle - the first created - is painted last, i.e. on top.
        %
        % An earlier version of this comment claimed the reverse, and the panels
        % were duly created FIRST "so they would sit behind everything". The
        % export showed them painted OVER the busbars and captions instead: the
        % 230 kV BUS 1 bar was chopped off at exactly the switchyard panel's left
        % edge, the 22 kV and 6.6 kV bars vanished, and the GAT, G1 and GSUT
        % captions were clipped where they straddled a panel edge. So every panel
        % must be laid down LAST, after every block, busbar and caption - see the
        % end of the layout section in build_ashuganj_main.m. Create one early
        % and it will erase the zone it was meant to frame.
        %
        % Blocks and signal lines are a SEPARATE, HIGHER layer drawn above ALL
        % annotations whatever their creation order, so drawing the panels last
        % hides no equipment. Verified by re-export, not assumed.
        noteCount = noteCount + 1;
        [mdl, pos, fill] = deal(varargin{2}, varargin{3}, varargin{4});
        an = Simulink.Annotation(sprintf('%s/panel%03d', mdl, noteCount));
        an.Text            = ' ';
        an.FixedWidth      = 'on';
        an.FixedHeight     = 'on';
        an.Position        = pos;
        an.BackgroundColor = fill;
        an.ForegroundColor = fill;
        if ~isequal(an.Position, pos)
            error('sps_wire:panelPosition', ...
                ['Zone panel would not take its Position: asked for [%s], got ', ...
                 '[%s].'], num2str(pos), num2str(an.Position));
        end
        varargout{1} = an;

    otherwise
        error('sps_wire:cmd','Unknown command ''%s''.', cmd);
end
end

% =====================================================================
function y = bus_tier(pa, pb)
%BUS_TIER  Which busbar tier do these two ports share?
%
%   A port reports its Position OUTSIDE the block edge it sits on, so the
%   midpoint of two ports on one bus is not always the bus tier itself:
%
%     ports facing each other (one block above the bar, one below)
%         y = 196 and 204 about tier 200  ->  midpoint 200, exact
%     ports facing the SAME way (both blocks hanging below the bar, as the
%     GSUT and the bus coupler both do on 230 kV BUS 1)
%         y = 236 and 236 about tier 240  ->  midpoint 236, one offset high
%
%   So the midpoint is SNAPPED to the nearest tier declared in sps_geom rather
%   than used directly. If it does not land near exactly one tier the build
%   stops: that means the two ports are not on a common busbar and the caller
%   has to say which tier the run belongs to, because guessing it would draw a
%   wire along a line that is not a bus.
%
%   The tolerance has to be at least 15, because that is how far outside the
%   block edge a CONNECTED port reports itself, and a pair of ports both facing
%   the same way is offset by the full 15. But the 22 kV bus and 230 kV BUS 2
%   sit only 20 apart, so a 16-unit window can in principle touch both. Rather
%   than widen or narrow the window and hope, a midpoint that falls inside two
%   windows is resolved to the CLEARLY nearer tier and rejected outright if
%   neither is clearly nearer. Every link in the present model resolves with a
%   margin of 85 units or more, so this is a guard against future edits, not a
%   crutch for the current layout.
g = sps_geom();
tiers = [g.tier.bus1, g.tier.bus2, g.tier.b22, g.tier.bus66];
names = {'230 kV BUS 1', '230 kV BUS 2', '22 kV GEN BUS', '6.6 kV MV BUS'};
mid   = (pa(2) + pb(2)) / 2;
d     = abs(tiers - mid);
near  = find(d <= 16);
if isempty(near)
    [dmin, imin] = min(d);
    error('sps_wire:noTier', ...
        ['Cannot tell which busbar joins the ports at y = %g and y = %g ', ...
         '(midpoint %g). The nearest declared tier is %s at y = %g, %g ', ...
         'units away. Pass the tier explicitly: ', ...
         'sps_wire(''link'', mdl, a, b, ytier).'], ...
        pa(2), pb(2), mid, names{imin}, tiers(imin), dmin);
end
if numel(near) > 1
    [ds, order] = sort(d(near));
    if ds(2) - ds(1) < 6
        error('sps_wire:ambiguousTier', ...
            ['The ports at y = %g and y = %g (midpoint %g) are %g units from ', ...
             '%s and %g units from %s. The busbar they share is ambiguous, and ', ...
             'a wire drawn along the wrong one would connect the wrong bus. ', ...
             'Separate the tiers in sps_geom or pass the tier explicitly.'], ...
            pa(2), pb(2), mid, ds(1), names{near(order(1))}, ...
            ds(2), names{near(order(2))});
    end
    near = near(order(1));
end
y = tiers(near);
end
