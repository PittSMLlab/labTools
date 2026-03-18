function [newTS, auxLabel] = getDataAsTS(this, label)
%getDataAsTS  Returns labTimeSeries (override)
%
%   [newTS, auxLabel] = getDataAsTS(this, label) returns data as
%   labTimeSeries
%
%   Inputs:
%       this - orientedLabTimeSeries object
%       label - string or cell array of label(s) to extract
%
%   Outputs:
%       newTS - labTimeSeries with requested data
%       auxLabel - cell array of labels
%
%   Note: I think this is unnecessary - default behavior if function is
%         not defined in inheriting class is to call the superclass'
%         method
%
%   See also: labTimeSeries/getDataAsTS, getDataAsOTS

[newTS, auxLabel] = getDataAsTS@labTimeSeries(this, label);
end

