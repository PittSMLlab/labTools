function AllMomentsTS = ...
    TorqueCalculatorNew(COMTS,COPTS,markerData,GRFData,weight)
%TORQUECALCULATORNEW Joint moments of both legs by inverse dynamics.
%
%   Computes ankle, knee, and hip moments of both legs from the segment
% centers of mass, the center of pressure and ground reaction forces, and
% the marker positions. Starting at the foot, segment accelerations come
% from the double derivative of the COM positions (low-passed at 20 Hz),
% segment masses and moments of inertia from body weight fractions, and
% each joint inherits the force and moment of the joint below. Moments
% larger than the limit in momentLimit are set to NaN.
%
% Side effects: warns when a marker is missing from markerData or the
%   orientation has to be assumed.
%
% Inputs:
%   COMTS      - segment centers of mass from COMCalculator
%   COPTS      - center of pressure and forces from COPCalculator
%   markerData - orientedLabTimeSeries of marker positions (mm)
%   GRFData    - GRF time series (LFz and RFz are read but not used; the
%                body weight comes from weight)
%   weight     - body weight
%
% Outputs:
%   AllMomentsTS - labTimeSeries with RAnkM, LAnkM, RKneM, LKneM, RHipM,
%                  LHipM
%
% Toolbox Dependencies: Signal Processing Toolbox (butter, filtfilt)
%
% See also TORQUECALCULATOR, COMCALCULATOR, COPCALCULATOR.

%% Get Center of Mass Time Series (COMTS) data
fcomR  = squeeze(COMTS.getOrientedData({'RfCOM'}));  % right foot COM
fcomxR = fcomR(:,1);
fcomyR = fcomR(:,2);
fcomzR = fcomR(:,3);

fcomL  = squeeze(COMTS.getOrientedData({'LfCOM'}));  % left foot COM
fcomxL = fcomL(:,1);
fcomyL = fcomL(:,2);
fcomzL = fcomL(:,3);

scomR  = squeeze(COMTS.getOrientedData({'RsCOM'}));  % right shank COM
scomxR = scomR(:,1);
scomyR = scomR(:,2);
scomzR = scomR(:,3);

scomL  = squeeze(COMTS.getOrientedData({'LsCOM'}));  % left shank COM
scomxL = scomL(:,1);
scomyL = scomL(:,2);
scomzL = scomL(:,3);

tcomR  = squeeze(COMTS.getOrientedData({'RtCOM'}));  % right thigh COM
tcomxR = tcomR(:,1);
tcomyR = tcomR(:,2);
tcomzR = tcomR(:,3);

tcomL  = squeeze(COMTS.getOrientedData({'LtCOM'}));  % left thigh COM
tcomxL = tcomL(:,1);
tcomyL = tcomL(:,2);
tcomzL = tcomL(:,3);

%% Get Center of Pressure Time Series (COPTS) data
NewGRFs  = ...
    COPTS.getDataAsTS({'RGRFx','RGRFy','RGRFz','LGRFx','LGRFy', ...
    'LGRFz'}).getSample(markerData.Time);
NewGRFzR = NewGRFs(:,3);
NewGRFyR = NewGRFs(:,2);
NewGRFxR = NewGRFs(:,1);
NewGRFzL = NewGRFs(:,6);
NewGRFyL = NewGRFs(:,5);
NewGRFxL = NewGRFs(:,4);
NewCOPs  = ...
    COPTS.getDataAsTS({'LCOPx','LCOPy','RCOPx', ...
    'RCOPy'}).getSample(markerData.Time);
NewCOPyR = NewCOPs(:,4);
NewCOPxR = NewCOPs(:,3);
NewCOPyL = NewCOPs(:,2);
NewCOPxL = NewCOPs(:,1);

%% Get relevant markerData
%get orientation
if isempty(markerData.orientation)
    warning('Assuming default orientation of axes for marker data.');
    orientation = orientationInfo([0,0,0],'x','y','z',1,1,1);
