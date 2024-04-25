classdef rawTrialData < rawLabData
    %Almost dummy class: implements rawLabData as is, just checking that
    %metaData is of trialMetaData type.
    %
    %See also: rawLabData
    
    properties
        
    end
    
    methods
        %Constructor 
        function this=rawTrialData(metaData,markerData,EMGData,GRFData,beltSpeedSetData,beltSpeedReadData,accData,EEGData,footSwitches,HreflexPin)
            if ~isa(metaData,'trialMetaData') && ~isa(metaData,'derivedMetaData') && ~isempty(metaData)
                ME=MException('rawTrialData:Constructor','First argument is not a trialMetaData object.');
                throw(ME);
            end
            this@rawLabData(metaData,markerData,EMGData,GRFData,beltSpeedSetData,beltSpeedReadData,accData,EEGData,footSwitches,HreflexPin);
        end
    end
    
end

