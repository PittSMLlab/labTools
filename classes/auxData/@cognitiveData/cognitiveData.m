classdef cognitiveData
    %cognitiveData  Stores information about cognitive tests performed
    %by study participants
    %
    %   cognitiveData contains results from cognitive assessments
    %   administered to study participants, including test names and
    %   scores.
    %
    %cognitiveData properties:
    %   labels - cell array of cognitive test names
    %   scores - matrix of test scores (subjects x tests)
    %
    %cognitiveData methods:
    %   cognitiveData - constructor for cognitive data
    %   getScore - retrieves scores for specified test(s)
    %   isaLabel - checks if label(s) exist in dataset
    %
    %See also: subjectData

    %% Properties
    properties
        labels = {''};
        scores = [];
    end

    methods
        %constructor
        function this=cognitiveData(labels,scores)
            if (length(labels)==size(scores,2)) && isa(labels,'cell')
                this.labels=labels;
                this.scores=scores;
            else
                ME=MException('cognitiveData:Constructor','The size of the labels array is inconsistent with the data being provided.');
                throw(ME)
            end
        end

        %Other I/O functions:
        function [score,auxLabel]=getScore(this,label)
            if nargin<2 || isempty(label)
                label=this.labels;
            end
            if isa(label,'char')
                auxLabel={label};
            else
                auxLabel=label;
            end
            [boolFlag,labelIdx]=this.isaLabel(auxLabel);
            for i=1:length(boolFlag)
                if boolFlag(i)==0
                    warning(['Label ' auxLabel{i} ' is not a labeled value in this data set.'])
                end
            end

            score=this.scores(:,labelIdx(boolFlag==1));
            auxLabel=this.labels(labelIdx(boolFlag==1));
        end

        function [boolFlag,labelIdx]=isaLabel(this,label)
            if isa(label,'char')
                auxLabel{1}=label;
            elseif isa(label,'cell')
                auxLabel=label;
            else
                error('labTimeSeries:isaLabel','label input argument has to be a string or a cell array containing strings.')
            end
            N=length(auxLabel);
            boolFlag=false(N,1);
            labelIdx=zeros(N,1);
            for j=1:N
                aux=strcmp(auxLabel{j},this.labels);
                boolFlag(j)=any(aux);
                labelIdx(j)=find(aux);
            end
        end

    end

end

