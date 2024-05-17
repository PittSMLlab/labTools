function fig = plotSnippets(times,snippets,labels,id,trialNum,path)
%PLOTSNIPPETS Plot H-reflex snippets
%   Plot the H-reflex snippets for desired muscles or forces (if desired)
% with the window bounds for M-wave and H-wave indicated by vertical lines.
%
% input:
%   times: number of samples x 1 array of the time in seconds with 0
%       indicating the identified stimulation artifact peak
%   snippets: N x 1 cell array of number of snippets x number of samples
%       arrays of force or raw EMG data (NOTE: no cells may be empty, and
%       every cell must have a corresponding label)
%   labels: N x 1 cell array of strings or character arrays of the tile
%       titles (i.e., labels) for each of the snippets plot
%   id: string or character array of participant / session ID for naming
%   trialNum: string or character array of the trial number for naming
%   path: OPTIONAL input for saving figures (not saved if not provided)
% output:
%   fig: handle object to the figure generated

narginchk(5,6); % verify correct number of input arguments

hasSameNumSamples = length(unique( ...
    [cellfun(@(x) size(x,2),snippets) length(times)]));
if ~hasSameNumSamples   % if not same number of samples for all arrays, ...
    error('There are different numbers of samples across arrays.');
end
% TODO: ensure that there is at least one snippet
% TODO: adapt this function to work for generating any snippets plot

% TODO: consider converting to a date object before performing the
% comparison, although string comparison seems to work just fine
if string(version('-release')) < "2019b" % if version older than 2019b, ...
    error('MATLAB version is not compatible with ''tiledlayout''.');
end

numLabels = length(labels);         % number of labels (subplot titles)

% set the figure to be full screen
fig = figure('Units','normalized','OuterPosition',[0 0 1 1]);
tl = tiledlayout(numLabels,1,'TileSpacing','tight');

indsForce = contains(labels,{'force','fz'},'IgnoreCase',true);
numForce = sum(indsForce);          % number of force labels
hasForce = any(indsForce);          % is there force data present?
numNonForce = numLabels - numForce; % number of non-force labels

% NOTE: assuming inputs in desired plot order from top to bottom
% TODO: consider plotting ipsilateral and contralateral leg force in the
% same tile but with different colors so that the gait phase in which stim
% occurred can more easily be deciphered; this would require changing the
% format of the snippets input and labeling
if hasForce     % if force provided for plotting, ...
    for ii = 1:numForce     % for each force label, ...
        plotTile(times,snippets{ii},labels{ii});
    end
end

ax = gobjects(1,numNonForce);   % initialize array of Axes objects
% TODO: move y-axis limit code outside this function or make optional input
% (e.g., which index to start from) for more flexibility
indsYLims = times > 0.005;
ymin = 0;                   % initialize minimum y-axis value to be 0
ymax = 0;
for ii = 1:numNonForce      % for each non-force signal, ...
    ax(ii) = plotTile(times,snippets{ii+numForce},labels{ii+numForce});
    newYmin = min(snippets{ii+numForce}(:,indsYLims),[],'all');
    newYmax = max(snippets{ii+numForce}(:,indsYLims),[],'all');
    if newYmin < ymin       % if minimum y-value less than previous, ...
        ymin = newYmin;     % update minimum y-axis value
    end
    if newYmax > ymax       % if maximum y-value greater than previous, ...
        ymax = newYmax;     % update maximum y-axis value
    end
end

linkaxes(ax);
xlabel(tl,'time (s)');
xlim([times(1) times(end)]);
ylim([ymin ymax]);

% TODO: should y-axis limits be the same in case of both legs present?
% TODO: consider accepting labels as optional input argument
xlabel(tl,'time (s)');  % TODO: make work for either sample number or time
% TODO: make figure title and filename optional inputs
title(tl,[id ' - Trial' trialNum ' - H-Reflex Snippets']);

if ~isempty(path)   % if figure saving path provided as input argument, ...
    % save figure
    saveas(gcf,[path id '_HreflexSnippets_Trial' trialNum '.png']);
    saveas(gcf,[path id '_HreflexSnippets_Trial' trialNum '.fig']);
end

end

function ax = plotTile(t,y,lbl)

ax = nexttile;  % advance to the next tile in tiled layout figure
hold on;
xline(0,'k','LineWidth',2);     % indicate stim artifact alignment
if ~contains(lbl,{'force','fz'},'IgnoreCase',true)  % if EMG snippet, ...
    % plot lines indicating M-wave and H-wave range
    % TODO: make this optional input
    % TODO: do not hardcode start and stop times
    xline(0.005,'b');           % M-wave start:  5 ms after stim artifact
    xline(0.020,'b');           % M-wave end:   20 ms
    xline(0.025,'g');           % H-wave start: 25 ms after stim artifact
    xline(0.045,'g');           % H-wave end:   45 ms
end
plot(t,y);
hold off;
if contains(lbl,{'force','fz'},'IgnoreCase',true)   % if force snippet, ...
    ylabel('Force (N)');
else                                                % otherwise, ...
    ylabel('Raw EMG (V)');                          % EMG snippet(s)
end
title(lbl);

end

