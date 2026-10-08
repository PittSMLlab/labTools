function newThis = times(this, constant)
%TIMES Multiplies by constant (override).
%
%   newThis = times(this, constant) multiplies and preserves
% orientedLabTimeSeries type
%
% Inputs:
%   this     - orientedLabTimeSeries object
%   constant - scalar or array to multiply by
%
% Outputs:
%   newThis - scaled orientedLabTimeSeries
%
% Toolbox Dependencies: None
%
% See also LABTIMESERIES/TIMES, PLUS.

newThis = times@labTimeSeries(this, constant);
newThis = newThis.castAsOTS(this.orientation);
end

