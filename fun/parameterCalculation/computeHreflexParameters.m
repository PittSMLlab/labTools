function out = computeHreflexParameters(strideEvents,HreflexData, ...
    EMGData,slowLeg)
%This function computes summary parameters per stride for the H-reflex data
%   This function outputs a 'parameterSeries' object, which can be
% concatenated with other 'parameterSeries' objects, for example, with
% those from 'computeTemporalParameters'. While this function is used for
% H-reflex parameters exclusively, it should work for any 'labTS' object.
% This function computes summary parameters per stride across three
% different muscles: SOL, MG, and LG.
%
% See also computeSpatialParameters, computeTemporalParameters,
% computeForceParameters, parameterSeries

% TODO: accept GRF data as input argument (if necessary) to leave as NaN
% strides for which stim occurs during double rather than single stance

%% Gait Stride Event Times
timeSHS = strideEvents.tSHS;    % array of slow heel strike event times
timeFHS = strideEvents.tFHS;    % array of fast heel strike event times
timeSTO = strideEvents.tSTO;    % Slow Toe Off event times
timeFTO = strideEvents.tFTO;    % Fast Toe Off event times
timeSHS2 = strideEvents.tSHS2;  % 2nd Slow Heel Strike event times
timeFHS2 = strideEvents.tFHS2;  % 2nd Fast Heel Strike event times

% NaN values give false in logical comparison
indsComp = all(~isnan([timeSHS timeFHS]),2);    % comparison inds (no NaNs)
% TODO: could also check the SHS2 and FHS2 times to be ultra safe
isSlowFirst = all(timeSHS(indsComp) < timeFHS(indsComp));

%% Labels & Descriptions
muscles = {'SOL','MG','LG'};
% H-reflex stimulation timing and amplitude parameters
% TODO: add convenience parameter for percentage of stance phase
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
aux={'stimTimeFromStanceSlow',        'time from SHS to slow leg stim (in s)'; ...
    'stimTimeFromStanceFast',         'time from FHS to fast leg stim (in s)'; ...
    'stimTimeFromSingleStanceSlow',     'time from FTO to slow leg stim (in s)'; ...
    'stimTimeFromSingleStanceFast',     'time from STO to fast leg stim (in s)'
    'isSingleStanceSlow',   'is stim during slow leg single stance phase'; ...
    'isSingleStanceFast',   'is stim during fast leg single stance phase'; ...
    'HwaveAmpSlowSOL',          'peak-to-peak voltage of the slow leg H-wave (in mV)'; ...
    'HwaveAmpFastSOL',          'peak-to-peak voltage of the fast leg H-wave (in mV)'; ...
    'MwaveAmpSlowSOL',            'peak-to-peak voltage of the slow leg M-wave (in mV)'; ...
    'MwaveAmpFastSOL',            'peak-to-peak voltage of the fast leg M-wave (in mV)'; ...
    'HreflexNoiseSlowSOL',     'peak-to-peak voltage of the slow leg noise (in mV)'; ...
    'HreflexNoiseFastSOL',     'peak-to-peak voltage of the fast leg noise (in mV)'; ...
    'H2MratioSlowSOL',         'ratio of the slow leg H-wave to M-wave amplitude'; ...
    'H2MratioFastSOL',         'ratio of the slow leg H-wave to M-wave amplitude'; ...
    'HwaveAmpSlowMG',       'peak-to-peak voltage of the slow leg MG H-wave (in mV)'; ...
    'HwaveAmpFastMG',       'peak-to-peak voltage of the fast leg MG H-wave (in mV)'; ...
    'MwaveAmpSlowMG',       'peak-to-peak voltage of the slow leg M-wave (in mV)'; ...
    'MwaveAmpFastMG',       'peak-to-peak voltage of the fast leg M-wave (in mV)'; ...
    'HreflexNoiseSlowMG',     'peak-to-peak voltage of the slow leg noise (in mV)'; ...
    'HreflexNoiseFastMG',     'peak-to-peak voltage of the fast leg noise (in mV)'; ...
    'H2MratioSlowMG',         'ratio of the slow leg H-wave to M-wave amplitude'; ...
    'H2MratioFastMG',         'ratio of the slow leg H-wave to M-wave amplitude'; ...
    'HwaveAmpSlowLG',          'peak-to-peak voltage of the slow leg H-wave (in mV)'; ...
    'HwaveAmpFastLG',          'peak-to-peak voltage of the fast leg H-wave (in mV)'; ...
    'MwaveAmpSlowLG',            'peak-to-peak voltage of the slow leg M-wave (in mV)'; ...
    'MwaveAmpFastLG',            'peak-to-peak voltage of the fast leg M-wave (in mV)'; ...
    'HreflexNoiseSlowLG',     'peak-to-peak voltage of the slow leg noise (in mV)'; ...
    'HreflexNoiseFastLG',     'peak-to-peak voltage of the fast leg noise (in mV)'; ...
    'H2MratioSlowLG',         'ratio of the slow leg H-wave to M-wave amplitude'; ...
    'H2MratioFastLG',         'ratio of the slow leg H-wave to M-wave amplitude'; ...
    };

