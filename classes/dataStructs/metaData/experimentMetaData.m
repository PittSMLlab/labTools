classdef experimentMetaData
    %Information concerning/describing the experiment as a whole.
    %
    %   experimentMetaData(ID,date,experimenter,obs,conds,trialLst,NTrials)
    %   ID - the study protocol
    %   date - the date of the experiment
    %   experimenter - the person(s) who ran the experiment
    %   obs - overall observations
    %   conds - decriptions of each condition
    %   trialLst - a cell with the trial numbers for each condition
    %   Ntrials - total number of trials
    
    properties
        ID;
        date=labDate.default; %labDate object
        experimenter='';        
        observations='';
        conditionName={};
        conditionDescription={};
        trialsInCondition={};
        Ntrials=[];        
    end   
   
    
    methods
        %Constructor
        function this=experimentMetaData(ID,date,experimenter,obs,conds,desc,trialLst,Ntrials)
            if isa(ID,'char') %&& nargin>0
                this.ID=ID; %Mandatory field, needs to be string
            elseif isempty(ID) %|| nargin==0
                this.ID='';
                %disp('Warning: creating emtpy ID field.')
            else
                ME=MException('labMetaData:Constructor','ID is not a string.');
                throw(ME);
            end            
            if nargin>1 && isa(date,'labDate');
                this.date=date;
            end
            if nargin>2 && isa(experimenter,'char');
                this.experimenter=experimenter;
            end            
            if nargin>3 && isa(obs,'char')
                this.observations=obs;
            end      
            if nargin>4 || ~isempty(conds)
                this.conditionName=conds;
            end
            if nargin>5 || ~isempty(desc)
                this.conditionDescription=desc;
            end            
            if nargin>6 || ~isempty(trialLst)
                %Check that no trial is repeatede
                aux=cell2mat(trialLst);
                aux2=unique(aux);
                for i=1:length(aux2)
                   a=find(aux==aux2(i)); 
                   if numel(a)>1
                       ME=MException('experimentMetaData:Constructor',['Trial ' num2str(aux2(i)) ' is listed as part of more than one condition.']);
                       throw(ME)
                   end
                end
                this.trialsInCondition=trialLst; %Must be cell of doubles
            end
            if nargin>7 && isa(Ntrials,'double')
                this.Ntrials=Ntrials; 
            end            
        end
        
        function condLst=getCondLstPerTrial(this)
           for i=1:this.Ntrials
               for cond=1:length(this.trialsInCondition)
                    k=find(i==this.trialsInCondition{cond},1);
                    if ~isempty(k)
                        break;
                    end
               end
               if isempty(k)
                   condLst(i)=NaN;
               else
                   condLst(i)=cond;
               end
           end 
        end
        
        function conditionIdxs=getConditionIdxsFromName(this,conditionNames)
            %Looks for condition names that are similar to the ones given
            %in conditionNames and returns the corresponding condition idx
            %ConditionNames should be a cell array containing a string or another cell array of strings in each of its cells. E.g. conditionNames={'Base','Adap',{'Post','wash'}}
            if isa(conditionNames,'char')
                conditionNames={conditionNames};
            end
            nConds=length(conditionNames); 
            conds=conditionNames;
            conditionIdxs=NaN(nConds,1);
            for i=1:nConds
                %First: find if there is a condition with a
                %similar name to the one given
                clear condName
                if iscell(conds{i})
                    for j=1:length(conds{i})
                        condName{j}=lower(conds{i}{j});
                    end
                else
                    condName{1}=lower(conds{i}); %Lower case
                end
                aux=this.conditionName;
                aux(cellfun(@isempty,aux))='';
                allConds=lower(aux);
                condIdx=[];
                j=0;
                while isempty(condIdx) && j<length(condName)
                    j=j+1;
                    condIdx=find(~cellfun(@isempty,strfind(allConds,condName{j})),1,'first');
                end
                if ~isempty(condIdx)
                    conditionIdxs(i)=condIdx;
                end
            end
        end
    end
    
end

