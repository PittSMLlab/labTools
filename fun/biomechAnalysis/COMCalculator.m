function [COMTS] = COMCalculator(markerData)

%% Step 1: Get relevant marker data

%get orientation
if isempty(markerData.orientation)
    warning('Assuming default orientation of axes for marker data.');
    orientation=orientationInfo([0,0,0],'x','y','z',1,1,1);
else
    orientation=markerData.orientation;
end

% Define the marker data
%get hip position
u=[orientation.sideSign, orientation.foreaftSign, orientation.updownSign];
markerList={'RHip','LHip','RAnk','LAnk','RKne','LKne','RToe','LToe'};
for i=1:length(markerList)
    name=markerData.getLabelsThatMatch(['^' upper(markerList{i}) '*x$']); %To allow variations of the type: RKNEx and RKNEEx
    if ~isempty(name)
        name=name{1}(1:end-1);
        aux=markerData.getDataAsVector({[name orientation.sideAxis],[name orientation.foreaftAxis],[name orientation.updownAxis]});
        aux=aux.*u;
    else %Marker is missing from full trial (it happens)
        aux=nan(length(markerData.Time),3);
        warning(['Marker ' markerList{i} ' was missing from markerData.'])
    end
    %eval([markerList{i} '=aux;']); 
    assignin('base',markerList{i},aux) %This is more elegant than eval (and
    %recommended, but it doesnt seem to work)
end

% RHip=markerData.getDataAsVector({['RHIP' orientation.sideAxis],['RHIP' orientation.foreaftAxis],['RHIP' orientation.updownAxis]});
% RHip=RHip.*u;
% RHip=[orientation.sideSign*RHip(:,1),orientation.foreaftSign*RHip(:,2),orientation.updownSign*RHip(:,3)];
% LHip=markerData.getDataAsVector({['LHIP' orientation.sideAxis],['LHIP' orientation.foreaftAxis],['LHIP' orientation.updownAxis]});
% LHip=[orientation.sideSign*LHip(:,1),orientation.foreaftSign*LHip(:,2),orientation.updownSign*LHip(:,3)];
% %get ankle position
% RAnk=markerData.getDataAsVector({['RANK' orientation.sideAxis],['RANK' orientation.foreaftAxis],['RANK' orientation.updownAxis]});
% RAnk=[orientation.sideSign*RAnk(:,1),orientation.foreaftSign*RAnk(:,2),orientation.updownSign*RAnk(:,3)];
% LAnk=markerData.getDataAsVector({['LANK' orientation.sideAxis],['LANK' orientation.foreaftAxis],['LANK' orientation.updownAxis]});
% LAnk=[orientation.sideSign*LAnk(:,1),orientation.foreaftSign*LAnk(:,2),orientation.updownSign*LAnk(:,3)];
% %get knee position
% RkneeName=markerData.getLabelsThatMatch('^RKNE');
% RkneeName=RkneeName{1}(1:end-1); %Removing axis suffix
% RKnee=markerData.getDataAsVector({[RkneeName orientation.sideAxis],[RkneeName orientation.foreaftAxis],[RkneeName orientation.updownAxis]});
% RKnee=[orientation.sideSign*RKnee(:,1),orientation.foreaftSign*RKnee(:,2),orientation.updownSign*RKnee(:,3)];
% 
% LkneeName=markerData.getLabelsThatMatch('^LKNE');
% LkneeName=LkneeName{1}(1:end-1); %Removing axis suffix
% LKnee=markerData.getDataAsVector({[LkneeName orientation.sideAxis],[LkneeName orientation.foreaftAxis],[LkneeName orientation.updownAxis]});
% LKnee=[orientation.sideSign*LKnee(:,1),orientation.foreaftSign*LKnee(:,2),orientation.updownSign*LKnee(:,3)];
% %get toe position
% RToe=markerData.getDataAsVector({['RTOE' orientation.sideAxis],['RTOE' orientation.foreaftAxis],['RTOE' orientation.updownAxis]});
% RToe=[orientation.sideSign*RToe(:,1),orientation.foreaftSign*RToe(:,2),orientation.updownSign*RToe(:,3)];
% LToe=markerData.getDataAsVector({['LTOE' orientation.sideAxis],['LTOE' orientation.foreaftAxis],['LTOE' orientation.updownAxis]});
% LToe=[orientation.sideSign*LToe(:,1),orientation.foreaftSign*LToe(:,2),orientation.updownSign*LToe(:,3)];


