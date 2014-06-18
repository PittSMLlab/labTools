classdef trialMetaData
    %Information that is specifc to an individual trial
    %   trialMetaData(desc,obs,refLeg,cond,filename,type)
    %   desc - describes condition(ex. 'split 2:1')
    %   obs - any trial-specific observations
    %   refLeg - the reference leg for parameter calculations (slow leg)
    %   cond - condition number
    %   rawDataFilename - path of file where vicon (.c3d) file was stored
    %   at time of creation
    %   type - indicates whether the trial was overground or on the treadmill
    
    properties
        description=''; %describes condition
        observations='';        
        refLeg='';
        condition=[];
        rawDataFilename=''; %string or cell array of strings, if there are many files
        type='';
    end

    
    methods
        %Constructor
        function this=trialMetaData(desc,obs,refLeg,cond,filename,type)                  
            if isa(desc,'char')
                this.description=desc;
            end
            if nargin>1 && isa(obs,'char')
                this.observations=obs;
            end
            if nargin>2 && (isa(refLeg,'char')) %Must be either 'L' or 'R'
                if strcmpi(refLeg,'R') || strcmpi(refLeg,'L')
                    this.refLeg=refLeg; 
                else
                    ME = MException('experimentMetaData:Constructor','refLeg must be either ''L'' or ''R''.');
                    throw(ME);
                end                
            end                      
            if nargin>3 && isa(cond,'double');
                this.condition=cond;
            end
            if nargin>4 && (isa(filename,'char') || (isa(filename,'cell')&& isa(filename{1},'char')) )
                this.rawDataFilename=filename;
            end
            if nargin>5 && (isa(type,'char'))
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