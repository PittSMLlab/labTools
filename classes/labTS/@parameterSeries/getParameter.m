function [data, auxLabel] = getParameter(this, label)
%getParameter  Retrieves parameter data
%
%   [data, auxLabel] = getParameter(this, label) returns data for
%   specified parameter(s)
%
%   Inputs:
%       this - parameterSeries object
%       label - string or cell array of parameter name(s)
%
%   Outputs:
%       data - matrix of parameter values
%       auxLabel - cell array of parameter labels
%
%   Note: Backwards compatibility wrapper
%
%   See also: getDataAsVector, isaParameter

[data, ~, auxLabel] = this.getDataAsVector(label);
end

