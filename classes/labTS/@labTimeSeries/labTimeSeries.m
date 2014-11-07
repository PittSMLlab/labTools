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
            if nargin==0 || isempty(data)
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
        
        function newTS=getDataAsTS(this,label)
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
        
        function index=getIndexClosestToTimePoing(this,timePoints)
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
            if nargin<3 || isempty(method)
                 if ~isa(this.Data(1,1),'logical')
                        method='interpft';
                 else
                     method='logical';
                 end
            end
            modNewTs=this.timeRange/(newN);
            switch method
                case 'interpft'
                    newData=interpft1(this.Data,newN,1); %Interpolation is done on a nice(r) way.
                case 'logical'
                   newData=false(newN,size(this.Data,2));
                   newTimeVec=[0:newN-1]*modNewTs+this.Time(1);
                   for i=1:size(this.Data,1)
                       if any(this.Data(i,:))
                           timePoint=this.Time(i);
                           [newTimePoint,newTimeInd]=min(abs(newTimeVec-timePoint));
                           newData(newTimeInd,:)=this.Data(i,:);
                       end
                   end
                otherwise %Method is 'linear', 'cubic' or any of the accepted methods for interp1
                    newData=zeros(length(newTimeVec),size(this.Data,2));
                    for i=1:size(this.Data,2)
                        newData(:,i)=interp1(this.Time,this.Data(:,i),newTimeVec,method);
                    end
            end
            t0=this.Time(1);
            newThis=labTimeSeries(newData,t0,modNewTs,this.labels);
        end
        
        function newThis=split(this,t0,t1)
           %Check t0>= Time(1)
           %Check t1<= Time(end)
           initT=this.Time(1)-2e-15;
           finalT=this.Time(end)+this.sampPeriod+2e-15;
           if ~(t0>= initT && t1<=finalT)
               if (t1<initT) || (t0>=finalT)
                   ME=MException('labTS:split','Given time interval is not (even partially) contained within the time series.');
                   throw(ME)
               else
                   warning('LabTS:split','Requested interval is not completely contained in TimeSeries.')
               end
           end
            i1=find(this.Time>=t0,1);
            i2=find(this.Time<t1,1,'last');
            if i2<i1
                warning('LabTS:split','Requested interval falls completely within two samples: returning empty timeSeries.') 
            end
            newThis=labTimeSeries(this.Data(i1:i2,:),this.Time(i1),this.sampPeriod,this.labels);
        end
        
        function [data,time,auxLabel]=getPartialDataAsVector(this,label,t0,t1)
            newThis=split(this.getDataAsTS(label),t0,t1);
            [data,time,auxLabel]=getDataAsVector(newThis);
        end
        
        function [steppedDataArray,bad,initTime,duration]=splitByEvents(this,eventTS,eventLabel)
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
           auxList=eventList*2.^[0:N-1]';
           
            refIdxLst=find(auxList==1);
            M=length(refIdxLst)-1;
            auxTime=eventTS.Time;
            aa=auxTime(refIdxLst);
            initTime=aa(1:M); %Initial time of each interval identified
            duration=diff(aa); %Duration of each interval
            steppedDataArray=cell(M,N);
            bad=zeros(M,1);
            for i=1:M
                t0=auxTime(refIdxLst(i));
                nextT0=auxTime(refIdxLst(i+1));
                lastEventIdx=refIdxLst(i);
                for j=1:N-1
                   nextEventIdx=lastEventIdx+find(auxList(lastEventIdx+1:refIdxLst(i+1)-1)==2^mod(j,N),1,'first');
                   t1= auxTime(nextEventIdx); %Look for next event
                   if ~isempty(t1) && ~isempty(t0)
                        steppedDataArray{i,j}=this.split(t0,t1);
                        t0=t1;
                        lastEventIdx=nextEventIdx;
                   else
                       	steppedDataArray{i,j}=[];
                        bad(i)=1;
                   end
                   
                end
                steppedDataArray{i,N}=this.split(t0,nextT0);
            end
        end
        
        function this=times(this,constant)
            this.Data=this.Data*constant;
        end
        
        function newThis=plus(this,other)
            if abs(this.Time(1)-other.Time(1))<eps && abs(this.sampPeriod-other.sampPeriod)<eps && length(this.labels)==length(other.labels)
                newThis=labTimeSeries(this.Data+other.Data,this.Time(1),this.sampPeriod,this.labels);
            end
        end
        
        function newThis=minus(this,other)
            if abs(this.Time(1)-other.Time(1))<eps && abs(this.sampPeriod-other.sampPeriod)<eps && length(this.labels)==length(other.labels)
                newThis=labTimeSeries(this.Data-other.Data,this.Time(1),this.sampPeriod,this.labels);
            end
        end
        
        function this=fillts(this)
            for i=1:size(this.Data,2)
                idx=isnan(this.Data(:,i));
                if any(idx)
                    disp([num2str(sum(idx)) ' samples were NaN in ' this.labels{i}])
                    this.Quality=idx;
                    this.QualityInfo.Code=[0 1];
                    this.QualityInfo.Description={'good','missing'};
                    this.Data(:,i)=interp1(this.Time(~idx),this.Data(~idx,i),this.Time,'linear','extrap');
                end
            end
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
        function h=plot(this,h,labels) %Alternative plot: all the traces go in different axes
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
            
            for i=1:N
                h1(i)=subplot(ceil(N/2),2,i);
                hold on
                plot(this.Time,relData(:,i),'.')
                ylabel(relLabels{i})
                hold off
            end
            linkaxes(h1,'x')
                
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
        
        function alignedTS=stridedTSToAlignedTS(stridedTS,N) %Need to correct this, so it aligns by all events, as opposed to just aligning the initial time-point
            %To be used after splitByEvents
            aux=zeros(N,size(stridedTS{1}.Data,2),length(stridedTS));
            for i=1:length(stridedTS)
                aa=resampleN(stridedTS{i},N);
                aux(:,:,i)=aa.Data;
            end
            alignedTS=alignedTimeSeries(0,1/N,aux,stridedTS{1}.labels);
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

