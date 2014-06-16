classdef derivedMetaData < labMetaData
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess=private)
        parentMetaData
    end

    
    methods
        %Constructor
        function this=derivedMetaData(ID,date,experimenter,type,desc,obs,parentMeta)
            this@labMetaData(ID,date,experimenter,type,desc,obs);
            if isa(parentMeta,'labMetaData');
                this.parentMetaData=parentMeta;
            else
                ME=MException('derivedMetaData:Constructor','parentMetaData is not a labMetaData object.');
                throw(ME);
            end
        end
        
    end
    
end

