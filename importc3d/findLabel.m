function markerLabel=findLabel(viconLabel)
%function to deal with different marker labels from vicon. For the code to
%run correctly, the label names must be as they are set in this code.
%
%DO NOT edit the markerLabel declarations, only edit the strings in the
%case statements

switch viconLabel
    case {'LGT','LHIP','OG80_LGT','OG88_LGT'}
        markerLabel='LHIP';
    case {'RGT','RHIP','OG80_RGT','OG88_RGT'}
        markerLabel='RHIP';
    case {'LANK','LANKLE','OG80_LANK','OG88_LANK'}
        markerLabel='LANK';
    case {'RANK','RANKLE','OG80_RANK','OG88_RANK'}
        markerLabel='RANK';
    case {'RHEE','RHEEL','OG80_RHEEL','OG88_LHEEL'}
        markerLabel='RHEE';
    case {'LHEE','LHEEL','OG80_LHEEL','OG88_RHEEL'}
        markerLabel='LHEE';
    case {'LTOE','OG80_LTOE','OG88_LTOE'}
        markerLabel='LTOE';
    case {'RTOE','OG80_RTOE','OG88_RTOE'}
        markerLabel='RTOE';   
    otherwise
        markerLabel=viconLabel;
end