% TODO: Re-add background EMG parameters
% 'HreflexBEMGMAVSlowSOL',   'mean absolute value of the slow leg background EMG (in mV)'; ...
% 'HreflexBEMGMAVFastSOL',   'mean absolute value of the fast leg background EMG (in mV)'; ...
% 'HreflexBEMGRMSSlowSOL',   'root mean square of the slow leg background EMG (in mV)'; ...
% 'HreflexBEMGRMSFastSOL',   'root mean square of the fast leg background EMG (in mV)'; ...
% 'HreflexBEMGMAVSlowMG',   'mean absolute value of the slow leg background EMG (in mV)'; ...
% 'HreflexBEMGMAVFastMG',   'mean absolute value of the fast leg background EMG (in mV)'; ...
% 'HreflexBEMGRMSSlowMG',   'root mean square of the slow leg background EMG (in mV)'; ...
% 'HreflexBEMGRMSFastMG',   'root mean square of the fast leg background EMG (in mV)'; ...
% 'HreflexBEMGMAVSlowLG',   'mean absolute value of the slow leg background EMG (in mV)'; ...
% 'HreflexBEMGMAVFastLG',   'mean absolute value of the fast leg background EMG (in mV)'; ...
% 'HreflexBEMGRMSSlowLG',   'root mean square of the slow leg background EMG (in mV)'; ...
% 'HreflexBEMGRMSFastLG',   'root mean square of the fast leg background EMG (in mV)'; ...

paramLabels = aux(:,1);
description = aux(:,2);

%% Compute the Parameters
% initialize parameter arrays: time of stimulation trigger pulse onset
% (i.e., rising edge) and H-wave amplitude (i.e., peak-to-peak voltage)
stimTimeFromStanceSlow = nan(size(timeSHS));
stimTimeFromStanceFast = nan(size(timeFHS));
stimTimeFromSingleStanceSlow = nan(size(timeSHS));
stimTimeFromSingleStanceFast = nan(size(timeFHS));
isSingleStanceSlow = false(size(timeSHS));  % TODO: initialize true or NaN?
isSingleStanceFast = false(size(timeFHS));
HwaveAmpSlowSOL = nan(size(timeSHS));
HwaveAmpFastSOL = nan(size(timeFHS));
MwaveAmpSlowSOL = nan(size(timeSHS));
MwaveAmpFastSOL = nan(size(timeFHS));
HreflexNoiseSlowSOL = nan(size(timeSHS));
HreflexNoiseFastSOL = nan(size(timeFHS));
% HreflexBEMGMAVSlowSOL = nan(size(timeSHS));
% HreflexBEMGMAVFastSOL = nan(size(timeFHS));
% HreflexBEMGRMSSlowSOL = nan(size(timeSHS));
% HreflexBEMGRMSFastSOL = nan(size(timeFHS));
H2MratioSlowSOL = nan(size(timeSHS));
H2MratioFastSOL = nan(size(timeFHS));

%% Identify Stimulus Artifact Indices
times = EMGData.Time;   % extract time for trial
% use proximal TA to identify stim artifact time (localize by stim trigger)
EMG_RTAP = EMGData.Data(:,contains(EMGData.labels,'RTAP'));
EMG_LTAP = EMGData.Data(:,contains(EMGData.labels,'LTAP'));

