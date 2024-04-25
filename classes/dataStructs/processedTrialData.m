classdef processedTrialData < processedLabData
    %Almost dummy class: implements processedLabData as is, just checking that
    %metaData is of trialMetaData type.
    %
    %See also: processedLabData
    
    %%
    properties (SetAccess=private)

    end
        
    
    %%
    methods
        
        %Constructor:
        function this=processedTrialData(metaData,markerData,EMGData,GRFData,beltSpeedSetData,beltSpeedReadData,accData,EEGData,footSwitches,events,procEMG,angleData,COPData,COMData,jointMomentsData,HreflexPin); %All arguments are mandatory
            
            if nargin<16 %metaData does not get replaced.
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
               angleData = [];
               COPData=[];
               COMData=[];
               jointMomentsData=[];
               HreflexPin = [];
            end
            if ~isa(metaData,'trialMetaData') && ~isa(metaData,'derivedMetaData') && ~isempty(metaData)
                ME=MException('processedTrialData:Constructor','First argument is not a trialMetaData object.');
                throw(ME);
            end
            this@processedLabData(metaData,markerData,EMGData,GRFData,beltSpeedSetData,beltSpeedReadData,accData,EEGData,footSwitches,events,procEMG,angleData,COPData,COMData,jointMomentsData,HreflexPin)
        end
        
%         function calcParams(this)
%             this.adaptParams=calcParameters(this);
%         end       
       
    end
    
    
end

