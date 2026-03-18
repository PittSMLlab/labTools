function newThis = times(this, constant)
%times  Multiplies by constant (override)
%
%   newThis = times(this, constant) multiplies and preserves
%   orientedLabTimeSeries type
%
%   Inputs:
%       this - orientedLabTimeSeries object
%       constant - scalar or array to multiply by
%
%   Outputs:
%       newThis - scaled orientedLabTimeSeries
%
%   See also: labTimeSeries/times, plus

newThis = times@labTimeSeries(this, constant);
newThis = newThis.castAsOTS(this.orientation);
end