else
    orientation = markerData.orientation;
end

%% Constants
footMassFraction     = 0.0145;  % TODO: source? (fraction of body weight)
shankMassFraction    = 0.0465;  % TODO: source? (fraction of body weight)
thighMassFraction    = 0.1;     % TODO: source? (fraction of body weight)
footGyrationRatio    = 0.690;   % TODO: source? (times segment length)
shankGyrationRatio   = 0.645;   % TODO: source? (times segment length)
thighGyrationRatio   = 0.54;    % TODO: source? (times segment length)
gravity              = 9.8;     % m/s^2
mmPerM               = 1000;    % marker positions are in mm
cutoffHz             = 20;      % TODO: source? (COM acceleration filter)
sampFreqHz           = 1000;    % TODO: source? (filter sampling rate)
momentLimit          = 3000;    % TODO: source? (larger moments: NaN)

% Define the body weight of the patient
LFz = GRFData.getDataAsVector('LFz');
RFz = GRFData.getDataAsVector('RFz');
BW  = weight;%abs(LFz(1,1)+RFz(1,1));

FootWeight  = (BW*footMassFraction);
ShankWeight = BW*shankMassFraction;
ThighWeight = BW*thighMassFraction;

% Get marker data
u          = [orientation.sideSign, orientation.foreaftSign, ...
    orientation.updownSign];
markerList = {'RHip','LHip','RAnk','LAnk','RKne','LKne','RToe','LToe'};
for ii = 1:length(markerList)
    %To allow variations of the type: RKNEx and RKNEEx
    name = markerData.getLabelsThatMatch(['^' upper(markerList{ii}) '*x$']);
    if ~isempty(name)
        name = name{1}(1:end-1);
        aux  = markerData.getDataAsVector({[name orientation.sideAxis], ...
            [name orientation.foreaftAxis],[name orientation.updownAxis]});
        aux  = aux.*u;
    else %Marker is missing from full trial (it happens)
        aux = nan(length(markerData.Time),3);
        warning(['Marker ' markerList{ii} ' was missing from markerData.'])
    end
    eval([markerList{ii} '=aux;']);
    %assignin('base',markerList{i},aux) %This is more elegant than eval (and
    %recommended, but it doesnt seem to work)
end

%% Segment angles
fcomRangle     = []; fcomLangle = []; scomRangle = []; scomLangle = ...
    []; tcomRangle = []; tcomLangle = [];
VerticalVector = [0,0,1];

for ii = 1:size(fcomL,1)
    RFootCOMLength  = RAnk(ii,:)-fcomR(ii,:);
    LFootCOMLength  = LAnk(ii,:)-fcomL(ii,:);
    RShankCOMLength = RKne(ii,:)-scomR(ii,:);
    LShankCOMLength = LKne(ii,:)-scomL(ii,:);
    RThighCOMLength = RHip(ii,:)-tcomR(ii,:);
    LThighCOMLength = LHip(ii,:)-tcomL(ii,:);

    fcomRangle(ii) = atan2(RFootCOMLength(1,2)-VerticalVector(1,2), ...
        RFootCOMLength(1,3)-VerticalVector(1,3));
    fcomLangle(ii) = atan2(LFootCOMLength(1,2)-VerticalVector(1,2), ...
        LFootCOMLength(1,3)-VerticalVector(1,3));
    scomRangle(ii) = atan2(RShankCOMLength(1,2)-VerticalVector(1,2), ...
        RShankCOMLength(1,3)-VerticalVector(1,3));
    scomLangle(ii) = atan2(LShankCOMLength(1,2)-VerticalVector(1,2), ...
        LShankCOMLength(1,3)-VerticalVector(1,3));
    tcomRangle(ii) = atan2(RThighCOMLength(1,2)-VerticalVector(1,2), ...
        RThighCOMLength(1,3)-VerticalVector(1,3));
    tcomLangle(ii) = atan2(LThighCOMLength(1,2)-VerticalVector(1,2), ...
        LThighCOMLength(1,3)-VerticalVector(1,3));
