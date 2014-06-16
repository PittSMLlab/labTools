classdef processedTrialData < processedLabData
    %UNTITLED2 Summary of this class goes here
    %Almost dummy class: implements processedLabData as is, just checking that
    %metaData is of trialMetaData type.
    
    %%
    properties (SetAccess=private)

    end
        
    
    %%
    methods
        
        %Constructor:
        function this=processedTrialData(metaData,markerData,EMGData,GRFData,beltSpeedSetData,beltSpeedReadData,accData,EEGData,footSwitches,events,procEMG) %All arguments are mandatory
            
            if nargin<11 %metaData does not get replaced.
               markerData=[];
               EMGData=[];
               GRFData=[];
               beltSpeedSetData=[];
               beltSpeedReadData=[];
               accData=[];
               EEGData=[];
               footSwitches=[];
               events=[];
               procEMG=[];
            end
            if ~isa(metaData,'trialMetaData') && ~isa(metaData,'derivedMetaData') && ~isempty(metaData)
                ME=MException('processedTrialData:Constructor','First argument is not a trialMetaData object.');
                throw(ME);
            end
            this@processedLabData(metaData,markerData,EMGData,GRFData,beltSpeedSetData,beltSpeedReadData,accData,EEGData,footSwitches,events,procEMG)
        end
       
    end
    
    
end

