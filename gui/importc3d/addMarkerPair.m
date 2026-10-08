function addMarkerPair(correctLabel,altLabel)
%ADDMARKERPAIR Register an alternate Vicon label for a marker.
%
%   Appends ALTLABEL to the list of accepted Vicon names for the marker
% whose standard label is CORRECTLABEL, and saves the updated table.
%
% Inputs:
%   correctLabel - standard marker label (e.g., 'LHIP'); matched
%                  case-insensitively against column 2 of matchedLabels
%   altLabel     - additional Vicon label to map to CORRECTLABEL
%
% Outputs:
%   None. Overwrites markerLabelKey.mat (the first copy found on the
%   MATLAB path) with the updated matchedLabels cell array.
%
% Toolbox Dependencies: None
%
% See also FINDLABEL.

%% Update the label key
fileStr = which('markerLabelKey.mat');
load(fileStr);

for lbl = 1:size(matchedLabels,1)                   % for each label, ...
    if strcmpi(correctLabel,matchedLabels{lbl,2})
        matchedLabels{lbl,1} = [matchedLabels{lbl,1} {altLabel}];
    end
end

save(fileStr,'matchedLabels');

end

