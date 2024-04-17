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
        function this=rawLabData(metaData,markerData,EMGData,GRFData,beltSpeedSetData,beltSpeedReadData,accData,EEGData,footSwitches,HreflexPin)
           this@labData(metaData,markerData,EMGData,GRFData,beltSpeedSetData,beltSpeedReadData,accData,EEGData,footSwitches,HreflexPin);
        end
    end
    
end

