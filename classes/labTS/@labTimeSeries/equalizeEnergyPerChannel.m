function newthis = equalizeEnergyPerChannel(this)
%equalizeEnergyPerChannel  Normalizes by RMS
%
%   newthis = equalizeEnergyPerChannel(this) equalizes each channel
%   such that the second moment of each channel equals 1, E(x^2) = 1
%
%   Inputs:
%       this - labTimeSeries object
%
%   Outputs:
%       newthis - normalized labTimeSeries
%
%   See also: equalizeVarPerChannel, demean

newthis = this;
newthis.Data = bsxfun(@rdivide, this.Data, sqrt(nanmean(this.Data.^2, 1)));
end

