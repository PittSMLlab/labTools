function newThis = discretize(this, averagingVector)
%discretize  Averages data across phases
%
%   newThis = discretize(this, averagingVector) averages data
%   according to specified averaging vector
%
%   Inputs:
%       this - alignedTimeSeries object
%       averagingVector - vector specifying samples to average per new
%                         phase (must sum to total samples)
%
%   Outputs:
%       newThis - discretized alignedTimeSeries
%
%   See also: mean, labTimeSeries/discretize

if sum(averagingVector) ~= sum(this.alignmentVector)
    error('alignedTS:discretize', ['The averaging vector must sum to ' ...
        'the number of samples of the alignedTS']);
end
lastInd = 0;
newData = nan(length(averagingVector), size(this.Data, 2), ...
    size(this.Data, 3));
expEventTimes = alignedTimeSeries.expandEventTimes(this.eventTimes, ...
    this.alignmentVector);
newEventTimes = nan(length(averagingVector), size(expEventTimes, 2) + 1);
auxSamp = 1 + [0 cumsum(this.alignmentVector)];
for i = 1:length(averagingVector)
    inds = lastInd + [1:averagingVector(i)];
    newData(i, :, :) = nanmean(this.Data(inds, :, :));
    if ~any(auxSamp == inds(1))
        aux1 = '-';
    else
        aux1 = this.alignmentLabels{auxSamp == inds(1)};
    end
    if ~any(auxSamp == inds(end))
        aux2 = '-';
    else
        aux2 = this.alignmentLabels{auxSamp == inds(end)};
    end
    aux = this.alignmentLabels(auxSamp > inds(1) & auxSamp < inds(end));
    if ~isempty(aux)
        auxM = cell2mat(aux);
    else
        auxM = '-';
    end
    alignLabel{i} = [aux1 aux2];
    % Beginning of averaged interval
    newEventTimes(i, 1:end - 1) = expEventTimes(lastInd + 1, :);
    lastInd = lastInd + averagingVector(i);
end
newEventTimes(1, end) = this.eventTimes(1, end);
newThis = alignedTimeSeries(0, 1, newData, this.labels, ...
    ones(size(averagingVector)), alignLabel, newEventTimes);
end

