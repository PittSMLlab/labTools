function [rotatedMarkerData,sAnkFwd,fAnkFwd,sAnk2D,fAnk2D,sAngle,fAngle,direction,hipPos]=getKinematicData(eventTimes,markerData,angleData,s)
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


refMarker3D=.5*sum(markerData.getOrientedData({'LHIP','RHIP'}),2); %midHip

%Ref axis option 1 (ideal): Body reference
refAxis=squeeze(diff(markerData.getOrientedData({'LHIP','RHIP'}),1,2)); %L to R

%Ref axis option 2 (assuming the subject walks only along the y axis):
refAxis=refAxis*[1,0,0]' *[1,0,0]; %Projecting along x direction, this is equivalent to just determining forward/backward sign
rotatedMarkerData=markerData.translate(-squeeze(refMarker3D)).alignRotate(refAxis,[0,0,1]);

%% Get relevant sample of data (using interpolation)
if strcmp(s,'L')
    f='R';
elseif strcmp(s,'R')
    f='L';
else
    error();
end 
orientation=markerData.orientation;
directions={orientation.sideAxis,orientation.foreaftAxis,orientation.updownAxis};
signs=[orientation.sideSign,orientation.foreaftSign,orientation.updownSign];
markers={'HIP','ANK','TOE'};
labels={};
legs={s,f};
legs2={'s','f'};
for j=1:length(markers)
    for leg=1:2
        labels{end+1}=[legs{leg} markers{j}]; %Odd are s, Even are f
    end
end
[bool,idx]=isaLabelPrefix(markerData,labels);
if ~all(bool)
    warning(['Markers are missing: ' cell2mat(strcat(labels(~bool),','))])
end
for j=1:length(labels) %Assign each marker data to a x3 str
    aux=markerData.getDataAsTS(markerData.addLabelSuffix(labels{j}));
    if ~isempty(aux.Data)
        newMarkerData=aux.getSample(eventTimes); %Linear(!) interpolation
        aux=rotatedMarkerData.getDataAsTS(rotatedMarkerData.addLabelSuffix(labels{j}));
        relMarkerData=aux.getSample(eventTimes); %Linear(!) interpolation
    else %Missing marker
        warning(['Marker ' labels{j} ' is missing. All references to it will return NaN.']);
        newMarkerData=nan([size(eventTimes),3]);
        relMarkerData=nan([size(eventTimes),3]);
    end
    
    if strcmp(labels{j}(1),s) %s markers
    	eval(['s' upper(labels{j}(2)) lower(labels{j}(3:4)) '=newMarkerData;']);
        eval(['s' upper(labels{j}(2)) lower(labels{j}(3:4)) 'Rel=relMarkerData;']);
    elseif strcmp(labels{j}(1),f)
        eval(['f' upper(labels{j}(2)) lower(labels{j}(3:4)) '=newMarkerData;']);
        eval(['f' upper(labels{j}(2)) lower(labels{j}(3:4)) 'Rel=relMarkerData;']);
    else
       error('Marker labels have to begin with ''R'' or ''L'''); 
    end
end 
    
%get angle data
if ~isempty(angleData)
    newAngleData=angleData.getDataAsTS({[s,'Limb'],[f,'Limb']});
    newAngleData=newAngleData.getSample(eventTimes);
    sAngle=newAngleData(:,:,1);
    fAngle=newAngleData(:,:,2);
else
    sAngle=nan(size(eventTimes,1),size(eventTimes,2),1);
    fAngle=nan(size(eventTimes,1),size(eventTimes,2),1);
end
    
%% Compute:
%find walking direction
direction=sign(diff(sAnk(:,4:5,2),1,2));


hipPos3D=.5*(sHip+fHip);
hipPos3DRel=.5*(sHipRel+fHipRel); %Just for check, should be all zeros
hipPosFwd=hipPos3D(:,:,2);%Y-axis component    
%hipPos= mean([sHip(indSHS,2) fHip(indSHS,2)]);
hipPos=hipPosFwd(:,1);

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

hipPos2D=hipPos3D(:,:,1:2);
%Compute ankle position relative to average hip position
sAnkFwd=sAnk(:,:,2)-hipPosFwd;
fAnkFwd=fAnk(:,:,2)-hipPosFwd;
sAnk2D=sAnk(:,:,1:2)-hipPos2D;
fAnk2D=fAnk(:,:,1:2)-hipPos2D;
% Set all steps to have the same slope (a negative slope during stance phase is assumed)
%WHAT IS THIS FOR? WHAT PROBLEMS DOES IT SOLVE THAT THE PREVIOUS ROTATION
%DOESN'T?
aux=sign(diff(sAnkFwd(:,[2,5]),1,2)); %Checks for: sAnk(indSHS2,2)<sAnk(indSTO,2)
sAnkFwd=bsxfun(@times,sAnkFwd,aux);
fAnkFwd=bsxfun(@times,fAnkFwd,aux);
sAnk2D=bsxfun(@times,sAnk2D,aux);
fAnk2D=bsxfun(@times,fAnk2D,aux);

%Alternative definition: should be equivalent, since we reference to midHip
%when doing the rotation. Only difference may be in sign of walking, since
%its computed slighltly different. Should not cause issues as differences
%may only ocurr when subject is turning around, which is a bad stride
%anyway
sAnkFwd=sAnkRel(:,:,2);
fAnkFwd=fAnkRel(:,:,2);
sAnk2D=sAnkRel(:,:,1:2);
fAnk2D=fAnkRel(:,:,1:2);

aux=sign(sAngle(:,1)); %Checks for sAngle(indSHS)<0
sAngle=bsxfun(@times,sAngle,aux);
fAngle=bsxfun(@times,fAngle,aux);

end