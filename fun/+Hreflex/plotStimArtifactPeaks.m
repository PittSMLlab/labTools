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
%   fig: handle object to the figure generated

narginchk(5,7); % verify correct number of input arguments

% TODO: consider converting to a date object before performing the
% comparison, although string comparison seems to work just fine
if string(version('-release')) < "2019b" % if version older than 2019b, ...
    error('MATLAB version is not compatible with ''tiledlayout''.');
end

numOptArgs = length(varargin);
switch numOptArgs
    case 0
        thresh = nan;   % default to Not-a-Number
        path = '';      % default to empty
    case 1  % one optional argument provided
        if isnumeric(varargin{1})   % if a number, ...
            thresh = varargin{1};   % it is the threshold
            path = '';
        else                        % otherwise, ...
            path = varargin{1};     % is is the file saving path
            thresh = nan;
        end
    case 2  % both optional arguments provided
        thresh = varargin{1};   % first always stim artifact threshold
        path = varargin{2};     % second always file saving path
end

% set the figure to be full screen
fig = figure('Units','normalized','OuterPosition',[0 0 1 1]);

numLegs = sum(cellfun(@(x) ~isempty(x),rawEMG_TAP)); % number of legs
if numLegs > 2                  % if cell array input incorrect length, ...
    error('There must not be more than two input EMG signals.');
elseif numLegs == 2             % if right and left TAP data present, ...
    if any(cellfun(@isempty,indsPeaks)) % if missing peak index data, ...
        error(['Missing stimulation artifact peak index data for one ' ...
            'or both legs.']);
    end
    tl = tiledlayout(2,1,'TileSpacing','tight');
    if ~isnan(thresh)           % if threshold is input argument, ...
        plotSignalWithPeaks(times,rawEMG_TAP{1},indsPeaks{1},thresh);
        title('Right TAP');
        plotSignalWithPeaks(times,rawEMG_TAP{2},indsPeaks{2},thresh);
        title('Left TAP');
    else                        % otherwise, ...
        plotSignalWithPeaks(times,rawEMG_TAP{1},indsPeaks{1});
        title('Right TAP');
        plotSignalWithPeaks(times,rawEMG_TAP{2},indsPeaks{2});
        title('Left TAP');
    end
elseif numLegs == 1             % if TAP data from only one leg, ...
    indLeg = find(cellfun(@(x) ~isempty(x),rawEMG_TAP));    % leg index
    if isempty(indsPeaks{indLeg})
        error('Missing stimulation artifact peak index data.');
    end
    tl = tiledlayout(1,1,'TileSpacing','tight');
    if indLeg == 1              % if right leg, ...
        plotSignalWithPeaks(times,rawEMG_TAP{indLeg},indsPeaks{indLeg});
        title('Right TAP');
    elseif indLeg == 2          % if left leg, ...
        plotSignalWithPeaks(times,rawEMG_TAP{indLeg},indsPeaks{indLeg});
        title('Left TAP');
    end
else                            % otherwise, ...
    error('There are no input EMG signals.');   % no EMG data present
end

% TODO: should y-axis limits be the same in case of both legs present?
% TODO: consider accepting labels as optional input argument
xlabel(tl,'time (s)');
ylabel(tl,'Raw EMG (V)');
title(tl,[id ' - Trial' trialNum ' - Stimulation Artifact Peak Finding']);

if ~isempty(path)   % if figure saving path provided as input argument, ...
    % save figure
    saveas(gcf,[path id '_StimArtifactPeakFinding_Trial' trialNum '.png']);
    saveas(gcf,[path id '_StimArtifactPeakFinding_Trial' trialNum '.fig']);
end

end

function plotSignalWithPeaks(x,y,inds,thresh)

% TODO: consider moving tile title into this helper function
narginchk(3,4);                         % only fourth input optional

nexttile;   % advance to the next tile in tiled layout figure
hold on;
% below code is copied from MATLAB 'findpeaks' function to replicate
hLine = plot(x,y,'Tag','Signal');       % plot signal line
hAxes = ancestor(hLine,'Axes');
grid on;                                % turn on grid
if length(y) > 1
    hAxes.XLim = hLine.XData([1 end]);  % restrict x-axis limits
end
color = get(hLine,'Color');             % use the color of the line
line(hLine.XData(inds),y(inds),'Parent',hAxes,'Marker','v', ...
    'MarkerFaceColor',color,'LineStyle','none','Color',color,'tag','Peak');
hold off;
if nargin == 4  % if there is a threshold input, ...
    yline(thresh,'r','Peak Finding Threshold');     % plot it
end

end

