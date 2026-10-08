function [AllMomentsTS,COPTS,COMTS] = TorqueCalculator(rawTrialData,weight)
%TORQUECALCULATOR Calculate torque at each leg joint using inverse dynamics.
%
%   Computes the center of pressure from the GRF data and the center of
% mass of the leg segments from the marker data. The torque step itself is
% not implemented: the call to TorqueCalculatorNew is commented out and
% AllMomentsTS is always empty.
%
% Inputs:
%   rawTrialData - rawTrialData with GRFData and markerData
%   weight       - body weight, not used while the torque step is off
%
% Outputs:
%   AllMomentsTS - empty array (torque step not implemented)
%   COPTS        - center of pressure time series, [] without GRF data
%   COMTS        - center of mass time series, [] without marker labels
%
% Toolbox Dependencies: Signal Processing Toolbox (through COPCalculator)
%
% See also COPCALCULATOR, COMCALCULATOR, TORQUECALCULATORNEW.

in = rawTrialData;
clear rawTrialData;

%% STEP 1: Compute Center of Pressure (COP)
if isempty(in.GRFData)                  % if GRF data is empty, ...
    COPTS = [];                         % output empty array
else                                    % otherwise, ...
    COPTS = COPCalculator(in.GRFData);  % calculate COP time series
end

%% STEP 2: Compute Center of Mass (COM)
% if no marker data or no marker labels, ...
if isempty(in.markerData) || numel(in.markerData.labels) == 0
    COMTS = [];                             % output empty array
else                                        % otherwise, ...
    COMTS = COMCalculator(in.markerData);   % calculate COM time series
end

%% STEP 3: Compute Torques
if isempty(COMTS) || isempty(COPTS)     % if no COM or COP time series, ...
    AllMomentsTS = [];                  % output empty array
else                                    % otherwise, ...
    % NOT YET IMPLEMENTED
    % TorqueCalculatorNew(COMTS,COPTS,in.markerData,in.GRFData,weight);
    AllMomentsTS = [];
end

end

