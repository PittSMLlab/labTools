function newTS = getDataAsTS(this, label)
%getDataAsTS  Returns processedEMGTimeSeries with specified label(s)
%
%   newTS = getDataAsTS(this, label) creates a new
%   processedEMGTimeSeries containing only the specified label(s),
%   preserving processing information
%
%   Inputs:
%       this - processedEMGTimeSeries object
%       label - string or cell array of label(s) to extract
%
%   Outputs:
%       newTS - new processedEMGTimeSeries with requested data
%
%   See also: labTimeSeries/getDataAsTS, getDataAsVector

[data, time, auxLabel] = getDataAsVector(this, label);
newTS = processedEMGTimeSeries( ...
    data, time(1), this.sampPeriod, auxLabel, this.processingInfo);
end

