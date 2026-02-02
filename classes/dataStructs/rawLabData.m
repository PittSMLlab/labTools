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
        function this = rawLabData(metaData, markerData, EMGData, ...
                GRFData, beltSpeedSetData, beltSpeedReadData, accData, ...
                EEGData, footSwitches, HreflexPin)
            %rawLabData  Constructor for rawLabData class
            %
            %   this = rawLabData(metaData, markerData, EMGData, GRFData,
            %   beltSpeedSetData, beltSpeedReadData, accData, EEGData,
            %   footSwitches, HreflexPin) creates a raw lab data object
            %   with specified data and metadata
            %
            %   Inputs:
            %       metaData - labMetaData or subclass object
            %       markerData - orientedLabTimeSeries with marker
            %                    trajectories
            %       EMGData - labTimeSeries with raw EMG signals
            %       GRFData - orientedLabTimeSeries with ground reaction
            %                 forces
            %       beltSpeedSetData - labTimeSeries with commanded belt
            %                          speeds
            %       beltSpeedReadData - labTimeSeries with actual belt
            %                           speeds
            %       accData - orientedLabTimeSeries with acceleration
            %                 data
            %       EEGData - labTimeSeries with EEG signals
            %       footSwitches - labTimeSeries with foot switch data
            %       HreflexPin - labTimeSeries with H-reflex stimulus
            %                    timing
            %
            %   Outputs:
            %       this - rawLabData object
            %
            %   See also: labData, processedLabData, rawTrialData

            this@labData(metaData, markerData, EMGData, GRFData, ...
                beltSpeedSetData, beltSpeedReadData, accData, EEGData, ...
                footSwitches, HreflexPin);
        end
    end

end

