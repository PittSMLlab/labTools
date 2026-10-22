function regressionDirectRun(name, mode, baseDir)
%REGRESSIONDIRECTRUN Direct before/after check for code the gate skips.
%
%   REGRESSIONDIRECTRUN(name, mode, baseDir) runs the synthetic-input
% cases of one function family and either saves the results
% ('baseline', run on the reference tree) or compares them with the
% saved ones ('compare'). Add a local direct<Name> function for new
% cases. Each
% case records the outputs, the error identifier and message, and the
% last warning (identifier and text), so frozen warning/error text is
% compared too. Figure cases record a property snapshot of every
% graphics object. Errors when any case differs.
%
% Inputs:
%   name    - char, 'ConditionsThatMatch', 'Correlations' or
%             'NanJackKnife'
%   mode    - char, 'baseline' or 'compare'
%   baseDir - char, folder for the MAT files
%
% Outputs:
%   none (prints one line per case; errors on any difference)
%
% Toolbox Dependencies: Statistics and Machine Learning Toolbox
% (Correlations)
%
% See also REGRESSIONSTRICTCHECK, REGRESSIONALL.

warning('off', 'backtrace');
set(groot, 'DefaultFigureVisible', 'off');
restore = onCleanup(@() set(groot, 'DefaultFigureVisible', 'on'));
cases = feval(['direct' name]);
file  = fullfile(baseDir, ['direct_' name '.mat']);
switch mode
    case 'baseline'
        save(file, 'cases');
        fprintf('DIRECT %s baseline saved: %d cases\n', name, ...
            numel(cases));
    case 'compare'
        ref  = load(file);
        nBad = 0;
        assert(numel(ref.cases) == numel(cases), 'case count differs');
        for ii = 1:numel(cases)
            same = isequaln(ref.cases(ii), cases(ii));
            if ~same
                nBad = nBad + 1;
                fprintf('DIRECT %s case %d (%s) DIFFERS\n', name, ii, ...
                    cases(ii).label);
            end
        end
        fprintf('DIRECT %s: %d of %d cases differ\n', name, nBad, ...
            numel(cases));
        if nBad > 0
            error('regressionDirectRun:changed', 'Direct %s failed.', name);
        end
end
end

function cases = directConditionsThatMatch()
%DIRECTCONDITIONSTHATMATCH getConditionsThatMatch(V2) on fake metadata.
names = {'TM base', 'OG base', 'Adaptation', 'TR post', '', ...
    'NIM catch', 'TM short'};
m = experimentMetaData('X', labDate.default, 'e', '', names, ...
    repmat({''}, 1, 7), num2cell(1:7), 7);
calls = {
    {'base'}
    {'base', 'TM'}
    {'base', 'OG'}
    {'adapt', 'TM'}
    {'post', 'TM'}
    {'post', 'NIM'}
    {'catch', 'NIM'}
    {'zzz', 'NIM'}
    {'zzz', 'TM'}
    {'zzz', 'OG'}
    {'base', 5}
    {'post', []}
    {'zzz'}
    {'short'}
    {5}
    {''}
    {'tm', 'tm'}
    {'awsdfasdas', 'TM'}
    };
cases = struct('label', {}, 'v1', {}, 'v2', {});
for ii = 1:numel(calls)
    a = calls{ii};
    cases(ii).label = sprintf('call %d', ii);
    cases(ii).v1 = capture(@() m.getConditionsThatMatch(a{:}));
    cases(ii).v2 = capture(@() m.getConditionsThatMatchV2(a{:}));
end
% an object whose names are all empty
m2 = experimentMetaData('Y', labDate.default, 'e', '', {'', 'Zed'}, ...
    {'', ''}, {1, 2}, 2);
cases(end+1).label = 'all empty';
cases(end).v1 = capture(@() m2.getConditionsThatMatch('a', 'TM'));
cases(end).v2 = capture(@() m2.getConditionsThatMatchV2('a', 'TM'));
end

function cases = directNanJackKnife()
%DIRECTNANJACKKNIFE nanJackKnife for nargin 3 to 7, plus invalid nargin.
x = 1:6;
y = [1 2 NaN 4 5 6];
E = [0.5 0.4 0.3 0.2 0.1 0.6];
L = y - E;
U = y + 2 * E;
col = [0.8 0.2 0.1];
pat = [0.9 0.9 0.5];
w   = [1 0 1 0 1 0];
args = {
    {x, y, E}
    {x, y, L, U}
    {x, y, E, col, pat}
    {x, y, E, col, pat, 0.4}
    {x, y, E, col, pat, 0.4, w}
    {x, y, zeros(1, 6)}
    {x, y, y, y}
    {x, y, zeros(1, 6), col, pat, 0.5, w}
    {x, y}
    {x, y, E, col, pat, 0.4, w, 9}
    {x, y, E, 'r', pat}
    };
cases = struct('label', {}, 'out', {});
for ii = 1:numel(args)
    cases(ii).label = sprintf('args %d', ii);
    a = args{ii};
    cases(ii).out = capture(@() figCall(@nanJackKnife, a));
