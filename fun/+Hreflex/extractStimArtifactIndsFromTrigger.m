function indsStimArtifact = extractStimArtifactIndsFromTrigger(times, ...
    rawEMG_TAP,pinHreflexStim,varargin)
%EXTRACTSTIMARTIFACTINDSFROMTRIGGER Extract TAP stim artifact peak indices
%   Extract the indices of the stimulation artifact peaks in the proximal
% tibialis anterior muscle raw EMG signal (which seems to be more robust
% than the stimulation artifact peak of the calf muscles, i.e., grastrocs
% or soleus, during walking) using the rising edge of the stimulation
% trigger pulse to localize the artifact peak.
%
% input(s):
%   times: number of samples x 1 array of the time in seconds from the
%       start of the trial for each sample
%   rawEMG_TAP: 2 x 1 cell array of number of samples x 1 arrays for right
%       (cell 1) and left (cell 2) leg proximal TA muscle EMG signal (NOTE:
%       if one cell is input as empty array, that leg will not be computed)
%   pinHreflexStim: 2 x 1 cell array of number of samples x 1 arrays for
%       right (cell 1) and left (cell 2) H-reflex stimulator trigger pulses
%   varargin: optional inputs (name-value pairs)
%       - 'threshStim': stimulation trigger pulse detection threshold
%                       (default: 2.5 V)
%       - 'winDurStim': search window duration around trigger pulse
%                       (default: 0.1 seconds)
%       - 'minArtifactPeak': minimum stimulation artifact peak height for
%                            detection (default: 0.001 V)
% output:
%   indsStimArtifact: 2 x 1 cell array of number of stimuli x 1 arrays for
%       right (cell 1) and left (cell 2) leg stimulation artifact indices

if isempty(times) || all(cellfun(@isempty,rawEMG_TAP)) || ...
        all(cellfun(@isempty,pinHreflexStim))   % validate input arguments
    error(['There is data missing that is crucial for computing the ' ...
        'stimulation artifact indices']);
end

% NOTE: it does not work to use stim trigger pulse to retrieve peak times
% if stimulator is disabled during trial (because there will be a trigger
% pulse but the participant will not have been stimulated)

p = inputParser;        % parse optional inputs
addParameter(p,'threshStim',2.5,@(x) isnumeric(x) && x > 0);
addParameter(p,'winDurStim',0.1,@(x) isnumeric(x) && x > 0);
addParameter(p,'minArtifactPeak',0.001,@(x) isnumeric(x) && x > 0);
parse(p,varargin{:});

threshStim = p.Results.threshStim;  % stim trigger pulse threshold (V)
winDurStim = p.Results.winDurStim;  % +/- 100 ms of stim pulse onset
minPeak = p.Results.minArtifactPeak;% 1 mV min. stim artifact peak height

% get stimulation onset times
stimTimeRAbs = getStimOnsetTimes(pinHreflexStim{1},times,threshStim);
stimTimeLAbs = getStimOnsetTimes(pinHreflexStim{2},times,threshStim);

% convert stimulation times to indices in the EMG signal
indsStimArtifact = cell(2, 1);
indsStimArtifact{1} = findStimArtifactInds(times,rawEMG_TAP{1}, ...
    stimTimeRAbs,winDurStim,minPeak);
indsStimArtifact{2} = findStimArtifactInds(times,rawEMG_TAP{2}, ...
    stimTimeLAbs,winDurStim,minPeak);

end

%% Helper Functions

function stimTimes = getStimOnsetTimes(stimTrig,times,threshStim)
% detect rising edges of stimulation trigger pulses
indsStimAll = find(stimTrig > threshStim);
% determine which indices correspond to start of new stimulus pulse
% (i.e., there is jump in index greater than 1, not just next sample)
indsNewPulse = diff([0; indsStimAll]) > 1;      % rising edges
% determine time since trial start when stim pulse began (rising edge)
stimTimes = times(indsStimAll(indsNewPulse));
end

function indsStimArtifact = findStimArtifactInds(times,rawEMG, ...
    stimTimes,winDurStim,minPeakHeight)
% identify stim artifact indices in EMG signal around stimulation times
if isempty(rawEMG) || isempty(stimTimes)    % if no EMG or stim data, ...
    indsStimArtifact = [];                  % return empty array
    return;
end

period = mean(diff(times));                 % sampling period
winSamples = round(winDurStim / period);    % search window dur. in samples
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

