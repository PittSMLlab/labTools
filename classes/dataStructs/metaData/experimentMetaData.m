classdef experimentMetaData
%experimentMetaData   Information describing the experiment as a whole.
%
%experimentMetaData Properties:
%   ID - string containing the group that the subject belongs to (i.e. the
%   study protocol)
%   date - labDate object containing the date of the experiment
%   experimenter - string with the person(s) who ran the experiment
%   observations - string with overall study observations (observations for individual
%   trials are stored in trailMetaData class objects)
%   conditionName - cell array of strings contatining labels given to each condition of the experiment
%   conditionDescription - cell array of strings contatining a detailed description of each condition.
%   (Contains information such as belt speeds, number of steps, belt ratio, etc.)
%   trailsInCondition - cell array of numbers matching condition number to
%   trial numbers
%   Ntrials - total number of trials
%
%experimentMetaData Methods:
%   getCondLstPerTrial - returns list of condition numbers for each trial
%   getConditionIdxsFromName - returns the condition number for conditions with a
%   similar name to the string(s) entered.
%
%See also: labDate
    
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
            this.ID=ID;           
            if nargin>1
                this.date=date;
            end
            if nargin>2
                this.experimenter=experimenter;
            end            
            if nargin>3
                this.observations=obs;
            end      
            if nargin>4
                this.conditionName=conds;
            end
            if nargin>5 
                this.conditionDescription=desc;
            end            
            if nargin>6                
                this.trialsInCondition=trialLst;
            end
            if nargin>7
                this.Ntrials=Ntrials; 
            end            
        end
        
        %% Setters
        function this=set.ID(this,ID)
            if isa(ID,'char') %&& nargin>0
                this.ID=ID; %Mandatory field, needs to be string
            elseif isempty(ID) %|| nargin==0
                this.ID='';
                %disp('Warning: creating emtpy ID field.')
            else
                ME=MException('experimentMetaData:Constructor','ID is not a string.');
                throw(ME);
            end 
        end        
        function this=set.date(this,date)
            if isa(date,'labDate')
                this.date=date;
            else
                ME=MException('experimentMetaData:Constructor','date is not labDate object.');
                throw(ME);
            end                           
        end
        function this=set.experimenter(this,experimenter)
            if isa(experimenter,'char');
                this.experimenter=experimenter;
            else
                ME=MException('experimentMetaData:Constructor','experimenter is not a string.');
                throw(ME);
            end
        end
        function this=set.observations(this,obs)
            if isa(obs,'char')
                this.observations=obs;
            else
                ME=MException('experimentMetaData:Constructor','observations is not a string.');
                throw(ME);
            end
        end
        function this=set.conditionName(this,conds)
            if ~isempty(conds) && isa(conds,'cell')
               this.conditionName=conds; 
            end
        end
        function this=set.conditionDescription(this,desc)
            if ~isempty(desc) && isa(desc,'cell')
               this.conditionDescription=desc; 
            end
        end
        function this=set.trialsInCondition(this,trialLst)
            %Must be cell of doubles
            if ~isempty(trialLst) && isa(trialLst,'cell')
            %Check that no trial is repeated
                aux=cell2mat(trialLst);
                aux2=unique(aux);
                for i=1:length(aux2)
                   a=find(aux==aux2(i)); 
                   if numel(a)>1
                       ME=MException('experimentMetaData:Constructor',['Trial ' num2str(aux2(i)) ' is listed as part of more than one condition.']);
                       throw(ME)
                   end
                end
                this.trialsInCondition=trialLst;
            end
        end
        function this=set.Ntrials(this,Ntrials)
            if isa(Ntrials,'double')
                this.Ntrials=Ntrials;
            end
        end
        
        %% Other methods
        function condLst=getCondLstPerTrial(this)
           %getCondLstPerTrial  Returns a vector with length equal to the
           %number of trials in the experiment and with values equal to the
           %condition number for each trial.
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
            %ConditionNames should be a cell array containing a string or 
            %another cell array of strings in each of its cells. 
            %E.g. conditionNames={'Base','Adap',{'Post','wash'}}
            if isa(conditionNames,'char')
                conditionNames={conditionNames};
            end
            nConds=length(conditionNames); 
            conditionIdxs=NaN(nConds,1);
            for i=1:nConds
                %First: find if there is a condition with a
                %similar name to the one given
                clear condName
                if iscell(conditionNames{i})
                    for j=1:length(conditionNames{i})
                        condName{j}=lower(conditionNames{i}{j});
                    end
                else
                    condName{1}=lower(conditionNames{i}); %Lower case
                end
                aux=this.conditionName;
                aux(cellfun(@isempty,aux))={''};
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
        
        function trialNums=getTrialsInCondition(this,conditionNames)
            conditionIdx=this.getConditionIdxsFromName(conditionNames);
            trialNums=cell2mat(this.trialsInCondition(conditionIdx));
        end
        
        function this=replaceConditionNames(this,currentName,newName)
            %Looks for conditions whose name match the options in
            %currentName & changes them to newName
            
           %Check currentName and newName are cell arrays of same length
           conditionIdxs=this.getConditionIdxsFromName(currentName);
           %this.conditionName(conditionIdxs)=newName;
           for i=1:length(currentName)
               if ~isnan(conditionIdxs(i))
                    this.conditionName{conditionIdxs(i)}=newName{i};
               end
           end
        end
    end
    
end

