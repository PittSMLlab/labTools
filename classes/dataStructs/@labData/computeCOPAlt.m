function [COPData, COPL, COPR] = computeCOPAlt(this, noFilterFlag)
%computeCOPAlt  Alternative method to compute center of pressure
%
%   [COPData, COPL, COPR] = computeCOPAlt(this) computes center
%   of pressure for left and right legs separately, then merges
%   them. Uses default filtering.
%
%   [COPData, COPL, COPR] = computeCOPAlt(this, noFilterFlag)
%   optionally disables filtering when noFilterFlag is true
%
%   Inputs:
%       this - labData object
%       noFilterFlag - flag to disable filtering (default: 1)
%
%   Outputs:
%       COPData - merged center of pressure data
%       COPL - left leg center of pressure
%       COPR - right leg center of pressure
%
%   Note: Only works for GRFData from Bertec instrumented
%         treadmill
%
%   See also: computeCOP, computeHemiCOP, mergeHemiCOPs

if nargin < 2 || isempty(noFilterFlag)
    noFilterFlag = 1;
end
% warning('orientedLabTimeSeries:computeCOP', 'This only works
% for GRFData that was obtained from the Bertec instrumented
% treadmill');
[COPL, FL, ~] = computeHemiCOP(this, 'L', noFilterFlag);
% To avoid repeat warnings, which are annoying
warning('off', 'orientedLabTimeSeries:computeCOP')
[COPR, FR, ~] = computeHemiCOP(this, 'R', noFilterFlag);
warning('on', 'orientedLabTimeSeries:computeCOP')
COPL.Data(any(isinf(COPL.Data) | isnan(COPL.Data), 2), :) = 0;
COPR.Data(any(isinf(COPR.Data) | isnan(COPR.Data), 2), :) = 0;
[COPData] = labData.mergeHemiCOPs(COPL, COPR, FL, FR, ...
    noFilterFlag);
end

