function processedData = process(this, subData, eventClass)
% process  Processes raw trial data to compute angles, gait events,
%   and adaptation parameters.
%
%   processedData = process(this, subData) processes the raw trial
%   data and returns a processedTrialData object with computed limb
%   angles, gait events, filtered EMG, COP, COM, and joint moments.
%
%   processedData = process(this, subData, eventClass) uses the
%   specified gait event detection method.
%
%   Inputs:
%     this       - labData object
%     subData    - subjectData object containing subject weight and
%                  other anthropometric information
%     eventClass - (optional) String specifying the gait event
%                  detection method. Defaults to '' if omitted:
%                    ''      - default (forces for TM trials,
%                              kinematics otherwise)
%                    'kin'   - strictly from kinematics
%                    'force' - strictly from forces
%
%   Outputs:
%     processedData - processedTrialData object containing all
%                     processed data
%
%   Note: This function must be idempotent, i.e.,
%           labData.process().process() == labData.process()
%         Otherwise re-processing data may lead to double or
%         triple filtering.
%
%   Toolbox Dependencies:
%     None
%
%   See also: processedTrialData, calcParameters, experimentData/process

if nargin < 3 || isempty(eventClass)
    eventClass = [];
end

% 1) Extract amplitude from EMG data if present
spikeRemovalFlag = 0;
[procEMGData, filteredEMGData] = processEMG(this, spikeRemovalFlag);

% 2) Interpolate marker data if there is missing data
%    (make into function once we have a method to do this)
markers = this.markerData;
if ~isempty(markers)
    % function goes here: check marker data health
end

% 3) Calculate limb angles
angleData = calcLimbAngles(this);

% 4) Calculate gait events from kinematics or forces if available;
%    last argument is the perceptual task flag
gaitEvents = getEvents(this, angleData,  this.metaData.perceptualTasks);

% 5) If 'beltSpeedReadData' is empty, try to generate it from
%    foot markers, if existent
if isempty(this.beltSpeedReadData)
    this.beltSpeedReadData = getBeltSpeedsFromFootMarkers(this,gaitEvents);
end

% 6) Compute COP, COM, and joint torque data
[jointMomentsData, ~, COMData] = this.computeTorques(subData.weight);
% Replacing COPData with alternative computation
COPData = this.computeCOPAlt();
% COMData = this.CarlysCOMData(); % CJS: you should do this!

% 7) Generate processedTrialData object
processedData = processedTrialData(this.metaData, this.markerData, ...
    filteredEMGData, this.GRFData, this.beltSpeedSetData, ...
    this.beltSpeedReadData, this.accData, this.EEGData, ...
    this.footSwitchData, gaitEvents, procEMGData, angleData, COPData, ...
    COMData, jointMomentsData, this.HreflexPin);

% 8) Calculate adaptation parameters (to be recalculated later)
processedData.adaptParams = ...
    calcParameters(processedData, subData, eventClass);

end

