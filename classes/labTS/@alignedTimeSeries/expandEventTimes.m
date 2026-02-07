function expEventTimes = expandEventTimes(eventTimes, alignmentVector)
%expandEventTimes  Computes sample times for all events
%
%   expEventTimes = expandEventTimes(eventTimes, alignmentVector)
%   computes corresponding time for each sample in alignedTimeSeries
%
%   Inputs:
%       eventTimes - matrix of event times (events x strides+1)
%       alignmentVector - vector specifying samples per phase
%
%   Outputs:
%       expEventTimes - matrix of sample times (samples x strides)
%
%   Note: Given event times and alignment vector, this function
%         computes the corresponding time for each sample in an
%         alignedTimeSeries, provided that sampling is uniform between
%         events. This method cannot be hidden because it is used in
%         labTS.
%
%   See also: alignedTimeSeries, labTimeSeries/align

% Static
% Given event times and an alignment vectors, this function computes
% the corresponding time for each sample in an alignedTimeSeries,
% provided that the sampling is uniform between events. This method
% cannot be hidden because it is used in labTS

% This should be 0+ for the old-style alignment
refTime = 1 + [0 cumsum(alignmentVector)]';
M = size(eventTimes, 2) - 1;
N = sum(alignmentVector);
allEventTimes = eventTimes(:);
refTime2 = bsxfun(@plus, refTime(1:end - 1), N * [0:M]);
allExpEventTimes = interp1(refTime2(:), allEventTimes(:), [1:N * M]');
expEventTimes = reshape(allExpEventTimes, N, M);

end

