function angleData = calcLimbAngles(this)
% calcLimbAngles  Calculates limb and joint angles from marker data.
%
%   Computes sagittal-plane limb, thigh, shank, foot, hip, knee, and
% ankle angles and their angular velocities for both legs from the 2D
% marker positions in this.markerData. Angles are defined as follows:
%   - Limb angle:  between the vertical and the line connecting the
%                  hip to the ankle
%   - Hip angle:   thigh angle with respect to vertical (assumes
%                  trunk is vertical)
%   - Knee angle:  between the thigh and shank segments
%   - Ankle angle: between the shank and foot segments
%
%   Inputs:
%     this - labData object containing markerData with hip, ankle,
%            knee, toe, and heel marker trajectories
%
%   Outputs:
%     angleData - labTimeSeries with 20 channels of angle and angular
%                 velocity time series for both legs (degrees, deg/s)
%
%   Toolbox Dependencies:
%     None
%
%   See also: labTimeSeries, orientationInfo, calcangle, labData/process
%
%   Created:  2014-05-14  HMH
%   Modified: Adapted by Digna de Kam to compute individual joint angles

arguments
    this (1,1) labData
end

%% Named Constants
% Horizontal offset (in marker data units, typically mm) used to define
% the reference direction for limb angle calculation via calcangle.
% The reference point is placed to the right of the hip along the
% fore-aft axis, so the resulting angle is measured from the horizontal,
% and 90 degrees is subtracted to convert to angle from the vertical.
limbAngleRefOffset = 100;

%% Setup
% disp('TEST: computing limb angles');
fs   = 1 / this.markerData.sampPeriod;
file = getSimpleFileName(this.metaData.rawDataFilename); % for warnings

% Angular velocity helper: forward-differentiates an angle signal,
% extending the result by one sample (repeating the last value) to
% preserve the original signal length after diff reduces it by one
angVel = @(angle) [diff(angle); angle(end) - angle(end-1)] * fs;

% Get orientation axes and signs from marker data
if isempty(this.markerData.orientation)
    warning('Assuming default orientation of axes for marker data.');
    orientation = orientationInfo([0, 0, 0], 'x', 'y', 'z', 1, 1, 1);
else
    orientation = this.markerData.orientation;
end

%% Retrieve Marker Positions

% ---- Hip ------------------------------------------------------------
if this.markerData.isaLabel('RHIPx') && this.markerData.isaLabel('LHIPx')
    RhipPos2D = getMarker2D(this.markerData, 'RHIP', orientation);
    LhipPos2D = getMarker2D(this.markerData, 'LHIP', orientation);
else
    warning(['There are missing hip markers in ' file ...
        '. Unable to calculate limb angles.']);
    angleData = [];
    return;
end

% ---- Ankle ----------------------------------------------------------
if this.markerData.isaLabel('RANKx') && this.markerData.isaLabel('LANKx')
    RankPos2D = getMarker2D(this.markerData, 'RANK', orientation);
    LankPos2D = getMarker2D(this.markerData, 'LANK', orientation);
else
    warning(['There are missing ankle markers in ' file ...
        '. Unable to calculate limb angles.']);
    % angleData = [];
    return;
end

% ---- Knee (two label variants: 'KNE' and 'KNEE') --------------------
if this.markerData.isaLabel('RKNEx') && this.markerData.isaLabel('LKNEx')
    RkneePos2D = getMarker2D(this.markerData, 'RKNE', orientation);
    LkneePos2D = getMarker2D(this.markerData, 'LKNE', orientation);
elseif this.markerData.isaLabel('RKNEEx') && ...
        this.markerData.isaLabel('LKNEEx')
    RkneePos2D = getMarker2D(this.markerData, 'RKNEE', orientation);
    LkneePos2D = getMarker2D(this.markerData, 'LKNEE', orientation);
else
    warning(['There are missing knee markers in ' file ...
        '. Unable to calculate limb angles.']);
    % % Marcela temporary fix
    % temp = this.markerData.getDataAsVector( ...
    %     {['RHIP' orientation.foreaftAxis], ...
    %     ['RHIP' orientation.updownAxis]});
    % LkneePos2D = nan * ones(size(temp));
    % RkneePos2D = nan * ones(size(temp));
    % % angleData = [];
    return;
end

