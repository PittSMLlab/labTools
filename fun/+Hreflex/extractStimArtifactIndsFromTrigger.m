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
% TODO: add checks that inputs are not empty or otherwise invalid
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
period = HreflexStimPin.sampPeriod;

% extract all stimulation trigger data for each leg
% TODO: update to work in case of only one leg
stimTrigR = HreflexStimPin.Data(:,contains(HreflexStimPin.labels, ...
    'right','IgnoreCase',true));
stimTrigL = HreflexStimPin.Data(:,contains(HreflexStimPin.labels, ...
    'left','IgnoreCase',true));

% determine indices when stimulus trigger is high (to stimulate)
indsStimRAll = find(stimTrigR > threshVolt);
indsStimLAll = find(stimTrigL > threshVolt);

% determine which indices correspond to start of new stimulus pulse
% (i.e., there is jump in index greater than 1, not just next sample)
indsNewPulseR = diff([0; indsStimRAll]) > 1;
indsNewPulseL = diff([0; indsStimLAll]) > 1;

% determine time since trial start when stim pulse began (rising edge)
stimTimeRAbs = HreflexStimPin.Time(indsStimRAll(indsNewPulseR));
stimTimeLAbs = HreflexStimPin.Time(indsStimLAll(indsNewPulseL));

% find the indices of the EMG data corresponding to the onset of the
% stimulation trigger pulse
indsEMGStimOnsetRAbs = arrayfun(@(x) find(x == times),stimTimeRAbs);
indsEMGStimOnsetLAbs = arrayfun(@(x) find(x == times),stimTimeLAbs);

numStimR = length(indsEMGStimOnsetRAbs);    % number of stimuli
numStimL = length(indsEMGStimOnsetLAbs);

% initialize array of indices determined by the stim artifact
indsStimArtifactR = nan(size(indsEMGStimOnsetRAbs));
indsStimArtifactL = nan(size(indsEMGStimOnsetLAbs));

winStim = 0.1 / period; % +/- 100 ms of the onset of the stim trigger pulse

% TODO: handle case of two peaks within window and smaller one is closer to
% time of stimulus onset and the correct peak for H-reflex alignment
% TODO: implement more robust peak finding and discrepancy handling
% consider moving into a function or reducing loops
for stR = 1:numStimR                    % for each right leg stimulus, ...
    winSearch = (indsEMGStimOnsetRAbs(stR) - winStim): ...
        (indsEMGStimOnsetRAbs(stR) + winStim);
    [~,indMaxTAP] = max(rawEMG_TAP{1}(winSearch));  % find artifact peak
    timesWin = times(winSearch);
    timeStimStart = timesWin(indMaxTAP);
    indsStimArtifactR(stR) = find(times == timeStimStart);
end

for stL = 1:numStimL                    % for each left leg stimulus, ...
    winSearch = (indsEMGStimOnsetLAbs(stL) - winStim): ...
        (indsEMGStimOnsetLAbs(stL) + winStim);
    [~,indMaxTAP] = max(rawEMG_TAP{2}(winSearch));
    timesWin = times(winSearch);
    timeStimStart = timesWin(indMaxTAP);
    indsStimArtifactL(stL) = find(times == timeStimStart);
end

indsStimArtifact = {indsStimArtifactR;indsStimArtifactL};

% TODO: accept plot optional input
% Hreflex.plotStimArtifactPeaks(times,{EMG_RTAP,EMG_LTAP}, ...
%     {locsR,locsL},id,trialNum,pathFigs);

end

