function newthis = equalizeVarPerChannel(this)
%EQUALIZEVARPERCHANNEL Normalizes by standard deviation.
%
%   newthis = equalizeVarPerChannel(this) equalizes each channel such that
% the second moment about the mean equals 1, E((x-E(x))^2) = 1
%
% Inputs:
%   this - labTimeSeries object
%
% Outputs:
%   newthis - normalized labTimeSeries
%
% Toolbox Dependencies: None
%
% See also EQUALIZEENERGYPERCHANNEL, DEMEAN.

newthis = this;
newthis.Data = bsxfun(@rdivide, this.Data, ...
    sqrt(var(this.Data, [], 1, 'omitnan')));
end

