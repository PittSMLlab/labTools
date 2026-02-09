function newThis = minus(this, other)
%minus  Subtracts two labTimeSeries
%
%   newThis = minus(this, other) subtracts other from this element-wise
%
%   Inputs:
%       this - labTimeSeries object
%       other - labTimeSeries object with same time vector
%
%   Outputs:
%       newThis - difference of two timeseries
%
%   Note: Could be deprecated in favor of: newThis = this + -1*other;
%
%   See also: plus, times

% Could be deprecated in favor of: newThis = this + -1*other;
M = size(this.Data, 2);
for i = 1:M
    newLabels{i} = ['(' this.labels{i} ' - ' other.labels{i} ')'];
end
if abs(this.Time(1) - other.Time(1)) < eps && ...
        abs(this.sampPeriod - other.sampPeriod) < eps && ...
        length(this.labels) == length(other.labels)
    newThis = labTimeSeries( ...
        this.Data - other.Data, this.Time(1), this.sampPeriod, newLabels);
end
end

