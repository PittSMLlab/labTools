classdef alignedTimeSeries %<labTimeSeries %TODO: make this inherit from labTimeSeries, as it should
    %alignedTimeSeries is a time-series-like object, but where it is
    %assumed that Data stores several repetitions of some recorded set
    
    properties
        Data
        Time
        labels
        alignmentVector=[];
        alignmentLabels={};
        eventTimes=[];
    end
    
    properties(Dependent)
        expandedEventTimes
    end
    
    methods
        function this=alignedTimeSeries(t0,Ts,Data,labels,alignmentVector,alignmentLabels,eventTimes)
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
            if nargin>6 
                this.eventTimes=eventTimes; %This actually calls on the set() method
            end
        end
        
        %Getters & setters
        function eET=get.expandedEventTimes(this)
            if ~isempty(this.eventTimes)
                eET=alignedTimeSeries.expandEventTimes(this.eventTimes,this.alignmentVector); 
            else %legacy version
                error('eventTimes are not determined')
            end
        end
        
        function this=set.eventTimes(this,eventTimes)
            if any(size(eventTimes)~=[length(this.alignmentVector) size(this.Data,3)+1])
                error('alignedTS:SetEventTimes','Data and eventTimes sizes do not match.')
            else
                this.eventTimes=eventTimes;
            end
        end
        
        %Other modifiers
        function newThis=getPartialStridesAsATS(this,inds)
            newThis=alignedTimeSeries(this.Time(1),this.Time(2)-this.Time(1),this.Data(:,:,inds),this.labels,this.alignmentVector,this.alignmentLabels,this.eventTimes(:,[inds inds(end)+1]));
        end
        
        function newThis=removeStridesWithNaNs(this)
           inds=find(all(all(~isnan(this.Data),2),1)); 
           newThis=getPartialStridesAsATS(this,inds);
        end
        
        function newThis=getPartialDataAsATS(this,labels)
            [boolIdx,relIdx]=this.isaLabel(labels);
            this.Data=this.Data(:,relIdx(boolIdx),:);
            this.labels=this.labels(relIdx(boolIdx));
            newThis=this;
            %newThis=alignedTimeSeries(this.Time(1),this.Time(2)-this.Time(1),this.Data(:,relIdx(boolIdx),:),this.labels(relIdx(boolIdx)),this.alignmentVector,this.alignmentLabels,this.eventTimes);
        end
        
        function [figHandle,plotHandles,plottedInds]=plot(this,figHandle,plotHandles,meanColor,events,individualLineStyle,plottedInds,bounds,medianFlag)
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
                if nargin<9 || isempty(medianFlag)
                    medianFlag=1;
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
               elseif any(plottedInds<=0) %Counting from the back
                  plottedInds(plottedInds<=0)=size(structure,3)+plottedInds(plottedInds<=0); 
               end
                   
               
               %Define centerline plot:
               if medianFlag==1
                   centerline=this.median.castAsTS; %Could do mean or median
               else
                   centerline=this.mean.castAsTS;
               end
               
               %Plot percentiles (bounds)
               if nargin<5 || isempty(events)
                    events=[];
                    meanEvents=[];
               else
                   if isa(events,'alignedTimeSeries')
                    [meanEvents,ss]=mean(events);
                    meanEvents=meanEvents.castAsTS;
                   else
                       meanEvents=events;
                       ss=[];
                   end
                    [i2,~]=find(meanEvents.Data);
               end
               if ~islogical(this.Data) && nargin>7 && ~isempty(bounds)
                   if length(bounds)==2 %Alt visualization: add patch
                       if any(bounds)==0
                           if medianFlag==1
                               st=this.stdRobust.castAsTS;
                           else
                               st=this.std.castAsTS;
                           end
                           if all(bounds)==0 %Plots ste
                               aux1=centerline+(st.* 1/sqrt(size(this.Data,3))); 
                               aux2=centerline-(st .* 1/sqrt(size(this.Data,3)));
                           else %Plots std
                               aux1=centerline+(st); 
                               aux2=centerline-(st); 
                           end
                       else
                            aux1=prctile(this,bounds(1));
                            aux2=prctile(this,bounds(2));
                       end
                       for i=1:M
                           subplot(plotHandles(i))
                           hold on
                           if size(aux1.Time,1)==numel(aux1.Time) %column vector
                               megaTime=[aux1.Time; aux1.Time(end:-1:1)];
                           else %row vector
                               megaTime=[aux1.Time, aux1.Time(end:-1:1)];
                           end
                           megaData=[aux1.Data(:,i);aux2.Data(end:-1:1,i)];
                           megaData(isnan(megaData))=0;
                           pp=patch(megaTime,megaData,meanColor,'FaceAlpha',.4,'EdgeColor','none');
                           uistack(pp,'bottom');
                           hold off
                       end
                   else %Plot each percentile line
                       for k=1:length(bounds)
                        [figHandle,plotHandles]=plot(this.prctile(bounds(k)).castAsTS,figHandle,[],plotHandles,[],meanColor*.8,.5);
                       end
                   end
               end
               
               %PLot mean trace
               [figHandle,plotHandles]=plot(centerline,figHandle,[],plotHandles,meanEvents,meanColor); %Plotting mean data
          
               %Plot individual traces
               for i=1:M %Go over labels
                   %subplot(b,a,i)
                   subplot(plotHandles(i))
                   hold on                  
                   %title(aux{1}.(field).labels{i})
                   data=squeeze(structure(:,i,:));
                   N=size(data,1);
                   if nargin<6 || isempty(individualLineStyle)
                        ppp=plot(this.Time,data,'Color',[.7,.7,.7]);
                        uistack(ppp,'bottom')
                   elseif individualLineStyle==0
                       %nop
                   else
                       ppp=plot(this.Time,data,individualLineStyle);
                       uistack(ppp,'bottom')
                   end
                   
                   %plot([0:N-1]/N,meanStr(:,i),'LineWidth',2,'Color',meanColor);
                   %legend(this.labels{i})
                   %maxM(i)=5*norm(data(:))/sqrt(length(data(:)));
                   meanM(i)=prctile(data(:),50);
                   maxM(i)=2*(prctile(data(:),99)-meanM(i))+meanM(i)+eps;
                   minM(i)=2*(prctile(data(:),1)-meanM(i))+meanM(i);
                   axis([this.Time(1) this.Time(end) minM(i) maxM(i)])
                   hold off
               end
     
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
               else
                   for i=1:length(plotHandles) %For each plot, plot a standard deviation bar indicating how disperse are events with respect to their mean/median (XTick set).
                        subplot(plotHandles(i))
                        xt=get(gca,'XTick');
                        xt=[this.Time(1)+[0,cumsum(this.alignmentVector)]*(this.Time(end)-this.Time(1))/sum(this.alignmentVector)];
                        xtl=[[this.alignmentLabels, this.alignmentLabels(1)]];
                        set(gca,'XTick',xt,'XTickLabel',xtl)
                        set(gca,'xgrid','on')
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
                %meanTS=labTimeSeries(nanmean(this.Data,3),this.Time(1),this.Time(2)-this.Time(1),this.labels);
                meanTS=alignedTimeSeries(this.Time(1),this.Time(2)-this.Time(1),nanmean(this.Data,3),this.labels,this.alignmentVector,this.alignmentLabels);
                stds=[];
            else %Logical timeseries. Will find events and average appropriately. Assuming the SAME number of events per stride, and in the same ORDER. %FIXME: check event order.
                [histogram,newLabels]=logicalHist(this);
                %Compute mean/median:
                newData=sparse([],[],false,size(this.Data,1),length(newLabels),size(this.Data,1));
                mH=nanmedian(histogram);
                for i=1:size(histogram,2)
                    if mod(mH(i),1)~=0
                        mH(i)=floor(mH(i));
                        warning(['Median event ' num2str(i) ' falls between two samples'])
                    end
                    newData(mH(i),i)=true;
                end
                %meanTS=labTimeSeries(newData,this.Time(1),this.Time(2)-this.Time(1),newLabels);
                meanTS=alignedTimeSeries(this.Time(1),this.Time(2)-this.Time(1),newData,newLabels,this.alignmentVector,this.alignmentLabels);
                stds=nanstd(histogram);
            end
        end
        
        function newThis=abs(this)
           newThis=this;
           newThis.Data=abs(this.Data);
        end
        
        function [stdTS]=std(this,strideIdxs)
            if nargin>1 && ~isempty(strideIdxs)
                this.Data=this.Data(:,:,strideIdxs);
            end
            if ~islogical(this.Data(1))
                %stdTS=labTimeSeries(nanstd(this.Data,[],3),this.Time(1),this.Time(2)-this.Time(1),this.labels);
                stdTS=alignedTimeSeries(this.Time(1),this.Time(2)-this.Time(1),nanstd(this.Data,[],3),this.labels,this.alignmentVector,this.alignmentLabels);
            else %Logical timeseries. Will find events and average appropriately. Assuming the SAME number of events per stride, and in the same ORDER. %FIXME: check event order.
                [histogram,~]=logicalHist(this);
                stdTS=std(histogram); %Not really a tS
            end
        end
        
        function [iqrTS]=iqr(this,strideIdxs)
            if nargin>1 && ~isempty(strideIdxs)
                this.Data=this.Data(:,:,strideIdxs);
            else
                strideIdxs=[];
            end
            if ~islogical(this.Data(1))
                iqrTS=this.prctile(75) - this.prctile(25);
            else %Logical timeseries. Will find events and average appropriately. Assuming the SAME number of events per stride, and in the same ORDER. %FIXME: check event order.
                [histogram,~]=logicalHist(this);
                iqrTS=iqr(histogram); %Not really a tS
            end
        end
        
        function [stdTS]=stdRobust(this,strideIdxs)
            if nargin>1 && ~isempty(strideIdxs)
                this.Data=this.Data(:,:,strideIdxs);
            end
            %IQR-based std computation
            stdTS=this.iqr .* (1/1.35);
        end
        
        function [prctileTS]=prctile(this,p,strideIdxs)
            if nargin>2 && ~isempty(strideIdxs)
                this.Data=this.Data(:,:,strideIdxs);
            end
            if ~islogical(this.Data(1))
                %prctileTS=labTimeSeries(prctile(this.Data,p,3),this.Time(1),this.Time(2)-this.Time(1),this.labels);
                prctileTS=alignedTimeSeries(this.Time(1),this.Time(2)-this.Time(1),prctile(this.Data,p,3),this.labels,this.alignmentVector,this.alignmentLabels);
            else %Logical timeseries. 
                error('alignedTimeSeries:prctile','Prctile not yet implemented for logical alignedTimeSeries.') %TODO
            end 
        end
        
        function medianTS=median(this,strideIdxs)
            if nargin<2 || isempty(strideIdxs)
                strideIdxs=[];
            end
            [medianTS]=prctile(this,50,strideIdxs);
        end
        
        function [decomposition,meanValue,avgStride,trial2trialVariability] =energyDecomposition(this)
            alignedData=this.Data;
            [decomposition,meanValue,avgStride,trial2trialVariability] = getVarianceDecomposition(alignedData);
        end
        
        function newThis=equalizeEnergyPerChannel(this)
            newThis=this;
            newThis.Data=bsxfun(@rdivide,newThis.Data,sqrt(mean(mean(this.Data.^2,3),1)));
        end
        
        function newThis=minus(this,other)
           newThis=this;
           newThis.Data=this.Data-other.Data;
        end
        
        function newThis=plus(this,other)
           newThis=this;
           newThis.Data=this.Data+other.Data;
        end
        
        function this=times(this,constant)
            this.Data=this.Data .* constant;
            if numel(constant)==1
                s=num2str(constant);
            else
                s='k'; %Generic constant string
            end
            this.labels=strcat([s '*'],this.labels);
        end
        
        function newThis=demean(this)
            newThis=this;
            newThis.Data=bsxfun(@minus,this.Data,this.mean.Data);
        end
        
        function newThis=catStrides(this)
            auxData=permute(this.Data,[2,1,3]);
            newThis=labTimeSeries(auxData(:,:)',this.Time(1),this.Time(2)-this.Time(1),this.labels);
        end
        
        function [boolFlag,labelIdx]=isaLabel(this,label)
            boolFlag=false(size(label));
            labelIdx=zeros(size(label));
            [bool,idx] = compareListsFast(label,this.labels);
            for j=1:length(label)
                if any(idx==j)
                    boolFlag(j)=true;
                    labelIdx(j)=find(idx==j);
                end
            end
        end
        
        function newThis=cat(this,other,dim,forceFlag)
            if nargin<4
                forceFlag=false;
            end
            if nargin<3 || isempty(dim)
                dim=3;%Cat-ting strides
            end
            
            %Check alignment vectors coincide & alignment labels coincide
            if any(this.alignmentVector~=other.alignmentVector)
                ME=MException('ATS:cat','Alignment vector mismatch');
                throw(ME);
            end
            if ~forceFlag && ~all(strcmp(this.alignmentLabels,other.alignmentLabels))
                ME=MException('ATS:cat','Alignment labels mismatch, this check can be ignored by setting forceFlag=true');
                throw(ME);
            end
            
            if dim==3
            %Check dimensions coincide
            s1=size(this.Data);
            s2=size(other.Data);
            if any(s1(1:2)~=s2(1:2))
                ME=MException('ATS:cat','Data dimension mismatch.');
                throw(ME);
            end

            %Check labels coincide (unless forced)
            if ~forceFlag && ~all(strcmp(this.labels,other.labels))
                ME=MException('ATS:cat','Label mismatch, this check can be ignored by setting forceFlag=true');
                throw(ME);
            end
            
            %Do the cat:
            newThis=alignedTimeSeries(this.Time(1),diff(this.Time(1:2)),cat(3,this.Data,other.Data),this.labels,this.alignmentVector,this.alignmentLabels);
            elseif dim==2 %Cat-ting labels
                %Check dimensions coincide
                s1=size(this.Data);
                s2=size(other.Data);
                if any(s1([1,3])~=s2([1,3]))
                    ME=MException('ATS:cat','Data dimension mismatch.');
                    throw(ME);
                end
                %Check no repeated labels
            
                %Check alignmentVector & Labels
                
                %Check that all eventTimes match
                if any(size(this.eventTimes)~=size(other.eventTimes)) || any(abs(this.eventTimes(:)-other.eventTimes(:))>1e-9)
                   ME=MException('ATS:cat','Trying to cat labels, but event times are different');
                   throw(ME);
                end
            
                %Do the cat
                newThis=alignedTimeSeries(this.Time(1),diff(this.Time(1:2)),cat(2,this.Data,other.Data),[this.labels,other.labels],this.alignmentVector,this.alignmentLabels,this.eventTimes);
            else
                ME=MException();
                throw(ME);
            end
        end
        
        function newThis=castAsTS(this)
           %Function to change the class to labTS (instead of ATS). This is a temp function, until alignedTS is changed to inherit from labTS
           if size(this.Data,3)>1
               ME=MException('alignedTS:castAsTS','To cast as TS, there may be a single alignedTS (i.e. size(this.Data,3)==1)');
               throw(ME)
           end
           newThis=labTimeSeries(this.Data,this.Time(1),this.Time(2)-this.Time(1),this.labels);
        end
        
        function newThis=concatenateAsTS(this)
            %This concatenates the ATS by putting strides one after another
            %in time, returning a single labTS
           newThis=labTimeSeries(reshape(permute(this.Data,[1,3,2]),[size(this.Data,1)*size(this.Data,3),size(this.Data,2)]),this.Time(1),this.Time(2)-this.Time(1),this.labels);
        end
        
        function newThis=fftshift(this,labels)
            %Shifts the first and second halves of the alignment cycle
            %Example, if the first half starts at FHS and second half
            %starts at SHS, the shifted version will start at SHS and FHS
            %will be the midpoint of the cycle.
            if nargin>1 && ~isempty(labels)
                [~,idxs]=this.isaLabel(labels);
            else
                idxs=1:length(this.labels);
            end
           newThis=this;
           M=round(length(this.alignmentVector)/2);
           N=sum(this.alignmentVector(1:M));
           newThis.Data(:,idxs,:)=this.Data([N+1:size(this.Data,1),1:N],idxs,:);
        end
        
        function labelList=getLabelsThatMatch(this,exp)
            %Returns labels on this labTS that match the regular expression exp.
            %labelList=getLabelsThatMatch(this,exp)
            %INPUT:
            %this: labTS object
            %exp: any regular expression (as string). 
            %OUTPUT:
            %labelList: cell array containing labels of this labTS that match
            %See also regexp
            labelList=this.labels; 
            flags=cellfun(@(x) ~isempty(x),regexp(labelList,exp));
            labelList=labelList(flags);
        end
        
        function newThis=rescaleTime(this,newTs,newT0)
            %Re-defines the Time vector to force a new sampling time
            %Made for backwards compatibility of aligned series always
            %being defined with time in [0 1]
            if nargin<3 || isempty(newT0)
                newT0=0;
            end
            if nargin<2 || isempty(newTs)
                newTs=1/length(this.Time); %Re-scales such that total duration is 1 [time can be thought of as % of some cycle]
            end
            newThis=alignedTimeSeries(newT0,newTs,this.Data,this.labels,this.alignmentVector,this.alignmentLabels);
        end
        
        function this=renameLabels(this,originalLabels,newLabels)
            warning('labTS:renameLabels:dont','You should not be renaming the labels. You have been warned.')
            if isempty(originalLabels)
                originalLabels=this.labels;
            end
            if size(newLabels)~=size(originalLabels)
                error('Inconsistent label sizes')
            end
            [boo,idx]=this.isaLabel(originalLabels);
            this.labels(idx(boo))=newLabels;
        end
        
        function newThis=discretize(this,averagingVector)
            if sum(averagingVector)~=sum(this.alignmentVector)
                error('The averaging vector must sum to the number of samples of the alignedTS')
            end
            lastInd=0;
            newData=nan(length(averagingVector),size(this.Data,2),size(this.Data,3));
            expEventTimes=alignedTimeSeries.expandEventTimes(this.eventTimes,this.alignmentVector);
            newEventTimes=nan(length(averagingVector),size(expEventTimes,2)+1);
            auxSamp=1+[0 cumsum(this.alignmentVector)];
            for i=1:length(averagingVector)
                inds=lastInd+[1:averagingVector(i)];
                newData(i,:,:)=nanmean(this.Data(inds,:,:));
                if ~any(auxSamp==inds(1))
                    aux1='-';
                else
                    aux1=this.alignmentLabels{auxSamp==inds(1)};
                end
                if ~any(auxSamp==inds(end))
                    aux2='-';
                else
                    aux2=this.alignmentLabels{auxSamp==inds(end)};
                end
                aux=this.alignmentLabels(auxSamp>inds(1) & auxSamp<inds(end));
                if ~isempty(aux)
                    auxM=cell2mat(aux);
                else
                    auxM='-';
                end
                alignLabel{i}=[aux1 aux2];
                newEventTimes(i,1:end-1)=expEventTimes(lastInd+1,:); %Beginning of averaged interval
                lastInd=lastInd+averagingVector(i);
            end
            newEventTimes(1,end)=this.eventTimes(1,end);
            newThis=alignedTimeSeries(0,1,newData,this.labels,ones(size(averagingVector)),alignLabel,newEventTimes);
        end
        
        function [this,iC,iI]=flipLR(this)
           %Find the side that has the starting event:
           alignedSide=this.alignmentLabels{1}(1);
           nonAlignedSide=getOtherLeg(alignedSide);
           %Flip non-aligned side:
           lC=this.getLabelsThatMatch(['^' nonAlignedSide]); %Get non-aligned side labels
           if ~isempty(lC)
               [~,iC]=this.isaLabel(lC); %Index for non-aligned
               aux=regexprep(lC,['^' nonAlignedSide],alignedSide); %Getting aligned side labels
               [bI,iI]=this.isaLabel(aux); %Index for aligned
               if ~all(bI) %Labels are not symm, aborting
                   warning('Asked to flipLR but labels are not symmetrically present.')
               else
                   this.Data(:,iC)=fftshift(this.Data(:,iC),1); %This just flips first and second halves of aligned data, no checks performed
                   this.alignmentLabels=regexprep(this.alignmentLabels,['^' alignedSide],'i');
                   this.alignmentLabels=regexprep(this.alignmentLabels,['^' nonAlignedSide],'c');
               end
           else
                warning('Asked to flipLR but couldn''t find aligned side.')
                iC=[];
           end
        end
        function [this,iC,iI]=getSym(this)
            [this,iC,iI]=this.flipLR; %First, flip the non-aligned side.
            %Then: compute sym/asym data and replace it.
            this.Data=.5*[this.Data(:,iI)-this.Data(:,iC) this.Data(:,iI)+this.Data(:,iC)];
            %Update labels:
            this.labels=[regexprep(this.labels(iI),['^' this.labels{iI(1)}(1)],'a') regexprep(this.labels(iI),['^' this.labels{iI(1)}(1)],'b')];
        end
        
        function [fh,ph]=plotCheckerboard(this,fh,ph)
           if nargin<2
               fh=figure();
           else
               figure(fh);
           end
           if nargin<3
               ph=gca;
           else
               axes(ph);
           end
           m=this.mean;
           %imagesc(m.Data')
           surf([this.Time, 2*this.Time(end)-this.Time(end-1)],[0:size(m.Data,2)],[[m.Data';m.Data(:,end)'],[m.Data(end,:)';0]],'EdgeColor','none')
           view(2)
           ax=gca;
           ax.YTick=[1:length(this.labels)]-.5;
           ax.YTickLabels=this.labels;
           ax.XTick=[.5 .5+cumsum(this.alignmentVector)]/sum(this.alignmentVector) *this.Time(end) ;
           ax.XTickLabel=this.alignmentLabels;
           axis([this.Time(1) 2*this.Time(end)-this.Time(end-1) 0 size(m.Data,2)])
           %Colormap:
            ex2=[0.2314    0.2980    0.7529];
            ex1=[0.7255    0.0863    0.1608];
            gamma=.5;
            map=[bsxfun(@plus,ex1.^(1/gamma),bsxfun(@times,1-ex1.^(1/gamma),[0:.01:1]'));bsxfun(@plus,ex2.^(1/gamma),bsxfun(@times,1-ex2.^(1/gamma),[1:-.01:0]'))].^gamma;

            colormap(flipud(map))
            try
            caxis([-1 1]*max(abs(m.Data(:)))) %Fails if plotted data is NaN
            colorbar
            catch
                
            end
            
            %To do: check if the events exist, and add DS/STANCE/DS/SWING labels
        end
    end
    
    methods (Static)
        function expEventTimes=expandEventTimes(eventTimes,alignmentVector)
            %Given event times and an alignment vectors, this function
            %computes the corresponding time for each sample in an
            %alignedTimeSeries, provided that the sampling is uniform
            %between events.
            %This method cannot be hiddent because it is used in labTS
            
            refTime=1+[0 cumsum(alignmentVector)]'; %This should be 0+ for the old-style alignment
            M=size(eventTimes,2)-1;
            N=sum(alignmentVector);
            allEventTimes=eventTimes(:);
            refTime2=bsxfun(@plus,refTime(1:end-1),N*[0:M]);
            allExpEventTimes=interp1(refTime2(:),allEventTimes(:),[1:N*M]');
            expEventTimes=reshape(allExpEventTimes,N,M);
           
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
            aaux=cellfun(@(x) isempty(x),strfind(this.labels,'force')) & cellfun(@(x) isempty(x),strfind(this.labels,'kin'));
            eventNo=mode(sum(sum(this.Data(:,aaux),1),2)); %Mode of the # of events per stride, assuming this is what should happen on every stride.
            nStrides=size(this.Data,3);
            eventType=nan(eventNo,1);
            for i=1:eventNo
                aux=nan(nStrides,1);
                for k=1:nStrides %Going over strides
                    eventIdx=find(sum(this.Data(:,aaux,k),2)==1,i,'first'); %Time index of first i events in stride k
                    if length(eventIdx)==i %Checking that I found i events
                        aux(k)=find(this.Data(eventIdx(i),aaux,k),1,'first');
                    end
                end
                eventType(i)=round(nanmedian(aux)); %Rounding is to break possible ties (very unlikely)
            end
            histogram=nan(nStrides,eventNo);
            ii=eventType;
            aux=zeros(eventNo,1);
            newLabels=cell(size(ii));
            for i=1:length(ii)
                aux(ii(i))=aux(ii(i))+1;
                if aux(ii(i))==1
                    newLabels{i}=this.labels{ii(i)};
                else
                    newLabels{i}=[this.labels{ii(i)} num2str(aux(ii(i)))];
                end
            end

            for i=1:nStrides
                [eventTimeIndex,eventType]=find(this.Data(:,aaux,i));
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

