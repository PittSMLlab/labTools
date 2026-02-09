function newThis = getPartialStridesAsATS(this, inds)
%getPartialStridesAsATS  Extracts subset of strides
%
%   newThis = getPartialStridesAsATS(this, inds) creates new
%   alignedTimeSeries with specified stride indices
%
%   Inputs:
%       this - alignedTimeSeries object
%       inds - vector of stride indices to extract
%
%   Outputs:
%       newThis - alignedTimeSeries with extracted strides
%
%   See also: getPartialDataAsATS, removeStridesWithNaNs

if ~isempty(this.eventTimes)
    % This can fail if eventTimes was not assigned (not mandatory)
    % newTimes = this.eventTimes(:, [inds inds(end) + 1]);
    % Changed by DMMO 10/4/2019 the dimension were not consistent
    % with previous code
    if size(inds, 1) == 1
        newTimes = this.eventTimes(:, [inds inds(end) + 1]);
    else
        newTimes = this.eventTimes(:, [inds; inds(end) + 1]);
    end
else
    newTimes = [];
end
newThis = alignedTimeSeries(this.Time(1), this.Time(2) - this.Time(1), ...
    this.Data(:, :, inds), this.labels, this.alignmentVector, ...
    this.alignmentLabels, newTimes);
end

