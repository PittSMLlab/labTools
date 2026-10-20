classdef trialMetaData
    %TRIALMETADATA Information that is specific to an individual trial.
    %
    % trialMetaData properties:
    %   name - short description of condition (e.g., 'slow base')
    %   description - long description of condition (e.g., '300
    %                 strides at 0.5 m/s')
    %   observations - any trial-specific observations (e.g., 'L heel
    %                  marker fell off')
    %   refLeg - the reference leg for parameter calculations (either
    %            'L' or 'R')
    %   condition - condition number
    %   rawDataFilename - path of file where Vicon (.c3d) file was
    %                     stored at time of creation
    %   type - string describing broader conditions than given in the
    %          name (e.g., 'OG' for overground trials, 'TM' for
    %          treadmill, 'NIM' for Nimbus, 'IN' for instrumented)
    %   schenleyLab - flag indicating if data collected in Schenley lab
    %   perceptualTasks - flag indicating presence of perceptual tasks
    %                     (2AFC)
    %   ID - trial identifier string
    %   datlog - data log structure
    %
    % trialMetaData methods:
    %   trialMetaData - constructor for trial metadata
    %
    % Toolbox Dependencies: None
    %
    % See also EXPERIMENTMETADATA, DERIVEDMETADATA.

    %% Properties
    properties
        name         = '';
        description  = ''; % describes condition
        observations = '';
        refLeg       = '';
        condition    = [];
        % string or cell array of strings, if there are many files
        rawDataFilename = '';
        type = '';
        schenleyLab = '';
        perceptualTasks = '';
        ID = '';
        datlog = '';
    end

    %% Constructor
    methods
        function this = trialMetaData(name, desc, obs, refLeg, cond, ...
            filename, type, schenleyLab, perceptualTasks, ID, datlog)
            %TRIALMETADATA Constructor for trialMetaData class.
            %
            %   this = trialMetaData(name) creates a trial metadata
            % object with the specified trial name.
            %
            %   this = trialMetaData(name, desc, obs, refLeg, cond,
            % filename, type, schenleyLab, perceptualTasks, ID, datlog)
            % creates a trial metadata object with all specified
            % parameters.
            %
            % Inputs:
            %   name            - short name/label for the trial condition
            %   desc            - (optional) detailed description of the
            %                     condition
            %   obs             - (optional) observations or notes about
            %                     the trial
            %   refLeg          - (optional) reference leg, 'L' or 'R'
            %   cond            - (optional) condition number
            %   filename        - (optional) raw data filename(s), string
            %                     or cell array
            %   type            - (optional) trial type: 'TM' (treadmill),
            %                     'OG' (overground), 'NIM' (Nimbus), or
            %                     'IN' (instrumented); default 'TM'
            %   schenleyLab     - (optional) flag for Schenley lab data;
            %                     default 0
            %   perceptualTasks - (optional) flag for perceptual tasks;
            %                     default 0
            %   ID              - (optional) trial identifier
            %   datlog          - (optional) data log structure
            %
            % Outputs:
            %   this - trialMetaData object
            %
            % NOTE: Omitted type, schenleyLab, and perceptualTasks fall
            %       back to their defaults with a warning.
            %
            % Toolbox Dependencies: None
            %
            % See also EXPERIMENTMETADATA, DERIVEDMETADATA.

            if isa(name, 'char')
                this.name = name;
            end
            if nargin > 1 && isa(desc, 'char')
                this.description = desc;
            end
            if nargin > 2 && isa(obs, 'char')
                this.observations = obs;
            end
            if nargin > 3 && (isa(refLeg, 'char'))
                % Must be either 'L' or 'R'
                if strcmpi(refLeg, 'R') || strcmpi(refLeg, 'L')
                    this.refLeg = refLeg;
                else
                    ME = MException('experimentMetaData:Constructor', ...
                        'refLeg must be either ''L'' or ''R''.');
                    throw(ME);
                end
            end
            if nargin > 4 && isa(cond, 'double')
                this.condition = cond;
            end
            if nargin > 5 && (isa(filename, 'char') || ...
                    (isa(filename, 'cell') && isa(filename{1}, 'char')))
                this.rawDataFilename = filename;
            end
            if nargin > 6 && (isa(type, 'char'))
                if strcmpi(type, 'TM') || strcmpi(type, 'OG') || ...
                        strcmpi(type, 'NIM') || strcmpi(type, 'IN')
                    this.type = type;
                else
                    ME = MException('labMetaData:Constructor', ...
                        ['type must be either ''OG'' or ''TM'', ' ...
                        '''NIM'' or ''IN''.']);
                    throw(ME);
                end
            else
                this.type = 'TM';
                warning('Assuming trial is conducted on the treadmill');
            end
            if nargin > 7 && (isa(schenleyLab, 'double'))
                this.schenleyLab = schenleyLab;
            else
                this.schenleyLab = 0;
                warning(['Assuming this data was not collected on ' ...
                    'Schenley lab. This will only affect overground ' ...
                    'trial turn removal.'])
            end
            if nargin > 8 && (isa(perceptualTasks, 'double'))
                this.perceptualTasks = perceptualTasks;
            else
                this.perceptualTasks = 0;
                warning(['Assuming this experiment does not have any ' ...
                    'perceptual tasks (2AFC tasks).']);
            end
            if nargin > 9 && (isa(ID, 'char'))
                this.ID = ID;
            else
                this.ID = '';
            end
            if nargin > 10 && (isa(datlog, 'struct'))
                this.datlog = datlog;
                % datlog is saved in datlog.datlog, this will be true
                % depends on how the datlog was loaded.
                if isfield(datlog, 'datlog')
                    this.datlog = this.datlog.datlog;
                end
            else
                this.datlog = '';
            end
        end
    end

end

