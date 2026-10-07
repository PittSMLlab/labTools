function newthis = demean(this)
%DEMEAN Removes mean from each channel.
%
%   newthis = demean(this) subtracts the mean from each channel
%
% Inputs:
%   this - labTimeSeries object
%
% Outputs:
%   newthis - demeaned labTimeSeries
%
% Toolbox Dependencies: None
%
% See also EQUALIZEVARPERCHANNEL, EQUALIZEENERGYPERCHANNEL.

newthis = this;
newthis.Data = bsxfun(@minus, this.Data, mean(this.Data, 'omitnan'));
end

