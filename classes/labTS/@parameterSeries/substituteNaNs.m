function newThis = substituteNaNs(this, method)
%substituteNaNs  Fills NaN values, preserving fixed params
%
%   newThis = substituteNaNs(this) fills NaN using linear interpolation
%
%   newThis = substituteNaNs(this, method) uses specified method
%
%   Inputs:
%       this - parameterSeries object
%       method - interpolation method (optional, default: 'linear')
%
%   Outputs:
%       newThis - parameterSeries with NaN filled
%
%   Note: Fixed parameters (bad, trial, initTime, etc.) are preserved
%         unchanged
%
%   See also: labTimeSeries/substituteNaNs

if nargin < 2 || isempty(method)
    method = 'linear';
end
newThis = this.substituteNaNs@labTimeSeries(method);
newThis.Data(:, 1:this.fixedParams) = this.Data(:, 1:this.fixedParams);
end

