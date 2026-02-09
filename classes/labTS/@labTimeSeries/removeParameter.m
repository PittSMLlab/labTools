function newThis = removeParameter(labels)
%removeParameter  Removes parameter from timeseries
%
%   newThis = removeParameter(labels) removes specified labels from
%   the timeseries
%
%   Inputs:
%       labels - cell array of label strings to remove
%
%   Outputs:
%       newThis - labTimeSeries with parameters removed
%
%   Note: Issues warning if some labels not present
%
%   See also: appendData

[bool, idxs] = compareLists(this.labels, labels);
if any(~bool)
    warning([{'Could not remove some parameters because they are ' ...
        'not present: '} labels(~bool)]);
end
newThis = this;
newThis.labels(idxs(bool)) = [];
newThis.Data(:, idxs(bool)) = [];
end

