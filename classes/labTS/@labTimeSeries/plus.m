function newThis = plus(this, other)
%plus  Adds two labTimeSeries
%
%   newThis = plus(this, other) adds two labTimeSeries element-wise
%
%   Inputs:
%       this - labTimeSeries object
%       other - labTimeSeries object with same time vector
%
%   Outputs:
%       newThis - sum of two timeseries
%
%   See also: minus, times

M = size(this.Data, 2);
if size(other.Data, 2) ~= M
    error('labTS:plus', 'Inconsistent sizes for sum');
end
newLabels = cell(size(this.labels));
for i = 1:M
    newLabels{i} = ['(' this.labels{i} ' + ' other.labels{i} ')'];
end
if abs(this.Time(1) - other.Time(1)) < eps && ...
        abs(this.sampPeriod - other.sampPeriod) < eps && ...
        length(this.labels) == length(other.labels)
    newThis = labTimeSeries( ...
        this.Data + other.Data, this.Time(1), this.sampPeriod, newLabels);
else
    error('labTS:plus', ...
        'Cannot add timeseries with different time vectors');
end
end

