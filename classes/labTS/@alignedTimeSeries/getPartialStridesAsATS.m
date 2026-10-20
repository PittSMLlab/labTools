function newThis = getPartialStridesAsATS(this, inds)
%GETPARTIALSTRIDESASATS Extracts subset of strides.
%
%   newThis = getPartialStridesAsATS(this, inds) creates new
% alignedTimeSeries with specified stride indices
%
% Inputs:
%   this - alignedTimeSeries object
%   inds - vector of stride indices to extract
%
% Outputs:
%   newThis - alignedTimeSeries with extracted strides
%
% Toolbox Dependencies: None
%
% See also GETPARTIALDATAASATS, REMOVESTRIDESWITHNANS.

if ~isempty(this.eventTimes)
    % This can fail if eventTimes was not assigned (not mandatory)
    % newTimes = this.eventTimes(:, [inds inds(end) + 1]);
    % NOTE: inds may be a row or a column vector, so the appended index
    % must follow the orientation of inds
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

