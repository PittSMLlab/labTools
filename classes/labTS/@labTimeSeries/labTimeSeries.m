classdef labTimeSeries  < timeseries
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    %%
    properties(SetAccess=private)
        labels={''};
        sampPeriod;
    end
    properties(Dependent)
        sampFreq
        timeRange
        Nsamples
    end
    
    %%
    methods
        
        %Constructor:
        function this=labTimeSeries(data,t0,Ts,labels) %Necessarily uniformly sampled
            if nargin==0
                data=[];
                time=[];
                labels={};
                Ts=[];
            else
                time=[0:size(data,1)-1]*Ts+t0;
            end
            this=this@timeseries(data,time);
            this.sampPeriod=Ts;
            if (length(labels)==size(data,2)) && isa(labels,'cell')
                this.labels=labels;
            else
                ME=MException('labTimeSeries:ConstructorInconsistentArguments','The size of the labels array is inconsistent with the data being provided.');
                throw(ME)
            end
        end
        
        %-------------------
        
        %Other I/O functions:
        function [data,time,auxLabel]=getDataAsVector(this,label)
            if isa(label,'char')
                auxLabel={label};
            else
                auxLabel=label;
            end
            time=this.Time;
            [boolFlag,labelIdx]=this.isaLabel(auxLabel);
            for i=1:length(boolFlag)
                if boolFlag(i)==0
                    warning(['Label ' auxLabel{i} ' is not a labeled dataset in this timeSeries.'])
                end
            end
            
            data=this.Data(:,labelIdx(boolFlag==1));
            auxLabel=this.labels(labelIdx(boolFlag==1));
        end
        
        function [newTS,auxLabel]=getDataAsTS(this,label)
            [data,time,auxLabel]=getDataAsVector(this,label);
            newTS=labTimeSeries(data,time(1),this.sampPeriod,auxLabel);
        end
        
        function labelList=getLabels(this)
           labelList=this.labels; 
        end
        
        function [boolFlag,labelIdx]=isaLabel(this,label)
            if isa(label,'char')
                auxLabel{1}=label;
            elseif isa(label,'cell')
                auxLabel=label;
            else
                error('labTimeSeries:isaLabel','label input argument has to be a string or a cell array containing strings.')
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
        
        function data=getSample(this,timePoints) %This does not seem efficient: we are creating a timeseries object (from native Matlab) and using its resample method. 
            if ~isempty(timePoints)
                newTS=resample(this,timePoints,1);
                data=newTS.Data;
            else
                data=[];
            end
        end
        
        function index=getIndexClosestToTimePoint(this,timePoints)
            index=[]; %ToDo
        end
        %-------------------
        
        %Modifier functions:
        function newThis=resample(this,newTs,hiddenFlag) %the newTS is respected as much as possible, but forcing it to be a divisor of the total time range
            if nargin<3 || hiddenFlag==0
                if newTs>this.sampPeriod %Under-sampling! be careful of aliasing
                    warning('labTS:resample','Under-sampling data, be careful of aliasing!');
                end
                newN=ceil(this.timeRange/newTs)+1;
                newThis=resampleN(this,newN);
            else
                newThis=this.resample@timeseries(newTs); %Warning: Treating newTs argument as a vector containing timepoints, not a sampling period. The super-class resampling returns a super-class object.
            end
        end
        
        function newThis=resampleN(this,newN,method) %Same as resample function, but directly fixing the number of samples instead of TS
            if ~isempty(this.Data)
            if nargin<3 || isempty(method)
                 if ~isa(this.Data(1,1),'logical')
                        method='interpft';
                 else
                     method='logical';
                 end
            end
            modNewTs=this.timeRange/(newN);
            newTimeVec=[0:newN-1]*modNewTs+this.Time(1);
            switch method
                case 'interpft'
                    allNaNIdxs=[];
                    if any(isnan(this.Data(:)))
                        if any(all(isnan(this.Data)))
                            allNaNIdxs=all(isnan(this.Data));
                            warning(['All data is NaNs for labels ' strcat(this.labels{allNaNIdxs},' ') ', not interpolating those: returning NaNs'])
                        end
                    end
                    this.Data(:,allNaNIdxs)=0; %Substituting 0's to allow the next line to run without problems
                    if any(isnan(this.Data(:))) %Only if there are still NaNs after the previous step, we will substitute the missing data with linearly interpolated values
                        warning('Trying to interpolate data using Fourier Transform method (''interpft1''), but data contains NaNs (missing values) which will propagate to the full timeseries. Substituting NaNs with linearly interpolated data.')
                        this=substituteNaNs(this,'linear'); %Interpolate time-series that are not all NaN (this is, there are just some values missing)
                    end
                    newData=interpft1(this.Data,newN,1); %Interpolation is done on a nice(r) way.
                    newData(:,allNaNIdxs)=nan; %Replacing the previously filled data with NaNs
                case 'logical'
                   newData=sparse([],[],false,newN,size(this.Data,2),newN);% Sparse logical array of size newN x size(this.Data,2) and room for up to size(this.Data,2) true elements.
                   for i=1:size(this.Data,2) %Go over event labels
                       oldEventTimes=this.Time(this.Data(:,i));
                       closestNewEventIndexes=round((oldEventTimes-this.Time(1))/modNewTs) + 1;
                       newData(closestNewEventIndexes,i)=true;
                   end
                otherwise %Method is 'linear', 'cubic' or any of the accepted methods for interp1
                    newData=zeros(length(newTimeVec),size(this.Data,2));
                    for i=1:size(this.Data,2)
                        newData(:,i)=interp1(this.Time,this.Data(:,i),newTimeVec,method,nan);
                    end
            end
            t0=this.Time(1);
            newThis=labTimeSeries(newData,t0,modNewTs,this.labels);
            else %this.Data==[]
                error('labTimeSeries:resampleN','Interpolating empty labTimeSeries,impossible.')
            end
        end
        
        function newThis=split(this,t0,t1)
           %Check t0>= Time(1)
           %Check t1<= Time(end)
           initT=this.Time(1)-eps;
           finalT=this.Time(end)+eps;
           if ~(t0>= initT && t1<=finalT)
               if (t1<initT) || (t0>=finalT)
                   ME=MException('labTS:split','Given time interval is not (even partially) contained within the time series.');
                   throw(ME)
               else
                   warning('LabTS:split','Requested interval is not completely contained in TimeSeries. Padding with NaNs.')
               end
           end
           %Find portion of requested interval that falls within the
           %timeseries' time vector (if any).
            i1=find(this.Time>=t0,1);
            i2=find(this.Time<t1,1,'last'); %Explicitly NOT including the final sample, so that the time series is returned as the semi-closed interval [t0, t1). This avoids repeated samples if we ask for [t0,t1) and then for [t1,t2)
            if i2<i1
                warning('LabTS:split','Requested interval falls completely within two samples: returning empty timeSeries.') 
            end
            %In case the requested time interval is larger than the
            %timeseries' actual time vector, pad with NaNs:
            if (this.Time(1)-t0)>eps %Case we are requesting time-samples preceding the timeseries' start-time
                ia=floor((this.Time(1)-t0)/this.sampPeriod); %Extra samples to be added at the beginning
            else
                ia=0;
            end
            if (t1-this.Time(end))> eps %Case we are requesting time-samples following the timeseries' end-time
                ib=floor((t1-this.Time(end))/this.sampPeriod); %Extra samples to be added at the end
            else
                ib=0;
            end
            if ~islogical(this.Data(1,1))
                newThis=labTimeSeries([nan(ia,size(this.Data,2)) ; this.Data(i1:i2,:); nan(ib,size(this.Data,2))],this.Time(i1)-this.sampPeriod*ia,this.sampPeriod,this.labels);
            else
                newThis=labTimeSeries([false(ia,size(this.Data,2)) ; this.Data(i1:i2,:); false(ib,size(this.Data,2))],this.Time(i1)-this.sampPeriod*ia,this.sampPeriod,this.labels);
            end
        end
        
        function [data,time,auxLabel]=getPartialDataAsVector(this,label,t0,t1)
            newThis=split(this.getDataAsTS(label),t0,t1);
            [data,time,auxLabel]=getDataAsVector(newThis,label);
        end
        
        function [steppedDataArray,bad,initTime,duration]=splitByEvents(this,eventTS,eventLabel,timeMargin)
           %eventTS needs to be a labTimeSeries with binary events as data
           %If eventLabel is not given, the first data column is used as
           %the relevant event marker. If given, eventLabel must be the
           %label of one of the data columns in eventTS
           
           %Check needed: is eventTS a labTimeSeries?
           if nargin>2
                eventList=eventTS.getDataAsVector(eventLabel);
           else
               eventList=eventTS.Data(:,1);
           end
           %Check needed: is eventList binary?
           N=size(eventList,2); %Number of events & intervals to be found
           auxList=double(eventList)*2.^[0:N-1]'; %List all events in a single vector, by numbering them differently.
           %
           if nargin<4 || isempty(timeMargin)
               timeMargin=0;
           end
           
            refIdxLst=find(auxList==1);
            M=length(refIdxLst)-1;
            auxTime=eventTS.Time;
            aa=auxTime(refIdxLst);
            initTime=aa(1:M); %Initial time of each interval identified
            duration=diff(aa); %Duration of each interval
            steppedDataArray=cell(M,N);
            bad=false(M,1);
            for i=1:M %Going over strides
                t0=auxTime(refIdxLst(i));
                nextT0=auxTime(refIdxLst(i+1));
                lastEventIdx=refIdxLst(i);
                for j=1:N-1 %Going over events
                   nextEventIdx=lastEventIdx+find(auxList(lastEventIdx+1:refIdxLst(i+1)-1)==2^mod(j,N),1,'first');
                   t1= auxTime(nextEventIdx); %Look for next event
                   if ~isempty(t1) && ~isempty(t0)
                        steppedDataArray{i,j}=this.split(t0-timeMargin,t1+timeMargin);
                        t0=t1;
                        lastEventIdx=nextEventIdx;
                   else
                       warning(['Events were not in order on stride ' num2str(i) ', returning empty labTimeSeries.'])
                        if islogical(this.Data)
                            steppedDataArray{i,j}=labTimeSeries(false(0,size(this.Data,2)),zeros(1,0),1,this.labels);
                        else
                            steppedDataArray{i,j}=labTimeSeries(zeros(0,size(this.Data,2)),zeros(1,0),1,this.labels); %Empty labTimeSeries
                        end
                        bad(i)=true;
                   end
                   
                end
                steppedDataArray{i,N}=this.split(t0-timeMargin,nextT0+timeMargin); %This line is executed for the last interval btw events, which is the only one when there is a single event separating (N=1).
            end
        end
        
        function this=times(this,constant)
            this.Data=this.Data*constant;
        end
        
        function newThis=plus(this,other)
            M=size(this.Data,2);
            for i=1:M
                newLabels{i}=['(' this.labels{i} ' + ' other.labels{i} ')'];
            end
            if abs(this.Time(1)-other.Time(1))<eps && abs(this.sampPeriod-other.sampPeriod)<eps && length(this.labels)==length(other.labels)
                newThis=labTimeSeries(this.Data+other.Data,this.Time(1),this.sampPeriod,this.labels);
            end
        end
        
        function newThis=minus(this,other)
            M=size(this.Data,2);
            for i=1:M
                newLabels{i}=['(' this.labels{i} ' - ' other.labels{i} ')'];
            end
            if abs(this.Time(1)-other.Time(1))<eps && abs(this.sampPeriod-other.sampPeriod)<eps && length(this.labels)==length(other.labels)
                newThis=labTimeSeries(this.Data-other.Data,this.Time(1),this.sampPeriod,newLabels);
            end
        end
        
        function newThis=derivate(this,other)
            M=size(this.Data,2);
            newData=[nan(1,M);.5*(this.Data(3:end,:)-this.Data(1:end-2,:));nan(1,M)]/this.sampPeriod;
            for i=1:M
                newLabels{i}=['d/dt ' this.labels{i}];
            end
            newThis=labTimeSeries(newData,this.Time(1),this.sampPeriod,newLabels);
        end
        
        function this=fillts(this) %TODO: Deprecate
            warning('labTS.fillts is being deprecated. Use substituteNaNs instead.')
            this=substituteNaNs(this,'linear');
        end
        
        function newThis=concatenate(this,other)
            %Check if time vectors are the same
            if all(this.Time==other.Time)
                newThis=labTimeSeries([this.Data,other.Data],this.Time(1),this.sampPeriod,[this.labels, other.labels]);
            else
                error('labTimeSeries:concatenate','Cannot concatenate timeseries with different Time vectors.')
            end
        end
        
        function this=substituteNaNs(this,method)
            if nargin<2 || isempty(method)
                method='linear';
            end
            if any(all(isnan(this.Data))) %Returns true if any TS contained in the data is all NaN
                %FIXME: This throws an exception now, but it should just
                %return all NaN labels as all NaN and substitute missing
                %values in the others.
                error('labTimeSeries:substituteNaNs','timeseries contains at least one label that is all NaN. Can''t replace those values (no data to use as reference).')
            end
            newData=zeros(size(this.Data));
            this.Quality=zeros(size(this.Data),'int8');
             for i=1:size(this.Data,2) %Going through labels
                 auxIdx=~isnan(this.Data(:,i)); %Finding indexes for non-NaN data under this label
                 %Saving quality data (to mark which samples were
                 %interpolated)
                 this.Quality(:,i)=~auxIdx; %Matlab's timeseries stores this as int8. I would have preferred a sparse array.
                 this.Data(:,i)=interp1(this.Time(auxIdx),this.Data(auxIdx,i),this.Time,method,0); %Extrapolation values are filled with 0,
             end
             this.QualityInfo.Code=[0 1];
             this.QualityInfo.Description={'good','missing'};
        end
        
        %------------------
        
        %Getters for dependent properties
        function fs=get.sampFreq(this)
            fs=1/this.sampPeriod;
        end
        
        function tr=get.timeRange(this)
            tr=(this.Nsamples)*this.sampPeriod;
        end
        
        function Nsamp=get.Nsamples(this)
            Nsamp=this.TimeInfo.Length;
        end
        
        %Display
        function [h,plotHandles]=plot(this,h,labels,plotHandles,events,color,lineWidth) %Alternative plot: all the traces go in different axes
            if nargin<2 || isempty(h)
                h=figure;
            else
                figure(h)
            end
            N=length(this.labels);
            if nargin<3 || isempty(labels)
                relData=this.Data;
                relLabels=this.labels;
            else
               [relData,~,relLabels]=this.getDataAsVector(labels); 
               N=size(relData,2);
            end
            if nargin<4 || isempty(plotHandles) || length(plotHandles)<length(relLabels)
                [b,a]=getFigStruct(length(relLabels));
                plotHandles=tight_subplot(b,a,[.05 .05],[.05 .05], [.05 .05]); %External function
            end
            if nargin<7 || isempty(lineWidth)
                lineWidth=2;
            end
            ax2=[];
            h1=[];
            for i=1:N
                h1(i)=plotHandles(i);
                subplot(h1(i))
                hold on
                if nargin<6 || isempty(color)
                    plot(this.Time,relData(:,i),'LineWidth',lineWidth)
                else
                    plot(this.Time,relData(:,i),'LineWidth',lineWidth,'Color',color)
                end
                ylabel(relLabels{i})
                %if i==ceil(N/2)
                %    xlabel('Time (s)')
                %end
                hold off
                if nargin>4 && ~isempty(events)
                    [ii,jj]=find(events.Data);
                    [ii,iaux]=sort(ii);
                    jj=jj(iaux);
                    ax1=gca;
                    %ax2(i) = axes('Position',ax1.Position,...
                    %'XAxisLocation','top',...
                    %'YAxisLocation','right',...
                    %'Color','none');%,'XColor','r','YColor','r');
                   set(ax1,'Xtick',events.Time(ii),'XTickLabel',events.labels(jj))
                   grid on
                end
            end
            %linkaxes([h1,ax2],'x')
            plotHandles=h1;  
        end
        
        %Other
        function [F,f]=fourierTransform(this,M)
            if nargin>1
                MM=2^ceil(log2(M)); %Force next power of 2
            else
                MM=this.Nsamples;
            end
            F=fft(this.Data,MM);
            f=[-floor(MM/2):floor(MM/2-1)];
        end
                
    end
    
    methods(Static)
        this=createLabTSFromTimeVector(data,time,labels); %Need to compute appropriate t0 and Ts constants and call the constructor. Tricky if time is not uniformly sampled.
        
        function [alignedTS,originalDurations]=stridedTSToAlignedTS(stridedTS,N) %Need to correct this, so it aligns by all events, as opposed to just aligning the initial time-point
            %To be used after splitByEvents
            if ~islogical(stridedTS{1}.Data(1))
                aux=zeros(sum(N),size(stridedTS{1}.Data,2),size(stridedTS,1));
            else
                aux=false(sum(N),size(stridedTS{1}.Data,2),size(stridedTS,1));
            end
            Nstrides=size(stridedTS,1);
            Nphases=size(stridedTS,2);
            originalDurations=nan(Nstrides,Nphases);
            for i=1:Nstrides %Going over strides
                M=[0,cumsum(N)];
                for j=1:Nphases %Going over aligned phases
                    if isa(stridedTS{i,j},'labTimeSeries')
                        originalDurations(i,j)=stridedTS{i,j}.timeRange;
                        if ~isempty(stridedTS{i,j}.Data)
                            aa=resampleN(stridedTS{i,j},N(j));
                            aux(M(j)+1:M(j+1),:,i)=aa.Data;
                        else %Separating by strides returned empty labTimeSeries, possibly because of events in disorder
                            if islogical(stridedTS{i,j}.Data)
                            	aux(M(j)+1:M(j+1),:,i)=false;
                            else
                                aux(M(j)+1:M(j+1),:,i)=NaN;
                            end
                        end
                    else
                        error('labTimeSeries:stridedTSToAlignedTS',['First argument is not a cell array of labTimeSeries. Element i=' num2str(i) ', j=' num2str(j)])
                    end
                end
            end
            alignedTS=alignedTimeSeries(0,1/sum(N),aux,stridedTS{1}.labels,N,cell(size(N)));
        end
        
        function [figHandle,plotHandles]=plotStridedTimeSeries(stridedTS,figHandle,plotHandles)
                if nargin<2
                    figHandle=[];
                end
                if nargin<3
                    plotHandles=[];
                end
               N=2^ceil(log2(1.5/stridedTS{1}.sampPeriod));
               structure=labTimeSeries.stridedTSToAlignedTS(stridedTS,N);
               [figHandle,plotHandles]=plot(structure,figHandle,plotHandles); %Using the alignedTimeSeries plot function
        end
        
        function this=join(labTSCellArray)
            masterSampPeriod=labTSCellArray{1}.sampPeriod;
            masterLabels=labTSCellArray{1}.labels;
            newData=labTSCellArray{1}.Data;
           for i=2:length(labTSCellArray(:))
               %Check sampling rate & dimensions are consistent, and append
               %at end of data
               if all(cellfun(@strcmp,masterLabels,labTSCellArray{i}.labels)) && masterSampPeriod==labTSCellArray{i}.sampPeriod
                   newData=[newData;labTSCellArray{i}.Data];
               else
                  warning([num2str(i) '-th element of input cell array does not have labels or sampling period consistent with other elements.']); 
               end
               this=labTimeSeries(newData,labTSCellArray{1}.Time(1),masterSampPeriod,masterLabels);
           end
        end
    end
    
        
end

