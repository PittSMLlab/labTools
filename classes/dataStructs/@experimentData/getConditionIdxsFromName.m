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

conditionIdxs = this.metaData.getConditionIdxsFromName(conditionNames);
end

