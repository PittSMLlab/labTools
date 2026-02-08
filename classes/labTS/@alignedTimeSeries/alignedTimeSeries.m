classdef alignedTimeSeries % < labTimeSeries
    % TODO: make this inherit from labTimeSeries, as it should
    %alignedTimeSeries  Time-series-like object for aligned/repeated data
    %
    %   alignedTimeSeries stores multiple repetitions of recorded data
    %   aligned to common events (e.g., gait cycles aligned to heel
    %   strikes). Data is organized as (samples x channels x repetitions).
    %
    %alignedTimeSeries properties:
    %   Data - 3D matrix (samples x channels x strides)
    %   Time - time vector for one stride cycle
    %   labels - cell array of channel labels
    %   alignmentVector - vector specifying samples per phase
    %   alignmentLabels - cell array of phase/event labels
    %   eventTimes - matrix of actual event times (events x strides+1)
    %   expandedEventTimes - sample times for all events (dependent)
    %
    %alignedTimeSeries methods:
    %   alignedTimeSeries - constructor
    %   getPartialStridesAsATS - extracts subset of strides
    %   removeStridesWithNaNs - removes strides with missing data
    %   getPartialDataAsATS - extracts subset of channels
    %   mean - computes mean across strides
    %   std - computes standard deviation
    %   iqr - computes interquartile range
    %   stdRobust - computes robust standard deviation
    %   prctile - computes percentile
    %   median - computes median
    %   energyDecomposition - decomposes variance
    %   abs - takes absolute value
    %   equalizeEnergyPerChannel - normalizes by RMS
    %   demean - removes mean
    %   minus - subtracts two alignedTimeSeries
    %   plus - adds two alignedTimeSeries
    %   times - multiplies by constant
    %   catStrides - concatenates strides into labTimeSeries
    %   castAsTS - converts to labTimeSeries
    %   concatenateAsTS - concatenates strides sequentially
    %   isaLabel - checks if labels exist
    %   getLabelsThatMatch - finds labels matching pattern
    %   renameLabels - renames labels
    %   cat - concatenates alignedTimeSeries
    %   fftshift - shifts alignment by half cycle
    %   discretize - averages data across phases
    %   flipLR - flips left/right alignment
    %   getSym - computes symmetric components
    %   getaSym - computes asymmetric components
    %   rescaleTime - redefines time vector
    %   plot - plots aligned data with mean
    %   plotCheckerboard - displays data as heatmap
    %
    %See also: labTimeSeries, processedLabData

    %% Properties
    properties
        Data
        Time
        labels
        alignmentVector = [];
        alignmentLabels = {};
        eventTimes = [];
    end

    properties (Dependent)
        expandedEventTimes
    end

    %% Constructor
    methods
        function this = alignedTimeSeries(t0, Ts, Data, labels, ...
                alignmentVector, alignmentLabels, eventTimes)
            %alignedTimeSeries  Constructor for alignedTimeSeries class
            %
            %   this = alignedTimeSeries(t0, Ts, Data, labels,
            %   alignmentVector, alignmentLabels) creates aligned
            %   timeseries without event times
            %
            %   this = alignedTimeSeries(t0, Ts, Data, labels,
            %   alignmentVector, alignmentLabels, eventTimes) includes
            %   event timing information
            %
            %   Inputs:
            %       t0 - initial time
            %       Ts - sampling period
            %       Data - 3D matrix (samples x channels x strides)
            %       labels - cell array of channel labels
            %       alignmentVector - vector specifying number of samples
            %                         per phase
            %       alignmentLabels - cell array of phase/event labels
            %       eventTimes - matrix of event times (optional)
            %
            %   Outputs:
            %       this - alignedTimeSeries object
            %
            %   See also: labTimeSeries, processedLabData/reduce

            if nargin < 6
                warning(['alignedTimeSeries being created without ' ...
                    'specifying alignment criteria.']);
                alignmentVector = 1;
                alignmentLabels = {'Unknown'};
            end
            if size(Data, 2) == length(labels)
                this.Data = Data;
                this.Time = t0 + [0:size(Data, 1) - 1] * Ts;
                this.labels = labels;
                if length(alignmentVector) ~= length(alignmentLabels)
                    error('alignedTS:Constructor', ...
                        'Alignment vector and labels sizes do not match.');
                else
                    this.alignmentVector = alignmentVector;
                    this.alignmentLabels = alignmentLabels;
                end
            else
                error('alignedTS:Constructor', ...
                    'Data size and label number do not match.');
            end
            if nargin > 6
                % This actually calls on the set() method
                this.eventTimes = eventTimes;
            end
        end
    end

    %% Property Getters and Setters
    methods
        function eET = get.expandedEventTimes(this)
            %get.expandedEventTimes  Returns sample times for all events
            %
            %   Outputs:
            %       eET - matrix of sample times for each event

            if ~isempty(this.eventTimes)
                eET = alignedTimeSeries.expandEventTimes(...
                    this.eventTimes, this.alignmentVector);
            else % legacy version
                error('alignedTS:expandedEventTimes', ...
                    'eventTimes are not determined');
            end
        end

        function this = set.eventTimes(this, eventTimes)
            %set.eventTimes  Validates and sets event times
            %
            %   Inputs:
            %       this - alignedTimeSeries object
            %       eventTimes - matrix of event times

            if any(size(eventTimes) ~= [length(this.alignmentVector) ...
                    size(this.Data, 3) + 1])
                error('alignedTS:SetEventTimes', ...
                    'Data and eventTimes sizes do not match.');
            else
                this.eventTimes = eventTimes;
            end
        end
    end

    %% Data Extraction Methods
    methods
        newThis = getPartialStridesAsATS(this, inds)

        newThis = removeStridesWithNaNs(this)

        newThis = getPartialDataAsATS(this, labels)
    end

    %% Statistical Methods
    methods
        [meanTS, stds] = mean(this, strideIdxs)

        stdTS = std(this, strideIdxs)

        iqrTS = iqr(this, strideIdxs)

        stdTS = stdRobust(this, strideIdxs)

        prctileTS = prctile(this, p, strideIdxs)

        medianTS = median(this, strideIdxs)

        [decomposition, meanValue, avgStride, trial2trialVariability] = ...
            energyDecomposition(this)
    end

    %% Normalization Methods
    methods
        newThis = equalizeEnergyPerChannel(this)

        newThis = demean(this)
    end

    %% Arithmetic Operations
    methods
        function newThis = abs(this)
            %abs  Takes absolute value
            %
            %   newThis = abs(this) computes absolute value of data
            %
            %   Inputs:
            %       this - alignedTimeSeries object
            %
            %   Outputs:
            %       newThis - alignedTimeSeries with absolute values

            newThis = this;
            newThis.Data = abs(this.Data);
        end

        newThis = minus(this, other)

        newThis = plus(this, other)

        this = times(this, constant)
    end

    %% Type Conversion Methods
    methods
        newThis = catStrides(this)

        newThis = castAsTS(this)

        newThis = concatenateAsTS(this)
    end

    %% Label Methods
    methods
        [boolFlag, labelIdx] = isaLabel(this, label)

        labelList = getLabelsThatMatch(this, exp)

        this = renameLabels(this, originalLabels, newLabels)
    end

    %% Data Manipulation Methods
    methods
        newThis = cat(this, other, dim, forceFlag)

        newThis = fftshift(this, labels)

        newThis = discretize(this, averagingVector)

        [this, iC, iI] = flipLR(this)

        [this, iC, iI] = getSym(this)

        [this, iC, iI] = getaSym(this)

        newThis = rescaleTime(this, newTs, newT0)
    end

    %% Visualization Methods
    methods
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

    %% Static Methods
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

    %% Hidden Methods
    methods (Hidden)
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

