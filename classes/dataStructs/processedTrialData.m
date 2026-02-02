classdef processedTrialData < processedLabData
    %processedTrialData  Processed data container for individual trials
    %
    %   processedTrialData extends processedLabData to enforce that the
    %   metadata is of trialMetaData type rather than the more general
    %   labMetaData type. This ensures proper trial-specific metadata is
    %   associated with the processed data.
    %
    %processedTrialData properties:
    %   (inherits all properties from processedLabData and labData)
    %
    %processedTrialData methods:
    %   processedTrialData - constructor for processed trial data
    %
    %See also: processedLabData, labData, trialMetaData, rawTrialData

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

