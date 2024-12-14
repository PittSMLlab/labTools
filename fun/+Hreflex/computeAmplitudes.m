function [amplitudes,rms,usedMedMinMaxInds] = computeAmplitudes(snippets)
%COMPUTEAMPLITUDES Compute amplitudes of interest from H-reflex snippets
%   Compute the peak-to-peak amplitudes of the M-wave, H-wave, and noise
% floor.
%
% input:
%   snippets: 2 x 1 cell array of number of stimuli x number of samples
%       arrays for right (cell 1) and left (cell 2) leg EMG signal (NOTE:
%       if one cell is input as empty array, that leg will not be computed)
% output:
%   amplitudes: 2 x 3 cell array of number of stimuli x 1 arrays for right
%       (row 1) and left (row 2) leg H-reflex amplitudes: M-wave (column
%       1), H-wave (column 2), noise (column 3)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Alternative Approaches
% If you want to explore alternatives, here are some potential methods:
%
% Peak-to-Peak Ratio Validation:
%
% Compute the peak-to-peak amplitude within the window and compare it to
% the signal's baseline noise level (e.g., using a window before the
% stimulus). Discard measurements only if the peak-to-peak amplitude is
% below a threshold that reflects the noise floor.
% Weighted Amplitude Computation:
%
% Signal-To-Noise Ratio (SNR) Criterion:
%
% Define a threshold for a valid measurement based on the SNR. For example,
% if the amplitude of the M-wave or H-wave is more than twice the baseline
% noise level, consider it valid.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% TODO:
%   3. make window indices optional input argument with default to avoid
%   duplication across multiple code locations
%   4. consider using noise mean to compute threshold for edge case values
%   5. dynamically set the window bounds (especially the noise window)
%   based on the H-reflex data (this may allow the noise window to be
%   broader than it currently is)

narginchk(1,1);                     % verify correct number of input args
if all(cellfun(@isempty,snippets))  % if no input snippet data, ...
    warning('There is no data to compute the H-reflex amplitudes.');
    return;
end

amplitudes = cell(2,3);             % instantiate amplitudes cell array
rms = cell(2,3);                    % instantiate output RMS cell array
usedMedMinMaxInds = cell(2,2);      % used averaged peak-trough method?

% NOTE: should always be same across trials and should be same for forces
% TODO: make optional input argument?
period = 0.0005;                    % sampling period
% M-wave is contained by interval:           4.5ms -  20ms after stim. art.
% H-wave is contained by interval:          25  ms -  45ms
% TODO: is noise window correct? GTO requested between M- & H-waves
% Noise is contained by interval:           20ms   -  25ms
indsWindows = [0.0045 0.025 0.020;
    0.020 0.045 0.025] ./ period;   % convert to samples
indsWindows = indsWindows + 11;     % offset since snippet starts at -5ms

for leg = 1:2                       % for each leg, ...
    snips = snippets{leg,1};        % extract EMG snippets for current leg
    numStim = size(snips,1);        % number of stimuli for trial
    if isempty(snips)               % if no snippets for current leg, ...
        warning('No snippets provided for leg %d.',leg);
        continue;
    end

    % extract M- and H-wave windows and noise window
    winsMwave = snips(:,indsWindows(1,1):indsWindows(2,1));
    winsHwave = snips(:,indsWindows(1,2):indsWindows(2,2));
    winsNoise = snips(:,indsWindows(1,3):indsWindows(2,3));

    [amplitudes{leg,1},usedMedMinMaxInds{leg,1}] = ...
        computeWaveAmplitudes(winsMwave);       % M-wave amplitudes
    rms{leg,1} = sqrt(mean(winsMwave.^2,2));    % M-wave RMS
    [amplitudes{leg,2},usedMedMinMaxInds{leg,2}] = ...
        computeWaveAmplitudes(winsHwave);       % H-wave amplitudes
    rms{leg,2} = sqrt(mean(winsHwave.^2,2));    % H-wave RMS
    amplitudes{leg,3} = max(winsNoise,[],2) - min(winsNoise,[],2);
    rms{leg,3} = sqrt(mean(winsNoise.^2,2));    % Noise RMS
end

end

function [amplitudes,isOutlierDur] = computeWaveAmplitudes(windowsEMG)
%COMPUTEWAVEAMPLITUDES Computes amplitudes of an M- or H-wave window
%   Computes all wave amplitudes as the difference between the maximum and
% minimum value and then updates computation for waves with abnormally long
% or short wave durations by using the median index at which the minimum
% and maximum occur to compute a value.
%
% input:
%   windowsEMG: numStimuli x numSamples array of M- or H-wave EMG window
% outputs:
%   amplitudes: numStimuli x 1 array of M- or H-wave amplitudes
%   isOutlierDur: numStimuli x 1 boolean array indicating whether waveform
%       duration is an outlier or not

[valsMin,indsMin] = min(windowsEMG,[],2);   % minimum value and index
[valsMax,indsMax] = max(windowsEMG,[],2);   % maximum value and index
amplitudes = valsMax - valsMin;             % compute all amplitudes

durations = indsMax - indsMin;              % duration from peak to trough
indMinMed = round(median(indsMin));         % median min. value index
indMaxMed = round(median(indsMax));         % median max. value index
% NOTE: this may be too liberal (or conservative) in the samples it
% includes, although it seems to work quite well for calibration trials
% (maximum wave duration is ~10ms, which was previous threshold anyway)
% may want to check certain indices of indsMin and indsMax if make sense
% ensure peak and trough occur within physiologically plausible time range.
% confirm their relative amplitude aligns with what is typically observed.
% TODO: handle unlikely scenario of all durations identical (i.e., IQR = 0)
isOutlierDur = isoutlier(durations,'quartiles');    % 1.5*IQR is threshold
amplitudes(isOutlierDur) = abs(windowsEMG(isOutlierDur,indMaxMed) - ...
    windowsEMG(isOutlierDur,indMinMed));    % update amplitude computations

end

