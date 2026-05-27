function out = computeSpatialParameters(strideEvents, markerData, ...
    angleData, s)
%COMPUTESPATIALPARAMETERS Compute spatial parameters per stride.
%
%   Computes stride-by-stride spatial gait parameters and returns a
% parameterSeries object that can be concatenated with other parameter
% series objects (e.g., from computeTemporalParameters).
%
% Inputs:
%   strideEvents - struct of stride-level gait event times generated
%                  by calcParameters, with fields tSHS, tFTO, tFHS,
%                  tSTO, tSHS2, tFTO2, tFHS2, and tSTO2 (N-by-1
%                  vectors, in seconds)
%   markerData   - orientedLabTimeSeries containing kinematic marker
%                  data for the trial
%   angleData    - labTimeSeries containing limb angle data, or []
%                  if angle data is not available
%   s            - char specifying the slow-belt leg ('L' or 'R')
%
% Outputs:
%   out - parameterSeries object containing all spatial parameters
%
% Toolbox Dependencies:
%   None
%
% See also COMPUTETEMPORALPARAMETERS, COMPUTEFORCEPARAMETERS,
%   COMPUTEHREFLEXPARAMETERS, PARAMETERSERIES, CALCPARAMETERS.

arguments
    strideEvents (1,1) struct
    markerData
    angleData
    s            (1,:) char
end

%% Gait Stride Event Times
timeSHS  = strideEvents.tSHS;   % slow heel strike event times
timeFTO  = strideEvents.tFTO;   % fast toe off event times
timeFHS  = strideEvents.tFHS;   % fast heel strike event times
timeSTO  = strideEvents.tSTO;   % slow toe off event times
timeSHS2 = strideEvents.tSHS2;  % 2nd slow heel strike event times
timeFTO2 = strideEvents.tFTO2;  % 2nd fast toe off event times
timeFHS2 = strideEvents.tFHS2;  % 2nd fast heel strike event times
timeSTO2 = strideEvents.tSTO2;  % 2nd slow toe off event times
eventTimes = [timeSHS timeFTO timeFHS timeSTO ...
    timeSHS2 timeFTO2 timeFHS2 timeSTO2];
% Column indices into the eventTimes matrix (named constants)
SHS  = 1;  FTO  = 2;  FHS  = 3;  STO  = 4;
SHS2 = 5;  FTO2 = 6;  FHS2 = 7;  STO2 = 8;

