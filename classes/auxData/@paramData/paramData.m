classdef paramData
    %paramData  Container for parameter data across trials
    %
    %   paramData stores adaptation parameters organized by label, along
    %   with trial indices and types. This class may no longer be in
    %   active use.
    %
    %paramData properties:
    %   labels - cell array of parameter names
    %   Data - matrix of parameter values (strides/samples x parameters)
    %   indsInTrial - cell array of indices indicating which data points
    %                 belong to each trial
    %   trialTypes - cell array of trial type identifiers
    %
    %paramData methods:
    %   paramData - constructor for parameter data
    %   getParameter - retrieves data for specified parameter(s)
    %   isaParameter - checks if parameter(s) exist in dataset
    %   isaLabel - checks if label(s) exist in dataset
    %   appendData - adds new parameters to dataset
    %
    %Note: This class may no longer be in use
    %
    %See also: parameterSeries, adaptationData

    %% Properties
    properties % (SetAccess = private)
        labels = {''};
        Data;
        indsInTrial = {};
        trialTypes = {};
    end

    properties (Dependent)
        % could include things here like 'learning' or 'transfer'...
    end

    %% Constructor
    methods
        function this = paramData(data, labels, inds, types)
            %paramData  Constructor for paramData class
            %
            %   this = paramData(data, labels, inds, types) creates a
            %   parameter data object with specified data, labels, trial
            %   indices, and trial types
            %
            %   Inputs:
            %       data - matrix of parameter values (samples x
            %              parameters)
            %       labels - cell array of parameter name strings
            %       inds - cell array of trial indices
            %       types - cell array of trial type identifiers
            %               (optional)
            %
            %   Outputs:
            %       this - paramData object
            %
            %   See also: appendData

            if (length(labels) == size(data, 2)) && isa(labels, 'cell')
                this.labels = labels;
                this.Data = data;
            else
                ME = MException(...
                    'paramData:ConstructorInconsistentArguments', ...
                    ['The size of the labels array is inconsistent ' ...
                    'with the data being provided.']);
                throw(ME);
            end
            if nargin > 2 && isa(inds, 'cell')
                this.indsInTrial = inds;
            else
                ME = MException('paramData:Constructor', ...
                    'Check that trial indices are entered correctly.');
                throw(ME);
            end
            if nargin > 3 && isa(types, 'cell')
                this.trialTypes = types;
            end
        end
    end

    %% Data Access Methods
    methods
        [data, auxLabel] = getParameter(this, label)

        [boolFlag, labelIdx] = isaParameter(this, label)

        [boolFlag, labelIdx] = isaLabel(this, label)
    end

    %% Data Modification Methods
    methods
        newThis = appendData(this, newData, newLabels)
    end

end

