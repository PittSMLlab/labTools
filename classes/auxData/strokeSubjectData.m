classdef strokeSubjectData < subjectData
    %strokeSubjectData  Extended subject data for stroke patients
    %
    %   strokeSubjectData is an extension of subjectData to support
    %   stroke patients and maintain data about their condition,
    %   including affected side and stroke date.
    %
    %strokeSubjectData properties:
    %   affectedSide - string, either 'L' or 'R' indicating affected
    %                  side
    %   strokeDate - labDate object indicating date of stroke
    %   (inherits all properties from subjectData)
    %
    %strokeSubjectData methods:
    %   strokeSubjectData - constructor for stroke subject data
    %
    %See also: subjectData, labDate

    %% Properties
    properties (SetAccess = private)
        affectedSide = '';
        strokeDate = labDate(01, 'Jan', 0000);
    end

    %% Constructor
    methods
        function this = strokeSubjectData(DOB, sex, dLeg, dArm, hgt, ...
                wgt, age, ID, fLeg, affected, strokeDate)
            %strokeSubjectData  Constructor for strokeSubjectData class
            %
            %   this = strokeSubjectData(DOB, sex, dLeg, dArm, hgt, wgt,
            %   age, ID, fLeg, affected, strokeDate) creates a stroke
            %   subject data object with specified information
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
            %       fLeg - fast leg, 'L' or 'R' (optional, added for
            %              newer protocols where dominance or affected
            %              side do not determine fast/slow leg)
            %       affected - affected side, 'L', 'R', 'Left', or
            %                  'Right' (optional)
            %       strokeDate - labDate object for date of stroke
            %                    (optional)
            %
            %   Outputs:
            %       this - strokeSubjectData object
            %
            %   See also: subjectData, labDate

            % fLeg is added given that newer protocols do not have
            % dominance or affected side as Fast or slow leg (refLeg)
            this@subjectData( ...
                DOB, sex, dLeg, dArm, hgt, wgt, age, ID, fLeg);
            if nargin > 9
                this.affectedSide = affected;
            end
            if nargin > 10
                this.strokeDate = strokeDate;
            end
        end
    end

    %% Property Setters
    methods
        % Setters are only used by constructor since properties are private
        function this = set.affectedSide(this, affected)
            %set.affectedSide  Validates and sets affected side
            %
            %   Accepts 'L', 'R', 'Left', or 'Right' and normalizes to
            %   single character format
            %
            %   Inputs:
            %       this - strokeSubjectData object
            %       affected - affected side specification

            if strcmpi(affected, 'R') || strcmpi(affected, 'L')
                this.affectedSide = affected;
            elseif strcmpi(affected, 'Right') || ...
                    strcmpi(affected, 'Left')
                if strcmpi(affected, 'Right')
                    this.affectedSide = 'R';
                else
                    this.affectedSide = 'L';
                end
            else
                % error('strokeSubjectData:Constructor', ['Argument ' ...
                %     '''affected'' needs to be either ''R'' or ''L''.']);
            end
        end

        function this = set.strokeDate(this, strokeDate)
            %set.strokeDate  Validates and sets stroke date
            %
            %   Inputs:
            %       this - strokeSubjectData object
            %       strokeDate - labDate object

            if isa(strokeDate, 'labDate')
                this.strokeDate = strokeDate;
            else
                error('strokeSubjectData:Constructor', ['Argument ' ...
                    '''strokeDate'' needs to be of labDate class.']);
            end
        end
    end

end

