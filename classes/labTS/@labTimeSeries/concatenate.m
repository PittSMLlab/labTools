function newThis = concatenate(this, other)
%concatenate  Merges two timeseries
%
%   newThis = concatenate(this, other) concatenates data from two
%   timeseries with same time vector
%
%   Inputs:
%       this - labTimeSeries object
%       other - labTimeSeries with same time vector
%
%   Outputs:
%       newThis - concatenated labTimeSeries
%
%   See also: cat, appendData

% Check if time vectors are the same
if all(this.Time == other.Time)
    newThis = labTimeSeries([this.Data, other.Data], this.Time(1), ...
        this.sampPeriod, [this.labels(:)', other.labels(:)']);
else
    error('labTimeSeries:concatenate', ...
        'Cannot concatenate timeseries with different Time vectors.');
end
end

