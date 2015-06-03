function [AllMomentsTS] = TorqueCalculatorNew(COMTS, COPTS, markerData, GRFData)

%% Get data from COMTS
fcomR=squeeze(COMTS.getOrientedData({'RfCOM'}));
fcomxR=fcomR(:,1);
fcomyR=fcomR(:,2);
fcomzR=fcomR(:,3);

fcomL=squeeze(COMTS.getOrientedData({'LfCOM'}));
fcomxL=fcomL(:,1);
fcomyL=fcomL(:,2);
fcomzL=fcomL(:,3);

scomR=squeeze(COMTS.getOrientedData({'RsCOM'}));
scomxR=scomR(:,1);
scomyR=scomR(:,2);
scomzR=scomR(:,3);

scomL=squeeze(COMTS.getOrientedData({'LsCOM'}));
scomxL=scomL(:,1);
scomyL=scomL(:,2);
scomzL=scomL(:,3);

tcomR=squeeze(COMTS.getOrientedData({'RtCOM'}));
tcomxR=tcomR(:,1);
tcomyR=tcomR(:,2);
tcomzR=tcomR(:,3);

tcomL=squeeze(COMTS.getOrientedData({'LtCOM'}));
tcomxL=tcomL(:,1);
tcomyL=tcomL(:,2);
tcomzL=tcomL(:,3);

%% Get data from COPTS
NewGRFs=COPTS.getDataAsTS({'RGRFx','RGRFy','RGRFz','LGRFx','LGRFy','LGRFz'}).getSample(markerData.Time);
NewGRFzR=NewGRFs(:,3);
NewGRFyR=NewGRFs(:,2);
NewGRFxR=NewGRFs(:,1);
NewGRFzL=NewGRFs(:,6);
NewGRFyL=NewGRFs(:,5);
NewGRFxL=NewGRFs(:,4);
NewCOPs=COPTS.getDataAsTS({'LCOPx','LCOPy','RCOPx','RCOPy'}).getSample(markerData.Time);
NewCOPyR=NewCOPs(:,4);
NewCOPxR=NewCOPs(:,3);
NewCOPyL=NewCOPs(:,2);
NewCOPxL=NewCOPs(:,1);


%% Get relevant markerData
%get orientation
if isempty(markerData.orientation)
    warning('Assuming default orientation of axes for marker data.');
    orientation=orientationInfo([0,0,0],'x','y','z',1,1,1);
else
    orientation=markerData.orientation;
end

% Define the body weight of the patient
LFz=GRFData.getDataAsVector('LFz');
RFz=GRFData.getDataAsVector('RFz');
BW=abs(LFz(1,1)+RFz(1,1));

FootWeight=(BW*.0145);
ShankWeight=BW*.0465;
ThighWeight=BW*0.1;

% Get marker data
% Define the marker data for relevant markers

%get hip position
RHip=markerData.getDataAsVector({['RHIP' orientation.sideAxis],['RHIP' orientation.foreaftAxis],['RHIP' orientation.updownAxis]});
RHip=[orientation.sideSign*RHip(:,1),orientation.foreaftSign*RHip(:,2),orientation.updownSign*RHip(:,3)];
LHip=markerData.getDataAsVector({['LHIP' orientation.sideAxis],['LHIP' orientation.foreaftAxis],['LHIP' orientation.updownAxis]});
LHip=[orientation.sideSign*LHip(:,1),orientation.foreaftSign*LHip(:,2),orientation.updownSign*LHip(:,3)];
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


%%
fcomRangle=[]; fcomLangle=[]; scomRangle=[]; scomLangle=[]; tcomRangle=[]; tcomLangle=[];
VerticalVector=[0,0,1];

