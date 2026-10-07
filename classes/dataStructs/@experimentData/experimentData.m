classdef experimentData
    %EXPERIMENTDATA Contain all information of one experimental session.
    %
    %   experimentData organizes all data, metadata, and subject
    % information for a complete experimental session. It provides
    % methods for data processing, analysis, visualization, and
    % parameter extraction.
    %
    % experimentData properties:
    %   metaData    - experimentMetaData object with experimental
    %                 conditions and trial organization
    %   subData     - subjectData object with subject demographics
    %                 and anthropometrics
    %   data        - cell array of labData objects or any objects
    %                 that extend labData
    %   isRaw       - true if data contains rawLabData objects (dependent)
    %   isProcessed - true if data contains processedLabData objects
    %                 (dependent)
    %   isStepped   - true if data contains strideData objects (dependent)
    %   fastLeg     - leg on the fast belt, 'L' or 'R' (dependent)
    %
    % experimentData methods:
    %   experimentData                - constructor
    %   getSubjectAgeAtExperimentDate - subject age at experiment date
    %   getSlowLeg                    - slow-belt leg identifier
    %   getRefLeg                     - reference leg identifier
    %   getNonRefLeg                  - non-reference leg identifier
    %   process                       - processes all raw trial data
    %   extractMarkerModels           - builds marker position models
    %   checkMarkerHealth             - validates marker data quality
    %   computeAngles                 - computes joint angles
    %   makeDataObj                   - creates adaptationData object
    %   reduce                        - creates reducedLabData objects
    %   parameterEvolutionPlot        - plots parameter evolution
    %   parameterTimeCourse           - plots parameter time course
    %   recomputeParameters           - recalculates adaptation params
    %   flushAndRecomputeParameters   - fully recalculates parameters
    %   recomputeEvents               - recalculates gait events
    %   splitIntoStrides              - splits trials into strides
    %   getStridedField               - extracts strided field data
    %   getAlignedField               - extracts time-aligned data
    %   getConditionIdxsFromName      - condition indices from names
    %   getStrideInfo                 - stride timing information
    %
    % experimentData static methods:
    %   loadobj - backward-compatible object loading (removes DOB)
    %
    % Toolbox Dependencies: None
    %
    % See also EXPERIMENTMETADATA, SUBJECTDATA, LABDATA, ADAPTATIONDATA.

    %% Properties
    properties
        metaData = [] % experimentMetaData object with experiment info
        subData  = [] % subjectData object
        data     = {} % cell array of labData or subclass objects
    end

    properties (Dependent)
        isRaw       % true if data is rawLabData class
        isProcessed % true if data is processedLabData class
        isStepped   % true if data is strideData class (or strided)
        fastLeg
    end

    %% Constructor
    methods
        function this = experimentData(meta, sub, data)
            %EXPERIMENTDATA Constructor for experimentData class.
            %
            %   this = experimentData(meta, sub, data) creates an experiment
            % data object with specified metadata, subject data, and trial
            % data. All arguments are optional.
            %
            % Inputs:
            %   meta - (optional) experimentMetaData object
            %   sub  - (optional) subjectData object
            %   data - (optional) cell array of labData objects
            %
            % Outputs:
            %   this - experimentData object
            %
            % Toolbox Dependencies: None
            %
            % See also EXPERIMENTMETADATA, SUBJECTDATA, LABDATA.

            arguments
                meta = []
                sub  = []
                data = {}
            end

            % Only assign non-empty arguments to avoid triggering
            % property validators with the default empty values
            if ~isempty(meta)
                this.metaData = meta;
            end
            if ~isempty(sub)
                this.subData = sub;
            end
            if ~isempty(data)
                this.data = data;
            end
        end
    end

    %% Property Setters
    methods
        function this = set.metaData(this, meta)
            %SET.METADATA Validates and sets experiment metadata.
            %
            %   Property-block validators (mustBeA) were not used here
            % because MATLAB evaluates them against the declared default
            % value at class load time, causing an immediate error since the
            % default [] is a double, not an experimentMetaData. The
            % constructor's if ~isempty() guard prevents this setter from
            % being reached with the default empty value.
            %
            % Inputs:
            %   this - experimentData object
            %   meta - experimentMetaData object
            %
            % Toolbox Dependencies: None

            if isa(meta, 'experimentMetaData')
                this.metaData = meta;
            else
                ME = MException('experimentData:Constructor', ...
                    ['Experiment metaData is not an ' ...
                    'experimentMetaData type object.']);
                throw(ME);
            end
        end

        function this = set.subData(this, sub)
            %SET.SUBDATA Validates and sets subject data.
            %
            %   Property-block validators (mustBeA) were not used here
            % because MATLAB evaluates them against the declared default
            % value at class load time, causing an immediate error since the
            % default [] is a double, not a subjectData. The constructor's
            % if ~isempty() guard prevents this setter from being reached
            % with the default empty value.
            %
            %   isa() returns true for subclasses of subjectData (e.g.,
            % strokeSubjectData), so this validator correctly accepts both
            % healthy and stroke participant data objects.
            %
            % Inputs:
            %   this - experimentData object
            %   sub  - subjectData object
            %
            % Toolbox Dependencies: None

            if isa(sub, 'subjectData')
                this.subData = sub;
            else
                ME = MException('experimentData:Constructor', ...
                    'Subject data is not a subjectData type object.');
                throw(ME);
            end
        end

        function this = set.data(this, data)
            %SET.DATA Validates and sets experimental trial data.
            %
            %   Element-level validation (each non-empty cell must contain a
            % labData or reducedLabData object) cannot be expressed in the
            % properties block, so all three property setters are retained
            % as explicit methods.
            %
            % Inputs:
            %   this - experimentData object
            %   data - cell array of labData objects
            %
            % Toolbox Dependencies: None

            if isa(data, 'cell')  % Has to be array of labData cells
                aux = find(cellfun('isempty', data) ~= 1);
                for ii = 1:length(aux)
                    if ~isa(data{aux(ii)}, 'labData') && ...
                            ~isa(data{aux(ii)}, 'reducedLabData')
                        ME = MException('experimentData:Constructor', ...
                            ['Data is not a cell array of labData ' ...
                            '(or one of its subclasses) objects.']);
                        throw(ME);
                    end
                end
                this.data = data;
            else
                ME = MException('experimentData:Constructor', ...
                    'Data is not a cell array.');
                throw(ME);
            end
        end
    end

    %% Dependent Property Getters
    methods
        function a = get.isProcessed(this)
            %GET.ISPROCESSED Checks if trials have been processed.
            %
            %   Returns true if the trials have been processed (i.e.,
            % parameters have been calculated through labData.process()),
            % and false if they contain only rawData.
            %
            % Inputs:
            %   this - experimentData object
            %
            % Outputs:
            %   a - boolean indicating if data is processed
            %
            % Toolbox Dependencies: None

            aux = cellfun('isempty', this.data);
            idx = find(aux ~= 1);       % not empty
            a   = true;
            for ii = idx
                if ~isa(this.data{ii}, 'processedLabData')
                    a = false;
                end
            end
        end

        function a = get.isStepped(this)
            %GET.ISSTEPPED Checks if data is strided.
            %
            %   Returns true if data is an object of the strideData class.
            %
            % Inputs:
            %   this - experimentData object
            %
            % Outputs:
            %   a - boolean indicating if data is strided
            %
            % Toolbox Dependencies: None

            aux = cellfun('isempty', this.data);
            idx = find(aux ~= 1, 1);
            a   = isa(this.data{idx}, 'strideData');
        end

        function a = get.isRaw(this)
            %GET.ISRAW Checks if data is raw.
            %
            %   Returns true if data is an object of the rawLabData class.
            %
            % Inputs:
            %   this - experimentData object
            %
            % Outputs:
            %   a - boolean indicating if data is raw
            %
            % Toolbox Dependencies: None

            aux = cellfun('isempty', this.data);
            idx = find(aux ~= 1, 1);
            a   = isa(this.data{idx}, 'rawLabData');
        end

        function fastLeg = get.fastLeg(this)
            %GET.FASTLEG Determines which leg was on the fast belt.
            %
            %   Based on each trial, determines from the data (not metadata,
            % which could be wrong) which leg is the fast leg, even if there
            % is no belt data.
            %
            % NOTE: Currently unimplemented. Try getRefLeg, which reads
            %   slow/fast leg labels from trial metaData.
            %
            % Inputs:
            %   this - experimentData object
            %
            % Outputs:
            %   fastLeg - 'R' or 'L'
            %
            % Toolbox Dependencies: None

            % NOTE: the error below makes the rest of this method
            % unreachable: remove the dead code or complete it.
            error(['Unimplemented. Try getRefLeg, which reads ' ...
                'slow/fast leg labels from trial metaData.']);
            % -- Dead code below this line ---------------------------
            vR     = [];
            vL     = [];
            trials = cell2mat(this.metaData.trialsInCondition);
            for ii = 1:length(trials)
                trial = trials(ii);
                if ~this.isStepped
                    if ~isempty(this.data{trial}.beltSpeedReadData)
                        % NOTE: the code below does not work because
                        % beltSpeedReadData is not populated.
                        % vR(end+1) = mean( ...
                        %     this.data{trial} ...
                        %     .beltSpeedReadData ...
                        %     .getDataAsVector('R'), 'omitnan');
                        % vL(end+1) = mean( ...
                        %     this.data{trial} ...
                        %     .beltSpeedReadData ...
                        %     .getDataAsVector('L'), 'omitnan');
                        % New version:
                        % TODO: Need to come up with an appropriate
                        % velocity measurement if we want this
                        % function to work properly.
                    end
                else % Stepped trial
                    for step = 1:length(this.data{trial})
                        if ~isempty( ...
                                this.data{trial}{step}.beltSpeedReadData)
                            % vR(end+1) = mean( ...
                            %     this.data{trial}{step} ...
                            %     .beltSpeedReadData ...
                            %     .getDataAsVector('R'), 'omitnan');
                            % vL(end+1) = mean( ...
                            %     this.data{trial}{step} ...
                            %     .beltSpeedReadData ...
                            %     .getDataAsVector('L'), 'omitnan');
                        end
                    end
                end
            end
            if ~isempty(vR) && ~isempty(vL)
                if mean(vR, 'omitnan') < mean(vL, 'omitnan')
                    fastLeg = 'L';
                elseif mean(vR, 'omitnan') > mean(vL, 'omitnan')
                    % Defaults to this, even if there is no beltSpeedData
                    fastLeg = 'R';
                else
                    error('experimentData:fastLeg', ...
                        'Both legs are moving at the same speed');
                end
            else
                error('experimentData:fastLeg', ...
                    ['No data to compute fastest leg, try using ' ...
                    'expData.getRefLeg which reads from each ' ...
                    'trial''s metaData.']);
            end
        end
    end

    %% Subject Information Methods
    methods
        ageInMonths = getSubjectAgeAtExperimentDate(this)
    end

    %% Leg Identification Methods
    methods
        slowLeg = getSlowLeg(this)

        refLeg = getRefLeg(this)

        fL = getNonRefLeg(this)
    end

    %% Data Processing Methods
    methods
        processedThis = process(this, eventClass)

        [allTrialModels, modelScore, badFlag] = extractMarkerModels(this)

        this = checkMarkerHealth(this, refTrial)

        this = computeAngles(this)
    end

    %% Data Reduction and Object Creation
    methods
        adaptData = makeDataObj( ...
            this, filename, experimentalFlag, contraLateralFlag)

        reducedThis = reduce(this, eventLabels, N)
    end

    %% Visualization Methods
    methods
        %% Display
        % NOTE: these are slow: a field that is not a label of adaptParams
        % is assumed to be in experimentalParams, which can take minutes
        % to find out that the parameter does not exist. They are kept
        % for flexibility; the efficient way is to build and save an
        % adaptData object and use its plotting methods (which these call).
        % TODO: warn the user that this takes long.
        [h, adaptDataObject] = parameterEvolutionPlot(this, field)

        [h, adaptDataObject] = parameterTimeCourse(this, field)
    end

    %% Parameter and Event Methods
    methods
        this = recomputeParameters( ...
            this, eventClass, initEventSide, parameterClasses, ...
            shouldComputeEMGNorm,muscleLabels, ...
            normalizationRefCond, biasRemovalCond)

        this = flushAndRecomputeParameters(this, eventClass, ...
            initEventSide,...
            shouldComputeEMGNorm,muscleLabels, ...
            normalizationRefCond, biasRemovalCond)

        this = recomputeEvents(this, eventClass, initEventSide)
    end

    %% Stride Analysis Methods
    methods
        stridedExp = splitIntoStrides(this, refEvent)

        [stridedField, bad, originalTrial, originalInitTime, ...
            gaitEventLabel] = getStridedField(this, field, ...
            conditions, gaitEventLabel)

        [alignedField, originalTrial, bad] = getAlignedField( ...
            this, field, conditions, gaitEventLabel, alignmentLengths)
    end

    %% Auxiliary Methods
    methods
        conditionIdxs = getConditionIdxsFromName(this, conditionNames)

        [numStrides, trials, initTimes, endTimes] = getStrideInfo( ...
            this, eventClass)
    end

    %% Private Methods
    methods (Hidden = true, Access = private)
        adaptData = makeDataObjNew( ...
            this, filename, experimentalFlag, contraLateralFlag)
    end

    %% Static Methods
    methods (Static)
        function this = loadobj(this)
            %LOADOBJ Object loading method for backward compatibility.
            %
            %   this = loadobj(this) scrubs date of birth information when
            % loading saved experimentData objects for privacy.
            %
            % Inputs:
            %   this - experimentData object being loaded
            %
            % Outputs:
            %   this - experimentData object with DOB removed
            %
            % Toolbox Dependencies: None
            %
            % See also SAVEOBJ, SUBJECTDATA.

            if ~isempty(this.subData.dateOfBirth)
                warning('expData:subjectDOB', ...
                    ['Subject data contains DOB information for ' ...
                    'subject ' this.subData.ID '. Data will be ' ...
                    'hidden. You should overwrite (save) your file ' ...
                    'with this new version to prevent this warning ' ...
                    'in the future. Please check that all other ' ...
                    'information is intact before overwriting.']);
                % Determine age (in months):
                age = round(this.metaData.date.timeSince( ...
                    this.subData.dateOfBirth));
                % Scrub DOB from subject meta data, save age at
                % experiment time (in years):
                this.subData = subjectData([], ...
                    this.subData.sex, ...
                    this.subData.dominantLeg, ...
                    this.subData.dominantArm, ...
                    this.subData.height, ...
                    this.subData.weight, ...
                    age / 12, this.subData.ID);
            end
        end
    end

end

