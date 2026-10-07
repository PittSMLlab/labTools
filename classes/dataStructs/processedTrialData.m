classdef processedTrialData < processedLabData
    %PROCESSEDTRIALDATA Processed data container for individual trials
    %
    %   processedTrialData extends processedLabData to enforce that the
    % metadata is of trialMetaData type rather than the more general
    % labMetaData type. This ensures proper trial-specific metadata is
    % associated with the processed data.
    %
    % processedTrialData properties:
    %   (inherits all properties from processedLabData and labData)
    %
    % processedTrialData methods:
    %   processedTrialData - constructor for processed trial data
    %
    % Toolbox Dependencies: None
    %
    % See also PROCESSEDLABDATA, LABDATA, TRIALMETADATA, RAWTRIALDATA.

    %% Properties
    properties (SetAccess = private)
    end

    %% Constructor
    methods
        function this = processedTrialData(metaData, markerData, ...
            EMGData, GRFData, beltSpeedSetData, beltSpeedReadData, ...
            accData, EEGData, footSwitches, events, procEMG, ...
            angleData, COPData, COMData, jointMomentsData, HreflexPin)
            %PROCESSEDTRIALDATA Constructor for processedTrialData class
            %
            %   this = processedTrialData(metaData, markerData, EMGData,
            % GRFData, beltSpeedSetData, beltSpeedReadData, accData,
            % EEGData, footSwitches, events, procEMG, angleData, COPData,
            % COMData, jointMomentsData, HreflexPin) creates a processed
            % trial data object with specified data and metadata
            %
            % NOTE: All arguments are mandatory
            %
            % Inputs:
            %   metaData          - trialMetaData or derivedMetaData object
            %   markerData        - orientedLabTimeSeries with marker
            %                       trajectories
            %   EMGData           - labTimeSeries with filtered EMG signals
            %   GRFData           - orientedLabTimeSeries with ground
            %                       reaction forces
            %   beltSpeedSetData  - labTimeSeries with commanded belt speeds
            %   beltSpeedReadData - labTimeSeries with actual belt speeds
            %   accData           - orientedLabTimeSeries with acceleration
            %                       data
            %   EEGData           - labTimeSeries with EEG signals
            %   footSwitches      - labTimeSeries with foot switch data
            %   events            - labTimeSeries with gait events
            %   procEMG           - processedEMGTimeSeries with processed
            %                       EMG
            %   angleData         - labTimeSeries with joint angles
            %   COPData           - orientedLabTimeSeries with center of
            %                       pressure
            %   COMData           - orientedLabTimeSeries with center of
            %                       mass
            %   jointMomentsData  - labTimeSeries with joint moments
            %   HreflexPin        - labTimeSeries with H-reflex stimulus
            %                       timing
            %
            % Outputs:
            %   this - processedTrialData object
            %
            % Toolbox Dependencies: None
            %
            % See also PROCESSEDLABDATA, TRIALMETADATA, RAWTRIALDATA.

            if nargin < 16 % metaData does not get replaced.
                markerData = [];
                EMGData = [];
                GRFData = [];
                beltSpeedSetData = [];
                beltSpeedReadData = [];
                accData = [];
                EEGData = [];
                footSwitches = [];
                events = [];
                procEMG = [];
                angleData = [];
                COPData = [];
                COMData = [];
                jointMomentsData = [];
                HreflexPin = [];
            end

            if ~isa(metaData, 'trialMetaData') && ...
                    ~isa(metaData, 'derivedMetaData') && ...
                    ~isempty(metaData)
                ME = MException('processedTrialData:Constructor', ...
                    'First argument is not a trialMetaData object.');
                throw(ME);
            end
            this@processedLabData(metaData, markerData, EMGData, ...
                GRFData, beltSpeedSetData, beltSpeedReadData, ...
                accData, ...
                EEGData, footSwitches, events, procEMG, angleData, ...
                COPData, COMData, jointMomentsData, HreflexPin);
        end

        % function calcParams(this)
        %     this.adaptParams = calcParameters(this);
        % end
    end

end

