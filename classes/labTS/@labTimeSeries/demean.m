function newthis = demean(this)
%demean  Removes mean from each channel
%
%   newthis = demean(this) subtracts the mean from each channel
%
%   Inputs:
%       this - labTimeSeries object
%
%   Outputs:
%       newthis - demeaned labTimeSeries
%
%   See also: equalizeVarPerChannel, equalizeEnergyPerChannel

newthis = this;
newthis.Data = bsxfun(@minus, this.Data, nanmean(this.Data));
end

