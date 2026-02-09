function newData = computeNewParameter( ...
    this, newParamLabel, funHandle, inputParameterLabels)
%computeNewParameter  Computes new parameter without adding to data
%
%   newData = computeNewParameter(this, newParamLabel, funHandle,
%   inputParameterLabels) computes new parameter from existing
%   parameters
%
%   Inputs:
%       this - labTimeSeries object
%       newParamLabel - string name for new parameter
%       funHandle - function handle with N input variables
%       inputParameterLabels - cell array of N parameter labels to use
%                              as inputs
%
%   Outputs:
%       newData - computed data for new parameter
%
%   Note: TODO - support many new parameters together, as long as
%         they use the same funHandle, with inputParameterLabels an NxM
%         array, where N is the size of newParamLabel (# parameters to be
%         computed). Use this change in linearStretch(this, labels,
%         rangeValues) for efficiency
%
%   See also: addNewParameter, parameterSeries

if length(inputParameterLabels) ~= nargin(funHandle)
    error('labTS:addNewParameter', ...
        ['Number of input arguments in function handle and number ' ...
        'of labels in inputParameterLabels should be the same']);
end
if compareListsFast(this.labels, newParamLabel)
    error('labTS:addNewParameter', ...
        'Cannot add parameter because it already exists');
end
oldData = this.getDataAsVector(inputParameterLabels);
str = '(';
for i = 1:size(oldData, 2)
    str = [str 'oldData(:,' num2str(i) '),'];
end
str(end) = ')'; % Replacing last comma with parenthesis
% Isn't there a way to do this without eval?
eval(['newData = funHandle' str ';']);
end

