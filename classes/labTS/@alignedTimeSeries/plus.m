function newThis = plus(this, other)
%PLUS Adds two alignedTimeSeries.
%
%   newThis = plus(this, other) adds other to this element-wise
%
% Inputs:
%   this  - alignedTimeSeries object
%   other - alignedTimeSeries with compatible dimensions
%
% Outputs:
%   newThis - sum of two alignedTimeSeries
%
% Toolbox Dependencies: None
%
% See also MINUS, TIMES.

newThis = this;
newThis.Data = this.Data + other.Data;
end

