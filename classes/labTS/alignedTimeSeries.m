classdef alignedTimeSeries
    %alignedTimeSeries is a time-series-like object, but where it is
    %assumed that Data stores several repetitions of some recorded set
    
    properties
        Data
        Time
        labels
        alignmentVector=[];
        alignmentLabels={};
    end
    
    methods
        function this=alignedTimeSeries(t0,Ts,Data,labels,alignmentVector,alignmentLabels)
            %Check: 
            if nargin<6
                warning('alignedTimeSeries being created without specifying alignment criteria.')
                alignmentVector=[1];
                alignmentLabels={'Unknown'}; 
            end
            if size(Data,2)==length(labels)
                this.Data=Data;
                this.Time=t0+[0:size(Data,1)-1]*Ts;
                this.labels=labels;
                if length(alignmentVector)~=length(alignmentLabels)
                    error('alignedTS:Constructor','Alignment vector and labels sizes do not match.')
                else
                    this.alignmentVector=alignmentVector;
                    this.alignmentLabels=alignmentLabels;
                end
            else
                error('alignedTS:Constructor','Data size and label number do not match.')
            end
        end
        
        function newThis=getPartialStridesAsATS(this,inds)
            newThis=alignedTimeSeries(this.Time(1),this.Time(2)-this.Time(1),this.Data(:,:,inds),this.labels,this.alignmentVector,this.alignmentLabels);
        end
        
        function newThis=getPartialDataAsATS(this,labels)
            [~,relIdx]=this.isaLabel(labels);
            newThis=alignedTimeSeries(this.Time(1),this.Time(2)-this.Time(1),this.Data(:,relIdx,:),this.labels(relIdx),this.alignmentVector,this.alignmentLabels);
        end
        
        function [figHandle,plotHandles,plottedInds]=plot(this,figHandle,plotHandles,meanColor,events,individualLineStyle,plottedInds,bounds)
            % Plot individual instances (strides) of the time-series, and overlays the mean of all of them
            % Uses one subplot for each label in the timeseries (same as
            % labTimeSeries.plot).
            % If events are given (alignedTimeSeries with the same time vector and number of strides),
            % it will display the average event-time ocurrence in the plot,
            % instead of the time in the x-axis.
            % See also labTimeSeries.plot
            %
            % SYNTAX:
            % [figHandle,plotHandles]=plot(this,figHandle,plotHandles,meanColor,events)
            %
            % INPUTS:
            % this: alignedTimeSeries object to plot
            % figHandle: handle to the figure to be used. If absent,
            % creates a new figure.
            % plotHandles: handles to the subplots being used. There need
            % to be at least as many handles as labels in the data.
            % meanColor: color to use for the plot of the mean. %FIXME
            % events: alignedTimeSeries of events.
            %
            % OUTPUT:
            % figHandle: handle to the figure used.
            % plotHandles: handles to the subplots used.
            %
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
               if nargin<3 || isempty(plotHandles) || length(plotHandles)<size(this.Data,2)
                [b,a]=getFigStruct(M);
                plotHandles=tight_subplot(b,a,[.02 .02],[.05 .05], [.05 .05]); %External function
               end
               meanStr=mean(structure,3);
               if nargin<7 || isempty(plottedInds)
                   plottedInds=1:size(structure,3);
                   if (numel(structure))>1e7
                           P=floor(1e7/numel(structure(:,:,1)));
                           warning(['There are too many strides in this condition to plot (' num2str(size(structure,3)) '). Only plotting first ' num2str(P) '.'])
                           plottedInds=1:P;  
                           structure=structure(:,:,plottedInds);
                   end
               end
               for i=1:M %Go over labels
                   %subplot(b,a,i)
                   subplot(plotHandles(i))
                   hold on                  
                   %title(aux{1}.(field).labels{i})
                   data=squeeze(structure(:,i,:));
                   N=size(data,1);
                   if nargin<6 || isempty(individualLineStyle)
                        plot([0:N-1]/N,data,'Color',[.7,.7,.7]);
                   else
                       plot([0:N-1]/N,data,individualLineStyle);
                   end
                   %plot([0:N-1]/N,meanStr(:,i),'LineWidth',2,'Color',meanColor);
                   %legend(this.labels{i})
                   %maxM(i)=5*norm(data(:))/sqrt(length(data(:)));
                   meanM(i)=prctile(data(:),50);
                   maxM(i)=2*(prctile(data(:),99)-meanM(i))+meanM(i);
                   minM(i)=2*(prctile(data(:),1)-meanM(i))+meanM(i);
                   axis([0 1 minM(i) maxM(i)])
                   hold off
               end
               if nargin<5 || isempty(events)
                    events=[];
                    meanEvents=[];
               else
                   if isa(events,'alignedTimeSeries')
                    [meanEvents,ss]=mean(events);
                   else
                       meanEvents=events;
                       ss=[];
                   end
                    [i2,~]=find(meanEvents.Data);
               end
               if ~islogical(this.Data) && nargin>7 && ~isempty(bounds)
                   for k=1:length(bounds)
                        [figHandle,plotHandles]=plot(prctile(this,bounds(k)),figHandle,[],plotHandles,[],meanColor*.8,.5);
                   end
               end
               [figHandle,plotHandles]=plot(mean(this),figHandle,[],plotHandles,meanEvents,meanColor); %Plotting mean data
               if ~isempty(events)
                   for i=1:length(plotHandles) %For each plot, plot a standard deviation bar indicating how disperse are events with respect to their mean/median (XTick set).
                       eventSampPeriod=(events.Time(2)-events.Time(1));
                       subplot(plotHandles(i))
                       hold on
                       for j=1:length(ss)
                        plot(events.Time(i2(j))+ss(j)*[-1,1]*eventSampPeriod,[0,0],'k','LineWidth',1);
                       end
                       %axis tight %TO DO: not use axis tight, but find proper axes limits by computing the rms value of the signal, or something like that.
                       hold off
                   end
               end
        end
        
        function [meanTS,stds]=mean(this,strideIdxs)
            %Computes mean and standard deviation across all the aligned timeSeries.
            %For regular (double/complex) timeseries, mean and std are
            %computed directly from this.Data and each is returned as a
            %timeseries.
            %For logical data (events), it is assumed that all the aligned
            %timeSeries have the same number of true values and in the same order. 
            %A histogram is computed for the temporal ocurrences of this
            %values, and a logical TS is returned with events only in the
            %median values given by this histogram. The labels in this TS are 
            %as many as events occur in a single TS (this.Data(:,:,1)). 
            %The std is returned as a vector of size Nx1.
            if nargin>1 && ~isempty(strideIdxs)
                this.Data=this.Data(:,:,strideIdxs);
            end
            if ~islogical(this.Data(1))
                meanTS=labTimeSeries(nanmean(this.Data,3),this.Time(1),this.Time(2)-this.Time(1),this.labels);
                stds=[];
            else %Logical timeseries. Will find events and average appropriately. Assuming the SAME number of events per stride, and in the same ORDER. %FIXME: check event order.
                [histogram,newLabels]=logicalHist(this);
                %Compute mean/median:
                newData=sparse([],[],false,size(this.Data,1),length(newLabels),size(this.Data,1));
                mH=nanmedian(histogram);
                for i=1:size(histogram,2)
                    newData(mH(i),i)=true;
                end
                meanTS=labTimeSeries(newData,this.Time(1),this.Time(2)-this.Time(1),newLabels);
                stds=nanstd(histogram);
            end
        end
        
        function [stdTS]=std(this,strideIdxs)
            if nargin>1 && ~isempty(strideIdxs)
                this.Data=this.Data(:,:,strideIdxs);
            end
            if ~islogical(this.Data(1))
                stdTS=labTimeSeries(nanstd(this.Data,[],3),this.Time(1),this.Time(2)-this.Time(1),this.labels);
            else %Logical timeseries. Will find events and average appropriately. Assuming the SAME number of events per stride, and in the same ORDER. %FIXME: check event order.
                [histogram,~]=logicalHist(this);
                stdTS=std(histogram); %Not really a tS
            end
        end
        
        function [prctileTS]=prctile(this,p,strideIdxs)
            if nargin>2 && ~isempty(strideIdxs)
                this.Data=this.Data(:,:,strideIdxs);
            end
            if ~islogical(this.Data(1))
                prctileTS=labTimeSeries(prctile(this.Data,p,3),this.Time(1),this.Time(2)-this.Time(1),this.labels);
            else %Logical timeseries. 
                error('alignedTimeSeries:prctile','Prctile not yet implemented for logical alignedTimeSeries.') %TODO
            end 
        end
        
        function [decomposition,meanValue,avgStride,trial2trialVariability] =energyDecomposition(this)
            alignedData=this.Data;
            [decomposition,meanValue,avgStride,trial2trialVariability] = getVarianceDecomposition(alignedData);
        end
        
        function [boolFlag,labelIdx]=isaLabel(this,label)
            if isa(label,'char')
                auxLabel{1}=label;
            elseif isa(label,'cell')
                auxLabel=label;
            end
            
            N=length(auxLabel);
            boolFlag=false(N,1);
            labelIdx=zeros(N,1);
            for j=1:N
                for i=1:length(this.labels)
                     if strcmpi(auxLabel{j},this.labels{i})
                       boolFlag(j)=true;
                       labelIdx(j)=i;
                       break;
                     end
                end
            end
        end
        
    end
    
    methods(Hidden)
        function [histogram,newLabels]=logicalHist(this)
            %Generates a histogram from the logical data (true/false) contained in this alignedTS. Assumes that all aligned TS contain the same events, in the same order.
            
            %Check: this is a logical alignedTS
            %TODO
            %TODO: dtermine the number of expected events. Currently this
            %is as many events as stride 1 has. May be problematic if
            %stride one is invalid.
            eventNo=mode(sum(sum(this.Data,1),2));
            nStrides=size(this.Data,3);
            eventType=nan(eventNo,1);
            for i=1:eventNo
                aux=nan(nStrides,1);
                for k=1:nStrides %Going over strides
                    eventIdx=find(sum(this.Data(:,:,k),2)==1,i,'first'); %Time index of first event in stride k
                    if length(eventIdx)==i
                        aux(k)=find(this.Data(eventIdx(i),:,k),1,'first');
                    end
                end
                eventType(i)=round(nanmedian(aux)); %Rounding is to break possible ties (very unlikely)
            end
            histogram=nan(nStrides,eventNo);
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

            for i=1:nStrides;
                [eventTimeIndex,eventType]=find(this.Data(:,:,i));
                if length(eventTimeIndex)~=length(newLabels)
                    warning(['alignedTS:logicalHist: Stride ' num2str(i) ' has more or less events than expected (expecting ' num2str(length(newLabels)) ', but got ' num2str(length(eventTimeIndex)) '). Discarding.']);
                    histogram(i,:)=nan;
                else
                    %FIXME: check event order by using the labels.
                    [eventTimeIndex,auxInds]=sort(eventTimeIndex);
                    if all(ii==eventType(auxInds))
                        histogram(i,:)=eventTimeIndex;
                    else
                        warning(['alignedTS:logicalHist: Stride ' num2str(i) ' has events in different order than expected (expecting ' num2str(ii') ', but got ' num2str(eventType(auxInds)') '). Discarding.']);
                    end
                end
            end
        end
    end
end