%% Labels and Descriptions
aux = { ...
    'direction',                    '-1 if walking towards window, 1 if walking towards door (implemented for OG bias removal and coordinate rotation)'; ...
    'hipPos',                       'mid hip position at SHS. NOT: average hip pos of stride (should be nearly constant on treadmill - implemented for OG bias removal) (in mm)'; ...
    'stepLengthSlow',               'distance between ankle markers at SHS2 (in mm)'; ...
    'stepLengthFast',               'distance between ankle markers at FHS (in mm)'; ...
    'takeOffLengthSlow',            'sAnkle position, with respect to fAnkle at STO (in mm)'; ...
    'takeOffLengthFast',            'fAnkle position with respect to sAnkle at FTO (in mm)'; ...
    'alphaSlow',                    'ankle placement of slow leg at SHS2 (realtive to avg hip marker) (in mm)'; ...
    'alphaTemp',                    'ankle placement of slow leg at SHS (realtive to avg hip marker) (in mm)'; ...
    'alphaFast',                    'ankle placement of fast leg at FHS (in mm)'; ...
    'alphaDiff',                    'alphaFast-alphaSlow'; ...
    'alphaAsym',                    '(alphaFast-alphaSlow)/(SLf+SLs)'; ...
    'alphaAngSlow',                 'slow leg angle (hip to ankle with respect to vertical) at SHS2 (in deg)'; ...
    'alphaAngFast',                 'fast leg angle at FHS (in deg)'; ...
    'betaSlow',                     'ankle placement of slow leg at STO (relative avg hip marker) (in mm)'; ...
    'betaFast',                     'ankle placement of fast leg at FTO2 (in mm)'; ...
    'XSlow',                        'ankle postion of the slow leg @FHS (in mm)'; ...
    'XFast',                        'ankle position of Fast leg @SHS (in mm)'; ...
    'Xdiff',                        'Xdiff Fast - Slow'; ...
    'Xasym',                        'Xdiff/(SLf+SLs)'; ...
    'RFastPos',                     'Ratio of FTO/FHS'; ...
    'RSloWPos',                     'Ratio of STO/SHS'; ...
    'RFastPosSHS',                  'Ratio of fank@SHS/FHS'; ...
    'RSlowPosFHS',                  'Ratio of sank@FHS/SHS'; ...
    'betaAngSlow',                  'slow leg angle at STO (in deg)'; ...
    'betaAngFast',                  'fast leg angle at FTO (in deg)'; ...
    'stanceRangeSlow',              'alphaSlow - betaSlow (i.e. total distance covered by slow ankle relative to hip during stance) (in mm)'; ...
    'stanceRangeFast',              'alphaFast - betaFast (in mm)'; ...
    'stanceRangeAngSlow',           '|alphaAngSlow| + |betaAngSlow| (i.t total angle swept out by slow leg during stance) (in deg)'; ...
    'stanceRangeAngFast',           '|alphaAngFast| + |betaAngFast| (in deg)'; ...
    'swingRangeSlow',               'total distance covered by slow ankle marker realtive to hip from STO to SHS2 (in mm)'; ...
    'swingRangeFast',               'total distance covered by fast ankle marker realtive to hip from FTO to FHS (in mm)'; ...
    'omegaSlow',                    'angle between legs at SHS2 (in deg)'; ...
    'omegaFast',                    'angle between legs at FHS (in deg)'; ...
    'alphaRatioSlow',               'alphaSlow/(alphaSlow+alphaFast)'; ...
    'alphaRatioFast',               'alphaFast/(alphaSlow+alphaFast)'; ...
    'alphaDeltaSlow',               'slow leg angle at SHS2 - fast leg angle at FHS (in deg)'; ...
    'alphaDeltaFast',               'fast leg angle at FHS - slow leg angle at SHS (in deg)'; ...
    'stepLengthDiff',               'stepLengthFast-stepLengthSlow (in mm)'; ...
    'stepLengthDiff2D',             'two-dimensional version of stepLengthDiff (in mm)'; ...
    'stepLengthAsym',               'Step length difference (fast-slow), divided by sum'; ...
    'stepLengthAsym2D',             'two-dimensional step length difference (fast-slow), divided by sum'; ...
    'angularSpreadDiff',            'omegaFast-omegaSlow (in deg)'; ...
    'angularSpreadAsym',            'angular spread difference / sum'; ...
    'Sout',                         'Alpha difference (fast-slow), divided by alpha sum'; ...
    'Serror',                       'alphaRatioSlow-alphaRatioFast'; ...
    'SerrorOld',                    'alphaRatioFast/alphaRatioSlow'; ...
    'Sgoal',                        '(stanceRangeAngFast-stanceRangeAngSlow)/stanceRangeAngFast'; ...
    'angleOfOscillationAsym',       '(alhpaAngFast+betaAngFast)/2-(alphaAngSlow+betaAngSlow)/2'; ...
    'phaseShift',                   'parcent of stride that one angle trace is shifted with respect to the other for max correlation'; ...
    'phaseShiftPos',                'same as phaseShift, but uses ankle pos trace instead of angles'; ...
    'spatialContribution',          'DIFFERENCE of relative position of ankle markers at ipsi-lateral HS (i.e. slow ankle at SHS minus fast ankle at FHS), it ends up being = sAnk(SHS2)+sAnk(SHS)-2*fAnk(FHS)'; ...
    'stepTimeContribution',         'Average ankle speed relative to mid-hip, times step time difference'; ...
    'velocityContribution',         'Average step time times ankle speed (relative to hip) difference'; ...
    'netContribution',              'Sum of the previous three'; ...
    'spatialContributionP',         'Same as spatial contribution, in absolute (lab) reference frame (no Hip involved)'; ...
    'stepTimeContributionP',        'Same as stepTime, in absolute frame'; ...
    'velocityContributionP',        'Same as velocityContribution, in absolute frame'; ...
    'netContributionP',             'Sum of the previous three (should make it identical to netContribution, which is equal to stepLengthAsym)'; ...
    'spatialContributionPNorm',     'Same as spatial contribution, in absolute (lab) reference frame (no Hip involved)'; ...
    'stepTimeContributionPNorm',    'Same as stepTime, in absolute frame'; ...
    'velocityContributionPNorm',    'Same as velocityContribution, in absolute frame'; ...
    'netContributionPNorm',         'Sum of the previous three (should make it identical to netContribution, which is equal to stepLengthAsym)'; ...
    'spatialContributionPNorm2',    'Same as spatial contribution Pnorm, corrected for OG walking (using rotated markerdata)'; ...
    'stepTimeContributionPNorm2',   'Same as stepTime contribution Pnorm, corrected for OG walking (using rotated markerdata)'; ...
    'velocityContributionPNorm2',   'Same as velocityContribution Pnorm, corrected for OG walking (using rotated markerdata)'; ...
    'netContributionPNorm2',        'Sum of the previous three'; ...
    'spatialContributionAlt',       'Spatial contribution divided by stride time, to get velocity units instead of length units'; ...
    'stepTimeContributionAlt',      'Step time contribution divided by stride time, to get velocity units instead of length units'; ...
    'velocityContributionAlt',      'Velocity contribution divided by stride time, to get velocity units instead of length units'; ...
    'netContributionAlt',           'Net contribution divided by cadence, to get velocity units instead of length units'; ...
    'spatialContributionAltRatio',  'Spatial contribution divided by cadence times sum of ankle velocities during stance, so that we get dimensionless (comparable to *Norm2) '; ...
    'stepTimeContributionAltRatio', 'Step time contribution divided by cadence times sum of ankle velocities during stance'; ...
    'velocityContributionAltRatio', 'Velocity contribution divided by cadence times sum of ankle velocities during stance, which should be a function of RATIO only'; ...
    'netContributionAltRatio',      'Net contribution divided by cadence times sum of ankle velocities during stance'; ...
    'spatialContributionNorm2',     'spatialContribution/(stepLengthFast+stepLengthSlow)'; ...
    'stepTimeContributionNorm2',    'stepTimeContribution/(stepLengthFast+stepLengthSlow)'; ...
    'velocityContributionNorm2',    'velContribution/(stepLengthFast+stepLengthSlow)'; ...
    'netContributionNorm2',         'netContribution/(stepLengthFast+stepLengthSlow). With this normalization, netContributionNorm2 shoudl be IDENTICAL to stepLengthAsym'; ...
    'stepTimeIdealT',               'Ideal stepTimeContribution value (normalized to sum of step lengths) based on Tgoal parameter'; ...
    'spatialIdealT',                'Ideal spatialContribution value (normalized to sum of step length) equivalent to -(velocityContributionNorm2+stepTimeIdealT)'; ...
    'stepTimeErrorT',               'Difference between stepTimeContributionNorm2 and stepTimeIdealT'; ...
    'spatialErrorT',                'Difference between spatialContributionNorm2 and spatialIdealT'; ...
    'stepTimeIdealS',               'Ideal stepTimeContribution value (normalized to sum of step lengths) based on Sgoal parameter'; ...
    'spatialIdealS',                'Ideal spatialContribution value (normalized to sum of step length) equivalent to -(velocityContributionNorm2+stepTimeIdealS)'; ...
    'stepTimeErrorS',               'Difference between stepTimeContributionNorm2 and stepTimeIdealS'; ...
    'spatialErrorS',                'Difference between spatialContributionNorm2 and spatialIdealS'; ...
    'equivalentSpeed',              'Relative speed of hip to feet'; ...
    'singleStanceSpeedSlowAbs',     'Absolute speed of slow toe during contralateral swing'; ...
    'singleStanceSpeedFastAbs',     'Absolute speed of fast toe during contralateral swing'; ...
    'singleStanceSpeedSlowAbsANK',  'Absolute speed of slow ankle during contralateral swing'; ...
    'singleStanceSpeedFastAbsANK',  'Absolute speed of fast ankle during contralateral swing'; ...
    'singleStanceSpeedDiffAbsAnk',  'Absolute speed of difference between fast and slow ankle during contralateral swing'; ...
    'stepSpeedSlow',                'Ankle relative to hip, from iHS to cHS'; ...
    'stepSpeedFast',                'Ankle relative to hip, from iHS to cHS'; ...
    'stepSpeedAvg',                 'Average speed of the ankle relative to the hip between slow and fast leg'; ...
    'stanceSpeedSlow',              'Ankle relative to hip, during ipsilateral stance'; ...
    'stanceSpeedFast',              'Ankle relative to hip, during ipsilateral stance'; ...
    'alphaTemp_fromAvgHip',         'Ankle placement of slow leg at SHS (realtive to avg hip marker and avg hip postion during time) (in mm)'; ...
    'alphaFast_fromAvgHip',         'Ankle placement of fast leg at FHS (realtive to avg hip marker and avg hip postion during time) (in mm)'; ...
    'alphaSlow_fromAvgHip',         'Ankle placement of slow leg at SHS2 (realtive to avg hip marker and avg hip postion during time) (in mm)'; ...
    'xTemp_fromAvgHip',             'Ankle placement of fast leg at SHS (realtive to avg hip marker and avg hip postion during time) (in mm)'; ...
    'xFast_fromAvgHip',             'Ankle placement of slow leg at FHS (realtive to avg hip marker and avg hip postion during time) (in mm)'; ...
    'xSlow_fromAvgHip',             'Ankle placement of fast leg at SHS2 (realtive to avg hip marker and avg hip postion during time) (in mm)'; ...
    'velocitySlow'                  'Velocity of  slow foot relative to hip, should be close to actual belt speed in TM trials'; ...
    'velocityFast'                  'Velocity of  fast foot relative to hip, should be close to actual belt speed in TM trials'; ...
    'velocityAltContribution'       'Alternative velocity contribution, which subtracts belt speeds as estimated by singleStanceSpeedFastAbs and SlowAbs (in mm)'; ...
    'velocityAltContributionAlt'    'velocityAltContribution, normalized by stride time'; ...
    'velocityAltContributionNorm2'  'velocityAltContribution, normalized by sum of step lengths'; ...
    'velocityAltContributionP'      'velocityAltContribtuion using absolute lab reference (mm)'; ...
    'velocityAltContributionPNorm'  'velocityAltContributionP, normalized to sum of step lengths'; ...
    'singleStanceSpeedSlow',        'Single stance speed for ankle relative to the hip for the slow leg during contralateral swing'; ...
    'singleStanceSpeedFast',        'Single stance speed for ankle relative to the hip for the fast leg during contralateral swing'; ...
    'singleStanceSpeedAvg',         'Single stance speed for ankle relative to the hip averaged accross the legs'; ...
    'singleStanceSpeedDiff',        'Single stance speed difference, fast single stance speed minus slow single stance speed (ankle relative to the hip)'; ...
    % 'avgRotation',                  'Angle that the coordinates were rotated by';...
    };

