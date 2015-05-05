classdef rawLabData < labData
    %rawLabData  Does nothing at the moment.
    %
    %See also: labData
    
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

