function [ AllMomentsTS,COPTS,COMTS ] = TorqueCalculator(rawTrialData)
%TorqueCalculator This function calculates the torques at each of the
%joints of the lower body based on inverse dynamics calculations.

in=rawTrialData;
clear rawTrialData

%%
%STEP 1: Compute COP
[COPTS] = COPCalculator(in.GRFData);

%% 
%STEP 2: Compute COM & extract values
[COMTS] = COMCalculator(in.markerData);

%% ---------------
%STEP 3: Compute Torques

[AllMomentsTS] = TorqueCalculatorNew(COMTS, COPTS, in.markerData, in.GRFData);

end
