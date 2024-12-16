function fig = plotSnippets(times,snippets,yLabels,titles,id,trialNum,path)
%PLOTSNIPPETS Plot H-reflex snippets with GRFs if available
%   Plot the H-reflex snippets for desired muscles or forces (if desired)
% with the window bounds for M-wave and H-wave indicated by vertical lines.
%
% input:
%   times: number of samples x 1 array of the time in seconds with 0
%       indicating the identified stimulation artifact peak
%   snippets: 2 x 3 cell array of number of snippets x number of samples
%       arrays for right (row 1) and left (row 2) leg H-reflex (col 1),
%       ipsilateral (col 2) and contralateral (col 3) GRF snippets
%   yLabels: N x 1 cell array of strings or character arrays of the tile
%       y-axis labels for each of the snippets plotted
%   titles: N x 1 cell array of strings or character arrays of the tile
%       titles for each of the snippets plotted
%   id: string or character array of participant / session ID for naming
%   trialNum: string or character array of the trial number for naming
%   path: OPTIONAL input for saving figures (not saved if not provided)
% output:
%   fig: handle object to the figure generated

narginchk(6,7); % verify correct number of input arguments

if string(version('-release')) < "2019b" % if version older than 2019b, ...
    error(['MATLAB version must support ''tiledlayout'' (R2019b or ' ...
        'later.']);
end

% validate the size of 'snippets' and ensure it matches the expected format
if size(snippets,1) ~= 2 || size(snippets,2) ~= 3
    error('Expected `snippets` to be a 2x3 cell array.');
end

numSnipSamps = cellfun(@(x) size(x,2),snippets);
numSnipSamps = reshape(numSnipSamps,1,[]);
hasSameNumSamples = length(unique([numSnipSamps length(times)]));
if ~hasSameNumSamples   % if not same number of samples for all arrays, ...
    error('There are different numbers of samples across arrays.');
end
% TODO: ensure that there is at least one snippet
% TODO: adapt this function to work for generating any snippets plot

% ensure the number of titles and labels matches the number of tiles
if all(cellfun(@isempty,snippets(:,2:3)))
    numTiles = 2;           % right and left EMG
else
    numTiles = 4;           % right GRFs, left GRFs, right EMG, left EMG
    if length(titles) ~= numTiles || length(yLabels) ~= numTiles
        error('Mismatch between the number of tiles, titles, or yLabels.');
    end
end

% create new figure - a vertically oriented tiled layout
% ('Units','normalized','OuterPosition',UPDATETHIS)
fig = figure;
tl = tiledlayout(numTiles,1,'TileSpacing','tight','Padding','compact');

% NOTE: assuming inputs in desired plot order from top to bottom
% check for force data (columns 2 & 3) and plot combined GRFs if available
if ~isempty(snippets{1,2}) && ~isempty(snippets{1,3})
    nexttile;           % plot right leg ipsilateral and contralateral GRFs
    hold on;
    plot(times,snippets{1,2},'LineWidth',1.5,'Color',[0.000 0.447 0.741]);
    plot(times,snippets{1,3},'LineWidth',1.5,'Color',[0.850 0.325 0.098]);
    title(titles{1});
    ylabel(yLabels{1});
    xlim([times(1) times(end)]);
    hold off;
end

if ~isempty(snippets{2,2}) && ~isempty(snippets{2,3})
    nexttile;           % plot left leg ipsilateral and contralateral GRFs
    hold on;
    plot(times,snippets{2,2},'LineWidth',1.5,'Color',[0.000 0.447 0.741]);
    plot(times,snippets{2,3},'LineWidth',1.5,'Color',[0.850 0.325 0.098]);
    title(titles{2});
    ylabel(yLabels{2});
    xlim([times(1) times(end)]);
    hold off;
end

ax = gobjects(1,2);         % initialize array of Axes objects
% TODO: move y-axis limit code outside this function or make optional input
% (e.g., which index to start from) for more flexibility
indsYLims = times > 0.005;
ymin = 0;                   % initialize minimum y-axis value to be 0
ymax = 0;
for ii = 1:2                % for each EMG H-reflex snippets array, ...
    ax(ii) = nexttile;      % advance to next figure tile
    hold on;
    xline(0,'k','LineWidth',2); % stimulation artifact alignment
    % M-wave and H-wave range
    % TODO: update to accept as function input rather than hard-coding
    xline(0.0045,'b','LineWidth',1.5);  % M-wave start: 4.5 ms after stim
    xline(0.0200,'b','LineWidth',1.5);  % M-wave end: 20 ms    artifact
    xline(0.0250,'g','LineWidth',1.5);  % H-wave start: 25 ms after stim
    xline(0.0450,'g','LineWidth',1.5);  % H-wave end: 45 ms   artifact
    plot(times,snippets{ii,1},'LineWidth',1.5);
    hold off;
    title(titles{ii+2}); % EMG titles are in positions 3 and 4
    ylabel(yLabels{ii+2});
    newYmin = min(snippets{ii,1}(:,indsYLims),[],'all');
    newYmax = max(snippets{ii,1}(:,indsYLims),[],'all');
    if newYmin < ymin       % if minimum y-value less than previous, ...
        ymin = newYmin;     % update minimum y-axis value
    end
    if newYmax > ymax       % if maximum y-value greater than previous, ...
        ymax = newYmax;     % update maximum y-axis value
    end
end

linkaxes(ax);
xlim([times(1) times(end)]);
ylim([ymin ymax]);

xlabel(tl,'Time (s)');
title(tl,sprintf('%s - Trial %s - H-Reflex Snippets',id,trialNum));

% TODO: should y-axis limits be the same in case of both legs present?
% TODO: consider accepting labels as optional input argument
% TODO: make work for either sample number or time
% TODO: make figure title and filename optional inputs

if nargin == 7 && ~isempty(path)    % if figure saving path provided, ...
    saveas(fig,fullfile(path, ...
        sprintf('%s_HreflexSnippets_Trial%s.fig',id,trialNum)));
    saveas(fig,fullfile(path, ...
        sprintf('%s_HreflexSnippets_Trial%s.png',id,trialNum)));
end

end

