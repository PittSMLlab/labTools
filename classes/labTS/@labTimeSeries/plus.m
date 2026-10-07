function newThis = plus(this, other)
%PLUS Adds two labTimeSeries.
%
%   newThis = plus(this, other) adds two labTimeSeries element-wise
%
% Inputs:
%   this  - labTimeSeries object
%   other - labTimeSeries object with same time vector
%
% Outputs:
%   newThis - sum of two timeseries
%
% Toolbox Dependencies: None
%
% See also MINUS, TIMES.

M = size(this.Data, 2);
if size(other.Data, 2) ~= M
    error('labTS:plus', 'Inconsistent sizes for sum');
end
newLabels = cell(size(this.labels));
for ii = 1:M
    newLabels{ii} = ['(' this.labels{ii} ' + ' other.labels{ii} ')'];
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

