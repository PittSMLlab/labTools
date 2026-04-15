function out = computeHarmonicRatioParameters(strideEvents, markerData, ...
    options)
% computeHarmonicRatioParameters  Compute harmonic ratios per stride.
%
%   Computes stride-by-stride harmonic ratio parameters and returns a
% parameterSeries object that can be concatenated with other parameter
% series objects (e.g., from computeTemporalParameters). Computes the
% vertical, medial-lateral, anterior-posterior, and aggregate harmonic
% ratios using the greater trochanter (GT) markers.
%
%   Inputs:
%     strideEvents - Struct of stride-level gait event times generated
%                    by calcParameters, with fields tSHS and tSHS2
%                    (N-by-1 vectors, in seconds)
%     markerData   - orientedLabTimeSeries containing kinematic marker
%                    data; must include 'RGT' and/or 'LGT' label
%                    prefixes
%     options      - (optional) Struct with fields:
%                      .numHarmonics: number of harmonics to include
%                                     (default: 10; following Menz,
%                                     Lord & Fitzpatrick 2003 J
%                                     Gerontol A, the foundational HR
%                                     paper for walking)
%                      .useMarkers:   'GT' or 'ALL' (default: 'GT';
%                                     GT markers sit on a firm bony
%                                     prominence and have lower soft-
%                                     tissue artifact than ASIS/PSIS)
%                      .filterCutoff: low-pass cutoff frequency in Hz
%                                     applied to pelvis position before
%                                     double differentiation (default:
%                                     6; conservative cutoff to limit
%                                     ω² noise amplification from
%                                     double differentiation; yields
%                                     ~6 meaningful harmonics at a
%                                     typical ~1 Hz stride frequency)
%
%   Outputs:
%     out - parameterSeries object containing all harmonic ratio
%           parameters
%
%   Toolbox Dependencies:
%     Signal Processing Toolbox (butter, filtfilt — used in
%     filterMarkerData local function)
%
%   See also: computeSpatialParameters, computeTemporalParameters,
%     computeForceParameters, parameterSeries, calcParameters

% TODO:
%   - store parameters as a structure if possible to convert to
% 'parameterSeries' object to help code readability (i.e., far fewer lines)
%   - rotate marker data to use a participant-based reference frame

arguments
    strideEvents (1,1) struct
    markerData
    options      (1,1) struct = struct()
end

if ~isfield(options, 'numHarmonics')    % if no field, ...
    options.numHarmonics = 10;          % set to default (10 harmonics)
end
if ~isfield(options, 'useMarkers')      % if no field, ...
    options.useMarkers = 'GT';          % use only 'GT' markers (default)
end
if ~isfield(options, 'filterCutoff')    % if no field, ...
    options.filterCutoff = 6;           % set to default (6 Hz)
end

%% Gait Stride Event Times
timeSHS  = strideEvents.tSHS;   % slow heel strike event times
timeSHS2 = strideEvents.tSHS2;  % 2nd slow heel strike event times

%% Labels and Descriptions
% harmonic ratio parameters
aux = { ...
    'harmonicRatio',    'aggregate harmonic ratio'; ...
    'harmonicRatioX',   'harmonic ratio along medial-lateral (i.e., X) axis'; ...
    'harmonicRatioY',   'harmonic ratio along anterior-posterior (i.e., Y) axis'; ...
    'harmonicRatioZ',   'harmonic ratio along vertical (i.e., Z) axis'};

paramLabels = aux(:, 1);
description = aux(:, 2);

%% Compute Harmonic Ratio Parameters
% Get sampling rate from marker data
samplingRate = 1 / markerData.sampPeriod;

% Compute pelvis position as centroid of GT markers; pelvisPos is
% a (T x 3) array where the columns correspond to x, y, z
pelvisPos = computePelvisPosition(markerData, options.useMarkers);

% Low-pass filter pelvis position data before differentiation
pelvisPosFilt = filterMarkerData( ...
    pelvisPos, samplingRate, options.filterCutoff);

% Compute pelvis acceleration via double differentiation
pelvisAccel = computeAcceleration(pelvisPosFilt, samplingRate);

% Initialize output arrays (one value per stride)
numStrides     = length(timeSHS);
harmonicRatio  = nan(numStrides, 1);
harmonicRatioX = nan(numStrides, 1);
harmonicRatioY = nan(numStrides, 1);
harmonicRatioZ = nan(numStrides, 1);

markerTime = markerData.Time;

