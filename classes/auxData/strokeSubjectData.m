classdef strokeSubjectData<subjectData
%strokeSubjectData is an extension of subjectData to support stroke
%patients and keep data about their condition.
%
%strokeSubjectData properies:
%   affectedSide - string, either 'L' or 'R'
%   strokeDate - labDate object
%
%see also: subjectData, labDate
    
    properties (SetAccess=private)
        affectedSide='';
        strokeDate=labDate(01,'Jan',0000);
    end
    
    methods
        %constructor
        function this=strokeSubjectData(DOB,sex,dLeg,dArm,hgt,wgt,age,ID,affected,strokeDate)
            this@subjectData(DOB,sex,dLeg,dArm,hgt,wgt,age,ID);
            if nargin>8
                this.affectedSide=affected;
            end
            if nargin>9
                this.strokeDate=strokeDate;
            end
        end
        %setters --> only used by constructor since properties are private
        function this=set.affectedSide(this,affected)
            if strcmpi(affected,'R') || strcmpi(affected,'L')
                this.affectedSide=affected;
            elseif strcmpi(affected,'Right') || strcmpi(affected,'Left')
                if strcmpi(affected,'Right')
                    this.affectedSide='R';
                else
                    this.affectedSide='L';
                end
            else
                %error('strokeSubjectData:Constructor','Argument ''affected'' needs to be either ''R'' or ''L''.')
            end
        end
        function this=set.strokeDate(this,strokeDate)
            if isa(strokeDate,'labDate')
                this.strokeDate=strokeDate;
            else
                error('strokeSubjectData:Constructor','Argument ''strokeDate'' needs to be of labDate class.')
            end
        end
    end
    
end
