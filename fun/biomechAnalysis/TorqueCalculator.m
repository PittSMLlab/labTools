function [AllMomentsTS,COPTS,COMTS] = TorqueCalculator(rawTrialData,weight)
%TORQUECALCULATOR Calculate torque at each leg joint using inverse dynamics

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
    AllMomentsTS = []; % TorqueCalculatorNew(COMTS,COPTS,in.markerData,in.GRFData,weight);
end

end