% Compute harmonic ratio for each stride
for st = 1:numStrides
    tStart = timeSHS(st);
    tEnd   = timeSHS2(st);

    % Skip strides with missing or invalid boundaries
    if isnan(tStart) || isnan(tEnd) || tEnd <= tStart
        continue;
    end

    % Find sample indices for this stride window
    sampleIdx = markerTime >= tStart & markerTime <= tEnd;

    % Skip strides with insufficient samples to resolve numHarmonics
    if sum(sampleIdx) < 2 * options.numHarmonics
        continue;
    end

    accelStride    = pelvisAccel(sampleIdx, :);
    strideDuration = tEnd - tStart;
    strideFreq     = 1 / strideDuration;

    % Compute harmonic ratio for each cardinal direction
    harmonicRatioX(st) = computeHR_singleStride( ...
        accelStride(:, 1), strideFreq, options.numHarmonics);
    harmonicRatioY(st) = computeHR_singleStride( ...
        accelStride(:, 2), strideFreq, options.numHarmonics);
    harmonicRatioZ(st) = computeHR_singleStride( ...
        accelStride(:, 3), strideFreq, options.numHarmonics);

    % Compute aggregate HR using vector magnitude
    accelMag          = sqrt(sum(accelStride.^2, 2));
    harmonicRatio(st) = computeHR_singleStride( ...
        accelMag, strideFreq, options.numHarmonics);
end

%% Assign Parameters to Data Matrix
data = nan(numStrides, length(paramLabels));
for ii = 1:length(paramLabels)
    eval(['data(:, ii) = ' paramLabels{ii} ';']);
end

%% Output Computed Parameters
out = parameterSeries(data, paramLabels, [], description);

end

%% Local Functions

function pelvisPos = computePelvisPosition(markerData, useMarkers)
% Compute pelvis position as (T x 3) centroid of available markers.
% Returns columns [x, y, z] in the same units as markerData.
if strcmpi(useMarkers, 'GT')
    % Use only Greater Trochanter markers (most reliable)
    GTdata    = markerData.getOrientedData({'RGT', 'LGT'});
    pelvisPos = squeeze(mean(GTdata, 2, 'omitnan'));
else
    % Use all available pelvis markers; getOrientedData returns NaN
    % columns for any prefixes not present, which are then excluded
    % by the 'omitnan' flag in mean()
    pelvisLabels = {'RGT', 'LGT', 'RASI', 'LASI', 'RPSI', 'LPSI'};
    GTdata    = markerData.getOrientedData(pelvisLabels);
    pelvisPos = squeeze(mean(GTdata, 2, 'omitnan'));
end
end

function markerDataOut = transformCoordinateSystem(markerDataIn, coordMapping)
% Transform marker data between coordinate systems
%
% Inputs:
%   markerDataIn:  struct with marker fields (each [n x 3])
%   coordMapping:  string specifying the transformation
%       'XYZ_to_MLAP_VT' - x=ML, y=AP, z=VT (no change needed)
%       'XZY_to_MLAP_VT' - x=ML, z=AP, y=VT (swap y and z)
%       'YXZ_to_MLAP_VT' - y=ML, x=AP, z=VT (swap x and y)
%       Custom: [ML_col, AP_col, VT_col] e.g., [1,2,3] or [2,1,3]
%
% Output:
%   markerDataOut: struct with transformed coordinates

markerDataOut = struct();
fields = fieldnames(markerDataIn);

% Define transformation
switch coordMapping
    case 'XYZ_to_MLAP_VT'
        colOrder = [1, 2, 3]; % No change - already correct
    case 'XZY_to_MLAP_VT'
        colOrder = [1, 3, 2]; % Swap y and z
    case 'YXZ_to_MLAP_VT'
        colOrder = [2, 1, 3]; % Swap x and y
    case 'ZXY_to_MLAP_VT'
        colOrder = [3, 1, 2]; % x→VT, y→ML, z→AP becomes ML,AP,VT
    otherwise
        if isnumeric(coordMapping) && length(coordMapping) == 3
            colOrder = coordMapping;
        else
            error(['Unknown coordinate mapping. Use predefined ' ...
                'string or [ML_col, AP_col, VT_col].']);
        end
end

% Apply transformation to all marker fields
for iField = 1:length(fields)
    fname = fields{iField};
    markerDataOut.(fname) = markerDataIn.(fname)(:, colOrder);
end

fprintf(['Applied coordinate transformation: ' ...
    'columns [%d,%d,%d] → [ML,AP,VT]\n'], colOrder);
end

function dataFilt = filterMarkerData(data, fs, fc)
% Low-pass Butterworth filter (4th order, zero-phase)
[b, a] = butter(4, fc/(fs/2), 'low');
dataFilt = filtfilt(b, a, data);
end

