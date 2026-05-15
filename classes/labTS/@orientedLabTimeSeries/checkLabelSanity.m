function labelSane = checkLabelSanity(labels)
%checkLabelSanity  Validates label format
%
%   labelSane = checkLabelSanity(labels) checks that labels are in
%   expected format for oriented data
%
%   Inputs:
%       labels - cell array of label strings
%
%   Outputs:
%       labelSane - true if labels pass all checks, false otherwise
%
%   Note: Checks that: (1) label count is multiple of 3, (2) labels end
%         in x, y, z in that order, (3) labels have same prefix in
%         groups of 3
%
%   See also: addLabelSuffix

labelSane = true;
% Check: labels is a multiple of 3
if mod(length(labels), 3) ~= 0
    warning(['Label length is not a multiple of 3, therefore they ' ...
        'can''t correspond to 3D oriented data.']);
    labelSane = false;
    return;
end
% Check: all labels end in 'x', 'y' or 'z'
% Should be 'x', 'y', 'z'
aux2 = cellfun(@(x) x(end), labels, 'UniformOutput', false);
if any(~strcmp(aux2(1:3:end), 'x')) || ...
        any(~strcmp(aux2(2:3:end), 'y')) || ...
        any(~strcmp(aux2(3:3:end), 'z'))
    warning(['Labels do not end in ''x'', ''y'', or ''z'' or in ' ...
        'that order, as expected.']);
    labelSane = false;
    return;
end
% Check: and labels have the same prefix in groups of 3
aux = cellfun(@(x) x(1:end - 1), labels, 'UniformOutput', false);
labelsx = aux(1:3:end);
labelsy = aux(2:3:end);
labelsz = aux(3:3:end);
if any(~strcmp(labelsx, labelsy)) || any(~strcmp(labelsx, labelsz))
    labelSane = false;
    return;
end
end