for i=1:size(fcomL,1)
        RFootCOMLength=RAnk(i,:)-fcomR(i,:);
        LFootCOMLength=LAnk(i,:)-fcomL(i,:);
        RShankCOMLength=RKnee(i,:)-scomR(i,:);
        LShankCOMLength=LKnee(i,:)-scomL(i,:);
        RThighCOMLength=RHip(i,:)-tcomR(i,:);
        LThighCOMLength=LHip(i,:)-tcomL(i,:);
    
    fcomRangle(i)=atan2(RFootCOMLength(1,2)-VerticalVector(1,2),RFootCOMLength(1,3)-VerticalVector(1,3));
    fcomLangle(i)=atan2(LFootCOMLength(1,2)-VerticalVector(1,2),LFootCOMLength(1,3)-VerticalVector(1,3));
    scomRangle(i)=atan2(RShankCOMLength(1,2)-VerticalVector(1,2),RShankCOMLength(1,3)-VerticalVector(1,3));
    scomLangle(i)=atan2(LShankCOMLength(1,2)-VerticalVector(1,2),LShankCOMLength(1,3)-VerticalVector(1,3));
    tcomRangle(i)=atan2(RThighCOMLength(1,2)-VerticalVector(1,2),RThighCOMLength(1,3)-VerticalVector(1,3));
    tcomLangle(i)=atan2(LThighCOMLength(1,2)-VerticalVector(1,2),LThighCOMLength(1,3)-VerticalVector(1,3));
end
% Determine the acceleration by differentiating the center of mass
% position twice and then applying a small filter on the data.
[B,A]=butter(1, 20/(1000/2));
AfcomxR=diff(diff(fcomxR./1000));
AfcomxR=filtfilt(B,A,AfcomxR);
AfcomyR=diff(diff(fcomyR./1000));
AfcomyR=filtfilt(B,A,AfcomyR);
AfcomzR=diff(diff(fcomzR./1000));
AfcomzR=filtfilt(B,A,AfcomzR);
AfcomxL=diff(diff(fcomxL./1000));
AfcomxL=filtfilt(B,A,AfcomxL);
AfcomyL=diff(diff(fcomyL./1000));
AfcomyL=filtfilt(B,A,AfcomyL);
AfcomzL=diff(diff(fcomzL./1000));
AfcomzL=filtfilt(B,A,AfcomzL);

AscomxR=diff(diff(scomxR./1000));
AscomxR=filtfilt(B,A,AscomxR);
AscomyR=diff(diff(scomyR./1000));
AscomyR=filtfilt(B,A,AscomyR);
AscomzR=diff(diff(scomzR./1000));
AscomzR=filtfilt(B,A,AscomzR);
AscomzL=diff(diff(scomzL./1000));
AscomzL=filtfilt(B,A,AscomzL);
AscomyL=diff(diff(scomyL./1000));
AscomyL=filtfilt(B,A,AscomyL);
AscomxL=diff(diff(scomxL./1000));
AscomxL=filtfilt(B,A,AscomxL);

AtcomxR=diff(diff(tcomxR./1000));
AtcomxR=filtfilt(B,A,AtcomxR);
AtcomyR=diff(diff(tcomyR./1000));
AtcomyR=filtfilt(B,A,AtcomyR);
AtcomzR=diff(diff(tcomzR./1000));
AtcomzR=filtfilt(B,A,AtcomzR);
AtcomxL=diff(diff(tcomxL./1000));
AtcomxL=filtfilt(B,A,AtcomxL);
AtcomyL=diff(diff(tcomyL./1000));
AtcomyL=filtfilt(B,A,AtcomyL);
AtcomzL=diff(diff(tcomzL./1000));
AtcomzL=filtfilt(B,A,AtcomzL);
% Define the angular accleration by finding the angle that the limb is
% away from a vertical point, and then differentiate this signal twice.
% Then a small filter is applied to the angular accleration data.
alphaRfoot=diff(diff(fcomRangle));
alphaRfoot=filtfilt(B,A,alphaRfoot);
alphaLfoot=diff(diff(fcomLangle));
alphaLfoot=filtfilt(B,A,alphaLfoot);
alphaRshank=diff(diff(scomRangle));
alphaRshank=filtfilt(B,A,alphaRshank);
alphaLshank=diff(diff(scomLangle));
alphaLshank=filtfilt(B,A,alphaLshank);
alphaRthigh=diff(diff(tcomRangle));
alphaRthigh=filtfilt(B,A,alphaRthigh);
alphaLthigh=diff(diff(tcomLangle));
alphaLthigh=filtfilt(B,A,alphaLthigh);
% Define the angular velocity in a similar manner
wfcomyR=diff(fcomRangle);
wfcomyR=filtfilt(B,A,wfcomyR);
wfcomyL=diff(fcomLangle);
wfcomyL=filtfilt(B,A,wfcomyL);
wscomyR=diff(scomRangle);
wscomyR=filtfilt(B,A,wscomyR);
wscomyL=diff(scomLangle);
wscomyL=filtfilt(B,A,wscomyL);
wtcomyR=diff(tcomRangle);
wtcomyR=filtfilt(B,A,wtcomyR);
wtcomyL=diff(tcomLangle);
wtcomyL=filtfilt(B,A,wtcomyL);



