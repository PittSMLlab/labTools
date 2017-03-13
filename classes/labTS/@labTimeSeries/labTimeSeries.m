classdef labTimeSeries  < timeseries
    %labTimeSeries  Extends timeseries (built-in MATLAB class) to meet
    %               our lab's needs for storing data.
    %
    %labTimeSeries properties:
    %   labels - cell array of strings with labels for the columns of Data
    %   sampPeriod - time between samples, equal to 1/sampFreq
    %   sampFreq - sampling rate in Hz, equal to 1/sampPeriod
    %   Nsamples - total number of samples in timeSeries
    %   Data - matrix of data values, size is Nsamples x length(labels)
    %   Time - time values corresponding to each sample
    %   Length - should be same as Nsamples
    %
    %labTimeSeries methods:
    %   getDataAsVector - get a vector of data for a given label
    %   getDataAsTS - returns a new labTimeSeries with data for given label(s) 
    %   getLabels - returns list of labels
    %   isaLabel - checks if a string is contained in label array
    %   plot - plots data...
    
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
                time=[0:size(data,1)-1]*Ts+t0';
            end
            this=this@timeseries(data,time);
            this.sampPeriod=Ts;
            if (length(labels)==size(data,2)) && isa(labels,'cell')
                this.labels=labels;
            else
                ME=MException('labTimeSeries:ConstructorInconsistentArguments','The size of the labels array is inconsistent with the data being provided.');
                throw(ME)
            end
            %Check for repeat labels:
            labels2=unique(lower(labels));
            if length(labels2)<length(labels)
                ME=MException('labTimeSeries:ConstructorRepeatedLabels','Two labels provided are the same (caps don''t matter).');
                    throw(ME)
            end
        end
        
        %-------------------
        
        %Other I/O functions:
        function [data,time,auxLabel]=getDataAsVector(this,label)
            if nargin<2 || isempty(label)
                label=this.labels;
            end
            if isa(label,'char')
                auxLabel={label};
            else
                auxLabel=label;
            end
            time=this.Time;
            [boolFlag,labelIdx]=this.isaLabel(auxLabel);
            for i=1:length(boolFlag)
                if ~boolFlag(i)
                    warning(['Label ' auxLabel{i} ' is not a labeled dataset in this timeSeries.'])
                end
            end
            
            data=this.Data(:,labelIdx(boolFlag));
            if nargout>2
                auxLabel=this.labels(boolFlag);
            end
        end
        
        function [newTS,auxLabel]=getDataAsTS(this,label)
            [data,time,auxLabel]=getDataAsVector(this,label);
            newTS=labTimeSeries(data,time(1),this.sampPeriod,auxLabel);
        end
        
        function labelList=getLabels(this)
           labelList=this.labels; 
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
        
        function [boolFlag,labelIdx]=isaLabel(this,label)
            if isa(label,'char')
                auxLabel{1}=label;
            elseif isa(label,'cell')
                auxLabel=label;
            else
                error('labTimeSeries:isaLabel','label input argument has to be a string or a cell array containing strings.')
            end
            auxLabel=auxLabel(:);
            N=length(auxLabel);
            M=length(this.labels);
            if N==M && all(strcmpi(auxLabel,this.labels(:))) %Case in which the list is identical to the label list, save time by not calling find() recursively. 
                %If this is true, it saves about 50ms per call, or 5 secs every 100 calls
                %If false, it adds a small overhead of less than .1ms per call, which is negligible compared to the loop that needs to be performed.
                boolFlag=true(N,1);
                labelIdx=1:M;
            else
                boolFlag=false(N,1);
                labelIdx=zeros(N,1);
                idxList=1:M;
                for j=1:N
                    %Alternative efficient formulation: (when running
                    %removeAltBias for a group of 16 subjects, this change
                    %shaves 180s of processing, which is roughly 85% of total
                    %processing time!)
                    aux=strcmpi(auxLabel{j},this.labels);
                    if any(aux)
                        boolFlag(j)=true;
                        labelIdx(j)=idxList(aux); %This will fail if there are repeated elements in list
                    end
                end
            end
        end
        
        function data=getSample(this,timePoints,method) %This does not seem efficient: we are creating a timeseries object (from native Matlab) and using its resample method. 
            if nargin<3 || isempty(method)
                method='linear';
            end
            
            if ~isempty(timePoints)
                M=length(this.labels);
                data=nan(numel(timePoints),M);
                switch method
                    case 'linear'
                        notNaNIdxs=~isnan(timePoints) & ~isinf(timePoints) & timePoints<this.Time(end) & timePoints>this.Time(1); %Excluding NaNs, Infs and out-of-range times from interpolation.
                        [notNaNTimes,sorting]=sort(timePoints(notNaNIdxs),'ascend');
                        newTS=resample(this,notNaNTimes,this.Time(1),1); %Using timeseres.resample which does linear interp by default

                        newTS.Data(sorting,:)=newTS.Data;
                        data(notNaNIdxs,:)=newTS.Data;
                    case 'closest'
                        aux=this.getIndexClosestToTimePoint(timePoints(:));
                        data(~isnan(aux),:)=this.Data(aux(~isnan(aux)),:);
                end
                data=reshape(data,[size(timePoints),M]);
            else
                data=[];
            end
        end
        
        function index=getIndexClosestToTimePoint(this,timePoints)
            %NaN returns NaN
            
            %aux=abs(bsxfun(@minus,this.Time(:),timePoints(:)'))<=(this.sampPeriod/2+eps);
            %[ii,jj]=find(aux);
            %index=nan(size(timePoints));
            %index(jj)=ii;
            index=round((timePoints(:)-this.Time(1))/this.sampPeriod)+1;
            index(index<1)=1;
            index(index>numel(this.Time))=numel(this.Time);
            index=reshape(index,size(timePoints));
            %Check
            %if any(abs(this.Time(index(:))-timePoints(:))>(this.sampPeriod/2-eps))
            %    error('Non consistent indexes found')
            %end
        end
        %-------------------
        
        %Modifier functions:
        function newThis=resample(this,newTs,newT0,hiddenFlag)
            if nargin<3 || isempty(newT0)
                error('labTS:resample','Resampling using only the new sampling period as argument is no longer supported. Use resampleN if you want to interpolate keeping the exact same time range.')
            end
            if nargin<4 || hiddenFlag==0 %hiddenFlag allows to do non-uniform sampling
                if newTs>this.sampPeriod %Under-sampling! be careful of aliasing
                    warning('labTS:resample','Under-sampling data, be careful of aliasing!');
                end
                %Commented on 4/4/2015 by Pablo. No longer think this is a
                %good idea. If we are explicitly trying to do uniform
                %resampling on the same range, should use resampleN.
                %Otherwise, if we try to synch two signals, and there is an
                %offset in initial time, this returns something else.
                
                %newN=ceil(this.timeRange/newTs)+1;
                %newThis=resampleN(this,newN);
                newTime=newT0:newTs:this.Time(end);
                 if ~isa(this.Data(1,1),'logical')
                        newThis=this.resample@timeseries(newTime);
                        newThis=labTimeSeries(newThis.Data,newThis.Time(1),newTs,this.labels);
                 else %logical timeseries
                       newThis=resampleLogical(this,newTs,newT0);
                 end
                
            elseif hiddenFlag==1% this allows for non-uniform resampling, and returns a timeseries object.
                newThis=this.resample@timeseries(newTs); %Warning: Treating newTs argument as a vector containing timepoints, not a sampling period. The super-class resampling returns a super-class object.
            else
                error('labTS:resample','HiddenFlag argument has to be 0 or 1');
            end
        end
        
        function newThis=resampleN(this,newN,method)
            %Uniform resampling of data, over the same time range. This
            %keeps the initial time on the same value, and returns newN
            %time-samples in the time interval of the original timeseries
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
                   newThis=resampleLogical(this,modNewTs,this.Time(1),newN);
                   newData=newThis.Data;
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
            
            %Need to test this chunk of code before enabling:
            %if isnan(t0) || isnan(t1)
            %    warning('labTS:split','One of the interval limits is NaN. Returning empty TS.')
            %    newTS=[];
            %    return
            %end
            
           %Check t0>= Time(1)
           %Check t1<= Time(end)
           initT=this.Time(1)-eps;
           finalT=this.Time(end)+eps;
           if ~(t0>= initT && t1<=finalT)
               if (t1<initT) || (t0>=finalT)
                   ME=MException('labTS:split','Given time interval is not (even partially) contained within the time series.');
                   throw(ME)
               else
                   warning('LabTS:split',['Requested interval [' num2str(t0) ',' num2str(t1) '] is not completely contained in TimeSeries. Padding with NaNs.'])
               end
           end
           %Find portion of requested interval that falls within the
           %timeseries' time vector (if any).
            i1=find(this.Time>=t0,1);
            i2=find(this.Time<t1,1,'last'); %Explicitly NOT including the final sample, so that the time series is returned as the semi-closed interval [t0, t1). This avoids repeated samples if we ask for [t0,t1) and then for [t1,t2)
            if i2<i1
                warning('LabTS:split',['Requested interval [' num2str(t0) ',' num2str(t1) '] falls completely within two samples: returning empty timeSeries.']) 
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
            if ~isempty(this.Quality)
                newThis.QualityInfo=this.QualityInfo;
                k=find(strcmp(this.QualityInfo.Description,'missing'));
                newThis.Quality=[k*ones(ia,size(this.Quality,2)) ; this.Quality(i1:i2,:); k*ones(ib,size(this.Quality,2))];
            end
        end
        
        function newThis=appendData(this,newData,newLabels) %For back compat
            other=labTimeSeries(newData,newLabels,this.Time(1),this.sampPeriod);
            newThis=cat(this,other);
        end
        
        function newThis=addNewParameter(this,newParamLabel,funHandle,inputParameterLabels)
           %This function allows to compute new parameters from other existing parameters and have them added to the data.
           %This is useful when trying out new parameters without having to
           %recompute all existing parameters.
           %INPUT:
           %newPAramLAbel: string with the name of the new parameter
           %funHandle: a function handle with N input variables, whose
           %result will be used to compute the new parameter
           %inputParameterLabels: the parameters that will replace each of
           %the variables in the funHandle
           %EXAMPLE:
           %See example in parameterSeries
           
           %Check input sanity:
           if length(inputParameterLabels)~=nargin(funHandle)
               error('labTS:addNewParameter','Number of input arguments in function handle and number of labels in inputParameterLabels should be the same')
           end
           oldData=this.getDataAsVector(inputParameterLabels);
           str='(';
           for i=1:size(oldData,2)
               str=[str 'oldData(:,' num2str(i) '),'];
           end
           str(end)=')'; %Replacing last comma with parenthesis
           eval(['newData=funHandle' str ';']);
           newThis=appendData(this,newData,{newParamLabel}) ;
        end
        
        function newThis=castAsOTS(this)
            error('Unimplemented')
            newThis=this; %Doxy
        end
        function newThis=castAsSTS(this,F,tWin,tOverlap)
            %1) Check if it satisfies STS requirements
            dataF=this.Data;
            labelsF=this.labels;
            t0=this.Time(1);
            Ts=this.sampPeriod;
            spectroTimeSeries.inputArgsCheck(dataF,labelsF,t0,Ts,F,tWin,tOverlap)
            newThis=spectroTimeSeries(dataF,labelsF,t0,Ts,F,tWin,tOverlap);
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
                            steppedDataArray{i,j}=labTimeSeries(false(0,size(this.Data,2)),0,1,this.labels);
                        else
                            steppedDataArray{i,j}=labTimeSeries(zeros(0,size(this.Data,2)),0,1,this.labels); %Empty labTimeSeries
                        end
                        bad(i)=true;
                   end
                   
                end
                steppedDataArray{i,N}=this.split(t0-timeMargin,nextT0+timeMargin); %This line is executed for the last interval btw events, which is the only one when there is a single event separating (N=1).
            end
        end
        
        function [slicedTS,initTime,duration]=sliceTS(this,timeBreakpoints,timeMargin)
          %Slices a single timeseries into a cell array of smaller timeseries, breaking at the given timeBreakpoints
          for i=1:length(timeBreakpoints)-1
              slicedTS{i}=this.split(timeBreakpoints(i)-timeMargin,timeBreakpoints(i+1)+timeMargin);
          end
            initTime=timeBreakpoints(1:end-1)-timeMargin;
            duration=diff(timeBreakpoints)+2*timeMargin;
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
        
        function newThis=derivate(this)
            M=size(this.Data,2);
            newData=[nan(1,M);.5*(this.Data(3:end,:)-this.Data(1:end-2,:));nan(1,M)]/this.sampPeriod;
            newLabels={};
            for i=1:M
                newLabels{i}=['d/dt ' this.labels{i}];
            end
            newThis=labTimeSeries(newData,this.Time(1),this.sampPeriod,newLabels);
        end
        
        function newthis=equalizeEnergyPerChannel(this)
            %Equalizes each channel such that the second moment of each
            %channel equals 1, E(x^2)=1
            newthis=this;
            newthis.Data=bsxfun(@rdivide,this.Data,sqrt(nanmean(this.Data.^2,1)));
        end
        
        function newthis=equalizeVarPerChannel(this)
            %Equalizes each channel such that the second moment  about the mean of each
            %channel equals 1, E((x-E(x))^2)=1
            newthis=this;
            newthis.Data=bsxfun(@rdivide,this.Data,sqrt(nanvar(this.Data,[],1)));
        end
        
        function newthis=demean(this)
            newthis=this;
            newthis.Data=bsxfun(@minus,this.Data,nanmean(this.Data));
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
        function newThis=cat(this,other)
            newThis=concatenate(this,other);
        end
        
        function this=substituteNaNs(this,method)
            if nargin<2 || isempty(method)
                method='linear';
            end
            if any(all(isnan(this.Data))) %Returns true if any TS contained in the data is all NaN
                %FIXME: This throws an exception now, but it should just
                %return all NaN labels as all NaN and substitute missing
                %values in the others.
                warning('labTimeSeries:substituteNaNs','timeseries contains at least one label that is all NaN. Can''t replace those values (no data to use as reference), setting to 0.')
                this.Data(:,all(isnan(this.Data)))=0;
            end
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
        
        function newThis=thresholdByChannel(this,th,label,moreThanFlag)
            newThis=this;
            if nargin<4 || isempty(moreThanFlag) || moreThanFlag==0
                newThis.Data(newThis.getDataAsVector(label)<th,:)=0;
            elseif moreThanFlag==1
                newThis.Data(newThis.getDataAsVector(label)>th,:)=0;
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
            if any(~isreal(relData(:)))
                warning('labTimeSeries:plot','Data is complex, plotting the modulus only.')
                relData=abs(relData);
            end
            for i=1:N
                h1(i)=plotHandles(i);
                subplot(h1(i))
                hold on
                if nargin<6 || isempty(color)
                    pp=plot(this.Time,relData(:,i),'LineWidth',lineWidth);
                else
                    pp=plot(this.Time,relData(:,i),'LineWidth',lineWidth,'Color',color);
                end
                uistack(pp,'top')
                ylabel(relLabels{i})
                %if i==ceil(N/2)
                %    xlabel('Time (s)')
                %end
                hold off
                if nargin>4 && ~isempty(events)
                    lls={'LHS','RTO','RHS','LTO'};
                    [ii,jj]=find(events.getDataAsTS(lls).Data);
                    [ii,iaux]=sort(ii);
                    jj=jj(iaux);
                    ax1=gca;
                    %ax2(i) = axes('Position',ax1.Position,...
                    %'XAxisLocation','top',...
                    %'YAxisLocation','right',...
                    %'Color','none');%,'XColor','r','YColor','r');
                    %[tt,i2]=unique(events.Time(ii));
                   set(ax1,'XTick',events.Time(ii),'XTickLabel',lls(jj))
                   grid on
                end
            end
            %linkaxes([h1,ax2],'x')
            plotHandles=h1;  
        end
        function [h,plotHandles]=plotAligned(this,h,labels,plotHandles,events,color,lineWidth)
            error('Unimplemented')
            %First attempt: align the data to the first column of events
            %provided
            for i=1:length(ee)
               this.split(t1,t2).plot 
            end
        end
        
        function [h,plotHandles]=bilateralPlot(this,h,labels,plotHandles,events,color,lineWidth)
            %Ideally we would plot 'L' and 'R' timeseries on top of each
            %other, to do a bilateral comparison. Need to implement.
            if nargin<2 || isempty(h)
                h=figure;
            else
                figure(h)
            end
            if nargin<5 || isempty(events)
                events=[];
            end
            if nargin<6 || isempty(color)
                color=[];
            end
            if nargin<3 || isempty(labels)
                labels=this.labels;
            end
            suffix=unique(cellfun(@(x) x(2:end),labels,'UniformOutput',false));
            if nargin<4 || isempty(plotHandles) || length(plotHandles)<length(suffix)
                [b,a]=getFigStruct(length(suffix));
                plotHandles=tight_subplot(b,a,[.05 .05],[.05 .05], [.05 .05]); %External function
            end
            if nargin<7 || isempty(lineWidth)
                lineWidth=2;
            end
            [h,plotHandles]=plot(this,h,strcat('L',suffix),plotHandles,events,color,lineWidth);
            [h,plotHandles]=plot(this,h,strcat('R',suffix),plotHandles,events,color,lineWidth);
            for i=1:length(suffix)
                subplot(plotHandles(i))
                ylabel(suffix{i})
                if i==length(suffix)
                legend('L','R')
                end
            end
        end
        
        function h=dispCov(this)
           h=figure;
           dd=cov(this.Data);
           imagesc(dd)
           set(gca,'XTick',1:length(this.labels),'XTickLabels',this.labels,'XTickLabelRotation',90,'YTick',1:length(this.labels),'YTickLabels',this.labels,'YTickLabelRotation',0)
           colorbar
           caxis([-1 1]*max(dd(:)));
        end
        
        %Other
        function Fthis=fourierTransform(this,M) %Changed on Apr 1st 2015, to return a timeseries. Now ignores second argument
            if nargin>1
                warning('labTimeSeries:fourierTransform','Ignoring second argument')
            end
            [F,f] = DiscreteTimeFourierTransform(this.Data,this.sampFreq);
            Fthis=labTimeSeries(F,f(1),f(2)-f(1),strcat(strcat('F(',this.labels),')'));
            Fthis.TimeInfo.Units='Hz';
        end
        
        function Sthis=spectrogram(this,labels,nFFT,tWin,tOverlap)
            if nargin<2
                labels=[];
            end
            if nargin<3
                nFFT=[];
            end
            if nargin<4
                tWin=[];
            end
            if nargin<5
                tOverlap=[];
            end
            Sthis = spectroTimeSeries.getSTSfromTS(this,labels,nFFT,tWin,tOverlap);
        end
        
        function [Athis,originalDurations,bad,initTime]=align(this,eventTS,eventLabel,N,timeMargin)
            if nargin<4 || isempty(N)
                N=256;
            end
            if nargin<5 || isempty(timeMargin)
                timeMargin=0;
            end
            [steppedDataArray,bad,initTime,~]=splitByEvents(this,eventTS,eventLabel,timeMargin);
            [Athis,originalDurations]=labTimeSeries.stridedTSToAlignedTS(steppedDataArray,N);
        end
        
        function newThis=lowPassFilter(this,fcut)
                Wn=fcut*2/this.sampFreq;
                Wst=min([2*Wn,Wn+.2*(1-Wn)]);
               filterList{1}=fdesign.lowpass('Fp,Fst,Ap,Ast',Wn,Wst,3,10); %
                lowPassFilter=design(filterList{1},'butter'); 
                newData=filtfilthd(lowPassFilter,this.Data);  %Ext function
                newThis=labTimeSeries(newData,this.Time(1),this.sampPeriod,this.labels);
                if ~isfield(this.UserData,'processingInfo')
                    this.UserData.processingInfo={};
                end
                newThis.UserData=this.UserData;
                newThis.UserData.processingInfo{end+1}=filterList{1};
        end
        function newThis=highPassFilter(this,fcut)
                Wn=fcut*2/this.sampFreq;
                filterList{1}=fdesign.highpass('Fst,Fp,Ast,Ap',Wn/2,Wn,10,3); 
                highPassFilter=design(filterList{1},'butter'); 
                newData=filtfilthd(highPassFilter,this.Data); 
                newThis=labTimeSeries(newData,this.Time(1),this.sampPeriod,this.labels);
                if ~isfield(this.UserData,'processingInfo')
                    this.UserData.processingInfo={};
                end
                newThis.UserData=this.UserData;
                newThis.UserData.processingInfo{end+1}=filterList{1};
        end
        
        function newThis=monotonicFilter(this,Nderiv,Nreg)
            if nargin<2 || isempty(Nderiv)
                Nderiv=2;
            end
            if nargin<3 || isempty(Nreg)
               Nreg=2; 
            end
            for i=1:size(this.Data,2)
               this.Data(:,i)=monoLS(this.Data(:,i),[],Nderiv,Nreg); 
            end
            newThis=this;
        end
        
        function this=medianFilter(this,N)
            if mod(N,2)==0
                error('Only odd filter orders are allowed')
                %This actually works with even orders, but then the data
                %gets shifted by half a sample, which is undesirable.
            end

            %this.Data=medfilt1(this.Data,N,1,'omitnan'); %altered 12/4/2015 "omitnan" is not a valid input to medfilt1 in 2015a, 'omitnan' allowed for the median to be taken among the non-NaN elemets
            this.Data=medfilt1(double(this.Data),double(N),double(1)); %This back-compatible alternative works as if the last argument were 'includenan' (i.e. whenever there is a NaN in the window, the result is NaN)
            %Setting the samples outside the filter to NaN:
            this.Data(1:floor(N/2),:)=NaN;
            this.Data(end-floor(N/2)+1:end,:)=NaN;
        end
                
    end
    
    methods(Hidden)
        function newThis=resampleLogical(this,newTs, newT0,newN)
            newTime=[0:newN-1]*newTs+newT0;
            newN=length(newTime);
            newData=sparse([],[],false,newN,size(this.Data,2),newN);% Sparse logical array of size newN x size(this.Data,2) and room for up to size(this.Data,2) true elements.
           for i=1:size(this.Data,2) %Go over event labels
               oldEventTimes=this.Time(this.Data(:,i)); %Find time of old events
               closestNewEventIndexes=round((oldEventTimes-newT0)/newTs) + 1; %Find closest index in new event 
               if any(closestNewEventIndexes>newN) %It could happen in case of down-sampling that the closest new index falls outside the range
                   %Option 1: set it to the last available sample (this
                   %would no longer be 'rounding')
                   closestNewEventIndexes(closestNewEventIndexes>newN)=newN;
                   %Option 2: eliminate event, as it falls outside range.
                   %This may cause failure of other functions that rely on
                   %down-sampling of events not changing the number of
                   %events
                   closestNewEventIndexes(closestNewEventIndexes>newN)=[];
               end
               
               newData(closestNewEventIndexes,i)=true;
           end
           newThis=labTimeSeries(newData,newT0,newTs,this.labels);
        end
    end
    
    methods(Static)
        this=createLabTSFromTimeVector(data,time,labels); %Need to compute appropriate t0 and Ts constants and call the constructor. Tricky if time is not uniformly sampled.
        
        function [alignedTS,originalDurations]=stridedTSToAlignedTS(stridedTS,N) %Need to correct this, so it aligns by all events, as opposed to just aligning the initial time-point
            %To be used after splitByEvents
            if numel(stridedTS)~=0
            if ~islogical(stridedTS{1}.Data)
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
            else
                alignedTS=alignedTimeSeries(0,1/sum(N),zeros(0,0),[],N,cell(size(N)));
                originalDurations=[];
            end
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

