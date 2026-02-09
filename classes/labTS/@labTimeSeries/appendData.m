function newThis = appendData(this, newData, newLabels)
%appendData  Adds more data as new labels
%
%   newThis = appendData(this, newData, newLabels) concatenates new
%   data columns to the timeseries
%
%   Inputs:
%       this - labTimeSeries object
%       newData - matrix of new data (same number of rows as existing)
%       newLabels - cell array of labels for new data
%
%   Outputs:
%       newThis - labTimeSeries with appended data
%
%   Note: For backward compatibility
%
%   See also: cat, concatenate

% For back compatibility
other = labTimeSeries(newData, newLabels, this.Time(1), this.sampPeriod);
newThis = cat(this, other);
end