function accel = computeAcceleration(pos, fs)
% Compute acceleration via central difference
% First derivative (velocity)
vel = gradient(pos, 1/fs);
% Second derivative (acceleration)
accel = gradient(vel, 1/fs);
end

function HR = computeHR_singleStride(signal, strideFreq, numHarmonics)
% Compute harmonic ratio for a single stride
% signal:       [n x 1] acceleration signal for one stride
% strideFreq:   fundamental frequency (stride frequency in Hz)
% numHarmonics: number of harmonics to analyze

% Ensure signal is column vector and remove mean
signal = signal(:) - mean(signal);
n = length(signal);

% Compute FFT
Y = fft(signal);
P = abs(Y/n);
P = P(1:floor(n/2)+1);
P(2:end-1) = 2*P(2:end-1);

% Frequency vector
fsLocal = n * strideFreq; % Effective sampling rate for this stride
f = fsLocal * (0:(floor(n/2))) / n;

% Extract harmonic amplitudes
evenSum = 0;
oddSum  = 0;

for h = 1:numHarmonics
    harmonicFreq = h * strideFreq;
    [~, idx] = min(abs(f - harmonicFreq));

    if idx <= length(P)
        if mod(h, 2) == 0
            evenSum = evenSum + P(idx);
        else
            oddSum = oddSum + P(idx);
        end
    end
end

% Compute harmonic ratio (even/odd)
if oddSum > 0
    HR = evenSum / oddSum;
else
    HR = NaN;
end
end

%% Example Usage Function
function example_usage()
% Example of how to use the harmonic ratio computation

% Simulate or load your marker data
samplingRate = 100; % Hz
duration = 30; % seconds
t = (0:1/samplingRate:duration-1/samplingRate)';

% Example: Create dummy marker data (replace with your actual data)
% Assuming your data is in x=ML, y=AP, z=VT format (no transformation needed)
markerData.R_GT = [0.1*sin(2*pi*1*t), zeros(size(t)), 0.02*sin(2*pi*2*t) + 1.0];
markerData.L_GT = [-0.1*sin(2*pi*1*t), zeros(size(t)), 0.02*sin(2*pi*2*t) + 1.0];

% If your coordinate system is different, transform it:
% markerData = transformCoordinateSystem(markerData, 'XYZ_to_MLAP_VT');
% For your system where x=left-right, y=heading, z=up-down, no transform needed!

% Example heel strikes (replace with your actual gait events)
strideTime = 1.1; % seconds per stride
heelStrikes.right = round((strideTime:strideTime:duration) * samplingRate)';
heelStrikes.left = round((strideTime/2:strideTime:duration) * samplingRate)';

% Set options
options.filterCutoff = 15;
options.numHarmonics = 20;
options.useMarkers = 'GT';

% Compute harmonic ratio
HR_results = computeHarmonicRatio(markerData, heelStrikes, samplingRate, options);

% Display results
fprintf('Computed %d strides\n', length(HR_results.HR_VT));
fprintf('Mean HR_VT: %.2f (SD: %.2f)\n', mean(HR_results.HR_VT, 'omitnan'), std(HR_results.HR_VT, 'omitnan'));
fprintf('Mean HR_AP: %.2f (SD: %.2f)\n', mean(HR_results.HR_AP, 'omitnan'), std(HR_results.HR_AP, 'omitnan'));
fprintf('Mean HR_ML: %.2f (SD: %.2f)\n', mean(HR_results.HR_ML, 'omitnan'), std(HR_results.HR_ML, 'omitnan'));
fprintf('Mean HR_MAG: %.2f (SD: %.2f)\n', mean(HR_results.HR_MAG, 'omitnan'), std(HR_results.HR_MAG, 'omitnan'));

% Plot results
figure;
subplot(4,1,1);
plot(HR_results.strideTimes, HR_results.HR_VT, 'o-');
ylabel('HR Vertical'); xlabel('Time (s)'); grid on;
title('Stride-by-Stride Harmonic Ratio');

subplot(4,1,2);
plot(HR_results.strideTimes, HR_results.HR_AP, 'o-');
ylabel('HR Anterior-Posterior'); xlabel('Time (s)'); grid on;

subplot(4,1,3);
plot(HR_results.strideTimes, HR_results.HR_ML, 'o-');
ylabel('HR Medio-Lateral'); xlabel('Time (s)'); grid on;

subplot(4,1,4);
plot(HR_results.strideTimes, HR_results.HR_MAG, 'o-');
ylabel('HR 3D Magnitude'); xlabel('Time (s)'); grid on;
end
