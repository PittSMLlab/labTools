function newthis = equalizeVarPerChannel(this)
%equalizeVarPerChannel  Normalizes by standard deviation
%
%   newthis = equalizeVarPerChannel(this) equalizes each channel such
%   that the second moment about the mean equals 1, E((x-E(x))^2) = 1
%
%   Inputs:
%       this - labTimeSeries object
%
%   Outputs:
%       newthis - normalized labTimeSeries
%
%   See also: equalizeEnergyPerChannel, demean

newthis = this;
newthis.Data = bsxfun(@rdivide, this.Data, sqrt(nanvar(this.Data, [], 1)));
end

