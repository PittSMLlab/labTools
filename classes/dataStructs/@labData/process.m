function processedData = process(this, subData, eventClass)
%process  Processes raw data to find angles, events, and
%adaptation parameters
%
%   processedData = process(this, subData) processes the raw
%   data and returns a processedTrialData object with computed
%   angles, events, EMG processing, COP, COM, and joint moments
%
%   processedData = process(this, subData, eventClass)
%   optionally specifies event class for parameter calculation
%
%   Inputs:
%       this - labData object
%       subData - subject data structure containing weight and
%                 other subject information
%       eventClass - optional event classification parameter
%
%   Outputs:
%       processedData - processedTrialData object containing
%                       all processed data
%
%   Note: This function MUST BE idempotent, i.e.,
%         labData.process.process = labData.process
%         Otherwise re-processing data may lead to double or
%         triple filtering.
%
%   See also: processedTrialData, calcParameters

% To all coders: this function HAS TO BE idempotent, ie:
% labData.process.process = labData.process
% Otherwise re-processing data may lead to double or triple
% filtering.
if nargin < 3 || isempty(eventClass)
    eventClass = [];
end


% 1) Extract amplitude from emg data if present
spikeRemovalFlag = 0;
[procEMGData, filteredEMGData] = processEMG(this, ...
    spikeRemovalFlag);

% 2) Attempt to interpolate marker data if there is missing
% data (make into function once we have a method to do this)
markers = this.markerData;
if ~isempty(markers)
    % function goes here: check marker data health
end

% 3) Calculate limb angles
angleData = calcLimbAngles(this);

% 4) Calculate events from kinematics or force if available
% Last argument is the perceptual task flag
events = getEvents(this, angleData, ...
    this.metaData.perceptualTasks);

% 5) If 'beltSpeedReadData' is empty, try to generate it
% from foot markers, if existent
if isempty(this.beltSpeedReadData)
    this.beltSpeedReadData = ...
        getBeltSpeedsFromFootMarkers(this, events);
end

% 6) Get COP, COM and joint torque data.
[jointMomentsData, ~, COMData] = ...
    this.computeTorques(subData.weight);
% Replacing COPData with alternative computation
COPData = this.computeCOPAlt;
% COMDATA = this.CarlysCOMData; % CJS: you should do this!

% 7) Generate processedTrial object
processedData = processedTrialData(this.metaData, ...
    this.markerData, filteredEMGData, this.GRFData, ...
    this.beltSpeedSetData, this.beltSpeedReadData, ...
    this.accData, this.EEGData, this.footSwitchData, events, ...
    procEMGData, angleData, COPData, COMData, ...
    jointMomentsData, this.HreflexPin);

% 8) Calculate adaptation parameters - to be
% recalculated later!!
processedData.adaptParams = calcParameters(processedData, ...
    subData, eventClass);

end

