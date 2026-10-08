function markerLabel = findLabel(viconLabel)
%FINDLABEL Map a Vicon marker label to the standard label.
%
%   Looks VICONLABEL up in the matchedLabels table of markerLabelKey.mat
% (column 1: cell of accepted Vicon names, column 2: standard label).
% Labels with no match are returned unchanged. The MAT file is loaded on
% every call. Add new aliases with ADDMARKERPAIR.
%
% Inputs:
%   viconLabel - marker label as recorded in the C3D file
%
% Outputs:
%   markerLabel - standard label, or VICONLABEL if no alias matches
%
% Toolbox Dependencies: None
%
% See also ADDMARKERPAIR.

%% Look up the label
markerLabel = viconLabel;               % default labels input argument
load('markerLabelKey.mat');             % contains 'matchedLabels' variable

for lbl = 1:size(matchedLabels,1)       % for each label, ...
    if ismember(viconLabel,matchedLabels{lbl,1})
        markerLabel = matchedLabels{lbl,2};
    end
end

end

% NOTE: the hard-coded alias list this table replaced, kept as a record.
% switch viconLabel
%     case {'LGT','OG80_LGT','OG88_LGT'}
%         markerLabel = 'LHIP';
%     case {'RGT','OG80_RGT','OG88_RGT'}
%         markerLabel = 'RHIP';
%     case {'LANKLE','OG80_LANK','OG88_LANK'}
%         markerLabel = 'LANK';
%     case {'RANKLE','OG80_RANK','OG88_RANK'}
%         markerLabel = 'RANK';
%     case {'RHEEL','OG80_RHEEL','OG88_LHEEL'}
%         markerLabel = 'RHEE';
%     case {'LHEEL','OG80_LHEEL','OG88_RHEEL'}
%         markerLabel = 'LHEE';
%     case {'OG80_LTOE','OG88_LTOE'}
%         markerLabel = 'LTOE';
%     case {'OG80_RTOE','OG88_RTOE'}
%         markerLabel = 'RTOE';
%     case {'RKNEE','OG80_RKNE'} %,'OG88_RKNE'}
%         markerLabel = 'RKNE';
%     case {'LKNEE','OG80_LKNE'} %,'OG88_LKNE'}
%         markerLabel = 'LKNE';
%     otherwise
%         markerLabel = viconLabel;
% end

