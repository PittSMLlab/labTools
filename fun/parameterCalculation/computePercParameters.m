function out = computePercParameters(trialData, initTime, endTime, ...
    slaParam)
% computePercParameters  Compute perceptual task parameters per stride.
%
%   Syntax:
%     out = computePercParameters(trialData, initTime, endTime, slaParam)
%
%   Computes stride-by-stride parameters related to the perceptual
% split-belt treadmill task and returns a parameterSeries object that
% can be concatenated with other parameter series objects (e.g., from
% computeTemporalParameters). Only adds parameters using gait event
% information; all parameters will be NaN or zero if the relevant
% events do not exist.
%
%   Inputs:
%     trialData - processedTrialData object for the trial; must contain
%                 gaitEvents with 'percStartCue', 'percEndCue', and
%                 'percEndRamp' labels, and metaData with a datlog
%     initTime  - N-by-1 vector of stride start times (in seconds)
%     endTime   - N-by-1 vector of stride end times (in seconds)
%     slaParam  - N-by-1 vector of step length asymmetry values
%
%   Outputs:
%     out - parameterSeries object containing all perceptual task
%           parameters
%
%   Toolbox Dependencies:
%     None
%
%   See also: computeTemporalParameters, computeSpatialParameters,
%     computeForceParameters, parameterSeries, calcParameters
%
%   Author: MGR
%   Date: 06/12/24

arguments
    trialData (1,1)
    initTime
    endTime
    slaParam
end

%% Locate Perceptual Task Event Indices
idxPstart = find(full(trialData.gaitEvents.Data(:, ...
    strcmpi(trialData.gaitEvents.labels, 'percStartCue'))));

% If Weber trial, the perturbation was most likely ramped down
if contains(lower(trialData.metaData.ID), 'weber')
    idxPend = find(full(trialData.gaitEvents.Data(:, ...
        strcmpi(trialData.gaitEvents.labels, 'percEndRamp'))));
else
    idxPend = find(full(trialData.gaitEvents.Data(:, ...
        strcmpi(trialData.gaitEvents.labels, 'percEndCue'))));
end

if length(idxPstart) ~= length(idxPend)
    minLen    = min(length(idxPstart), length(idxPend));
    idxPstart = idxPstart(1:minLen);
    idxPend   = idxPend(1:minLen);
end

timePercInit = trialData.gaitEvents.Time(idxPstart);
timePercEnd  = trialData.gaitEvents.Time(idxPend);

%% Extract Perturbation Sizes
% Grab the perturbation sizes tested from the speed profiles in the
% datlogs. Negative values indicate the right leg was slower.
beltSpeedDiff = trialData.metaData.datlog.speedprofile.velR ...
    - trialData.metaData.datlog.speedprofile.velL;
nanMask = isnan(beltSpeedDiff);
nanBoundaryMask = arrayfun( ...
    @(i) (nanMask(i) == 1 && nanMask(i-1) == 0 ...
    && nanMask(i+1) == 1), 2:length(nanMask)-1);
speedDiffPercTask = beltSpeedDiff(nanBoundaryMask); % pert sizes in mm/s

%% Labels and Descriptions
aux = { ...
    'percTaskInitStride',   'binary parameter where 1 indicates the beginning of a perceptual trial'; ...
    'percTaskEndStride',    'binary parameter where 1 indicates the end of a perceptual trial'; ...
    'percTask',             'binary parameter where 1 indicates the stride belongs to a perceptual trial'; ...
    'pertSizePercTask',     'value of the leg-speed difference experienced during the perceptual trial'; ...
    'SLAinPercTask',        'step length asymmetry parameter for the perceptual trials, otherwise nan'; ...
    'SLAnotPercTask',       'step length asymmetry parameter except for the perceptual trials (filled with nans)'};

paramLabels = aux(:, 1);
description = aux(:, 2);

%% Initialize Output Arrays
percTaskInitStride = zeros(size(initTime));
percTaskEndStride  = zeros(size(initTime));
percTask           = zeros(size(initTime));
pertSizePercTask   = nan(size(initTime));
SLAinPercTask      = nan(size(initTime));
SLAnotPercTask     = nan(size(initTime));

%% Compute Perceptual Task Parameters
% Find the indices of the nearest heel strike to the start/end of each
% perceptual task interval.
% TODO: add a data check to warn if the stride indices are considerably
% different from what was expected

SLAnotPercTask = slaParam;
if ~isempty(timePercInit) && ~isempty(timePercEnd)
    indsInitStride = arrayfun( ...
        @(x) find((x - initTime) > 0, 1, 'last'), ...
        timePercInit); % initTime is the stride initial times
    indsEndStride  = arrayfun( ...
        @(x) find((x - endTime) < 0, 1, 'first'), ...
        timePercEnd); % timePercEnd is the stride final times

    percTaskInitStride(indsInitStride) = 1;
    percTaskEndStride(indsEndStride)   = 1;

    for iPerc = 1:length(indsInitStride)
        % Here I am not currently considering the changes in the belt
        % speed when going back to tied; sometimes it takes a couple of
        % strides to reach this fully.
        % Previously used indsEndStride(iPerc)+3 to account for the
        % delay before belt speed reaches the tied condition.
        percTask(indsInitStride(iPerc):indsEndStride(iPerc)) = 1;

        % No +3 buffer here: use the true perceptual task end for SLA.
        SLAinPercTask(indsInitStride(iPerc):indsEndStride(iPerc)) = ...
            slaParam(indsInitStride(iPerc):indsEndStride(iPerc));

        % Previously used indsEndStride(iPerc)+3 here as well.
        SLAnotPercTask(indsInitStride(iPerc):indsEndStride(iPerc)) = nan;

        if length(speedDiffPercTask) >= iPerc
            pertSizePercTask( ...
                indsInitStride(iPerc):indsEndStride(iPerc)) = ...
                speedDiffPercTask(iPerc);
        end
    end
end

%% Assign Parameters to Data Matrix
data = nan(length(initTime), length(paramLabels));
for ii = 1:length(paramLabels)
    eval(['data(:, ii) = ' paramLabels{ii} ';']);
end

%% Output Computed Parameters
out = parameterSeries(data, paramLabels, [], description);

end

