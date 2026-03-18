function newThis = derivative(this, diffOrder)
%derivative  Numerical derivative (override)
%
%   newThis = derivative(this, diffOrder) computes derivative and
%   preserves orientedLabTimeSeries type
%
%   Inputs:
%       this - orientedLabTimeSeries object
%       diffOrder - order of finite difference filter (optional)
%
%   Outputs:
%       newThis - differentiated orientedLabTimeSeries
%
%   See also: labTimeSeries/derivative, derivate

if nargin < 2
    diffOrder = [];
end
newThis = derivative@labTimeSeries(this, diffOrder);
newThis = newThis.castAsOTS(this.orientation);
end

