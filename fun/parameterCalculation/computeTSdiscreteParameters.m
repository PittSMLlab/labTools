function out = computeTSdiscreteParameters(someTS, gaitEvents, eventTypes, alignmentVector, summaryFun)
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


if nargin<4 || isempty(alignmentVector)

    if ~isa(eventTypes,'cell') %Allow to change the type of event post-processing

        if ~isa(eventTypes,'char')
            error('Bad argument for eventTypes')
        end
arguments
    tsData          (1,1)
    gaitEvents      (1,1)
    eventTypes
    alignmentVector = []
    summaryFun      = []
end

        s = eventTypes;    f = getOtherLeg(s);
        eventTypes={[s 'HS'], [f 'TO'], [f 'HS'], [s 'TO']};
    end

    alignmentVector = [2, 4, 2, 4];
    desc2={'SHS to mid DS1', 'mid DS1 to FTO', ...
        'FTO to 1/4 fast swing', '1/4 to mid fast swing', ...
        'mid fast swing to 3/4', '3/4 fast swing to FHS', ...
        'FHS to mid DS2', 'mid DS2 to STO', ...
        'STO to 1/4 slow swing', '1/4  to mid slow swing', ...
        'mid slow swing to 3/4', '3/4 slow swing to SHS'}';
else
    if length(eventTypes)~=length(alignmentVector)
        if ~isempty(alignmentVector)
            error('Inconsistent sizes of eventTypes and alignmentVector')
        end
    end
    desc2 = cell(sum(alignmentVector), 1);
end
if nargin<5
    summaryFun = [];
end
someTS.Quality = []; %Needed to avoid error %TODO: use quality info to mark parameters as BAD if necessary
[DTS, ~] = someTS.discretize(gaitEvents, eventTypes, alignmentVector, summaryFun);
[N, M, P] = size(DTS.Data);
%Make labels:
ll = strcat(repmat(strcat(DTS.labels, '_s'), N, 1), repmat(mat2cell(num2str([1:N]'), ones(N, 1), 2), 1, M));
%Make descriptions:
desc = strcat(strcat(strcat('Mean of data in TS ', repmat(DTS.labels, N, 1)), ' from '), repmat(desc2, 1, M));
out = parameterSeries(reshape(DTS.Data, N*M, P)', ll(:), 1:P, desc(:));
end