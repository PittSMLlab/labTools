classdef labTimeSeries  < timeseries
    %labTimeSeries  Extends timeseries (built-in MATLAB class) to meet
    %our lab's needs for storing data
    %
    %   labTimeSeries forces timeseries to be uniformly sampled and adds
    %   label-based data access, resampling, filtering, and alignment
    %   capabilities.
    %
    %labTimeSeries properties:
    %   labels - cell array of strings with labels for columns of Data
    %   sampPeriod - time between samples, equal to 1/sampFreq
    %   sampFreq - sampling rate in Hz, equal to 1/sampPeriod (dependent)
    %   timeRange - total time duration (dependent)
    %   Nsamples - total number of samples in timeSeries (dependent)
    %   Data - matrix of data values, size Nsamples x length(labels)
    %   Time - time values corresponding to each sample
    %   Length - should be same as Nsamples
    %
    %labTimeSeries methods:
    %   getDataAsVector - gets data vector for given label(s)
    %   getDataAsTS - returns new labTimeSeries with given label(s)
    %   getLabels - returns list of labels
    %   getLabelsThatMatch - returns labels matching regular expression
    %   isaLabel - checks if string is contained in label array
    %   getSample - samples timeseries at arbitrary timepoints
    %   synchTo - resamples to match another timeseries
    %   getIndexClosestToTimePoint - finds index nearest to time point
    %   resample - resamples to different sampling period
    %   resampleN - resamples to N samples over same time range
    %   split - returns timeseries between two timepoints
    %   appendData - adds more data as new labels
    %   addNewParameter - adds computed parameter from existing data
    %   computeNewParameter - computes new parameter without adding
    %   removeParameter - removes parameter from timeseries
    %   castAsOTS - converts to orientedLabTimeSeries
    %   castAsSTS - converts to spectroTimeSeries
    %   getPartialDataAsVector - returns data for labels and time range
    %   splitByEvents - separates by events in boolean timeseries
    %   sliceTS - slices at given time breakpoints
    %   times - multiplies data by constant
    %   rectify - takes absolute value of data
    %   plus - adds two labTimeSeries
    %   minus - subtracts two labTimeSeries
    %   derivate - differentiates (legacy)
    %   derivative - numerical differentiation
    %   integrate - numerical integration
    %   equalizeEnergyPerChannel - normalizes by RMS
    %   equalizeVarPerChannel - normalizes by standard deviation
    %   demean - removes mean from each channel
    %   fillts - substitutes NaN values (deprecated)
    %   concatenate - merges two timeseries
    %   cat - alias for concatenate
    %   substituteNaNs - replaces NaN by interpolation
    %   thresholdByChannel - zeros data based on threshold
    %   lowPassFilter - applies low-pass filter
    %   highPassFilter - applies high-pass filter
    %   monotonicFilter - applies monotonic least squares
    %   medianFilter - applies median filter
    %   fourierTransform - computes Fourier transform
    %   spectrogram - computes spectrogram
    %   align - aligns data to gait events
    %   discretize - discretizes by averaging across phases
    %   plot - plots data in subplots
    %   plotAligned - plots aligned data (unimplemented)
    %   bilateralPlot - plots bilateral comparison
    %   dispCov - displays covariance matrix
    %   assessMissing - assesses and plots missing data
    %   findOutliers - detects outliers using model
    %
    %See also: timeseries, orientedLabTimeSeries, alignedTimeSeries

    %% Properties
    properties (SetAccess = private)
        labels = {''};
        sampPeriod;
    end

    properties (Dependent)
        sampFreq
        timeRange
        Nsamples
    end

    %% Constructor
    methods
        function this = labTimeSeries(data, t0, Ts, labels)
            %labTimeSeries  Constructor for labTimeSeries class
            %
            %   this = labTimeSeries(data, t0, Ts, labels) creates a
            %   uniformly sampled timeseries with specified data, initial
            %   time, sampling period, and labels
            %
            %   Inputs:
            %       data - matrix of data values (samples x channels)
            %       t0 - initial time in seconds
            %       Ts - sampling period in seconds
            %       labels - cell array of label strings for each channel
            %
            %   Outputs:
            %       this - labTimeSeries object
            %
            %   Note: Necessarily uniformly sampled
            %
            %   See also: timeseries

            if nargin == 0
                data = [];
                time = [];
                labels = {};
                Ts = [];
            else
                time = [0:size(data, 1) - 1] * Ts + t0';
            end
            this = this@timeseries(data, time);
            this.sampPeriod = Ts;
            if (length(labels) == size(data, 2)) && isa(labels, 'cell')
                this.labels = labels;
            else
                ME = MException(...
                    'labTimeSeries:ConstructorInconsistentArguments', ...
                    ['The size of the labels array is inconsistent ' ...
                    'with the data being provided.']);
                throw(ME);
            end
            % Check for repeat labels:
            [~, i1, i2] = unique(lower(labels));
            if length(i1) < length(labels)
                repIdx = ...
                    find((sort(i1) - [1:length(i1)]') ~= 0, 1, 'first');
                if isempty(repIdx)
                    repIdx = length(i1) + 1;
                end
                ME = MException(...
                    'labTimeSeries:ConstructorRepeatedLabels', ...
                    ['Found ' num2str(length(labels) - length(i1)) ...
                    ' collisions of label names. First collision is: ' ...
                    labels{repIdx}]);
                throw(ME);
            end
        end
    end

    %% Dependent Property Getters
    methods
        function fs = get.sampFreq(this)
            %get.sampFreq  Returns sampling frequency
            %
            %   Outputs:
            %       fs - sampling frequency in Hz

            fs = 1 / this.sampPeriod;
        end

        function tr = get.timeRange(this)
            %get.timeRange  Returns total time duration
            %
            %   Outputs:
            %       tr - time range in seconds

            tr = (this.Nsamples) * this.sampPeriod;
        end

        function Nsamp = get.Nsamples(this)
            %get.Nsamples  Returns number of samples
            %
            %   Outputs:
            %       Nsamp - total number of samples

            Nsamp = this.TimeInfo.Length;
        end
    end

    %% Data Access Methods
    methods
        [data, time, auxLabel] = getDataAsVector(this, label)

        [newTS, auxLabel] = getDataAsTS(this, label)

        function labelList = getLabels(this)
            %getLabels  Returns list of labels
            %
            %   labelList = getLabels(this) returns all data labels
            %
            %   Inputs:
            %       this - labTimeSeries object
            %
            %   Outputs:
            %       labelList - cell array of label strings
            %
            %   See also: getLabelsThatMatch, isaLabel

            labelList = this.labels;
        end

        [data, time, auxLabel] = ...
            getPartialDataAsVector(this, label, t0, t1)
    end

    %% Label Query Methods
    methods
        this = renameLabels(this, originalLabels, newLabels)

        labelList = getLabelsThatMatch(this, exp)

        [boolFlag, labelIdx] = isaLabel(this, label)
    end

    %% Sampling and Synchronization Methods
    methods
        data = getSample(this, timePoints, method)

        newTS = synchTo(this, otherTS)

        index = getIndexClosestToTimePoint(this, timePoints)
    end

    %% Resampling Methods
    methods
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
    end

    %% Data Segmentation Methods
    methods
        newThis = split(this, t0, t1)

        [steppedDataArray, bad, initTime, eventTimes] = splitByEvents( ...
            this, eventTS, eventLabel, timeMargin)

        [slicedTS, initTime, duration] = sliceTS( ...
            this, timeBreakpoints, timeMargin)
    end

    %% Data Modification Methods
    methods
        newThis = appendData(this, newData, newLabels)

        [newThis, newData] = addNewParameter( ...
            this, newParamLabel, funHandle, inputParameterLabels)

        newData = computeNewParameter( ...
            this, newParamLabel, funHandle, inputParameterLabels)

        newThis = removeParameter(labels)
    end

    %% Type Conversion Methods
    methods
        newThis = castAsOTS(this, orientation)

        Sthis = castAsSTS(this, nFFT, tWin, tOverlap)
    end

    %% Arithmetic Operations
    methods
        this = times(this, constant)

        this = rectify(this)

        newThis = plus(this, other)

        newThis = minus(this, other)
    end

    %% Differentiation and Integration
    methods
        newThis = derivate(this)

        [newThis, lag] = derivative(this, diffOrder)

        newThis = integrate(this, initValues)
    end

    %% Normalization Methods
    methods
        newthis = equalizeEnergyPerChannel(this)

        newthis = equalizeVarPerChannel(this)

        newthis = demean(this)
    end

    %% Data Cleaning Methods
    methods
        this = fillts(this)

        this = substituteNaNs(this, method)

        newThis = thresholdByChannel(this, th, label, moreThanFlag)
    end

    %% Concatenation Methods
    methods
        newThis = concatenate(this, other)

        function newThis = cat(this, other)
            %cat  Alias for concatenate
            %
            %   newThis = cat(this, other) concatenates two labTimeSeries
            %
            %   Inputs:
            %       this - labTimeSeries object
            %       other - labTimeSeries object to concatenate
            %
            %   Outputs:
            %       newThis - concatenated labTimeSeries
            %
            %   See also: concatenate

            newThis = concatenate(this, other);
        end
    end

    %% Filtering Methods
    methods
        newThis = lowPassFilter(this, fcut)

        newThis = highPassFilter(this, fcut)

        newThis = monotonicFilter(this, Nderiv, Nreg)

        this = medianFilter(this, N)
    end

    %% Spectral Analysis Methods
    methods
        Fthis = fourierTransform(this, M)

        Sthis = spectrogram(this, labels, nFFT, tWin, tOverlap)
    end

    %% Alignment Methods
    methods
        [ATS, bad] = align(this, eventTS, eventLabel, N, ~)

        [DTS, bad] = ...
            discretize(this, eventTS, eventLabel, N, summaryFunction)
    end

    %% Visualization Methods
    methods
        % [h, plotHandles] = plot( ...
        %     this, h, labels, plotHandles, events, color, lineWidth)
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

        % [h, plotHandles] = plotAligned( ...
        %     this, h, labels, plotHandles, events, color, lineWidth)
        function [h,plotHandles]=plotAligned(this,h,labels,plotHandles,events,color,lineWidth)
            error('Unimplemented')
            %First attempt: align the data to the first column of events
            %provided
            for i=1:length(ee)
                this.split(t1,t2).plot
            end
        end

        % [h, plotHandles] = bilateralPlot( ...
        %     this, h, labels, plotHandles, events, color, lineWidth)
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

        h = dispCov(this)

        [fh, ph, missing] = assessMissing(this, labels, fh, ph)

        [newThis, logL] = findOutliers(this, model, verbose)
    end

    %% Hidden Methods
    methods (Hidden)
        newThis = resampleLogical(this, newTs, newT0, newN)

        [ATS, bad, Data] = align_v2(this, eventTS, eventLabel, N)
    end

    %% Static Methods
    methods (Static)
        this = createLabTSFromTimeVector(data, time, labels)

        eventTimes = getArrayedEvents(eventTS, eventLabel)

        [alignedTS, originalDurations] = ...
            stridedTSToAlignedTS(stridedTS, N)

        [figHandle, plotHandles] = ...
            plotStridedTimeSeries(stridedTS, figHandle, plotHandles)

        this = join(labTSCellArray)
    end

end

