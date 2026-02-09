function this = normalizeToBaseline(this, labels, rangeValues)
%normalizeToBaseline  Normalizes parameters (deprecated)
%
%   this = normalizeToBaseline(this, labels, rangeValues) linearly
%   transforms parameters
%
%   Inputs:
%       this - parameterSeries object
%       labels - cell array of parameter labels to normalize
%       rangeValues - 2-element vector [min max] defining range
%
%   Outputs:
%       this - parameterSeries with normalized parameters
%
%   Note: Deprecated, use linearStretch instead
%
%   See also: linearStretch

warning('parameterSeries:normalizeToBaseline', ...
    'Deprecated, use linearStretch');
this = linearStretch(this, labels, rangeValues);
end