%From here on, anywhere it says F should say R, and anywhere that says s
%should say L (domLeg==1)

% The number of frames differs betwen the force and marker data by a
% few frames after getting the new forces. Find the difference to make
% sure future for loops do not break.
lengthdiff=abs(length(RAnk)-length(NewGRFzR));
COPcount=1;
Cross1=[]; Cross2=[];
for i=1:(length(RAnk)-lengthdiff-2)
    % Define second moment of inertia for the segment.
    RFootLength=norm(RAnk(i,:)-RToe(i,:))/1000;
    RFootI0=FootWeight*(RFootLength*0.690)^2;
    % Define the reaction forces at the ankle based on a freebody
    % diagram of the foot.
        RzAnkleForce(i)=-1*FootWeight*9.8-FootWeight*AfcomzR(i)+NewGRFzR(i);
        RyAnkleForce(i)=NewGRFyR(i)-FootWeight*AfcomyR(i);
        RxAnkleForce(i)=NewGRFxR(i)-FootWeight*AfcomxR(i);

    % Place the ground reaciton forces and the reaction forces into
    % their own matrices.
    GRFR=[NewGRFxR(i),NewGRFyR(i),NewGRFzR(i)];
    COPfR=[NewCOPxR(COPcount),NewCOPyR(COPcount),0];
    RAnkF=[RxAnkleForce(i),RyAnkleForce(i),RzAnkleForce(i)];
    % Place the center of masses and the center of pressures into their
    % own matrices.
        fcomR=[fcomxR(i),fcomyR(i),fcomzR(i)];
    % Ensure that when the foot is not on the ground that the distance
    % between the center of mass and center of pressure is zero.
    r1=(fcomR-COPfR)/1000;
        if isnan(NewCOPxR(COPcount))==1
            r1=[0,0,0];
        end
    r2=(RAnk(i,:)-fcomR)/1000;
    % Perform a cross product between the distances and forces to get
    % the overall moments occuring at the right ankle joint.
    Cross1(i,:)=cross(r1,GRFR);
    Cross2(i,:)=cross(r2,RAnkF);
    RAnkleCross=Cross1(i,:)+Cross2(i,:);
    % Subtract away the moment of intertia multiplied by the angular
    % accleration to get the total ankle moment.
        RAnkleMoment(i)=RAnkleCross(1,1)-RFootI0*alphaRfoot(i);
        RAnklePower(i)=RAnkleMoment(i)*wfcomyR(i);
    COPcount=COPcount+1;
