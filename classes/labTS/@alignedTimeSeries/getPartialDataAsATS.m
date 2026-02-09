function newThis = getPartialDataAsATS(this, labels)
%getPartialDataAsATS  Extracts subset of channels
%
%   newThis = getPartialDataAsATS(this, labels) creates new
%   alignedTimeSeries with only specified channel labels
%
%   Inputs:
%       this - alignedTimeSeries object
%       labels - cell array of channel labels to extract
%
%   Outputs:
%       newThis - alignedTimeSeries with extracted channels
%
%   See also: getPartialStridesAsATS, isaLabel

[boolIdx, relIdx] = this.isaLabel(labels);
this.Data = this.Data(:, relIdx(boolIdx), :);
this.labels = this.labels(relIdx(boolIdx));
newThis = this;
% newThis = alignedTimeSeries(this.Time(1), this.Time(2) - this.Time(1),...
%     this.Data(:, relIdx(boolIdx), :), this.labels(relIdx(boolIdx)), ...
%     this.alignmentVector, this.alignmentLabels, this.eventTimes);
end