stimTrigR = HreflexData.getDataAsVector( ...
    'Stimulator_Trigger_Sync_Right_Stimulator');
stimTrigL = HreflexData.getDataAsVector( ...
    'Stimulator_Trigger_Sync_Left__Stimulator');
indsStimArtifact = Hreflex.extractStimArtifactIndsFromTrigger( ...
    times,{EMG_RTAP,EMG_LTAP},{stimTrigR,stimTrigL});

if all(cellfun(@isempty,indsStimArtifact))
    data = nan(length(timeSHS),length(paramLabels));
    for i=1:length(paramLabels)
        eval(['data(:,i)=' paramLabels{i} ';'])
    end
    out = parameterSeries(data,paramLabels,[],description);
    return;
end

%% Extract EMG Signal for Each Muscle of Interest
EMG_RSOL = EMGData.Data(:, contains(EMGData.labels, 'RSOL'));
EMG_LSOL = EMGData.Data(:, contains(EMGData.labels, 'LSOL'));
EMG_RMG = EMGData.Data(:, contains(EMGData.labels, 'RMG'));
EMG_LMG = EMGData.Data(:, contains(EMGData.labels, 'LMG'));
EMG_RLG = EMGData.Data(:, contains(EMGData.labels, 'RLG'));
EMG_LLG = EMGData.Data(:, contains(EMGData.labels, 'LLG'));

% use MG to compute H-reflex amplitudes
EMG_RSOL = EMGData.Data(:,contains(EMGData.labels,'RSOL'));
EMG_LSOL = EMGData.Data(:,contains(EMGData.labels,'LSOL'));

snippets = Hreflex.extractSnippets(indsStimArtifact,{EMG_RSOL; EMG_LSOL});
amps = Hreflex.computeAmplitudes(snippets(:,1));
% convert wave amplitudes from Volts to Millivolts
amps = cellfun(@(x) 1000.*x,amps,'UniformOutput',false);
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
% different across legs (i.e., not including strides where stim was missed)
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
stimTimeFromStanceSlow(indsStimStrideSlow) = timeStimSlow - ...
    timeSHS(indsStimStrideSlow);
stimTimeFromStanceFast(indsStimStrideFast) = timeStimFast - ...
    timeFHS(indsStimStrideFast);
stimTimeFromSingleStanceSlow(indsStimStrideSlow) = timeStimSlow - ...
    timeFTO(indsStimStrideSlow);
stimTimeFromSingleStanceFast(indsStimStrideFast) = timeStimFast - ...
    timeSTO(indsStimStrideFast);
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

HwaveAmpSlowSOL(indsStimStrideSlow) = amps{indSlow,2};
HwaveAmpFastSOL(indsStimStrideFast) = amps{indFast,2};
MwaveAmpSlowSOL(indsStimStrideSlow) = amps{indSlow,1};
MwaveAmpFastSOL(indsStimStrideFast) = amps{indFast,1};
HreflexNoiseSlowSOL(indsStimStrideSlow) = amps{indSlow,3};
HreflexNoiseFastSOL(indsStimStrideFast) = amps{indFast,3};
% HreflexBEMGMAVSlow(indsStimStrideSlow) = amps{indSlow,4};
% HreflexBEMGMAVFast(indsStimStrideFast) = amps{indFast,4};
% HreflexBEMGRMSSlow(indsStimStrideSlow) = amps{indSlow,5};
% HreflexBEMGRMSFast(indsStimStrideFast) = amps{indFast,5};
H2MratioSlowSOL(indsStimStrideSlow) = amps{indSlow,2} ./ amps{indSlow,1};
H2MratioFastSOL(indsStimStrideFast) = amps{indFast,2} ./ amps{indFast,1};

%% Assign Parameters to the Data Matrix
data = nan(length(timeSHS),length(paramLabels));
for i=1:length(paramLabels)
    eval(['data(:,i)=' paramLabels{i} ';'])
end

%% Output the Computed Parameters
out = parameterSeries(data,paramLabels,[],description);

end