paramLabels = aux(:, 1);
description = aux(:, 2);

%% Detect Markers at the Origin and Set Data to NaN
[dd, ll] = markerData.getOrientedData();
dd = permute(dd, [1 3 2]);
ee = all(dd == 0, 2);
if any(ee(:))
    msg = ['Markers were reconstructed at the origin. Setting ' ...
        'to NaN for spatial parameter computation.'];
    for ii = 1:size(ee, 3)
        if any(ee(:, 1, ii)) && ...
                sum(ee(:, 1, ii)) * markerData.sampPeriod > 1
            msg = [msg ' ' ll{ii} ' was at origin for ' ...
                num2str(sum(ee(:, 1, ii)) * markerData.sampPeriod) 's.'];
        end
    end
    warning(msg);
end

ee = repmat(ee, 1, 3, 1);
markerData.Data(ee) = NaN;
dd = markerData.getOrientedData();
dd = permute(dd, [1 3 2]);
ee = all(dd == 0, 2);
if any(ee(:))
    error('Setting markers at the origin to NaN did not work.');
end

%% Get Rotated Kinematic Data
[rotatedMarkerData, sAnkFwd, fAnkFwd, sAnk2D, fAnk2D, sAngle, fAngle, ...
    direction, hipPos, sAnk_fromAvgHip, fAnk_fromAvgHip] = ...
    getKinematicData(eventTimes, markerData, angleData, s);
