classdef groupAdaptationData
    %groupAdaptaitonData  contains the adaptation data objects for a group
    %of subjects
    %
    %groupAdaptaitonData properties:
    %   ID - cell array of strings listing subject ID's in group
    %   adaptData - cell array of adaptationData objects
    %
    %groupAdaptaitonData Methods:
    %
    %See also: experimentMetaData, subjectData, adaptationData
    
    properties
        ID %cell array of strings listing subject ID's in group
        adaptData % cell array of adaptationData objects
    end
    
    properties (Dependent)
        
    end
    
    methods
        %% Constructor
        function this=groupAdaptationData(ID,data)
            if nargin>1 && length(ID)==length(data)
                boolFlag=false(1,length(data));
                for i=1:length(data)
                    boolFlag(i)=isa(data{i},'adaptationData');
                end
                if all(boolFlag)
                    this.ID=ID;
                    this.adaptData=data;
                end
            end
        end
        
        %% Other Functions
        
        function conditions = getCommonConditions(this,subs)
            if nargin<2 || isempty(subs)
                subs=1:length(this.ID);
            else
                if isa(subs,'cell')
                    subs=find(ismember(this.ID,subs));
                end
            end
            conditions=this.adaptData{subs(1)}.metaData.conditionName;
            conditions=conditions(~cellfun('isempty',conditions));
            for s=2:length(subs)
                conds=this.adaptData{subs(s)}.metaData.conditionName;
                conds=conds(~cellfun('isempty',conds));
                %check if current subject had conditions other than the rest
                for c=1:length(conds)                    
                    if ~ismember(conds(c),conditions)
                        %Subs.(abrevGroup).conditions{end+1}=conditions{c};
                        disp(['Warning: ' this.ID{subs(s)} ' performed ' conds{c} ', but it was not perfomred by all subjects.'])
                    end                    
                end
                %check if current subject didn't have a condition that the rest had
                for c=1:length(conditions)
                    if ~ismember(conditions(c),conds) && ~isempty(conditions{c})
                        disp(['Warning: ' this.ID{subs(s)} ' did not perform ' conditions{c} ' but ' strjoin(this.ID(subs(1:s-1)),', ') ' did.'])
                        conditions{c}='';
                    end
                end
                %refresh conditions by removing empty cells (if you remove
                %them above, the for loop doesn't work any more)
                conditions=conditions(~cellfun('isempty',conditions));
            end
        end
        
        function [parameters,descriptions] = getCommonParameters(this,subs)
            if nargin<2 || isempty(subs)
                subs=1:length(this.ID);
            else
                if isa(subs,'cell')
                    subs=find(ismember(this.ID,subs));
                end
            end
            [parameters,descriptions]=this.adaptData{1}.getParameterList;
            for s=2:length(subs)
                params=this.adaptData{subs(s)}.getParameterList;
                %check if current subject had parameters other than the rest
                for p=1:length(params)                    
                    if ~ismember(params(p),parameters)
                        disp(['Warning: ' this.ID{subs(s)} ' has ' params{p} ', but it was not computed for all subjects.'])
                    end                    
                end
                %check if current subject didn't have a parameter that the rest had
                for p=1:length(parameters)
                    if ~ismember(parameters(p),params)
                        disp(['Warning: '  parameters{p} 'was not computed for' this.ID{subs(s)} ', but was for ' strjoin(this.ID(1:subs(1:s-1)),', ') '.'])
                        parameters{p}='';                        
                    end
                end
                %refresh parameters by removing empty cells (if you remove
                %them above, the for loop doesn't work any more)
                inds=find(~cellfun('isempty',parameters));
                parameters=parameters(inds);
                descriptions=descriptions(inds);
            end
        end
        
        function newThis=cat(this,other)
            newThis=groupAdaptationData([this.ID other.ID],[this.adaptData other.adaptData]);            
        end
        
        function data=getAdaptData(this,subID)
           subInd=find(ismember(subID,this.ID));
           if subInd ~= 0
               data = this.adaptData{subInd};
           else
               data =[];
           end
        end
        
        function [data]=getGroupedData(this,label,conds,removeBiasFlag,numberOfStrides,exemptFirst,exemptLast)
            data=cell(size(numberOfStrides));
            nConds=length(conds);
            nLabs=length(label);
            for subject=1:length(this.adaptData) %Getting data for each subject in the list
                data_aux=getEarlyLateData_v2(this.adaptData{subject},label,conds,removeBiasFlag,numberOfStrides,exemptLast,exemptFirst);
                for i=1:length(data)
                    data{i}(1:nConds,1:abs(numberOfStrides(i)),1:nLabs,subject)=data_aux{i};
                end
            %Indexes in data correspond to: condition, stride,label,subject
            end
        end
    end
end

