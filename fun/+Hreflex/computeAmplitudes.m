function [amplitudes,rms,usedMedMinMaxInds] = ...
    computeAmplitudes(snippets,varargin)
%COMPUTEAMPLITUDES Compute amplitudes of H-reflex components from EMG data
%   Compute the peak-to-peak amplitudes and RMS values of the M-wave,
% H-wave, and noise floor from EMG signal snippets for both legs.
%
% input:
%   snippets: 2 x 1 cell array of number of stimuli x number of samples
%       arrays for right (cell 1) and left (cell 2) leg EMG signal
%   varargin: (optional)
%     'WindowDefinitions': 3 x 2 array Time (s) for M-, H-wave, and noise
%       intervals as [startM endM; startH endH; startNoise endNoise].
%       Default: [4.5e-3 20e-3; 25e-3 45e-3; 20e-3 25e-3].
%     'SamplingPeriod': scalar Time (s) between samples. Default: 0.0005 s.
%
% output:
%   amplitudes: 2 x 3 cell array of number of stimuli x 1 arrays for right
%       (row 1) and left (row 2) leg H-reflex amplitudes: M-wave (column
%       1), H-wave (column 2), noise (column 3)
%   rms: 2 x 3 cell array of RMS values for each wave.
%   usedMedMinMaxInds: 2 x 2 cell array indicating stimuli with outlier
%       durations and where median indices were used.

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

p = inputParser;                    % parse optional input arguments
% M-wave is contained by interval:  4.5ms - 20ms after stimulation artifact
% H-wave is contained by interval: 25  ms - 45ms
% Noise is contained by interval:  20  ms - 25ms
% TODO: is noise window correct? GTO requested between M- and H-wave
addParameter(p,'WindowDefinitions', ...
    [4.5e-3 20e-3; 25e-3 45e-3; 20e-3 25e-3]);
% NOTE: should always be same across trials and should be same for forces
addParameter(p,'SamplingPeriod',0.0005);
parse(p,varargin{:});
windowDefs = p.Results.WindowDefinitions;
period = p.Results.SamplingPeriod;

amplitudes = cell(2,3);             % instantiate amplitudes cell array
rms = cell(2,3);                    % instantiate output RMS cell array
usedMedMinMaxInds = cell(2,2);      % used averaged peak-trough method?

% convert window definitions from time to sample indices
indsWindows = round(windowDefs ./ period) + 11;     % offset for -5ms start

for leg = 1:2                       % for each leg, ...
    snips = snippets{leg,1};        % extract EMG snippets for current leg
    if isempty(snips)               % if no snippets for current leg, ...
        warning('No snippets provided for leg %d.',leg);
        continue;
    end

    % extract M-wave, H-wave, and noise windows
    winsMwave = snips(:,indsWindows(1,1):indsWindows(1,2));
    winsHwave = snips(:,indsWindows(2,1):indsWindows(2,2));
    winsNoise = snips(:,indsWindows(3,1):indsWindows(3,2));

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