[rotatedMarkerDataAbs, sAnkFwdAbs, fAnkFwdAbs, sAnk2DAbs, fAnk2DAbs, ...
    sAngleAbs, fAngleAbs, directionAbs, hipPosSHSAbs, ...
    sAnk_fromAvgHipAbs, fAnk_fromAvgHipAbs] = ...
    getKinematicDataAbs(eventTimes, markerData, angleData, s);

%% Compute Intralimb Spatial Parameters
if strcmp(s, 'L')           % if slow leg is left, ...
    f = 'R';                % fast is right
elseif strcmp(s, 'R')       % if slow leg is right, ...
    f = 'L';
else                        % otherwise, invalid leg ID
    error('Invalid slow leg input argument, must be ''R'' or ''L''.');
end

% Step lengths (1D).
% If sAnkFwd and fAnkFwd are measured with respect to the same
% reference, this equals the difference of the marker positions.
stepLengthSlow    = sAnkFwd(:, SHS2) - fAnkFwd(:, SHS2);
stepLengthFast    = fAnkFwd(:, FHS)  - sAnkFwd(:, FHS);
takeOffLengthSlow = sAnkFwd(:, STO)  - fAnkFwd(:, STO);
takeOffLengthFast = fAnkFwd(:, FTO)  - sAnkFwd(:, FTO);

% Alternative computation that does not use the HIP marker, so HIP
% marker loss does not affect the result. Since HIP is used as a
% reference, its absence generates NaN values downstream. Walking
% direction is instead determined from the left-to-right ankle vector.
stepLengthSlow    = sAnkFwdAbs(:, SHS2) - fAnkFwdAbs(:, SHS2);
stepLengthFast    = fAnkFwdAbs(:, FHS)  - sAnkFwdAbs(:, FHS);
takeOffLengthSlow = sAnkFwdAbs(:, STO)  - fAnkFwdAbs(:, STO);
takeOffLengthFast = fAnkFwdAbs(:, FTO)  - sAnkFwdAbs(:, FTO);

% Step lengths (2D), expressed with respect to the hip (not saved).
stepLengthSlow2D = sqrt(sum( ...
    (sAnk2D(:, SHS2, :) - fAnk2D(:, SHS2, :)).^2, 3));
stepLengthFast2D = sqrt(sum( ...
    (fAnk2D(:, FHS, :)  - sAnk2D(:, FHS,  :)).^2, 3));

% Spatial parameters (in millimeters)

% Alpha: positive portion of interlimb angle at heel strike
alphaSlow = sAnkFwd(:, SHS2);
alphaTemp = sAnkFwd(:, SHS);
alphaFast = fAnkFwd(:, FHS);
alphaDiff = alphaFast - alphaSlow;

% Beta: negative portion of interlimb angle at toe off
betaSlow = sAnkFwd(:, STO);
betaFast = fAnkFwd(:, FTO2);

% Position of the ankle marker at contralateral heel strike
XSlow = sAnkFwd(:, FHS);
XFast = fAnkFwd(:, SHS2);
Xdiff = XFast - XSlow;

% Stance range (subtract since beta is a negative value)
stanceRangeSlow = alphaTemp - betaSlow;
stanceRangeFast = alphaFast - betaFast;

% Swing range
swingRangeSlow = sAnkFwd(:, SHS2) - sAnkFwd(:, STO);
swingRangeFast = fAnkFwd(:, FHS)  - fAnkFwd(:, FTO);
swingRangeSlowAbs = sAnkFwdAbs(:, SHS2) - sAnkFwdAbs(:, STO);
swingRangeFastAbs = fAnkFwdAbs(:, FHS)  - fAnkFwdAbs(:, FTO);

% Ratio TO/HS
RFastPos = abs(betaFast ./ alphaFast);
RSloWPos = abs(betaSlow ./ alphaTemp);

% Ratio ankle position at HS of contralateral leg / HS
RFastPosSHS = abs(XFast ./ alphaFast);
RSlowPosFHS = abs(XSlow ./ alphaTemp);

% Spatial parameters (in degrees)

% Alpha: positive portion of interlimb angle at heel strike
alphaAngSlow = sAngle(:, SHS2);
alphaAngTemp = sAngle(:, SHS);
alphaAngFast = fAngle(:, FHS);

% Beta: negative portion of interlimb angle at toe off
betaAngSlow = sAngle(:, STO);
betaAngFast = fAngle(:, FTO2);

% Stance angle range (alpha + beta)
stanceRangeAngSlow = alphaAngTemp - betaAngSlow;
stanceRangeAngFast = alphaAngFast - betaAngFast;

% Interlimb spread at heel strike
omegaSlow = abs(sAngle(:, SHS2) - fAngle(:, SHS2));
omegaFast = abs(fAngle(:, FHS)  - sAngle(:, FHS));

% Alpha ratios
alphaRatioSlow = alphaSlow ./ (alphaSlow + alphaFast);
alphaRatioFast = alphaFast ./ (alphaSlow + alphaFast);

