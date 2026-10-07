function COMData = computeCOM(this)
%COMPUTECOM Computes center of mass from marker data.
%
%   COMData = computeCOM(this) calculates the center of mass trajectory
% using the COMCalculator function
%
% Inputs:
%   this - labData object
%
% Outputs:
%   COMData - orientedLabTimeSeries containing center of mass data
%
% Toolbox Dependencies: None
%
% See also COMCALCULATOR.

COMData = COMCalculator(this.markerData);
end

