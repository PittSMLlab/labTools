function out = computeTemporalParameters(strideEvents)
%This function computes summary temporal parameters per stride
%   This function outputs a 'parameterSeries' object, which can be
% concatenated with other 'parameterSeries' objects, for example, with
% those from 'computeSpatialParameters'. While this function is used for
% temporal parameters exclusively, it should work for any 'labTS' object.
%
% See also computeSpatialParameters, computeTemporalParameters,
% computeForceParameters, parameterSeries

%% Gait Stride Event Times
timeSHS = strideEvents.tSHS;    % slow heel strike event times
timeFTO = strideEvents.tFTO;    % fast toe off event times
timeFHS = strideEvents.tFHS;    % fast heel strike event times
timeSTO = strideEvents.tSTO;    % slow toe off event times
timeSHS2 = strideEvents.tSHS2;  % 2nd slow heel strike event times
timeFTO2 = strideEvents.tFTO2;  % 2nd fast toe off event times

%% Labels & Descriptions
aux = { ...
    'swingTimeSlow',            'time from STO to SHS2 (in s)'; ...
    'swingTimeFast',            'time from FTO to FHS (in s)'; ...
    'stanceTimeSlow',           'time from SHS to STO (in s)'; ...
    'stanceTimeFast',           'time from FHS to FTO2 (in s)'; ...
    'doubleSupportSlow',        'time from FHS to STO (in s)'; ...
    'doubleSupportFast',        'time from SHS2 to FTO2 (in s)'; ...
    'doubleSupportTemp',        'time from SHS to FTO (in s)'; ...
    'stepTimeSlow',             'time from FHS to SHS2 (in s)'; ...
    'stepTimeFast',             'time from SHS to FHS (in s)'; ...
    'toeOffSlow',               'time from STO to FTO2 (in s)'; ...
    'toeOffFast',               'time from FTO to STO (in s)'; ...
    'strideTimeSlow',           'time from SHS to SHS2 (in s)'; ...
    'strideTimeFast',           'time from FTO to FTO2 (in s)'; ...
    'cadenceSlow',              '1/strideTimeSlow (in Hz)'; ...
    'cadenceFast',              '1/strideTimeFast (in Hz)'; ...
    'stepCadenceSlow',          '1/stepTimeSlow (in Hz)'; ...
    'stepCadenceFast',          '1/stepTimeFast (in Hz)'; ...
    'doubleSupportPctSlow',     '(doubleSupportSlow/strideTimeSlow)*100'; ...
    'doubleSupportPctFast',     '(doubleSupportFast/strideTimeFast)*100'; ...
    'doubleSupportDiff',        'doubleSupportSlow-doubleSupportFast (in s)'; ...
    'stepTimeDiff',             'stepTimeFast-stepTimeSlow (in s)'; ...
    'stanceTimeDiff',           'stanceTimeSlow-stanceTimeFast (in s)'; ...
    'swingTimeDiff',            'swingTimeFast-swingTimeSlow (in s)'; ...
    'doubleSupportAsym',        '(doubleSupportPctFast-doubleSupportPctSlow)/(doubleSupportPctFast+doubleSupportPctSlow)'; ...
    'Tout',                     'stepTimeDiff/strideTimeSlow'; ...
    'Tgoal',                    'stanceTimeDiff/strideTimeSlow'; ...
    'TgoalSW',                  'swingTimeDiff/strideTimeSlow (should be same as Tgoal)'};

paramLabels = aux(:,1);
description = aux(:,2);

%% Compute Temporal Parameters
% intraleg parameters (i.e., within each leg)
% swing phase durations per stride
swingTimeSlow = timeSHS2 - timeSTO;
swingTimeFast = timeFHS - timeFTO;
% stance phase durations (includes double support)
stanceTimeSlow = timeSTO - timeSHS;
stanceTimeFast = timeFTO2 - timeFHS;
% double support phase durations
doubleSupportSlow = timeSTO - timeFHS;
doubleSupportTemp = timeFTO - timeSHS;
% Pablo I. modified (11/11/2014) below parameter to use the second step
% rather than the first one, so that
% stance time = step time + double support time with the given indexing.
doubleSupportFast = timeFTO2 - timeSHS2;
% step durations (time between heel strike events)
stepTimeSlow = timeSHS2 - timeFHS;
stepTimeFast = timeFHS - timeSHS;
% time between toe off events
toeOffSlow = timeFTO2 - timeSTO;
toeOffFast = timeSTO - timeFTO;
% stride durations
strideTimeSlow = timeSHS2 - timeSHS;
strideTimeFast = timeFTO2 - timeFTO;
% cadence (stride cycles per second)
cadenceSlow = 1 ./ strideTimeSlow;
cadenceFast = 1 ./ strideTimeFast;
% step cadence (steps per second)
stepCadenceSlow = 1 ./ stepTimeSlow;
stepCadenceFast = 1 ./ stepTimeFast;
% percentage of gait cycle that is double support phase
doubleSupportPctSlow = (doubleSupportSlow ./ strideTimeSlow) * 100;
doubleSupportPctFast = (doubleSupportFast ./ strideTimeFast) * 100;

% interleg parameters (i.e., across the legs)
% NOTE: the decision as to whether to use fast - slow or slow - fast was
% made pragmatically based on how the parameter timecourse appeared
doubleSupportDiff = doubleSupportSlow - doubleSupportFast;
stepTimeDiff = stepTimeFast - stepTimeSlow;
stanceTimeDiff = stanceTimeSlow - stanceTimeFast;
swingTimeDiff = swingTimeFast - swingTimeSlow;
doubleSupportAsym = (doubleSupportPctFast - doubleSupportPctSlow) ./ ...
    (doubleSupportPctFast + doubleSupportPctSlow);
Tout = stepTimeDiff ./ strideTimeSlow;
Tgoal = stanceTimeDiff ./ strideTimeSlow;
TgoalSW = swingTimeDiff ./ strideTimeSlow;

%% Assign Parameters to the Data Matrix
data = nan(length(timeSHS),length(paramLabels));
for ii = 1:length(paramLabels)
    eval(['data(:,ii) = ' paramLabels{ii} ';']);
end

%% Output the Computed Parameters
out = parameterSeries(data,paramLabels,[],description);

end

