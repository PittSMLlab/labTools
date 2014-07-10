function angleData = calcLimbAngles(trialData)
% Calculates angles using marker data
%   Created 5/14/2014 by HMH
%   only calculates leg angle at the moment (using hip and ankle markers)

%get orientation
if isempty(trialData.markerData.orientation)
    warning('Assuming default orientation of axes for marker data.');
    orientation=orientationInfo([0,0,0],'x','y','z',1,1,1);
else
    orientation=trialData.markerData.orientation;
end

[file] = getSimpleFileName(trialData.metaData.rawDataFilename);


% get hip position in fore-aft and up-down axes
if trialData.markerData.isaLabel('RHIPx') && trialData.markerData.isaLabel('LHIPx')
    LhipPos2D=trialData.getMarkerData({['LHIP' orientation.foreaftAxis],['LHIP' orientation.updownAxis]});
    LhipPos2D=[orientation.foreaftSign* LhipPos2D(:,1),orientation.updownSign*LhipPos2D(:,2)];
    RhipPos2D=trialData.getMarkerData({['RHIP' orientation.foreaftAxis],['RHIP' orientation.updownAxis]});
    RhipPos2D=[orientation.foreaftSign* RhipPos2D(:,1),orientation.updownSign*RhipPos2D(:,2)];
else
    warning(['There are missing hip markers in ',file,'. Unable to claculate limb angles']);
    angleData=[];
    return
end

% get ankle position in fore-aft and up-down axes
if trialData.markerData.isaLabel('RANKx') && trialData.markerData.isaLabel('LANKx')
    LanklePos2D=trialData.getMarkerData({['LANK' orientation.foreaftAxis],['LANK' orientation.updownAxis]});
    LanklePos2D=[orientation.foreaftSign* LanklePos2D(:,1),orientation.updownSign*LanklePos2D(:,2)];
    RanklePos2D=trialData.getMarkerData({['RANK' orientation.foreaftAxis],['RANK' orientation.updownAxis]});
    RanklePos2D=[orientation.foreaftSign* RanklePos2D(:,1),orientation.updownSign*RanklePos2D(:,2)];
else    
    warning(['There are missing ankle markers in',file,'. Unable to claculate limb angles']);
    angleData=[];
    return
end

% calculate limb angles
RLimbAngle = calcangle([RanklePos2D(:,1) RanklePos2D(:,2)], [RhipPos2D(:,1) RhipPos2D(:,2)], [RhipPos2D(:,1)+100 RhipPos2D(:,2)])-90;
LLimbAngle = calcangle([LanklePos2D(:,1) LanklePos2D(:,2)], [LhipPos2D(:,1) LhipPos2D(:,2)], [LhipPos2D(:,1)+100 LhipPos2D(:,2)])-90;

% time info needed for labtimeseries object
t0=trialData.markerData.Time(1);
Ts=trialData.markerData.sampPeriod;

angleData = labTimeSeries([RLimbAngle LLimbAngle],t0,Ts,{'RLimb','LLimb'});
