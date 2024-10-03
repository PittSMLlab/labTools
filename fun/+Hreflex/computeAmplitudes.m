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
%   amps: 2 x 5 cell array of number of stimuli x 1 arrays for right (row
%       1) and left (row 2) leg H-reflex amplitudes: M-wave (column 1),
%       H-wave (column 2), noise (column 3), background EMG MAV (column 4),
%       and background EMG RMS (column 5)
%   durs: 2 x 2 cell array of number of stimuli x 1 arrays for right (row
%       1) and left (row 2) leg M-wave (column 1) and H-wave (column 2)
%       durations (i.e., absolute time difference between the minimum and
%       maximum values) for determining whether a valid wave

% TODO: Incorporate call to H-reflex snippet extraction here for modularity
% so that there is a clean linear process of extracting stimulation
% indices, then snippets, then amplitudes?
% TODO: reject measurements if GRF reveals not in single stance (prefer
% outside of this function so do not have to pass as input parameter and
% this function gives more or less the 'raw' amplitudes besides more basic
% rejection based on the H-reflex waveform itself)

narginchk(2,2);     % verify correct number of input arguments
amplitudes = cell(2,5);   % instantiate output amplitudes cell array
durations = cell(2,2);   % instantiate output wave durations cell array

% if both cells are empty arrays for either input argument, ...
if all(cellfun(@isempty,indsStimArtifact)) || ...
        all(cellfun(@isempty,rawEMG_MG))
    warning(['There is data missing necessary to compute the H-reflex ' ...
        'amplitudes.']);
    return;
end

% NOTE: should always be same across trials and should be same for forces
% TODO: make optional input argument
period = 0.0005; % EMG.sampPeriod;    % sampling period
% TODO: update to include the M- and H-wave value by default and only set
% to NaN if determined to be an invalid measurement by more stringent
% criteria, store the indices at which the min and max occur to determine
% the mode (or median?) samples at which the wave peak and trough occur to
% compute values in the cases when errant points are selected

% TODO: make indices optional input argument with default to avoid
% duplication across multiple code locations
% TODO: consider combining into single matrix for simplicity
% M-wave is contained by interval:           4ms -  23ms after stim. art.
% H-wave is contained by interval:          24ms -  43ms
% TODO: is noise window correct? GTO requested between M- & H-waves
% Noise is contained by interval:           20ms -  25ms
% Background EMG is contained by interval: -99ms - -50ms (neg. = before)
indsStart = [0.004 0.024 0.020 -0.099] ./ period;   % convert to samples
indsEnd = [0.023 0.049 0.025 -0.050] ./ period;
% NOTE: number of start and end indices MUST be identical

% TODO: consider using noise mean to compute threshold for edge case values
% TODO: loop through number of legs present to handle case of only one leg
% compute H-reflex amplitudes for each leg
[amplitudes(1,:),durations(1,:)] = computeAmpsOneLeg(rawEMG_MG{1}, ...
    indsStimArtifact{1},indsStart,indsEnd,period);
[amplitudes(1,:),durations(1,:)] = computeAmpsOneLeg(rawEMG_MG{1}, ...
    indsStimArtifact{1},indsStart,indsEnd,period);
[amplitudes(2,:),durations(2,:)] = computeAmpsOneLeg(rawEMG_MG{2}, ...
    indsStimArtifact{2},indsStart,indsEnd,period);

end

function [amps,durs] = computeAmpsOneLeg(rawEMG,indsStimArt, ...
    indsWinStart,indsWinEnd,per)
%COMPUTEAMPSONESTIM Computes H-reflex amplitudes for single stimulus (leg)
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
%   indsWinStart:
%   indsWinEnd:
%   per: EMG data sampling period
% output:
%   amps: 1 x 5 cell array of number of stimuli x 1 arrays for right or
%       left leg H-reflex amplitudes: M-wave (column 1), H-wave (column 2),
%       noise (column 3), background EMG MAV (column 4), and background EMG
%       RMS (column 5)
%   durs: 1 x 2 cell array of number of stimuli x 1 arrays for right or
%       left leg M-wave (column 1) and H-wave (column 2) durations (i.e.,
%       absolute time difference between the minimum and maximum values)
%       for determining whether a valid wave

% TODO: add inputs checks (e.g., indStim not outside rawEMG array bounds)
narginchk(5,5);                     % verify correct # of input arguments
amps = cell(1,5);   % instantiate output amplitudes cell array
durs = cell(1,2);   % instantiate output wave durations cell array

numStim = length(indsStimArt);          % number of stimuli
% initialize output amplitudes and durations arrays
% TODO: is below initialization necessary or beneficial?
amps = cellfun(@(x) nan(numStim,1),amps,'UniformOutput',false);
durs = cellfun(@(x) nan(numStim,1),durs,'UniformOutput',false);
% NOTE: increased threshold from 8ms to 10ms to include more waveforms
threshDur = 0.010;                  % 10ms is longest valid M/H-wave dur.
numWins = length(indsWinStart);     % # of windows to extract data from

for st = 1:numStim                      % for each stimulus, ...
    indStim = indsStimArt(st);          % stimulation index
    for win = 1:numWins                 % for each stim snippet window, ...
        indsWin = (indStim+indsWinStart(win)):(indStim+indsWinEnd(win));
        % ensure do not index outside of EMG bounds if stim near end trial
        indsWin = indsWin(indsWin < length(rawEMG));
        % extract EMG data for time windows from stim artifact onset
        if ~isempty(indsWin)
            winEMG = rawEMG(indsWin);   % extract EMG time window data
            [valMax,indMax] = max(winEMG);
            [valMin,indMin] = min(winEMG);
        else
            valMax = nan; indMax = nan;
            valMin = nan; indMin = nan;
        end
        % TODO: add check that M-wave and H-wave are not too broad in lieu
        % of or in addition to check that min or max are not early or late
        % in EMG window
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

