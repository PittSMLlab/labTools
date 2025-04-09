function [rotatedMarkerData,sAnkFwd,fAnkFwd,sAnk2D,fAnk2D, ...
    sAngle,fAngle,direction,hipPosSHS,sAnk_fromAvgHip,fAnk_fromAvgHip] =...
    getKinematicDataAbs(eventTimes,markerData,angleData,s)
%getKinematicData   loads marker data sampled only at time of gait events
%
%getKinematicData generates:
%
% Three dimensional matrices in the format:
%   number of strides x 6 events (SHS thru FTO2) x 2 dimensions (x,y)
% whith variable names:
%   sAnk2D, fAnk2D
%
% Two dimensional matrices in the format:
%   number of strides x 6 events (SHS thru FTO2)
% with variable names:
%   sAnkFwd, fAnkFwd: ankle position in fore-aft direction with respect to avg hip
%   sAngle, fAngle: limb angles (angle of hip-ankle vector with respect to verticle)
%
% direction: a vector with length equal to the number of strides and
%   values of 1 if walking towards the door in the lab and -1 if walking
%   towards the window.

% Three dimensional matrices in the format:
%   number of strides x 6 events (SHS thru FTO2) x 3 dimensions (x,y,z)
% whith variable names:
%   sHip
%   fHip
%   sAnk
%   fAnk
%   sToe
%   fToe

refMarker3D=[0,0,0]; %Absolute lab reference

%Ref axis option 2 (assuming the subject walks only along the y axis):
refAxis=squeeze(diff(markerData.getOrientedData({'LANK','RANK'}),1,2)); %So that only ankle markers are needed to determine walking direction
refAxis=refAxis*[1,0,0]' *[1,0,0]; %Projecting along x direction, this is equivalent to just determining forward/backward sign
rotatedMarkerData=markerData.translate(-squeeze(refMarker3D)).alignRotate(refAxis,[0,0,1]);

%% Get Relevant Sample of Data (Using Interpolation)
% 's' represents the slow limb, 'f' represents the fast limb
if strcmp(s,'L')
    f = 'R';
elseif strcmp(s,'R')
    f = 'L';
else
    error('Invalid limb specification. Must be ''L'' or ''R''.');
end

% extract marker orientation and axis information
orientation = markerData.orientation;
directions = {orientation.sideAxis,orientation.foreaftAxis,orientation.updownAxis};
signs = [orientation.sideSign orientation.foreaftSign orientation.updownSign];

% define markers of interest
markers = {'HIP','ANK','TOE'};
labels = {};
legs = {s,f};
legs2 = {'s','f'};

% construct labels for markers (e.g., 'sHIP', 'fANK', etc.)
for j = 1:length(markers)
    for leg = 1:2
        labels{end+1} = [legs{leg} markers{j}]; % odd indices: slow leg, even indices: fast leg
    end
end

% check for missing markers
[bool,idx] = isaLabelPrefix(markerData,labels);
if ~all(bool)
    warning(['Markers are missing: ' cell2mat(strcat(labels(~bool),','))]);
end

% extract marker data at gait event times
for j = 1:length(labels)    % assign each marker data to a x3 str
    aux = markerData.getDataAsTS(markerData.addLabelSuffix(labels{j}));
    if ~isempty(aux.Data)
        % extract data by finding the closest available sample at each event time
        newMarkerData = aux.getSample(eventTimes,'closest');
        relMarkerData = rotatedMarkerData.getDataAsTS(rotatedMarkerData.addLabelSuffix(labels{j}));
        relMarkerData = relMarkerData.getSample(eventTimes,'closest');
    else    % otherwise, a marker is missing
        warning(['Marker ' labels{j} ' is missing. All references to it will return NaN.']);
        newMarkerData = nan([size(eventTimes) 3]);
        relMarkerData = nan([size(eventTimes) 3]);
    end

    % assign extracted marker data to corresponding variables
    if strcmp(labels{j}(1),s)       % if slow leg markers, ...
        eval(['s' upper(labels{j}(2)) lower(labels{j}(3:4)) ' = newMarkerData;']);
        eval(['s' upper(labels{j}(2)) lower(labels{j}(3:4)) 'Rel = relMarkerData;']);
    elseif strcmp(labels{j}(1),f)   % if fast leg markers, ...
        eval(['f' upper(labels{j}(2)) lower(labels{j}(3:4)) ' = newMarkerData;']);
        eval(['f' upper(labels{j}(2)) lower(labels{j}(3:4)) 'Rel = relMarkerData;']);
    else                            % otherwise, ...
        error('Marker labels must begin with ''R'' or ''L''.');
    end
end

%% Extract Angle Data at Gait Event Times
if ~isempty(angleData)
    newAngleData = angleData.getDataAsTS({[s 'Limb'],[f 'Limb']});
    newAngleData = newAngleData.getSample(eventTimes,'closest');
    sAngle = newAngleData(:,:,1);
    fAngle = newAngleData(:,:,2);
