function [sAnk, fAnk, sAngle, fAngle, direction, hipPos3D, ...
    hipPosSHS, sAnk_fromAvgHip, fAnk_fromAvgHip] = ...
    extractKinematicDataAtEvents(eventTimes, markerData, ...
    rotatedMarkerData, angleData, s)
%EXTRACTKINEMATICDATAATEVENTS Extract markers and angles at gait event times.
%
%   Shared implementation used by GETKINEMATICDATA and
% GETKINEMATICDATAABS. Determines fast/slow leg assignment, extracts
% marker data at eight gait events per stride from both markerData
% (original lab frame) and rotatedMarkerData (caller-specific rotated
% frame), extracts and sign-corrects limb angles, computes walking
% direction, and computes hip and ankle positions. The caller provides
% rotatedMarkerData and is responsible for computing the final ankle
% positions in its chosen coordinate frame.
%
% Inputs:
%   eventTimes        - (numStrides x numEvents) array of gait event
%                       times
%   markerData        - orientedLabTimeSeries of 3D marker trajectories
%                       in the original lab frame
%   rotatedMarkerData - orientedLabTimeSeries already translated/rotated
%                       by the caller to the desired reference frame
%   angleData         - labTimeSeries of limb angles (or empty)
%   s                 - (char) slow-leg identifier: 'L' or 'R'
%
% Outputs:
%   sAnk            - (numStrides x numEvents x 3) slow ankle marker
%                     positions at event times, in lab frame
%   fAnk            - (numStrides x numEvents x 3) fast ankle marker
%                     positions at event times, in lab frame
%   sAngle          - (numStrides x numEvents) slow leg limb angles,
%                     sign-corrected so SHS value is positive
%   fAngle          - (numStrides x numEvents) fast leg limb angles,
%                     sign-corrected to match sAngle sign
%   direction       - (numStrides x 1) walking direction (+1 or -1)
%   hipPos3D        - (numStrides x numEvents x 3) mid-hip 3D position
%                     (average of slow and fast hip markers) at event
%                     times, in lab frame
%   hipPosSHS       - (numStrides x 1) mid-hip fore-aft position at SHS
%   sAnk_fromAvgHip - (numStrides x numEvents) slow ankle fore-aft
%                     position relative to mean hip position over stride
%   fAnk_fromAvgHip - (numStrides x numEvents) fast ankle fore-aft
%                     position relative to mean hip position over stride
%
% Toolbox Dependencies:
%   None
%
% See also GETKINEMATICDATA, GETKINEMATICDATAABS, COMPUTESPATIALPARAMETERS.

arguments
    eventTimes        (:,:) double
    markerData
    rotatedMarkerData
    angleData
    s                 (1,:) char
end

%% Get Relevant Sample of Data (Using Interpolation)
% 's' represents the slow limb, 'f' represents the fast limb
if strcmp(s, 'L')
    f = 'R';
elseif strcmp(s, 'R')
    f = 'L';
else
    error('Invalid limb specification. Must be ''L'' or ''R''.');
end

% extract marker orientation and axis information
orientation = markerData.orientation;
% NOTE: directions, signs, and legs2 are not currently used downstream
% but are preserved here for potential future generalization.
directions  = {orientation.sideAxis, orientation.foreaftAxis, ...
    orientation.updownAxis};
signs = [orientation.sideSign orientation.foreaftSign ...
    orientation.updownSign];

% define markers of interest
markers = {'HIP', 'ANK', 'TOE'};
labels  = {};
legs    = {s, f};
legs2   = {'s', 'f'};

% construct labels for markers (e.g., 'sHIP', 'fANK', etc.)
for mrkr = 1:length(markers)
    for ii = 1:2
        % odd indices: slow leg, even indices: fast leg
        labels{end+1} = [legs{ii} markers{mrkr}];
    end
end

% check for missing markers
[bool, idx] = isaLabelPrefix(markerData, labels);
if ~all(bool)
    warning(['Markers are missing: ' ...
        cell2mat(strcat(labels(~bool), ','))]);
end

