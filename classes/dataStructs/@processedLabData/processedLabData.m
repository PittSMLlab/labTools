classdef processedLabData < labData
    %PROCESSEDLABDATA Extend labData with data processed from raw data.
    %
    % processedLabData properties:
    %   gaitEvents - labTS object with HS and TO events
    %   procEMGdata - processedEMGTS object
    %   angleData - labTS object with angles calculated from marker data
    %   adaptParams - parameterSeries adaptation values on a
    %                 stride-by-stride basis
    %   isSingleStride - boolean flag to check length of data
    %   experimentalParams - parameterSeries for testing new
    %                        adaptation parameters
    %
    % processedLabData methods:
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
    %   separateIntoSuperStrides - splits data into 1.5-stride
    %                              segments for parameter calculation
    %   separateIntoDoubleStrides - splits data into 2-stride
    %                               segments for parameter calculation
    %   getStrideInfo - returns stride count and timing information
    %   getStridedField - extracts field data organized by stride
    %   getAlignedField - time-aligns field data to gait events
    %
    % Toolbox Dependencies: None
    %
    % See also LABDATA, LABTIMESERIES, PROCESSEDEMGTIMESERIES,
    %   PARAMETERSERIES.

    %% Properties
    properties % (SetAccess = private)  Cannot set to private,
        % because labData will try to set it when using split()
        gaitEvents % labTS
        procEMGData % processedEMGTS
        angleData % labTS (angles based off kinematics)
        adaptParams % paramterSeries (parameters which characterize
        % adaptation process) --> must be calculated,
        % therefore not part of constructor.
        % EMGData, which is inherited from labData, saves the
        % FILTERED EMG data used for processing afterwards (not the
        % RAW, which is saved in the not-procesed labData)
        COPData
        COMData
        jointMomentsData
    end

    properties (Dependent)
        isSingleStride % ever used?
        experimentalParams
    end

    %% Constructor
    methods
        function this = processedLabData(metaData, markerData, EMGData, ...
            GRFData, beltSpeedSetData, beltSpeedReadData, accData, ...
            EEGData, footSwitches, events, procEMG, angleData, ...
            COPData, COMData, jointMomentsData, HreflexPin)
            %PROCESSEDLABDATA Constructor for processedLabData class
            %
            %   All arguments are mandatory
            %
            % Toolbox Dependencies: None

            if nargin < 16 % metaData does not get replaced!
                markerData = [];
                EMGData = [];
                GRFData = [];
                beltSpeedSetData = [];
                beltSpeedReadData = [];
                accData = [];
                EEGData = [];
                footSwitches = [];
                events = [];
                procEMG = [];
                angleData = [];
                COPData = [];
                COMData = [];
                jointMomentsData = [];
                HreflexPin = [];
            end
            this@labData(metaData, markerData, EMGData, GRFData, ...
                beltSpeedSetData, beltSpeedReadData, accData, ...
                EEGData, footSwitches, HreflexPin);
            this.gaitEvents = events;
            this.procEMGData = procEMG;
            this.angleData = angleData;
            this.COPData = COPData;
            this.COMData = COMData;
            this.jointMomentsData = jointMomentsData;
        end
    end

        %% Property Setters
    methods
        function this = set.gaitEvents(this, events)
            %SET.GAITEVENTS Validate and set the gaitEvents property.
            %
            %   Accepts a labTimeSeries or an empty value; otherwise throws
            % a processedLabData:Constructor error.
            %
            % Inputs:
            %   this   - processedLabData object
            %   events - labTimeSeries with the gait events
            %
            % Outputs:
            %   this - processedLabData object with the new events
            %
            % Toolbox Dependencies: None

            if isa(events, 'labTimeSeries') || isempty(events)
                this.gaitEvents = events;
            else
                ME = MException('processedLabData:Constructor', ...
                    'events parameter is not a labTimeSeries object.');
                throw(ME);
            end
        end

        function this = set.procEMGData(this, procEMG)
            %SET.PROCEMGDATA Validate and set the procEMGData property.
            %
            %   Accepts a processedEMGTimeSeries or an empty value;
            % otherwise throws a processedLabData:Constructor error.
            %
            % Inputs:
            %   this    - processedLabData object
            %   procEMG - processedEMGTimeSeries object
            %
            % Outputs:
            %   this - processedLabData object with the new data
            %
            % Toolbox Dependencies: None

            if isa(procEMG, 'processedEMGTimeSeries') || ...
                    isempty(procEMG)
                this.procEMGData = procEMG;
            else
                ME = MException('processedLabData:Constructor', ...
                    ['procEMG parameter is not a ' ...
                    'processedEMGTimeSeries object.']);
                throw(ME);
            end
        end

        function this = set.angleData(this, angleData)
            %SET.ANGLEDATA Validate and set the angleData property.
            %
            %   Accepts a labTimeSeries or an empty value; otherwise throws
            % a processedLabData:Constructor error.
            %
            % Inputs:
            %   this      - processedLabData object
            %   angleData - labTimeSeries with the joint angles
            %
            % Outputs:
            %   this - processedLabData object with the new data
            %
            % Toolbox Dependencies: None

            if isa(angleData, 'labTimeSeries') || ...
                    isempty(angleData)
                this.angleData = angleData;
            else
                ME = MException('processedLabData:Constructor', ...
                    ['angleData parameter is not a labTimeSeries ' ...
                    'object.']);
                throw(ME);
            end
        end

        function this = set.adaptParams(this, adaptData)
            %SET.ADAPTPARAMS Validate and set the adaptParams property.
            %
            %   Accepts a parameterSeries or a labTimeSeries; otherwise
            % throws a processedLabData:Constructor error.
            %
            % Inputs:
            %   this      - processedLabData object
            %   adaptData - parameterSeries with the parameters
            %
            % Outputs:
            %   this - processedLabData object with the new parameters
            %
            % Toolbox Dependencies: None

            if isa(adaptData, 'parameterSeries') || ...
                    isa(adaptData, 'labTimeSeries')
                this.adaptParams = adaptData;
            else
                ME = MException('processedLabData:Constructor', ...
                    ['adaptParams parameter is not a ' ...
                    'parameterSeries object.']);
                throw(ME);
            end
        end
    end

        %% Data Access Methods
    methods
        % Access method for fields not defined in raw class.
        % function partialProcEMGData = getProcEMGData(this, muscleName)
        %     partialProcEMGData = ...
        %    this.getPartialData('procEMGData', muscleName);
        % end

        % function list = getProcEMGList(this)
        %     list = this.getLabelList('procEMGData');
        % end

        function partialGaitEvents = ...
            getPartialGaitEvents(this, eventName)
            %GETPARTIALGAITEVENTS Get a subset of the gait events.
            %
            % Inputs:
            %   this      - processedLabData object
            %   eventName - label(s) of the events to keep
            %
            % Outputs:
            %   partialGaitEvents - labTimeSeries with only those events
            %
            % Toolbox Dependencies: None
            %
            % See also LABDATA.GETPARTIALDATA.

            partialGaitEvents = ...
                this.getPartialData('gaitEvents', eventName);
        end

        % function list = getEventList(this)
        %     list = this.getLabelList('gaitEvents');
        % end

        % function partialAngleData = getAngleData(this, angleName)
        %     partialAngleData = this.getPartialData('angleData', ...
        %    angleName);
        % end

        % function partialParamData = getParam(this, paramName)
        %     partialParamData = this.getPartialData('adaptParams', ...
        %    paramName);
        % end

        % function partialParamData = getExpParam(this, paramName)
        %     partialParamData = ...
        %    this.getPartialData('experimentalParams', paramName);
        % end

        adaptParams = calcAdaptParams(this)

        function [alignedField, bad] = getAlignedField(this, field, ...
            events, alignmentLengths)
            %GETALIGNEDFIELD Align a field to the gait events.
            %
            %   Calls the ALIGN method of the requested time series with
            % this object's gait events.
            %
            % Inputs:
            %   this             - processedLabData object
            %   field            - name of the time series property to align
            %   events           - event labels that define the alignment
            %   alignmentLengths - number of samples per phase
            %
            % Outputs:
            %   alignedField - aligned time series
            %   bad          - strides that could not be aligned
            %
            % Toolbox Dependencies: None
            %
            % See also LABTIMESERIES.ALIGN.

            [alignedField, bad] = ...
                this.(field).align(this.gaitEvents, ...
                events, alignmentLengths);
        end
    end

        %% Data Transformation Methods
    methods
        reducedThis = reduce(this, eventLabels, N)

        newThis = recomputeEvents(this)
    end

        %% Dependent Property Getters
    methods
        function expParams = get.experimentalParams(this)
            %GET.EXPERIMENTALPARAMS Compute the experimental parameters.
            %
            %   Dependent property: calls CALCEXPERIMENTALPARAMS each time
            % it is read.
            %
            % Inputs:
            %   this - processedLabData object
            %
            % Outputs:
            %   expParams - parameterSeries for testing new adaptation
            %               parameters
            %
            % Toolbox Dependencies: None
            %
            % See also CALCEXPERIMENTALPARAMS.

            expParams = calcExperimentalParams(this);
        end

        function b = get.isSingleStride(this)
            %GET.ISSINGLESTRIDE Check whether this object is a strideData.
            %
            % Inputs:
            %   this - processedLabData object
            %
            % Outputs:
            %   b - true if the object is a strideData
            %
            % Toolbox Dependencies: None
            %
            % See also STRIDEDATA.

            b = isa(this, 'strideData');
        end
    end

        %% Event Processing Methods
    methods
        arrayedEvents = getArrayedEvents(this, eventList)

        [numStrides, initTime, endTime] = ...
            getStrideInfo(this, triggerEvent, endEvent)

        [numSteps, initTime, endTime, initEventSide] = ...
            getStepInfo(this, triggerEvent)
    end

        %% Stride Segmentation Methods
    methods
        [steppedDataArray, initTime, endTime] = ...
            separateIntoStrides(this, triggerEvent)

        [steppedDataArray, initTime, endTime] = ...
            separateIntoSuperStrides(this, triggerEvent)

        [steppedDataArray, initTime, endTime] = ...
            separateIntoDoubleStrides(this, triggerEvent)

        function [stridedField, bad, initTime, events] = ...
            getStridedField(this, field, events)
            %GETSTRIDEDFIELD Slice a field by strides (very slow).
            %
            %   Deprecated: warns on every call because it is very slow.
            % Splits the field at the first event and then at every other
            % event found inside each stride; strides where an expected
            % event is not found exactly once are marked bad.
            %
            % Inputs:
            %   this   - processedLabData object
            %   field  - name of the time series property to slice
            %   events - event label(s) (char or cell array); the first one
            %            defines the strides
            %
            % Outputs:
            %   stridedField - strides x events cell array of sliced time
            %                  series
            %   bad          - logical column, true for strides with a
            %                  missing or repeated event
            %   initTime     - start time of every stride
            %   events       - event labels used
            %
            % Toolbox Dependencies: None
            %
            % See also GETSTRIDEINFO, SEPARATEINTOSTRIDES.

            warning(['This is very slow and has been deprecated. ' ...
                'Please don''t use.']);
            if isa(events,'char')
                events = {events};
            end
            %Step 1: separate strides by the first event
            [numStrides,initTime,endTime] = ...
                getStrideInfo(this,events{1});
            M = numStrides;
            N = length(events);
            %Step 2: for each stride, find the other events (if any)
            intermediateTimes = nan(M,N-1);
            bad = false(M,1);
            for ii = 1:M
                for jj = 1:N-1
                    aux = find( ...
                        this.gaitEvents.getDataAsVector( ...
                        events{jj+1}) & ...
                        this.gaitEvents.Time >= initTime(ii) & ...
                        this.gaitEvents.Time < endTime(ii));
                    %Found only one event, as expected
                    if length(aux) == 1
                        intermediateTimes(ii,jj) = ...
                            this.gaitEvents.Time(aux);
                    else
                        bad(ii) = true;
                    end
                end
            end
            %Step 3: slice timeseries
            timeBreakpoints = [initTime, intermediateTimes]';
            [slicedTS,~,~] = ...
                sliceTS(this.(field), ...
                [timeBreakpoints(:); endTime(end)],0);

            %Step 4: reshape & set to [] the slices which didn't have
            %proper events
            stridedField = reshape(slicedTS,N,M)';
        end
    end

end

