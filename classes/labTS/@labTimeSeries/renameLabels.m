function this = renameLabels(this, originalLabels, newLabels)
%renameLabels  Renames labels in timeseries
%
%   this = renameLabels(this, originalLabels, newLabels) renames
%   specified labels
%
%   Inputs:
%       this - labTimeSeries object
%       originalLabels - cell array of labels to rename (empty for all)
%       newLabels - cell array of new label names
%
%   Outputs:
%       this - labTimeSeries with renamed labels
%
%   Note: You should not be renaming labels. You have been warned.
%
%   See also: getLabels

warning('labTS:renameLabels:dont', ...
    'You should not be renaming the labels. You have been warned.');
if isempty(originalLabels)
    originalLabels = this.labels;
end
if size(newLabels) ~= size(originalLabels)
    error('labTS:renameLabels', 'Inconsistent label sizes');
end
[boo, idx] = this.isaLabel(originalLabels);
this.labels(idx(boo)) = newLabels(boo);
end

