classdef subjectData
%subjectData  stores information about study participants
%   
%subjectData properties:
%   dateOfBirth - labDate object
%   sex - string, either 'male' or 'female'
%   dominantLeg - string, either 'L' or 'R'
%   dominantArm - string, either 'L' or 'R'
%   height - double (cm)
%   weight - double (kg)
%   age - labDate object e.g. age = expDate.year - DOB.year;
%   ID - string containing experimental identifier e.g. 'OG90'
%
%See also: labDate, strokeSubjectData
    
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
    
    properties %other
        cognitiveScores
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
        
        function this=set.cognitiveScores(this,scores)
            if isa(scores,'cognitiveData') || isempty(scores)
                this.cognitiveScores=scores;
            else
                ME=MException('subjectData:Setter','cognitiveScores parameter is not object of the cognitiveData class');
                throw(ME);
            end
        end  
    end
    
         
end

