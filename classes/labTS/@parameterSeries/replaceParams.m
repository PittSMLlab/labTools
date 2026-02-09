function this = replaceParams(this, other)
%replaceParams  Replaces existing parameters
%
%   this = replaceParams(this, other) replaces existing parameters in
%   this with parameter data from other
%
%   Inputs:
%       this - parameterSeries object
%       other - parameterSeries with parameters to replace
%
%   Outputs:
%       this - parameterSeries with replaced parameters
%
%   Note: If other contains parameters that don't exist in this, they
%         are appended
%
%   See also: cat, appendData

% Finding parameters that already existed
[bool, idx] = this.isaLabel(other.labels);
% Replacing data
this.Data(:, idx(bool)) = other.Data(:, bool);
% Replacing descriptions (is this necessary?)
this.description_(idx(bool)) = other.description(bool);
% catting data for parameters that DIDN'T exist
if any(~bool)
    warning(['Asked to replace parameters, but found parameters ' ...
        'that didn''t exist. Appending.']);
    this = this.cat(other.getDataAsPS(other.labels(~bool), [], 1));
end
end