% ---- Toe ------------------------------------------------------------
if this.markerData.isaLabel('RTOEx') && this.markerData.isaLabel('LTOEx')
    RtoePos2D = getMarker2D(this.markerData, 'RTOE', orientation);
    LtoePos2D = getMarker2D(this.markerData, 'LTOE', orientation);
else
    warning(['There are missing toe markers in ' file ...
        '. Unable to calculate limb angles.']);
    % keyboard
    % angleData = [];
    return;
end

% ---- Heel -----------------------------------------------------------
if this.markerData.isaLabel('RHEEx') && this.markerData.isaLabel('LHEEx')
    RheelPos2D = getMarker2D(this.markerData, 'RHEE', orientation);
    LheelPos2D = getMarker2D(this.markerData, 'LHEE', orientation);
else
    LheelPos2D = nan(size(LtoePos2D));
    RheelPos2D = nan(size(RtoePos2D));
    warning(['There are missing heel markers in ' file ...
        '. Unable to calculate limb angles.']);
    % keyboard
    % angleData = [];
    return;
end

%% Calculate Angles
% ---- Limb angles ----------------------------------------------------
% Angle of the hip-to-ankle segment with the horizontal; 90 degrees is
% subtracted to convert to angle measured from the vertical
RLimbAngle = calcangle([RankPos2D(:, 1),  RankPos2D(:, 2)], ...
    [RhipPos2D(:, 1),  RhipPos2D(:, 2)], ...
    [RhipPos2D(:, 1) + limbAngleRefOffset,  RhipPos2D(:, 2)]) - 90;
LLimbAngle = calcangle([LankPos2D(:, 1),  LankPos2D(:, 2)], ...
    [LhipPos2D(:, 1),  LhipPos2D(:, 2)], ...
    [LhipPos2D(:, 1) + limbAngleRefOffset,  LhipPos2D(:, 2)]) - 90;

% Commented-out alternative using the hip-knee segment
% RhipAngle = calcangle([RkneePos2D(:, 1),  RkneePos2D(:, 2)], ...
%     [RhipPos2D(:, 1),   RhipPos2D(:, 2)], ...
%     [RhipPos2D(:, 1) + limbAngleRefOffset,  RhipPos2D(:, 2)]) - 90;
% LhipAngle = calcangle([LkneePos2D(:, 1),  LkneePos2D(:, 2)], ...
%     [LhipPos2D(:, 1),   LhipPos2D(:, 2)], ...
%     [LhipPos2D(:, 1) + limbAngleRefOffset,  LhipPos2D(:, 2)]) - 90;

% ---- Segment angles (thigh, shank, foot) ----------------------------
RThighAngle = atand((RhipPos2D(:, 1) - RkneePos2D(:, 1)) ./ ...
    (RhipPos2D(:, 2) - RkneePos2D(:, 2)));
LThighAngle = atand((LhipPos2D(:, 1) - LkneePos2D(:, 1)) ./ ...
    (LhipPos2D(:, 2) - LkneePos2D(:, 2)));

RShankAngle = atand((RkneePos2D(:, 1) - RankPos2D(:, 1)) ./ ...
    (RkneePos2D(:, 2) - RankPos2D(:, 2)));
LShankAngle = atand((LkneePos2D(:, 1) - LankPos2D(:, 1)) ./ ...
    (LkneePos2D(:, 2) - LankPos2D(:, 2)));

RfootAngle = atand((RtoePos2D(:, 2) - RheelPos2D(:, 2)) ./ ...
    (RtoePos2D(:, 1) - RheelPos2D(:, 1)));
LfootAngle = atand((LtoePos2D(:, 2) - LheelPos2D(:, 2)) ./ ...
    (LtoePos2D(:, 1) - LheelPos2D(:, 1)));

% ---- Joint angles and angular velocities ----------------------------
% Hip: thigh angle from vertical, assuming trunk is vertical
RhipAngle   = RThighAngle;
LhipAngle   = LThighAngle;
RhipAngVel  = angVel(RhipAngle);
LhipAngVel  = angVel(LhipAngle);

% Knee: supplementary angle derived from thigh and shank segment angles
RkneeAngle  = 180 - ((90 - RThighAngle) + (90 + RShankAngle));
LkneeAngle  = 180 - ((90 - LThighAngle) + (90 + LShankAngle));
RkneeAngVel = angVel(RkneeAngle);
LkneeAngVel = angVel(LkneeAngle);

