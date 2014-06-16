classdef experimentMetaData <labMetaData
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        conditionsDescription={};
        trialsInCondition={};
        Ntrials=[];
    end
    
    methods
        %Constructor (ID,date,experimenter,type,desc,obs,conds,trialLst,Ntrials)
        function this=experimentMetaData(ID,date,experimenter,type,desc,obs,conds,trialLst,Ntrials)
            this@labMetaData(ID,date,experimenter,type,desc,obs)
            if nargin>6 || ~isempty(conds)
                this.conditionsDescription=conds; %Must be cell of strings
            end
            if nargin>7 || ~isempty(trialLst)
                this.trialsInCondition=trialLst; %Must be cell of strings
            end
            if nargin>8 || ~isempty(Ntrials)
                this.Ntrials=Ntrials; %Must be cell of strings
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

