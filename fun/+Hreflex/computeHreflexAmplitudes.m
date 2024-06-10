function amps = computeHreflexAmplitudes(rawEMG_MG,indsStimArtifact)
%COMPUTEHREFLEXAMPLITUDES Compute amplitudes of interest from H-reflex
%   Compute the peak-to-peak amplitudes of the M-wave, H-wave, noise floor,
% and the background EMG.
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

% TODO: reject measurements if GRF reveals not in single stance
% TODO: accept threshold as optional input to overwrite noise threshold
% threshWaveAmp = 0.00015;    % 0.15 mV peak-to-peak voltage threshold

narginchk(2,2); % verify correct number of input arguments

% instantiate and initialize output amplitudes cell array
amps = cell(2,5);

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
% TODO: make indices optional input argument with default option to avoid
% having these values duplicated in multiple locations
% M-wave is contained by interval:           4ms -  23ms
% H-wave is contained by interval:          24ms -  43ms
% Noise is contained by interval:           50ms -  99ms
% Background EMG is contained by interval: -99ms - -50ms (neg. = before)
indStartM = 0.004 / period;        % 4 ms after stim artifact in samples
indEndM = 0.023 / period;          % 23 ms
indStartH = 0.024 / period;        % 24 ms
indEndH = 0.043 / period;          % 43 ms
indStartN = 0.050 / period;        % 50 ms  % TODO: is noise window right?
indEndN = 0.099 / period;          % 99 ms
indStartB = -0.099 / period;       % -99 ms
indEndB = -0.050 / period;         % -50 ms

numStimR = length(indsStimArtifact{1});
numStimL = length(indsStimArtifact{2});

amps(1,:) = cellfun(@(x) nan(numStimR,1),amps(1,:),'UniformOutput',false);
amps(2,:) = cellfun(@(x) nan(numStimL,1),amps(2,:),'UniformOutput',false);

% TODO: consider using noise mean to compute threshold to set edge case
% values; otherwise, move the noise computation into same for loops
for stR = 1:numStimR                % for each right leg stimulus, ...
    winEMGN = rawEMG_MG{1}((indsStimArtifact{1}(stR)+indStartN): ...
        (indsStimArtifact{1}(stR)+indEndN));
    amps{1,3}(stR) = max(winEMGN) - min(winEMGN);
end

for stL = 1:numStimL                % for each left leg stimulus, ...
    winEMGN = rawEMG_MG{2}((indsStimArtifact{2}(stL)+indStartN): ...
        (indsStimArtifact{2}(stL)+indEndN));
    amps{2,3}(stL) = max(winEMGN) - min(winEMGN);
end

% TODO: put into a helper function and use for loop through the number of
% legs present to reduce code duplication (handle case of only one leg)
for stR = 1:numStimR                % for each right leg stimulus, ...
    % extract EMG data for relevant time windows from stim artifact onset
    winEMGM = rawEMG_MG{1}((indsStimArtifact{1}(stR)+indStartM): ...
        (indsStimArtifact{1}(stR)+indEndM));
    winEMGH = rawEMG_MG{1}((indsStimArtifact{1}(stR)+indStartH): ...
        (indsStimArtifact{1}(stR)+indEndH));
    winEMGB = rawEMG_MG{1}((indsStimArtifact{1}(stR)+indStartB): ...
        (indsStimArtifact{1}(stR)+indEndB));
    [maxM,indMaxM] = max(winEMGM);
    [minM,indMinM] = min(winEMGM);
    [maxH,indMaxH] = max(winEMGH);
    [minH,indMinH] = min(winEMGH);
    % if min or max index is not within first or last two two samples, ...
    if ~(any(indMinM == [1 2]) || any(indMaxM == [1 2]) || ...
            any(indMinM == [length(winEMGM)-1 length(winEMGM)]) || ...
            any(indMaxM == [length(winEMGM)-1 length(winEMGM)]))
        amps{1,1}(stR) = maxM - minM;  % compute peak-to-peak voltage
    else    % otherwise, ...
        % leave value as NaN (previously set to the noise floor threshold)
        % ampsMwaveR(stR) = threshWaveAmp;
    end
    if ~(any(indMinH == [1 2]) || any(indMaxH == [1 2]) || ...
            any(indMinH == [length(winEMGH)-1 length(winEMGH)]) || ...
            any(indMaxH == [length(winEMGH)-1 length(winEMGH)]))
        amps{1,2}(stR) = maxH - minH;
    else
        % ampsHwaveR(stR) = threshWaveAmp;
    end
    % compute mean absolute value (MAV) of background EMG window
    amps{1,4}(stR) = mean(abs(winEMGB));
    % compute root mean square (RM) of background EMG window
    amps{1,5}(stR) = sqrt(mean(winEMGB.^2));
end

for stL = 1:numStimL                % for each left leg stimulus, ...
    winEMGM = rawEMG_MG{2}((indsStimArtifact{2}(stL)+indStartM): ...
        (indsStimArtifact{2}(stL)+indEndM));
    winEMGH = rawEMG_MG{2}((indsStimArtifact{2}(stL)+indStartH): ...
        (indsStimArtifact{2}(stL)+indEndH));
    winEMGB = rawEMG_MG{2}((indsStimArtifact{2}(stL)+indStartB): ...
        (indsStimArtifact{2}(stL)+indEndB));
    [maxM,indMaxM] = max(winEMGM);
    [minM,indMinM] = min(winEMGM);
    [maxH,indMaxH] = max(winEMGH);
    [minH,indMinH] = min(winEMGH);
    if ~(any(indMinM == [1 2]) || any(indMaxM == [1 2]) || ...
            any(indMinM == [length(winEMGM)-1 length(winEMGM)]) || ...
            any(indMaxM == [length(winEMGM)-1 length(winEMGM)]))
        amps{2,1}(stL) = maxM - minM;
    else
        % ampsMwaveL(stL) = threshWaveAmp;
    end
    if ~(any(indMinH == [1 2]) || any(indMaxH == [1 2]) || ...
            any(indMinH == [length(winEMGH)-1 length(winEMGH)]) || ...
            any(indMaxH == [length(winEMGH)-1 length(winEMGH)]))
        amps{2,2}(stL) = maxH - minH;
    else
        % ampsHwaveL(stL) = threshWaveAmp;
    end
    amps{2,4}(stL) = mean(abs(winEMGB));
    amps{2,5}(stL) = sqrt(mean(winEMGB.^2));
end

end

