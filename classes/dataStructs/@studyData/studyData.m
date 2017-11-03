classdef studyData %< dynamicprops

    properties
        groupData
    end
    properties(Dependent)
       groupNames 
    end
    
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
        
        function outputArg = get.groupNames(this)
            for i=1:length(this.groupData)
                outputArg{i} = this.groupData{i}.groupID;
            end
        end
        
        function out = getCommonConditions(this)
            out = []; %Doxy
        end
        
        function out = getCommonParameters(this)
            out = []; %Doxy
        end
        
        function out = getEpochData(this,epochs)
            out = []; %Doxy
        end
        
        function out = barPlot(this,epochs)
           out = []; %Doxy 
        end
        
        function out = anova(this,epochs,contrasts)
            out = []; %Doxy
        end
    end
    
    methods(Static)
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

