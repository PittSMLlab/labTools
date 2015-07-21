function [ AllMomentsTS,COPTS,COMTS ] = TorqueCalculator(rawTrialData, weight)
%TorqueCalculator This function calculates the torques at each of the
%joints of the lower body based on inverse dynamics calculations.

in=rawTrialData;
clear rawTrialData

%% STEP 1: Compute COP
if isempty(in.GRFData)
    COPTS = [];
else
    [COPTS] = COPCalculator(in.GRFData);
end

%% STEP 2: Compute COM & extract values
if isempty(in.markerData)
    COMTS = [];
else
    [COMTS] = COMCalculator(in.markerData);
end
%% STEP 3: Compute Torques
if isempty(COMTS) || isempty(COPTS)
    AllMomentsTS = [];
else
    [AllMomentsTS] = TorqueCalculatorNew(COMTS, COPTS, in.markerData, in.GRFData, weight);
end
end
