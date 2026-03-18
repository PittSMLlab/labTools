function newThis = substituteNaNs(this, method)
%substituteNaNs  Fills NaN values (override)
%
%   newThis = substituteNaNs(this, method) fills NaN and preserves
%   orientedLabTimeSeries type
%
%   Inputs:
%       this - orientedLabTimeSeries object
%       method - interpolation method (optional)
%
%   Outputs:
%       newThis - orientedLabTimeSeries with NaN filled
%
%   See also: labTimeSeries/substituteNaNs

if nargin < 2 || isempty(method)
    method = [];
end
newThis = substituteNaNs@labTimeSeries(this, method);
newThis = newThis.castAsOTS(this.orientation);
end

