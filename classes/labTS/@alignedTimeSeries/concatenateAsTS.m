function newThis = concatenateAsTS(this)
%concatenateAsTS  Concatenates strides sequentially
%
%   newThis = concatenateAsTS(this) concatenates strides one after
%   another in time, returning a single labTimeSeries
%
%   Inputs:
%       this - alignedTimeSeries object
%
%   Outputs:
%       newThis - labTimeSeries with strides concatenated in time
%
%   See also: catStrides, castAsTS

newThis = labTimeSeries(reshape(permute(this.Data, [1, 3, 2]), ...
    [size(this.Data, 1) * size(this.Data, 3), size(this.Data, 2)]), ...
    this.Time(1), this.Time(2) - this.Time(1), this.labels);
end

