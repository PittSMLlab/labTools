function newThis = derivate(this)
%derivate  Differentiates timeseries (legacy)
%
%   newThis = derivate(this) computes numerical derivative and pads
%   with NaN
%
%   Inputs:
%       this - labTimeSeries object
%
%   Outputs:
%       newThis - differentiated labTimeSeries with NaN padding
%
%   Note: Kept for legacy compatibility purposes only
%
%   See also: derivative

partialThis = this.derivative;
pad = nan(1, size(this.Data, 2));
newThis = labTimeSeries([pad; partialThis.Data; pad], this.Time(1), ...
    this.sampPeriod, partialThis.labels);
end

