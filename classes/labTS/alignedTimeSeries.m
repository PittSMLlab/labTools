classdef alignedTimeSeries
    %alignedTimeSeries is a time-series-like object, but where it is
    %assumed that Data stores several repetitions of some recorded set
    
    properties
        Data
        Time
        labels
    end
    
    methods
        function this=alignedTimeSeries(t0,Ts,Data,labels)
            %Check: 
            if size(Data,2)==length(labels)
                this.Data=Data;
                this.Time=t0+[0:size(Data,1)-1]*Ts;
                this.labels=labels;
            else
                error('alignedTS:Constructor','Data size and label number do not match.')
            end
        end
        
        function [figHandle,plotHandles]=plot(this,figHandle,plotHandles,meanColor,events)
                if nargin<4 || isempty(meanColor)
                   meanColor=[1,0,0]; 
                end
                structure=this.Data;
                if nargin<2 || isempty(figHandle)
                    figHandle=figure();
                else
                    figure(figHandle) %Only works for one condition!
                end
               set(figHandle,'Units','normalized','OuterPosition',[0 0 1 1])
               M=size(structure,2);
               if nargin<3 || isempty(plotHandles)
                [b,a]=getFigStruct(M);
                plotHandles=tight_subplot(b,a,[.02 .02],[.05 .05], [.05 .05]); %External function
               end
               meanStr=mean(structure,3);
               if (numel(structure))>1e7
                       P=floor(1e7/numel(structure(:,:,1)));
                       warning(['There are too many strides in this condition to plot (' num2str(size(structure,3)) '). Only plotting first ' num2str(P) '.'])
                       structure=structure(:,:,1:P);
               end
               for i=1:M %Go over labels
                   %subplot(b,a,i)
                   subplot(plotHandles(i))
                   hold on                  
                   %title(aux{1}.(field).labels{i})
                   data=squeeze(structure(:,i,:));
                   N=size(data,1);
                   plot([0:N-1]/N,data,'Color',[.7,.7,.7])
                   %plot([0:N-1]/N,meanStr(:,i),'LineWidth',2,'Color',meanColor);
                   %legend(this.labels{i})
                   hold off
               end
               [meanEvents,ss]=mean(events);
               [i2,~]=find(meanEvents.Data);
               [figHandle,plotHandles]=plot(mean(this),figHandle,[],plotHandles,meanEvents);
               for i=1:length(plotHandles) %For each plot, 
                   subplot(plotHandles(i))
                   hold on
                   for j=1:length(ss)
                    plot(((i2(j)-1)+ss(j)*[-1,1])/size(structure,1),[0,0],'k','LineWidth',1);
                   end
                   axis tight
                   hold off
               end
        end
        
        function [labTS,stds]=mean(this,strideIdxs)
            if nargin>1 && ~isempty(strideIdxs)
                this.Data=this.Data(:,:,strideIdxs);
            end
            if ~islogical(this.Data(1))
                labTS=labTimeSeries(nanmean(this.Data,3),this.Time(1),this.Time(2)-this.Time(1),this.labels);
                stds=[];
            else %Logical timeseries. Will find events and average appropriately. Assuming the SAME number of events per stride, and in the same ORDER.
                [eventTimeIndex,eventType]=find(this.Data(:,:,1));
                histogram=nan(size(this.Data,3),length(eventTimeIndex));
                [eventTimeIndex,ii]=sort(eventTimeIndex);
                eventType=eventType(ii);
                ii=eventType;
                aux=zeros(length(this.labels),1);
                newLabels=cell(size(ii));
                for i=1:length(ii)
                    aux(ii(i))=aux(ii(i))+1;
                    if aux(ii(i))==1
                        newLabels{i}=this.labels{ii(i)};
                    else
                        newLabels{i}=[this.labels{ii(i)} num2str(aux(ii(i)))];
                    end
                end
                
                for i=1:size(this.Data,3);
                    [eventTimeIndex,eventType]=find(this.Data(:,:,i));
                    [eventTimeIndex,~]=sort(eventTimeIndex);
                    histogram(i,:)=eventTimeIndex;
                end
                newData=false(size(this.Data,1),length(newLabels));
                mH=median(histogram);
                for i=1:size(histogram,2)
                    newData(mH(i),i)=true;
                end
                labTS=labTimeSeries(newData,this.Time(1),this.Time(2)-this.Time(1),newLabels);
                stds=std(histogram);
            end
        end
        
        function [decomposition,meanValue,avgStride,trial2trialVariability] =energyDecomposition(this)
            alignedData=this.Data;
            avgStride=mean(alignedData,3);
            meanValue=mean(avgStride,1);
            trial2trialVariability=bsxfun(@minus,alignedData,avgStride);
            avgStride=bsxfun(@minus,avgStride,meanValue);


            decomposition(1,:)=meanValue.^2 * size(alignedData,3) * size(alignedData,1);
            decomposition(2,:)=sum(avgStride.^2,1) * size(alignedData,3);
            decomposition(3,:)=sum(sum(trial2trialVariability.^2,3),1);


            %Check: difference btw decomposition and actual energy is not more than .1%
            %of total energy
            if any(sum(decomposition,1)-sum(sum(alignedData.^2,3),1)>.001*sum(sum(alignedData.^2,3),1))
                warning('Decomposition does not add up to actual signal energy')
            end


            %Normalize decomposition so we get RMS values of each component:
            decomposition=sqrt(decomposition/(size(alignedData,3)*size(alignedData,1)));
        end
        
        
    end
    
end