% Delta alphas
alphaDeltaSlow = sAngle(:, SHS2) - fAngle(:, FHS);
alphaDeltaFast = fAngle(:, FHS)  - sAngle(:, SHS);

%% Compute Average Hip-Referenced Ankle Placements
% Multiply by -1 to correct for direction since alpha must be positive
alphaTemp_fromAvgHip = -1 * sAnk_fromAvgHip(:, SHS);
alphaFast_fromAvgHip = -1 * fAnk_fromAvgHip(:, FHS);
alphaSlow_fromAvgHip = -1 * sAnk_fromAvgHip(:, SHS2);

xTemp_fromAvgHip = -1 * fAnk_fromAvgHip(:, SHS);
xSlow_fromAvgHip = -1 * sAnk_fromAvgHip(:, FHS);
xFast_fromAvgHip = -1 * fAnk_fromAvgHip(:, SHS2);

%% Compute Interlimb Spatial Parameters
stepLengthDiff   = stepLengthFast   - stepLengthSlow;
stepLengthAsym   = stepLengthDiff  ./ (stepLengthFast + stepLengthSlow);
stepLengthDiff2D = stepLengthFast2D - stepLengthSlow2D;
stepLengthAsym2D = stepLengthDiff2D ./ ...
    (stepLengthFast2D + stepLengthSlow2D);
angularSpreadDiff = omegaFast - omegaSlow;
angularSpreadAsym = angularSpreadDiff ./ (omegaFast + omegaSlow);
Sout     = (alphaFast - alphaSlow) ./ (alphaFast + alphaSlow);
Serror   = alphaRatioSlow - alphaRatioFast;
SerrorOld = alphaRatioFast ./ alphaRatioSlow;
Sgoal    = (stanceRangeFast - stanceRangeSlow) ./ ...
    (stanceRangeFast + stanceRangeSlow);
centerSlow = (alphaAngSlow + betaAngSlow) ./ 2;
centerFast = (alphaAngFast + betaAngFast) ./ 2;
angleOfOscillationAsym = centerFast - centerSlow;
Xasym    = Xdiff ./ (stepLengthFast + stepLengthSlow);
alphaAsym = alphaDiff ./ (stepLengthFast + stepLengthSlow);

% Phase shift (using angles)
% slowlimb = sAngle(indSHS:indSHS2);
% fastlimb = fAngle(indSHS:indSHS2);
% slowlimb = slowlimb - mean(slowlimb);
% fastlimb = fastlimb - mean(fastlimb);
% % Circular correlation
% phaseShift = circCorr(slowlimb, fastlimb);
%
% Phase shift (using marker locations)
% slowlimb = sAnkPos(indSHS:indSHS2);
% fastlimb = fAnkPos(indSHS:indSHS2);
% slowlimb = slowlimb - mean(slowlimb);
% fastlimb = fastlimb - mean(fastlimb);
% % Circular correlation
% phaseShiftPos = circCorr(slowlimb, fastlimb);
T = length(timeSHS);
phaseShift    = nan(T, 1);
phaseShiftPos = nan(T, 1);
for ii = 1:T
    if ~isnan(timeSHS(ii)) && ~isnan(timeSHS2(ii))
        if ~isempty(angleData)
            sLimb = angleData.split( ...
                timeSHS(ii), timeSHS2(ii)).getDataAsVector({[s 'Limb']});
            fLimb = angleData.split( ...
                timeSHS(ii), timeSHS2(ii)).getDataAsVector({[f 'Limb']});
            if ~isempty(sLimb) && ~isempty(fLimb)
                phaseShift(ii) = circCorr(sLimb, fLimb);
            end
        end
        Pos = rotatedMarkerData.split(timeSHS(ii), timeSHS2(ii)) ...
            .getOrientedData({[s 'ANK'], [f 'ANK']});
        if ~isempty(Pos)
            % Use only y-axis components, equivalent to sAnkFwd
            phaseShiftPos(ii) = circCorr(Pos(:, 1, 2), Pos(:, 2, 2));
        end
    end
end

%% Compute Contributions
% Compute spatial contributions (1D)
spatialFast = fAnkFwd(:, FHS) - sAnkFwd(:, SHS);
spatialSlow = sAnkFwd(:, SHS2) - fAnkFwd(:, FHS);

% Compute temporal contributions
ts    = timeFHS  - timeSHS;
tf    = timeSHS2 - timeFHS;
difft = ts - tf;

% FIXME: DO NOT use absolute value; if the sign is supposed to be the
% opposite one, just leave it as is. The absolute value makes it murky
% to know what this quantity means.
dispSlow = abs(sAnkFwd(:, FHS)  - sAnkFwd(:, SHS));
dispFast = abs(fAnkFwd(:, SHS2) - fAnkFwd(:, FHS));

% Velocity of foot relative to hip; should be close to actual belt speed
velocitySlow = dispSlow ./ ts;
velocityFast = dispFast ./ tf;
avgVel      = mean([velocitySlow velocityFast], 2);
avgStepTime = mean([ts tf], 2);         % half of strideTimeSlow!

spatialContribution   = spatialFast - spatialSlow;
stepTimeContribution  = avgVel .* difft;
velocityContribution  = avgStepTime .* (velocitySlow - velocityFast);
netContribution = ...
    spatialContribution + stepTimeContribution + velocityContribution;