end
% Determine the acceleration by differentiating the center of mass
% position twice and then applying a small filter on the data.
[B,A] = butter(1, cutoffHz/(sampFreqHz/2));
AfcomxR = diff(diff(fcomxR./mmPerM));
AfcomxR = filtfilt(B,A,AfcomxR);
AfcomyR = diff(diff(fcomyR./mmPerM));
AfcomyR = filtfilt(B,A,AfcomyR);
AfcomzR = diff(diff(fcomzR./mmPerM));
AfcomzR = filtfilt(B,A,AfcomzR);
AfcomxL = diff(diff(fcomxL./mmPerM));
AfcomxL = filtfilt(B,A,AfcomxL);
AfcomyL = diff(diff(fcomyL./mmPerM));
AfcomyL = filtfilt(B,A,AfcomyL);
AfcomzL = diff(diff(fcomzL./mmPerM));
AfcomzL = filtfilt(B,A,AfcomzL);

AscomxR = diff(diff(scomxR./mmPerM));
AscomxR = filtfilt(B,A,AscomxR);
AscomyR = diff(diff(scomyR./mmPerM));
AscomyR = filtfilt(B,A,AscomyR);
AscomzR = diff(diff(scomzR./mmPerM));
AscomzR = filtfilt(B,A,AscomzR);
AscomzL = diff(diff(scomzL./mmPerM));
AscomzL = filtfilt(B,A,AscomzL);
AscomyL = diff(diff(scomyL./mmPerM));
AscomyL = filtfilt(B,A,AscomyL);
AscomxL = diff(diff(scomxL./mmPerM));
AscomxL = filtfilt(B,A,AscomxL);

AtcomxR = diff(diff(tcomxR./mmPerM));
AtcomxR = filtfilt(B,A,AtcomxR);
AtcomyR = diff(diff(tcomyR./mmPerM));
AtcomyR = filtfilt(B,A,AtcomyR);
AtcomzR = diff(diff(tcomzR./mmPerM));
AtcomzR = filtfilt(B,A,AtcomzR);
AtcomxL = diff(diff(tcomxL./mmPerM));
AtcomxL = filtfilt(B,A,AtcomxL);
AtcomyL = diff(diff(tcomyL./mmPerM));
AtcomyL = filtfilt(B,A,AtcomyL);
AtcomzL = diff(diff(tcomzL./mmPerM));
AtcomzL = filtfilt(B,A,AtcomzL);
% Define the angular accleration by finding the angle that the limb is
% away from a vertical point, and then differentiate this signal twice.
% Then a small filter is applied to the angular accleration data.
alphaRfoot  = diff(diff(fcomRangle));
alphaRfoot  = filtfilt(B,A,alphaRfoot);
alphaLfoot  = diff(diff(fcomLangle));
alphaLfoot  = filtfilt(B,A,alphaLfoot);
alphaRshank = diff(diff(scomRangle));
alphaRshank = filtfilt(B,A,alphaRshank);
alphaLshank = diff(diff(scomLangle));
alphaLshank = filtfilt(B,A,alphaLshank);
alphaRthigh = diff(diff(tcomRangle));
alphaRthigh = filtfilt(B,A,alphaRthigh);
alphaLthigh = diff(diff(tcomLangle));
alphaLthigh = filtfilt(B,A,alphaLthigh);
% Define the angular velocity in a similar manner
wfcomyR = diff(fcomRangle);
wfcomyR = filtfilt(B,A,wfcomyR);
wfcomyL = diff(fcomLangle);
wfcomyL = filtfilt(B,A,wfcomyL);
wscomyR = diff(scomRangle);
wscomyR = filtfilt(B,A,wscomyR);
wscomyL = diff(scomLangle);
wscomyL = filtfilt(B,A,wscomyL);
wtcomyR = diff(tcomRangle);
wtcomyR = filtfilt(B,A,wtcomyR);
wtcomyL = diff(tcomLangle);
wtcomyL = filtfilt(B,A,wtcomyL);



