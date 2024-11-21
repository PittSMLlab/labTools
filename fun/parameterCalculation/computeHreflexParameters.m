function [out] = computeHreflexParameters(strideEvents,HreflexData, ...
    EMGData,slowLeg)
%This function computes summary parameters per stride for the H-reflex data
% The output is a parameterSeries object, which can be concatenated with
% other parameterSeries objects, for example with those from
% computeTemporalParameters. While this is used for Hreflex parameters
% strictly, it should work for any labTS.
% See also computeSpatialParameters, computeTemporalParameters,
% computeForceParameters, parameterSeries

% TODO: accept GRF data as input argument (if necessary) to leave as NaN
% strides for which stim occurs during double rather than single stance

%% Gait Stride Event Times
timeSHS = strideEvents.tSHS;    % array of slow heel strike event times
timeFHS = strideEvents.tFHS;    % array of fast heel strike event times
timeSHS2 = strideEvents.tSHS2;
timeFHS2 = strideEvents.tFHS2;
% NaN values give false in logical comparison
indsComp = all(~isnan([timeSHS timeFHS]),2);    % comparison inds (no NaNs)
% TODO: could also check the SHS2 and FHS2 times to be ultra safe
isSlowFirst = all(timeSHS(indsComp) < timeFHS(indsComp));

%% Labels & Descriptions:
% H-reflex stimulation timing and amplitude parameters
% TODO: convert to mV rather than V here for readability of figures?
% TODO: add convenience parameter for percentage of stance phase
% TODO: add 'Amp' in parameter names for clarity?
% TODO: consider implementing Wilson Amplitude background EMG parameter
% TODO: noise floor EMG window is definitely incorrect for all
%       participants (e.g., SAH12 has EMG data in the window).
% TODO: store timing of the H- and M-waves?
% "The H-reflex amplitude is simply the peak-to-peak measurement of reflex,
% and the BEMG is the average rectified EMG amplitude present in the muscle
% for some period before the stimulation. The window for BEMG measurement
% is typically between 50 and 100 milliseconds."
%   "The Hoffmann reflex: Methodologic considerations and applications for
%   use in sports medicine and athletic training research" (Palmieri et
%   al.)
aux={'stimTimeSlow',        'time from SHS to slow leg stim (in s)'; ...
    'stimTimeFast',         'time from FHS to fast leg stim (in s)'; ...
    'isSingleStanceSlow',   'is stim during slow leg single stance phase'; ...
    'isSingleStanceFast',   'is stim during fast leg single stance phase'; ...
    'hReflexSlow',          'peak-to-peak voltage of the slow leg H-wave (in V)'; ...
    'hReflexFast',          'peak-to-peak voltage of the fast leg H-wave (in V)'; ...
    'mWaveSlow',            'peak-to-peak voltage of the slow leg M-wave (in V)'; ...
    'mWaveFast',            'peak-to-peak voltage of the fast leg M-wave (in V)'; ...
    'hReflexNoiseSlow',     'peak-to-peak voltage of the slow leg noise (in V)'; ...
    'hReflexNoiseFast',     'peak-to-peak voltage of the fast leg noise (in V)'; ...
    'hReflexBEMGMAVSlow',   'mean absolute value of the slow leg background EMG (in V)'; ...
    'hReflexBEMGMAVFast',   'mean absolute value of the fast leg background EMG (in V)'; ...
    'hReflexBEMGRMSSlow',   'root mean square of the slow leg background EMG (in V)'; ...
    'hReflexBEMGRMSFast',   'root mean square of the fast leg background EMG (in V)'; ...
    'h2mRatioSlow',         'ratio of the slow leg H-wave to M-wave amplitude'; ...
    'h2mRatioFast',         'ratio of the slow leg H-wave to M-wave amplitude'};

paramLabels = aux(:,1);
description = aux(:,2);

%% Compute the Parameters
% initialize parameter arrays: time of stimulation trigger pulse onset
% (i.e., rising edge) and H-wave amplitude (i.e., peak-to-peak voltage)
stimTimeSlow = nan(size(timeSHS));
stimTimeFast = nan(size(timeFHS));
isSingleStanceSlow = false(size(timeSHS));  % TODO: initialize true or NaN?
isSingleStanceFast = false(size(timeFHS));
hReflexSlow = nan(size(timeSHS));
hReflexFast = nan(size(timeFHS));
mWaveSlow = nan(size(timeSHS));
mWaveFast = nan(size(timeFHS));
hReflexNoiseSlow = nan(size(timeSHS));
hReflexNoiseFast = nan(size(timeFHS));
hReflexBEMGMAVSlow = nan(size(timeSHS));
hReflexBEMGMAVFast = nan(size(timeFHS));
hReflexBEMGRMSSlow = nan(size(timeSHS));
hReflexBEMGRMSFast = nan(size(timeFHS));
h2mRatioSlow = nan(size(timeSHS));
h2mRatioFast = nan(size(timeFHS));

times = EMGData.Time;   % extract time for trial
% use proximal TA to identify stim artifact time (localize by stim trigger)
EMG_RTAP = EMGData.Data(:,contains(EMGData.labels,'RTAP'));
EMG_LTAP = EMGData.Data(:,contains(EMGData.labels,'LTAP'));
indsStimArtifact = Hreflex.extractStimArtifactIndsFromTrigger(times, ...
    {EMG_RTAP;EMG_LTAP},HreflexData);

