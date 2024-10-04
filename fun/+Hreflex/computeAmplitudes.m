function [amplitudes,durations] = computeAmplitudes(rawEMG_MG, ...
    indsStimArtifact)
%COMPUTEHREFLEXAMPLITUDES Compute amplitudes of interest from H-reflex
%   Compute the peak-to-peak amplitudes of the M-wave, H-wave, noise floor,
% and the mean absolute value (MAV) and root mean square (RMS) of the
% background EMG (for possible future normalization).
%
% input:
%   rawEMG_MG: 2 x 1 cell array of number of samples x 1 arrays for right
%       (cell 1) and left (cell 2) leg MG muscle EMG signal (NOTE: if one
%       cell is input as empty array, that leg will not be computed)
%   indsStimArtifact: 2 x 1 cell array of number of stimuli x 1 arrays for
%       right (cell 1) and left (cell 2) leg stimulus artifact indices for
%       H-reflex alignment
% output:
%   amplitudes: 2 x 5 cell array of number of stimuli x 1 arrays for right
%       (row 1) and left (row 2) leg H-reflex amplitudes: M-wave (column
%       1), H-wave (column 2), noise (column 3), background EMG MAV (column
%       4), and background EMG RMS (column 5)
%   durations: 2 x 2 cell array of number of stimuli x 1 arrays for right
%       (row 1) and left (row 2) leg M-wave (column 1) and H-wave (column
%       2) durations (i.e., absolute time difference between the minimum
%       and maximum values) for determining whether a valid wave

% TODO:
%   1. incorporate call to H-reflex snippet extraction here for modularity
%   so that there is a clean, linear process of extracting stimulation
%   indices, then snippets, then amplitudes?
%   2. reject measurements if GRF reveals not in single stance
%       NOTE: I prefer to reject measurements (i.e., implement quality
%       checks) outside of this function so that this function gives more
%       or less the 'raw' amplitudes besides basic rejection to avoid
%       passing more input parameters
%       NOTE: it may be beneficial to store the indices at which the min
%       and max occur to determine the mode (or median?) samples at which
%       the wave peak and trough occur to compute values in cases where
%       errant indices are selected (for getting a value from noisy data)
%       it may be inappropriate to set the value to NaN when it is merely a
%       low value comparable to noise floor (more stringent for invalid)
%   3. make window indices optional input argument with default to avoid
%   duplication across multiple code locations
%   4. consider using noise mean to compute threshold for edge case values
%   5. dynamically set the window bounds (especially the noise window)
%   based on the H-reflex data (this may allow the noise window to be
%   broader than it currently is)

narginchk(2,2);             % verify correct number of input arguments
amplitudes = cell(2,5);     % instantiate output amplitudes cell array
durations = cell(2,2);      % instantiate output wave durations cell array

% if both cells are empty arrays for either input argument, ...
if all(cellfun(@isempty,indsStimArtifact)) || ...
        all(cellfun(@isempty,rawEMG_MG))
    warning(['There is data missing necessary to compute the H-reflex ' ...
        'amplitudes.']);
    return;
end

% NOTE: should always be same across trials and should be same for forces
% TODO: make optional input argument
period = 0.0005;                                    % sampling period
% M-wave is contained by interval:           4ms -  23ms after stim. art.
% H-wave is contained by interval:          24ms -  43ms
% TODO: is noise window correct? GTO requested between M- & H-waves
% Noise is contained by interval:           20ms -  25ms
% Background EMG is contained by interval: -99ms - -50ms (neg. = before)
indsWindows = [0.004 0.024 0.020 -0.099;
    0.023 0.049 0.025 -0.050] ./ period; % convert to samples

% compute H-reflex amplitudes for each leg
[amplitudes(1,:),durations(1,:)] = computeAmpsOneLeg(rawEMG_MG{1}, ...
    indsStimArtifact{1},indsWindows,period);
[amplitudes(2,:),durations(2,:)] = computeAmpsOneLeg(rawEMG_MG{2}, ...
    indsStimArtifact{2},indsWindows,period);

end

