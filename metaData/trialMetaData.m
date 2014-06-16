classdef trialMetaData < labMetaData
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        condition=[];
        rawDataFilename=''; %string or cell array of strings, if there are many files
    end

    
    methods
        function this=trialMetaData(ID,date,experimenter,type,desc,obs,cond,filename)
            this@labMetaData(ID,date,experimenter,type,desc,obs);
            if nargin>6 && isa(cond,'double');
                this.condition=cond;
            end
            if nargin>7 && (isa(filename,'char') || (isa(filename,'cell')&& isa(filename{1},'char')) )
                this.rawDataFilename=filename;
            end
        end
        
    end
    
end

