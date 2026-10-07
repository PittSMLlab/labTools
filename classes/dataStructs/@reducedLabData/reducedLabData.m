classdef reducedLabData % AKA alignedLabData
    %REDUCEDLABDATA Time-aligned and resampled data container
    %
    %   reducedLabData (also known as alignedLabData) contains data that
    % has been aligned to gait events and resampled to a standard time
    % base. All time series are organized into a single alignedTimeSeries
    % object with consistent sampling across strides.
    %
    % reducedLabData properties:
    %   Data - alignedTimeSeries object containing all aligned data
    %   bad - logical vector indicating strides with issues
    %   gaitEvents - labTimeSeries with gait event markers
    %   adaptParams - parameterSeries with adaptation parameters
    %   metaData - labMetaData object
    %   procEMGData - processed EMG data (dependent)
    %   angleData - joint angle data (dependent)
    %   COPData - center of pressure data (dependent)
    %   COMData - center of mass data (dependent)
    %   jointMomentsData - joint moment data (dependent)
    %   markerData - marker trajectory data (dependent)
    %   GRFData - ground reaction force data (dependent)
    %   accData - acceleration data (dependent)
    %   beltSpeedSetData - commanded belt speeds (dependent)
    %   beltSpeedReadData - actual belt speeds (dependent)
    %   footSwitchData - foot switch data (dependent)
    %   strideNo - number of strides (dependent)
    %   initTimes - initial time for each stride (dependent)
    %
    % reducedLabData methods:
    %   reducedLabData - constructor for reduced lab data
    %
    % Toolbox Dependencies: None
    %
    % See also PROCESSEDLABDATA, ALIGNEDTIMESERIES, LABDATA.

    %% Properties
    properties
        Data = [];
        bad  = [];
        gaitEvents % labTS
        adaptParams
        metaData % labMetaData object
    end

    properties (Dependent)
        procEMGData % processedEMGTS
        angleData % labTS (angles based off kinematics)
        COPData
        COMData
        jointMomentsData
        markerData % orientedLabTS
        GRFData % orientedLabTS
        accData % orientedLabTS
        beltSpeedSetData % labTS, sent commands to treadmill
        beltSpeedReadData % labTS, speed read from treadmill
        footSwitchData % labTS
        strideNo
        initTimes
    end

    properties (SetAccess = private)
        fields_
        fieldPrefixes_
    end

    %% Constructor
    methods
        function this = reducedLabData(metaData, events, alignTS, bad, ...
            fields, fieldPrefixes, adaptParams)
            %REDUCEDLABDATA Constructor for reducedLabData class
            %
            %   this = reducedLabData(metaData, events, alignTS, bad,
            % fields, fieldPrefixes, adaptParams) creates a reduced lab data
            % object with time-aligned data organized by stride
            %
            % Inputs:
            %   metaData      - labMetaData or subclass object
            %   events        - labTimeSeries with gait events
            %   alignTS       - alignedTimeSeries with resampled data
            %   bad           - logical vector indicating bad strides
            %   fields        - cell array of field names included in data
            %   fieldPrefixes - cell array of prefixes for each field
            %   adaptParams   - parameterSeries with parameters
            %
            % Outputs:
            %   this - reducedLabData object
            %
            % Toolbox Dependencies: None
            %
            % See also PROCESSEDLABDATA.REDUCE, ALIGNEDTIMESERIES.

            this.metaData = metaData;
            this.Data = alignTS;
            this.bad = bad;
            this.fields_ = fields;
            this.fieldPrefixes_ = fieldPrefixes;
            this.adaptParams = adaptParams;
            this.gaitEvents = events;
        end
    end

    %% Dependent Property Getters
    methods
        % Can we do a universal getter for dependent fields like this?
        % function pED = get(fieldName)
        %     prefix = this.fieldPrefixes_(strcmp(this.fields_, fieldName));
        %     pED = this.Data.getPartialDataAsATS( ...
        %    this.Data.getLabelsThatMatch(prefix));
        % end

        function pED = get.procEMGData(this)
            %GET.PROCEMGDATA Returns processed EMG data
            %
            %   Uses universal getter to extract EMG-prefixed data
            %
            % Toolbox Dependencies: None

            ST  = dbstack;
            pED = this.universalDependentFieldGetter(ST.name);
        end

        function pED = get.angleData(this)
            %GET.ANGLEDATA Returns joint angle data
            %
            %   Uses universal getter to extract angle-prefixed data
            %
            % Toolbox Dependencies: None

            [ST, ~] = dbstack;
            pED = this.universalDependentFieldGetter(ST.name);
        end

        function pED = get.COPData(this)
            %GET.COPDATA Returns center of pressure data
            %
            %   Uses universal getter to extract COP-prefixed data
            %
            % Toolbox Dependencies: None

            [ST, ~] = dbstack;
            pED = this.universalDependentFieldGetter(ST.name);
        end

        function pED = get.COMData(this)
            %GET.COMDATA Returns center of mass data
            %
            %   Uses universal getter to extract COM-prefixed data
            %
            % Toolbox Dependencies: None

            [ST, ~] = dbstack;
            pED = this.universalDependentFieldGetter(ST.name);
        end

        function pED = get.jointMomentsData(this)
            %GET.JOINTMOMENTSDATA Returns joint moment data
            %
            %   Uses universal getter to extract moment-prefixed data
            %
            % Toolbox Dependencies: None

            [ST, ~] = dbstack;
            pED = this.universalDependentFieldGetter(ST.name);
        end

        function pED = get.markerData(this)
            %GET.MARKERDATA Returns marker trajectory data
            %
            %   Uses universal getter to extract marker-prefixed data
            %
            % Toolbox Dependencies: None

            [ST, ~] = dbstack;
            pED = this.universalDependentFieldGetter(ST.name);
        end

        function pED = get.accData(this)
            %GET.ACCDATA Returns acceleration data
            %
            %   Uses universal getter to extract acceleration-prefixed data
            %
            % Toolbox Dependencies: None

            [ST, ~] = dbstack;
            pED = this.universalDependentFieldGetter(ST.name);
        end

        function pED = get.GRFData(this)
            %GET.GRFDATA Returns ground reaction force data
            %
            %   Uses universal getter to extract GRF-prefixed data
            %
            % Toolbox Dependencies: None

            [ST, ~] = dbstack;
            pED = this.universalDependentFieldGetter(ST.name);
        end

        function pED = get.beltSpeedSetData(this)
            %GET.BELTSPEEDSETDATA Returns commanded belt speed data
            %
            %   Currently returns empty as belt speed data is not included
            % in reduced format
            %
            % Toolbox Dependencies: None

            pED = [];
        end

        function pED = get.beltSpeedReadData(this)
            %GET.BELTSPEEDREADDATA Returns actual belt speed data
            %
            %   Currently returns empty as belt speed data is not included
            % in reduced format
            %
            % Toolbox Dependencies: None

            pED = [];
        end

        function pED = get.footSwitchData(this)
            %GET.FOOTSWITCHDATA Returns foot switch data
            %
            %   Currently returns empty as foot switch data is not included
            % in reduced format
            %
            % Toolbox Dependencies: None

            pED = [];
        end

        function sN = get.strideNo(this)
            %GET.STRIDENO Returns number of strides in data
            %
            % Outputs:
            %   sN - number of strides (third dimension of Data)
            %
            % Toolbox Dependencies: None

            sN = size(this.Data.Data, 3);
        end

        function iT = get.initTimes(this)
            %GET.INITTIMES Returns initial time for each stride
            %
            % Outputs:
            %   iT - vector of initial times for each stride
            %
            % Toolbox Dependencies: None

            iT = this.Data.eventTimes(1, 1:end - 1);
        end
    end

    %% Property Setters
    methods
        function this = set.metaData(this, mD)
            %SET.METADATA Validates and sets metadata
            %
            % Inputs:
            %   this - reducedLabData object
            %   mD   - labMetaData or subclass object
            %
            % Toolbox Dependencies: None

            % TODO: Check something
            this.metaData = mD;
        end

        function this = set.Data(this, dd)
            %SET.DATA Validates and sets aligned data
            %
            % Inputs:
            %   this - reducedLabData object
            %   dd   - alignedTimeSeries object
            %
            % Toolbox Dependencies: None

            if ~isa(dd, 'alignedTimeSeries')
                error('reducedLabData:setData', ...
                    'Data needs to be an ATS');
            else
                this.Data = dd;
            end
        end

        function this = set.bad(this, b)
            %SET.BAD Validates and sets bad stride flags
            %
            % Inputs:
            %   this - reducedLabData object
            %   b    - logical vector of length equal to number of strides
            %
            % Toolbox Dependencies: None

            if length(b) ~= this.strideNo
                error('reducedLabData:setBad', ...
                    'Inconsistent sizes');
            else
                this.bad = b;
            end
        end

        function this = set.gaitEvents(this, e)
            %SET.GAITEVENTS Validates and sets gait events
            %
            % Inputs:
            %   this - reducedLabData object
            %   e    - logical labTimeSeries with event markers
            %
            % Toolbox Dependencies: None

            if ~isa(e, 'labTimeSeries') || ~isa(e.Data, 'logical')
                error('reducedLabData:setGaitEvents', ...
                    'Input argument needs to be a logical labTimeSeries');
            else
                this.gaitEvents = e;
            end
        end

        function this = set.adaptParams(this, aP)
            %SET.ADAPTPARAMS Validates and sets adaptation parameters
            %
            % NOTE: Validates that parameter count matches stride count and
            %   that initial times are consistent
            %
            % Inputs:
            %   this - reducedLabData object
            %   aP   - parameterSeries object with parameters for each
            %          stride
            %
            % Toolbox Dependencies: None

            if ~isa(aP, 'parameterSeries') || ...
                    size(aP.Data, 1) ~= this.strideNo
                error('reducedLabData:setAdaptParams', ...
                    ['Input argument needs to be a parameterSeries ' ...
                    'object of length equal to stride number.']);
                % Check that adaptParams is computed with the same initial
                % event as alignTS was
            elseif any(abs(aP.getDataAsVector('initTime') - ...
                    this.initTimes') > 1e-9)
                error('reducedLabData:setAdaptParams', ...
                    ['AdaptParams seems to have been computed with ' ...
                    'different events than the provided data (alignTS)']);
            else
                this.adaptParams = aP;
            end
        end
    end

    %% Hidden Methods
    methods (Hidden)
        function pED = universalDependentFieldGetter(this, funName)
            %UNIVERSALDEPENDENTFIELDGETTER Universal getter for dependent
            %fields
            %
            %   pED = universalDependentFieldGetter(this, funName) extracts
            % data for a dependent field by matching the field prefix and
            % removing the prefix from labels
            %
            % NOTE: This method is called by all dependent property getters
            %   to extract field-specific data from the unified Data
            %   property
            %
            % Inputs:
            %   this    - reducedLabData object
            %   funName - full function name from stack trace
            %
            % Outputs:
            %   pED - alignedTimeSeries with extracted field data
            %
            % Toolbox Dependencies: None

            fieldName = regexp(funName, '\.get\.', 'split');
            prefix = this.fieldPrefixes_(strcmp(this.fields_, ...
                fieldName{2}));
            pED = this.Data.getPartialDataAsATS(...
                this.Data.getLabelsThatMatch(prefix));
            warning('off', 'labTS:renameLabels:dont');
            pED = pED.renameLabels([], cellfun(@(x) x(4:end), ...
                pED.labels, 'UniformOutput', false));
            warning('on', 'labTS:renameLabels:dont');
        end
    end

end

