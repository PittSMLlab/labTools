classdef strideMetaData < derivedMetaData
    %strideMetaData  Metadata for individual stride data
    %
    %   strideMetaData extends derivedMetaData to represent metadata
    %   for individual stride segments extracted from a parent trial.
    %   It maintains a reference to the parent trial's metadata and
    %   inherits all properties from it.
    %
    %strideMetaData properties:
    %   (inherits all properties from derivedMetaData and
    %   trialMetaData)
    %
    %strideMetaData methods:
    %   strideMetaData - constructor for stride metadata
    %
    %See also: derivedMetaData, trialMetaData, strideData

    %% Properties
    properties (SetAccess = private)
        % initialEvent
        % type? --> OG vs. TM
    end

    %% Constructor
    methods
        function this = strideMetaData(ID, date, experimenter, desc, ...
                obs, refLeg, parentMeta)
            %strideMetaData  Constructor for strideMetaData class
            %
            %   this = strideMetaData(ID, date, experimenter, desc, obs,
            %   refLeg, parentMeta) creates a stride metadata object with
            %   specified parameters, inheriting properties from parent
            %   metadata
            %
            %   Inputs:
            %       ID - identifier string for the stride
            %       date - date of stride extraction
            %       experimenter - name of experimenter
            %       desc - description of the stride (e.g., stride number)
            %       obs - observations about the stride
            %       refLeg - reference leg, 'L' or 'R'
            %       parentMeta - parent trial's metadata object
            %
            %   Outputs:
            %       this - strideMetaData object
            %
            %   See also: derivedMetaData, trialMetaData, strideData

            this@derivedMetaData(ID, date, experimenter, desc, obs, ...
                refLeg, parentMeta);
        end
    end

end