end
end

function out = figCall(fcn, a)
%FIGCALL Run fcn in a fresh invisible figure and snapshot the result.
before  = findall(groot, 'Type', 'figure');
cleanup = onCleanup(@() closeNew(before));
figure();
[pa, li] = fcn(a{:});
out.pa   = snapshot(pa);
out.li   = snapshot(li);
out.snap = snapshotNew(before);
end

function cases = directCorrelations()
%DIRECTCORRELATIONS adaptationData.Correlations, types 1 and 2.
rng(7);
conds  = {'c1', 'c2', 'c3'};
params = {'pA', 'pB', 'pC'};
groups = {'g1', 'g2'};
results = struct();
for cc = 1:numel(conds)
    for pp = 1:numel(params)
        n = 12;
        results.(conds{cc}).indiv.(params{pp}) = ...
            [repmat([1; 2], n / 2, 1), randn(n, 1) + cc + pp];
    end
end
results.c3.indiv.pB(2, 2) = NaN;
colors = [0.9 0.1 0.1; 0.1 0.1 0.9; 0.1 0.8 0.1];
calls = {
    {[], results, params, conds, groups, colors, 1}
    {[], results, params, conds, groups, colors, 2}
    {[], results, params(1:2), conds, groups, [], 1}
    {[], results, params(1:2), conds, groups, colors, 2}
    {[], results, params, conds(1:2), groups, colors, 2}
    {[], results, params, conds, groups, colors, 3}
    };
cases = struct('label', {}, 'out', {});
for ii = 1:numel(calls)
    cases(ii).label = sprintf('call %d', ii);
    a = calls{ii};
    cases(ii).out = capture(@() corrCall(a));
end
end

function out = corrCall(a)
%CORRCALL Run Correlations in a fresh invisible figure and snapshot it.
before  = findall(groot, 'Type', 'figure');
cleanup = onCleanup(@() closeNew(before));
figure();
adaptationData.Correlations(a{:});
out.snap     = snapshotNew(before);
out.renderer = get(gcf, 'Renderer');
end

function snap = snapshotNew(before)
%SNAPSHOTNEW Snapshot of every figure created since BEFORE.
figs = setdiff(findall(groot, 'Type', 'figure'), before);
snap = {};
for ff = 1:numel(figs)
    snap = [snap, snapshot(findall(figs(ff)))]; %#ok<AGROW>
end
end

function closeNew(before)
%CLOSENEW Close every figure created since BEFORE.
close(setdiff(findall(groot, 'Type', 'figure'), before));
end

function res = capture(fcn)
%CAPTURE Outputs, error id/message and last warning of fcn().
lastwarn('');
res = struct('out', [], 'errId', '', 'errMsg', '', 'warnId', '', ...
    'warnMsg', '');
try
    res.out = fcn();
catch err
    res.errId  = err.identifier;
    res.errMsg = err.message;
end
[res.warnMsg, res.warnId] = lastwarn();
end

function snap = snapshot(h)
%SNAPSHOT Property snapshot of graphics objects, in handle order.
snap = {};
props = struct( ...
    'axes', {{'XLim', 'YLim', 'Position', 'XDir', 'YDir', ...
        'FontSize', 'DataAspectRatio', 'PlotBoxAspectRatio'}}, ...
    'line', {{'XData', 'YData', 'Color', 'Marker', 'MarkerSize', ...
        'LineStyle', 'LineWidth', 'MarkerFaceColor', ...
        'MarkerEdgeColor'}}, ...
    'patch', {{'XData', 'YData', 'FaceColor', 'EdgeColor', ...
        'FaceAlpha', 'LineStyle', 'LineWidth'}}, ...
    'text', {{'String', 'Position', 'FontSize'}}, ...
    'legend', {{'String'}});
for ii = 1:numel(h)
    if ~isgraphics(h(ii))
        continue
    end
    typ = get(h(ii), 'Type');
    if ~isfield(props, typ)
        continue
    end
    rec = struct('type', typ);
    for pp = props.(typ)
        % auto-placed title and axis labels move by ~1e-3 with the
        % renderer's font metrics; their strings are still compared
        if strcmp(typ, 'text') && strcmp(pp{1}, 'Position') && ...
                isAxisLabel(h(ii))
            continue
        end
        rec.(pp{1}) = get(h(ii), pp{1});
    end
    if strcmp(typ, 'axes')
        rec.title  = get(get(h(ii), 'Title'), 'String');
        rec.xlabel = get(get(h(ii), 'XLabel'), 'String');
        rec.ylabel = get(get(h(ii), 'YLabel'), 'String');
    end
    snap{end+1} = rec; %#ok<AGROW>
end
end

function tf = isAxisLabel(txt)
%ISAXISLABEL True for the title and axis labels of the parent axes.
ax = ancestor(txt, 'axes');
tf = ~isempty(ax) && any(txt == [ax.Title, ax.XLabel, ax.YLabel, ...
    ax.ZLabel]);
end