end
COPcount=1;
Cross1=[]; Cross2=[];
for i=1:(length(LAnk)-lengthdiff-2)
    % Define second moment of inertia for the segment.
    LFootLength=norm(LAnk(i,:)-LToe(i,:))/1000;
    LFootI0=FootWeight*(LFootLength*0.690)^2;
    % Define the reaction forces at the ankle based on a freebody
    % diagram of the foot.
        LzAnkleForce(i)=-1*FootWeight*9.8-FootWeight*AfcomzL(i)+NewGRFzL(i);
        LyAnkleForce(i)=NewGRFyL(i)-FootWeight*AfcomyL(i);
        LxAnkleForce(i)=NewGRFxL(i)-FootWeight*AfcomxL(i);
    % Place the ground reaciton forces and the reaction forces into
    % their own matrices.
    GRFL=[NewGRFxL(i),NewGRFyL(i),NewGRFzL(i)];
        COPfL=[NewCOPxL(COPcount),NewCOPyL(COPcount),0];
    LAnkF=[LxAnkleForce(i),LyAnkleForce(i),LzAnkleForce(i)];
    % Place the center of masses and the center of pressures into their
    % own matrices.
        fcomL=[fcomxL(i),fcomyL(i),fcomzL(i)];
    % Ensure that when the foot is not on the ground that the distance
    % between the center of mass and center of pressure is zero.
    r1=(fcomL-COPfL)/1000;
        if isnan(NewCOPxL(COPcount))==1
            r1=[0,0,0];
        end
    r2=(LAnk(i,:)-fcomL)/1000;
    % Perform a cross product between the distances and forces to get
    % the overall moments occuring at the right ankle joint.
    Cross1(i,:)=cross(r1,GRFL);
    Cross2(i,:)=cross(r2,LAnkF);
    LAnkleCross=Cross1(i,:)+Cross2(i,:);
    % Subtract away the moment of intertia multiplied by the angular
    % accleration to get the total ankle moment.
        LAnkleMoment(i)=LAnkleCross(1,1)-LFootI0*alphaLfoot(i);
        LAnklePower(i)=LAnkleMoment(i)*wfcomyL(i);
    COPcount=COPcount+1;
end


for i=1:abs(length(NewGRFzL)-lengthdiff-2)
    RShankLength=norm(RKnee(i,:)-RAnk(i,:))/1000;
    RShankI0=ShankWeight*(RShankLength*0.645)^2;
        RyKneeForce(i)=RyAnkleForce(i)-ShankWeight*AscomyR(i);
        RzKneeForce(i)=RzAnkleForce(i)-ShankWeight*AscomzR(i)-ShankWeight*9.8;
        RxKneeForce(i)=RxAnkleForce(i)-ShankWeight*AscomxR(i);
        
    RAnkF=[RxAnkleForce(i),RyAnkleForce(i),RzAnkleForce(i)];
    RKneeF=[RxKneeForce(i),RyKneeForce(i),RzKneeForce(i)];
        scomR(i,:)=[scomxR(i),scomyR(i),scomzR(i)];
    r1=(scomR(i,:)-RAnk(i,:))/1000;
    r2=(RKnee(i,:)-scomR(i,:))/1000;
    RKneeCross=cross(r1,RAnkF)+cross(r2,RKneeF);
        RKneeMoment(i)=-1*((RKneeCross(1,1))-RShankI0*alphaRshank(i)+RAnkleMoment(i));
        RKneePower(i)=RKneeMoment(i)*wscomyR(i);
end
for i=1:abs(length(NewGRFzL)-lengthdiff-2)
    LShankLength=norm(LKnee(i,:)-LAnk(i,:))/1000;
    LShankI0=ShankWeight*(LShankLength*0.645)^2;
        LyKneeForce(i)=LyAnkleForce(i)-ShankWeight*AscomyL(i);
        LzKneeForce(i)=LzAnkleForce(i)-ShankWeight*AscomzL(i)-ShankWeight*9.8;
        LxKneeForce(i)=LxAnkleForce(i)-ShankWeight*AscomxL(i);
    LAnkF=[LxAnkleForce(i),LyAnkleForce(i),LzAnkleForce(i)];
    LKneeF=[LxKneeForce(i),LyKneeForce(i),LzKneeForce(i)];
        scomL(i,:)=[scomxL(i),scomyL(i),scomzL(i)];
    r1=(scomL(i,:)-LAnk(i,:))/1000;
    r2=(LKnee(i,:)-scomL(i,:))/1000;
    LKneeCross=cross(r1,LAnkF)+cross(r2,LKneeF);
        LKneeMoment(i)=-1*((LKneeCross(1,1))-LShankI0*alphaLshank(i)+LAnkleMoment(i));
        LKneePower(i)=LKneeMoment(i)*wscomyL(i);