%From here on, anywhere it says F should say R, and anywhere that says s
%should say L (domLeg==1)

% The number of frames differs betwen the force and marker data by a
% few frames after getting the new forces. Find the difference to make
% sure future for loops do not break.
lengthdiff = abs(length(RAnk)-length(NewGRFzR));
COPcount   = 1;
Cross1     = []; Cross2 = [];
for ii = 1:(length(RAnk)-lengthdiff-2)
    % Define second moment of inertia for the segment.
    RFootLength = norm(RAnk(ii,:)-RToe(ii,:))/mmPerM;
    RFootI0     = FootWeight*(RFootLength*footGyrationRatio)^2;
    % Define the reaction forces at the ankle based on a freebody
    % diagram of the foot.
    RzAnkleForce(ii) = -1*FootWeight*gravity-FootWeight*AfcomzR(ii) ...
        +NewGRFzR(ii);
    RyAnkleForce(ii) = NewGRFyR(ii)-FootWeight*AfcomyR(ii);
    RxAnkleForce(ii) = NewGRFxR(ii)-FootWeight*AfcomxR(ii);

    % Place the ground reaciton forces and the reaction forces into
    % their own matrices.
    GRFR  = [NewGRFxR(ii),NewGRFyR(ii),NewGRFzR(ii)];
    COPfR = [NewCOPxR(COPcount),NewCOPyR(COPcount),0];
    RAnkF = [RxAnkleForce(ii),RyAnkleForce(ii),RzAnkleForce(ii)];
    % Place the center of masses and the center of pressures into their
    % own matrices.
    fcomR = [fcomxR(ii),fcomyR(ii),fcomzR(ii)];
    % Ensure that when the foot is not on the ground that the distance
    % between the center of mass and center of pressure is zero.
    r1 = (fcomR-COPfR)/mmPerM;
    if isnan(NewCOPxR(COPcount)) == 1
        r1 = [0,0,0];
    end
    r2 = (RAnk(ii,:)-fcomR)/mmPerM;
    % Perform a cross product between the distances and forces to get
    % the overall moments occuring at the right ankle joint.
    Cross1(ii,:) = cross(r1,GRFR);
    Cross2(ii,:) = cross(r2,RAnkF);
    RAnkleCross = Cross1(ii,:)+Cross2(ii,:);
    % Subtract away the moment of intertia multiplied by the angular
    % accleration to get the total ankle moment.
    RAnkleMoment(ii) = RAnkleCross(1,1)-RFootI0*alphaRfoot(ii);
    RAnklePower(ii) = RAnkleMoment(ii)*wfcomyR(ii);
    COPcount = COPcount+1;
end
COPcount = 1;
Cross1   = []; Cross2 = [];
for ii = 1:(length(LAnk)-lengthdiff-2)
    % Define second moment of inertia for the segment.
    LFootLength = norm(LAnk(ii,:)-LToe(ii,:))/mmPerM;
    LFootI0     = FootWeight*(LFootLength*footGyrationRatio)^2;
    % Define the reaction forces at the ankle based on a freebody
    % diagram of the foot.
    LzAnkleForce(ii) = -1*FootWeight*gravity-FootWeight*AfcomzL(ii) ...
        +NewGRFzL(ii);
    LyAnkleForce(ii) = NewGRFyL(ii)-FootWeight*AfcomyL(ii);
    LxAnkleForce(ii) = NewGRFxL(ii)-FootWeight*AfcomxL(ii);
    % Place the ground reaciton forces and the reaction forces into
    % their own matrices.
    GRFL  = [NewGRFxL(ii),NewGRFyL(ii),NewGRFzL(ii)];
    COPfL = [NewCOPxL(COPcount),NewCOPyL(COPcount),0];
    LAnkF = [LxAnkleForce(ii),LyAnkleForce(ii),LzAnkleForce(ii)];
    % Place the center of masses and the center of pressures into their
    % own matrices.
    fcomL = [fcomxL(ii),fcomyL(ii),fcomzL(ii)];
    % Ensure that when the foot is not on the ground that the distance
    % between the center of mass and center of pressure is zero.
    r1 = (fcomL-COPfL)/mmPerM;
    if isnan(NewCOPxL(COPcount)) == 1
        r1 = [0,0,0];
    end
    r2 = (LAnk(ii,:)-fcomL)/mmPerM;
    % Perform a cross product between the distances and forces to get
    % the overall moments occuring at the right ankle joint.
    Cross1(ii,:) = cross(r1,GRFL);
    Cross2(ii,:) = cross(r2,LAnkF);
    LAnkleCross = Cross1(ii,:)+Cross2(ii,:);
    % Subtract away the moment of intertia multiplied by the angular
    % accleration to get the total ankle moment.
    LAnkleMoment(ii) = LAnkleCross(1,1)-LFootI0*alphaLfoot(ii);
    LAnklePower(ii) = LAnkleMoment(ii)*wfcomyL(ii);
    COPcount = COPcount+1;
