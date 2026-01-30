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
        function checkMarkerDataHealth(this)
            ts=this.markerData;

            %First: diagnose missing markers
            ll=ts.getLabelPrefix;
            dd=ts.getOrientedData;
            aux=zeros(size(dd,1),size(dd,2));
            for i=1:length(ll)
                l=ll{i};
                aux(:,i)=any(isnan(dd(:,i,:)),3);
                if any(aux(i,:))
                    warning('labData:checkMarkerDataHealth',['Marker ' l ' is missing for ' num2str(sum(aux)*ts.sampPeriod) ' secs.'])
                    for j=1:3
                        dd(aux,i,j)=nanmean(dd(:,i,j)); %Filling gaps just for healthCheck purposes
                    end
                end
            end
            figure
            subplot(2,2,1) % Missing frames as % of total
            hold on
            c=sum(aux,1)/size(aux,1);
            bar(c)
            set(gca,'XTick',1:numel(ll),'XTickLabel',ll,'XTickLabelRotation',90)
            ylabel('Missing frames (%)')

            subplot(2,2,2) %Distribution of gap lengths
            hold on
            h=[];
            s={};
            for i=1:length(ll)
                if c(i)>.01
                    w= [ 0; aux(:,i); 0 ]; % auxiliary vector
                    runs_ones = find(diff(w)==-1)-find(diff(w)==1);
                    h(end+1)=histogram(runs_ones,[.5:1:50],'DisplayName',ll{i});
                    s{end+1}=ll{i};
                end
            end
            legend(h,s)
            title('Distribution of gap lenghts')
            ylabel('Gap count')
            xlabel('Gap length')
            axis tight

            subplot(2,2,3)
            hold on
            d=sum(aux,2);
            histogram(d,[-.5:1:5.5],'Normalization','probability')
            title('Distribution of # missing in each frame')
            ylabel('% of frames with missing markers')
            xlabel('# missing markers')
            axis tight


            %Two: create a model to determine if outliers are present
            dd=permute(dd,[2,3,1]);
            [D,sD] = createZeroModel(dd);
            [lp,~] = determineLikelihoodFromZeroModel(dd,D,sD);
            subplot(2,2,4)
            hold on
            minLike=min(lp,[],1);
            plot(minLike)
            medLike=nanmedian(lp,1);
            plot(medLike,'r')
            legend(ll)
            ii=find(medLike<-1);
            for j=1:length(ii)
                figure
                plot3(dd(:,1,ii(j)),dd(:,2,ii(j)),dd(:,3,ii(j)),'o')
                text(dd(:,1,ii(j)),dd(:,2,ii(j)),dd(:,3,ii(j)),ll)
                hold on
                [~,zz]=min(lp(:,ii(j)));
                plot3(dd(zz,1,ii(j)),dd(zz,2,ii(j)),dd(zz,3,ii(j)),'ro')
                title(['median likeli=' num2str(medLike(ii(j))) ', frame ' num2str(ii(j))])
                pause
            end

            %             %Check for outliers:
            %             %Do a data translation:
            %             %refMarker=squeeze(mean(ts.getOrientedData({'LHIP','RHIP'}),2)); %Assuming these markers exist
            %             %Do a label-agnostic data translation:
            %             refMarker=squeeze(nanmean(dd,2));
            %             newTS=ts.translate([-refMarker(:,1:2),zeros(size(refMarker,1),1)]); %Assuming z is a known fixed axis
            %             %Not agnostic rotation:
            %             %relData=squeeze(markerData.getOrientedData('RHIP'));
            %             %Label agnostic data rotation:
            %             newTS=newTS.alignRotate([refMarker(:,2),-refMarker(:,1),zeros(size(refMarker,1),1)],[0,0,1]);
            %             medianTS=newTS.median; %Gets the median skeleton of the markers
            %
            %             %With this median skeleton, a minimization can be done to find
            %             %another label agnostic data rotation that does not depend on
            %             %estimating the translation velocity:
            %
            %             %Another attempt at label agnostic rotation (not using
            %             %velocity, but actually some info about the skeleton having
            %             %Left and Right)
            %             %l1=cellfun(@(x) x(1:end-1),ts.getLabelsThatMatch('^L'),'UniformOutput',false);
            %             %l2=cellfun(@(x) x(1:end-1),ts.getLabelsThatMatch('^R'),'UniformOutput',false);
            %             %relDataOTS=newTS.computeDifferenceOTS([],[],l1(1:3:end),l2(1:3:end));
            %             %relData=squeeze(nanmedian(relDataOTS.getOrientedData,2)); %Need to work on this
            %
            %
            %
            %             %Try to fit a 2-cluster model, to see if some marker labels are
            %             %switched at some point during experiment
            %
            %             %Assuming single mode/cluster, find outliers by getting stats
            %             %on distribution of positions/distance and velocities.
        end
    end

    %% Data Transformation Methods
    methods
        newThis = split(this, t0, t1, newClass)
        function newThis=split(this,t0,t1,newClass) %Returns an object of the same type, unless newClass is specified (it needs to be a subclass)
            %Split the data into [t0, t1).
            %Args:
            %   -t0: time in seconds (relative to trial start) of where to start the split (inclusive)
            %           when given NaN, default to start of the trial.
            %   -t1: time in seconds (relative to trial start) of where to stop (exclusive).
            %           OPTIONAL, when not provided or got NaN, default to end of the trial
            %   -newClass: string representing class/object type to reutnr.
            %           OPTIONAL, default return the same type
            newThis=[]; %Just to avoid Matlab saying this is not defined
            cname=class(this);
            if nargin<4
                %(ID,date,experimenter,desc,obs,refLeg,parentMeta)
                metaData=derivedMetaData(labDate.genIDFromClock,labDate.getCurrent,'labData.split',['Splice of ' this.metaData.description],'Auto-generated',this.metaData.refLeg,this.metaData); %HH removed 'Partial Interval' after labdata.split since 'type' propery was eliminated.
                eval(['newThis=' cname '(metaData);']); %Call empty constructor of same class
            else
                metaData=strideMetaData(labDate.genIDFromClock,labDate.getCurrent,'labData.split',['Splice of ' this.metaData.description],'Auto-generated',this.metaData.refLeg,this.metaData); %Should I call a different metaData constructor
                eval(['newThis=' newClass '(metaData);']); %Call empty constructor of same class
            end
            auxLst=properties(cname);
            for i=1:length(auxLst)
                eval(['oldVal=this.' auxLst{i} ';']) %Should try to do this only if the property is not dependent, otherwise, I'm computing things I don't need
                if isa(oldVal,'labTimeSeries') && ~isa(oldVal,'parameterSeries')
                    if nargin < 3 || isnan(t1) %no end time point provided, assume spliting from t0 to end of the trial
                        tEnd = oldVal.Time(end) + oldVal.sampPeriod;
                    else %end point provided use it
                        tEnd = t1;
                    end
                    if isnan(t0) %a flag/fake initial time provided, assuming split from beginning to to t1
                        tStart = oldVal.Time(1); %start is inclusive, no need to pad
                    else %end point provided use it.
                        tStart = t0;
                    end
                    newVal=oldVal.split(tStart,tEnd); %Calling labTS.split (or one of the subclass' implementation)
                elseif ~isa(oldVal,'labMetaData')
                    newVal=oldVal; %Not a labTS object, not splitting
                end
                try
                    eval(['newThis.' auxLst{i} '=newVal;']) %If this fails is because the property is not settable
                catch

                end
            end
            newThis.metaData=metaData;

        end

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