end

for i=1:abs(length(NewGRFzL)-lengthdiff-2)
    RThighLength=norm(RHip(i,:)-RKnee(i,:))/1000;
    RThighI0=ThighWeight*(RThighLength*0.54)^2;
        RxHipForce(i)=RxKneeForce(i)-ThighWeight*AtcomxR(i);
        RyHipForce(i)=RyKneeForce(i)-ThighWeight*AtcomyR(i);
        RzHipForce(i)=RzKneeForce(i)-ThighWeight*AtcomzR(i)-ThighWeight*9.8;
    RHipF=[RxHipForce(i), RyHipForce(i), RzHipForce(i)];
    RKneeF=[RxKneeForce(i), RyKneeForce(i), RzKneeForce(i)];
        tcomF=[tcomxR(i), tcomyR(i), tcomzR(i)];
    r1=(tcomF-RKnee(i,:))/1000;
    r2=(RHip(i,:)-tcomF)/1000;
    RHipCross=cross(r1,RKneeF)+cross(r2,RHipF);
        RHipMoment(i)=RHipCross(1,1)-RThighI0*alphaRthigh(i)+RKneeMoment(i);
        RHipPower(i)=RHipMoment(i)*wtcomyR(i);
end
for i=1:abs(length(NewGRFzL)-lengthdiff-2)
    LThighLength=norm(LHip(i,:)-LKnee(i,:))/1000;
    LThighI0=ThighWeight*(LThighLength*0.54)^2;
        LxHipForce(i)=LxKneeForce(i)-ThighWeight*AtcomxL(i);
        LyHipForce(i)=LyKneeForce(i)-ThighWeight*AtcomyL(i);
        LzHipForce(i)=LzKneeForce(i)-ThighWeight*AtcomzL(i)-ThighWeight*9.8;
    LHipF=[LxHipForce(i), LyHipForce(i), LzHipForce(i)];
    LKneeF=[LxKneeForce(i), LyKneeForce(i), LzKneeForce(i)];
        tcomS=[tcomxL(i), tcomyL(i), tcomzL(i)];
    r1=(tcomS-LKnee(i,:))/1000;
    r2=(LHip(i,:)-tcomS)/1000;
    LHipCross=cross(r1,LKneeF)+cross(r2,LHipF);
        LHipMoment(i)=LHipCross(1,1)-LThighI0*alphaLthigh(i)+LKneeMoment(i);
        LHipPower(i)=LHipMoment(i)*wtcomyL(i);
end


% Destroys outliers
for i=1:length(RAnkleMoment)
    if abs(RAnkleMoment(i))>3000
        RAnkleMoment(i)=NaN;
    end
    if abs(LAnkleMoment(i))>3000
        LAnkleMoment(i)=NaN;
    end
    if abs(RKneeMoment(i))>3000
        RKneeMoment(i)=NaN;
    end
    if abs(LKneeMoment(i))>3000
        LKneeMoment(i)=NaN;
    end
    if abs(RHipMoment(i))>3000
        RHipMoment(i)=NaN;
    end
    if abs(LHipMoment(i))>3000
        LHipMoment(i)=NaN;
    end
end

AllMoments=[RAnkleMoment' LAnkleMoment' RKneeMoment' LKneeMoment' RHipMoment' LHipMoment'];
labels={'RAnkM','LAnkM','RKneM','LKneM','RHipM','LHipM'};
AllMomentsTS=labTimeSeries(AllMoments,markerData.Time(1),markerData.sampPeriod,labels(:));

end

