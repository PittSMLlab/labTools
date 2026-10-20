function [baseConds, trialTypes] = getBaseConditions(this, trialType)
%GETBASECONDITIONS Find the baseline condition of each trial type.
%
%   Looks up, for every trial type, the condition whose name matches
% 'base' and returns the first match. Errors if a trial type has no
% baseline condition; warns and lists the candidates if it has several.
%
% Inputs:
%   this      - adaptationData object
%   trialType - (optional) cell array of trial type names; defaults to
%               every non-empty type in this.trialTypes()
%
% Outputs:
%   baseConds  - cell array with one baseline condition name per type
%   trialTypes - cell array of the trial types that were searched
%
% Toolbox Dependencies: None
%
% See also ADAPTATIONDATA, GETBASEDATA.

if nargin < 2
    % trialTypes() guesses the types for objects saved without them
    trialTypes = this.trialTypes();
    types      = unique(trialTypes(~cellfun(@isempty, trialTypes)));
else
    types = trialType;
end

for itype = 1:length(types)
    allTrials = find(strcmp(this.trialTypes(), types{itype}));
    baseCond = this.metaData.getConditionsThatMatch('base', ...
        types{itype});
    if isempty(baseCond)
        error('No base conditions were found. Exiting.')
    end
    if length(baseCond) > 1
        warning(['More than one base condition was provided/found. ' ...
            'Using only the first one.'])
        disp('List of baseline conditions provided:')
        disp(baseCond)
    end
    baseCond = baseCond{1};
    baseConds{itype} = baseCond;
end
trialTypes = types;

end
