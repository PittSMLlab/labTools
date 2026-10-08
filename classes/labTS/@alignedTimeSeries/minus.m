function newThis = minus(this, other)
%MINUS Subtracts two alignedTimeSeries.
%
%   newThis = minus(this, other) subtracts other from this element-wise
%
% Inputs:
%   this  - alignedTimeSeries object
%   other - alignedTimeSeries with compatible dimensions
%
% Outputs:
%   newThis - difference of two alignedTimeSeries
%
% Toolbox Dependencies: None
%
% See also PLUS, TIMES.

newThis = this;
newThis.Data = this.Data - other.Data;
end

