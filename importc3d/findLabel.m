function markerLabel=findLabel(viconLabel)
%function to deal with different marker labels from vicon. For the code to
%run correctly, the labels names must be as they are set in this code.
%
%DO NOT edit the markerLabels, only edit the text in the cases

switch viconLabel
    case {'LGT','LHIP'}
        markerLabel='LHIP';
    case {'RGT','RHIP'}
        markerLabel='RHIP';
    case {'LANK','LANKLE'}
        markerLabel='LANK';
    case {'RANK','RANKLE'}
        markerLabel='RANK';
    case {'RHEE','RHEEL'}
        markerLabel='RHEE';
    case {'LHEE','LHEEL'}
        markerLabel='LHEE';
    case {'LTOE'}
        markerLabel='LTOE';
    case {'RTOE'}
        markerLabel='RTOE';
    otherwise
        markerLabel=viconLabel;
end