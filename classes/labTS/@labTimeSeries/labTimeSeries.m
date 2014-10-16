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
            boolFlag=zeros(N,1);
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
                newThis=this.resample@timeseries(newTs); %Warning: Treating newTs argument as a vector containing timepoints, not a sampling period!!!
            end
        end
        
        function newThis=resampleN(this,newN) %Same as resample function, but directly fixing the number of samples instead of TS
            modNewTs=this.timeRange/(newN);
            if ~isa(this.Data(1,1),'logical')
                newData=interpft1(this.Data,newN,1); %Interpolation is done on a nice(r) way.
            else
               newData=false(newN,size(this.Data,2));
               newTimeVec=[0:newN-1]*modNewTs+this.Time(1);
               for i=1:size(this.Data,1)
                   if any(this.Data(i,:))
                       timePoint=this.Time(i);
                       [newTimePoint,newTimeInd]=min(abs(newTimeVec-timePoint));
                       newData(newTimeInd,:)=this.Data(i,:);
                   end
               end
            end
            newThis=labTimeSeries(newData,this.Time(1),modNewTs,this.labels);
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
        
        function steppedDataArray=splitByEvents(this,eventTS,eventLabel)
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
            refIdxLst=find(eventList==1);
            auxTime=eventTS.Time;
            steppedDataArray={};
            for i=1:length(refIdxLst)-1
                steppedDataArray{i}=this.split(auxTime(refIdxLst(i)),auxTime(refIdxLst(find(refIdxLst(:)>refIdxLst(i),1,'first'))));
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
    end
    
        
end

