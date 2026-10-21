function fig = plotStimArtifactPeaks(times, rawEMG, indsPeaks, id, ...
    trialNum, options)
%PLOTSTIMARTIFACTPEAKS Plot located stimulation artifact peaks in EMG.
%
%   Plot the raw EMG trace of the artifact localization muscle (normally
% the proximal tibialis anterior) for each leg with the identified
% stimulation artifact peaks highlighted by a filled triangle, so that
% the experimenter can verify the indices used for H-reflex snippet
% alignment before any amplitude is computed. Peaks flagged as weak by
% HREFLEX.EXTRACTSTIMARTIFACTINDSFROMTRIGGER are drawn distinctly so a
% disabled stimulator or a detached electrode is visible at a glance. When
% pathFig is nonempty, also writes <id>_StimArtifactPeakFinding_Trial<n>
% as .png and .fig there, silently overwriting existing files (see
% DATA_OUTPUTS.md).
%
% Inputs:
%   times     - number of samples x 1 array of time in seconds from the
%               start of the trial for each sample
%   rawEMG    - 2-element cell of number of samples x 1 arrays for right
%               (cell 1) and left (cell 2) leg artifact localization
%               muscle EMG (if one cell is empty, that leg is not plot)
%   indsPeaks - 2-element cell of number of peaks x 1 arrays of the
%               stimulation artifact peak indices found by the algorithm
%   id        - string or character array of participant/session ID
%   trialNum  - string or character array of the trial number
%
% Optional Name-Value Inputs:
%   thresh  - peak finding threshold (V) to draw as a horizontal line;
%             not drawn if NaN (default: NaN)
%   pathFig - path for saving figures; not saved if empty (default: '')
%   labels  - 2-element cell of tile title strings for the right (cell
%             1) and left (cell 2) leg
%             (default: {'Right TAP', 'Left TAP'})
%   isWeak  - 2-element cell of number of peaks x 1 logical arrays
%             marking peaks whose absolute deflection fell below the
%             quality control floor (default: {[], []}, none flagged)
%
% Outputs:
%   fig - handle object to the figure generated for further customization
%
% Toolbox Dependencies:
%   None
%
% See also HREFLEX.EXTRACTSTIMARTIFACTINDSFROMTRIGGER,
%   HREFLEX.PLOTSNIPPETS, GENERATEHREFLEXRECRUITMENTCURVES.

arguments
    times     (:,1) double
    rawEMG    cell
    indsPeaks cell
    id        (1,:) {mustBeText}
    trialNum  (1,:) {mustBeText}
    options.thresh  (1,1) double = NaN
    options.pathFig (1,:) char   = ''
    options.labels  cell         = {'Right TAP', 'Left TAP'}
    options.isWeak  cell         = {[], []}
end

if string(version('-release')) < "2019b" % if version older than 2019b, ...
    error(['MATLAB version must support ''tiledlayout'' (R2019b or ' ...
        'later).']);
end

% TODO: add check of correct dimensions for cell arrays
if isempty(times) || all(cellfun(@isempty, rawEMG)) || ...
        all(cellfun(@isempty, indsPeaks))   % validate input arguments
    error(['There is critical data missing for plotting the EMG ' ...
        'signal with detected artifact peaks.']);
end

numLegs = sum(cellfun(@(x) ~isempty(x), rawEMG));   % number of legs
if numLegs > 2                                      % if more than 2, ...
    error('Input EMG signals must be limited to 2 legs (right and left).');
end

%% Create Figure
% set the figure to be full screen
fig = figure('Units', 'normalized', 'OuterPosition', [0 0 1 1]);
tl = tiledlayout(numLegs, 1, 'TileSpacing', 'tight');

%% Plot Each Leg With Data
for leg = 1:2                       % for each leg, ...
    if isempty(rawEMG{leg})         % if no EMG data available, ...
        continue;                   % advance to next leg
    end
    nexttile;                       % plot signal with detected peaks
    plotSignalWithPeaks(times, rawEMG{leg}, indsPeaks{leg}, ...
        options.thresh, options.isWeak{leg});
    title(options.labels(leg));
end

% TODO: should y-axis limits be the same in case of both legs present?
% global labels and title
xlabel(tl, 'Time (s)');
ylabel(tl, 'Raw EMG (V)');
title(tl, sprintf( ...
    '%s - Trial %s - Stimulation Artifact Peak Finding', id, trialNum));

%% Save Figure
if ~isempty(options.pathFig)    % if figure saving path provided, ...
    saveFigure(fig, options.pathFig, id, trialNum);
end

end

%% Helper Functions

function plotSignalWithPeaks(x, y, inds, thresh, isWeak)
%PLOTSIGNALWITHPEAKS Plot one leg's EMG signal with its detected peaks.
%
%   Plot the raw EMG trace with a filled triangle at each detected
% stimulation artifact peak, drawing any peak flagged as weak in red so
% that it stands out from the accepted peaks.
%
% Inputs:
%   x      - number of samples x 1 array of time in seconds
%   y      - number of samples x 1 array of raw EMG signal (V)
%   inds   - number of peaks x 1 array of artifact peak indices
%   thresh - peak finding threshold (V); not drawn if NaN
%   isWeak - number of peaks x 1 logical array marking weak peaks, or
%            empty if no peak was flagged
%
% Outputs:
%   None
%
% Toolbox Dependencies:
%   None

% TODO: consider moving tile title into this helper function
if isempty(isWeak)                      % if no peak flagged, ...
    isWeak = false(size(inds));         % treat all peaks as accepted
end

hold on;
% below code is copied from MATLAB 'findpeaks' function to replicate
hLine = plot(x, y, 'Tag', 'Signal');    % plot signal line
hAxes = ancestor(hLine, 'Axes');
grid on;                                % turn on grid
if numel(y) > 1
    hAxes.XLim = hLine.XData([1 end]);  % restrict x-axis limits
end
color = get(hLine, 'Color');            % use the color of the line
indsOK = inds(~isWeak);
line(hLine.XData(indsOK), y(indsOK), 'Parent', hAxes, 'Marker', 'v', ...
    'MarkerFaceColor', color, 'LineStyle', 'none', 'Color', color, ...
    'Tag', 'Peak');
if any(isWeak)                          % if any peak flagged weak, ...
    indsWeak = inds(isWeak);            % highlight it in red
    line(hLine.XData(indsWeak), y(indsWeak), 'Parent', hAxes, ...
        'Marker', 'o', 'MarkerSize', 10, 'LineWidth', 1.5, ...
        'LineStyle', 'none', 'Color', 'r', 'Tag', 'WeakPeak');
end
if ~isnan(thresh)                       % if threshold is not NaN, ...
    yline(thresh, 'r', 'Peak Finding Threshold');   % plot it
end
hold off;

end

function saveFigure(fig, path, id, trialNum)
%SAVEFIGURE Save the artifact peak finding figure to disk.
%
%   Save the figure in both PNG and FIG formats using the standard
% participant and trial naming convention.
%
% Inputs:
%   fig      - handle to the figure to save
%   path     - path of the folder in which to save the figure
%   id       - string or character array of participant/session ID
%   trialNum - string or character array of the trial number
%
% Outputs:
%   None
%
% Toolbox Dependencies:
%   None

fileBase = fullfile(path, ...
    sprintf('%s_StimArtifactPeakFinding_Trial%s', id, trialNum));
saveas(fig, [fileBase '.png']);
saveas(fig, [fileBase '.fig']);

end
