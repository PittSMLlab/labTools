function markerLabel=findLabel(viconLabel)
%function to deal with different marker labels from vicon. For the code to
%run correctly, the labels names must be as they are set in this code.
%
%DO NOT edit the markerLabels, only edit the text in the cases

switch viconLabel
    case {'LGT','LHIP','OG80_LGT'}
        markerLabel='LHIP';
    case {'RGT','RHIP','OG80_RGT'}
        markerLabel='RHIP';
    case {'LANK','LANKLE','OG80_LANK'}
        markerLabel='LANK';
    case {'RANK','RANKLE','OG80_RANK'}
        markerLabel='RANK';
    case {'RHEE','RHEEL','OG80_RHEEL'}
        markerLabel='RHEE';
    case {'LHEE','LHEEL','OG80_LHEEL'}
        markerLabel='LHEE';
    case {'LTOE','OG80_LTOE'}
        markerLabel='LTOE';
    case {'RTOE','OG80_RTOE'}
        markerLabel='RTOE';
    otherwise
        markerLabel=viconLabel;
end