% Alternative and normalized contributions
strideTimeSlow = timeSHS2 - timeSHS; % same as in computeTemporalParameters
spatialContributionAlt   = spatialContribution  ./ strideTimeSlow;
stepTimeContributionAlt  = stepTimeContribution ./ strideTimeSlow;
velocityContributionAlt  = velocityContribution ./ strideTimeSlow;
netContributionAlt       = netContribution      ./ strideTimeSlow;

% spatialContributionNorm = spatialContributionAlt ./ equivalentSpeed;
% stepTimeContributionNorm = stepTimeContributionAlt ./ equivalentSpeed;
% velocityContributionNorm = velocityContributionAlt ./ equivalentSpeed;
% netContributionNorm = netContributionAlt ./ equivalentSpeed;

spatialContributionAltRatio = ...
    spatialContributionAlt  ./ (velocitySlow + velocityFast);
stepTimeContributionAltRatio = ...
    stepTimeContributionAlt ./ (velocitySlow + velocityFast);
velocityContributionAltRatio = ...
    velocityContributionAlt ./ (velocitySlow + velocityFast);
netContributionAltRatio = ...
    netContributionAlt      ./ (velocitySlow + velocityFast);

Dist = stepLengthFast + stepLengthSlow;
spatialContributionNorm2  = spatialContribution  ./ Dist;
stepTimeContributionNorm2 = stepTimeContribution ./ Dist;
velocityContributionNorm2 = velocityContribution ./ Dist;
netContributionNorm2      = netContribution      ./ Dist;

aux = markerData.getDataAsTS( ...
    {[f 'ANKy'], [s 'ANKy']}).getSample(eventTimes, 'closest');
spatialContributionP = ...
    -(2 * aux(:, FHS, 1) - aux(:, SHS2, 2) - aux(:, SHS, 2));
vf = (aux(:, SHS2, 1) - aux(:, FHS,  1)) ./ tf;
vs = (aux(:, FHS,  2) - aux(:, SHS,  2)) ./ ts;
stepTimeContributionP  = 0.5 * (vf + vs) .* (ts - tf);
velocityContributionP  = 0.5 * (vs - vf) .* (tf + ts);
netContributionP = ...
    spatialContributionP + stepTimeContributionP + velocityContributionP;

spatialContributionPNorm  = spatialContributionP  ./ Dist;
stepTimeContributionPNorm = stepTimeContributionP ./ Dist;
velocityContributionPNorm = velocityContributionP ./ Dist;
netContributionPNorm      = netContributionP      ./ Dist;

% Added by Marcela 06/01/2021: displacement for single stance.
% FIXME: DO NOT use absolute value; if the sign is supposed to be the
% opposite one, just leave it as is since the absolute value makes it
% murky to know what this quantity means.
dispS = abs(sAnkFwd(:, FHS) - sAnkFwd(:, FTO));
dispF = abs(fAnkFwd(:, SHS2) - fAnkFwd(:, STO));

singleStanceSpeedSlow = dispS ./ (timeFHS  - timeFTO);
singleStanceSpeedFast = dispF ./ (timeSHS2 - timeSTO);
% NOTE: it will not be good for the split conditions to omit 'NaN' values
singleStanceSpeedAvg  = ...
    mean([singleStanceSpeedSlow singleStanceSpeedFast], 2);
singleStanceSpeedDiff = singleStanceSpeedFast - singleStanceSpeedSlow;

% Contributions in absolute frame using rotated marker data.
% NOTE: modified by Digna de Kam (April 2018) to use rotated markerdata,
% which allows using these values for overground trials.
aux = -rotatedMarkerDataAbs.getDataAsTS( ...
    {[f 'ANKy'], [s 'ANKy']}).getSample(eventTimes, 'closest');
spatialContributionP2 = ...
    -(2 * aux(:, FHS, 1) - aux(:, SHS2, 2) - aux(:, SHS, 2));
vf2 = abs((aux(:, SHS2, 1) - aux(:, FHS, 1))) ./ tf;
vs2 = abs((aux(:, FHS,  2) - aux(:, SHS, 2))) ./ ts;
stepTimeContributionP2  = 0.5 * (vf2 + vs2) .* (ts  - tf);
velocityContributionP2  = 0.5 * (vs2 - vf2) .* (tf  + ts);
netContributionP2 = spatialContributionP2 + ...
    stepTimeContributionP2 + velocityContributionP2;

spatialContributionPNorm2  = spatialContributionP2  ./ Dist;
stepTimeContributionPNorm2 = stepTimeContributionP2 ./ Dist;
velocityContributionPNorm2 = velocityContributionP2 ./ Dist;
netContributionPNorm2      = netContributionP2      ./ Dist;

% Contribution error values from T goal
stanceTimeSlow = timeSTO  - timeSHS;
stanceTimeFast = timeFTO2 - timeFHS;
stepTimeIdealT = ((velocitySlow + velocityFast) ./ 2) .* ...
    (stanceTimeSlow - stanceTimeFast) ./ Dist;
spatialIdealT  = -(velocityContributionNorm2 + stepTimeIdealT);
stepTimeErrorT = stepTimeIdealT - stepTimeContributionNorm2;
spatialErrorT  = spatialIdealT  - spatialContributionNorm2;

% Contribution error values from S goal
rangeSlow = alphaSlow - betaSlow;
rangeFast = alphaFast - betaFast;
spatialIdealS  = (2 * (alphaFast + alphaSlow) ./ Dist) .* ...
    ((rangeFast - rangeSlow) ./ (rangeFast + rangeSlow));
