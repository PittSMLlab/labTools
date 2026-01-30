function COPData = computeCOP(this)
%computeCOP  Computes center of pressure from GRF data
%
%   COPData = computeCOP(this) calculates the center of
%   pressure using the COPCalculator function
%
%   Inputs:
%       this - labData object
%
%   Outputs:
%       COPData - orientedLabTimeSeries containing center of
%                 pressure data
%
%   See also: COPCalculator, computeCOPAlt

COPData = COPCalculator(this.GRFData);
end

