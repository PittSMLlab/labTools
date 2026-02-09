function newThis = markBadWhenMissingAll(this, labels)
%markBadWhenMissingAll  Marks strides bad if all params missing
%
%   newThis = markBadWhenMissingAll(this, labels) marks strides as bad
%   if all of the specified parameters have NaN values
%
%   Inputs:
%       this - parameterSeries object
%       labels - cell array of parameter labels to check
%
%   Outputs:
%       newThis - parameterSeries with updated bad flags
%
%   See also: markBadWhenMissingAny, markBadStridesAsNan

newThis = this;
aux = this.getDataAsVector(labels);
[~, bi] = this.isaLabel('bad');
newThis.Data(:, bi) = this.bad | all(isnan(aux), 2);
[~, bg] = this.isaLabel('good');
newThis.Data(:, bg) = ~this.bad;
end

