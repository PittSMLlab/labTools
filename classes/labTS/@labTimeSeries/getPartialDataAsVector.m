function [data, time, auxLabel] = ...
    getPartialDataAsVector(this, label, t0, t1)
%getPartialDataAsVector  Returns data for labels and time range
%
%   [data, time, auxLabel] = getPartialDataAsVector(this, label, t0,
%   t1) extracts data for specified labels within time range [t0, t1)
%
%   Inputs:
%       this - labTimeSeries object
%       label - string or cell array of label(s)
%       t0 - start time
%       t1 - end time
%
%   Outputs:
%       data - data matrix for requested labels and time range
%       time - time vector
%       auxLabel - cell array of labels
%
%   See also: getDataAsVector, split

newThis = split(this.getDataAsTS(label), t0, t1);
[data, time, auxLabel] = getDataAsVector(newThis, label);
end

