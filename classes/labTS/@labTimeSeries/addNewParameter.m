function [newThis, newData] = addNewParameter( ...
    this, newParamLabel, funHandle, inputParameterLabels)
%addNewParameter  Adds computed parameter from existing data
%
%   [newThis, newData] = addNewParameter(this, newParamLabel,
%   funHandle, inputParameterLabels) computes new parameter from
%   existing parameters and adds it to the timeseries
%
%   Inputs:
%       this - labTimeSeries object
%       newParamLabel - string name for new parameter
%       funHandle - function handle with N input variables
%       inputParameterLabels - cell array of N parameter labels to use
%                              as inputs
%
%   Outputs:
%       newThis - labTimeSeries with new parameter added
%       newData - computed data for new parameter
%
%   Example:
%       See example in parameterSeries
%
%   See also: computeNewParameter, appendData

newData = computeNewParameter( ...
    this, newParamLabel, funHandle, inputParameterLabels);
newThis = appendData(this, newData, {newParamLabel});
end

