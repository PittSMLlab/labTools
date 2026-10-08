function newThis = equalizeEnergyPerChannel(this)
%EQUALIZEENERGYPERCHANNEL Normalizes by RMS.
%
%   newThis = equalizeEnergyPerChannel(this) normalizes each channel by its
% RMS value across time and strides
%
% Inputs:
%   this - alignedTimeSeries object
%
% Outputs:
%   newThis - normalized alignedTimeSeries
%
% Toolbox Dependencies: None
%
% See also DEMEAN, LABTIMESERIES/EQUALIZEENERGYPERCHANNEL.

newThis = this;
newThis.Data = bsxfun(@rdivide, newThis.Data, ...
    sqrt(mean(mean(this.Data.^2, 3), 1)));
end