end


for ii = 1:abs(length(NewGRFzL)-lengthdiff-2)
    RShankLength = norm(RKne(ii,:)-RAnk(ii,:))/mmPerM;
    RShankI0     = ShankWeight*(RShankLength*shankGyrationRatio)^2;
    RyKneeForce(ii) = RyAnkleForce(ii)-ShankWeight*AscomyR(ii);
    RzKneeForce(ii) = RzAnkleForce(ii)-ShankWeight*AscomzR(ii) ...
        -ShankWeight*gravity;
    RxKneeForce(ii) = RxAnkleForce(ii)-ShankWeight*AscomxR(ii);

    RAnkF  = [RxAnkleForce(ii),RyAnkleForce(ii),RzAnkleForce(ii)];
    RKneeF = [RxKneeForce(ii),RyKneeForce(ii),RzKneeForce(ii)];
    scomR(ii,:) = [scomxR(ii),scomyR(ii),scomzR(ii)];
    r1         = (scomR(ii,:)-RAnk(ii,:))/mmPerM;
    r2         = (RKne(ii,:)-scomR(ii,:))/mmPerM;
    RKneeCross = cross(r1,RAnkF)+cross(r2,RKneeF);
    RKneeMoment(ii) = ...
        -1*((RKneeCross(1,1))-RShankI0*alphaRshank(ii)+RAnkleMoment(ii));
    RKneePower(ii) = RKneeMoment(ii)*wscomyR(ii);
end
for ii = 1:abs(length(NewGRFzL)-lengthdiff-2)
    LShankLength = norm(LKne(ii,:)-LAnk(ii,:))/mmPerM;
    LShankI0     = ShankWeight*(LShankLength*shankGyrationRatio)^2;
    LyKneeForce(ii) = LyAnkleForce(ii)-ShankWeight*AscomyL(ii);
    LzKneeForce(ii) = LzAnkleForce(ii)-ShankWeight*AscomzL(ii) ...
        -ShankWeight*gravity;
    LxKneeForce(ii) = LxAnkleForce(ii)-ShankWeight*AscomxL(ii);
    LAnkF  = [LxAnkleForce(ii),LyAnkleForce(ii),LzAnkleForce(ii)];
    LKneeF = [LxKneeForce(ii),LyKneeForce(ii),LzKneeForce(ii)];
    scomL(ii,:) = [scomxL(ii),scomyL(ii),scomzL(ii)];
    r1         = (scomL(ii,:)-LAnk(ii,:))/mmPerM;
    r2         = (LKne(ii,:)-scomL(ii,:))/mmPerM;
    LKneeCross = cross(r1,LAnkF)+cross(r2,LKneeF);
    LKneeMoment(ii) = ...
        -1*((LKneeCross(1,1))-LShankI0*alphaLshank(ii)+LAnkleMoment(ii));
    LKneePower(ii) = LKneeMoment(ii)*wscomyL(ii);
