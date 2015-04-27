function angleData = calcLimbAngles(trialData)
% calcLimbAngles  Calculates angles using marker data   
%   angleData=clacLimbAngles(trailData) returns a labTimeSeries object
%   containg angles computed from marker data given an object of the
%   labData class. As of 4/27/2015, only the limb angles are calculated
%   (angle between verticle line through hip and vector connecting hip 
%   marker to ankle marker)
%
%Created 5/14/2014 by HMH

[file] = getSimpleFileName(trialData.metaData.rawDataFilename); %for error printout purposes

%get orientation
if isempty(trialData.markerData.orientation)
    warning('Assuming default orientation of axes for marker data.');
    orientation=orientationInfo([0,0,0],'x','y','z',1,1,1);
else
    orientation=trialData.markerData.orientation;
end

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
    LankPos2D=trialData.getMarkerData({['LANK' orientation.foreaftAxis],['LANK' orientation.updownAxis]});
    LankPos2D=[orientation.foreaftSign* LankPos2D(:,1),orientation.updownSign*LankPos2D(:,2)];
    RankPos2D=trialData.getMarkerData({['RANK' orientation.foreaftAxis],['RANK' orientation.updownAxis]});
    RankPos2D=[orientation.foreaftSign* RankPos2D(:,1),orientation.updownSign*RankPos2D(:,2)];
else    
    warning(['There are missing ankle markers in',file,'. Unable to claculate limb angles']);
    angleData=[];
    return
end

% calculate limb angles
RLimbAngle = calcangle([RankPos2D(:,1) RankPos2D(:,2)], [RhipPos2D(:,1) RhipPos2D(:,2)], [RhipPos2D(:,1)+100 RhipPos2D(:,2)])-90;
LLimbAngle = calcangle([LankPos2D(:,1) LankPos2D(:,2)], [LhipPos2D(:,1) LhipPos2D(:,2)], [LhipPos2D(:,1)+100 LhipPos2D(:,2)])-90;

% time info needed for labtimeseries object
t0=trialData.markerData.Time(1);
Ts=trialData.markerData.sampPeriod;

angleData = labTimeSeries([RLimbAngle LLimbAngle],t0,Ts,{'RLimb','LLimb'});