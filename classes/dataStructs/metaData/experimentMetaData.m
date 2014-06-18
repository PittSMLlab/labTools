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
        conditionDescription={};
        trialsInCondition={};
        Ntrials=[];        
    end   
   
    
    methods
        %Constructor
        function this=experimentMetaData(ID,date,experimenter,obs,conds,trialLst,Ntrials)
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
                this.conditionDescription=conds;
            end
            if nargin>5 || ~isempty(trialLst)
                this.trialsInCondition=trialLst; %Must be cell of doubles
            end
            if nargin>6 && isa(Ntrials,'double')
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
    end
    
end

