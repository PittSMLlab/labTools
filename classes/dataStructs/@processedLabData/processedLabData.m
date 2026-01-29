classdef processedLabData < labData
    %processedLabData Extends labData to include proccessed data derived
    %from the raw data.
    %
    %processedLabData properties:
    %   gaitEvents - labTS object with HS and TO events
    %   procEMGdata - processedEMGTS object
    %   angleData - labTS object with angles calculated from marker data
    %   adaptParams - parameterSeries adaptation values on a strid-by-stide basis
    %   isSingleStride - boolean flag to check length of data
    %   experimentalParams - parameterSeries for testing new adaptation
    %                           parameters
    %
    %processedLabData methods:
    %
    %   getProcEMGData - accessor for processed EMGs
    %   getProcEMGList - returns list of processed EMG labels
    %   getPartialGaitEvents - accessor for specific events
    %   getEventList - returns list of event labels
    %   getAngleData - accessor for angle data
    %   getParam - accessor for adaptation parameters
    %   getExpParam - accessor for experimental adaptation parameters
    %   calcAdaptParams - re-computes adaptation parameters
    %
    %   separateIntoStrides - splits data into individual stride segments
    %   separateIntoSuperStrides - splits data into 1.5-stride segments for
    %                               parameter calculation
    %   separateIntoDoubleStrides - splits data into 2-stride segments for
    %                               parameter calculation
    %   getStrideInfo - returns stride count and timing information
    %   getStridedField - extracts field data organized by stride
    %   getAlignedField - time-aligns field data to gait events
    %
    %See also: labData, labTimeSeries, processedEMGTimeSeries,
    %   parameterSeries

    %% Properties
    properties  % (SetAccess = private)
        % can not set to private, because 'labData' will try to set it
        % when using the 'split()' method
        gaitEvents      % labTS
        procEMGData     % processedEMGTS
        angleData       % labTS (angles based off kinematics)
        adaptParams     % parameterSeries
        % parameters which characterize adaptation process) --> must be
        % calculated, therefore not a part of the constructor.
        % EMGData
        % which is inherited from 'labData', saved the FILTERED EMG data
        % used for processing afterwards (not the RAW, which is saved in
        % the not-processed 'labData')
        COPData
        COMData
        jointMomentsData
    end

    properties (Dependent)
        isSingleStride      % ever used?
        experimentalParams
    end

    %% Constructor
    methods

        function this=processedLabData(metaData,markerData, ...
                EMGData,GRFData,beltSpeedSetData,beltSpeedReadData, ...
                accData,EEGData,footSwitches,events,procEMG, ...
                angleData,COPData,COMData,jointMomentsData, ...
                HreflexPin) % all input parameters are mandatory
            if nargin < 16  % 'metaData' does not get replaced!
                markerData=[];
                EMGData=[];
                GRFData=[];
                beltSpeedSetData=[];
                beltSpeedReadData=[];
                accData=[];
                EEGData=[];
                footSwitches=[];
                events=[];
                procEMG=[];
                angleData = [];
                COPData=[];
                COMData=[];
                jointMomentsData=[];
                HreflexPin=[];
            end
            this@labData(metaData,markerData,EMGData,GRFData, ...
                beltSpeedSetData,beltSpeedReadData,accData,EEGData, ...
                footSwitches,HreflexPin);
            this.gaitEvents=events;
            this.procEMGData=procEMG;
            this.angleData=angleData;
            this.COPData=COPData;
            this.COMData=COMData;
            this.jointMomentsData=jointMomentsData;
        end
    end

    %% Property Setters
    methods

        function this=set.gaitEvents(this,events)
            if isa(events,'labTimeSeries') || isempty(events)
                this.gaitEvents=events;
            else
                ME=MException('processedLabData:Constructor',...
                    'events parameter is not a labTimeSeries object.');
                throw(ME);
            end
        end

        function this=set.procEMGData(this,procEMG)
            if isa(procEMG,'processedEMGTimeSeries') || ...
                    isempty(procEMG)
                this.procEMGData=procEMG;
            else
                ME=MException('processedLabData:Constructor',...
                    'procEMG parameter is not a processedEMGTimeSeries object.');
                throw(ME);
            end
        end

        function this=set.angleData(this,angleData)
            if isa(angleData,'labTimeSeries') || isempty(angleData)
                this.angleData=angleData;
            else
                ME=MException('processedLabData:Constructor',...
                    'angleData parameter is not a labTimeSeries object.');
                throw(ME);
            end
        end

        function this=set.adaptParams(this,adaptData)
            if isa(adaptData,'parameterSeries') || ...
                    isa(adaptData,'labTimeSeries')
                this.adaptParams=adaptData;
            else
                ME=MException('processedLabData:Constructor',...
                    'adaptParams parameter is not a parameterSeries object.');
                throw(ME);
            end
        end

    end

    %% Data Access Methods
    methods

        %Access method for fields not defined in raw class.
        %         function partialProcEMGData=getProcEMGData(this,muscleName)
        %             partialProcEMGData=this.getPartialData('procEMGData',muscleName);
        %         end

        %         function list=getProcEMGList(this)
        %             list=this.getLabelList('procEMGData');
        %         end

        function partialGaitEvents=getPartialGaitEvents(this,...
                eventName)
            partialGaitEvents=this.getPartialData('gaitEvents',...
                eventName);
        end

        %         function list=getEventList(this)
        %             list=this.getLabelList('gaitEvents');
        %         end

        %         function partialAngleData= getAngleData(this,angleName)
        %             partialAngleData=this.getPartialData('angleData',angleName);
        %         end

        %         function partialParamData=getParam(this,paramName)
        %             partialParamData=this.getPartialData('adaptParams',paramName);
        %         end

        %         function partialParamData=getExpParam(this,paramName)
        %             partialParamData=this.getPartialData('experimentalParams',paramName);
        %         end

        adaptParams=calcAdaptParams(this)

        function [alignedField,bad]=getAlignedField(this,field,events,alignmentLengths)
            [alignedField,bad]=this.(field).align(this.gaitEvents,events,alignmentLengths);
        end

    end

    %% Data Transformation Methods
    methods

        reducedThis=reduce(this,eventLabels,N)

        newThis=recomputeEvents(this)

    end

    %% Dependent Property Getters
    methods

        function expParams=get.experimentalParams(this)
            expParams=calcExperimentalParams(this);
        end

        function b=get.isSingleStride(this)
            b=isa(this,'strideData');
        end

    end

    %% Event Processing Methods
    methods

        [arrayedEvents]=getArrayedEvents(this,eventList)

        [numStrides,initTime,endTime]=getStrideInfo(this,triggerEvent, ...
            endEvent)

        [numSteps,initTime,endTime,initEventSide]=getStepInfo(this, ...
            triggerEvent)

    end

    %% Stride Segmentation Methods
    methods

        [steppedDataArray,initTime,endTime]=separateIntoStrides(...
            this,triggerEvent)

        [steppedDataArray,initTime,endTime]=...
            separateIntoSuperStrides(this,triggerEvent)

        [steppedDataArray,initTime,endTime]=...
            separateIntoDoubleStrides(this,triggerEvent)

        function [stridedField,bad,initTime,events]=getStridedField(this,field,events)
            warning('This is very slow and has been deprecated. Please don''t use')
            if isa(events,'char')
                events={events};
            end
            %Step 1: separate strides by the first event
            [numStrides,initTime,endTime]=getStrideInfo(this,events{1});
            M=numStrides;
            N=length(events);
            %Step 2: for each stride, find the other events (if any)
            intermediateTimes=nan(M,N-1);
            bad=false(M,1);
            for i=1:M
                for j=1:N-1
                    aux=find(this.gaitEvents.getDataAsVector(events{j+1}) & this.gaitEvents.Time>=initTime(i) & this.gaitEvents.Time<endTime(i));
                    if length(aux)==1 %Found only one event, as expected
                        intermediateTimes(i,j) = this.gaitEvents.Time(aux);
                    else
                        bad(i)=true;
                    end
                end
            end
            %Step 3: slice timeseries
            timeBreakpoints=[initTime, intermediateTimes]';
            [slicedTS,~,~]=sliceTS(this.(field),[timeBreakpoints(:); endTime(end)],0);

            %Step 4: reshape & set to [] the slices which didn't have
            %proper events
            stridedField=reshape(slicedTS,N,M)';
        end

    end

end

