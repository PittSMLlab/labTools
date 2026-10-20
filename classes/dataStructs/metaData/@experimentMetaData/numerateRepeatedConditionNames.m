function [newThis, change] = numerateRepeatedConditionNames(this)
%NUMERATEREPEATEDCONDITIONNAMES Adds numbers to repeated condition names.
%
%   [newThis, change] = numerateRepeatedConditionNames(this) finds any
% repeated condition names and appends sequential numbers to make
% them unique
%
% Inputs:
%   this - experimentMetaData object
%
% Outputs:
%   newThis - experimentMetaData object with unique condition names
%   change  - logical flag indicating if any changes were made
%
% NOTE: This function should (almost) never be used. metaData no longer
%       allows repeated condition names, so this is unnecessary. However,
%       for files created before the prohibition, it may happen.
%
% Toolbox Dependencies: None
%
% See also REPLACECONDITIONNAMES, VALIDATETRIALSINCONDITION.

aaa    = unique(this.conditionName);
change = false;
if length(aaa) < length(this.conditionName) % There are repetitions
    change = true;
    for ii = 1:length(aaa)
        aux = find(strcmpi(aaa{ii}, this.conditionName));
        if length(aux) > 1
            disp(['Found a repeated condition name ' aaa{ii}]);
            for jj = 1:length(aux)
                aaux = this.trialsInCondition{aux(jj)};
                % This queries the user for a new name:
                % disp(['Occurrence ' num2str(j) ' contains trials '
                % num2str(aaux) '.']);
                % ss = input(['Please input a new name for this
                % condition: ']);

                % This assigns a new name by adding a number:
                ss = [aaa{ii} ' ' num2str(jj)];
                this.conditionName{aux(jj)} = ss;
                disp(['Occurrence ' num2str(jj) ' contains trials ' ...
                    num2str(aaux) ', was replaced by ' ss '.']);
            end
        end
    end
end
newThis = this;
end

