function amps = computeHreflexAmplitudes(rawEMG_MG,indsStimArtifact)
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
%   amps: 2 x 5 cell array of number of stimuli x 1 arrays for
%       right (row 1) and left (row 2) leg H-reflex amplitudes: M-wave
%       (column 1), H-wave (column 2), noise (column 3), background EMG MAV
%       (column 4), and background EMG RMS (column 5)

% TODO: reject measurements if GRF reveals not in single stance (prefer
% outside of this function so do not have to pass as input parameter and
% this function gives more or less the 'raw' amplitudes besides more basic
% rejection based on the H-reflex waveform itself)

narginchk(2,2);     % verify correct number of input arguments
amps = cell(2,5);   % instantiate output amplitudes cell array

% if both cells are empty arrays for either input argument, ...
if all(cellfun(@isempty,indsStimArtifact)) || ...
        all(cellfun(@isempty,rawEMG_MG))
    warning(['There is data missing necessary to compute the H-reflex ' ...
        'amplitudes.']);
    return;
end

numStimR = length(indsStimArtifact{1}); % number of right leg stimuli
numStimL = length(indsStimArtifact{2}); % number of left leg stimuli
% initialize output amplitudes arrays
amps(1,:) = cellfun(@(x) nan(numStimR,1),amps(1,:),'UniformOutput',false);
amps(2,:) = cellfun(@(x) nan(numStimL,1),amps(2,:),'UniformOutput',false);

% NOTE: should always be same across trials and should be same for forces
% TODO: make optional input argument
period = 0.0005; % EMG.sampPeriod;    % sampling period
% TODO: make indices optional input argument with default option to avoid
% having these values duplicated in multiple locations
% M-wave is contained by interval:           4ms -  23ms after stim. art.
% H-wave is contained by interval:          24ms -  43ms
% Noise is contained by interval:           50ms -  99ms % TODO: is noise window right?
% Background EMG is contained by interval: -99ms - -50ms (neg. = before)
indsStart = [0.004 0.024 0.050 -0.099] ./ period;   % convert to samples
indsEnd = [0.023 0.043 0.099 -0.050] ./ period;
% NOTE: number of start and end indices MUST be identical
numWins = length(indsStart);    % number of windows to extract data from

% TODO: consider using noise mean to compute threshold for edge case values
% TODO: put into a helper function and use for loop through the number of
% legs present to reduce code duplication (handle case of only one leg)
for stR = 1:numStimR                    % for each right leg stimulus, ...
    indStim = indsStimArtifact{1}(stR); % stimulation index
    for win = 1:numWins                 % for each stim snippet window, ...
        % extract EMG data for time windows from stim artifact onset
        winEMG = rawEMG_MG{1}((indStim+indsStart(win)): ...
            (indStim+indsEnd(win)));
        [valMax,indMax] = max(winEMG);
        [valMin,indMin] = min(winEMG);
        % TODO: add check that M-wave and H-wave are not too broad in lieu
        % of or in addition to check that min or max are not early or late
        % in EMG window
        switch win
            case {1,2}                  % M-wave or H-wave
                % if min or max index not w/in 1st or last two samps, ...
                numPnts = length(winEMG);   % number of points in window
                if ~(any(indMin == [1 2]) || any(indMax == [1 2]) || ...
                        any(indMin == [numPnts-1 numPnts]) || ...
                        any(indMax == [numPnts-1 numPnts]))
                    % compute peak-to-peak voltage
                    amps{1,win}(stR) = valMax - valMin;
                else                    % otherwise, ...
                    % leave as NaN (previously set to noise floor thresh.)
                end
            case 3                      % noise window
                amps{1,win}(stR) = valMax - valMin;
            case 4                      % background EMG window
                % compute mean absolute value (MAV) of background EMG wind.
                amps{1,win}(stR) = mean(abs(winEMG));
                % compute root mean square (RMS) of background EMG window
                amps{1,win+1}(stR) = sqrt(mean(winEMG.^2));
            otherwise
                % not possible to enter this statement
        end
    end
end

for stL = 1:numStimL                    % for each left leg stimulus, ...
    indStim = indsStimArtifact{2}(stL); % stimulation index
    for win = 1:numWins                 % for each stim snippet window, ...
        winEMG = rawEMG_MG{2}((indStim+indsStart(win)): ...
            (indStim+indsEnd(win)));    % extract EMG time window data
        [valMax,indMax] = max(winEMG);
        [valMin,indMin] = min(winEMG);
        switch win
            case {1,2}                  % M-wave or H-wave
                % if min or max index not w/in 1st or last two samps, ...
                numPnts = length(winEMG);   % number of points in window
                if ~(any(indMin == [1 2]) || any(indMax == [1 2]) || ...
                        any(indMin == [numPnts-1 numPnts]) || ...
                        any(indMax == [numPnts-1 numPnts]))
                    % compute peak-to-peak voltage
                    amps{2,win}(stL) = valMax - valMin;
                else                    % otherwise, ...
                    % leave as NaN (previously set to noise floor thresh.)
                end
            case 3                      % noise window
                amps{2,win}(stL) = valMax - valMin;
            case 4                      % background EMG window
                amps{2,win}(stL) = mean(abs(winEMG));       % compute MAV
                amps{2,win+1}(stL) = sqrt(mean(winEMG.^2)); % compute RMS
            otherwise
                % not possible to enter this statement
        end
    end
end

end

