function Subs = makeSMatrix

Subs=struct;
%find all files in pwd
files=what('./'); 
fileList=files.mat;


for i=1:length(fileList)
    %find files in pwd that are (Subject)param.mat files
    aux1=strfind(lower(fileList{i}),'params');
    if ~isempty(aux1)
        subID=fileList{i}(1:(aux1-1));
        %subID=adaptData.subData.ID; %I think this is more appropriate.-Pablo
        load(fileList{i});        
        subAge=adaptData.subData.age;
        expDate=adaptData.metaData.date;
        experimenter=adaptData.metaData.experimenter;
        obs=adaptData.metaData.observations;
        gender=adaptData.subData.sex;
        ht=adaptData.subData.height;
        wt=adaptData.subData.weight;
        fileName=fileList{i};
        %get group
        group=adaptData.metaData.ID;
        abrevGroup=group(ismember(group,['A':'Z' 'a':'z'])); %remove non-alphabetic characters
        if isempty(abrevGroup)
            abrevGroup='NoDescription';
            group = '(empty)';
        end
%         spaces=find(group==' ');
%         abrevGroup=group(spaces+1);%         
%         abrevGroup=[group(1) abrevGroup];
        %get conditions
        conditions=adaptData.metaData.conditionName;
        conditions=conditions(~cellfun('isempty',conditions));
        
        if isfield(Subs,abrevGroup)
            Subs.(abrevGroup).IDs(end+1,:)={subID,gender,subAge,ht,wt,expDate,experimenter,obs,fileName};
            Subs.(abrevGroup).(subID)=adaptData;
            if isfield(Subs.(abrevGroup),'conditions')
                %check if current subject had conditions other than the rest
                for c=1:length(conditions)
                    if ~ismember(conditions(c),Subs.(abrevGroup).conditions)
                        %Subs.(abrevGroup).conditions{end+1}=conditions{c};
                        disp(['Warning: ' subID ' performed ' conditions{c} ', but it was not perfomred by all subjects in ' group '.'])
                    end                    
                end
                %check if current subject didn't have a condition that the rest had
                for c=1:length(Subs.(abrevGroup).conditions)
                    if ~ismember(Subs.(abrevGroup).conditions(c),conditions) && ~isempty(Subs.(abrevGroup).conditions{c})                                          
                        disp(['Warning: ' subID ' did not perform ' Subs.(abrevGroup).conditions{c}, '.'])
                        Subs.(abrevGroup).conditions{c}='';
                    end                    
                end
                %refresh conditions by removing empty cells
                Subs.(abrevGroup).conditions=Subs.(abrevGroup).conditions(~cellfun('isempty',Subs.(abrevGroup).conditions));
            end
        else
            Subs.(abrevGroup).IDs(1,:)={subID,gender,subAge,ht,wt,expDate,experimenter,obs,fileName};            
            Subs.(abrevGroup).conditions=conditions;
            Subs.(abrevGroup).(subID)=adaptData;            
            
        end       
    end
end%MAKESMATRIX Build a subject matrix struct from params.mat files in the
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
