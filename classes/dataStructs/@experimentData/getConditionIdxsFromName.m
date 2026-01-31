function conditionIdxs = getConditionIdxsFromName(this, ...
    conditionNames)
%getConditionIdxsFromName  Gets condition indices from names
%
%   conditionIdxs = getConditionIdxsFromName(this, conditionNames)
%   looks for conditions with names similar to those specified
%
%   Inputs:
%       this - experimentData object
%       conditionNames - cell array containing strings or nested cell
%                        arrays (e.g., {'Base', 'Adap', {'Post',
%                        'wash'}})
%
%   Outputs:
%       conditionIdxs - vector of condition indices
%
%   See also: experimentMetaData/getConditionIdxsFromName

% Looks for condition names that are similar to the ones given in
% conditionNames and returns the corresponding condition idx
% ConditionNames should be a cell array containing a string or another
% cell array of strings in each of its cells. E.g. conditionNames =
% {'Base', 'Adap', {'Post', 'wash'}}
conditionIdxs = ...
    this.metaData.getConditionIdxsFromName(conditionNames);
end

