classdef strokeSubjectData<subjectData
    %strokeSubjectData is an extension of subjectData to support stroke
    %patients and keep data about their condition.
    
    properties (SetAccess=private)
        affectedSide='';
        strokeDate=labDate(01,'Jan',0000);
    end
    
    methods
        function this=strokeSubjectData(DOB,sex,dLeg,dArm,hgt,wgt,age,ID,affected,strokeDate)
            this@subjectData(DOB,sex,dLeg,dArm,hgt,wgt,age,ID);
            if nargin>8 || ~(strcmpi(affected,'R') || strcmpi(affected,'L'))
               this.affectedSide=affected;
            else
                error('strokeSubjectData:Constructor','Argument ''affected'' needs to be either ''R'' or ''L''.')
            end
            if nargin>9
                if isa(strokeDate,'labDate')
                this.strokeDate=strokeDate;
                else
                    error('strokeSubjectData:Constructor','Argument ''strokeDate'' needs to be of labDate class.')
                end
            end  
        end
    end
    
end
