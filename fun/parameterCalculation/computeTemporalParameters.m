function out = computeTemporalParameters(strideEvents)
% computeTemporalParameters  Compute temporal parameters per stride.
%
%   Syntax:
%     out = computeTemporalParameters(strideEvents)
%
%   Computes stride-by-stride temporal gait parameters and returns a
% parameterSeries object that can be concatenated with other parameter
% series objects (e.g., from computeSpatialParameters).
%
%   Inputs:
%     strideEvents - Struct of stride-level gait event times generated
%                    by calcParameters, with fields tSHS, tFTO, tFHS,
%                    tSTO, tSHS2, and tFTO2 (N-by-1 vectors, seconds)
%
%   Outputs:
%     out - parameterSeries object containing all temporal parameters
%
%   Toolbox Dependencies:
%     None
%
%   See also: computeSpatialParameters, computeForceParameters,
%     parameterSeries, calcParameters

arguments
    strideEvents (1,1) struct
end

%% Gait Stride Event Times
timeSHS  = strideEvents.tSHS;   % slow heel strike event times
timeFTO  = strideEvents.tFTO;   % fast toe off event times
timeFHS  = strideEvents.tFHS;   % fast heel strike event times
timeSTO  = strideEvents.tSTO;   % slow toe off event times
timeSHS2 = strideEvents.tSHS2;  % 2nd slow heel strike event times
timeFTO2 = strideEvents.tFTO2;  % 2nd fast toe off event times

%% Labels and Descriptions
aux = { ...
    'swingTimeSlow',        'time from STO to SHS2 (in s)'; ...
    'swingTimeFast',        'time from FTO to FHS (in s)'; ...
    'stanceTimeSlow',       'time from SHS to STO (in s)'; ...
    'stanceTimeFast',       'time from FHS to FTO2 (in s)'; ...
    'doubleSupportSlow',    'time from FHS to STO (in s)'; ...
    'doubleSupportFast',    'time from SHS2 to FTO2 (in s)'; ...
    'doubleSupportTemp',    'time from SHS to FTO (in s)'; ...
    'stepTimeSlow',         'time from FHS to SHS2 (in s)'; ...
    'stepTimeFast',         'time from SHS to FHS (in s)'; ...
    'toeOffSlow',           'time from STO to FTO2 (in s)'; ...
    'toeOffFast',           'time from FTO to STO (in s)'; ...
    'strideTimeSlow',       'time from SHS to SHS2 (in s)'; ...
    'strideTimeFast',       'time from FTO to FTO2 (in s)'; ...
    'cadenceSlow',          '1/strideTimeSlow (in Hz)'; ...
    'cadenceFast',          '1/strideTimeFast (in Hz)'; ...
    'stepCadenceSlow',      '1/stepTimeSlow (in Hz)'; ...
    'stepCadenceFast',      '1/stepTimeFast (in Hz)'; ...
    'doubleSupportPctSlow', '(doubleSupportSlow/strideTimeSlow)*100'; ...
    'doubleSupportPctFast', '(doubleSupportFast/strideTimeFast)*100'; ...
    'doubleSupportDiff',    'doubleSupportSlow-doubleSupportFast (in s)'; ...
    'stepTimeDiff',         'stepTimeFast-stepTimeSlow (in s)'; ...
    'stanceTimeDiff',       'stanceTimeSlow-stanceTimeFast (in s)'; ...
    'swingTimeDiff',        'swingTimeFast-swingTimeSlow (in s)'; ...
    'doubleSupportAsym',    '(doubleSupportPctFast-doubleSupportPctSlow)/(doubleSupportPctFast+doubleSupportPctSlow)'; ...
    'Tout',                 'stepTimeDiff/strideTimeSlow'; ...
    'Tgoal',                'stanceTimeDiff/strideTimeSlow'; ...
    'TgoalSW',              'swingTimeDiff/strideTimeSlow (should be same as Tgoal)'};

paramLabels = aux(:, 1);
description = aux(:, 2);

%% Compute Temporal Parameters
% Intraleg parameters (i.e., within each leg)

% Swing phase durations per stride
swingTimeSlow = timeSHS2 - timeSTO;
swingTimeFast = timeFHS  - timeFTO;

% Stance phase durations (includes double support)
stanceTimeSlow = timeSTO  - timeSHS;
stanceTimeFast = timeFTO2 - timeFHS;

% Double support phase durations
doubleSupportSlow = timeSTO - timeFHS;
doubleSupportTemp = timeFTO - timeSHS;
% Pablo I. modified (11/11/2014) the parameter below to use the second
% step rather than the first one, so that:
% stance time = step time + double support time (with given indexing)
doubleSupportFast = timeFTO2 - timeSHS2;

% Step durations (time between heel strike events)
stepTimeSlow = timeSHS2 - timeFHS;
stepTimeFast = timeFHS  - timeSHS;

% Time between toe off events
toeOffSlow = timeFTO2 - timeSTO;
toeOffFast = timeSTO  - timeFTO;

% Stride durations
strideTimeSlow = timeSHS2 - timeSHS;
strideTimeFast = timeFTO2 - timeFTO;

% Cadence (stride cycles per second)
cadenceSlow = 1 ./ strideTimeSlow;
cadenceFast = 1 ./ strideTimeFast;

% Step cadence (steps per second)
stepCadenceSlow = 1 ./ stepTimeSlow;
stepCadenceFast = 1 ./ stepTimeFast;

% Percentage of gait cycle that is double support phase
doubleSupportPctSlow = (doubleSupportSlow ./ strideTimeSlow) * 100;
doubleSupportPctFast = (doubleSupportFast ./ strideTimeFast) * 100;

% Interleg parameters (i.e., across the legs)
% NOTE: the sign convention (fast - slow or slow - fast) was chosen
% pragmatically based on how each parameter timecourse appeared
doubleSupportDiff = doubleSupportSlow - doubleSupportFast;
stepTimeDiff      = stepTimeFast      - stepTimeSlow;
stanceTimeDiff    = stanceTimeSlow    - stanceTimeFast;
swingTimeDiff     = swingTimeFast     - swingTimeSlow;
doubleSupportAsym = (doubleSupportPctFast - doubleSupportPctSlow) ./ ...
    (doubleSupportPctFast + doubleSupportPctSlow);
Tout   = stepTimeDiff   ./ strideTimeSlow;
Tgoal  = stanceTimeDiff ./ strideTimeSlow;
TgoalSW = swingTimeDiff ./ strideTimeSlow;

%% Assign Parameters to Data Matrix
data = nan(length(timeSHS), length(paramLabels));
for ii = 1:length(paramLabels)
    eval(['data(:, ii) = ' paramLabels{ii} ';']);
end

%% Output Computed Parameters
out = parameterSeries(data, paramLabels, [], description);

end

