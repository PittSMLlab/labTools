        %subID=adaptData.subData.ID; %I think this is more appropriate.-Pablo
function Subs = makeSMatrix
%MAKESMATRIX Build a subject matrix struct from params.mat files in the
% current folder.
%
%   Scans the current working directory for *params.mat files, loads
% each adaptData variable, and organises subjects by group into a
% hierarchical Subs struct. Warns when a subject's condition list
% differs from the rest of the group.
%
% Inputs:
%   None
%
% Outputs:
%   Subs - Struct with one field per group (named by abbreviated group
%          string from adaptData.metaData.ID). Each group field has:
%            IDs        - N×9 cell array: subID, sex, age, height,
%                         weight, date, experimenter, obs, filename
%            conditions - cell array of condition names
%            (subID)    - adaptData struct for each subject
%
% Toolbox Dependencies: None
%
% See also MAKESMATRIXV2, GETRESULTSSMART.

Subs  = struct;
files = what('./');
fileList = files.mat;

for ii = 1:length(fileList)
    aux1 = strfind(lower(fileList{ii}), 'params');
    if ~isempty(aux1)
        subID        = fileList{ii}(1:(aux1 - 1));
        load(fileList{ii});
        subAge       = adaptData.subData.age;
        expDate      = adaptData.metaData.date;
        experimenter = adaptData.metaData.experimenter;
        obs          = adaptData.metaData.observations;
        gender       = adaptData.subData.sex;
        ht           = adaptData.subData.height;
        wt           = adaptData.subData.weight;
        fileName     = fileList{ii};

        group      = adaptData.metaData.ID;
        abrevGroup = group(ismember(group, ['A':'Z' 'a':'z']));
        if isempty(abrevGroup)
            abrevGroup = 'NoDescription';
            group      = '(empty)';
        end

        conditions = adaptData.metaData.conditionName;
        conditions = conditions(~cellfun('isempty', conditions));

        if isfield(Subs, abrevGroup)
            Subs.(abrevGroup).IDs(end+1, :) = ...
                {subID, gender, subAge, ht, wt, ...
                 expDate, experimenter, obs, fileName};
            Subs.(abrevGroup).(subID) = adaptData;
            if isfield(Subs.(abrevGroup), 'conditions')
                for cc = 1:length(conditions)
                    if ~ismember(conditions(cc), ...
                            Subs.(abrevGroup).conditions)
                        disp(['Warning: ' subID ' performed ' ...
                            conditions{cc} ', but it was not ' ...
                            'performed by all subjects in ' group '.'])
                    end
                end
                for cc = 1:length(Subs.(abrevGroup).conditions)
                    if ~ismember( ...
                            Subs.(abrevGroup).conditions(cc), ...
                            conditions) && ...
                            ~isempty(Subs.(abrevGroup).conditions{cc})
                        disp(['Warning: ' subID ' did not perform ' ...
                            Subs.(abrevGroup).conditions{cc} '.'])
                        Subs.(abrevGroup).conditions{cc} = '';
                    end
                end
                Subs.(abrevGroup).conditions = ...
                    Subs.(abrevGroup).conditions( ...
                        ~cellfun('isempty', ...
                            Subs.(abrevGroup).conditions));
            end
        else
            Subs.(abrevGroup).IDs(1, :) = ...
                {subID, gender, subAge, ht, wt, ...
                 expDate, experimenter, obs, fileName};
            Subs.(abrevGroup).conditions   = conditions;
            Subs.(abrevGroup).(subID)      = adaptData;
        end
    end
end

end