end

for ii = 1:abs(length(NewGRFzL)-lengthdiff-2)
    RThighLength = norm(RHip(ii,:)-RKne(ii,:))/mmPerM;
    RThighI0     = ThighWeight*(RThighLength*thighGyrationRatio)^2;
    RxHipForce(ii) = RxKneeForce(ii)-ThighWeight*AtcomxR(ii);
    RyHipForce(ii) = RyKneeForce(ii)-ThighWeight*AtcomyR(ii);
    RzHipForce(ii) = RzKneeForce(ii)-ThighWeight*AtcomzR(ii) ...
        -ThighWeight*gravity;
    RHipF     = [RxHipForce(ii), RyHipForce(ii), RzHipForce(ii)];
    RKneeF    = [RxKneeForce(ii), RyKneeForce(ii), RzKneeForce(ii)];
    tcomF     = [tcomxR(ii), tcomyR(ii), tcomzR(ii)];
    r1        = (tcomF-RKne(ii,:))/mmPerM;
    r2        = (RHip(ii,:)-tcomF)/mmPerM;
    RHipCross = cross(r1,RKneeF)+cross(r2,RHipF);
    RHipMoment(ii) = RHipCross(1,1)-RThighI0*alphaRthigh(ii) ...
        +RKneeMoment(ii);
    RHipPower(ii) = RHipMoment(ii)*wtcomyR(ii);
end
for ii = 1:abs(length(NewGRFzL)-lengthdiff-2)
    LThighLength = norm(LHip(ii,:)-LKne(ii,:))/mmPerM;
    LThighI0     = ThighWeight*(LThighLength*thighGyrationRatio)^2;
    LxHipForce(ii) = LxKneeForce(ii)-ThighWeight*AtcomxL(ii);
    LyHipForce(ii) = LyKneeForce(ii)-ThighWeight*AtcomyL(ii);
    LzHipForce(ii) = LzKneeForce(ii)-ThighWeight*AtcomzL(ii) ...
        -ThighWeight*gravity;
    LHipF     = [LxHipForce(ii), LyHipForce(ii), LzHipForce(ii)];
    LKneeF    = [LxKneeForce(ii), LyKneeForce(ii), LzKneeForce(ii)];
    tcomS     = [tcomxL(ii), tcomyL(ii), tcomzL(ii)];
    r1        = (tcomS-LKne(ii,:))/mmPerM;
    r2        = (LHip(ii,:)-tcomS)/mmPerM;
    LHipCross = cross(r1,LKneeF)+cross(r2,LHipF);
    LHipMoment(ii) = LHipCross(1,1)-LThighI0*alphaLthigh(ii) ...
        +LKneeMoment(ii);
    LHipPower(ii) = LHipMoment(ii)*wtcomyL(ii);
end


% Destroys outliers
for ii = 1:length(RAnkleMoment)
    if abs(RAnkleMoment(ii)) > momentLimit
        RAnkleMoment(ii) = NaN;
    end
    if abs(LAnkleMoment(ii)) > momentLimit
        LAnkleMoment(ii) = NaN;
    end
    if abs(RKneeMoment(ii)) > momentLimit
        RKneeMoment(ii) = NaN;
    end
    if abs(LKneeMoment(ii)) > momentLimit
        LKneeMoment(ii) = NaN;
    end
    if abs(RHipMoment(ii)) > momentLimit
        RHipMoment(ii) = NaN;
    end
    if abs(LHipMoment(ii)) > momentLimit
        LHipMoment(ii) = NaN;
    end
end

AllMoments   = [RAnkleMoment' LAnkleMoment' RKneeMoment' LKneeMoment' ...
    RHipMoment' LHipMoment'];
labels       = {'RAnkM','LAnkM','RKneM','LKneM','RHipM','LHipM'};
AllMomentsTS = labTimeSeries(AllMoments,markerData.Time(1), ...
    markerData.sampPeriod,labels(:));

end

