function [out] = computePercParameters(trialData,initTime,endTime,slaParam)
% This function will add some parameters and summary information from the perceptual task in the datlogs
% The output is a parameterSeries object, which can be concatenated with
% other parameterSeries objects, for example with those from
% computeTemporalParameters. While this is used for perceptual tasks parameters
% strictly, it should work for any labTS.
% See also computeSpatialParameters, computeTemporalParameters,
% computeForceParameters, parameterSeries
% Author: MGR 
% Date: 06/12/24

%% Gait perceptual task gait event times
idxPstart = find(full(trialData.gaitEvents.Data(:,strcmpi(trialData.gaitEvents.labels,'percStartCue'))));
timePercInit = trialData.gaitEvents.Time(idxPstart);

if contains(lower(trialData.metaData.ID),'weber') %if this is true, we were most likely ramping down the perturbation 
    idxPend = find(full(trialData.gaitEvents.Data(:,strcmpi(trialData.gaitEvents.labels,'percEndRamp'))));
    timePercEnd = trialData.gaitEvents.Time(idxPend);
else
    idxPend = find(full(trialData.gaitEvents.Data(:,strcmpi(trialData.gaitEvents.labels,'percEndCue'))));
    timePercEnd = trialData.gaitEvents.Time(idxPend);
end

%% Perturbation sizes 
% Grab the perturbation sizes tested from the speed profiles in the
% datlogs

profile = trialData.metaData.datlog.speedprofile.velR-trialData.metaData.datlog.speedprofile.velL; % negative perturbation sizes mean that the right leg was slower
nanProfile = isnan(profile); 

isNextOne = arrayfun(@(i) (nanProfile(i) == 1 && nanProfile(i-1) == 0 && nanProfile(i+1) == 1), 2:length(nanProfile)-1);
speedDiffPercTask = profile(isNextOne); % This are the values of pert size in mm/s that will be saved in the params

%% Labels & Descriptions:
aux={'percTaskInitStride',        'binary parameter where 1 indicates the beginning of a perceptual trial'; ...
    'percTaskEndStride',         'binary parameter where 1 indicates the end of a perceptual trial'; ...
    'percTask',          'binary parameter where 1 indicates the stride belong to a perceptual trial'; ...
    'pertSizePercTask',          'value of the leg-speed difference experienced during the perceptual trial'; ...
    'SLAinPercTask',          'step length asymmetry parameter for the perceptual trials, otherwise nan'; ...
    'SLAnotPercTask',          'step length asymmetry parameter except for the perceptual trials (filled with nans)'};

paramLabels = aux(:,1);
description = aux(:,2);

%% Initialize the parameters

percTaskInitStride = zeros(size(initTime));
percTaskEndStride = zeros(size(initTime));
percTask = zeros(size(initTime));
pertSizePercTask = nan(size(initTime));
SLAinPercTask = nan(size(initTime));
SLAnotPercTask = slaParam;

%% Compute the Parameters

% find the indices of the nearest initial time of heel strike to the time
% of the start of the perceptual task
% TODO: add a data check to warn if the stride indices are considerably
% different of what was expected
if ~isempty(timePercInit) && ~isempty(timePercEnd)
    indsInitStride = arrayfun(@(x) find((x-initTime) > 0,1,'last'), ...
        timePercInit); %initTime is the stride initial times
    indsEndStride = arrayfun(@(x) find((x-endTime) < 0,1,'first'), ...
        timePercEnd); %timePercEnd is the stride final times

    % populate the times for the strides that have perceptual tasks
    percTaskInitStride(indsInitStride) = 1;
    percTaskEndStride(indsEndStride) = 1;

    SLAnotPercTask = slaParam;
    for i = 1:length(indsInitStride)
        percTask(indsInitStride(i):indsEndStride(i)) = 1;
        SLAinPercTask(indsInitStride(i):indsEndStride(i)) = slaParam(indsInitStride(i):indsEndStride(i));
        SLAnotPercTask(indsInitStride(i):indsEndStride(i)) = nan;
        if length(speedDiffPercTask) >= i
            pertSizePercTask(indsInitStride(i):indsEndStride(i)) = speedDiffPercTask(i);
        end
    end

end

%% Assign Parameters to the Data Matrix
data = nan(length(initTime),length(paramLabels));
for i=1:length(paramLabels)
    eval(['data(:,i)=' paramLabels{i} ';'])
end

%% Create parameterSeries
out = parameterSeries(data,paramLabels,[],description);

end

