classdef experimentMetaData
    %EXPERIMENTMETADATA Describe an experimental session as a whole.
    %
    %   experimentMetaData contains metadata for an entire experimental
    % session, including subject information, experimental conditions,
    % trial organization, and condition validation methods.
    %
    % experimentMetaData properties:
    %   ID - string containing the subject ID (e.g., 'OG90' or 'CGN05')
    %   date - labDate object containing the date of the experiment
    %   experimenter - string, initials/name of person(s) who ran the
    %                  experiment
    %   observations - string with overall study observations
    %                  (observations for individual trials are stored in
    %                  trialMetaData class objects)
    %   conditionName - cell array of strings containing labels given to
    %                   each condition of the experiment
    %   conditionDescription - cell array of strings containing detailed
    %                          description of each condition (belt speeds,
    %                          number of steps, belt ratio, etc.)
    %   trialsInCondition - cell array of numbers matching condition
    %                       number to trial numbers (trial numbers must
    %                       match up with c3d file names)
    %   Ntrials - total number of trials
    %   SchenleyPlace - flag indicating if data collected at Schenley
    %                   Place lab
    %   PerceptualTasks - flag indicating presence of perceptual tasks
    %   datlog - data log structure
    %
    % experimentMetaData methods:
    %   getCondLstPerTrial - returns list of condition numbers for each
    %                        trial
    %   splitConditionIntoTrials - splits condition into separate trials
    %   getConditionIdxsFromName - returns condition number for
    %                              conditions with similar name
    %   getTrialsInCondition - returns trial numbers in each condition
    %   replaceConditionNames - replaces condition names
    %   checkConditionOrder - checks that conditions appear in order
    %   validateTrialsInCondition - validates trial organization
    %   sortConditions - sorts conditions by trial order
    %   numerateRepeatedConditionNames - adds numbers to repeated
    %                                    condition names
    %   getConditionsThatMatch - returns condition names matching pattern
    %   getConditionsThatMatchV2 - returns condition names matching
    %                              pattern with fallback
    %
    % Toolbox Dependencies: None
    %
    % See also LABDATE, TRIALMETADATA.

    %% Properties
    properties
        ID;
        date = labDate.default; % labDate object
        experimenter = '';
        observations = '';
        conditionName = {};
        conditionDescription = {};
        trialsInCondition = {};
        Ntrials = [];
        SchenleyPlace = [];
        PerceptualTasks = [];
        datlog;
    end

    %% Constructor
    methods
        function this = experimentMetaData(ID, date, experimenter, obs, ...
            conds, desc, trialLst, Ntrials, SchenleyPlace, ...
            PerceptualTasks, datlog)
            %EXPERIMENTMETADATA Constructor for experimentMetaData class.
            %
            %   this = experimentMetaData(ID) creates an experiment
            % metadata object with the specified subject ID.
            %
            %   this = experimentMetaData(ID, date, experimenter, obs,
            % conds, desc, trialLst, Ntrials, SchenleyPlace,
            % PerceptualTasks, datlog) creates an experiment metadata
            % object with all specified parameters.
            %
            % Inputs:
            %   ID              - subject identifier string
            %   date            - (optional) labDate object
            %   experimenter    - (optional) experimenter name/initials
            %   obs             - (optional) general observations
            %   conds           - (optional) cell array of condition names
            %   desc            - (optional) cell array of condition
            %                     descriptions
            %   trialLst        - (optional) cell array of trial numbers
            %                     per condition
            %   Ntrials         - (optional) total number of trials
            %   SchenleyPlace   - (optional) Schenley Place lab flag
            %   PerceptualTasks - (optional) perceptual tasks flag
            %   datlog          - (optional) data log structure
            %
            % Outputs:
            %   this - experimentMetaData object
            %
            % NOTE: The constructor validates that condition names are
            %       unique and that trials are not interleaved between
            %       conditions.
            %
            % Toolbox Dependencies: None
            %
            % See also TRIALMETADATA, LABDATE.

            this.ID = ID;
            if nargin > 1
                this.date = date;
            end
            if nargin > 2
                this.experimenter = experimenter;
            end
            if nargin > 3
                this.observations = obs;
            end
            if nargin > 4
                if length(unique(conds)) < length(conds)
                    error('ExperimentMetaData:Constructor', ...
                        ['There are repeated condition names, which is '...
                        'not allowed']);
                elseif sum(cellfun(@(x) ~isempty(strfind(x, ...
                        'TM base')), conds)) > 1 || ...
                        sum(cellfun(@(x) ~isempty(strfind(x, ...
                        'OG base')), conds)) > 1
                    error('ExperimentMetaData:Constructor', ...
                        ['More than one condition name contains the ' ...
                        'string ''TM base'' or ''OG base'' which is ' ...
                        'not allowed.']);
                else
                    this.conditionName = conds;
                end
            end
            if nargin > 5
                this.conditionDescription = desc;
            end
            if nargin > 6
                this.trialsInCondition = trialLst;
            end
            if nargin > 7
                this.Ntrials = Ntrials;
            end
            if nargin > 8
                this.SchenleyPlace = SchenleyPlace;
            end
            if nargin > 9
                this.PerceptualTasks = PerceptualTasks;
            end
            if nargin > 10
                this.datlog = datlog;
            end

            % Check that conditions do not include interleaved or
            % repeated trials:
            conditionOrder = this.validateTrialsInCondition;
            % Sort conditions according to trial numbers:
            this = this.sortConditions;
        end
    end

    %% Property Setters
    methods
        function this = set.ID(this, ID)
            %SET.ID Validate and set the subject ID.
            %
            %   Stores a char ID; an empty value is stored as ''. Any other
            % type raises experimentMetaData:Constructor.
            %
            % Inputs:
            %   this - experimentMetaData object
            %   ID   - subject identifier (char, or empty)
            %
            % Outputs:
            %   this - experimentMetaData object (updated)
            %
            % Toolbox Dependencies: None
            %
            % See also EXPERIMENTMETADATA.
            if isa(ID, 'char') % && nargin > 0
                this.ID = ID; % Mandatory field, needs to be string
            elseif isempty(ID) % || nargin == 0
                this.ID = '';
                % disp('Warning: creating emtpy ID field.')
            else
                ME = MException('experimentMetaData:Constructor', ...
                    'ID is not a string.');
                throw(ME);
            end
        end

        function this = set.date(this, date)
            %SET.DATE Validate and set the experiment date.
            %
            %   Stores a labDate object; any other type raises
            % experimentMetaData:Constructor.
            %
            % Inputs:
            %   this - experimentMetaData object
            %   date - experiment date (labDate)
            %
            % Outputs:
            %   this - experimentMetaData object (updated)
            %
            % Toolbox Dependencies: None
            %
            % See also EXPERIMENTMETADATA.
            if isa(date, 'labDate')
                this.date = date;
            else
                ME = MException('experimentMetaData:Constructor', ...
                    'date is not labDate object.');
                throw(ME);
            end
        end

        function this = set.experimenter(this, experimenter)
            %SET.EXPERIMENTER Validate and set the experimenter name.
            %
            %   Stores a char; any other type raises
            % experimentMetaData:Constructor.
            %
            % Inputs:
            %   this         - experimentMetaData object
            %   experimenter - experimenter name or initials (char)
            %
            % Outputs:
            %   this         - experimentMetaData object (updated)
            %
            % Toolbox Dependencies: None
            %
            % See also EXPERIMENTMETADATA.
            if isa(experimenter, 'char')
                this.experimenter = experimenter;
            else
                ME = MException('experimentMetaData:Constructor', ...
                    'experimenter is not a string.');
                throw(ME);
            end
        end

        function this = set.observations(this, obs)
            %SET.OBSERVATIONS Validate and set the session observations.
            %
            %   Stores a char; any other type raises
            % experimentMetaData:Constructor.
            %
            % Inputs:
            %   this - experimentMetaData object
            %   obs  - session observations (char)
            %
            % Outputs:
            %   this - experimentMetaData object (updated)
            %
            % Toolbox Dependencies: None
            %
            % See also EXPERIMENTMETADATA.
            if isa(obs, 'char')
                this.observations = obs;
            else
                ME = MException('experimentMetaData:Constructor', ...
                    'observations is not a string.');
                throw(ME);
            end
        end

        function this = set.conditionName(this, conds)
            %SET.CONDITIONNAME Set the condition names.
            %
            %   Stores a non-empty cell array; any other value is ignored
            % without error.
            %
            % Inputs:
            %   this  - experimentMetaData object
            %   conds - condition names (cell array of char)
            %
            % Outputs:
            %   this  - experimentMetaData object (updated)
            %
            % Toolbox Dependencies: None
            %
            % See also EXPERIMENTMETADATA.
            if ~isempty(conds) && isa(conds, 'cell')
                this.conditionName = conds;
            end
        end

        function this = set.conditionDescription(this, desc)
            %SET.CONDITIONDESCRIPTION Set the condition descriptions.
            %
            %   Stores a non-empty cell array; any other value is ignored
            % without error.
            %
            % Inputs:
            %   this - experimentMetaData object
            %   desc - condition descriptions (cell array of char)
            %
            % Outputs:
            %   this - experimentMetaData object (updated)
            %
            % Toolbox Dependencies: None
            %
            % See also EXPERIMENTMETADATA.
            if ~isempty(desc) && isa(desc, 'cell')
                this.conditionDescription = desc;
            end
        end

        function this = set.trialsInCondition(this, trialLst)
            %SET.TRIALSINCONDITION Validate and set trials per condition.
            %
            %   Stores a non-empty cell array of trial numbers per
            % condition; raises experimentMetaData:Constructor if a trial
            % appears in more than one condition. Any other value is
            % ignored without error.
            %
            % Inputs:
            %   this     - experimentMetaData object
            %   trialLst - trial numbers per condition (cell of double)
            %
            % Outputs:
            %   this     - experimentMetaData object (updated)
            %
            % Toolbox Dependencies: None
            %
            % See also EXPERIMENTMETADATA.
            % Must be cell of doubles
            if ~isempty(trialLst) && isa(trialLst, 'cell')
                % Check that no trial is repeated
                aux  = cell2mat(trialLst);
                aux2 = unique(aux);
                for ii = 1:length(aux2)
                    a = find(aux == aux2(ii));
                    if numel(a) > 1
                        ME = MException( ...
                            'experimentMetaData:Constructor', ...
                            ['Trial ' num2str(aux2(ii)) ' is listed as ' ...
                            'part of more than one condition.']);
                        throw(ME);
                    end
                end
                this.trialsInCondition = trialLst;
            end
        end

        function this = set.Ntrials(this, Ntrials)
            %SET.NTRIALS Set the number of trials.
            %
            %   Stores a double; any other value is ignored without error.
            %
            % Inputs:
            %   this    - experimentMetaData object
            %   Ntrials - total number of trials (double)
            %
            % Outputs:
            %   this    - experimentMetaData object (updated)
            %
            % Toolbox Dependencies: None
            %
            % See also EXPERIMENTMETADATA.
            if isa(Ntrials, 'double')
                this.Ntrials = Ntrials;
            end
        end

        function this = set.SchenleyPlace(this, SchenleyPlace)
            %SET.SCHENLEYPLACE Set the Schenley Place lab flag.
            %
            %   Stores a double; any other value is ignored without error.
            %
            % Inputs:
            %   this          - experimentMetaData object
            %   SchenleyPlace - Schenley Place lab flag (double)
            %
            % Outputs:
            %   this          - experimentMetaData object (updated)
            %
            % Toolbox Dependencies: None
            %
            % See also EXPERIMENTMETADATA.
            if isa(SchenleyPlace, 'double')
                this.SchenleyPlace = SchenleyPlace;
            end
        end

        function this = set.PerceptualTasks(this, PerceptualTasks)
            %SET.PERCEPTUALTASKS Set the perceptual-tasks flag.
            %
            %   Stores a double; any other value is ignored without error.
            %
            % Inputs:
            %   this            - experimentMetaData object
            %   PerceptualTasks - perceptual-tasks flag (double)
            %
            % Outputs:
            %   this            - experimentMetaData object (updated)
            %
            % Toolbox Dependencies: None
            %
            % See also EXPERIMENTMETADATA.
            if isa(PerceptualTasks, 'double')
                this.PerceptualTasks = PerceptualTasks;
            end
        end

        function this = set.datlog(this, datlog)
            %SET.DATLOG Set the data log.
            %
            %   Stores a cell array; any other value is ignored without
            % error.
            %
            % Inputs:
            %   this   - experimentMetaData object
            %   datlog - data log (cell array)
            %
            % Outputs:
            %   this   - experimentMetaData object (updated)
            %
            % Toolbox Dependencies: None
            %
            % See also EXPERIMENTMETADATA.
            if isa(datlog, 'cell')
                this.datlog = datlog;
            end
        end
    end

    %% Condition Query Methods
    methods
        condLst = getCondLstPerTrial(this)

        conditionIdxs = getConditionIdxsFromName(this, conditionNames, ...
            exactMatchesOnlyFlag, ignoreMissingNamesFlag)

        trialNums = getTrialsInCondition(this, conditionNames)

        condNames = getConditionsThatMatch(this, name, type)

        condNames = getConditionsThatMatchV2(this, name, type)
    end

    %% Condition Manipulation Methods
    methods
        newThis = splitConditionIntoTrials(this, condList)

        [newThis, change] = replaceConditionNames(this, currentName, ...
            newName)

        [newThis, change] = numerateRepeatedConditionNames(this)
    end

    %% Validation Methods
    methods
        conditionOrder = checkConditionOrder(this, ...
            conditionNamesInOrder, silentFlag)

        conditionOrder = validateTrialsInCondition(this)

        newThis = sortConditions(this)
    end

    %% Static Methods
    methods (Static)
        function this = loadobj(this)
            %LOADOBJ Validate and sort conditions when loading an object.
            %
            %   this = loadobj(this) validates and sorts conditions when
            % loading saved experimentMetaData objects, so older saved
            % objects are checked every time they are loaded.
            %
            % Inputs:
            %   this - experimentMetaData object being loaded
            %
            % Outputs:
            %   this - validated and sorted experimentMetaData object
            %
            % Toolbox Dependencies: None
            %
            % See also SAVEOBJ, VALIDATETRIALSINCONDITION, SORTCONDITIONS.

            conditionOrder = this.validateTrialsInCondition();
            this           = this.sortConditions();
        end
    end

end