else
    sAngle = nan(size(eventTimes,1),size(eventTimes,2),1);
    fAngle = nan(size(eventTimes,1),size(eventTimes,2),1);
end

%find walking direction
direction=sign(diff(sAnk(:,2:3,2),1,2)); %Difference in ankle marker position on the y-axis, between fTO and fHS


%% Compute Ankle Positions Relative to Hip
hipPos3D = 0.5 * (sHip + fHip);
hipPos3DRel = 0.5 * (sHipRel + fHipRel); %Just for check, should be all zeros
hipPosFwd=hipPos3D(:,:,2);%Y-axis component
%hipPos= mean([sHip(indSHS,2) fHip(indSHS,2)]);
hipPosSHS=hipPosFwd(:,1);
hipPosAvg_forFast = mean(nanmean(hipPosFwd(:,1:6))); % Average Hip Position from SHS to STO2
hipPosAvg_forSlow = mean(nanmean(hipPosFwd(:,3:8))); % Average Hip Position from SHS to STO2

%rotate coordinates to be aligned wiht walking dierection
%sRotation = calcangle(sAnk(indSHS2,1:2),sAnk(indSTO,1:2),[sAnk(indSTO,1)-100*direction sAnk(indSTO,2)])-90;
%fRotation = calcangle(fAnk(indFHS,1:2),fAnk(indFTO,1:2),[fAnk(indFTO,1)-100*direction fAnk(indFTO,2)])-90;

%avgRotation = (sRotation+fRotation)./2;

%rotationMatrix = [cosd(avgRotation) -sind(avgRotation) 0; sind(avgRotation) cosd(avgRotation) 0; 0 0 1];
%sAnk(indSHS:indFTO2,:) = (rotationMatrix*sAnk(indSHS:indFTO2,:)')';
%fAnk(indSHS:indFTO2,:) = (rotationMatrix*fAnk(indSHS:indFTO2,:)')';
%sHip(indSHS:indFTO2,:) = (rotationMatrix*sHip(indSHS:indFTO2,:)')';
%fHip(indSHS:indFTO2,:) = (rotationMatrix*fHip(indSHS:indFTO2,:)')';

% NEED TO ROTATE
hipPos2D = hipPos3D(:,:,1:2);
%Compute ankle position relative to average hip position
sAnkFwd = sAnk(:,:,2);
fAnkFwd = fAnk(:,:,2);
sAnk2D = sAnk(:,:,1:2);
fAnk2D = fAnk(:,:,1:2);
sAnk_fromAvgHip = sAnk(:,:,2) - hipPosAvg_forSlow; % y positon of slow ankle corrected by average hip postion
fAnk_fromAvgHip = fAnk(:,:,2) - hipPosAvg_forFast; % y positon of fast ankle corrected by average hip postion
% Set all steps to have the same slope (a negative slope during stance phase is assumed)
%WHAT IS THIS FOR? WHAT PROBLEMS DOES IT SOLVE THAT THE PREVIOUS ROTATION
%DOESN'T?

aux = sign(diff(sAnk(:,[4,5],2),1,2)); %Checks for: sAnk(indSHS2,2)<sAnk(indSTO,2). Doesn't use HIP to avoid HIP fluctuation issues.
sAnkFwd = bsxfun(@times,sAnkFwd,aux);
fAnkFwd = bsxfun(@times,fAnkFwd,aux);
sAnk2D = bsxfun(@times,sAnk2D,aux);
fAnk2D = bsxfun(@times,fAnk2D,aux);

%Alternative definition: should be equivalent, since we reference to midHip
%when doing the rotation. Only difference may be in sign of walking, since
%its computed slighltly different. Should not cause issues as differences
%may only ocurr when subject is turning around, which is a bad stride
%anyway
%WARNING: THIS WAS DISABLED BECAUSE IT LEADS TO CRAPPY RESULTS WHEN HIP
%MARKERS ARE NOT RELIABLE (NOISY). NEED TO FIX. THE PROBLEM IS
%sAnkFwd-fAnkFwd DEPENDS ON HIP POSITION WHEN IT SHOULDNT (COMPUTING
%DIFFERENCE OF TWO MARKER POSITIONS USING SAME REFERENCE). NOT SURE WHY.
%sAnkFwd=sAnkRel(:,:,2);
%fAnkFwd=fAnkRel(:,:,2);
%sAnk2D=sAnkRel(:,:,1:2);
%fAnk2D=fAnkRel(:,:,1:2);

aux = sign(sAngle(:,1));            % checks for sAngle(indSHS) < 0
sAngle = bsxfun(@times,sAngle,aux);
fAngle = bsxfun(@times,fAngle,aux);

end

