classdef derivedMetaData < trialMetaData
    %DERIVEDMETADATA Metadata for data derived from a parent trial.
    %
    %   derivedMetaData extends trialMetaData to represent metadata for
    % data segments or processed data derived from a parent trial. It
    % maintains a reference to the parent trial's metadata and can
    % inherit properties from it.
    %
    % derivedMetaData properties:
    %   parentMetaData - reference to the parent trial's metadata
    %                    object
    %   (inherits all properties from trialMetaData)
    %
    % derivedMetaData methods:
    %   derivedMetaData - constructor for derived metadata
    %
    % Toolbox Dependencies: None
    %
    % See also TRIALMETADATA, STRIDEMETADATA.

    %% Properties
    properties (SetAccess = private)
        parentMetaData
    end

    %% Constructor
    methods
        function this = derivedMetaData(ID, date, experimenter, desc, ...
            obs, refLeg, parentMeta, condition, rawDataFilename, ...
            type, schenleyLab, perceptualTasks, datlog, fastLeg)
            %DERIVEDMETADATA Constructor for derivedMetaData class.
            %
            %   this = derivedMetaData(ID, date, experimenter, desc, obs,
            % refLeg, parentMeta) creates a derived metadata object with
            % specified parameters and inherits the remaining properties
            % from the parent metadata.
            %
            %   this = derivedMetaData(ID, date, experimenter, desc, obs,
            % refLeg, parentMeta, condition, rawDataFilename, type,
            % schenleyLab, perceptualTasks, datlog, fastLeg) creates a
            % derived metadata object with all specified parameters.
            %
            % Inputs:
            %   ID              - identifier string for the derived data
            %   date            - date of data creation
            %   experimenter    - name of experimenter
            %   desc            - description of the derived data
            %   obs             - observations about the derived data
            %   refLeg          - reference leg, 'L' or 'R'
            %   parentMeta      - parent trial's metadata object
            %   condition       - (optional) condition number; inherited
            %                     from parent if only 7 args
            %   rawDataFilename - (optional) raw data filename(s);
            %                     inherited from parent if only 7 args
            %   type            - (optional) trial type; inherited from
            %                     parent if only 7 args
            %   schenleyLab     - (optional) Schenley lab flag; inherited
            %                     from parent if only 7 args
            %   perceptualTasks - (optional) perceptual tasks flag;
            %                     inherited from parent if only 7 args
            %   datlog          - (optional) data log structure; inherited
            %                     from parent if only 7 args
            %   fastLeg         - (optional) fast leg designation;
            %                     defaults to refLeg
            %
            % Outputs:
            %   this - derivedMetaData object
            %
            % NOTE: The superclass constructor receives parentMeta.type,
            %       not the type argument.
            %
            % Toolbox Dependencies: None
            %
            % See also TRIALMETADATA, STRIDEMETADATA.

            % parentMeta is given, but no other args are given, set
            % it to the parent
            if nargin == 7
                condition = parentMeta.condition;
                rawDataFilename = parentMeta.rawDataFilename;
                type = parentMeta.type;
                schenleyLab = parentMeta.schenleyLab;
                perceptualTasks = parentMeta.perceptualTasks;
                datlog = parentMeta.datlog;
                % fastLeg = parentMeta.fastLeg;
                % backwardCheck = parentMeta.backwardCheck;
            end
            % no condition provided & hasn't been set by parent meta.
            if ~exist('condition', 'var')
                % default to empty (the type of default to set see
                % @trialMetaData properties default)
                condition = [];
            end
            if ~exist('rawDataFilename', 'var') % no condition provided
                rawDataFilename = ""; % default to empty
            end
            if ~exist('type', 'var') % no condition provided
                type = ""; % default to empty
            end
            if ~exist('schenleyLab', 'var') % no condition provided
                schenleyLab = ""; % default to empty
            end
            if ~exist('perceptualTasks', 'var') % no condition provided
                perceptualTasks = ""; % default to empty
            end
            if ~exist('datlog', 'var') % no condition provided
                datlog = ""; % default to empty
            end
            if ~exist('fastLeg', 'var') % no condition provided
                fastLeg = refLeg; % default to refLeg
            end
            if ~exist('backwardCheck', 'var') % no condition provided
                backwardCheck = ""; % default to empty
            end
            this@trialMetaData(ID, desc, obs, refLeg, condition, ...
                rawDataFilename, parentMeta.type, schenleyLab, ...
                perceptualTasks, datlog)
            % NOTE: parentMeta is not validated as a labMetaData object
            % because trialMetaData and experimentMetaData do not extend it
            % if isa(parentMeta, 'labMetaData');
            this.parentMetaData = parentMeta;
            % else
            %     ME = MException('derivedMetaData:Constructor',
            %     'parentMetaData is not a labMetaData object.');
            %     throw(ME);
            % end
        end
    end

end

