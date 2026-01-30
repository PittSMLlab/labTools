classdef stridedExperimentData
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        metaData %experimentMetaData type
        subData %subjectData type
        stridedTrials %cell array of cell array of strideData objects
    end
    
    properties(SetAccess=private) 
        isTimeNormalized=false; %This should be dependent, and be returned by checking that the length of all timeSeries in all strides has the same length, it is rather boring to do.
    end
    
    methods
        %Constructor
        function this=stridedExperimentData(meta,sub,strides)
                if isa(meta,'experimentMetaData')
                    this.metaData=meta;
                else
                    ME=MException();
                    throw(ME)
                end
                if isa(sub,'subjectData')
                    this.subData=sub;
                else
                    ME=MException();
                    throw(ME)
                end
                if isa(strides,'cell') && all( cellfun('isempty',strides) | cellisa(strides,'cell'))
                    aux=cellisa(strides,'cell');
                    idx=find(aux==1,1);
                    if all(cellisa(strides{idx},'strideData')) %Just checking whether the first non-empty cell is made of strideData objects, but should actually check them all
                        this.stridedTrials=strides;
                    else
                        ME=MException();
                        throw(ME);
                    end
                else
                    ME=MException();
                    throw(ME);
                end                
        end
        
        %Getters for Dependent properties
        %function a=get.isTimeNormalized(this)
        %    a='Who knows?'; %ToDo!
        %end
        
        %Modifiers
        function newThis=timeNormalize(this,N)
           %Lstrides
           newStrides=cell(1,length(this.stridedTrials));
           for trial=1:length(this.stridedTrials)
               thisTrial=this.stridedTrials{trial};
               newTrial=cell(1,length(thisTrial));
               for stride=1:length(thisTrial)
                   thisStride=thisTrial{stride};
                   newTrial{stride}=timeNormalize(thisStride,N);
               end
               newStrides{trial}=newTrial;
           end
           
           %Construct newTrial
           newThis=stridedExperimentData(this.metaData,this.subData,newStrides);
           newThis.isTimeNormalized=true;
        end
        
        function [strides]=getStridesFromCondition(this,condition)
           strides={};           
           for trial=this.metaData.trialsInCondition{condition}
               trialData=this.stridedTrials{trial};
               Nsteps=length(trialData);
               strides(end+1:end+Nsteps)=trialData;                           
           end
        end
        
        %Assess results
        function [figHandle,plotHandles]=plotAllStrides(this,field,conditions,plotHandles,figHandle)
            %To Do: need to add gait Events markers.
            
            % Set colors
            poster_colors;
            % Set colors order
            ColorOrder=[p_red; p_orange; p_fade_green; p_fade_blue; p_plum; p_green; p_blue; p_fade_red; p_lime; p_yellow];
            set(gcf,'DefaultAxesColorOrder',ColorOrder);
            
            for cond=conditions
                if nargin<5 || isempty(figHandle)
                    figHandle=figure('Name',['Subject ' num2str(this.subData.ID) ' Condition ' num2str(cond) ' ' field ]);
                else
                    figure(figHandle) %Only works for one condition!
                end
               set(figHandle,'Units','normalized','OuterPosition',[0 0 1 1])
               aux=this.getStridesFromCondition(cond);
               N=2^ceil(log2(1.5/aux{1}.(field).sampPeriod));
               structure=this.getDataAsMatrices(field,cond,N);
               M=size(structure{cond},2);
               if nargin<4 || isempty(plotHandles)
                [b,a]=getFigStruct(M);
                plotHandles=tight_subplot(b,a,[.02 .02],[.05 .02], [.02 .05]); %External function
               end
               if (numel(structure{cond}))>1e6
                       P=floor(1e7/numel(structure{cond}(:,:,1)));
                       warning(['There are too many strides in this condition to plot (' num2str(size(structure{cond},3)) '). Only plotting first ' num2str(P) '.'])
                       meanStr{cond}=mean(structure{cond},3);
                       structure{cond}=structure{cond}(:,:,1:P);
                   end
               for i=1:M
                   %subplot(b,a,i)
                   subplot(plotHandles(i))
                   hold on
                   %title(aux{1}.(field).labels{i})
                   data=squeeze(structure{cond}(:,i,:));
                   plot([0:N-1]/N,data,'Color',[.7,.7,.7])
                   plot([0:N-1]/N,meanStr{cond}(:,i),'LineWidth',2,'Color',ColorOrder(mod(cond-1,size(ColorOrder,1))+1,:));
                   legend(aux{1}.(field).labels{i})
                   hold off
               end
            end
            
        end
        
        function [figHandle,plotHandles]=plotAllStridesBilateral(this,field,conditions,plotHandles,figHandle) %Forces 'L' and 'R' to be plotted on top of each other %To Do
            [figHandle,plotHandles]=plotAllStrides(this,field,conditions,plotHandles,figHandle);
        end
        
        function [figHandle,plotHandles]=plotAvgStride(this,field,conditions,plotHandles,figHandle)
            % Set colors
            poster_colors;
            % Set colors order
            ColorOrder=[p_red; p_orange; p_fade_green; p_fade_blue; p_plum; p_green; p_blue; p_fade_red; p_lime; p_yellow];
            set(gcf,'DefaultAxesColorOrder',ColorOrder);
            
                if nargin<5 || isempty(figHandle)
                    figHandle=figure('Name',['Subject ' num2str(this.subData.ID) ' ' field ]);
                else
                    figure(figHandle) %Only works for one condition!
                end
                set(figHandle,'Units','normalized','OuterPosition',[0 0 1 1])
               aux=this.getStridesFromCondition(conditions(1));
               N=2^ceil(log2(size(aux{1}.(field).Data,1)));
               structure=this.getDataAsMatrices(field,conditions,N);
               if nargin<4 || isempty(plotHandles)
                M=size(structure{1},2);
                [b,a]=getFigStruct(M);
                plotHandles=tight_subplot(b,a,[.04 .02],[.05 .02], [.04 .05]);
               end
               for i=1:M
                   %subplot(b,a,i)
                   subplot(plotHandles(i))
                   hold on
                   legStr={};
                   title(aux{1}.(field).labels{i})
                   for cond=conditions
                   data=mean(squeeze(structure{cond}(:,i,:)),2);
                   plot([0:N-1]/N,data,'LineWidth',2,'Color',ColorOrder(mod(cond-1,size(ColorOrder,1))+1,:))
                   legStr{end+1}=['Condition ' num2str(cond)];
                   end
                   if i==M
                   legend(legStr)
                   end
                   hold off
               end
        end
            
        function alignedData=alignEvents(this,spacing,trial,fieldName,labelList)
               alignedData=[]; 
        end %This function will be deprecated, use getAlignedData instead.
        
        function newThis=discardBadStrides(this) %No need, the discarding happens when this structure is created from a processed experiment.
            newThis=[];
        end
        
        function alignedData=getAlignedData(this,spacing,trial,fieldName,labelList)
                data=this;
                M=spacing;
                aux=[0 cumsum(M)];
                strides=data.stridedTrials{trial};
                alignedData=zeros(sum(M),length(labelList),length(strides));
                    Nphases=4;
                    for phase=1:Nphases
                        samples=zeros(length(strides),length(labelList));
                        for stride=1:length(strides)
                            switch phase
                                case 1
                                    thisPhase=strides{stride}.getDoubleSupportLR;
                                case 2
                                    thisPhase=strides{stride}.getSingleStanceL;
                                case 3
                                    thisPhase=strides{stride}.getDoubleSupportRL;
                                case 4
                                    thisPhase=strides{stride}.getSingleStanceR;
                            end
                            alignedData(aux(phase)+1:aux(phase)+M(phase),:,stride)=thisPhase.(fieldName).resampleN(M(phase)).getDataAsVector(labelList);
                        end  
                    end
        end
            
        
        function structure=getDataAsMatrices(this,fields,conditions,N)
            for cond=conditions
                strides=this.getStridesFromCondition(cond);
                if isa(fields,'cell')
                    for f=1:length(fields)
                        for s=1:length(strides)
                            aux=strideData.cell2mat(strides,fields{f},N);
                        end
                        eval(['structure{cond}.' fields{f} '=aux;']);
                    end
                else
                    aux=strideData.cell2mat(strides,fields,N);
                    structure{cond}=aux;
                end
            end
        end
        
        
    end
    
end

