function newThis = catStrides(this)
%CATSTRIDES Concatenates strides into labTimeSeries.
%
%   newThis = catStrides(this) concatenates all strides sequentially into a
% single labTimeSeries
%
% Inputs:
%   this - alignedTimeSeries object
%
% Outputs:
%   newThis - labTimeSeries with concatenated stride data
%
% Toolbox Dependencies: None
%
% See also CONCATENATEASTS, CASTASTS.

auxData = permute(this.Data, [2, 1, 3]);
newThis = labTimeSeries(auxData(:, :)', this.Time(1), ...
    this.Time(2) - this.Time(1), this.labels);
end

