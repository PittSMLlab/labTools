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

% get hip position in fore-aft and up-down axes
if trialData.markerData.isaLabel('LGTx') %checks if hip was labeled 'GT'
    LhipPos2D=trialData.getMarkerData({['LGT' orientation.foreaftAxis],['LGT' orientation.updownAxis]});
    LhipPos2D=[orientation.foreaftSign* LhipPos2D(:,1),orientation.updownSign*LhipPos2D(:,2)];
    RhipPos2D=trialData.getMarkerData({['RGT' orientation.foreaftAxis],['RGT' orientation.updownAxis]});
    RhipPos2D=[orientation.foreaftSign* RhipPos2D(:,1),orientation.updownSign*RhipPos2D(:,2)];
elseif trialData.markerData.isaLabel('LHIPx') %checks if hip was labeled 'HIP'
    LhipPos2D=trialData.getMarkerData({['LHIP' orientation.foreaftAxis],['LHIP' orientation.updownAxis]});
    LhipPos2D=[orientation.foreaftSign* LhipPos2D(:,1),orientation.updownSign*LhipPos2D(:,2)];
    RhipPos2D=trialData.getMarkerData({['RHIP' orientation.foreaftAxis],['RHIP' orientation.updownAxis]});
    RhipPos2D=[orientation.foreaftSign* RhipPos2D(:,1),orientation.updownSign*RhipPos2D(:,2)];
else
    %this should never be the case, but may want to stop the
    %code here if it is and give a warning
    ME=MException('labData:Proccess','There are no markers labeled ''GT'' or ''HIP''. Unable to claculate limb angles');
    throw(ME);
end

% get ankle position in fore-aft and up-down axes
LanklePos2D=trialData.getMarkerData({['LANK' orientation.foreaftAxis],['LANK' orientation.updownAxis]});
LanklePos2D=[orientation.foreaftSign* LanklePos2D(:,1),orientation.updownSign*LanklePos2D(:,2)];
RanklePos2D=trialData.getMarkerData({['RANK' orientation.foreaftAxis],['RANK' orientation.updownAxis]});
RanklePos2D=[orientation.foreaftSign* RanklePos2D(:,1),orientation.updownSign*RanklePos2D(:,2)];

% calculate limb angles
RLimbAngle = calcangle([RanklePos2D(:,1) RanklePos2D(:,2)], [RhipPos2D(:,1) RhipPos2D(:,2)], [RhipPos2D(:,1)+100 RhipPos2D(:,2)])-90;
LLimbAngle = calcangle([LanklePos2D(:,1) LanklePos2D(:,2)], [LhipPos2D(:,1) LhipPos2D(:,2)], [LhipPos2D(:,1)+100 LhipPos2D(:,2)])-90;

% time info needed for labtimeseries object
t0=trialData.markerData.Time(1);
Ts=trialData.markerData.sampPeriod;

angleData = labTimeSeries([RLimbAngle LLimbAngle],t0,Ts,{'RLimb','LLimb'});
