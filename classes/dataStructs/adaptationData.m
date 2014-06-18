classdef adaptationData
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        metaData %experimentMetaData type
        subData %subjectData type
        data %Contains adaptation parameters
    end
    
    properties (Dependent)
        
    end
    
    methods
        %Constructor
        function this=adaptationData(meta,sub,data)

           if nargin>0 && isa(meta,'experimentMetaData')
               this.metaData=meta;
           else
               ME=MException('adaptationData:Constructor','metaData is not an experimentMetaData type object.');
               throw(ME);
           end
           
           if nargin>1 && isa(sub,'subjectData')
               this.subData=sub;
           else
               ME=MException('adaptationData:Constructor','Subject data is not a subjectData type object.');
               throw(ME);
           end
           
           if nargin>2 && isa(data,'paramData')                
                this.data=data;              
           else
               ME=MException('adaptationData:Constructor','Data is not a paramData type object.');
               throw(ME);
           end
        end 
        
        %Other I/O functions:
        function [data,auxLabel]=getParameterInTrial(this,label,trial)
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
            inds=
            data=this.Data(:,labelIdx(boolFlag==1));
            auxLabel=this.labels(labelIdx(boolFlag==1));
        end
        
        function labelList=getParameters(this)
           labelList=this.data.labels; 
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
                for i=1:length(this.data.labels)
                     if strcmp(auxLabel{j},this.data.labels{i})
                       boolFlag(j)=true;
                       labelIdx(j)=i;
                       break;
                     end
                end
            end
        end
    end   
end

