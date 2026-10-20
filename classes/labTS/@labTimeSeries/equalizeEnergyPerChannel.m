function newthis = equalizeEnergyPerChannel(this)
%EQUALIZEENERGYPERCHANNEL Normalizes by RMS.
%
%   newthis = equalizeEnergyPerChannel(this) equalizes each channel such
% that the second moment of each channel equals 1, E(x^2) = 1
%
% Inputs:
%   this - labTimeSeries object
%
% Outputs:
%   newthis - normalized labTimeSeries
%
% Toolbox Dependencies: None
%
% See also EQUALIZEVARPERCHANNEL, DEMEAN.

newthis = this;
newthis.Data = bsxfun(@rdivide, this.Data, ...
    sqrt(mean(this.Data.^2, 1, 'omitnan')));
end