% Ankle: foot deviation from shank alignment
RankAngle   = 90 - (RShankAngle + 90 + RfootAngle);
LankAngle   = 90 - (LShankAngle + 90 + LfootAngle);
RankAngVel  = angVel(RankAngle);
LankAngVel  = angVel(LankAngle);

% keyboard
% Commented-out alternative joint angle calculations using calcangle
% and calcangle2; cosine-based approach had issues with negative values
% RhipAngle = calcangle([RkneePos2D(:, 1),  RkneePos2D(:, 2)], ...
%     [RhipPos2D(:, 1),   RhipPos2D(:, 2)], ...
%     [RhipPos2D(:, 1),   RhipPos2D(:, 2) + limbAngleRefOffset]) - 90;
% LhipAngle = calcangle([LkneePos2D(:, 1),  LkneePos2D(:, 2)], ...
%     [LhipPos2D(:, 1),   LhipPos2D(:, 2)], ...
%     [LhipPos2D(:, 1),   LhipPos2D(:, 2) + limbAngleRefOffset]) - 90;
%
% RkneeAngle = calcangle([RankPos2D(:, 1),   RankPos2D(:, 2)], ...
%     [RkneePos2D(:, 1),  RkneePos2D(:, 2)], ...
%     [RhipPos2D(:, 1),   RhipPos2D(:, 2)]) - 90;
% LkneeAngle = calcangle([LankPos2D(:, 1),   LankPos2D(:, 2)], ...
%     [LkneePos2D(:, 1),  LkneePos2D(:, 2)], ...
%     [LhipPos2D(:, 1),   LhipPos2D(:, 2)]) - 90;
%
% RankAngle = calcangle2([RkneePos2D(:, 1), RkneePos2D(:, 2)] - ...
%     [RankPos2D(:, 1),  RankPos2D(:, 2)], ...
%     [RtoePos2D(:, 1),  RtoePos2D(:, 2)] - ...
%     [RheelPos2D(:, 1), RheelPos2D(:, 2)]) - 90;
% LankAngle = calcangle2([LkneePos2D(:, 1), LkneePos2D(:, 2)] - ...
%     [LankPos2D(:, 1),  LankPos2D(:, 2)], ...
%     [LtoePos2D(:, 1),  LtoePos2D(:, 2)] - ...
%     [LheelPos2D(:, 1), LheelPos2D(:, 2)]) - 90;
% % keyboard

%% Construct Output
angleData = labTimeSeries( ...
    [RLimbAngle   LLimbAngle   RThighAngle  LThighAngle  ...
    RShankAngle  LShankAngle  RfootAngle   LfootAngle   ...
    RhipAngle    LhipAngle    RkneeAngle   LkneeAngle   ...
    RankAngle    LankAngle    RhipAngVel   LhipAngVel   ...
    RkneeAngVel  LkneeAngVel  RankAngVel   LankAngVel], ...
    this.markerData.Time(1), this.markerData.sampPeriod, ...
    {'RLimb',    'LLimb',    'RThigh',   'LThigh',   ...
    'RShank',   'LShank',   'RFoot',    'LFoot',    ...
    'Rhip',     'Lhip',     'Rknee',    'Lknee',    ...
    'Rank',     'Lank',     'RhipVel',  'LhipVel',  ...
    'RkneeVel', 'LkneeVel', 'RankVel',  'LankVel'});

end

% ============================================================
% ==================== Local Functions =======================
% ============================================================

function pos2D = getMarker2D(markerData, markerName, orientation)
% getMarker2D  Retrieves a single marker's signed 2D position.
%
%   Extracts the fore-aft and up-down position components for the
% named marker and applies the orientation sign conventions, returning
% a two-column matrix ready for angle computation.
%
%   Inputs:
%     markerData  - orientedLabTimeSeries containing marker trajectories
%     markerName  - String marker label prefix, e.g. 'RHIP', 'LANK'
%     orientation - orientationInfo object specifying axis names and signs
%
%   Outputs:
%     pos2D - Nx2 matrix of signed [foreaft, updown] positions

raw   = markerData.getDataAsVector( ...
    {[markerName orientation.foreaftAxis], ...
    [markerName orientation.updownAxis]});
pos2D = [orientation.foreaftSign * raw(:, 1), ...
    orientation.updownSign  * raw(:, 2)];

end