stepTimeIdealS = -velocityContributionNorm2 - spatialIdealS;
spatialErrorS  = spatialIdealS  - spatialContributionNorm2;
stepTimeErrorS = stepTimeIdealS - stepTimeContributionNorm2;

%% Compute Speeds
% Weighted average of ipsilateral speeds: if subjects spend much more
% time over one foot than the other, this may not be the arithmetic
% mean. = (ts./(tf+ts))*dispSlow./ts + (tf./(tf+ts))*dispFast./tf
%       = (ts./(tf+ts))*vs + (tf./(tf+ts))*vf
equivalentSpeed = (dispSlow + dispFast) ./ (ts + tf);

% sStanceIdxs = indFTO:indFHS;
% fStanceIdxs = indSTO:indSHS2;
% singleStanceSpeedSlowAbs = prctile(f_events*diff(sToe(sStanceIdxs,2)),70);
% singleStanceSpeedFastAbs = prctile(f_events*diff(fToe(fStanceIdxs,2)),70);
T = numel(timeSHS);                             % number of strides
singleStanceSpeedSlowAbs = nan(T, 1);
singleStanceSpeedFastAbs = nan(T, 1);
sToeAbsVel = markerData.getDataAsOTS({[s 'TOE']}).derivate;
fToeAbsVel = markerData.getDataAsOTS({[f 'TOE']}).derivate;
for ii = 1:T                                    % for each stride, ...
    if ~isnan(timeFTO(ii)) && ~isnan(timeFHS(ii))   % if events exist,...
        sToePartial = ...
            sToeAbsVel.split(timeFTO(ii), timeFHS(ii)).getOrientedData();
        singleStanceSpeedSlowAbs(ii) = prctile(sToePartial(:, 1, 2), 70);
    end
    if ~isnan(timeSTO(ii)) && ~isnan(timeSHS2(ii))
        fToePartial = ...
            fToeAbsVel.split(timeSTO(ii), timeSHS2(ii)).getOrientedData();
        singleStanceSpeedFastAbs(ii) = prctile(fToePartial(:, 1, 2), 70);
    end
end

singleStanceSpeedSlowAbsANK = nan(T, 1);
singleStanceSpeedFastAbsANK = nan(T, 1);
sToeAbsVelANK = markerData.getDataAsOTS({[s 'ANK']}).derivate;
fToeAbsVelANK = markerData.getDataAsOTS({[f 'ANK']}).derivate;
for ii = 1:T                                    % for each stride, ...
    if ~isnan(timeFTO(ii)) && ~isnan(timeFHS(ii))   % if events exist,...
        sToePartialANK = sToeAbsVelANK.split( ...
            timeFTO(ii), timeFHS(ii)).getOrientedData();
        singleStanceSpeedSlowAbsANK(ii) = ...
            prctile(sToePartialANK(:, 1, 2), 70);
    end
    if ~isnan(timeSTO(ii)) && ~isnan(timeSHS2(ii))
        fToePartialANK = fToeAbsVelANK.split( ...
            timeSTO(ii), timeSHS2(ii)).getOrientedData();
        singleStanceSpeedFastAbsANK(ii) = ...
            prctile(fToePartialANK(:, 1, 2), 70);
    end
end

singleStanceSpeedDiffAbsAnk = ...
    singleStanceSpeedFastAbsANK - singleStanceSpeedSlowAbsANK;

% Ankle relative to hip during ipsilateral stance phase
stanceSpeedSlow = abs(sAnkFwd(:, STO)  - sAnkFwd(:, SHS))  ./ ...
    (timeSTO  - timeSHS);
stanceSpeedFast = abs(fAnkFwd(:, FTO2) - fAnkFwd(:, FHS))  ./ ...
    (timeFTO2 - timeFHS);

% NOTE: 'stepSpeed' should be the same as the velocity calculation
% used for the contributions above.
stepSpeedSlow = dispSlow ./ ts; % ankle relative to hip, iHS to cHS
stepSpeedFast = dispFast ./ tf; % ankle relative to hip, iHS to cHS
stepSpeedAvg  = mean([stepSpeedSlow stepSpeedFast], 2, 'omitnan');

