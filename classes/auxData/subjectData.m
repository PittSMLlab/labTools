classdef subjectData
    %UNTITLED3 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess=private)
        dateOfBirth='';
        sex='';
        dominantLeg='';
        dominantArm='';
        height=[]; %meters
        weight=[]; %kgs
        age=[]; %in months, at time of experiment
        ID=[]; %experimental ID assigned
    end
    
    methods
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

