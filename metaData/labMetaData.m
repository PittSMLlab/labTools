classdef labMetaData
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        date=labDate.default; %labDate object
        experimenter='';
        type=''; %One of {'exp', 'trial', 'stride'}
        description=''; %To be used as label or similar
        observations='';
        ID;
    end
    properties(Constant)
        build=1;
    end
    
    methods
        function this=labMetaData(ID,date,experimenter,type,desc,obs)
            if nargin>1 && isa(date,'labDate');
                this.date=date;
            end
            if nargin>2 && isa(experimenter,'char');
                this.experimenter=experimenter;
            end
            if nargin>3 && isa(type,'char');
                this.type=type;
            end
            if nargin>4 && isa(desc,'char')
                this.description=desc;
            end
            if nargin>5 && isa(obs,'char')
                this.observations=obs;
            end
            if isa(ID,'char') %&& nargin>0
                this.ID=ID; %Mandatory field, needs to be string
            elseif isempty(ID) %|| nargin==0
                this.ID='';
                %disp('Warning: creating emtpy ID field.')
            else
                ME=MException('labMetaData:Constructor','ID is not a string.');
                throw(ME);
            end
        end
        
    end
    
end

