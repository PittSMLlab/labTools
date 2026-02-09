classdef subjectData
    %subjectData  Stores information about study participants
    %
    %   subjectData contains demographic and anthropometric information
    %   about research participants, with privacy protections for date of
    %   birth information.
    %
    %subjectData properties:
    %   dateOfBirth - labDate object (private, discouraged for privacy)
    %   sex - string, either 'male' or 'female'
    %   fastLeg - string, either 'L' or 'R'
    %   dominantLeg - string, either 'L' or 'R'
    %   dominantArm - string, either 'L' or 'R'
    %   height - height in centimeters
    %   weight - weight in kilograms
    %   age - age in years at time of experiment
    %   cognitiveScores - cognitiveData object with test results
    %   ID - string containing experimental identifier (e.g., 'OG90')
    %
    %subjectData methods:
    %   subjectData - constructor for subject data
    %
    %See also: labDate, strokeSubjectData, cognitiveData

    %% Properties
    properties (SetAccess = private)
        dateOfBirth = labDate.default;
        sex = '';
        fastLeg = '';
        dominantLeg = '';
        dominantArm = '';
        height = []; % centimeters
        weight = []; % kgs
        age = []; % in years, at time of experiment
    end

    properties % other
        cognitiveScores
        ID = []; % experimental ID assigned
    end

    %% Constructor
    methods
        function this = subjectData(DOB, sex, dLeg, dArm, hgt, wgt, ...
                age, ID, fLeg)
            %subjectData  Constructor for subjectData class
            %
            %   this = subjectData(DOB, sex, dLeg, dArm, hgt, wgt, age,
            %   ID, fLeg) creates a subject data object with specified
            %   information
            %
            %   Inputs:
            %       DOB - date of birth as labDate (optional, ignored for
            %             privacy)
            %       sex - 'male' or 'female' (optional)
            %       dLeg - dominant leg, 'L' or 'R' (optional)
            %       dArm - dominant arm, 'L' or 'R' (optional)
            %       hgt - height in cm (optional)
            %       wgt - weight in kg (optional)
            %       age - age in years at experiment time (optional)
            %       ID - subject identifier string (optional)
            %       fLeg - fast leg, 'L' or 'R' (optional)
            %
            %   Outputs:
            %       this - subjectData object
            %
            %   Note: Date of birth is ignored for privacy protection.
            %         Use age instead.
            %
            %   See also: labDate, experimentData

            if nargin > 0 && ~isempty(DOB)
                warning('subjectData:DOB', ['Date of birth was provided'...
                    ' but will be ignored for privacy.']);
            end
            if nargin > 1 && ~isempty(sex)
                this.sex = sex;
            end
            if nargin > 2 && ~isempty(dLeg)
                this.dominantLeg = dLeg;
            end
            if nargin > 3 && ~isempty(dArm)
                this.dominantArm = dArm;
            end
            if nargin > 4 && ~isempty(hgt)
                this.height = hgt;
            end
            if nargin > 5 && ~isempty(wgt)
                this.weight = wgt;
            end
            if nargin > 6 && ~isempty(age)
                this.age = age;
            end
            if nargin > 7 && ~isempty(ID)
                this.ID = ID;
            end
            if nargin > 8 && ~isempty(fLeg)
                this.fastLeg = fLeg;
            end
        end
    end

    %% Property Setters
    methods
        function this = set.cognitiveScores(this, scores)
            %set.cognitiveScores  Validates and sets cognitive test scores
            %
            %   Inputs:
            %       this - subjectData object
            %       scores - cognitiveData object or empty

            if isa(scores, 'cognitiveData') || isempty(scores)
                this.cognitiveScores = scores;
            else
                ME = MException('subjectData:Setter', ...
                    ['cognitiveScores parameter is not object of the ' ...
                    'cognitiveData class']);
                throw(ME);
            end
        end
    end

    %% Static Methods
    methods (Static)
        function this = loadobj(this)
            %loadobj  Object loading method for privacy protection
            %
            %   this = loadobj(this) warns if date of birth information
            %   is present when loading saved subjectData objects
            %
            %   Inputs:
            %       this - subjectData object being loaded
            %
            %   Outputs:
            %       this - subjectData object
            %
            %   Note: This function was created to warn about DOB being
            %         present at load time. DOB is not automatically
            %         scrubbed to prevent loss of information.
            %
            %   See also: experimentData/loadobj

            if ~isempty(this.dateOfBirth)
                warning('subjectData:DOB', ...
                    ['Subject data contains DOB for subject ' this.ID ...
                    ', which is in violation of HIPAA requirements ' ...
                    'for sharing data. Do not share until DOB has ' ...
                    'been scrubbed.']);
            end
        end
    end

end

