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
            if nargin==1 && isa(varargin,'cell')
                V=varargin{1};
                N=numel(varargin);
            else
                V=varargin;
                N=nargin;
            end
            for i=1:N
                if isa(V{i},'groupAdaptationData')
                    this.groupData{i}=V{i};
                    %An attempt at making dot notation a thing:
                    %P=addprop(this,V{i}.groupID);
                    %P.Dependent=true;
                else
                    error('All input arguments must be groupAdaptationData objects')
                end
            end
        end
    end

    %% Dependent Property Getters
    methods
        function outputArg = get.groupNames(this)
            outputArg=cell(size(this.groupData));
            for i=1:length(this.groupData)
                outputArg{i} = this.groupData{i}.groupID;
            end
        end
    end

    %% Data Access Methods
    methods
        function out = getCommonConditions(this)
            out = []; %Doxy
        end

        function out = getCommonParameters(this)
            out = []; %Doxy
        end

        function data=getEpochData(this,epochs,labels,summaryFlag)
            %getEpochData returns data from all subjects in all groups for each epoch
            %See also: adaptationData.getEpochData

            %Manage inputs:
            if nargin<4
                summaryFlag=[]; %Respect default in adaptationData.getEpochData
            end
            if isa(labels,'char')
                labels={labels};
            end

            data=cell(size(this.groupData));
            allSameSize=true;
            N=length(this.groupData{1}.ID);
            for i=1:length(this.groupData)
                data{i}=this.groupData{i}.getEpochData(epochs,labels,summaryFlag);
                allSameSize=allSameSize && N==size(data{i},3);
            end

            if allSameSize %If all groups are same size, catting into a matrix for easier manipulation (this is probably a bad idea)
                data=reshape(cell2mat(data),length(labels),length(epochs),length(this.groupData),N); %Cats along dim 2 by default
            end
        end
    end

    %% Visualization and Analysis Methods
    methods
        function out = barPlot(this,epochs)
            out = []; %Doxy
        end

        function out = anova(this,epochs,contrasts)
            out = []; %Doxy
        end
    end

    %% Static Methods
    methods (Static)
        function this = createStudyData(groupAdaptationDataList)
            %This function creates a studyData object  from a list of
            %filenames, each containing a groupAdaptation object

            %Check: groupAdaptationDataList is a cell of strings
            %Doxy

            aux=cell(size(groupAdaptationDataList));
            for i=1:length(groupAdaptationDataList)
                aux{i}=load(groupAdaptationDataList{i});
            end
            this = studyData(aux);
        end
    end

end

