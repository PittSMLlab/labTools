classdef rawLabData < labData
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    %%
    properties (SetAccess=private)

    end
    
    %%
    methods
        
        %Constructor:
        function this=rawLabData(metaData,markerData,EMGData,GRFData,beltSpeedSetData,beltSpeedReadData,accData,EEGData,footSwitches)
           this@labData(metaData,markerData,EMGData,GRFData,beltSpeedSetData,beltSpeedReadData,accData,EEGData,footSwitches);
        end
    end
    
end

