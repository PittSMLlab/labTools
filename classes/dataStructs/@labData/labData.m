classdef labData
    %labData  Contains data collected in the lab, including kinematics,
    %kinetics, and EMG signals.
    %
    %labData properties:
    %   metaData - labMetaData objetct
    %   markerData - orientedLabTS with kinematic data
    %   EMGData - labTS with EMG recordings
    %   EEGData - labTS with EEG recordings
    %   GRFData - orientedLabTS with kinetic data
    %   accData - orientedLabTS with acceleration data
    %   beltSpeedSetData - labTS with commands sent to treadmill
    %   beltSpeedReadData - labTS with speed read from treadmill
    %   footSwitchData - labTS with data from foot switches
    %   HreflexPin - labTS with analog signal with spike once in a while
    %                representing time when H-reflex stimulation is being
    %                delivered
    %
    %labData methods:
    %
    %   getMarkerData - accessor method for marker data
    %   getMarkerList - returns a list of marker labels
    %   getEMGData - accessor for EMG data
    %   getEMGList - returns a list of EMG labels
    %   getEEGData - accessor for EEG data
    %   getEEGList - returns list of EEG labels
    %   getGRFList - returns list of force labels
    %   getForce - accessor for forces (from GRFData)
    %   getMoment - accessor for moments (from GRFData)
    %   getBeltSpeed - accessor for beltSpeedReadData
    %   computeCOP - computes center of pressure from GRF data
    %   computeCOM - computes center of mass from marker data
    %   computeCOPAlt - alternative COP computation method
    %   computeTorques - computes joint torques from kinematics and
    %                    kinetics
    %   estimateSubjectBodyWeight - estimates subject weight from GRF data
    %   process - processes raw data to find angles, events, and adaptation
    %             parameters. Returns processedTrialData object
    %   recomputeEvents - re-calculates gait events from angle data
    %   checkMarkerDataHealth - diagnoses issues with marker data
    %   split - splits data into time-delimited segments
    %   alignAllTS - aligns all time series data (unimplemented)
    %
    %See also: labMetaData, orientedLabTimeSeries, labTimeSeries

    %% Properties
    properties % (SetAccess = private)
        metaData % labMetaData object
        markerData % orientedLabTS
        EMGData % labTS
        EEGData % labTS
        GRFData % orientedLabTS
        accData % orientedLabTS
        beltSpeedSetData % labTS, sent commands to treadmill
        beltSpeedReadData % labTS, speed read from treadmill
        footSwitchData % labTS
        HreflexPin % labTS, sync signal for H-reflex stimulus delivery
    end

    %% Constructor
    methods
        function this = labData(metaData, markerData, EMGData, GRFData, ...
                beltSpeedSetData, beltSpeedReadData, accData, EEGData, ...
                footSwitches, HreflexPin)
            %labData  Constructor for labData class
            %
            %   All arguments validated for proper type

            % ----------------

            % if nargin < 1 || isempty(metaData)
            %     this.metaData = labMetaData(); % I think this should
            %     be mandatory and fail instead of putting an empty
            %     metaData.
            % end
            % if isa(metaData, 'trialMetaData') % Had to comment this
            % on 10/7/2014, because trialMetaData and
            % experimentMetaData are no longer labMetaData objects.
            % -Pablo
            this.metaData = metaData;
            % else
            %     ME = MException('labData:Constructor', 'First
            %     argument (metaData) should be a labMetaData
            %     object.');
            %     throw(ME)
            % end
            if nargin < 2 || isempty(markerData)
                this.markerData = [];
            elseif isa(markerData, 'orientedLabTimeSeries')
                this.markerData = markerData; % Needs to be empty or
                % have labels {'Lxxx*', 'Rxxx*'}, where 'xxx' is a
                % 2 or 3-letter abbreviation from the list: {'ANK',
                % 'TOE','HEE','KNE','TIB','THI','PEL','HIP','SHO',
                % 'ELB','WRI'} or {'HEA*'}
            else
                ME = MException('labData:Constructor', ...
                    'Second argument (markerData) should be an orientedLabTimeSeries object.');
                throw(ME);
            end
            if nargin < 3 || isempty(EMGData)
                this.EMGData = [];
            elseif isa(EMGData, 'labTimeSeries')
                this.EMGData = EMGData; % Needs to be empty or have
                % labels {'Lxxx', 'Rxxx'}, where 'xxx' is a 2 or
                % 3-letter abbreviation from the list: {'TA','PER',
                % 'SOL','MG','BF','RF','VM','TFL','GLU'}
            else
                ME = MException('labData:Constructor', ...
                    'Third argument (EMGData) should be a labTimeSeries object.');
                throw(ME);
            end
            if nargin < 4 || isempty(GRFData)
                this.GRFData = [];
            elseif isa(GRFData, 'orientedLabTimeSeries')
                this.GRFData = GRFData; % Needs to be empty or have
                % labels {'F*L','F*R','M*R','M*L'}, where '*' is
                % either 'x', 'y' or 'z'
            else
                ME = MException('labData:Constructor', ...
                    'Fourth argument (GRFData) should be an orientedLabTimeSeries object.');
                throw(ME);
            end
            if nargin < 5 || isempty(beltSpeedSetData)
                this.beltSpeedSetData = [];
            elseif isa(beltSpeedSetData, 'labTimeSeries')
                % Empty or labels 'L' and 'R'
                this.beltSpeedSetData = beltSpeedSetData;
            else
                ME = MException('labData:Constructor', ...
                    'Fifth argument (beltSpeedSetData) should be a LabTimeSeries object.');
                throw(ME);
            end
            if nargin < 6 || isempty(beltSpeedReadData)
                this.beltSpeedReadData = [];
            elseif isa(beltSpeedReadData, 'labTimeSeries')
                % Empty or labels 'L' and 'R'
                this.beltSpeedReadData = beltSpeedReadData;
            else
                ME = MException('labData:Constructor', ...
                    'Sixth argument (beltSpeadReadData) should be a LabTimeSeries object.');
                throw(ME);
            end
            if nargin < 7 || isempty(accData)
                this.accData = [];
            elseif isa(accData, 'orientedLabTimeSeries')
                this.accData = accData;
            else
                ME = MException('labData:Constructor', ...
                    'Seventh argument (accData) should be an orientedLabTimeSeries object.');
                throw(ME);
            end
            if nargin < 8 || isempty(EEGData)
                this.EEGData = [];
            elseif isa(EEGData, 'labTimeSeries')
                this.EEGData = EEGData; % Needs to be empty or have
                % labels in the international 10-20 system.
            else
                ME = MException('labData:Constructor', ...
                    'Eigth argument (EEGData) should be a LabTimeSeries object.');
                throw(ME);
            end
            if nargin < 9 || isempty(footSwitches)
                this.footSwitchData = [];
            elseif isa(footSwitches, 'labTimeSeries')
                % Empty or labels 'L' and 'R'
                this.footSwitchData = footSwitches;
            else
                ME = MException('labData:Constructor', ...
                    'Ninth argument (footSwitches) should be a LabTimeSeries object.');
                throw(ME);
            end
            if nargin < 10 || isempty(HreflexPin)
                this.HreflexPin = [];
            elseif isa(HreflexPin, 'labTimeSeries')
                % Empty or labels 'L' and 'R'
                this.HreflexPin = HreflexPin;
            else
                ME = MException('labData:Constructor', ...
                    'Tenth argument (HreflexPin) should be a LabTimeSeries object.');
                throw(ME);
            end
            % ---------------
            % Check that all data is from the same time interval: To Do!
            % ---------------
        end
    end

    %% Data Access Methods
    methods
        % Other I/O:
        % function partialMarkerData = getMarkerData(this, markerName)
        %     % returns marker data for input markername
        %     partialMarkerData = this.getPartialData('markerData', markerName);
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

        % function partialEEGData = getEEGData(this, positionName) % Standard 10-20 nomenclature
        %     partialEEGData = this.getPartialData('EEGData', positionName);
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
        %     specificForce = this.getGRFData([side 'F' axis]); % Assuming that labels in GRF data are 'FxL', 'FxR', 'FyL' and so on...
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

