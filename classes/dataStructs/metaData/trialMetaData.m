classdef trialMetaData
%trialMetaData  Information that is specifc to an individual trial
%
%trialMetaData properties:   
%   name - short description of condition (ex. 'slow base')
%   description - long description of condition (ex. '300 strides at 0.5 m/s')
%   observations - any trial-specific observations (ex: 'L heel marker fell off')
%   refLeg - the reference leg for parameter calculations (either 'L' or 'R')
%   condition - condition number
%   rawDataFilename - path of file where vicon (.c3d) file was stored at time of creation
%   type - string describing broader conditions than given in the name (ex:'OG' for overground trials)
%
    
    properties
        name='';
        description=''; %describes condition
        observations='';        
        refLeg='';
        condition=[];
        rawDataFilename=''; %string or cell array of strings, if there are many files
        type='';
    end

    
    methods
        %Constructor
        %trialMetaData(desc,obs,refLeg,cond,filename,type)
        function this=trialMetaData(name,desc,obs,refLeg,cond,filename,type)                  
            if isa(name,'char')
                this.name=name;
            end
            if nargin>1 && isa(desc,'char')
                this.description=desc;
            end
            if nargin>2 && isa(obs,'char')
                this.observations=obs;
            end
            if nargin>3 && (isa(refLeg,'char')) %Must be either 'L' or 'R'
                if strcmpi(refLeg,'R') || strcmpi(refLeg,'L')
                    this.refLeg=refLeg; 
                else
                    ME = MException('experimentMetaData:Constructor','refLeg must be either ''L'' or ''R''.');
                    throw(ME);
                end                
            end                      
            if nargin>4 && isa(cond,'double');
                this.condition=cond;
            end
            if nargin>5 && (isa(filename,'char') || (isa(filename,'cell')&& isa(filename{1},'char')) )
                this.rawDataFilename=filename;
            end
            if nargin>6 && (isa(type,'char'))
                if strcmpi(type,'TM') || strcmpi(type,'OG')
                    this.type=type;
                else
                    ME = MException('labMetaData:Constructor','type must be either ''OG'' or ''TM''.');
                    throw(ME);
                end
            else
                this.type='TM';
                warning('Assuming trial is conducted on the treadmill')
            end
        end
        
    end
    
end