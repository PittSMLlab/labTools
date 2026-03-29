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
    LhipPos2D = this.markerData.getDataAsVector( ...
        {['LHIP' orientation.foreaftAxis], ...
        ['LHIP' orientation.updownAxis]});
    LhipPos2D = [orientation.foreaftSign * LhipPos2D(:, 1), ...
        orientation.updownSign * LhipPos2D(:, 2)];
    RhipPos2D = this.markerData.getDataAsVector( ...
        {['RHIP' orientation.foreaftAxis], ...
        ['RHIP' orientation.updownAxis]});
    RhipPos2D = [orientation.foreaftSign * RhipPos2D(:, 1), ...
        orientation.updownSign * RhipPos2D(:, 2)];
else
    warning(['There are missing hip markers in ' file ...
        '. Unable to calculate limb angles.']);
    angleData = [];
    return;
end

% ---- Ankle ----------------------------------------------------------
if this.markerData.isaLabel('RANKx') && this.markerData.isaLabel('LANKx')
    LankPos2D = this.markerData.getDataAsVector( ...
        {['LANK' orientation.foreaftAxis], ...
        ['LANK' orientation.updownAxis]});
    LankPos2D = [orientation.foreaftSign * LankPos2D(:, 1), ...
        orientation.updownSign * LankPos2D(:, 2)];
    RankPos2D = this.markerData.getDataAsVector( ...
        {['RANK' orientation.foreaftAxis], ...
        ['RANK' orientation.updownAxis]});
    RankPos2D = [orientation.foreaftSign * RankPos2D(:, 1), ...
        orientation.updownSign * RankPos2D(:, 2)];
else
    warning(['There are missing ankle markers in ' file ...
        '. Unable to calculate limb angles.']);
    % angleData = [];
    return;
end

% ---- Knee -----------------------------------------------------------
if this.markerData.isaLabel('RKNEx') && this.markerData.isaLabel('LKNEx')
    LkneePos2D = this.markerData.getDataAsVector( ...
        {['LKNE' orientation.foreaftAxis], ...
        ['LKNE' orientation.updownAxis]});
    LkneePos2D = [orientation.foreaftSign * LkneePos2D(:, 1), ...
        orientation.updownSign * LkneePos2D(:, 2)];
    RkneePos2D = this.markerData.getDataAsVector( ...
        {['RKNE' orientation.foreaftAxis], ...
        ['RKNE' orientation.updownAxis]});
    RkneePos2D = [orientation.foreaftSign * RkneePos2D(:, 1), ...
        orientation.updownSign * RkneePos2D(:, 2)];
elseif this.markerData.isaLabel('RKNEEx') && ...
        this.markerData.isaLabel('LKNEEx')
    LkneePos2D = this.markerData.getDataAsVector( ...
        {['LKNEE' orientation.foreaftAxis], ...
        ['LKNEE' orientation.updownAxis]});
    LkneePos2D = [orientation.foreaftSign * LkneePos2D(:, 1), ...
        orientation.updownSign * LkneePos2D(:, 2)];
    RkneePos2D = this.markerData.getDataAsVector( ...
        {['RKNEE' orientation.foreaftAxis], ...
        ['RKNEE' orientation.updownAxis]});
    RkneePos2D = [orientation.foreaftSign * RkneePos2D(:, 1), ...
        orientation.updownSign * RkneePos2D(:, 2)];
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
    LtoePos2D = this.markerData.getDataAsVector( ...
        {['LTOE' orientation.foreaftAxis], ...
        ['LTOE' orientation.updownAxis]});
    LtoePos2D = [orientation.foreaftSign * LtoePos2D(:, 1), ...
        orientation.updownSign * LtoePos2D(:, 2)];
    RtoePos2D = this.markerData.getDataAsVector( ...
        {['RTOE' orientation.foreaftAxis], ...
        ['RTOE' orientation.updownAxis]});
    RtoePos2D = [orientation.foreaftSign * RtoePos2D(:, 1), ...
        orientation.updownSign * RtoePos2D(:, 2)];
else
    warning(['There are missing toe markers in ' file ...
        '. Unable to calculate limb angles.']);
    % keyboard
    % angleData = [];
    return;
end

% ---- Heel -----------------------------------------------------------
if this.markerData.isaLabel('RHEEx') && this.markerData.isaLabel('LHEEx')
    LheelPos2D = this.markerData.getDataAsVector( ...
        {['LHEE' orientation.foreaftAxis], ...
        ['LHEE' orientation.updownAxis]});
    LheelPos2D = [orientation.foreaftSign * LheelPos2D(:, 1), ...
        orientation.updownSign * LheelPos2D(:, 2)];
    RheelPos2D = this.markerData.getDataAsVector( ...
        {['RHEE' orientation.foreaftAxis], ...
        ['RHEE' orientation.updownAxis]});
    RheelPos2D = [orientation.foreaftSign * RheelPos2D(:, 1), ...
        orientation.updownSign * RheelPos2D(:, 2)];
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
RhipAngVel        = diff(RhipAngle) * fs;
RhipAngVel(end+1) = RhipAngVel(end);   % extend to match signal length
LhipAngVel        = diff(LhipAngle) * fs;
LhipAngVel(end+1) = LhipAngVel(end);
RhipAngle   = RThighAngle;
LhipAngle   = LThighAngle;

% Knee: supplementary angle derived from thigh and shank segment angles
RkneeAngVel        = diff(RkneeAngle) * fs;
RkneeAngVel(end+1) = RkneeAngVel(end);
LkneeAngVel        = diff(LkneeAngle) * fs;
LkneeAngVel(end+1) = LkneeAngVel(end);
RkneeAngle  = 180 - ((90 - RThighAngle) + (90 + RShankAngle));
LkneeAngle  = 180 - ((90 - LThighAngle) + (90 + LShankAngle));

% Ankle: foot deviation from shank alignment
RankAngVel        = diff(RankAngle) * fs;
RankAngVel(end+1) = RankAngVel(end);
LankAngVel        = diff(LankAngle) * fs;
LankAngVel(end+1) = LankAngVel(end);
RankAngle   = 90 - (RShankAngle + 90 + RfootAngle);
LankAngle   = 90 - (LShankAngle + 90 + LfootAngle);

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