%% Need to calculate the position of the center of mass of each segment

%Foot:
fcomR=(RAnk+RToe)/2;
fcomL=(LAnk+LToe)/2;
% fcomxR=(RAnk(:,1)-RToe(:,1)).*.5+RToe(:,1); %m
% fcomxL=(LAnk(:,1)-LToe(:,1)).*.5+LToe(:,1); %m
% fcomyR=(RAnk(:,2)-RToe(:,2)).*.5+RToe(:,2); %m
% fcomzR=(RAnk(:,3)-RToe(:,3)).*.5+RToe(:,3); %m
% fcomyL=(LAnk(:,2)-LToe(:,2)).*.5+LToe(:,2); %m
% fcomzL=(LAnk(:,3)-LToe(:,3)).*.5+LToe(:,3); %m
% 
% fcomR=[fcomxR,fcomyR,fcomzR]; %foot
% fcomL=[fcomxL,fcomyL,fcomzL];

%Shank:
scomR=(RKne-RAnk)+.394*RAnk;
scomL=(LKne-LAnk)+.394*LAnk;

% scomxR=(RKnee(:,1)-RAnk(:,1)).*.394+RAnk(:,1);
% scomxL=(LKnee(:,1)-LAnk(:,1)).*.394+LAnk(:,1);
% scomyR=(RKnee(:,2)-RAnk(:,2)).*.394+RAnk(:,2);
% scomzR=(RKnee(:,3)-RAnk(:,3)).*.394+RAnk(:,3);
% scomyL=(LKnee(:,2)-LAnk(:,2)).*.394+LAnk(:,2);
% scomzL=(LKnee(:,3)-LAnk(:,3)).*.394+LAnk(:,3);
% 
% scomR=[scomxR,scomyR,scomzR]; %Shank
% scomL=[scomxL,scomyL,scomzL];

%Thigh:
tcomR=(RHip-RKne)+.567*RKne;
tcomL=(LHip-LKne)+.567*LKne;
% tcomxR=(RHip(:,1)-RKnee(:,1)).*.567+RKnee(:,1);
% tcomxL=(LHip(:,1)-LKnee(:,1)).*.567+LKnee(:,1);
% tcomyR=(RHip(:,2)-RKnee(:,2)).*.567+RKnee(:,2);
% tcomzR=(RHip(:,3)-RKnee(:,3)).*.567+RKnee(:,3);
% tcomyL=(LHip(:,2)-LKnee(:,2)).*.567+LKnee(:,2);
% tcomzL=(LHip(:,3)-LKnee(:,3)).*.567+LKnee(:,3);
% 
% tcomR=[tcomxR,tcomyR,tcomzR]; %Thigh
% tcomL=[tcomxL,tcomyL,tcomzL];

%% Save everything in an orientedLabTS
COMData=[fcomR fcomL scomR scomL tcomR tcomL]; %CJS note to self, change here to change what is stored in the COM
%COM accelerations for each of the different body parts in each of the
%directions.

labels={'RfCOM','LfCOM','RsCOM','LsCOM','RtCOM','LtCOM'};
labels=[strcat(labels,'x'); strcat(labels,'y'); strcat(labels,'z')];

%Pablo: creating orientedLabTS
COMTS=orientedLabTimeSeries(COMData,markerData.Time(1),markerData.sampPeriod,labels(:),markerData.orientation);


end