% rotate coordinates back to original to prevent discontinuities
% rotationMatrix = [cosd(-avgRotation) -sind(-avgRotation) 0;
%     sind(-avgRotation) cosd(-avgRotation) 0;
%     0 0 1];
% sAnk(indSHS:indFTO2,:) = (rotationMatrix * sAnk(indSHS:indFTO2,:)')';
% fAnk(indSHS:indFTO2,:) = (rotationMatrix * fAnk(indSHS:indFTO2,:)')';
% sHip(indSHS:indFTO2,:) = (rotationMatrix * sHip(indSHS:indFTO2,:)')';
% fHip(indSHS:indFTO2,:) = (rotationMatrix * fHip(indSHS:indFTO2,:)')';

%% Compute Other Contributions
velocityAltContribution = velocityContribution - ...
    (singleStanceSpeedSlowAbs - singleStanceSpeedFastAbs) .* avgStepTime;
velocityAltContributionAlt   = velocityAltContribution ./ strideTimeSlow;
velocityAltContributionNorm2 = velocityAltContribution ./ Dist;
velocityAltContributionP     = velocityContributionP - ...
    (singleStanceSpeedSlowAbs - singleStanceSpeedFastAbs) .* (tf + ts) / 2;
velocityAltContributionPNorm = velocityAltContributionP ./ Dist;

%% Assign Parameters to Data Matrix
data = nan(length(timeSHS), length(paramLabels));
data(:,   1) = direction;
data(:,   2) = hipPos;
data(:,   3) = stepLengthSlow;
data(:,   4) = stepLengthFast;
data(:,   5) = takeOffLengthSlow;
data(:,   6) = takeOffLengthFast;
data(:,   7) = alphaSlow;
data(:,   8) = alphaTemp;
data(:,   9) = alphaFast;
data(:,  10) = alphaDiff;
data(:,  11) = alphaAsym;
data(:,  12) = alphaAngSlow;
data(:,  13) = alphaAngFast;
data(:,  14) = betaSlow;
data(:,  15) = betaFast;
data(:,  16) = XSlow;
data(:,  17) = XFast;
data(:,  18) = Xdiff;
data(:,  19) = Xasym;
data(:,  20) = RFastPos;
data(:,  21) = RSloWPos;
data(:,  22) = RFastPosSHS;
data(:,  23) = RSlowPosFHS;
data(:,  24) = betaAngSlow;
data(:,  25) = betaAngFast;
data(:,  26) = stanceRangeSlow;
data(:,  27) = stanceRangeFast;
data(:,  28) = stanceRangeAngSlow;
data(:,  29) = stanceRangeAngFast;
data(:,  30) = swingRangeSlow;
data(:,  31) = swingRangeFast;
data(:,  32) = omegaSlow;
data(:,  33) = omegaFast;
data(:,  34) = alphaRatioSlow;
data(:,  35) = alphaRatioFast;
data(:,  36) = alphaDeltaSlow;
data(:,  37) = alphaDeltaFast;
data(:,  38) = stepLengthDiff;
data(:,  39) = stepLengthDiff2D;
data(:,  40) = stepLengthAsym;
data(:,  41) = stepLengthAsym2D;
data(:,  42) = angularSpreadDiff;
data(:,  43) = angularSpreadAsym;
data(:,  44) = Sout;
data(:,  45) = Serror;
data(:,  46) = SerrorOld;
data(:,  47) = Sgoal;
data(:,  48) = angleOfOscillationAsym;
data(:,  49) = phaseShift;
data(:,  50) = phaseShiftPos;
data(:,  51) = spatialContribution;
data(:,  52) = stepTimeContribution;
data(:,  53) = velocityContribution;
data(:,  54) = netContribution;
data(:,  55) = spatialContributionP;
data(:,  56) = stepTimeContributionP;
data(:,  57) = velocityContributionP;
data(:,  58) = netContributionP;
data(:,  59) = spatialContributionPNorm;
data(:,  60) = stepTimeContributionPNorm;
data(:,  61) = velocityContributionPNorm;
data(:,  62) = netContributionPNorm;
data(:,  63) = spatialContributionPNorm2;
data(:,  64) = stepTimeContributionPNorm2;
data(:,  65) = velocityContributionPNorm2;
data(:,  66) = netContributionPNorm2;
data(:,  67) = spatialContributionAlt;
data(:,  68) = stepTimeContributionAlt;
data(:,  69) = velocityContributionAlt;
data(:,  70) = netContributionAlt;
data(:,  71) = spatialContributionAltRatio;
data(:,  72) = stepTimeContributionAltRatio;
data(:,  73) = velocityContributionAltRatio;
data(:,  74) = netContributionAltRatio;
data(:,  75) = spatialContributionNorm2;
data(:,  76) = stepTimeContributionNorm2;
data(:,  77) = velocityContributionNorm2;
data(:,  78) = netContributionNorm2;
data(:,  79) = stepTimeIdealT;
data(:,  80) = spatialIdealT;
data(:,  81) = stepTimeErrorT;
data(:,  82) = spatialErrorT;
data(:,  83) = stepTimeIdealS;
data(:,  84) = spatialIdealS;
data(:,  85) = stepTimeErrorS;
data(:,  86) = spatialErrorS;
data(:,  87) = equivalentSpeed;
data(:,  88) = singleStanceSpeedSlowAbs;
data(:,  89) = singleStanceSpeedFastAbs;
data(:,  90) = singleStanceSpeedSlowAbsANK;
data(:,  91) = singleStanceSpeedFastAbsANK;
data(:,  92) = singleStanceSpeedDiffAbsAnk;
data(:,  93) = stepSpeedSlow;
data(:,  94) = stepSpeedFast;
data(:,  95) = stepSpeedAvg;
data(:,  96) = stanceSpeedSlow;
data(:,  97) = stanceSpeedFast;
data(:,  98) = alphaTemp_fromAvgHip;
data(:,  99) = alphaFast_fromAvgHip;
data(:, 100) = alphaSlow_fromAvgHip;
data(:, 101) = xTemp_fromAvgHip;
data(:, 102) = xFast_fromAvgHip;
data(:, 103) = xSlow_fromAvgHip;
data(:, 104) = velocitySlow;
data(:, 105) = velocityFast;
data(:, 106) = velocityAltContribution;
data(:, 107) = velocityAltContributionAlt;
data(:, 108) = velocityAltContributionNorm2;
data(:, 109) = velocityAltContributionP;
data(:, 110) = velocityAltContributionPNorm;
data(:, 111) = singleStanceSpeedSlow;
data(:, 112) = singleStanceSpeedFast;
data(:, 113) = singleStanceSpeedAvg;
data(:, 114) = singleStanceSpeedDiff;

%% Output Computed Parameters
out = parameterSeries(data, paramLabels, [], description);

end

