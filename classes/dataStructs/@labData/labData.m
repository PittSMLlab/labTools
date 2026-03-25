classdef labData
    % labData  Contains data collected in the lab, including
    %   kinematics, kinetics, and EMG signals.
    %
    % Toolbox Dependencies:
    %   None
    %
    % labData properties:
    %   metaData          - labMetaData object
    %   markerData        - orientedLabTS with kinematic data
    %   EMGData           - labTS with EMG recordings
    %   EEGData           - labTS with EEG recordings
    %   GRFData           - orientedLabTS with kinetic data
    %   accData           - orientedLabTS with acceleration data
    %   beltSpeedSetData  - labTS with treadmill speed commands
    %   beltSpeedReadData - labTS with speed read from treadmill
    %   footSwitchData    - labTS with foot switch data
    %   HreflexPin        - labTS with H-reflex sync signal
    %
    % labData methods:
    %   labData                   - constructor
    %   getMarkerData             - accessor for marker data
    %   getMarkerList             - list of available marker labels
    %   getEMGData                - accessor for EMG data
    %   getEMGList                - list of available EMG labels
    %   getEEGData                - accessor for EEG data
    %   getEEGList                - list of available EEG labels
    %   getGRFList                - list of available force labels
    %   getForce                  - accessor for forces from GRFData
    %   getMoment                 - accessor for moments from GRFData
    %   getBeltSpeed              - accessor for beltSpeedReadData
    %   computeCOP                - computes center of pressure
    %   computeCOM                - computes center of mass
    %   computeCOPAlt             - alternative COP computation
    %   computeTorques            - computes joint torques
    %   estimateSubjectBodyWeight - estimates subject weight from GRF
    %   process                   - processes raw data for events and
    %                               adaptation parameters
    %   recomputeEvents           - recalculates gait events
    %   checkMarkerDataHealth     - diagnoses marker data issues
    %   split                     - splits data into time segments
    %   alignAllTS (unimplemented)- aligns all time series data
    %
    % See also: labMetaData, orientedLabTimeSeries, labTimeSeries

    %% Properties
    properties % (SetAccess = private)
        metaData          = [] % labMetaData object
        markerData        = [] % orientedLabTS with kinematic data
        EMGData           = [] % labTS with EMG recordings
        EEGData           = [] % labTS with EEG recordings
        GRFData           = [] % orientedLabTS with kinetic data
        accData           = [] % orientedLabTS with acceleration data
        beltSpeedSetData  = [] % labTS with treadmill speed commands
        beltSpeedReadData = [] % labTS with speed read from treadmill
        footSwitchData    = [] % labTS with foot switch data
        HreflexPin        = [] % labTS with H-reflex sync signal
    end

    %% Constructor
    methods
        function this = labData(metaData, markerData, EMGData, ...
                GRFData, beltSpeedSetData, beltSpeedReadData, ...
                accData, EEGData, footSwitches, HreflexPin)
            % labData  Constructor for labData class.
            %
            %   All input arguments except metaData are optional
            %   and validated for proper type.
            %
            %   Inputs:
            %     metaData          - labMetaData object
            %     markerData        - (optional) orientedLabTimeSeries
            %                        with kinematic marker data
            %     EMGData           - (optional) labTimeSeries with
            %                        EMG recordings
            %     GRFData           - (optional) orientedLabTimeSeries
            %                        with ground reaction force data
            %     beltSpeedSetData  - (optional) labTimeSeries with
            %                        treadmill speed commands
            %     beltSpeedReadData - (optional) labTimeSeries with
            %                        treadmill speed readings
            %     accData           - (optional) orientedLabTimeSeries
            %                        with acceleration data
            %     EEGData           - (optional) labTimeSeries with
            %                        EEG recordings
            %     footSwitches      - (optional) labTimeSeries with
            %                        foot switch data
            %     HreflexPin        - (optional) labTimeSeries with
            %                        H-reflex sync signal
            %
            %   Outputs:
            %     this - labData object
            %
            %   See also: labMetaData, orientedLabTimeSeries, labTimeSeries

            arguments
                metaData
                markerData        = []
                EMGData           = []
                GRFData           = []
                beltSpeedSetData  = []
                beltSpeedReadData = []
                accData           = []
                EEGData           = []
                footSwitches      = []
                HreflexPin        = []
            end

            % if nargin < 1 || isempty(metaData)
            %     % should be mandatory and fail instead of empty metaData
            %     this.metaData = labMetaData();
            % end
            % commented because trialMetaData and experimentMetaData are
            % no longer labMetaData objects
            % if isa(metaData, 'trialMetaData')
            this.metaData = metaData;
            % else
            %     ME = MException('labData:Constructor', ...
            %         ['First argument (metaData) should be a ' ...
            %         'labMetaData object.']);
            %     throw(ME);
            % end

            if ~isempty(markerData)
                if isa(markerData, 'orientedLabTimeSeries')
                    % Needs to be empty or have labels {'Lxxx*', 'Rxxx*'},
                    % where 'xxx' is 2- or 3-letter abbreviation from list:
                    % {'ANK','TOE','HEE','KNE','TIB','THI','PEL','HIP', ...
                    % 'SHO','ELB','WRI'} or {'HEA*'}
                    this.markerData = markerData;
                else
                    ME = MException('labData:Constructor', ...
                        ['Second argument (markerData) should ' ...
                        'be an orientedLabTimeSeries object.']);
                    throw(ME);
                end
            end

            if ~isempty(EMGData)
                if isa(EMGData, 'labTimeSeries')
                    % Needs to be empty or have labels {'Lxxx', 'Rxxx'},
                    % where 'xxx' is 2- or 3-letter abbreviation from list:
                    % {'TA','PER','SOL','MG','BF','RF','VM','TFL','GLU'}
                    this.EMGData = EMGData;
                else
                    ME = MException('labData:Constructor', ...
                        ['Third argument (EMGData) should be ' ...
                        'a labTimeSeries object.']);
                    throw(ME);
                end
            end

            if ~isempty(GRFData)
                if isa(GRFData, 'orientedLabTimeSeries')
                    % Needs to be empty or have labels {'F*L','F*R', ...
                    % 'M*R','M*L'}, where '*' is either 'x', 'y' or 'z'
                    this.GRFData = GRFData;
                else
                    ME = MException('labData:Constructor', ...
                        ['Fourth argument (GRFData) should be ' ...
                        'an orientedLabTimeSeries object.']);
                    throw(ME);
                end
            end

            if ~isempty(beltSpeedSetData)
                if isa(beltSpeedSetData, 'labTimeSeries')
                    % Empty or labels 'L' and 'R'
                    this.beltSpeedSetData = beltSpeedSetData;
                else
                    ME = MException('labData:Constructor', ...
                        ['Fifth argument (beltSpeedSetData) ' ...
                        'should be a labTimeSeries object.']);
                    throw(ME);
                end
            end

            if ~isempty(beltSpeedReadData)
                if isa(beltSpeedReadData, 'labTimeSeries')
                    % Empty or labels 'L' and 'R'
                    this.beltSpeedReadData = beltSpeedReadData;
                else
                    ME = MException('labData:Constructor', ...
                        ['Sixth argument (beltSpeedReadData) ' ...
                        'should be a labTimeSeries object.']);
                    throw(ME);
                end
            end

            if ~isempty(accData)
                if isa(accData, 'orientedLabTimeSeries')
                    this.accData = accData;
                else
                    ME = MException('labData:Constructor', ...
                        ['Seventh argument (accData) should be ' ...
                        'an orientedLabTimeSeries object.']);
                    throw(ME);
                end
            end

            if ~isempty(EEGData)
                if isa(EEGData, 'labTimeSeries')
                    % Needs to be empty or have labels in the international
                    % 10-20 system
                    this.EEGData = EEGData;
                else
                    ME = MException('labData:Constructor', ...
                        ['Eighth argument (EEGData) should be ' ...
                        'a labTimeSeries object.']);
                    throw(ME);
                end
            end

            if ~isempty(footSwitches)
                if isa(footSwitches, 'labTimeSeries')
                    % Empty or labels 'L' and 'R'
                    this.footSwitchData = footSwitches;
                else
                    ME = MException('labData:Constructor', ...
                        ['Ninth argument (footSwitches) should ' ...
                        'be a labTimeSeries object.']);
                    throw(ME);
                end
            end

            if ~isempty(HreflexPin)
                if isa(HreflexPin, 'labTimeSeries')
                    % Empty or labels 'L' and 'R'
                    this.HreflexPin = HreflexPin;
                else
                    ME = MException('labData:Constructor', ...
                        ['Tenth argument (HreflexPin) should ' ...
                        'be a labTimeSeries object.']);
                    throw(ME);
                end
            end
            % ---------------
            % Check that all data is from the same time interval: TODO!
            % ---------------
        end
    end

    %% Data Access Methods
    methods
        % Other I/O:
        % function partialMarkerData = getMarkerData(this, markerName)
        %     % returns marker data for input markername
        %     partialMarkerData = this.getPartialData( ...
        %         'markerData', markerName);
        % end

        % function list = getMarkerList(this)
        %     % returns list of available marker names
        %     list = this.getLabelList('markerData');
        % end

        % function partialEMGData = getEMGData(this, muscleName)
        %     partialEMGData = this.getPartialData('EMGData', muscleName);
        % end

        % function list = getEMGList(this)
        %     list = this.getLabelList('EMGData');
        % end

        % function partialEEGData = getEEGData(this, positionName)
        %     % Standard 10-20 nomenclature
        %     partialEEGData = this.getPartialData( ...
        %         'EEGData', positionName);
        % end

        % function list = getEEGList(this)
        %     list = this.getLabelList('EEGData');
        % end

        % function partialGRFData = getGRFData(this, label)
        %     partialGRFData = this.getPartialData('GRFData', label);
        % end

        % function list = getGRFList(this)
        %     list = this.getLabelList('GRFData');
        % end

        % function specificForce = getForce(this, side, axis)
        %     % Labels in GRF data: 'FxL', 'FxR', 'FyL', etc.
        %     specificForce = this.getGRFData([side 'F' axis]);
        % end

        % function specificMoment = getMoment(this, side, axis)
        %     specificMoment = this.getGRFData([side 'M' axis]);
        % end

        % function beltSp = getBeltSpeed(this, side)
        %     beltSp = this.getPartialData('beltSpeedReadData', side);
        % end
    end

    %% Kinetic Computation Methods
    methods
        COPData = computeCOP(this)

        COMData = computeCOM(this)

        [COPData, COPL, COPR] = computeCOPAlt(this, noFilterFlag)

        [momentData, COP, COM] = computeTorques(this, subjectWeight)

        bodyWeight = estimateSubjectBodyWeight(this)
    end

    %% Data Processing Methods
    methods
        processedData = process(this, subData, eventClass)

        newThis = recomputeEvents(this)

        checkMarkerDataHealth(this)
    end

    %% Data Transformation Methods
    methods
        newThis = split(this, t0, t1, newClass)

        newThis = alignAllTS(this, alignmentVector)
    end

    %% Protected Methods
    methods (Access = protected)
        partialData = getPartialData(this, fieldName, labels)

        list = getLabelList(this, fieldName)

        [COP, F, M] = computeHemiCOP(this, side, noFilterFlag)
    end

    %% Static Methods
    methods (Static)
        COP = mergeHemiCOPs(COPL, COPR, FL, FR, noFilterFlag)
    end

end

