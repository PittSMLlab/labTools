classdef rawLabData < labData
    %rawLabData  Raw data container extending labData
    %
    %   rawLabData extends labData to provide a specific class for raw,
    %   unprocessed data. Currently this class does not add functionality
    %   beyond labData, but serves as a type identifier for data that has
    %   not been processed.
    %
    %rawLabData properties:
    %   (inherits all properties from labData)
    %
    %rawLabData methods:
    %   rawLabData - constructor for raw lab data
    %
    %See also: labData, processedLabData, rawTrialData

    %% Properties
    properties (SetAccess = private)
    end

    %% Constructor
    methods

        %Constructor:
        function this=rawLabData(metaData,markerData,EMGData,GRFData,beltSpeedSetData,beltSpeedReadData,accData,EEGData,footSwitches,HreflexPin)
            this@labData(metaData,markerData,EMGData,GRFData,beltSpeedSetData,beltSpeedReadData,accData,EEGData,footSwitches,HreflexPin);
        end
    end

end

