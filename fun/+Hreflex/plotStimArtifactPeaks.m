function fig = plotStimArtifactPeaks(times,rawEMG_TAP,indsPeaks,id, ...
    trialNum,varargin)
%PLOTSTIMARTIFACTPEAKS Plot stimulation artifact peaks in proximal TA
%   Plot the H-reflex raw EMG traces for the proximal tibialis anterior
% muscle with the identified stimulation artifact peaks highlighted with a
% filled in triangle to verify that the indices found for the peaks are
% correct for later H-reflex alignment and analysis.
%
% input:
%   times: number of samples x 1 array with the time in seconds from the
%       start of the trial for each sample
%   rawEMG_TAP: 2 x 1 cell array of number of samples x 1 arrays for right
%       (cell 1) and left (cell 2) leg proximal TA muscle EMG signal (NOTE:
%       if one cell is input as empty array, that leg will not be plot)
%   indsPeaks: 2 x 1 cell array of number of peaks x 1 arrays of the
%       stimulation artifact peaks found by the algorithm
%   id: string or character array of participant / session ID for naming
%   trialNum: string or character array of the trial number for naming
%   thresh: OPTIONAL input for the threshold used to determine peaks
%   path: OPTIONAL input for saving figures (not saved if not provided)
% output:
%   fig: handle object to the figure generated for further customization

narginchk(5,7); % verify correct number of input arguments

if string(version('-release')) < "2019b" % if version older than 2019b, ...
    error(['MATLAB version must support ''tiledlayout'' (R2019b or ' ...
        'later).']);
end

% TODO: add check of correct dimensions for cell arrays
if isempty(times) || all(cellfun(@isempty,rawEMG_TAP)) || ...
        all(cellfun(@isempty,indsPeaks))    % validate input arguments
    error(['There is critical data missing for plotting the EMG ' ...
        'signal with detected artifact peaks.']);
end

numOptArgs = length(varargin);
switch numOptArgs
    case 0
        thresh = nan;               % default to Not-a-Number
        path = '';                  % default to empty
    case 1                          % one optional argument provided
        if isnumeric(varargin{1})   % if a number, ...
            thresh = varargin{1};   % it is the threshold
            path = '';
        else                        % otherwise, ...
            thresh = NaN;
            path = varargin{1};     % it is the file saving path
        end
    case 2                          % both optional arguments provided
        thresh = varargin{1};       % first always stim artifact threshold
        path = varargin{2};         % second always file saving path
    otherwise
        error('Too many optional arguments. Provide at most 2.');
end

numLegs = sum(cellfun(@(x) ~isempty(x),rawEMG_TAP));% number of legs
if numLegs > 2                                      % if more than 2, ...
    error('Input EMG signals must be limited to 2 legs (right and left).');
end

% set the figure to be full screen
fig = figure('Units','normalized','OuterPosition',[0 0 1 1]);
tl = tiledlayout(numLegs,1,'TileSpacing','tight');

labelsLegs = {'Right TAP','Left TAP'};
for leg = 1:2                       % for each leg, ...
    if ~isempty(rawEMG_TAP{leg})    % if EMG data is available, ...
        nexttile;                   % plot signal with detected peaks
        plotSignalWithPeaks(times, rawEMG_TAP{leg}, indsPeaks{leg}, thresh);
        title(labelsLegs(leg));
    end
end

% TODO: should y-axis limits be the same in case of both legs present?
% TODO: consider accepting labels as optional input argument
% global labels and title
xlabel(tl,'Time (s)');
ylabel(tl,'Raw EMG (V)');
title(tl,sprintf( ...
    '%s - Trial %s - Stimulation Artifact Peak Finding',id,trialNum));

if ~isempty(path)   % if figure saving path provided as input argument, ...
    saveFigure(fig,path,id,trialNum);
end

end

function plotSignalWithPeaks(x,y,inds,thresh)
% plot EMG signals with detected peaks
% TODO: consider moving tile title into this helper function

hold on;
% below code is copied from MATLAB 'findpeaks' function to replicate
hLine = plot(x,y,'Tag','Signal');       % plot signal line
hAxes = ancestor(hLine,'Axes');
grid on;                                % turn on grid
if numel(y) > 1
    hAxes.XLim = hLine.XData([1 end]);  % restrict x-axis limits
end
color = get(hLine,'Color');             % use the color of the line
line(hLine.XData(inds),y(inds),'Parent',hAxes,'Marker','v', ...
    'MarkerFaceColor',color,'LineStyle','none','Color',color,'tag','Peak');
if ~isnan(thresh)                       % if threshold is not NaN, ...
    yline(thresh,'r','Peak Finding Threshold');     % plot it
end
hold off;

end

function saveFigure(fig,path,id,trialNum)
% save figure in PNG and FIG formats
fileBase = fullfile(path, ...
    sprintf('%s_StimArtifactPeakFinding_Trial%s',id,trialNum));
saveas(fig,[fileBase '.png']);
saveas(fig,[fileBase '.fig']);
end

