classdef experimentData
    % experimentData  Contains all information for a single
    %   experimental session.
    %
    %   experimentData organizes all data, metadata, and subject
    % information for a complete experimental session. It provides
    % methods for data processing, analysis, visualization, and
    % parameter extraction.
    %
    % Toolbox Dependencies:
    %   None
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
    % See also: experimentMetaData, subjectData, labData, adaptationData

    %% Properties
    properties
        metaData = []  % experimentMetaData object with experiment info
        subData  = []  % subjectData object
        data     = {}  % cell array of labData or subclass objects
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
            %experimentData  Constructor for experimentData class.
            %
            %   this = experimentData(meta, sub, data) creates an
            % experiment data object with specified metadata, subject data,
            % and trial data.
            %
            %   Inputs:
            %       meta - experimentMetaData object
            %       sub  - subjectData object
            %       data - cell array of labData objects
            %
            %   Outputs:
            %       this - experimentData object
            %
            %   See also: experimentMetaData, subjectData, labData

            if nargin > 0
                this.metaData = meta;
            end
            if nargin > 1
                this.subData = sub;
            end
            if nargin > 2
                this.data = data;
            end
        end
    end

    %% Property Setters
    methods
        function this = set.metaData(this, meta)
            %set.metaData  Validates and sets experiment metadata.
            %
            %   Inputs:
            %       this - experimentData object
            %       meta - experimentMetaData object

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
            %set.subData  Validates and sets subject data.
            %
            %   Inputs:
            %       this - experimentData object
            %       sub  - subjectData object

            % isa() returns true for subclasses of subjectData (e.g.,
            % strokeSubjectData), so this validator correctly accepts
            % both healthy and stroke participant data objects.
            if isa(sub, 'subjectData')
                this.subData = sub;
            else
                ME = MException('experimentData:Constructor', ...
                    'Subject data is not a subjectData type object.');
                throw(ME);
            end
        end

        function this = set.data(this, data)
            %set.data  Validates and sets experimental trial data.
            %
            %   Inputs:
            %       this - experimentData object
            %       data - cell array of labData objects

            if isa(data, 'cell')  % Has to be array of labData cells
                aux = find(cellfun('isempty', data) ~= 1);
                for i = 1:length(aux)
                    if ~isa(data{aux(i)}, 'labData') && ...
                            ~isa(data{aux(i)}, 'reducedLabData')
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
            %get.isProcessed  Checks if trials have been processed.
            %
            %   Returns true if the trials have been processed (i.e.,
            %   parameters have been calculated through labData.process()),
            %   and false if they contain only rawData.
            %
            %   Inputs:
            %       this - experimentData object
            %
            %   Outputs:
            %       a - boolean indicating if data is processed

            aux = cellfun('isempty', this.data);
            idx = find(aux ~= 1);       % not empty
            a   = true;
            for i = idx
                if ~isa(this.data{i}, 'processedLabData')
                    a = false;
                end
            end
        end

        function a = get.isStepped(this)
            %get.isStepped  Checks if data is strided.
            %
            %   Returns true if data is an object of the strideData class.
            %
            %   Inputs:
            %       this - experimentData object
            %
            %   Outputs:
            %       a - boolean indicating if data is strided

            aux = cellfun('isempty', this.data);
            idx = find(aux ~= 1, 1);
            a   = isa(this.data{idx}, 'strideData');
        end

        function a = get.isRaw(this)
            %get.isRaw  Checks if data is raw.
            %
            %   Returns true if data is an object of the rawLabData class.
            %
            %   Inputs:
            %       this - experimentData object
            %
            %   Outputs:
            %       a - boolean indicating if data is raw

            aux = cellfun('isempty', this.data);
            idx = find(aux ~= 1, 1);
            a   = isa(this.data{idx}, 'rawLabData');
        end

        function fastLeg = get.fastLeg(this)
            %get.fastLeg  Determines which leg was on the fast belt.
            %
            %   Based on each trial, determines from the data (not
            %   metadata, which could be wrong) which leg is the fast
            %   leg, even if there is no belt data.
            %
            %   Inputs:
            %       this - experimentData object
            %
            %   Outputs:
            %       fastLeg - 'R' or 'L'
            %
            %   Note: Currently unimplemented. Try getRefLeg, which
            %         reads slow/fast leg labels from trial metaData.

            % NOTE: The error below makes all code in this method
            % body unreachable. See suggestion to either remove the
            % dead code or complete the implementation.
            error(['Unimplemented. Try getRefLeg, which reads ' ...
                'slow/fast leg labels from trial metaData.']);
            % -- Dead code below this line ---------------------------
            vR     = [];
            vL     = [];
            trials = cell2mat(this.metaData.trialsInCondition);
            for i = 1:length(trials)
                trial = trials(i);
                if ~this.isStepped
                    if ~isempty(this.data{trial}.beltSpeedReadData)
                        % Old version: Need to fix, as we are not
                        % really populating the beltSpeedReadData
                        % field.
                        % vR(end+1) = nanmean( ...
                        %     this.data{trial} ...
                        %     .beltSpeedReadData ...
                        %     .getDataAsVector('R'));
                        % vL(end+1) = nanmean( ...
                        %     this.data{trial} ...
                        %     .beltSpeedReadData ...
                        %     .getDataAsVector('L'));
                        % New version:
                        % TODO: Need to come up with an appropriate
                        % velocity measurement if we want this
                        % function to work properly.
                    end
                else % Stepped trial
                    for step = 1:length(this.data{trial})
                        if ~isempty( ...
                                this.data{trial}{step}.beltSpeedReadData)
                            % vR(end+1) = nanmean( ...
                            %     this.data{trial}{step} ...
                            %     .beltSpeedReadData ...
                            %     .getDataAsVector('R'));
                            % vL(end+1) = nanmean( ...
                            %     this.data{trial}{step} ...
                            %     .beltSpeedReadData ...
                            %     .getDataAsVector('L'));
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
        % HH: I don't like either of these functions. They take way too
        % long to run, and at the time being they assume that if a field
        % isn't a label of the adaptParams property, then it must be a
        % label of experimentalParams (which is a bad assumption because it
        % could result in 5+ minutes of waiting just to find out the
        % parameter doesn't exist.)
        % PI, 5/26/2015: Agreed. Is there any other way to do it if someone
        % asks for a label that does not exist? Do note that these
        % functions are here for flexibility of the code, but the really
        % efficient way to do it is generate an adaptData object (and save
        % it) and use its plotting functions (which is what these do).
        % Perhaps we could issue a warning or a disclaimer telling the user
        % that this takes TOO long.
        [h, adaptDataObject] = parameterEvolutionPlot(this, field)

        [h, adaptDataObject] = parameterTimeCourse(this, field)
    end

    %% Parameter and Event Methods
    methods
        this = recomputeParameters( ...
            this, eventClass, initEventSide, parameterClasses)

        this = flushAndRecomputeParameters(this, eventClass, initEventSide)

        this = recomputeEvents(this, eventClass, initEventSide)
    end

    %% Stride Analysis Methods
    methods
        stridedExp = splitIntoStrides(this, refEvent)

        % [stridedField, bad, originalTrial, originalInitTime, events] =...
        %     getStridedField(this, field, conditions, events)
        function [stridedField, bad, originalTrial, originalInitTime, ...
                events] = getStridedField(this, field, conditions, events)
            if nargin < 4 || isempty(events)
                events = [this.getSlowLeg() 'HS'];
            end
            if nargin < 3 || isempty(conditions)
                trials = cell2mat(this.metaData.trialsInCondition);
            else
                % If conditions are given by name, not by index
                if ~isa(conditions, 'double')
                    conditions = getConditionIdxsFromName( ...
                        this, conditions);
                end
                trials = cell2mat( ...
                    this.metaData.trialsInCondition(conditions));
            end
            stridedField     = {};
            bad              = [];
            originalInitTime = [];
            originalTrial    = [];
            for i = trials
                % [aux, bad1, initTime1] = ...
                %     this.data{i}.(field).splitByEvents( ...
                %     this.data{i}.gaitEvents, events);
                [aux, bad1, initTime1, events] = ...
                    this.data{i}.getStridedField(field, events);
                stridedField     = [stridedField; aux];
                bad              = [bad; bad1];
                originalTrial    = [originalTrial; i * ones(size(bad1))];
                originalInitTime = [originalInitTime; initTime1];
            end
        end

        % [alignedField, originalTrial, bad] = getAlignedField( ...
        %     this, field, conditions, events, alignmentLengths)
        function [alignedField, originalTrial, bad] = getAlignedField( ...
                this, field, conditions, events, alignmentLengths)
            if nargin < 4 || isempty(events)
                events = [this.getSlowLeg() 'HS'];
            end
            if nargin < 3 || isempty(conditions)
                trials = cell2mat(this.metaData.trialsInCondition);
            else
                % If conditions are given by name, not by index
                if ~isa(conditions, 'double')
                    conditions = getConditionIdxsFromName(this,conditions);
                end
                trials = cell2mat( ...
                    this.metaData.trialsInCondition(conditions));
            end
            bad               = [];
            originalInitTime  = [];
            originalTrial     = [];
            originalDurations = [];
            for i = trials   % Trials in condition
                % [aux, bad1, initTime1] = ...
                %     this.data{i}.(field).splitByEvents( ...
                %     this.data{i}.gaitEvents, events);
                [alignedField1, bad1] = this.data{i}.getAlignedField( ...
                    field, events, alignmentLengths);
                if i == trials(1)
                    alignedField = alignedField1;
                else
                    force        = false;
                    alignedField = alignedField.cat( ...
                        alignedField1, [], force);
                end
                bad           = [bad; bad1];
                originalTrial = [originalTrial; i * ones(size(bad1))];
                % originalInitTime = [originalInitTime; initTime1];
                % originalDurations = [originalDurations; ...
                %     originalDurations1];
            end
        end
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
            %loadobj  Object loading method for backward compatibility.
            %
            %   this = loadobj(this) scrubs date of birth information
            %   when loading saved experimentData objects for privacy.
            %
            %   Inputs:
            %       this - experimentData object being loaded
            %
            %   Outputs:
            %       this - experimentData object with DOB removed
            %
            %   See also: saveobj, subjectData

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

