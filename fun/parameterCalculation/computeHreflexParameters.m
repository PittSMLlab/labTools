function [out] = computeHreflexParameters(strideEvents,HreflexData,EMGData,slowLeg)
%This function computes summary parameters per stride for the H-reflex data
% The output is a parameterSeries object, which can be concatenated with
% other parameterSeries objects, for example with those from
% computeTemporalParameters. While this is used for Hreflex parameters
% strictly, it should work for any labTS.
% See also computeSpatialParameters, computeTemporalParameters,
% computeForceParameters, parameterSeries

%% Gait Stride Event Times
timeSHS = strideEvents.tSHS;    % array of slow heel strike event times
timeFHS = strideEvents.tFHS;    % array of fast heel strike event times

%% Labels & Descriptions:
aux={'stimTimeSlow',        'time from SHS to slow leg stim (in s)'; ...
    'stimTimeFast',         'time from FHS to fast leg stim (in s)'; ...
    'hReflexSlow',          'peak-to-peak voltage of the slow leg H-wave (in V)'; ...
    'hReflexFast',          'peak-to-peak voltage of the fast leg H-wave (in V)'};

paramLabels = aux(:,1);
description = aux(:,2);

%% Compute the Parameters
threshVolt = 2.5; % threshold to determine stimulation trigger pulse
% extract all stimulation trigger data for each leg
stimTrigR = HreflexData.Data(:,contains(HreflexData.labels,'right', ...
    'IgnoreCase',true));
stimTrigL = HreflexData.Data(:,contains(HreflexData.labels,'left', ...
    'IgnoreCase',true));
% determine indices when stimulus trigger is high (to stimulate), and
% extract slow and fast leg EMG data for the Medial Gastrocnemius muscle
switch lower(slowLeg)   % which leg is slow, R or L
    case 'r'            % if right leg is slow, ...
        indsStimSlowAll = find(stimTrigR > threshVolt);
        indsStimFastAll = find(stimTrigL > threshVolt);
        % MG is the muscle used for the H-reflex
        EMGSlow = EMGData.Data(:,contains(EMGData.labels,'RMG'));
        EMGFast = EMGData.Data(:,contains(EMGData.labels,'LMG'));
    case 'l'            % if left leg is slow, ...
        indsStimSlowAll = find(stimTrigL > threshVolt);
        indsStimFastAll = find(stimTrigR > threshVolt);
        EMGSlow = EMGData.Data(:,contains(EMGData.labels,'LMG'));
        EMGFast = EMGData.Data(:,contains(EMGData.labels,'RMG'));
    otherwise           % otherwise, throw an error
        error('Invalid slow leg input argument, must be ''R'' or ''L''');
end

% determine which indices correspond to the start of a new stimulus pulse
% (i.e., there is a jump in index greater than 1, not the next sample)
indsNewPulseSlow = diff([0; indsStimSlowAll]) > 1;
indsNewPulseFast = diff([0; indsStimFastAll]) > 1;

% determine time since start of trial when stim pulse occurred
stimTimeSlowAbs = HreflexData.Time(indsStimSlowAll(indsNewPulseSlow));
stimTimeFastAbs = HreflexData.Time(indsStimFastAll(indsNewPulseFast));

% initialize parameter arrays: time of stimulation trigger pulse onset
% (i.e., rising edge) and H-wave magnitude (i.e., peak-to-peak voltage)
stimTimeSlow = nan(size(timeSHS));
stimTimeFast = nan(size(timeFHS));
hReflexSlow = nan(size(timeSHS));
hReflexFast = nan(size(timeFHS));

% find the indices of the nearest stride heel strike to the time of stim
% NOTE: this **should** be identical but may not be due to missed
% stimulation pulses, especially at the start or end of a trial (however,
% there should not be substantial differences in the stride indices)
% TODO: add a data check to warn if the stride indices are considerably
% different (i.e., other than missed strides)
indsStimStrideSlow = arrayfun(@(x) find((x-timeSHS) > 0,1,'last'), ...
    stimTimeSlowAbs);
indsStimStrideFast = arrayfun(@(x) find((x-timeFHS) > 0,1,'last'), ...
    stimTimeFastAbs);

% populate the times for the strides that have stimulation
stimTimeSlow(indsStimStrideSlow) = stimTimeSlowAbs - ...
    timeSHS(indsStimStrideSlow);
stimTimeFast(indsStimStrideFast) = stimTimeFastAbs - ...
    timeFHS(indsStimStrideFast);

% find the indices of the EMG data corresponding to the onset of the
% stimulation trigger pulse
indsEMGStimOnsetSlowAbs = arrayfun(@(x) find(x == EMGData.Time), ...
    stimTimeSlowAbs);
indsEMGStimOnsetFastAbs = arrayfun(@(x) find(x == EMGData.Time), ...
    stimTimeFastAbs);
numStimSlow = length(indsEMGStimOnsetSlowAbs);  % number of stimuli
numStimFast = length(indsEMGStimOnsetFastAbs);

% 20 ms after stimulus trigger pulse onset divided by sample period to get
% the number of samples after stim onset for the start of the H-wave window
winStart = 0.020 / EMGData.sampPeriod;
winEnd = 0.050 / EMGData.sampPeriod;    % 50 ms after stimulus pulse onset

for stS = 1:numStimSlow     % for each slow leg stimulus, ...
    % extract the EMG data for the time window of 20 ms - 50 ms from the
    % onset of the stimulus pulse
    indWinStart = indsEMGStimOnsetSlowAbs(stS) + winStart;
    indWinEnd = indsEMGStimOnsetSlowAbs(stS) + winEnd;
    winEMG = EMGSlow(indWinStart:indWinEnd);
    % compute amplitude of the H-waveform (i.e., peak-to-peak voltage)
    hReflexSlow(indsStimStrideSlow(stS)) = max(winEMG) - min(winEMG);
end

for stF = 1:numStimFast     % for each fast leg stimulus, ...
    % extract the EMG data for the time window of 20 ms - 50 ms from the
    % onset of the stimulus pulse
    indWinStart = indsEMGStimOnsetFastAbs(stF) + winStart;
    indWinEnd = indsEMGStimOnsetFastAbs(stF) + winEnd;
    winEMG = EMGFast(indWinStart:indWinEnd);
    % compute amplitude of the H-waveform (i.e., peak-to-peak voltage)
    hReflexFast(indsStimStrideFast(stF)) = max(winEMG) - min(winEMG);
end

%% Assign Parameters to the Data Matrix
data = nan(length(timeSHS),length(paramLabels));
for i=1:length(paramLabels)
    eval(['data(:,i)=' paramLabels{i} ';'])
end

%% Create parameterSeries
out = parameterSeries(data,paramLabels,[],description);

end

