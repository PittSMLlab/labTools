function COMData = computeCOM(this)
%computeCOM  Computes center of mass from marker data
%
%   COMData = computeCOM(this) calculates the center of mass
%   trajectory using the COMCalculator function
%
%   Inputs:
%       this - labData object
%
%   Outputs:
%       COMData - orientedLabTimeSeries containing center of
%                 mass data
%
%   See also: COMCalculator

COMData = COMCalculator(this.markerData);
end

