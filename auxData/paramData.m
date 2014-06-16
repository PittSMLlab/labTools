classdef paramData
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    %%
    properties %(SetAccess=private)
        labels={''};
        Data;
        conditionDescription={};
        trialsInCondition={};
        indsInTrial={};        
    end
    properties(Dependent)
        %could include things here like 'learning' or 'transfer'...
    end
    
    %%
    methods
        
        %Constructor:
        function this=adaptationData(data,labels,inds)
            if (length(labels)==size(data,2)) && isa(labels,'cell')
                this.labels=labels;
                this.Data=data;
            else
                ME=MException('adaptationData:ConstructorInconsistentArguments','The size of the labels array is inconsistent with the data being provided.');
                throw(ME)
            end
            this.conditionDescri
        end
        
        %-------------------
        
        %Other I/O functions:
        function [data,auxLabel]=getParameter(this,label)
            if isa(label,'char')
                auxLabel={label};
            else
                auxLabel=label;
            end            
            [boolFlag,labelIdx]=this.isaLabel(auxLabel);
            for i=1:length(boolFlag)
                if boolFlag(i)==0
                    warning(['Label ' auxLabel{i} ' is not a labeled dataset in this timeSeries.'])
                end
            end            
            data=this.Data(:,labelIdx(boolFlag==1));
            auxLabel=this.labels(labelIdx(boolFlag==1));
        end
        
        function labelList=getLabels(this)
           labelList=this.labels; 
        end
        
        function [boolFlag,labelIdx]=isaLabel(this,label)
            if isa(label,'char')
                auxLabel{1}=label;
            elseif isa(label,'cell')
                auxLabel=label;
            end            
            N=length(auxLabel);
            boolFlag=zeros(N,1);
            labelIdx=zeros(N,1);
            for j=1:N
                for i=1:length(this.labels)
                     if strcmp(auxLabel{j},this.labels{i})
                       boolFlag(j)=true;
                       labelIdx(j)=i;
                       break;
                     end
                end
            end
        end     
        
        %Display
        function h=plot(this,h)
            %nothing for time being
        end      
        
    end    
        
end

