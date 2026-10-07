function COPData = computeCOP(this)
%COMPUTECOP Computes center of pressure from GRF data.
%
%   COPData = computeCOP(this) calculates the center of pressure using the
% COPCalculator function
%
% Inputs:
%   this - labData object
%
% Outputs:
%   COPData - orientedLabTimeSeries containing center of pressure data
%
% Toolbox Dependencies: None
%
% See also COPCALCULATOR, COMPUTECOPALT.

COPData = COPCalculator(this.GRFData);
end

