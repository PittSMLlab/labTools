function markerLabel=findLabel(viconLabel)
%function to deal with different marker labels from vicon. For the code to
%run correctly, the label names must be as they are set in this code.
%
%DO NOT edit the markerLabel declarations, only edit the strings in the
%case statements

markerLabel=viconLabel; %defualt

load('markerLabelKey.mat') %contatins matchedLabels variable

for i=1:size(matchedLabels,1);
    if ismember(viconLabel,matchedLabels{i,1})   
        markerLabel=matchedLabels{i,2};
    end
end

end

% switch viconLabel
%     case {'LGT','OG80_LGT','OG88_LGT'}
%         markerLabel='LHIP';
%     case {'RGT','OG80_RGT','OG88_RGT'}
%         markerLabel='RHIP';
%     case {'LANKLE','OG80_LANK','OG88_LANK'}
%         markerLabel='LANK';
%     case {'RANKLE','OG80_RANK','OG88_RANK'}
%         markerLabel='RANK';
%     case {'RHEEL','OG80_RHEEL','OG88_LHEEL'}
%         markerLabel='RHEE';
%     case {'LHEEL','OG80_LHEEL','OG88_RHEEL'}
%         markerLabel='LHEE';
%     case {'OG80_LTOE','OG88_LTOE'}
%         markerLabel='LTOE';
%     case {'OG80_RTOE','OG88_RTOE'}
%         markerLabel='RTOE';
%     case {'RKNEE','OG80_RKNE'}%,'OG88_RKNE'}
%         markerLabel='RKNE';
%     case {'LKNEE','OG80_LKNE'}%,'OG88_LKNE'}
%         markerLabel='LKNE';
%     otherwise
%         markerLabel=viconLabel;
% end