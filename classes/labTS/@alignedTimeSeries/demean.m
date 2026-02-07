function newThis = demean(this)
%demean  Removes mean
%
%   newThis = demean(this) subtracts the mean (across strides) from
%   each channel
%
%   Inputs:
%       this - alignedTimeSeries object
%
%   Outputs:
%       newThis - demeaned alignedTimeSeries
%
%   See also: mean, equalizeEnergyPerChannel

newThis = this;
newThis.Data = bsxfun(@minus, this.Data, this.mean.Data);
end

