function out = computeTSdiscreteParameters(tsData, gaitEvents, ...
    eventTypes, alignmentVector, summaryFun)
% computeTSdiscreteParameters  Discretize time series into stride phases.
%
%   Syntax:
%     out = computeTSdiscreteParameters(tsData, gaitEvents, eventTypes)
%     out = computeTSdiscreteParameters(tsData, gaitEvents, eventTypes, ...
%         alignmentVector)
%     out = computeTSdiscreteParameters(tsData, gaitEvents, eventTypes, ...
%         alignmentVector, summaryFun)
%
%   Averages labTS data across given gait phases and returns a
% parameterSeries object that can be concatenated with other parameter
% series objects (e.g., from computeTemporalParameters).
%
%   Inputs:
%     tsData          - labTimeSeries object to discretize
%     gaitEvents      - labTimeSeries of gait events for the trial
%     eventTypes      - Cell array of gait event type strings as
%                       constructed in calcParameters (e.g.,
%                       {'LHS','RTO','RHS','LTO'}), or a single char
%                       specifying the slow leg ('L' or 'R')
%     alignmentVector - (optional) Integer vector of the same length as
%                       eventTypes specifying phase alignment; defaults
%                       to [2, 4, 2, 4]
%     summaryFun      - (optional) Summary function handle applied per
%                       phase; defaults to [] (mean)
%
%   Outputs:
%     out - parameterSeries object containing one parameter per channel
%           per gait phase
%
%   Toolbox Dependencies:
%     None
%
%   See also: computeAngleParameters, computeEMGParameters,
%     computeTemporalParameters, computeForceParameters,
%     parameterSeries, calcParameters

% TODO: this should be a method of labTS

arguments
    tsData          (1,1)
    gaitEvents      (1,1)
    eventTypes
    alignmentVector = []
    summaryFun      = []
end

%% Configure Event Types and Phase Labels
if ~isa(eventTypes, 'cell')  % allow char slow-leg input as a shorthand
    if ~isa(eventTypes, 'char')
        error('Bad argument for eventTypes');
    end
    slowLeg    = eventTypes;
    fastLeg    = getOtherLeg(slowLeg);
    eventTypes = {[slowLeg 'HS'], [fastLeg 'TO'], ...
        [fastLeg 'HS'], [slowLeg 'TO']};
end

if isempty(alignmentVector)
    alignmentVector   = [2, 4, 2, 4];
    phaseDescriptions = {'SHS to mid DS1', 'mid DS1 to FTO', ...
        'FTO to 1/4 fast swing', '1/4 to mid fast swing', ...
        'mid fast swing to 3/4', '3/4 fast swing to FHS', ...
        'FHS to mid DS2', 'mid DS2 to STO', ...
        'STO to 1/4 slow swing', '1/4  to mid slow swing', ...
        'mid slow swing to 3/4', '3/4 slow swing to SHS'}';
else
    if length(eventTypes) ~= length(alignmentVector)
        if ~isempty(alignmentVector)
            error('Inconsistent sizes of eventTypes and alignmentVector');
        end
    end
    phaseDescriptions = cell(sum(alignmentVector), 1);
end

%% Discretize Time Series
% TODO: use quality info to mark parameters as BAD if necessary
tsData.Quality = []; % needed to avoid error in discretize()
[discTS, ~] = tsData.discretize( ...
    gaitEvents, eventTypes, alignmentVector, summaryFun);
[numPhases, numChannels, numStrides] = size(discTS.Data);

%% Build Parameter Labels and Descriptions
labelsGrid = strcat( ...
    repmat(strcat(discTS.labels, '_s'), numPhases, 1), ...
    repmat(mat2cell(num2str((1:numPhases)'), ones(numPhases, 1), 2), ...
    1, numChannels));
description = strcat(strcat( ...
    strcat('Mean of data in TS ', repmat(discTS.labels, numPhases, 1)), ...
    ' from '), repmat(phaseDescriptions, 1, numChannels));

%% Output Computed Parameters
out = parameterSeries( ...
    reshape(discTS.Data, numPhases * numChannels, numStrides)', ...
    labelsGrid(:), 1:numStrides, description(:));

end

