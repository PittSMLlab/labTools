function out = computeHarmonicRatioParameters(strideEvents, markerData, ...
    options)
% computeHarmonicRatioParameters  Compute harmonic ratios per stride.
%
%   Syntax:
%     out = computeHarmonicRatioParameters(strideEvents, markerData)
%     out = computeHarmonicRatioParameters(strideEvents, markerData, ...
%         options)
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
% computePelvisPosition  Compute pelvis centroid position from markers.
%
%   Syntax:
%     pelvisPos = computePelvisPosition(markerData, useMarkers)
%
%   Returns the (T x 3) mean position across available pelvis markers,
% where columns correspond to [x, y, z] in the same units as markerData.
%
%   Inputs:
%     markerData  - orientedLabTimeSeries containing pelvis marker data
%     useMarkers  - 'GT' to use only greater trochanter markers, or
%                   any other value to use all available pelvis markers
%
%   Outputs:
%     pelvisPos - (T x 3) array of pelvis centroid position [x, y, z]
%
%   Toolbox Dependencies:
%     None
if strcmpi(useMarkers, 'GT')
    % Use only Greater Trochanter markers (most reliable)
    gtData    = markerData.getOrientedData({'RGT', 'LGT'});
    pelvisPos = squeeze(mean(gtData, 2, 'omitnan'));
else
    % Use all available pelvis markers; getOrientedData returns NaN
    % columns for any prefixes not present, which are then excluded
    % by the 'omitnan' flag in mean()
    pelvisLabels = {'RGT', 'LGT', 'RASI', 'LASI', 'RPSI', 'LPSI'};
    gtData    = markerData.getOrientedData(pelvisLabels);
    pelvisPos = squeeze(mean(gtData, 2, 'omitnan'));
end
end

function markerDataOut = transformCoordinateSystem( ...
    markerDataIn, coordMapping)
% transformCoordinateSystem  Reorder marker data columns to ML/AP/VT.
%
%   Syntax:
%     markerDataOut = transformCoordinateSystem(markerDataIn, coordMapping)
%
%   Inputs:
%     markerDataIn  - Struct with marker fields (each [n x 3])
%     coordMapping  - String specifying the transformation, or a
%                     3-element numeric vector [ML_col, AP_col, VT_col]:
%                       'XYZ_to_MLAP_VT' - x=ML, y=AP, z=VT (no change)
%                       'XZY_to_MLAP_VT' - x=ML, z=AP, y=VT (swap y,z)
%                       'YXZ_to_MLAP_VT' - y=ML, x=AP, z=VT (swap x,y)
%                       'ZXY_to_MLAP_VT' - z=VT, x=ML, y=AP
%
%   Outputs:
%     markerDataOut - Struct with columns reordered to [ML, AP, VT]
%
%   Toolbox Dependencies:
%     None

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
    fieldName = fields{iField};
    markerDataOut.(fieldName) = markerDataIn.(fieldName)(:, colOrder);
end

fprintf(['Applied coordinate transformation: ' ...
    'columns [%d,%d,%d] → [ML,AP,VT]\n'], colOrder);
end

function dataFilt = filterMarkerData(data, fs, fc)
% filterMarkerData  Apply zero-phase low-pass Butterworth filter.
%
%   Syntax:
%     dataFilt = filterMarkerData(data, fs, fc)
%
%   Inputs:
%     data - (T x N) data array to filter
%     fs   - Sampling frequency in Hz
%     fc   - Low-pass cutoff frequency in Hz
%
%   Outputs:
%     dataFilt - Filtered data, same size as data
%
%   Toolbox Dependencies:
%     Signal Processing Toolbox (butter, filtfilt)

[b, a] = butter(4, fc/(fs/2), 'low');
dataFilt = filtfilt(b, a, data);
end

function accel = computeAcceleration(pos, fs)
% computeAcceleration  Compute acceleration via double differentiation.
%
%   Syntax:
%     accel = computeAcceleration(pos, fs)
%
%   Inputs:
%     pos - (T x N) position data array
%     fs  - Sampling frequency in Hz
%
%   Outputs:
%     accel - (T x N) acceleration array (same units as pos * fs^2)
%
%   Toolbox Dependencies:
%     None

% First derivative (velocity), then second derivative (acceleration)
vel   = gradient(pos, 1/fs);
accel = gradient(vel, 1/fs);
end

function HR = computeHR_singleStride(signal, strideFreq, numHarmonics)
% computeHR_singleStride  Compute harmonic ratio for one stride.
%
%   Syntax:
%     HR = computeHR_singleStride(signal, strideFreq, numHarmonics)
%
%   Inputs:
%     signal       - (n x 1) acceleration signal for one stride window
%     strideFreq   - Fundamental stride frequency in Hz
%     numHarmonics - Number of harmonics to sum in the even/odd ratio
%
%   Outputs:
%     HR - Harmonic ratio (even-harmonic sum / odd-harmonic sum);
%          NaN if the odd-harmonic sum is zero
%
%   Toolbox Dependencies:
%     None

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
    [~, freqIdx] = min(abs(f - harmonicFreq));

    if freqIdx <= length(P)
        if mod(h, 2) == 0
            evenSum = evenSum + P(freqIdx);
        else
            oddSum = oddSum + P(freqIdx);
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

