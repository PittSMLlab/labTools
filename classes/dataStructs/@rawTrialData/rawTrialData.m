classdef rawTrialData < rawLabData
    %UNTITLED Summary of this class goes here
    %Almost dummy class: implements rawLabData as is, just checking that
    %metaData is of trialMetaData type.
    
    properties
        
    end
    
    methods
        %Constructor 
        function this=rawTrialData(metaData,markerData,EMGData,GRFData,beltSpeedSetData,beltSpeedReadData,accData,EEGData,footSwitches)
            if ~isa(metaData,'trialMetaData') && ~isa(metaData,'derivedMetaData') && ~isempty(metaData)
                ME=MException('rawTrialData:Constructor','First argument is not a trialMetaData object.');
                throw(ME);
            end
            this@rawLabData(metaData,markerData,EMGData,GRFData,beltSpeedSetData,beltSpeedReadData,accData,EEGData,footSwitches);
        end
    end
    
end