% extract marker data at gait event times
% NOTE: sToe, fToe, sToeRel, and fToeRel are populated by the loop
% below but are not exposed as outputs; add outputs here if callers
% need toe marker data.
for lbl = 1:length(labels) % assign each marker data to a x3 str
    markerTS = markerData.getDataAsTS( ...
        markerData.addLabelSuffix(labels{lbl}));
    if ~isempty(markerTS.Data)
        % extract data by finding the closest available sample at each
        % event time
        newMarkerData = markerTS.getSample(eventTimes, 'closest');
        relMarkerData = rotatedMarkerData.getDataAsTS( ...
            rotatedMarkerData.addLabelSuffix(labels{lbl}));
        relMarkerData = relMarkerData.getSample(eventTimes, 'closest');
    else    % otherwise, a marker is missing
        warning(['Marker ' labels{lbl} ...
            ' is missing. All references to it will return NaN.']);
        newMarkerData = nan([size(eventTimes), 3]);
        relMarkerData = nan([size(eventTimes), 3]);
    end

    % assign extracted marker data to corresponding variables
    if strcmp(labels{lbl}(1), s)       % if slow leg markers, ...
        eval(['s' upper(labels{lbl}(2)) ...
            lower(labels{lbl}(3:4)) ' = newMarkerData;']);
        eval(['s' upper(labels{lbl}(2)) ...
            lower(labels{lbl}(3:4)) 'Rel = relMarkerData;']);
    elseif strcmp(labels{lbl}(1), f)   % if fast leg markers, ...
        eval(['f' upper(labels{lbl}(2)) ...
            lower(labels{lbl}(3:4)) ' = newMarkerData;']);
        eval(['f' upper(labels{lbl}(2)) ...
            lower(labels{lbl}(3:4)) 'Rel = relMarkerData;']);
    else                            % otherwise, ...
        error('Marker labels must begin with ''R'' or ''L''.');
    end
end

%% Extract Angle Data at Gait Event Times
if ~isempty(angleData)
    newAngleData = angleData.getDataAsTS({[s 'Limb'], [f 'Limb']});
    newAngleData = newAngleData.getSample(eventTimes, 'closest');
    sAngle = newAngleData(:, :, 1);
    fAngle = newAngleData(:, :, 2);
else
    sAngle = nan(size(eventTimes, 1), size(eventTimes, 2), 1);
    fAngle = nan(size(eventTimes, 1), size(eventTimes, 2), 1);
end

angleSignCorr = sign(sAngle(:, 1));     % checks for sAngle(indSHS) < 0
sAngle = bsxfun(@times, sAngle, angleSignCorr);
fAngle = bsxfun(@times, fAngle, angleSignCorr);

%% Compute Walking Direction
% direction is determined from y-axis difference of slow ankle marker
% during swing phase (STO to SHS2)
% TODO: would using SHS and STO work just as well?
direction = sign(diff(sAnk(:, 4:5, 2), 1, 2));

% handle missing values in direction vector
indsDirNans = find(isnan(direction));   % identify any NaN values
numNans     = length(indsDirNans);      % number of NaN values
for miss = 1:numNans                    % for each missing value, ...
    % check only y-axis values for current stride (i.e., none of gait
    % events with '2' in the name since could be at or approaching a turn)
    hasVal = ~isnan(sAnk(indsDirNans(miss), 1:4, 2));
    % use two most disparate gait events in time to try to account for
    % noise in the ankle marker y-axis position during stance phase
    direction(indsDirNans(miss)) = sign(diff(sAnk(indsDirNans(miss), ...
        [find(hasVal, 1) find(hasVal, 1, 'last')], 2), 1, 2));
end

% TODO: would it be best to simply leave the zeros since unclear?
% handle invalid direction values (where only one valid y-value exists)
indsDirZeros = find(direction == 0);
numZeros     = length(indsDirZeros);
for ii = 1:numZeros                     % for each invalid measure, ...
    if indsDirZeros(ii) == 1            % if first stride is invalid, ...
        direction(1) = direction(2);    % set to be same as stride 2
    else                                % otherwise, ...
        % set invalid direction value to be previous stride direction value
        direction(indsDirZeros(ii)) = direction(indsDirZeros(ii)-1);
    end
end

%% Compute Hip Positions
hipPos3D    = 0.5 * (sHip + fHip);
hipPosFwd   = hipPos3D(:, :, 2);    % extract y-axis component
% just for check, should be all zeros
hipPos3DRel = 0.5 * (sHipRel + fHipRel);
% hipPos = mean([sHip(indSHS,2) fHip(indSHS,2)]);
hipPosSHS   = hipPosFwd(:, 1);      % hip position at SHS
% compute average hip position over gait cycle (SHS to STO2)
hipPosAvg_forFast = mean(mean(hipPosFwd(:, 1:6), 'omitnan'));
hipPosAvg_forSlow = mean(mean(hipPosFwd(:, 3:8), 'omitnan'));

% y position of slow/fast ankle corrected by average hip position
sAnk_fromAvgHip = sAnk(:, :, 2) - hipPosAvg_forSlow;
fAnk_fromAvgHip = fAnk(:, :, 2) - hipPosAvg_forFast;

end
