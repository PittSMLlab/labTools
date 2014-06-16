classdef labMetaData
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        date=labDate.default; %labDate object
        experimenter='';
        description=''; %To be used as label or similar
        observations='';
        ID;
        refLeg='';
    end
        
    methods
        function this=labMetaData(ID,date,experimenter,desc,obs,refLeg)
            if nargin>1 && isa(date,'labDate');
                this.date=date;
            end
            if nargin>2 && isa(experimenter,'char');
                this.experimenter=experimenter;
            end            
            if nargin>3 && isa(desc,'char')
                this.description=desc;
            end
            if nargin>4 && isa(obs,'char')
                this.observations=obs;
            end
            if nargin>5 && (isa(refLeg,'char')) %Must be either 'L' or 'R'
                if strcmpi(refLeg,'R') || strcmpi(refLeg,'L')
                    this.refLeg=refLeg; 
                else
                    ME = MException('experimentMetaData:Constructor','refLeg must be either ''L'' or ''R''.');
                    throw(ME);
                end                
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

