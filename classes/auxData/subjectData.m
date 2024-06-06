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
        dateOfBirth=labDate.default;
        sex='';
        fastLeg='';
        dominantLeg='';
        dominantArm='';
        height=[]; %centimeters
        weight=[]; %kgs
        age=[]; %in years, at time of experiment     
    end
    
    properties %other
        cognitiveScores
        ID=[]; %experimental ID assigned
    end
    
    methods
        %constructor
        function this=subjectData(DOB,sex,dLeg,dArm,hgt,wgt,age,ID,fLeg)
            if nargin>0 && ~isempty(DOB)
                warning('subjectData:DOB','Date of birth was provided but will be ignored for privacy.')
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
            if nargin>8 && ~isempty(fLeg)
                this.fastLeg=fLeg;
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
    
    methods(Static)
        %% Loading
        function this=loadobj(this)
            %This function was created to warn about DOB being present at load time 
            %DOB is not automatically scrubbed to prevent loss of information
            if ~isempty(this.dateOfBirth)
                warning('subjectData:DOB',['Subject data contains DOB for subject ' this.ID ' , which is in violation of HIPAA requirements for sharing data. Do not share until DOB has been scrubbed.'])
            end
        end
    end
         
end

