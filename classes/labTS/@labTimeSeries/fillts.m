function this = fillts(this)
%fillts  Substitutes NaN values (deprecated)
%
%   this = fillts(this) fills NaN values using linear interpolation
%
%   Inputs:
%       this - labTimeSeries object
%
%   Outputs:
%       this - labTimeSeries with NaN filled
%
%   Note: TODO - Deprecate. Use substituteNaNs instead.
%
%   See also: substituteNaNs

warning('labTS:fillts', ...
    'labTS.fillts is being deprecated. Use substituteNaNs instead.');
this = substituteNaNs(this, 'linear');
end

