function newThis = plus(this, other)
%PLUS Adds two OTS (override).
%
%   newThis = plus(this, other) adds and preserves orientedLabTimeSeries
% type with updated labels
%
% Inputs:
%   this  - orientedLabTimeSeries object
%   other - orientedLabTimeSeries to add
%
% Outputs:
%   newThis - sum as orientedLabTimeSeries
%
% Toolbox Dependencies: None
%
% See also LABTIMESERIES/PLUS, MINUS, TIMES.

newThis = plus@labTimeSeries(this, other);
tL = this.getLabelPrefix;
oL = other.getLabelPrefix;
newLabelPrefixes = cell(size(tL));
for ii = 1:length(newLabelPrefixes)
    newLabelPrefixes{ii} = ['(' tL{ii} ' + ' oL{ii} ')'];
end
newLabels = orientedLabTimeSeries.addLabelSuffix(newLabelPrefixes);
newThis = orientedLabTimeSeries(newThis.Data, newThis.Time(1), ...
    newThis.sampPeriod, newLabels, this.orientation);
end

