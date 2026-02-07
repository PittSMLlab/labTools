function newThis = fftshift(this, labels)
%fftshift  Shifts alignment by half cycle
%
%   newThis = fftshift(this) shifts first and second halves of
%   alignment cycle for all labels
%
%   newThis = fftshift(this, labels) shifts only specified labels
%
%   Inputs:
%       this - alignedTimeSeries object
%       labels - cell array of labels to shift (optional, default: all)
%
%   Outputs:
%       newThis - shifted alignedTimeSeries
%
%   Example:
%       If first half starts at FHS and second half starts at SHS, the
%       shifted version will start at SHS and FHS will be the midpoint
%       of the cycle
%
%   See also: flipLR

% Shifts the first and second halves of the alignment cycle Example,
% if the first half starts at FHS and second half starts at SHS, the
% shifted version will start at SHS and FHS will be the midpoint of
% the cycle.
if nargin > 1 && ~isempty(labels)
    [~, idxs] = this.isaLabel(labels);
else
    idxs = 1:length(this.labels);
end
newThis = this;
M = round(length(this.alignmentVector) / 2);
N = sum(this.alignmentVector(1:M));
newThis.Data(:, idxs, :) = ...
    this.Data([N + 1:size(this.Data, 1), 1:N], idxs, :);
end

