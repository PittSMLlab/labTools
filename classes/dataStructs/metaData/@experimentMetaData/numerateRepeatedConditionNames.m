function [newThis, change] = numerateRepeatedConditionNames(this)
%numerateRepeatedConditionNames  Adds numbers to repeated condition
%names
%
%   [newThis, change] = numerateRepeatedConditionNames(this) finds any
%   repeated condition names and appends sequential numbers to make
%   them unique
%
%   Inputs:
%       this - experimentMetaData object
%
%   Outputs:
%       newThis - experimentMetaData object with unique condition names
%       change - logical flag indicating if any changes were made
%
%   Note: This function should (almost) never be used. metaData no
%         longer allows repeated condition names, so this is
%         unnecessary. However, for files created before the
%         prohibition, it may happen.
%
%   See also: replaceConditionNames, validateTrialsInCondition

% This function should (almost) never be used. metaData no longer
% allows repeated condition names, so this is unnecessary. However, for
% files created before the prohibition, it may happen.
aaa = unique(this.conditionName);
change = false;
if length(aaa) < length(this.conditionName) % There are repetitions
    change = true;
    for i = 1:length(aaa)
        aux = find(strcmpi(aaa{i}, this.conditionName));
        if length(aux) > 1
            disp(['Found a repeated condition name ' aaa{i}]);
            for j = 1:length(aux)
                aaux = this.trialsInCondition{aux(j)};
                % This queries the user for a new name:
                % disp(['Occurrence ' num2str(j) ' contains trials '
                % num2str(aaux) '.']);
                % ss = input(['Please input a new name for this
                % condition: ']);

                % This assigns a new name by adding a number:
                ss = [aaa{i} ' ' num2str(j)];
                this.conditionName{aux(j)} = ss;
                disp(['Occurrence ' num2str(j) ' contains trials ' ...
                    num2str(aaux) ', was replaced by ' ss '.']);
            end
        end
    end
end
newThis = this;
end

