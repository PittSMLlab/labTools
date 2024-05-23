classdef labTimeSeries  < timeseries
    %labTimeSeries  Extends timeseries (built-in MATLAB class) to meet
    %               our lab's needs for storing data. Forces timeseries to
    %               be uniformly sampled.
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
    %   getLabelsThatMatch - returns list of labels that match a given string
    %   isaLabel - checks if a string is contained in label array
    %   getSample - samples the timeseries at arbitrary timepoints
    %   resample - resamples timeseries to a different sampling period
    %   split - returns a timeseries containing the data between to given timepoints
    %   appendData - adds more data to the timeseries (As new 'labels')
    %   addNewParameter - adds data to TS computing it from existing data
    %   getPartialDataAsVector - returns data corresponding to some labels in matrix form
    %   splitByEvents - separates the timeseries according to the events given in an event (boolean) timeseries
    %   derivate - differentiates the timeseries in time
    %   fillts - substitutes NaN values by interpolation
    %   concatenate/cat - merges two timeseries into a single one
    %   lowPassFilter - what the name says
    %   highPassFilter - what the name says
    %   monotonicFilter - calls monoLS on the data for each column
    %   medianFilter - what the name says
    %   FourierTransform - what the name says
    %   plot - plots data

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
            [~,i1,i2]=unique(lower(labels));
            if length(i1)<length(labels)
                repIdx=find((sort(i1)-[1:length(i1)]')~=0,1,'first');
                if isempty(repIdx)
                    repIdx=length(i1)+1;
                end
                ME=MException('labTimeSeries:ConstructorRepeatedLabels',['Found ' num2str(length(labels)-length(i1)) ' collisions of label names. First collision is: ' labels{repIdx}]);
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
            if ~any(boolFlag)
                auxLabel2=[];
                for i=1:length(auxLabel)
                    auxLabel2=[auxLabel2 this.getLabelsThatMatch(auxLabel{i})];
                end
                [boolFlag,labelIdx]=this.isaLabel(auxLabel2);
                NN=numel(auxLabel2);
                warning(['None of the provided labels are a parameter in this timeSeries. Trying to return labels that match the provided label as a regular expression: found ' num2str(NN) ' matches.'])
                else
                    for i=1:length(boolFlag)
                        if ~boolFlag(i)
                            warning(['Label ' auxLabel{i} ' is not a labeled dataset in this timeSeries.'])
                        end
                    end
                end

            data=this.Data(:,labelIdx(boolFlag));
            if nargout>2
                auxLabel=this.labels(labelIdx(boolFlag));
            end
        end

        function [newTS,auxLabel]=getDataAsTS(this,label)
            [data,time,auxLabel]=getDataAsVector(this,label);
            newTS=labTimeSeries(data,time(1),this.sampPeriod,auxLabel);
        end

        function labelList=getLabels(this)
           labelList=this.labels;
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
            this.labels(idx(boo))=newLabels(boo);
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
                [boolFlag,labelIdx] = compareListsFast(this.labels,auxLabel);
            end
        end

        function data=getSample(this,timePoints,method) %This does not seem efficient: we are creating a timeseries object (from native Matlab) and using its resample method.
            if nargin<3 || isempty(method)
                if isa(this.Data,'logical')
                    method='closest';
                else
                    method='linear';
                end
            end

            if ~isempty(timePoints)
                M=length(this.labels);
                switch method
                    case 'linear'
                        data=nan(numel(timePoints),M);
                        notNaNIdxs=~isnan(timePoints) & ~isinf(timePoints) & timePoints<this.Time(end) & timePoints>this.Time(1); %Excluding NaNs, Infs and out-of-range times from interpolation.
                        [notNaNTimes,sorting]=sort(timePoints(notNaNIdxs),'ascend');
                        newTS=resample(this,notNaNTimes,this.Time(1),1); %Using timeseres.resample which does linear interp by default

                        newTS.Data(sorting,:)=newTS.Data;
                        data(notNaNIdxs,:)=newTS.Data;
                    case 'closest'
                        data=nan(numel(timePoints),M);
                        aux=this.getIndexClosestToTimePoint(timePoints(:));
                        inds=~isnan(aux);
                        aux=aux(inds); %Eliminating NaNs
                        newData=this.Data(aux,:); %This would be the new data in the simplest case.
                        initData=newData;
                        %But, if two samples map to the same timePoint (sub-sampling) and that timePoint corresponds 
                        %to an event, just keep the closest one, to avoid repeating events.
                        trueEventSamples=unique(aux(any(newData,2) & [diff(aux);1]==0)); %Unique samples that contain an event
                        tt=this.Time(trueEventSamples);
                        for i=1:length(trueEventSamples)
                            mappedInds=find(aux==trueEventSamples(i));
                            relevantTimePoints=timePoints(mappedInds);
                            Dt=abs(tt(i)-relevantTimePoints);
                            jj=find(Dt==min(Dt),1,'first'); %The find() is needed to resolve ties
                            mappedInds(jj)=[];
                            newData(mappedInds,:)=0;
                        end
                        
                        data(inds,:)=newData;
%                         %Sanity check, this can be deprecated if no errors
%                         %found by Jan 1st 2018. [implemented Sept 11 2017]
%                         %Check that #events did not change:
%                         if any(sum(newData)~=sum(this.split(min(timePoints(:))-this.sampPeriod/2,max(timePoints(:))+this.sampPeriod).Data))
%                             error('Something went wrong when resampling: number of events changed')
%                         end
%                         %Check that no event is present at a sample where
%                         %it was previously not:
%                         if any(any(newData & ~initData))
%                             error('Something went wrong when resampling: event location changed')
%                         end
                        %TODO: add interpft1 interpolation as possible
                        %method, provided that the timepoints are equally
                        %spaced.
                end
                data=reshape(full(data),[size(timePoints),M]); %Can't have sparse ND matrices (WHY??)
            else
                data=[];
            end
        end
        
        function newTS=synchTo(this,otherTS)
           %Resamples the timeseries assuring that the new time vector coincides with that of otherTS. Pads with NaN if necessary.
           if ~islogical(this.Data)
                method=[];
           else
               method='closest';
           end
           data=squeeze(this.getSample(otherTS.Time,method));
           newTS=labTimeSeries(data,otherTS.Time(1),otherTS.sampPeriod,this.labels);
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
            this.Quality=[]; %So that Quality is not resample if it exists.
            if nargin<3 || isempty(newT0)
                error('labTS:resample','Resampling using only the new sampling period as argument is no longer supported. Use resampleN if you want to interpolate keeping the exact same time range.')
            end
            if nargin<4 || isempty(hiddenFlag) || hiddenFlag==0 %hiddenFlag allows to do non-uniform sampling
                if newTs>this.sampPeriod %Under-sampling! be careful of aliasing
                    warning('labTS:resample','Under-sampling data, be careful of aliasing!');
                end
                %Commented on 4/4/2015 by Pablo. No longer think this is a
                %good idea. If we are explicitly trying to do uniform
                %resampling on the same range, should use resampleN.
                %Otherwise, if we try to synch two signals, and there is an
                %offset in initial time, this returns something else.

                newN=ceil(this.timeRange/newTs)+1;
                %newThis=resampleN(this,newN);
                newTime=newT0:newTs:this.Time(end);
                 if ~isa(this.Data(1,1),'logical')
                        newThis=this.resample@timeseries(newTime);
                        newThis=labTimeSeries(newThis.Data,newThis.Time(1),newTs,this.labels);
                 else %logical timeseries
                       newThis=resampleLogical(this,newTs,newT0,newN);
                       %Can be this deprecated in favor of just using
                       %getSample() for a logical TS?
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
           % finalT=this.Time(end)+eps;%SL commented out, this will throw warning when trying to get the last sample
           %the original intention was good to do [t0,t1) to avoid repeated sample,
           %but the last sample (Time(end)) was never retrievable with this approach.
           finalT = this.Time(end) + this.sampPeriod;%To get the last sample without warning.
           if ~(t0>= initT && t1<=finalT)
               if (t1<initT) || (t0>=finalT)
                   %ME=MException('labTS:split','Given time interval is not (even partially) contained within the time series.');
                   %throw(ME)
			        warning('LabTS:split',['Requested interval [' num2str(t0) ',' num2str(t1) '] is fully outside the timeseries. Padding with NaNs.'])
               else
                   warning('LabTS:split',['Requested interval [' num2str(t0) ',' num2str(t1) '] is not completely contained in TimeSeries. Padding with NaNs.'])
               end
           end
           %Find portion of requested interval that falls within the
           %timeseries' time vector (if any).
            i1=find(this.Time>=t0,1);
            i2=find(this.Time<t1,1,'last'); %Explicitly NOT including the final sample, so that the time series is returned as the semi-closed interval [t0, t1). This avoids repeated samples if we ask for [t0,t1) and then for [t1,t2)
            %SL: this will never be able to find the last sample
            %if set t1 = this.Time(end)+eps, this.Time(end) < t1 evaluates
            %to false (eps is machine precision, too small to make the
            %boolean eval true? This may be a Matlab precision issue)
            if isempty(i1) || isempty(i2) %This happens when the whole timeseries is outside the range
		i1=1;
		i2=0;
	    elseif i2<i1 %When this happens the last included sample precedes the first included one, which happens, because of rounding, when asking for a very small interval (smaller than the sample period).
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

        function [newThis,newData]=addNewParameter(this,newParamLabel,funHandle,inputParameterLabels)
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

           [newData]=computeNewParameter(this,newParamLabel,funHandle,inputParameterLabels);
           newThis=appendData(this,newData,{newParamLabel}) ;
        end
        
        function [newData]=computeNewParameter(this,newParamLabel,funHandle,inputParameterLabels)
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
           %See also: addNewParameter
           
           %TO DO: support many new parameters together, as long as they
           %use the same funHandle, with inputParameterLabels an NxM array,
           %where N is the size of newParamLabel (# parameters to be
           %computed). Use this change in
           %linearStretch(this,labels,rangeValues) for efficiency
           
           %Check input sanity:
           if length(inputParameterLabels)~=nargin(funHandle)
               error('labTS:addNewParameter','Number of input arguments in function handle and number of labels in inputParameterLabels should be the same')
           end
           if compareListsFast(this.labels,newParamLabel)
               error('labTS:addNewParameter','Cannot add parameter because it already exists')
           end
           oldData=this.getDataAsVector(inputParameterLabels);
           str='(';
           for i=1:size(oldData,2)
               str=[str 'oldData(:,' num2str(i) '),'];
           end
           str(end)=')'; %Replacing last comma with parenthesis
           eval(['newData=funHandle' str ';']); %Isn't there a way to do this without eval?
        end
        
        function newThis=removeParameter(labels)
            [bool,idxs] = compareLists(this.labels,labels);
            if any(~bool)
                warning([{'Could not remove some parameters because they are not present: '} labels(~bool)])
            end
            newThis=this;
            newThis.labels(idxs(bool))=[];
            newThis.Data(:,idxs(bool))=[];
        end

        function newThis=castAsOTS(this,orientation)
            if nargin<2 || isempty(orientation)
                orientation=orientationInfo;
            end
            newThis=orientedLabTimeSeries(this.Data,this.Time(1),this.sampPeriod,this.labels,orientation);
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

        function [steppedDataArray,bad,initTime,eventTimes]=splitByEvents(this,eventTS,eventLabel,timeMargin)
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

           %TODO: this needs to call on getArrayedEvents() to avoid
           %duplicating the event-finding logic
           
            refIdxLst=find(auxList==1);
            M=length(refIdxLst)-1;
            auxTime=eventTS.Time;
            aa=auxTime(refIdxLst);
            initTime=aa(1:M); %Initial time of each interval identified
            eventTimes=nan(M,N); %Duration of each interval
            eventTimes(:,1)=initTime;
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
                       eventTimes(i,j+1)=t1;
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
          slicedTS=cell(1,length(timeBreakpoints)-1);
          for i=1:length(timeBreakpoints)-1
              if isnan(timeBreakpoints(i)) || isnan(timeBreakpoints(i+1)) || timeBreakpoints(i+1)<timeBreakpoints(i)
                  warning('off') %Preventing overload of annoying warnings
              end
              slicedTS{i}=this.split(timeBreakpoints(i)-timeMargin,timeBreakpoints(i+1)+timeMargin);
              warning('on')
          end
            initTime=timeBreakpoints(1:end-1)-timeMargin;
            duration=diff(timeBreakpoints)+2*timeMargin;
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
        
        function this=rectify(this)
            this.Data=abs(this.Data);
            this.labels=strcat(strcat(this.labels),'abs');
        end

        function newThis=plus(this,other)
            M=size(this.Data,2);
            if size(other.Data,2)~=M
                error('Inconsistent sizes for sum')
            end
            newLabels=cell(size(this.labels));
            for i=1:M
                newLabels{i}=['(' this.labels{i} ' + ' other.labels{i} ')'];
            end
            if abs(this.Time(1)-other.Time(1))<eps && abs(this.sampPeriod-other.sampPeriod)<eps && length(this.labels)==length(other.labels)
                newThis=labTimeSeries(this.Data+other.Data,this.Time(1),this.sampPeriod,newLabels);
            else
                error('')
            end
        end

        function newThis=minus(this,other)
            %Subtracts two labTSs
            %Could be deprecated in favor of: newThis=this + -1*other;
            M=size(this.Data,2);
            for i=1:M
                newLabels{i}=['(' this.labels{i} ' - ' other.labels{i} ')'];
            end
            if abs(this.Time(1)-other.Time(1))<eps && abs(this.sampPeriod-other.sampPeriod)<eps && length(this.labels)==length(other.labels)
                newThis=labTimeSeries(this.Data-other.Data,this.Time(1),this.sampPeriod,newLabels);
            end
        end

        function newThis=derivate(this)
            %This is kept for legacy compatibility purposes only
            partialThis=this.derivative;
            pad=nan(1,size(this.Data,2));
            newThis=labTimeSeries([pad;partialThis.Data;pad],this.Time(1),this.sampPeriod,partialThis.labels);
        end
        
        function [newThis,lag]=derivative(this,diffOrder)
            %Numerical differentiation of labTS
            %diffOrder establishes the order of the filter used for
            %estimation, NOT higher order derivatives [we are approximating
            %an IIR filter -the true derivative- through a FIR].
            %Ref: https://en.wikipedia.org/wiki/Finite_difference_coefficient
            if nargin<2 || isempty(diffOrder)
                diffOrder=2; %Default
            end
            lag=diffOrder/2;
            switch diffOrder
               case 1
                   w= [1 -1];
               case 2
                   w=.5*[1 0 -1];
               case 4
                   w=[-1 8 0 -8 1]/12;
               case 6
                   w=[1 -9 45 0 -45 9 -1]/60;
               case 8
                   w=[-1/56 4/21 -1 4 0 -4 1 -4/21 1/56]/5;
               otherwise
                   error('Order not supported')
            end

            M=size(this.Data,2);
            newData=conv2(this.Data,w','valid')/this.sampPeriod;
            %newData=[nan(order,M);.5*(this.Data(3:end,:)-this.Data(1:end-2,:));nan(order,M)]/this.sampPeriod; %Centered differential
            if mod(diffOrder,2)==0 %For even order differences, we can preserve the sampling of the time series, padding with NaN on the edges
                newT0=this.Time(1);
                newData=cat(1,nan(lag,size(newData,2)),newData,nan(lag,size(newData,2)));
            else
                newT0=this.Time(1)+lag*this.sampPeriod;
            end
            newLabels=strcat('d/dt',{' '},this.labels);
            newThis=labTimeSeries(newData,newT0,this.sampPeriod,newLabels);
        end
        
        function newThis=integrate(this,initValues)
            %This is the inverse operator of derivative when used with
            %diffOrder=1;
            M=size(this.Data,2);
            if nargin<2 || isempty(initValues)
               initValues=zeros(1,M);  %Default initial condition = 0
               %Initial values represent the integrated data values HALF A
               %SAMPLE before the first sample of this.
               %
            end
            if numel(initValues)~=M
                error('Initial values mismatch between Data and initValues')
            end
            newData=bsxfun(@plus,initValues(:)',cumsum([zeros(1,M); this.Data],1) * this.sampPeriod); 
            lag=-.5;
            newLabels=strcat('\int',{' '},this.labels,{' '},'dt');
            newT0=this.Time(1)+lag*this.sampPeriod;
            newThis=labTimeSeries(newData,newT0,this.sampPeriod,newLabels);
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
                newThis=labTimeSeries([this.Data,other.Data],this.Time(1),this.sampPeriod,[this.labels(:)', other.labels(:)']);
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
            badColumns=sum(~isnan(this.Data))<2;
            if any(badColumns) %Returns true if any TS contained in the data is all NaN
                %FIXME: This throws an exception now, but it should just
                %return all NaN labels as all NaN and substitute missing
                %values in the others.
                warning('labTimeSeries:substituteNaNs','timeseries contains at least one label that is all (or all but one sample) NaN. Can''t replace those values (no data to use as reference), setting to 0.')
                this.Data(:,badColumns)=0;
            end
            %this.Quality=zeros(size(this.Data),'int8');
            aux=isnan(this.Data);
             for i=1:size(this.Data,2) %Going through labels
                 auxIdx=aux(:,i);
                 this.Data(auxIdx,i)=interp1(this.Time(~auxIdx),this.Data(~auxIdx,i),this.Time(auxIdx),method,0); %Extrapolation values are filled with 0,
             end
             %Saving quality data (to mark which samples were interpolated):
             this.Quality=int8(aux); %Matlab's timeseries stores this as int8. I would have preferred a sparse array.
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
                if ~isempty(this.Quality)
                    relQual=this.Quality==1;
                else
                    relQual=true(size(relData));
                end
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
                %plot(this.Time(relQual(:,i)),relData(relQual(:,i),i),'rx')
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
        
        function [fh,ph,missing]=assessMissing(this,labels,fh,ph)
            noDisp=false;
            if nargin<3 || isempty(fh)
                fh=figure();
            elseif fh==-1
                noDisp=true;
            else
                figure(fh)
                if nargin<4
                    ph=gca;
                else
                    axes(ph)
            end
            end
            
            if nargin<2
                labels=this.labels;
            end
            data=this.getDataAsVector(labels);
            missing=isnan(data);
            miss=missing(:,any(missing));
            
            if ~noDisp
            pp=plot(miss,'o');
            aux=labels(any(missing));
            for i=1:length(pp)
                set(pp(i),'DisplayName',[aux{i} ' (' num2str(sum(miss(:,i))) ' frames)'])
            end
            legend(pp)
            title('Missing markers')
            xlabel('Time (frames)')
            set(gca,'YTick',[0 1],'YTickLabel',{'Present','Missing'})
            else
                fprintf(['Missing data in ' num2str(sum(any(missing,2))) '/' num2str(size(missing,1)) ' frames, avg. ' num2str(sum(missing(:))/sum(any(missing,2)),3) ' per frame.\n']);
          end
        end
        
        function [newThis,logL]=findOutliers(this,model,verbose)
            %Uses marker model data to assess outliers
                
                d=this.getDataAsVector(model.markerLabels)';
                l=this.labels;
                [out,logL]=model.outlierDetect(d,-4);
                [boolF,idx]=this.isaLabel(model.markerLabels);
                aux(:,idx(boolF))=(out==1)';
                this.Quality=aux;
            
            if verbose
                fprintf(['Outlier data in ' num2str(sum(any(out,1))) '/' num2str(size(out,2)) ' frames, avg. ' num2str(sum(out(:))/sum(any(out,1))) ' per frame.\n']);
                for j=1:size(out,1)
                    if sum(out(j,:)==1)>0
                    disp([l{j} ': ' num2str(sum(out(j,:)==1)) ' frames'])
                    end
                end
            end
%             s=naiveDistances.summaryStats(d);
%             s=s(model.activeStats,:)';
%             m=model.statMedian;
%             m=m(model.activeStats);
%             ss=model.getRobustStd(.94);
%             ss=3*ss(model.activeStats); %3 standard devs
%             aux=model.loglikelihood(d)<-4^2/2;
%             figure; pp=plot(s); axis tight; hold on;
%             for j=1:size(s,2)
%                 patch([1 size(s,1) size(s,1) 1],[m(j)-ss(j) m(j)-ss(j) m(j)+ss(j) m(j)+ss(j)],pp(j).Color,'FaceAlpha',.3,'EdgeColor','None')
%                 plot(find(aux(j,:)),s(aux(j,:),j),'x','Color',pp(j).Color,'MarkerSize',4);
%             end
            newThis=this;
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

        function [ATS,bad]=align(this,eventTS,eventLabel,N,~)
            if nargin<3 || isempty(eventLabel)
                eventLabel=eventTS.labels(1);
            end    
            if nargin<4 || isempty(N)
                N=256*ones(size(eventLabel));
            end
            [ATS,bad]=this.align_v2(eventTS.split(this.Time(1)-this.sampPeriod,this.Time(end)+this.sampPeriod),eventLabel,N);
        end
        
        function [DTS,bad]=discretize(this,eventTS,eventLabel,N,summaryFunction)
            %Discretizes a time-series by averaging data across different
            %phases of gait. The phases are defined by intervals between
            %given events, and in turn these can be divided into sub-phases
            if nargin<3 || isempty(eventLabel)
                eventLabel=eventTS.labels(1);
            end
            %NEw attempt, no alignment:
            eventTimes=labTimeSeries.getArrayedEvents(eventTS,eventLabel);
            bad=any(isnan(eventTimes(1:end-1,:)),2);
            expEventTimes=alignedTimeSeries.expandEventTimes(eventTimes',N);
            ee=[expEventTimes(:); eventTimes(end,1)];
            [slicedTS]=this.sliceTS(ee,0);
            if nargin<5 || isempty(summaryFunction)
                summaryFunction='nanmean';%nanmean, only along the columns, so that if we have NAN data, and to account for the odd instance when we only have one row or data in our slicedTS
            end
            eval(['myfun=@(x) ' summaryFunction '(x,1);']);
            d=cell2mat(cellfun(@(x) myfun(x.Data),slicedTS,'UniformOutput',false)'); 
            [M,N1]=size(expEventTimes);        M2=size(d,2);
            d=permute(reshape(d,sum(N),N1,M2),[1,3,2]);
            DTS=alignedTimeSeries(0,1,d,this.labels,N,eventLabel,eventTimes');
        end

        function newThis=lowPassFilter(this,fcut)
                Wn=fcut*2/this.sampFreq;
                Wst=min([2*Wn,Wn+.2*(1-Wn)]);
               filterList{1}=fdesign.lowpass('Fp,Fst,Ap,Ast',Wn,Wst,3,10); %
                lowPassFilter=design(filterList{1},'butter');
                newData=filtfilthd_short(lowPassFilter,this.Data,'reflect',this.sampFreq);  %Ext function
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
                newData=filtfilthd_short(highPassFilter,this.Data,'reflect',this.sampFreq);
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
            %newN=floor((this.Time(end)-newT0)/newTs +1);
            %Can this be deprecated in favor of resample with 'logical'
            %method?
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
        
        function [ATS,bad,Data]=align_v2(this,eventTS,eventLabel,N)
            %Efficient & robust substitute for legacy align()
            eventTimes=labTimeSeries.getArrayedEvents(eventTS,eventLabel);
            expEventTimes=alignedTimeSeries.expandEventTimes(eventTimes',N);
            Data=permute(this.getSample(expEventTimes),[1,3,2]);
            bad=any(isnan(eventTimes(1:end-1,:)),2);
            ATS=alignedTimeSeries(0,1,Data,this.labels,N,eventLabel,eventTimes');
        end
    end

    methods(Static)
        this=createLabTSFromTimeVector(data,time,labels); %Need to compute appropriate t0 and Ts constants and call the constructor. Tricky if time is not uniformly sampled.
        
        function eventTimes=getArrayedEvents(eventTS,eventLabel)
           if nargin>1
                eventList=eventTS.getDataAsVector(eventLabel);
           else
               eventList=eventTS.Data(:,1);
           end
           %Check needed: is eventList binary?
           N=size(eventList,2); %Number of events & intervals to be found
           %auxList=double(eventList)*2.^[0:N-1]'; %List all events in a single vector, by numbering them differently.

            %refIdxLst=find(auxList==1);
            refIdxLst=find(eventList(:,1)); %Alt definition, to match what is returned if a single event was provided
            M=length(refIdxLst)-1;
            auxTime=eventTS.Time;
            initTime=auxTime(refIdxLst); %Initial time of each interval identified
            eventTimes=nan(M+1,N); %Duration of each interval
            eventTimes(:,1)=initTime;
            for i=1:M %Going over strides
                t0=auxTime(refIdxLst(i));
                lastEventIdx=refIdxLst(i);
                for j=1:N-1 %Going over events
                   %nextEventIdx=lastEventIdx+find(auxList(lastEventIdx+1:refIdxLst(i+1)-1)==2^mod(j,N),1,'first');
                   nextEventIdx=lastEventIdx+find(eventList(lastEventIdx+1:refIdxLst(i+1)-1,j+1),1,'first');
                   t1= auxTime(nextEventIdx); %Look for next event
                   if ~isempty(t1) && ~isempty(t0)
                       eventTimes(i,j+1)=t1;
                        lastEventIdx=nextEventIdx;
                   end

                end
            end
        end

        function [alignedTS,originalDurations]=stridedTSToAlignedTS(stridedTS,N) 
            error('Deprecated. Use labTS.align()')
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
                            if ~isempty(stridedTS{i,j}.Data) && sum(~isnan(stridedTS{i,j}.Data(:,1)))>1
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
                alignmentLabels=cell(size(N)); %Need to populate this field properly
                alignedTS=alignedTimeSeries(0,1,aux,stridedTS{1}.labels,N,alignmentLabels); %On May 2nd 2017, Pablo changed to have sampling time =1 [time vector now counts samples]
            else
                alignmentLabels=cell(size(N));
                alignedTS=alignedTimeSeries(0,1,zeros(0,0),[],N,alignmentLabels);
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
