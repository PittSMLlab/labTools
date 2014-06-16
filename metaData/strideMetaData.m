classdef strideMetaData < derivedMetaData
    %UNTITLED2 Summary of this class goes here
    % Dummy class
    
    properties (SetAccess=private)
        %initialEvent
        %type? --> OG vs TM
    end
    
    methods
        %Constructor
        function this=strideMetaData(ID,date,experimenter,desc,obs,refLeg,parentMeta)
            this@derivedMetaData(ID,date,experimenter,desc,obs,refLeg,parentMeta);
        end
        
    end
    
end

