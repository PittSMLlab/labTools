classdef experimentMetaData
%experimentMetaData   Information describing the experiment as a whole.
%
%experimentMetaData Properties:
%   ID - string containing the subject ID e.g. 'OG90' or 'CGN05' 
%   date - labDate object containing the date of the experiment
%   experimenter - string, initials/name of person(s) who ran the experiment
%   observations - string with overall study observations (observations for individual
%   trials are stored in trailMetaData class objects)
%   conditionName - cell array of strings containing labels given to each condition of the experiment
%   conditionDescription - cell array of strings containing a detailed description of each condition.
%   (Contains information such as belt speeds, number of steps, belt ratio, etc.)
%   trailsInCondition - cell array of numbers (type double?) matching condition number to
%   trial numbers -- trial numbers must match up with c3d file names
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
                if length(unique(conds))<length(conds)
                    error('ExperimentMetaData:Constructor','There are repeated condition names, which is not allowed')
                elseif sum(cellfun(@(x) ~isempty(strfind(x,'TM base')),conds))>1 || sum(cellfun(@(x) ~isempty(strfind(x,'OG base')),conds))>1
                    error('ExperimentMetaData:Constructor','More than one condition name contains the string ''TM base'' or ''OG base'' which is not allowed.')
                else
                    this.conditionName=conds;
                end
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
           %Returns a vector with length equal to the
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
        
        function conditionIdxs=getConditionIdxsFromName(this,conditionNames,exactMatchesOnlyFlag,ignoreMissingNamesFlag)
            %Looks for condition names that are similar to the ones given
            %in conditionNames and returns the corresponding condition idx
            %
            %Inputs:
            %ConditionNames -- cell array containing a string or 
            %another cell array of strings in each of its cells. 
            %E.g. conditionNames={'Base','Adap',{'Post','wash'}}
            if nargin<3 || isempty(exactMatchesOnlyFlag)
                exactMatchesOnlyFlag=0; %Default behavior accepts partial matches
            end
            if nargin<4 || isempty(ignoreMissingNamesFlag)
                ignoreMissingNamesFlag=0; 
            end
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
                    matches=find(strcmpi(allConds,condName{j})); %Exact matches
                    if isempty(matches) && exactMatchesOnlyFlag==0
                        warning(['Looking for conditions named ''' condName{j} ''' but found no exact matches. Looking for partial matches.'])
                        matches=find(~cellfun(@isempty,strfind(allConds,condName{j})));
                    end
                    if length(matches)>1
                        warning(['Looking for conditions named ''' condName{j} ''' but found multiple matches. Using ''' allConds{matches(1)}]);
                        matches=matches(1);
                    end
                    condIdx=matches;
                end
                if ~isempty(condIdx)
                    conditionIdxs(i)=condIdx;
                else
                    if ~ignoreMissingNamesFlag
                        error(['Looking for conditions named ''' cell2mat(strcat(condName,',')) '''but found no matches, stopping.'])
                    else
                        warning(['Looking for conditions named ''' cell2mat(strcat(condName,',')) '''but found no matches, ignoring.'])
                    end
                end
            end
        end
        
        function trialNums=getTrialsInCondition(this,conditionNames)
            %Return trial numbers in each condition
            %
            %Inputs:
            %conditionNames -- cell containing string(s)
            %E.g. conditionNames={'Base','Adap',{'Post','wash'}}
            %
            %output:
            %trialNums -- a matrix of trial numbers in a condition
            %
            %example:
            %trialNums = getTrialsInCondition({'Base'})
            %trialNums = [1 2 3]
            conditionIdx=this.getConditionIdxsFromName(conditionNames);
            trialNums=cell2mat(this.trialsInCondition(conditionIdx));
        end
        
        function [this,change]=replaceConditionNames(this,currentName,newName)
            %Looks for conditions whose name match the options in
            %currentName & changes them to newName
            change=false;
           %Check currentName and newName are cell arrays of same length
           conditionIdxs=this.getConditionIdxsFromName(currentName,1,1); %Exact matches only, but allows not finding matches (does not accept partial matches)
           %this.conditionName(conditionIdxs)=newName;
           for i=1:length(currentName)
               if ~isnan(conditionIdxs(i)) && ~strcmp(this.conditionName{conditionIdxs(i)},newName{i})
                    this.conditionName{conditionIdxs(i)}=newName{i};
                    change=true;
               end
           end
        end
        
        function [newThis,change]=numerateRepeatedConditionNames(this)
           %This function should (almost) never be used. metaData no longer allows repeated condition names, so this is unnecessary.
           %However, for files created before the prohibition, it may
           %happen.
           aaa=unique(this.conditionName);
            change=false;
            if length(aaa)<length(this.conditionName) %There are repetitions
                change=true;
                for i=1:length(aaa)
                    aux=find(strcmpi(aaa{i},this.conditionName));
                    if length(aux)>1
                        disp(['Found a repeated condition name ' aaa{i} ])
                       for j=1:length(aux)
                          aaux=this.trialsInCondition{aux(j)} ;
                          %This queries the user for a new name:
                          
                          %disp(['Occurrence ' num2str(j) ' contains trials ' num2str(aaux) '.'])
                          %ss=input(['Please input a new name for this condition: ']);
                          
                          %This assigns a new name by adding a number:
                          ss=[aaa{i} ' ' num2str(j)];
                          
                          
                          this.conditionName{aux(j)}=ss;
                          disp(['Occurrence ' num2str(j) ' contains trials ' num2str(aaux) ', was replaced by ' ss '.'])
                       end

                    end
                end
            end
            newThis=this;
        end
        
        function [condNames]=getConditionsThatMatch(this,name,type)
           %Returns condition names that match certain patterns
           
           if nargin<2 || isempty(name) || ~isa(name,'char')
               error('Pattern name to search for needs to be a string')
           end
           patternMatches=cellfun(@(x) ~isempty(x),(strfind(lower(this.conditionName),lower(name))));
           if nargin>2 && ~isempty(type) && isa(type,'char')
               typeMatches=cellfun(@(x) ~isempty(x),(strfind(lower(this.conditionName),lower(type))));
           else
               typeMatches=true(size(patternMatches));
           end
           condNames=this.conditionName(patternMatches & typeMatches);
        end
    end
    
end

