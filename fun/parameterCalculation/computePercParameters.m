function [out] = computePercParameters(trialData, initTime, endTime, slaParam)
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

idxPstart = find(full(trialData.gaitEvents.Data(:, strcmpi(trialData.gaitEvents.labels, 'percStartCue'))));
arguments
    trialData (1,1)
    initTime
    endTime
    slaParam
end

%% Locate Perceptual Task Event Indices

if contains(lower(trialData.metaData.ID),'weber') %if this is true, we were most likely ramping down the perturbation
    idxPend = find(full(trialData.gaitEvents.Data(:, strcmpi(trialData.gaitEvents.labels, 'percEndRamp'))));
else
    idxPend = find(full(trialData.gaitEvents.Data(:, strcmpi(trialData.gaitEvents.labels, 'percEndCue'))));
end

if length(idxPstart)~= length(idxPend)
    mask=min(length(idxPstart),length(idxPend));
    idxPstart=idxPstart(1:mask);
    idxPend=idxPend(1:mask);
end

timePercInit = trialData.gaitEvents.Time(idxPstart);
timePercEnd = trialData.gaitEvents.Time(idxPend);

profile = trialData.metaData.datlog.speedprofile.velR-trialData.metaData.datlog.speedprofile.velL; % negative perturbation sizes mean that the right leg was slower
nanProfile = isnan(profile);

isNextOne = arrayfun(@(i) (nanProfile(i) == 1 && nanProfile(i-1) == 0 && nanProfile(i+1) == 1), 2:length(nanProfile)-1);
speedDiffPercTask = profile(isNextOne); % This are the values of pert size in mm/s that will be saved in the params

aux={'percTaskInitStride',        'binary parameter where 1 indicates the beginning of a perceptual trial'; ...
    'percTaskEndStride',         'binary parameter where 1 indicates the end of a perceptual trial'; ...
    'percTask',          'binary parameter where 1 indicates the stride belong to a perceptual trial'; ...
    'pertSizePercTask',          'value of the leg-speed difference experienced during the perceptual trial'; ...
    'SLAinPercTask',          'step length asymmetry parameter for the perceptual trials, otherwise nan'; ...
    'SLAnotPercTask',          'step length asymmetry parameter except for the perceptual trials (filled with nans)'};
%% Extract Perturbation Sizes
% Grab the perturbation sizes tested from the speed profiles in the
% datlogs. Negative values indicate the right leg was slower.
%% Labels and Descriptions

paramLabels = aux(:, 1);
description = aux(:, 2);

%% Initialize Output Arrays
percTaskInitStride = zeros(size(initTime));
percTaskEndStride = zeros(size(initTime));
percTask = zeros(size(initTime));
pertSizePercTask = nan(size(initTime));
SLAinPercTask = nan(size(initTime));
SLAnotPercTask = nan(size(initTime));

%% Compute Perceptual Task Parameters
% Find the indices of the nearest heel strike to the start/end of each
% perceptual task interval.
% TODO: add a data check to warn if the stride indices are considerably
% different from what was expected

SLAnotPercTask = slaParam;
if ~isempty(timePercInit) && ~isempty(timePercEnd)
    indsInitStride = arrayfun(@(x) find((x-initTime) > 0, 1, 'last'), ...
        timePercInit); %initTime is the stride initial times
    indsEndStride = arrayfun(@(x) find((x-endTime) < 0, 1, 'first'), ...
        timePercEnd); %timePercEnd is the stride final times

    % populate the times for the strides that have perceptual tasks
    percTaskInitStride(indsInitStride) = 1;
    percTaskEndStride(indsEndStride) = 1;


    for i = 1:length(indsInitStride)

        percTask(indsInitStride(i):indsEndStride(i)) = 1; % Previously I had indsEndStride(i)+3 to consider that we do not reach the speeds (tied) right away because we update belts speeds separately during swing
        SLAinPercTask(indsInitStride(i):indsEndStride(i)) = slaParam(indsInitStride(i):indsEndStride(i)); % This one I do not consider the back to tied strides, since I want the true end of perceptual task
        SLAnotPercTask(indsInitStride(i):indsEndStride(i)) = nan; % Previously I had indsEndStride(i)+3
        if length(speedDiffPercTask) >= i
            pertSizePercTask(indsInitStride(i):indsEndStride(i)) = speedDiffPercTask(i);
        % Here I am not currently considering the changes in the belt
        % speed when going back to tied; sometimes it takes a couple of
        % strides to reach this fully.
        % Previously used indsEndStride(iPerc)+3 to account for the
        % delay before belt speed reaches the tied condition.
        end
    end

end

%% Assign Parameters to Data Matrix
data = nan(length(initTime), length(paramLabels));
for i=1:length(paramLabels)
    eval(['data(:, i) = ' paramLabels{i} ';'])
end

%% Output Computed Parameters
out = parameterSeries(data, paramLabels, [], description);

end

