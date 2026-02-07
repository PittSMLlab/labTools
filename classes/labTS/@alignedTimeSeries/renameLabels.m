function this = renameLabels(this, originalLabels, newLabels)
%renameLabels  Renames labels
%
%   this = renameLabels(this, originalLabels, newLabels) renames
%   specified labels
%
%   Inputs:
%       this - alignedTimeSeries object
%       originalLabels - cell array of current labels (empty for all)
%       newLabels - cell array of new label names
%
%   Outputs:
%       this - alignedTimeSeries with renamed labels
%
%   Note: You should not be renaming labels. You have been warned.
%
%   See also: isaLabel

warning('labTS:renameLabels:dont', ...
    'You should not be renaming the labels. You have been warned.');
if isempty(originalLabels)
    originalLabels = this.labels;
end
if size(newLabels) ~= size(originalLabels)
    error('alignedTS:renameLabels', 'Inconsistent label sizes');
end
[boo, idx] = this.isaLabel(originalLabels);
this.labels(idx(boo)) = newLabels;
end

