function angleData = calcLimbAngles(trialData)
% calcLimbAngles  Calculates angles using marker data   
%   angleData=clacLimbAngles(trailData) returns a labTimeSeries object
%   containg angles computed from marker data given an object of the
%   labData class.

%Created 5/14/2014 by HMH
% adapted by Digna de Kam to compute individual joint angles
% -hip angle is between vertical and line connecting hip and knee
% -knee angle is between line connecting hip and knee and line connecting
%  knee and ankle
% -ankle angle is between line connecting knee and ankle and line
%  connecting heel and toe

%disp('TEST: computing limb angles')
fs=1/trialData.markerData.sampPeriod;

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
    LhipPos2D=trialData.markerData.getDataAsVector({['LHIP' orientation.foreaftAxis],['LHIP' orientation.updownAxis]});
    LhipPos2D=[orientation.foreaftSign* LhipPos2D(:,1),orientation.updownSign*LhipPos2D(:,2)];
    RhipPos2D=trialData.markerData.getDataAsVector({['RHIP' orientation.foreaftAxis],['RHIP' orientation.updownAxis]});
    RhipPos2D=[orientation.foreaftSign* RhipPos2D(:,1),orientation.updownSign*RhipPos2D(:,2)];
else
    warning(['There are missing hip markers in ',file,'. Unable to claculate limb angles']);
      angleData=[];
    return
end

% get ankle position in fore-aft and up-down axes
if trialData.markerData.isaLabel('RANKx') && trialData.markerData.isaLabel('LANKx')
    LankPos2D=trialData.markerData.getDataAsVector({['LANK' orientation.foreaftAxis],['LANK' orientation.updownAxis]});
    LankPos2D=[orientation.foreaftSign* LankPos2D(:,1),orientation.updownSign*LankPos2D(:,2)];
    RankPos2D=trialData.markerData.getDataAsVector({['RANK' orientation.foreaftAxis],['RANK' orientation.updownAxis]});
    RankPos2D=[orientation.foreaftSign* RankPos2D(:,1),orientation.updownSign*RankPos2D(:,2)];
else    
    warning(['There are missing ankle markers in',file,'. Unable to claculate limb angles']);
%    angleData=[];
    return
end

% get knee position in fore-aft and up-down axes
if trialData.markerData.isaLabel('RKNEx') && trialData.markerData.isaLabel('LKNEx')
    LkneePos2D=trialData.markerData.getDataAsVector({['LKNE' orientation.foreaftAxis],['LKNE' orientation.updownAxis]});
    LkneePos2D=[orientation.foreaftSign* LkneePos2D(:,1),orientation.updownSign*LkneePos2D(:,2)];
    RkneePos2D=trialData.markerData.getDataAsVector({['RKNE' orientation.foreaftAxis],['RKNE' orientation.updownAxis]});
    RkneePos2D=[orientation.foreaftSign* RkneePos2D(:,1),orientation.updownSign*RkneePos2D(:,2)];
elseif trialData.markerData.isaLabel('RKNEEx') && trialData.markerData.isaLabel('LKNEEx')  
    LkneePos2D=trialData.markerData.getDataAsVector({['LKNEE' orientation.foreaftAxis],['LKNEE' orientation.updownAxis]});
    LkneePos2D=[orientation.foreaftSign* LkneePos2D(:,1),orientation.updownSign*LkneePos2D(:,2)];
    RkneePos2D=trialData.markerData.getDataAsVector({['RKNEE' orientation.foreaftAxis],['RKNEE' orientation.updownAxis]});
    RkneePos2D=[orientation.foreaftSign* RkneePos2D(:,1),orientation.updownSign*RkneePos2D(:,2)];
else
    
    warning(['There are missing knee markers in',file,'. Unable to claculate limb angles']);
    
    %Marcela temporal fix
    temp = trialData.markerData.getDataAsVector({['RHIP' orientation.foreaftAxis],['RHIP' orientation.updownAxis]});
    LkneePos2D = nan*ones(size(temp));
    RkneePos2D = nan*ones(size(temp));
%    % angleData=[];
%     return
end

% get toe position in fore-aft and up-down axes
if trialData.markerData.isaLabel('RTOEx') && trialData.markerData.isaLabel('LTOEx')
    LtoePos2D=trialData.markerData.getDataAsVector({['LTOE' orientation.foreaftAxis],['LTOE' orientation.updownAxis]});
    LtoePos2D=[orientation.foreaftSign* LtoePos2D(:,1),orientation.updownSign*LtoePos2D(:,2)];
    RtoePos2D=trialData.markerData.getDataAsVector({['RTOE' orientation.foreaftAxis],['RTOE' orientation.updownAxis]});
    RtoePos2D=[orientation.foreaftSign* RtoePos2D(:,1),orientation.updownSign*RtoePos2D(:,2)];
else    
    warning(['There are missing toe markers in',file,'. Unable to claculate limb angles']);
   % keyboard
    %angleData=[];
    return
end

% get heel position in fore-aft and up-down axes
if trialData.markerData.isaLabel('RHEEx') && trialData.markerData.isaLabel('LHEEx')
    LheelPos2D=trialData.markerData.getDataAsVector({['LHEE' orientation.foreaftAxis],['LHEE' orientation.updownAxis]});
    LheelPos2D=[orientation.foreaftSign* LheelPos2D(:,1),orientation.updownSign*LheelPos2D(:,2)];
    RheelPos2D=trialData.markerData.getDataAsVector({['RHEE' orientation.foreaftAxis],['RHEE' orientation.updownAxis]});
    RheelPos2D=[orientation.foreaftSign* RheelPos2D(:,1),orientation.updownSign*RheelPos2D(:,2)];
