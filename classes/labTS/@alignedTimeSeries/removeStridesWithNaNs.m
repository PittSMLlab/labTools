function newThis = removeStridesWithNaNs(this)
%removeStridesWithNaNs  Removes strides with missing data
%
%   newThis = removeStridesWithNaNs(this) removes all strides that
%   contain any NaN values
%
%   Inputs:
%       this - alignedTimeSeries object
%
%   Outputs:
%       newThis - alignedTimeSeries with complete strides only
%
%   See also: getPartialStridesAsATS

inds = find(all(all(~isnan(this.Data), 2), 1));
newThis = getPartialStridesAsATS(this, inds);
end

