function [newTS, auxLabel] = getDataAsTS(this, label)
%getDataAsTS  Returns new labTimeSeries with given label(s)
%
%   [newTS, auxLabel] = getDataAsTS(this, label) creates a new
%   labTimeSeries containing only the specified label(s)
%
%   Inputs:
%       this - labTimeSeries object
%       label - string or cell array of label(s) to extract
%
%   Outputs:
%       newTS - new labTimeSeries with requested data
%       auxLabel - cell array of labels in new timeseries
%
%   See also: getDataAsVector, split

[data, time, auxLabel] = getDataAsVector(this, label);
newTS = labTimeSeries(data, time(1), this.sampPeriod, auxLabel);
end

