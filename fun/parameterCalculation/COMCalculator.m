function [markerDataNEW] = COMCalculator(markerData, BW)
%CJS 5/2017  -- COMCalculator 
% Takes marker data and will give you an approximation of the COM position
% (1) If a HAT marker is present then a more correct version of the COM will be
%       Calculated using anthropometry tables from
%       (http://www.smf.org/docs/articles/hic/USAARL_88-5.pdf), winters,
%       and perhaps some assymptions from https://msis.jsc.nasa.gov/sections/section03.htm#3.3.7.3.2.1
%       WHICH ASSUMES: I am assuming that the arms don't affect anything because they are swinging completely counter clockwise to each other
% (2) If not HAT marker is present than we will use the average of the hips
%       isntead.  I know what you are thinking!  Yes, the ASIS and PSIS
%       would be better ("Alteration in the center of mass trajectory of 
%       patients after stroke"), but people don't take the time to fill these
%       markers in so I think from than perspective, the hips are better.
%% Step 1: Get relevant marker data
%get orientation
if isempty(markerData.orientation)
    warning('Assuming default orientation of axes for marker data.');
    orientation=orientationInfo([0,0,0],'x','y','z',1,1,1);
else
    orientation=markerData.orientation;
end

%get hip position
RHip=markerData.getDataAsVector({['RHIP' orientation.sideAxis],['RHIP' orientation.foreaftAxis],['RHIP' orientation.updownAxis]});
RHip=[orientation.sideSign*RHip(:,1),orientation.foreaftSign*RHip(:,2),orientation.updownSign*RHip(:,3)];
LHip=markerData.getDataAsVector({['LHIP' orientation.sideAxis],['LHIP' orientation.foreaftAxis],['LHIP' orientation.updownAxis]});
LHip=[orientation.sideSign*LHip(:,1),orientation.foreaftSign*LHip(:,2),orientation.updownSign*LHip(:,3)];

% Define the marker data
if isempty(markerData.getLabelsThatMatch('HAT')) %we don't have the data we need to do this for realy, but we can use a proxy
    warning('Not enough markers to calculate the COM, using the average of the hips as a proxy')
    %THe average of the pelvis would be better, but people don't usually
    %take the time to fill these markers, so this will be more robust
    BCOM=[mean([RHip(:,1) LHip(:,1)], 2) mean([RHip(:,2) LHip(:,2)], 2) mean([RHip(:,3) LHip(:,3)], 2)];
else
    
    %get ankle position
    RAnk=markerData.getDataAsVector({['RANK' orientation.sideAxis],['RANK' orientation.foreaftAxis],['RANK' orientation.updownAxis]});
    RAnk=[orientation.sideSign*RAnk(:,1),orientation.foreaftSign*RAnk(:,2),orientation.updownSign*RAnk(:,3)];
    LAnk=markerData.getDataAsVector({['LANK' orientation.sideAxis],['LANK' orientation.foreaftAxis],['LANK' orientation.updownAxis]});
    LAnk=[orientation.sideSign*LAnk(:,1),orientation.foreaftSign*LAnk(:,2),orientation.updownSign*LAnk(:,3)];
    %get knee position
    RKnee=markerData.getDataAsVector({['RKNE' orientation.sideAxis],['RKNE' orientation.foreaftAxis],['RKNE' orientation.updownAxis]});
    RKnee=[orientation.sideSign*RKnee(:,1),orientation.foreaftSign*RKnee(:,2),orientation.updownSign*RKnee(:,3)];
    LKnee=markerData.getDataAsVector({['LKNE' orientation.sideAxis],['LKNE' orientation.foreaftAxis],['LKNE' orientation.updownAxis]});
    LKnee=[orientation.sideSign*LKnee(:,1),orientation.foreaftSign*LKnee(:,2),orientation.updownSign*LKnee(:,3)];
    %get toe position
    RToe=markerData.getDataAsVector({['RTOE' orientation.sideAxis],['RTOE' orientation.foreaftAxis],['RTOE' orientation.updownAxis]});
    RToe=[orientation.sideSign*RToe(:,1),orientation.foreaftSign*RToe(:,2),orientation.updownSign*RToe(:,3)];
    LToe=markerData.getDataAsVector({['LTOE' orientation.sideAxis],['LTOE' orientation.foreaftAxis],['LTOE' orientation.updownAxis]});
    LToe=[orientation.sideSign*LToe(:,1),orientation.foreaftSign*LToe(:,2),orientation.updownSign*LToe(:,3)];
    %get HAT position
    HAT=markerData.getDataAsVector({['HAT' orientation.sideAxis],['HAT' orientation.foreaftAxis],['HAT' orientation.updownAxis]});
    HAT=[orientation.sideSign*HAT(:,1),orientation.foreaftSign*HAT(:,2),orientation.updownSign*HAT(:,3)];
    
    %% Need to calculate the position of the center of mass of each segment
    
    %Foot:
    fcomxR=abs(RAnk(:,1)-RToe(:,1)).*.5+RToe(:,1); %m
    fcomxL=abs(LAnk(:,1)-LToe(:,1)).*.5+LToe(:,1); %m
    fcomyR=abs(RAnk(:,2)-RToe(:,2)).*.5+RToe(:,2); %m
    fcomzR=abs(RAnk(:,3)-RToe(:,3)).*.5+RToe(:,3); %m
    fcomyL=abs(LAnk(:,2)-LToe(:,2)).*.5+LToe(:,2); %m
    fcomzL=abs(LAnk(:,3)-LToe(:,3)).*.5+LToe(:,3); %m
    
    fcomR=[fcomxR,fcomyR,fcomzR]; %foot
    fcomL=[fcomxL,fcomyL,fcomzL];
    
    %Shank: former I was using 0.394, but that is the whole leg, I just want
    %the shank, 0.567 is closer to what I want but I need to recalculate
    display('Updated Shank COM length?')
    scomxR=abs(RKnee(:,1)-RAnk(:,1)).*.567+RAnk(:,1);
    scomxL=abs(LKnee(:,1)-LAnk(:,1)).*.567+LAnk(:,1);
    scomyR=abs(RKnee(:,2)-RAnk(:,2)).*.567+RAnk(:,2);
    scomzR=abs(RKnee(:,3)-RAnk(:,3)).*.567+RAnk(:,3);
    scomyL=abs(LKnee(:,2)-LAnk(:,2)).*.567+LAnk(:,2);
    scomzL=abs(LKnee(:,3)-LAnk(:,3)).*.567+LAnk(:,3);
    
    scomR=[scomxR,scomyR,scomzR]; %Shank
    scomL=[scomxL,scomyL,scomzL];
    
    %Thigh:
    tcomxR=abs(RHip(:,1)-RKnee(:,1)).*.567+RKnee(:,1);
    tcomxL=abs(LHip(:,1)-LKnee(:,1)).*.567+LKnee(:,1);
    tcomyR=abs(RHip(:,2)-RKnee(:,2)).*.567+RKnee(:,2);
    tcomzR=abs(RHip(:,3)-RKnee(:,3)).*.567+RKnee(:,3);
    tcomyL=abs(LHip(:,2)-LKnee(:,2)).*.567+LKnee(:,2);
    tcomzL=abs(LHip(:,3)-LKnee(:,3)).*.567+LKnee(:,3);
    
    tcomR=[tcomxR,tcomyR,tcomzR]; %Thigh
    tcomL=[tcomxL,tcomyL,tcomzL];
    
    %HAT: head, arms, trunk
    % The distal distance from top of the head I calculated useing winter and
    % the midsized pilot from this document (http://www.smf.org/docs/articles/hic/USAARL_88-5.pdf)
    HATcomx=abs(nanmean([RHip(:,1) LHip(:,1)], 2)-HAT(:,1)).*(1-0.697)+nanmean([RHip(:,1); LHip(:,1)]);
    HATcomy=abs(nanmean([RHip(:,2) LHip(:,2)], 2)-HAT(:,2)).*(1-0.697)+nanmean([RHip(:,2); LHip(:,2)]);
    HATcomz=abs(nanmean([RHip(:,3) LHip(:,3)], 2)-HAT(:,3)).*(1-0.697)+nanmean([RHip(:,3); LHip(:,3)]);
    
    HATcom=[HATcomx, HATcomy, HATcomz];
    
    %% Need to compile whole body COM
    FootW=0.0145.*BW;
    shankW=0.0465.*BW;
    thighW=0.1.*BW;
    HATW=0.71.*BW;
    
    BodyCOMx=(1/BW).*((fcomxR*FootW+scomxR*shankW+tcomxR*thighW)+(fcomxL*FootW+scomxL*shankW+tcomxL*thighW)+HATcomx*HATW);
    BodyCOMy=(1/BW).*((fcomyR*FootW+scomyR*shankW+tcomyR*thighW)+(fcomyL*FootW+scomyL*shankW+tcomyL*thighW)+HATcomy*HATW);
    BodyCOMz=(1/BW).*((fcomzR*FootW+scomzR*shankW+tcomzR*thighW)+(fcomzL*FootW+scomzL*shankW+tcomzL*thighW)+HATcomz*HATW);
    
    BCOM=[BodyCOMx, BodyCOMy, BodyCOMz];
    %% Save everything in an orientedLabTS
    COMData=[fcomR fcomL scomR scomL tcomR tcomL HATcom BCOM]; %CJS note to self, change here to change what is stored in the COM
    labels={'RfCOMx','RfCOMy','RfCOMz','LfCOMx','LfCOMy','LfCOMz', 'RsCOMx','RsCOMy','RsCOMz','LsCOMx','LsCOMy','LsCOMz','RtCOMx','RtCOMy','RtCOMz','LtCOMx', 'LtCOMy','LtCOMz','HATCOMx','HATCOMy','HATCOMz','BCOMx','BCOMy','BCOMz'};
end

labelsBody={'BCOMx','BCOMy','BCOMz'};
%Pablo: creating orientedLabTS
%COMTS=orientedLabTimeSeries(COMData,markerData.Time(1),markerData.sampPeriod,labels(:),markerData.orientation);
markerDataNEW=appendData(markerData,BCOM,labelsBody,markerData.orientation);
end

