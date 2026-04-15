function out = computeHarmonicRatioParameters(strideEvents, markerData, ...
    options)
% computeHarmonicRatioParameters  Compute harmonic ratio parameters per stride.
%
%   Computes stride-by-stride harmonic ratio parameters and returns a
% parameterSeries object that can be concatenated with other parameter
% series objects (e.g., from computeTemporalParameters). Computes the
% vertical, medial-lateral, anterior-posterior, and aggregate harmonic
% ratios using the greater trochanter (GT) markers.
%
%   Inputs:
%     strideEvents - Struct of stride-level gait event times generated
%                    by calcParameters, with fields tSHS, tFTO, tFHS,
%                    tSTO, tSHS2, and tFHS2 (N-by-1 vectors, in seconds)
%     markerData   - orientedLabTimeSeries containing kinematic marker
%                    data; used to compute pelvis position and acceleration
%     options      - (optional) Struct with fields:
%                      .numHarmonics: number of harmonics to include
%                                     (default: 20)
%                      .useMarkers:   'GT' or 'ALL' (default: 'GT')
%
%   Outputs:
%     out - parameterSeries object containing all harmonic ratio parameters
%
%   Toolbox Dependencies:
%     None
%
%   See also: computeSpatialParameters, computeTemporalParameters,
%     computeForceParameters, parameterSeries, calcParameters

% TODO:
%   - store parameters as a structure if possible to convert to
% 'parameterSeries' object to help code readability (i.e., far fewer lines)
%   - refilter marker data if beneficial for analysis
%   - rotate marker data to use a participant-based reference frame

if nargin < 4                           % if no 'options' structure, ...
    options = struct();                 % set to empty structure
end

if ~isfield(options, 'numHarmonics')    % if no field, ...
    options.numHarmonics = 20;          % set to default (20 harmonics)
end
if ~isfield(options, 'useMarkers')      % if no field, ...
    options.useMarkers = 'GT';          % use only 'GT' markers (default)
end

%% Gait Stride Event Times
timeSHS  = strideEvents.tSHS;   % slow heel strike event times
timeFTO  = strideEvents.tFTO;   % fast toe off event times
timeFHS  = strideEvents.tFHS;   % fast heel strike event times
timeSTO  = strideEvents.tSTO;   % slow toe off event times
timeSHS2 = strideEvents.tSHS2;  % 2nd slow heel strike event times
timeFHS2 = strideEvents.tFHS2;  % 2nd fast heel strike event times

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
% Compute pelvis position (centroid of markers)
pelvisPos = computePelvisPosition(markerData, options.useMarkers);

% Filter position data before differentiation
pelvisPosFilt = filterMarkerData(pelvisPos, samplingRate, options.filterCutoff);

% Compute acceleration via double differentiation
pelvisAccel = computeAcceleration(pelvisPosFilt, samplingRate);

% Identify complete strides (right HS to right HS or left HS to left HS)
% Use the leg with more detected heel strikes
allHS = combineHeelStrikes(heelStrikes);

% Initialize output arrays
numStrides = length(allHS.indices) - 1;
HR_VT         = nan(numStrides, 1);
HR_AP         = nan(numStrides, 1);
HR_ML         = nan(numStrides, 1);
HR_MAG        = nan(numStrides, 1);
strideIndices = zeros(numStrides, 2);
strideTimes   = zeros(numStrides, 1);
strideFreq    = zeros(numStrides, 1);

% Compute harmonic ratio for each stride
for i = 1:numStrides
    % Extract stride data
    idx_start = allHS.indices(i);
    idx_end   = allHS.indices(i+1);

    % Store stride info
    strideIndices(i,:) = [idx_start, idx_end];
    strideTimes(i) = (idx_start + idx_end) / 2 / samplingRate;
    strideDuration = (idx_end - idx_start) / samplingRate;
    strideFreq(i) = 1 / strideDuration;

    % Extract acceleration for this stride
    accel_stride = pelvisAccel(idx_start:idx_end, :);

    % Compute harmonic ratio for each direction
    HR_VT(i) = computeHR_singleStride(accel_stride(:,3), strideFreq(i), options.numHarmonics);
    HR_AP(i) = computeHR_singleStride(accel_stride(:,2), strideFreq(i), options.numHarmonics);
    HR_ML(i) = computeHR_singleStride(accel_stride(:,1), strideFreq(i), options.numHarmonics);

    % Compute aggregate HR using vector magnitude
    accel_mag = sqrt(sum(accel_stride.^2, 2));
    HR_MAG(i) = computeHR_singleStride(accel_mag, strideFreq(i), options.numHarmonics);
