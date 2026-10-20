function this = markBadStridesAsNan(this)
%MARKBADSTRIDESASNAN Sets bad strides to NaN.
%
%   this = markBadStridesAsNan(this) sets all parameter values to NaN for
% strides marked as bad
%
% Inputs:
%   this - parameterSeries object
%
% Outputs:
%   this - parameterSeries with bad strides set to NaN
%
%   Note: Fixed parameters remain unchanged
%
% Toolbox Dependencies: None
%
% See also MARKBADWHENMISSINGANY, BAD.

inds = this.bad;
this.Data(inds == 1, this.fixedParams + 1:end) = NaN;
end

