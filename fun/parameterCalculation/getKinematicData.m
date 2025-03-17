function [rotatedMarkerData,sAnkFwd,fAnkFwd,sAnk2D,fAnk2D,sAngle, ...
    fAngle,direction,hipPosSHS,sAnk_fromAvgHip,fAnk_fromAvgHip] = ...
    getKinematicData(eventTimes,markerData,angleData,s)
%GETKINEMATICDATA loads marker data sampled only at time of gait events
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

%THE FOLLOWING RELIES ON HAVING A DECENT RECONSTRUCTION OF HIP MARKERS:
refMarker3D = 0.5 * sum(markerData.getOrientedData({'LHIP','RHIP'}),2); %midHip

% Ref axis option 1 (ideal): Body reference
refAxis = squeeze(diff(markerData.getOrientedData({'LHIP','RHIP'}),1,2)); %L to R

% Ref axis option 2 (assuming the subject walks only along the y axis):
refAxis = refAxis * [1 0 0]' * [1 0 0]; % projecting along x direction, this is equivalent to just determining forward/backward sign
rotatedMarkerData = markerData.translate(-squeeze(refMarker3D)).alignRotate(refAxis,[0 0 1]);

%% Get relevant sample of data (using interpolation)
if strcmp(s,'L')
    f = 'R';
elseif strcmp(s,'R')
    f = 'L';
else
    error();
end
orientation = markerData.orientation;
directions = {orientation.sideAxis,orientation.foreaftAxis,orientation.updownAxis};
signs = [orientation.sideSign orientation.foreaftSign orientation.updownSign];
markers = {'HIP','ANK','TOE'};
labels = {};
legs = {s,f};
legs2 = {'s','f'};
for j = 1:length(markers)
    for leg = 1:2
        labels{end+1} = [legs{leg} markers{j}]; % odd are s, Even are f
    end
end

[bool,idx] = isaLabelPrefix(markerData,labels);
if ~all(bool)
    warning(['Markers are missing: ' cell2mat(strcat(labels(~bool),','))]);
end

for j = 1:length(labels)    % assign each marker data to a x3 str
    aux = markerData.getDataAsTS(markerData.addLabelSuffix(labels{j}));
    if ~isempty(aux.Data)
        newMarkerData = aux.getSample(eventTimes,'closest');    % closest point interpolation
        aux = rotatedMarkerData.getDataAsTS(rotatedMarkerData.addLabelSuffix(labels{j}));
        relMarkerData = aux.getSample(eventTimes,'closest');    % closest point interpolation
    else    % otherwise, missing marker
        warning(['Marker ' labels{j} ' is missing. All references to it will return NaN.']);
        newMarkerData = nan([size(eventTimes) 3]);
        relMarkerData = nan([size(eventTimes) 3]);
    end

    if strcmp(labels{j}(1),s)   % s markers
        eval(['s' upper(labels{j}(2)) lower(labels{j}(3:4)) ' = newMarkerData;']);
        eval(['s' upper(labels{j}(2)) lower(labels{j}(3:4)) 'Rel = relMarkerData;']);
    elseif strcmp(labels{j}(1),f)
        eval(['f' upper(labels{j}(2)) lower(labels{j}(3:4)) ' = newMarkerData;']);
        eval(['f' upper(labels{j}(2)) lower(labels{j}(3:4)) 'Rel = relMarkerData;']);
    else
        error('Marker labels have to begin with ''R'' or ''L''');
    end
end

% get angle data
if ~isempty(angleData)
    newAngleData = angleData.getDataAsTS({[s 'Limb'],[f 'Limb']});
    newAngleData = newAngleData.getSample(eventTimes,'closest');
    sAngle = newAngleData(:,:,1);
    fAngle = newAngleData(:,:,2);
else
    sAngle = nan(size(eventTimes,1),size(eventTimes,2),1);
    fAngle = nan(size(eventTimes,1),size(eventTimes,2),1);
end

%% Compute:
% find walking direction, y difference slow ankle marker from STO to SHS2
% TODO: would using SHS and STO work just as well?
direction = sign(diff(sAnk(:,4:5,2),1,2));
indsDirNans = find(isnan(direction));   % identify any NaN values
numNans = length(indsDirNans);          % number of NaN values
for miss = 1:numNans                    % for each missing value, ...
    % check only y-axis values for current stride (i.e., none of gait
    % events with '2' in the name since could be at or approaching a turn)
    hasVal = ~isnan(sAnk(indsDirNans(miss),1:4,2));
    % use two most disparate gait events in time to try to account for
    % noise in the ankle marker y-axis position during stance phase
    direction(indsDirNans(miss)) = sign(diff(sAnk(indsDirNans(miss), ...
        [find(hasVal,1) find(hasVal,1,'last')],2),1,2));
