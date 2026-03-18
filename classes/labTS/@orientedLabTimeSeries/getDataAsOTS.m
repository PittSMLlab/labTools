function newThis = getDataAsOTS(this, label)
%getDataAsOTS  Returns subset as orientedLabTimeSeries
%
%   newThis = getDataAsOTS(this) returns all data as OTS
%
%   newThis = getDataAsOTS(this, label) returns data for specified
%   marker prefixes
%
%   Inputs:
%       this - orientedLabTimeSeries object
%       label - cell array of marker prefixes (optional, default: all)
%
%   Outputs:
%       newThis - orientedLabTimeSeries with requested data
%
%   See also: getOrientedData, getDataAsTS

if nargin < 2 || isempty(label)
    label = [];
end
[data, label] = getOrientedData(this, label);
data = permute(data, [1, 3, 2]);
newThis = orientedLabTimeSeries(data(:, :), this.Time(1), ...
    this.sampPeriod, ...
    orientedLabTimeSeries.addLabelSuffix(label), this.orientation);
end

