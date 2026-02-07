function newThis = minus(this, other)
%minus  Subtracts two alignedTimeSeries
%
%   newThis = minus(this, other) subtracts other from this element-wise
%
%   Inputs:
%       this - alignedTimeSeries object
%       other - alignedTimeSeries with compatible dimensions
%
%   Outputs:
%       newThis - difference of two alignedTimeSeries
%
%   See also: plus, times

newThis = this;
newThis.Data = this.Data - other.Data;
end

