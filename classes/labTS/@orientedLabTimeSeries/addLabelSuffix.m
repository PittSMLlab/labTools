function extendedLabels = addLabelSuffix(labels)
%addLabelSuffix  Adds x/y/z suffix to labels
%
%   extendedLabels = addLabelSuffix(labels) adds component suffixes to
%   each label
%
%   Inputs:
%       labels - cell array or string of label prefixes
%
%   Outputs:
%       extendedLabels - cell array with x, y, z suffixes added
%
%   Example:
%       labels = {'RHIP', 'LHIP', ...}
%       extendedLabels = addLabelSuffix(labels);
%       extendedLabels = {'RHIPx', 'RHIPy', 'RHIPz', 'LHIPx', ...}
%
%   See also: getLabelPrefix, checkLabelSanity

% Static
% Add component suffix to each label
%
% example:
% labels = {'RHIP', 'LHIP', ...}
% extendedLabels = addLabelSuffix(labels);
% extendedLabels = {'RHIPx', 'RHIPy', 'RHIPz', 'LHIPx', 'LHIPy',
%     'LHIPz', ...}

if ischar(labels)
    labels = {labels};
end
extendedLabels = cell(length(labels) * 3, 1);
extendedLabels(1:3:end) = strcat(labels, 'x');
extendedLabels(2:3:end) = strcat(labels, 'y');
extendedLabels(3:3:end) = strcat(labels, 'z');
end

