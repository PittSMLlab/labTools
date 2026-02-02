classdef experimentMetaData
    %experimentMetaData  Information describing the experiment as a whole
    %
    %   experimentMetaData contains metadata for an entire experimental
    %   session, including subject information, experimental conditions,
    %   trial organization, and condition validation methods.
    %
    %experimentMetaData properties:
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
    %experimentMetaData methods:
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
    %See also: labDate, trialMetaData

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
            %experimentMetaData  Constructor for experimentMetaData class
            %
            %   this = experimentMetaData(ID) creates an experiment
            %   metadata object with the specified subject ID
            %
            %   this = experimentMetaData(ID, date, experimenter, obs,
            %   conds, desc, trialLst, Ntrials, SchenleyPlace,
            %   PerceptualTasks, datlog) creates an experiment metadata
            %   object with all specified parameters
            %
            %   Inputs:
            %       ID - subject identifier string
            %       date - labDate object (optional)
            %       experimenter - experimenter name/initials (optional)
            %       obs - general observations (optional)
            %       conds - cell array of condition names (optional)
            %       desc - cell array of condition descriptions (optional)
            %       trialLst - cell array of trial numbers per condition
            %                  (optional)
            %       Ntrials - total number of trials (optional)
            %       SchenleyPlace - Schenley Place lab flag (optional)
            %       PerceptualTasks - perceptual tasks flag (optional)
            %       datlog - data log structure (optional)
            %
            %   Outputs:
            %       this - experimentMetaData object
            %
            %   Note: Constructor validates that condition names are unique
            %         and that trials are not interleaved between
            %         conditions
            %
            %   See also: trialMetaData, labDate

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
            if isa(date, 'labDate')
                this.date = date;
            else
                ME = MException('experimentMetaData:Constructor', ...
                    'date is not labDate object.');
                throw(ME);
            end
        end

        function this = set.experimenter(this, experimenter)
            if isa(experimenter, 'char')
                this.experimenter = experimenter;
            else
                ME = MException('experimentMetaData:Constructor', ...
                    'experimenter is not a string.');
                throw(ME);
            end
        end

        function this = set.observations(this, obs)
            if isa(obs, 'char')
                this.observations = obs;
            else
                ME = MException('experimentMetaData:Constructor', ...
                    'observations is not a string.');
                throw(ME);
            end
        end

        function this = set.conditionName(this, conds)
            if ~isempty(conds) && isa(conds, 'cell')
                this.conditionName = conds;
            end
        end

        function this = set.conditionDescription(this, desc)
            if ~isempty(desc) && isa(desc, 'cell')
                this.conditionDescription = desc;
            end
        end

        function this = set.trialsInCondition(this, trialLst)
            % Must be cell of doubles
            if ~isempty(trialLst) && isa(trialLst, 'cell')
                % Check that no trial is repeated
                aux = cell2mat(trialLst);
                aux2 = unique(aux);
                for i = 1:length(aux2)
                    a = find(aux == aux2(i));
                    if numel(a) > 1
                        ME = MException('experimentMetaData:Constructor', ...
                            ['Trial ' num2str(aux2(i)) ' is listed as ' ...
                            'part of more than one condition.']);
                        throw(ME);
                    end
                end
                this.trialsInCondition = trialLst;
            end
        end

        function this = set.Ntrials(this, Ntrials)
            if isa(Ntrials, 'double')
                this.Ntrials = Ntrials;
            end
        end

        function this = set.SchenleyPlace(this, SchenleyPlace)
            if isa(SchenleyPlace, 'double')
                this.SchenleyPlace = SchenleyPlace;
            end
        end

        function this = set.PerceptualTasks(this, PerceptualTasks)
            if isa(PerceptualTasks, 'double')
                this.PerceptualTasks = PerceptualTasks;
            end
        end

        function this = set.datlog(this, datlog)
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
            %loadobj  Object loading method for backward compatibility
            %
            %   this = loadobj(this) validates and sorts conditions when
            %   loading saved experimentMetaData objects
            %
            %   Inputs:
            %       this - experimentMetaData object being loaded
            %
            %   Outputs:
            %       this - validated and sorted experimentMetaData object
            %
            %   Note: This function was created to retroactively validate
            %         trials every time this is loaded
            %
            %   See also: saveobj, validateTrialsInCondition,
            %             sortConditions

            conditionOrder = this.validateTrialsInCondition();
            this = this.sortConditions();
        end
    end

end

