function fig = plotSnippets(times, snippets, yLabels, titles, ...
    id, trialNum, options)
%PLOTSNIPPETS Plot H-reflex snippets with GRFs if available.
%
%   Plot the H-reflex snippets for desired muscles or forces (if desired)
% with the window bounds for M-wave and H-wave indicated by vertical lines.
% A leg with no snippets (i.e., a leg that was not stimulated) is skipped
% rather than plot as an empty tile. When pathFig is nonempty, also writes
% <id>_HreflexSnippets_Trial<n> as .fig and .png there, silently
% overwriting existing files (see DATA_OUTPUTS.md).
%
% Inputs:
%   times    - number of samples x 1 array of time in seconds with 0
%              indicating the identified stimulation artifact peak
%   snippets - 2 x 3 cell of number of snippets x number of samples
%              arrays for right (row 1) and left (row 2) leg H-reflex
%              (col 1), ipsilateral (col 2), and contralateral (col 3)
%              GRF snippets
%   yLabels  - N x 1 cell array of y-axis label strings for each tile
%   titles   - N x 1 cell array of title strings for each tile
%   id       - string or character array of participant/session ID
%   trialNum - string or character array of the trial number
%
% Optional Name-Value Inputs:
%   pathFig - path for saving figures; not saved if empty (default: '')
%
% Outputs:
%   fig - handle to the figure generated
%
% Toolbox Dependencies:
%   None
%
% See also HREFLEX.EXTRACTSNIPPETS, HREFLEX.COMPUTEAMPLITUDES.

% TODO: adapt this function to work for generating any snippets plot

arguments
    times    (:,1) double
    snippets (2,3) cell
    yLabels  cell
    titles   cell
    id       (1,:) {mustBeText}
    trialNum (1,:) {mustBeText}
    options.pathFig (1,:) char = ''
end

%% Validate Input Dimensions
% NOTE: an empty cell is a leg that was not stimulated, so its (absent)
% sample count must not be compared against the snippet time vector
isPresent    = ~cellfun(@isempty, snippets);
numSnipSamps = cellfun(@(x) size(x, 2), snippets);
numSnipSamps = reshape(numSnipSamps(isPresent), 1, []);
numUniqueSampleCounts = length(unique([numSnipSamps length(times)]));
if numUniqueSampleCounts > 1    % if sample counts differ across arrays, ...
    error('There are different numbers of samples across arrays.');
end

% tile order is fixed: right GRFs, left GRFs, right EMG, left EMG, and
% titles and y-axis labels are indexed by that fixed position so that a
% leg without data can be skipped without renumbering the tiles that remain
if length(titles) < 4 || length(yLabels) < 4
    error('Mismatch between the number of tiles, titles, or yLabels.');
end

%% Determine Which Tiles Have Data
hasGRF = false(1, 2);
hasEMG = false(1, 2);
for leg = 1:2                   % for right and left leg, ...
    hasGRF(leg) = isPresent(leg, 2) && isPresent(leg, 3);
    hasEMG(leg) = isPresent(leg, 1);
end
if ~any(hasEMG)                 % if no leg has H-reflex snippets, ...
    error('There are no H-reflex snippets to plot.');
end
numTiles = sum(hasGRF) + sum(hasEMG);

%% Create Figure
fig = figure;
tl = tiledlayout(numTiles, 1, 'TileSpacing', 'tight', 'Padding', 'compact');

%% Plot GRF Tiles
% NOTE: assuming inputs in desired plot order from top to bottom
% check for force data (columns 2 & 3) and plot combined GRFs if available
for leg = 1:2                   % for right and left leg, ...
    if ~hasGRF(leg)             % if no GRF data for this leg, ...
        continue;               % advance to next leg
    end
    nexttile;                   % plot ipsilateral and contralateral GRFs
    hold on;
    plot(times, snippets{leg,2}, 'LineWidth', 1.5, ...
        'Color', [0.000 0.447 0.741]);
    plot(times, snippets{leg,3}, 'LineWidth', 1.5, ...
        'Color', [0.850 0.325 0.098]);
    title(titles{leg});
    ylabel(yLabels{leg});
    xlim([times(1) times(end)]);
    hold off;
end

%% Plot EMG Tiles
ax = gobjects(1, sum(hasEMG));  % initialize array of Axes objects
numAxes = 0;                % number of EMG tiles created so far
% TODO: move y-axis limit code outside this function or make optional input
% (e.g., which index to start from) for more flexibility
indsYLims = times > 0.005;
ymin = 0;                   % initialize minimum y-axis value to be 0
ymax = 0;
for leg = 1:2               % for each EMG H-reflex snippets array, ...
    if ~hasEMG(leg)         % if no snippets for this leg, ...
        continue;           % advance to next leg
    end
    numAxes = numAxes + 1;
    ax(numAxes) = nexttile; % advance to next figure tile
    hold on;
    xline(0, 'k', 'LineWidth', 2);  % stimulation artifact alignment
    % M-wave and H-wave range
    % TODO: update to accept as function input rather than hard-coding
    xline(0.0045, 'b', 'LineWidth', 1.5);  % M-wave start: 4.5 ms after stim
    xline(0.0200, 'b', 'LineWidth', 1.5);  % M-wave end: 20 ms after stim
    xline(0.0250, 'g', 'LineWidth', 1.5);  % H-wave start: 25 ms after stim
    xline(0.0450, 'g', 'LineWidth', 1.5);  % H-wave end: 45 ms after stim
    plot(times, snippets{leg,1}, 'LineWidth', 1.5);
    hold off;
    title(titles{leg+2}); % EMG titles are in positions 3 and 4
    ylabel(yLabels{leg+2});
    newYmin = min(snippets{leg,1}(:, indsYLims), [], 'all');
    newYmax = max(snippets{leg,1}(:, indsYLims), [], 'all');
    if newYmin < ymin       % if minimum y-value less than previous, ...
        ymin = newYmin;     % update minimum y-axis value
    end
    if newYmax > ymax       % if maximum y-value greater than previous, ...
        ymax = newYmax;     % update maximum y-axis value
    end
end

%% Finalize Axes & Labels
linkaxes(ax);
xlim([times(1) times(end)]);
if ymax > ymin              % if snippets span a nonzero range, ...
    ylim([ymin ymax]);      % use the range across all plot legs
end

% TODO: should y-axis limits be the same in case of both legs present?
% TODO: consider accepting labels as optional input argument
% TODO: make figure title and filename optional inputs
xlabel(tl, 'Time (s)');
title(tl, sprintf('%s - Trial %s - H-Reflex Snippets', id, trialNum));

if ~isempty(options.pathFig)        % if figure saving path provided, ...
    saveas(fig, fullfile(options.pathFig, ...
        sprintf('%s_HreflexSnippets_Trial%s.fig', id, trialNum)));
    saveas(fig, fullfile(options.pathFig, ...
        sprintf('%s_HreflexSnippets_Trial%s.png', id, trialNum)));
end

end