% use MG to compute H-reflex amplitudes
EMG_RMG = EMGData.Data(:,contains(EMGData.labels,'RMG'));
EMG_LMG = EMGData.Data(:,contains(EMGData.labels,'LMG'));
amps = Hreflex.computeAmplitudes({EMG_RMG;EMG_LMG},indsStimArtifact);
switch lower(slowLeg)   % which leg is slow, R or L
    case 'r'            % if right leg is slow, ...
        indSlow = 1;
        indFast = 2;
    case 'l'            % if left leg is slow, ...
        indSlow = 2;
        indFast = 1;
    otherwise           % otherwise, throw an error
        error('Invalid slow leg input argument, must be ''R'' or ''L''');
end

% find indices of nearest stride heel strike to the time of stim
% NOTE: this **should** be identical but may not be due to missed
% stimulation pulses, especially at start or end of trial (however,
% there should not be substantial differences in stride indices)
% TODO: add data check to warn if stride indices are considerably
% different (i.e., other than missed strides)
timeStimSlow = times(indsStimArtifact{indSlow});
timeStimFast = times(indsStimArtifact{indFast});

% discard stimuli that occur too early (e.g., when H-reflex stim happens
% during a transition into a new condition or before a first valid HS is
% detected) or too late (e.g., more than 1 second after final HS)
% TODO: 1 second may not be the correct threshold here
shouldDiscardStimSlow = (timeStimSlow <= timeSHS(1)) | ...
    (timeStimSlow >= (timeSHS(end)+1));
shouldDiscardStimFast = (timeStimFast <= timeFHS(1)) | ...
    (timeStimFast >= (timeFHS(end)+1));
timeStimSlow = timeStimSlow(~shouldDiscardStimSlow);
timeStimFast = timeStimFast(~shouldDiscardStimFast);

if any(shouldDiscardStimSlow)   % if discarding any stim, ...
    warning('Dropping %d stimuli for the slow leg', ...
        sum(shouldDiscardStimSlow));
end

if any(shouldDiscardStimFast)
    warning('Dropping %d stimuli for the fast leg', ...
        sum(shouldDiscardStimFast));
end

indsStimStrideSlow = arrayfun(@(x) ...
    find((x - timeSHS) > 0,1,'last'),timeStimSlow);
indsStimStrideFast = arrayfun(@(x) ...
    find((x - timeFHS) > 0,1,'last'),timeStimFast);

% populate the times for the strides that have stimulation
stimTimeSlow(indsStimStrideSlow) = timeStimSlow - ...
    timeSHS(indsStimStrideSlow);
stimTimeFast(indsStimStrideFast) = timeStimFast - ...
    timeFHS(indsStimStrideFast);
if isSlowFirst  % if slow leg heel strikes first, ...
    % TODO: conditions return false if time is NaN - implement handling
    isSingleStanceSlow(indsStimStrideSlow) = ...
        (timeStimSlow > timeSHS(indsStimStrideSlow)) & ...
        (timeStimSlow < timeFHS(indsStimStrideSlow));
    isSingleStanceFast(indsStimStrideFast) = ...
        (timeStimFast > timeFHS(indsStimStrideFast)) & ...
        (timeStimFast < timeSHS2(indsStimStrideFast));
else            % otherwise, fast leg heel strikes first, ...
    isSingleStanceFast(indsStimStrideFast) = ...
        (timeStimFast > timeFHS(indsStimStrideFast)) & ...
        (timeStimFast < timeSHS(indsStimStrideFast));
    isSingleStanceSlow(indsStimStrideSlow) = ...
        (timeStimSlow > timeSHS(indsStimStrideSlow)) & ...
        (timeStimSlow < timeFHS2(indsStimStrideSlow));
end

% remove stim values for steps to discard for each leg
amps(indSlow,:) = cellfun(@(x) x(~shouldDiscardStimSlow), ...
    amps(indSlow,:),'UniformOutput',false);
amps(indFast,:) = cellfun(@(x) x(~shouldDiscardStimFast), ...
    amps(indFast,:),'UniformOutput',false);

hReflexSlow(indsStimStrideSlow) = amps{indSlow,2};
hReflexFast(indsStimStrideFast) = amps{indFast,2};
mWaveSlow(indsStimStrideSlow) = amps{indSlow,1};
mWaveFast(indsStimStrideFast) = amps{indFast,1};
hReflexNoiseSlow(indsStimStrideSlow) = amps{indSlow,3};
hReflexNoiseFast(indsStimStrideFast) = amps{indFast,3};
hReflexBEMGMAVSlow(indsStimStrideSlow) = amps{indSlow,4};
hReflexBEMGMAVFast(indsStimStrideFast) = amps{indFast,4};
hReflexBEMGRMSSlow(indsStimStrideSlow) = amps{indSlow,5};
hReflexBEMGRMSFast(indsStimStrideFast) = amps{indFast,5};
h2mRatioSlow(indsStimStrideSlow) = amps{indSlow,2} ./ amps{indSlow,1};
h2mRatioFast(indsStimStrideFast) = amps{indFast,2} ./ amps{indFast,1};

%% Assign Parameters to the Data Matrix
data = nan(length(timeSHS),length(paramLabels));
for i=1:length(paramLabels)
    eval(['data(:,i)=' paramLabels{i} ';'])
end

%% Create parameterSeries
out = parameterSeries(data,paramLabels,[],description);

end