end
% find invalid measurements (0 or 1 non-NaN y-values so difference is 0)
% TODO: would it be best to simply leave the zeros since unclear?
indsDirZeros = find(direction == 0);
numZeros = length(indsDirZeros);
for inv = 1:numZeros                    % for each invalid measure, ...
    if indsDirZeros(inv) == 1           % if first stride is invalid, ...
        direction(1) = direction(2);    % set to be same as stride 2
    else                                % otherwise, ...
        % set invalid direction value to be previous stride direction value
        direction(indsDirZeros(inv)) = direction(indsDirZeros(inv)-1);
    end
end

% if find(indsDirZeros,1) == 1        % if first stride is invalid, ...
%     direction(1) = direction(2);    % set to be same as stride 2
%     indsDirZeros = direction == 0;  % remove stride 1 from invalid list
% end
% set invalid direction values to previous stride direction value
% direction(indsDirZeros) = direction([indsDirZeros(2:end); false]);

hipPos3D = 0.5 * (sHip + fHip);
hipPos3DRel = 0.5 * (sHipRel + fHipRel);    % just for check, should be all zeros
hipPosFwd = hipPos3D(:,:,2);    % y-axis component
% hipPos= mean([sHip(indSHS,2) fHip(indSHS,2)]);
hipPosSHS = hipPosFwd(:,1);
hipPosAvg_forFast = mean(nanmean(hipPosFwd(:,1:6))); % average Hip Position from SHS to STO2
hipPosAvg_forSlow = mean(nanmean(hipPosFwd(:,3:8))); % average Hip Position from SHS to STO2

%rotate coordinates to be aligned wiht walking dierection
%sRotation = calcangle(sAnk(indSHS2,1:2),sAnk(indSTO,1:2),[sAnk(indSTO,1)-100*direction sAnk(indSTO,2)])-90;
%fRotation = calcangle(fAnk(indFHS,1:2),fAnk(indFTO,1:2),[fAnk(indFTO,1)-100*direction fAnk(indFTO,2)])-90;

%avgRotation = (sRotation+fRotation)./2;

%rotationMatrix = [cosd(avgRotation) -sind(avgRotation) 0; sind(avgRotation) cosd(avgRotation) 0; 0 0 1];
%sAnk(indSHS:indFTO2,:) = (rotationMatrix*sAnk(indSHS:indFTO2,:)')';
%fAnk(indSHS:indFTO2,:) = (rotationMatrix*fAnk(indSHS:indFTO2,:)')';
%sHip(indSHS:indFTO2,:) = (rotationMatrix*sHip(indSHS:indFTO2,:)')';
%fHip(indSHS:indFTO2,:) = (rotationMatrix*fHip(indSHS:indFTO2,:)')';

%NEED TO ROTATE

hipPos2D = hipPos3D(:,:,1:2);
%Compute ankle position relative to average hip position
sAnkFwd = sAnk(:,:,2) - hipPosFwd;
fAnkFwd = fAnk(:,:,2) - hipPosFwd;
sAnk2D = sAnk(:,:,1:2) - hipPos2D;
fAnk2D = fAnk(:,:,1:2) - hipPos2D;
sAnk_fromAvgHip = sAnk(:,:,2) - hipPosAvg_forSlow; % y positon of slow ankle corrected by average hip postion
fAnk_fromAvgHip = fAnk(:,:,2) - hipPosAvg_forFast; % y positon of fast ankle corrected by average hip postion
% Set all steps to have the same slope (a negative slope during stance phase is assumed)
%WHAT IS THIS FOR? WHAT PROBLEMS DOES IT SOLVE THAT THE PREVIOUS ROTATION
%DOESN'T?

aux = sign(diff(sAnk(:,[3,5],2),1,2)); %Checks for: sAnk(indSHS2,2)<sAnk(indFHS,2). Doesn't use HIP to avoid HIP fluctuation issues.
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

aux = sign(sAngle(:,1)); %Checks for sAngle(indSHS)<0
sAngle = bsxfun(@times,sAngle,aux);
fAngle = bsxfun(@times,fAngle,aux);

end

