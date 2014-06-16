classdef strideMetaData < derivedMetaData
    %UNTITLED2 Summary of this class goes here
    % Dummy class
    
    properties (SetAccess=private)
        %initialEvent
    end
    
    methods
        %Constructor
        function this=strideMetaData(ID,date,experimenter,type,desc,obs,parentMeta)
            this@derivedMetaData(ID,date,experimenter,type,desc,obs,parentMeta);
        end
        
    end
    
end

