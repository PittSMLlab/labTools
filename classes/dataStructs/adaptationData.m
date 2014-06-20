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
        function [data,auxLabel]=getParamInCond(this,label,condition)
            if isa(label,'char')
                auxLabel={label};
            else
                auxLabel=label;
            end            
            [boolFlag,labelIdx]=this.data.isaLabel(auxLabel);
            for i=1:length(boolFlag)
                if boolFlag(i)==0
                    warning(['Label ' auxLabel{i} ' is not a parameter in this data set.'])
                end
            end
            if isa(condition,'char') 
                condNum=find(strcmp(this.metaData.conditionDescription,condition));
            elseif isa(condition,'cell')
                for i=1:length(condition)
                    boolFlags=strcmp(this.metaData.conditionDescription,condition{i});
                    if any(boolFlags)
                        condNum(i)=find(boolFlags);
                    else
                        warning(['Label ' condition{i} ' is not a condition description in this experiment.'])
                    end
                end
            else %a numerical vector
                condNum=condition;
            end                
            
            trials=cell2mat(this.metaData.trialsInCondition(condNum));
            inds=cell2mat(this.data.indsInTrial(trials));
            
            data=this.data.Data(inds,labelIdx(boolFlag==1));
            auxLabel=this.data.labels(labelIdx(boolFlag==1));
        end
        
        function plotParamTimeCourse(this,label,binWidth)
            figure
            hold on
            % Set colors
            poster_colors;
            % Set colors order
            ColorOrder=[[255 0 0]/255; [255 185 0]/255; [11 132 199]/255; [0.2 0.2 0.2]; p_red; p_orange; p_fade_green; p_fade_blue; p_plum; p_green; p_blue; p_fade_red; p_lime; p_gray; p_black; p_yellow];
            for c=unique(this.metaData.getCondLstPerTrial)
                data=getParamInCond(label,c);
                
            end
        end
        
    end   
end