function [amps,durs] = computeAmpsOneLeg(rawEMG,indsStimArt,indsWinsRel,per)
%COMPUTEAMPSONESTIM Computes H-reflex amplitudes for a single leg
%   This function accepts the raw EMG data (from the MG muscle of a single
% leg) as input along with the stimulation artifact indices for alignment
% and computes the H-reflex amplitudes for the M-wave, H-wave, noise, and
% background EMG (MAV and RMS) for one leg. The purpose of this helper
% function is to consolidate the H-reflex computations rather than
% duplicating the same code across both legs.
%
% input(s):
%   rawEMG: number of samples x 1 array of right or left leg MG muscle EMG
%       signal
%   indsStimArt: number of stimuli x 1 array of right or left leg stimulus
%       artifact indices for H-reflex alignment
%   indsWinsRel: 2 x 5 array of snippet window of interest start and stop
%       indices
%   per: EMG data sampling period
% output(s):
%   amps: 1 x 5 cell array of number of stimuli x 1 arrays for right or
%       left leg H-reflex amplitudes: M-wave (column 1), H-wave (column 2),
%       noise (column 3), background EMG MAV (column 4), and background EMG
%       RMS (column 5)
%   durs: 1 x 2 cell array of number of stimuli x 1 arrays for right or
%       left leg M-wave (column 1) and H-wave (column 2) durations (i.e.,
%       absolute time difference between the minimum and maximum values)
%       for determining whether a valid wave

narginchk(4,4);                 % verify correct number of input arguments

if isempty(indsStimArt)         % if no stimulation artifact indices, ...
    error(['There are no stimulation artifact indices for which to ' ...
        'extract the H-reflex amplitudes.']);   % return with error message
end

numStim = length(indsStimArt);  % number of stimuli
% NOTE: increased threshold from 8ms to 10ms to include more waveforms
threshDur = 0.010;              % 10ms is longest valid M/H-wave duration
numWins = size(indsWinsRel,2);  % number of windows to extract data from
% TODO: add inputs checks (e.g., indStim not outside rawEMG array bounds)

amps = cell(1,5);           % instantiate output amplitudes cell array
durs = cell(1,2);           % instantiate output wave durations cell array
% initialize output amplitudes and durations arrays
amps = cellfun(@(x) nan(numStim,1),amps,'UniformOutput',false);
durs = cellfun(@(x) nan(numStim,1),durs,'UniformOutput',false);

if isempty(rawEMG)              % if no EMG data provided, ...
    warning(['There is no EMG data provided from which to extract the ' ...
        'H-reflex amplitudes.']);   % TODO: indicate which leg missing data
    return;                     % return with 'NaN' value output
end

for st = 1:numStim                      % for each stimulus, ...
    indStim = indsStimArt(st);          % stimulation index
    for win = 1:numWins                 % for each stim snippet window, ...
        indsWinAbs = (indStim + indsWinsRel(1,win)): ...
            (indStim + indsWinsRel(2,win));
        % ensure do not index outside of EMG bounds if stim near end trial
        indsWinAbs = indsWinAbs(indsWinAbs < length(rawEMG));
        % extract EMG data for time windows from stim artifact onset
        if ~isempty(indsWinAbs)
            winEMG = rawEMG(indsWinAbs);   % extract EMG time window data
            [valMax,indMax] = max(winEMG);
            [valMin,indMin] = min(winEMG);
        else
            valMax = nan; indMax = nan;
            valMin = nan; indMin = nan;
        end
        % TODO: add check that M/H-wave are not too broad in lieu of or in
        % addition to check that min or max are not early or late in window
        switch win
            case {1,2}                  % M-wave or H-wave
                durs{win}(st) = per * abs(indMax - indMin);
                % TODO: improve sample rejection (want to be liberal in
                % keeping samples unless good reason to reject and even
                % then may want the noisy value as long as it's not
                % deceptively high)
                % NOTE: it does not make sense to eliminate samples based
                % on the location of the peaks alone since the H-wave can
                % vary in latency based on age, height, and other factors
                % if wave duration is less than threshold, ...
                if durs{win}(st) <= threshDur
                    amps{win}(st) = valMax - valMin;
                else                    % otherwise, ...
                    % leave as NaN
                end
                % if min or max index not w/in 1st or last two samps, ...
                % numPnts = length(winEMG);   % number of points in window
                % if ~(any(indMin == [1 2]) || any(indMax == [1 2]) || ...
                %         any(indMin == [numPnts-1 numPnts]) || ...
                %         any(indMax == [numPnts-1 numPnts]))
                %     % compute peak-to-peak voltage
                %     amps(win) = valMax - valMin;
                % else                    % otherwise, ...
                %     % leave as NaN (previously set to noise floor thresh.)
                % end
            case 3                      % noise window
                amps{win}(st) = valMax - valMin;
            case 4                      % background EMG window
                % compute mean absolute value (MAV) of background EMG wind.
                amps{win}(st) = mean(abs(winEMG));
                % compute root mean square (RMS) of background EMG window
                amps{win+1}(st) = sqrt(mean(winEMG.^2));
            otherwise
                % not possible to enter this statement
        end
    end
end

end