else    
    LheelPos2D=nan(size(LtoePos2D));
    RheelPos2D=nan(size(RtoePos2D));
    warning(['There are missing heel markers in',file,'. Unable to claculate limb angles']);
   % keyboard
    %angleData=[];
    return
end

% calculate limb angles
RLimbAngle = calcangle([RankPos2D(:,1) RankPos2D(:,2)], [RhipPos2D(:,1) RhipPos2D(:,2)], [RhipPos2D(:,1)+100 RhipPos2D(:,2)])-90;%so this computes angle with the horizontal, which is why 90 deg is subtracted
LLimbAngle = calcangle([LankPos2D(:,1) LankPos2D(:,2)], [LhipPos2D(:,1) LhipPos2D(:,2)], [LhipPos2D(:,1)+100 LhipPos2D(:,2)])-90;

% calculate limb angles
% RhipAngle = calcangle([RkneePos2D(:,1) RkneePos2D(:,2)], [RhipPos2D(:,1) RhipPos2D(:,2)], [RhipPos2D(:,1)+100 RhipPos2D(:,2)])-90;
% LhipAngle = calcangle([LkneePos2D(:,1) LkneePos2D(:,2)], [LhipPos2D(:,1) LhipPos2D(:,2)], [LhipPos2D(:,1)+100 LhipPos2D(:,2)])-90;

RThighAngle=atand([RhipPos2D(:,1)-RkneePos2D(:,1)]./[RhipPos2D(:,2)-RkneePos2D(:,2)]);
LThighAngle=atand([LhipPos2D(:,1)-LkneePos2D(:,1)]./[LhipPos2D(:,2)-LkneePos2D(:,2)]);

RShankAngle=atand([RkneePos2D(:,1)-RankPos2D(:,1)]./[RkneePos2D(:,2)-RankPos2D(:,2)]);
LShankAngle=atand([LkneePos2D(:,1)-LankPos2D(:,1)]./[LkneePos2D(:,2)-LankPos2D(:,2)]);

RfootAngle=atand([RtoePos2D(:,2)-RheelPos2D(:,2)]./[RtoePos2D(:,1)-RheelPos2D(:,1)]);
LfootAngle=atand([LtoePos2D(:,2)-LheelPos2D(:,2)]./[LtoePos2D(:,1)-LheelPos2D(:,1)]);

RhipAngle=RThighAngle;%assuming that trunk is vertical
LhipAngle=LThighAngle;
RhipAngVel=diff(RhipAngle)*fs;RhipAngVel(end+1)=RhipAngVel(end);%to ensure that vectors are the same length
LhipAngVel=diff(LhipAngle)*fs;LhipAngVel(end+1)=LhipAngVel(end);

RkneeAngle=180-((90-RThighAngle)+(90+RShankAngle));
LkneeAngle=180-((90-LThighAngle)+(90+LShankAngle));
RkneeAngVel=diff(RkneeAngle)*fs;RkneeAngVel(end+1)=RkneeAngVel(end);
LkneeAngVel=diff(LkneeAngle)*fs;LkneeAngVel(end+1)=LkneeAngVel(end);

RankAngle=90-(RShankAngle+90+RfootAngle);
LankAngle=90-(LShankAngle+90+LfootAngle);
RankAngVel=diff(RankAngle)*fs;RankAngVel(end+1)=RankAngVel(end);
LankAngVel=diff(LankAngle)*fs;LankAngVel(end+1)=LankAngVel(end);

%keyboard
% RhipAngle = calcangle([RkneePos2D(:,1) RkneePos2D(:,2)], [RhipPos2D(:,1) RhipPos2D(:,2)], [RhipPos2D(:,1) RhipPos2D(:,2)+100])-90;%this does not work, cosine has problem with negative values I think
% LhipAngle = calcangle([LkneePos2D(:,1) LkneePos2D(:,2)], [LhipPos2D(:,1) LhipPos2D(:,2)], [LhipPos2D(:,1) LhipPos2D(:,2)+100])-90;
% 
% RkneeAngle = calcangle([RankPos2D(:,1) RankPos2D(:,2)],[RkneePos2D(:,1) RkneePos2D(:,2)], [RhipPos2D(:,1) RhipPos2D(:,2)])-90;
% LkneeAngle = calcangle([LankPos2D(:,1) LankPos2D(:,2)],[LkneePos2D(:,1) LkneePos2D(:,2)], [LhipPos2D(:,1) LhipPos2D(:,2)])-90;
% 
% RankAngle = calcangle2([RkneePos2D(:,1) RkneePos2D(:,2)]-[RankPos2D(:,1) RankPos2D(:,2)],[RtoePos2D(:,1) RtoePos2D(:,2)]-[RheelPos2D(:,1) RheelPos2D(:,2)])-90;
% LankAngle = calcangle2([LkneePos2D(:,1) LkneePos2D(:,2)]-[LankPos2D(:,1) LankPos2D(:,2)],[LtoePos2D(:,1) LtoePos2D(:,2)]-[LheelPos2D(:,1) LheelPos2D(:,2)])-90;
% %keyboard

% time info needed for labtimeseries object
t0=trialData.markerData.Time(1);
Ts=trialData.markerData.sampPeriod;

angleData = labTimeSeries([RLimbAngle LLimbAngle RThighAngle LThighAngle RShankAngle LShankAngle RfootAngle LfootAngle RhipAngle LhipAngle RkneeAngle LkneeAngle RankAngle LankAngle RhipAngVel LhipAngVel RkneeAngVel LkneeAngVel RankAngVel LankAngVel]...
    ,t0,Ts,{'RLimb','LLimb','RThigh','LThigh','RShank','LShank','RFoot','LFoot','Rhip','Lhip','Rknee','Lknee','Rank','Lank','RhipVel','LhipVel','RkneeVel','LkneeVel','RankVel','LankVel'});
