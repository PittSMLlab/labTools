function newThis = markBadWhenMissingAny(this, labels)
%MARKBADWHENMISSINGANY Marks strides bad if any param missing.
%
%   newThis = markBadWhenMissingAny(this, labels) marks strides as bad if
% any of the specified parameters have NaN values
%
% Inputs:
%   this   - parameterSeries object
%   labels - cell array of parameter labels to check
%
% Outputs:
%   newThis - parameterSeries with updated bad flags
%
% Toolbox Dependencies: None
%
% See also MARKBADWHENMISSINGALL, MARKBADSTRIDESASNAN.

newThis = this;
aux     = this.getDataAsVector(labels);
[~, bi] = this.isaLabel('bad');
newThis.Data(:, bi) = this.bad | any(isnan(aux), 2);
[~, bg] = this.isaLabel('good');
newThis.Data(:, bg) = ~this.bad;
end

