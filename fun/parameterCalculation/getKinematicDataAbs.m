function [rotatedMarkerData, sAnkFwd, fAnkFwd, sAnk2D, fAnk2D, ...
    sAngle, fAngle, direction, hipPosSHS, ...
    sAnk_fromAvgHip, fAnk_fromAvgHip] = ...
    getKinematicDataAbs(eventTimes, markerData, angleData, s)
%GETKINEMATICDATAABS Extract marker data in absolute lab-frame coordinates.
%
%   Like GETKINEMATICDATA but uses an absolute lab-frame reference
% (origin) rather than a hip-centered coordinate frame. Ankle
% positions in sAnkFwd and sAnk2D are therefore absolute rather than
% relative to the hip. The reference axis for rotation is derived
% from the ankle markers instead of the hip markers.
%
% Inputs:
%   eventTimes  - (numStrides x numEvents) array of gait event times
%   markerData  - orientedLabTimeSeries of 3D marker trajectories
%   angleData   - labTimeSeries of limb angles (or empty)
%   s           - (char) slow-leg identifier: 'L' or 'R'
%
% Outputs:
%   rotatedMarkerData - markerData rotated to lab-frame orientation
%   sAnkFwd           - (numStrides x numEvents) slow ankle fore-aft
%                       position in absolute lab frame
%   fAnkFwd           - (numStrides x numEvents) fast ankle fore-aft
%                       position in absolute lab frame
%   sAnk2D            - (numStrides x numEvents x 2) slow ankle 2D
%                       position in absolute lab frame
%   fAnk2D            - (numStrides x numEvents x 2) fast ankle 2D
%                       position in absolute lab frame
%   sAngle            - (numStrides x numEvents) slow leg limb angles,
%                       sign-corrected so SHS value is positive
%   fAngle            - (numStrides x numEvents) fast leg limb angles,
%                       sign-corrected to match sAngle sign
%   direction         - (numStrides x 1) walking direction (+1 or -1)
%   hipPosSHS         - (numStrides x 1) hip position at slow heel
%                       strike
%   sAnk_fromAvgHip   - slow ankle fore-aft position relative to mean
%                       hip
%   fAnk_fromAvgHip   - fast ankle fore-aft position relative to mean
%                       hip
%
% Toolbox Dependencies:
%   None
%
% See also EXTRACTKINEMATICDATAATEVENTS, GETKINEMATICDATA,
%   COMPUTESPATIALPARAMETERS.

arguments
    eventTimes  (:,:) double
    markerData
    angleData
    s           (1,:) char
end

%% Rotate Marker Data to Absolute Lab Frame
refMarker3D = [0 0 0];  % absolute lab reference

% define reference axis:
% option 1 (ideal): body reference (vector from left to right hip)
% compute difference between LHIP and RHIP (i.e., RHIP - LHIP) for x, y, z
refAxis = squeeze( ...
    diff(markerData.getOrientedData({'LANK', 'RANK'}), 1, 2)); % L to R

% Ref axis option 2 (assuming the subject walks only along the y axis):
% option 2: assuming the subject walks primarily along the y-axis,
% project onto the x-direction to determine forward/backward motion
% merely makes the y and z columns zeros and leaves the x column as is
% projecting along x direction — equivalent to determining the
% forward/backward sign
refAxis = refAxis * [1 0 0]' * [1 0 0];

% align marker data by translating to the reference marker (origin)
% and rotating so that the reference axis aligns with the vertical axis
% call to 'alignRotate' appears equivalent to swapping the signs of the x
% and y columns (but not z) of the output from 'translate'
rotatedMarkerData = markerData.translate(-squeeze(refMarker3D)) ...
    .alignRotate(refAxis, [0 0 1]);

%% Extract Kinematic Data at Event Times
[sAnk, fAnk, sAngle, fAngle, direction, hipPos3D, hipPosSHS, ...
    sAnk_fromAvgHip, fAnk_fromAvgHip] = ...
    extractKinematicDataAtEvents(eventTimes, markerData, ...
    rotatedMarkerData, angleData, s);

%% Compute Absolute Ankle Positions
%rotate coordinates to be aligned with walking direction
%sRotation = calcangle(sAnk(indSHS2,1:2),sAnk(indSTO,1:2),[sAnk(indSTO,1)-100*direction sAnk(indSTO,2)])-90;
%fRotation = calcangle(fAnk(indFHS,1:2),fAnk(indFTO,1:2),[fAnk(indFTO,1)-100*direction fAnk(indFTO,2)])-90;

%avgRotation = (sRotation+fRotation)./2;

%rotationMatrix = [cosd(avgRotation) -sind(avgRotation) 0; sind(avgRotation) cosd(avgRotation) 0; 0 0 1];
%sAnk(indSHS:indFTO2,:) = (rotationMatrix*sAnk(indSHS:indFTO2,:)')';
%fAnk(indSHS:indFTO2,:) = (rotationMatrix*fAnk(indSHS:indFTO2,:)')';
%sHip(indSHS:indFTO2,:) = (rotationMatrix*sHip(indSHS:indFTO2,:)')';
%fHip(indSHS:indFTO2,:) = (rotationMatrix*fHip(indSHS:indFTO2,:)')';

% NEED TO ROTATE
hipPos2D = hipPos3D(:, :, 1:2);
% compute ankle positions
sAnkFwd = sAnk(:, :, 2);
fAnkFwd = fAnk(:, :, 2);
sAnk2D  = sAnk(:, :, 1:2);
fAnk2D  = fAnk(:, :, 1:2);

% set all steps to have the same slope (a negative slope during
% stance phase is assumed)
%WHAT IS THIS FOR? WHAT PROBLEMS DOES IT SOLVE THAT THE PREVIOUS ROTATION
%DOESN'T?

% adjust stride data to ensure consistent slope during stance phase
% checks for: sAnk(indSHS2,2) < sAnk(indSTO,2)
% (doesn't use HIP to avoid HIP fluctuation issues)
aux = sign(diff(sAnk(:, [4 5], 2), 1, 2));
sAnkFwd = bsxfun(@times, sAnkFwd, aux);
fAnkFwd = bsxfun(@times, fAnkFwd, aux);
sAnk2D  = bsxfun(@times, sAnk2D, aux);
fAnk2D  = bsxfun(@times, fAnk2D, aux);

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

end

