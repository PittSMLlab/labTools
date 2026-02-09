function [data, auxLabel] = getParameter(this, label)
%getParameter  Retrieves data for specified parameter(s)
%
%   [data, auxLabel] = getParameter(this, label) returns parameter
%   data for specified label(s)
%
%   Inputs:
%       this - paramData object
%       label - string or cell array of parameter name(s) to retrieve
%
%   Outputs:
%       data - matrix of parameter values for requested parameter(s)
%       auxLabel - cell array of labels for returned parameters
%
%   See also: isaParameter, isaLabel

if isa(label, 'char')
    auxLabel = {label};
else
    auxLabel = label;
end
[boolFlag, labelIdx] = this.isaParameter(auxLabel);
data = this.Data(:, labelIdx(boolFlag == 1));
auxLabel = this.labels(labelIdx(boolFlag == 1));
end

