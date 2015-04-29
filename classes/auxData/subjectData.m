classdef subjectData
%subjectData  stores information about study participants
%   
%subjectData properties:
%   dateOfBirth - labData object
%   sex - string, either 'male' or 'female'
%   dominantLeg - string, either 'L' or 'R'
%   dominantArm - string, either 'L' or 'R'
%   height - number (in cm)
%   weight - number (in Kg)
%   age - labDate object
%   ID - string containing experimental identifier
    
    properties (SetAccess=private)
        dateOfBirth='';
        sex='';
        dominantLeg='';
        dominantArm='';
        height=[]; %centimeters
        weight=[]; %kgs
        age=[]; %in years, at time of experiment
        ID=[]; %experimental ID assigned
    end
    
    methods
        %constructor
        function this=subjectData(DOB,sex,dLeg,dArm,hgt,wgt,age,ID)
            if nargin>0 && ~isempty(DOB)
                this.dateOfBirth=DOB;
            end
            if nargin>1 && ~isempty(sex)
                this.sex=sex;
            end
            if nargin>2 && ~isempty(dLeg)
                this.dominantLeg=dLeg;
            end
            if nargin>3 && ~isempty(dArm)
                this.dominantArm=dArm;
            end
            if nargin>4 && ~isempty(hgt)
                this.height=hgt;
            end
            if nargin>5 && ~isempty(wgt)
                this.weight=wgt;
            end 
            if nargin>6 && ~isempty(age)
                this.age=age;
            end
            if nargin>7 && ~isempty(ID)
                this.ID=ID;
            end
        end
    end
    
end