end

% Package results
HR_results.HR_VT         = HR_VT;
HR_results.HR_AP         = HR_AP;
HR_results.HR_ML         = HR_ML;
HR_results.HR_MAG        = HR_MAG;
HR_results.strideIndices = strideIndices;
HR_results.strideTimes   = strideTimes;
HR_results.strideFreq    = strideFreq;

%% Assign Parameters to Data Matrix
data = nan(length(timeSHS), length(paramLabels));
for ii = 1:length(paramLabels)
    eval(['data(:, ii) = ' paramLabels{ii} ';']);
end

%% Output Computed Parameters
out = parameterSeries(data, paramLabels, [], description);

end

%% Local Functions

function pelvisPos = computePelvisPosition(markerData,useMarkers)
% compute pelvis position as centroid of available markers
if strcmpi(useMarkers,'GT')
    % use only Greater Trochanter markers (most reliable)
    pelvisPos = (markerData.R_GT + markerData.L_GT) / 2;
else
    % use all available markers
    markers = {};
    if isfield(markerData,'R_GT'), markers{end+1} = markerData.R_GT; end
    if isfield(markerData,'L_GT'), markers{end+1} = markerData.L_GT; end
    if isfield(markerData,'R_ASIS'), markers{end+1} = markerData.R_ASIS; end
    if isfield(markerData,'L_ASIS'), markers{end+1} = markerData.L_ASIS; end
    if isfield(markerData,'R_PSIS'), markers{end+1} = markerData.R_PSIS; end
    if isfield(markerData,'L_PSIS'), markers{end+1} = markerData.L_PSIS; end

    pelvisPos = mean(cat(3, markers{:}), 3);
end
end

function markerDataOut = transformCoordinateSystem(markerDataIn, coordMapping)
% Transform marker data between coordinate systems
%
% Inputs:
%   markerDataIn: struct with marker fields (each [n x 3])
%   coordMapping: string specifying the transformation
%       'XYZ_to_MLAP_VT' - x=ML, y=AP, z=VT (your system, no change needed)
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
            error('Unknown coordinate mapping. Use predefined string or [ML_col, AP_col, VT_col]');
        end
end

% Apply transformation to all marker fields
for i = 1:length(fields)
    markerDataOut.(fields{i}) = markerDataIn.(fields{i})(:, colOrder);
end

fprintf('Applied coordinate transformation: columns [%d,%d,%d] → [ML,AP,VT]\n', colOrder);
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

function allHS = combineHeelStrikes(heelStrikes)
% Combine and sort heel strikes from both legs
% Determine which to use for stride segmentation
rightHS = heelStrikes.right;
leftHS = heelStrikes.left;

% Use whichever leg has more heel strikes
if length(rightHS) >= length(leftHS)
    allHS.indices = sort(rightHS);
    allHS.leg = 'right';
else
    allHS.indices = sort(leftHS);
    allHS.leg = 'left';
end
end

function HR = computeHR_singleStride(signal, strideFreq, numHarmonics)
% Compute harmonic ratio for a single stride
% signal: [n x 1] acceleration signal for one stride
% strideFreq: fundamental frequency (stride frequency in Hz)
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
fs_local = n * strideFreq; % Effective sampling rate for this stride
f = fs_local * (0:(floor(n/2))) / n;

% Find fundamental frequency and harmonics
[~, idx_fundamental] = min(abs(f - strideFreq));

% Extract harmonic amplitudes
evenSum = 0;
oddSum = 0;

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
