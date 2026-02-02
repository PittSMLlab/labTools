classdef rawTrialData < rawLabData
    %rawTrialData  Raw data container for individual trial data
    %
    %   rawTrialData extends rawLabData to enforce that the metadata is
    %   of trialMetaData type rather than the more general labMetaData
    %   type. This ensures proper trial-specific metadata is associated
    %   with the data.
    %
    %rawTrialData properties:
    %   (inherits all properties from rawLabData and labData)
    %
    %rawTrialData methods:
    %   rawTrialData - constructor for raw trial data
    %
    %See also: rawLabData, labData, trialMetaData, processedTrialData

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

