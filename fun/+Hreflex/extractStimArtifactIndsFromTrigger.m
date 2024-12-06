function indsStimArtifact = extractStimArtifactIndsFromTrigger(times, ...
    rawEMG_TAP,HreflexStimPin)
%EXTRACTSTIMARTIFACTINDSFROMTRIGGER Extract TAP stim artifact peak indices
%   Extract the indices of the stimulation artifact peaks in the proximal
% tibialis anterior muscle raw EMG signal (which seems to be more robust
% than the stimulation artifact peak of the calf muscles, i.e., grastrocs
% or soleus, during walking) using the rising edge of the stimulation
% trigger pulse to localize the artifact peak.
%
% input:
%   times: number of samples x 1 array with the time in seconds from the
%       start of the trial for each sample
%   rawEMG_TAP: 2 x 1 cell array of number of samples x 1 arrays for right
%       (cell 1) and left (cell 2) leg proximal TA muscle EMG signal (NOTE:
%       if one cell is input as empty array, that leg will not be computed)
%   HreflexStimPin: labTimeSeries object of the data from the H-reflex
%       stimulation trigger pulse pin
% output:
%   indsStimArtifact: 2 x 1 cell array of number of stimuli x 1 arrays for
%       right (cell 1) and left (cell 2) leg stimulation artifact indices

narginchk(3,3); % verify correct number of input arguments
if isempty(times) || all(cellfun(@isempty,rawEMG_TAP)) || ...
        isempty(HreflexStimPin)
    error(['There is data missing that is crucial for computing the ' ...
        'stimulation artifact indices']);
end

% NOTE: it does not work to use stim trigger pulse to retrieve peak times
% if stimulator is disabled during trial (because there will be a trigger
% pulse but the participant will not have been stimulated)

% threshold to determine rising edge of stimulation trigger pulse
% TODO: consider making an optional input parameter
threshVolt = 2.5;
winStim = 0.1;          % +/- 100 ms of the onset of the stim trigger pulse
minPeakHeight = 0.001;  % 1 mV minimum stim artifact peak height

% extract all stimulation trigger data for each leg
% TODO: update to work in case of only one leg
stimTrigR = HreflexStimPin.Data(:,contains(HreflexStimPin.labels, ...
    'right','IgnoreCase',true));
stimTrigL = HreflexStimPin.Data(:,contains(HreflexStimPin.labels, ...
    'left','IgnoreCase',true));

% get stimulation onset times
stimTimeRAbs = getStimOnsetTimes(stimTrigR,times,threshVolt);
stimTimeLAbs = getStimOnsetTimes(stimTrigL,times,threshVolt);

% convert stimulation times to indices in the EMG signal
indsStimArtifact = cell(2, 1);
indsStimArtifact{1} = findStimArtifactInds(times,rawEMG_TAP{1}, ...
    stimTimeRAbs,winStim,minPeakHeight);
indsStimArtifact{2} = findStimArtifactInds(times,rawEMG_TAP{2}, ...
    stimTimeLAbs,winStim,minPeakHeight);

end

%% Helper Functions

function stimTimes = getStimOnsetTimes(stimTrig,times,threshVolt)
% detect rising edges of stimulation trigger pulses
indsStimAll = find(stimTrig > threshVolt);
% determine which indices correspond to start of new stimulus pulse
% (i.e., there is jump in index greater than 1, not just next sample)
indsNewPulse = diff([0; indsStimAll]) > 1;      % rising edges
% determine time since trial start when stim pulse began (rising edge)
stimTimes = times(indsStimAll(indsNewPulse));
end

function indsStimArtifact = findStimArtifactInds(times,rawEMG, ...
    stimTimes,winStim,minPeakHeight)
% identify stim artifact indices in EMG signal around stimulation times
if isempty(rawEMG) || isempty(stimTimes)    % if no EMG or stim data, ...
    indsStimArtifact = [];                  % return empty array
    return;
end

period = mean(diff(times));                 % sampling period
winSamples = round(winStim / period);       % search window dur. in samples
numStim = numel(stimTimes);                 % number of stimuli
indsStimArtifact = nan(numStim,1);          % initialize array of indices

for st = 1:numStim                          % for each stimulus, ...
    % locate EMG data index corresponding to onset of stim trigger pulse
    [~,indStim] = min(abs(times - stimTimes(st)));
    % ensure window does not exceed EMG data in case stim near trial end
    winSearch = max(1,indStim - winSamples): ...    % search window around
        min(length(rawEMG),indStim + winSamples);   % stimulation time
    [~,locs] = findpeaks(rawEMG(winSearch),'MinPeakHeight',minPeakHeight);

    if isempty(locs)                        % if no peaks detected, ...
        [~,indMaxTAP] = max(rawEMG(winSearch)); % use maximum value as peak
    else                                    % otherwise, ...
        indMaxTAP = locs(1);                % use first (earliest) peak
    end

    indsStimArtifact(st) = winSearch(indMaxTAP);
end

end

