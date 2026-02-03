classdef studyData % < dynamicprops
    %studyData  Container for multiple group adaptation data sets
    %
    %   studyData organizes and manages data from multiple experimental
    %   groups, enabling cross-group comparisons and statistical analyses.
    %   Each group is represented by a groupAdaptationData object.
    %
    %studyData properties:
    %   groupData - cell array of groupAdaptationData objects
    %   groupNames - cell array of group identifier strings (dependent)
    %
    %studyData methods:
    %   studyData - constructor for study data
    %   getCommonConditions - returns conditions common to all groups
    %   getCommonParameters - returns parameters common to all groups
    %   getEpochData - extracts epoch data from all groups
    %   barPlot - creates bar plot comparing groups across epochs
    %   anova - performs ANOVA comparing groups across epochs
    %
    %studyData static methods:
    %   createStudyData - creates studyData from list of data files
    %
    %See also: groupAdaptationData, adaptationData

    %% Properties
    properties
        groupData
    end

    properties (Dependent)
        groupNames
    end

    %% Constructor
    methods
        function this = studyData(varargin)
            %studyData  Constructor for studyData class
            %
            %   this = studyData(group1, group2, ...) creates a study data
            %   object from multiple groupAdaptationData objects
            %
            %   this = studyData(groupCell) creates a study data object
            %   from a cell array of groupAdaptationData objects
            %
            %   Inputs:
            %       varargin - variable number of groupAdaptationData
            %                  objects or single cell array of
            %                  groupAdaptationData objects
            %
            %   Outputs:
            %       this - studyData object
            %
            %   See also: groupAdaptationData, createStudyData

            if nargin == 1 && isa(varargin, 'cell')
                V = varargin{1};
                N = numel(varargin);
            else
                V = varargin;
                N = nargin;
            end

            for i = 1:N
                if isa(V{i}, 'groupAdaptationData')
                    this.groupData{i} = V{i};
                    % An attempt at making dot notation a thing:
                    % P = addprop(this, V{i}.groupID);
                    % P.Dependent = true;
                else
                    error(['All input arguments must be ' ...
                        'groupAdaptationData objects']);
                end
            end
        end
    end

    %% Dependent Property Getters
    methods
        function outputArg = get.groupNames(this)
            %get.groupNames  Returns group identifier names
            %
            %   groupNames = get.groupNames(this) returns a cell array of
            %   group identifier strings
            %
            %   Inputs:
            %       this - studyData object
            %
            %   Outputs:
            %       outputArg - cell array of group ID strings

            outputArg = cell(size(this.groupData));
            for i = 1:length(this.groupData)
                outputArg{i} = this.groupData{i}.groupID;
            end
        end
    end

    %% Data Access Methods
    methods
        out = getCommonConditions(this)

        out = getCommonParameters(this)

        data = getEpochData(this, epochs, labels, summaryFlag)
    end

    %% Visualization and Analysis Methods
    methods
        out = barPlot(this, epochs)

        out = anova(this, epochs, contrasts)
    end

    %% Static Methods
    methods (Static)
        this = createStudyData(groupAdaptationDataList)
    end

end

