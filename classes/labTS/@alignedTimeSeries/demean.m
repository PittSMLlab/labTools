function newThis = demean(this)
%DEMEAN Removes mean.
%
%   newThis = demean(this) subtracts the mean (across strides) from each
% channel
%
% Inputs:
%   this - alignedTimeSeries object
%
% Outputs:
%   newThis - demeaned alignedTimeSeries
%
% Toolbox Dependencies: None
%
% See also MEAN, EQUALIZEENERGYPERCHANNEL.

newThis = this;
newThis.Data = bsxfun(@minus, this.Data, this.mean.Data);
end

