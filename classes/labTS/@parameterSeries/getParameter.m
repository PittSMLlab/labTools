function [data, auxLabel] = getParameter(this, label)
%GETPARAMETER Retrieves parameter data.
%
%   [data, auxLabel] = getParameter(this, label) returns data for specified
% parameter(s)
%
% Inputs:
%   this  - parameterSeries object
%   label - string or cell array of parameter name(s)
%
% Outputs:
%   data     - matrix of parameter values
%   auxLabel - cell array of parameter labels
%
%   Note: Backwards compatibility wrapper
%
% Toolbox Dependencies: None
%
% See also GETDATAASVECTOR, ISAPARAMETER.

[data, ~, auxLabel] = this.getDataAsVector(label);
end

