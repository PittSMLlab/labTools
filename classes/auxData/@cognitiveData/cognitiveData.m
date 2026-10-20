classdef cognitiveData
    %COGNITIVEDATA Results of cognitive tests for study participants.
    %
    %   cognitiveData contains the names and scores of cognitive assessments
    % administered to study participants.
    %
    % cognitiveData properties:
    %   labels - cell array of cognitive test names
    %   scores - matrix of test scores (subjects x tests)
    %
    % cognitiveData methods:
    %   cognitiveData - constructor for cognitive data
    %   getScore      - retrieves scores for specified test(s)
    %   isaLabel      - checks if label(s) exist in dataset
    %
    % Toolbox Dependencies: None
    %
    % See also SUBJECTDATA.

    %% Properties
    properties
        labels = {''};
        scores = [];
    end

    %% Constructor
    methods
        function this = cognitiveData(labels, scores)
            %COGNITIVEDATA Constructor for cognitiveData class.
            %
            %   this = cognitiveData(labels, scores) creates a cognitive
            % data object with specified test labels and scores
            %
            % Inputs:
            %   labels - cell array of test name strings
            %   scores - matrix of scores (subjects x tests), where number
            %            of columns matches length of labels
            %
            % Outputs:
            %   this - cognitiveData object
            %
            % Toolbox Dependencies: None
            %
            % See also SUBJECTDATA.

            if (length(labels) == size(scores, 2)) && isa(labels, 'cell')
                this.labels = labels;
                this.scores = scores;
            else
                ME = MException('cognitiveData:Constructor', ...
                    ['The size of the labels array is inconsistent ' ...
                    'with the data being provided.']);
                throw(ME);
            end
        end
    end

    %% Data Access Methods
    methods
        [score, auxLabel] = getScore(this, label)

        [boolFlag, labelIdx] = isaLabel(this, label)
    end

end

