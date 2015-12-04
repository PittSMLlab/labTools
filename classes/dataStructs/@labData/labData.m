classdef labData
%labData    contains data collected in the lab, including kinematics,
%           kinetics, and EMG signals.
%
%labData properties:
%   metaData - labMetaData objetct
%   markerData - orientedLabTS with kinematic data
%   EMGData - labTS with EMG recordings
%   EEGData  - labTS with EEG recordings
%   GRFData - orientedLabTS with kinetic data
%   accData - orientedLabTS with acceleration data
%   beltSpeedSetData - labTS with commands sent to treadmill
%   beltSpeedReadData - labTS with speed read from treadmill
%   footSwitchData - labTS with data from foot switches
%
%labData methods:
%   getMarkerData - accessor method for marker data
%   getMarkerList - returns a list of marker labels
%   getEMGData - accessor for EMG data
%   getEMGList - returns a list of EMG labels
%   getEEGData - accessor
%   getEEGList - reutrns list of labels   
%   getGRFList - returns list of force labels
%   getForce - accessor for forces (from GRFData)
%   getMoment - accessor for moments (from GRFData)
%   getBeltSpeed - accessor for beltSpeedReadData
%   PROCESS - processes raw data to find angles, events, and adaptation
%   parameters and to clean up EMG and marker data. Returns a
%   processedTrialData object
%   split - returns ?
%
%See also: labMetaData, orientedLabTimeSeries, labTimeSeries   
    
    
    %%
    properties %(SetAccess=private)
        metaData %labMetaData object
        markerData %orientedLabTS
        EMGData %labTS
        EEGData %labTS
        GRFData %orientedLabTS
        accData %orientedLabTS
        beltSpeedSetData %labTS, sent commands to treadmill
        beltSpeedReadData %labTS, speed read from treadmill
        footSwitchData %labTS
    end
    
    %%
    methods
        
        %Constructor:
        function this=labData(metaData,markerData,EMGData,GRFData,beltSpeedSetData,beltSpeedReadData,accData,EEGData,footSwitches)
            %----------------
            
            %if nargin<1 || isempty(metaData)
            %    this.metaData=labMetaData(); %I think this should be mandatory and fail instead of putting an empty metaData.
            %end
            %if isa(metaData,'trialMetaData') %Had to comment this on
            %10/7/2014, because trialMetaData and experimentMetaData are no
            %longer labMetaData objects. -Pablo
            this.metaData=metaData;
            %else
            %    ME=MException('labData:Constructor','First argument (metaData) should be a labMetaData object.');
            %    throw(ME)
            %end
            if nargin<2 || isempty(markerData)
                this.markerData=[];
            elseif isa(markerData,'orientedLabTimeSeries')
                this.markerData=markerData; %Needs to be empty or have labels {'Lxxx*', 'Rxxx*'}, where 'xxx' is a 2 or 3-letter abbreviation from the list: {'ANK','TOE','HEE','KNE','TIB','THI','PEL','HIP','SHO','ELB','WRI'} or {'HEA*'}
            else
                ME=MException('labData:Constructor','Second argument (markerData) should be an orientedLabTimeSeries object.');
                throw(ME);
            end
            if nargin<3 || isempty(EMGData)
                this.EMGData=[];
            elseif isa(EMGData,'labTimeSeries')
                this.EMGData=EMGData; %Needs to be empty or have labels {'Lxxx', 'Rxxx'}, where 'xxx' is a 2 or 3-letter abbreviation from the list: {'TA','PER','SOL','MG','BF','RF','VM','TFL','GLU'}
            else
                ME=MException('labData:Constructor','Third argument (EMGData) should be a labTimeSeries object.');
                throw(ME);
            end
            if nargin<4 || isempty(GRFData)
                this.GRFData=[];
            elseif isa(GRFData,'orientedLabTimeSeries')
                this.GRFData=GRFData; %Needs to be empty or have labels {'F*L','F*R','M*R','M*L'}, where '*' is either 'x', 'y' or 'z'
            else
                ME=MException('labData:Constructor','Fourth argument (GRFData) should be an orientedLabTimeSeries object.');
                throw(ME);
            end
            if nargin<5 || isempty(beltSpeedSetData)
                this.beltSpeedSetData=[];
            elseif isa(beltSpeedSetData,'labTimeSeries')
                this.beltSpeedSetData=beltSpeedSetData; %Empty or labels 'L' and 'R'
            else
                ME=MException('labData:Constructor','Fifth argument (beltSpeedSetData) should be a LabTimeSeries object.');
                throw(ME);
            end
            if nargin<6 || isempty(beltSpeedReadData)
                this.beltSpeedReadData=[];
            elseif isa(beltSpeedReadData,'labTimeSeries')
                this.beltSpeedReadData=beltSpeedReadData; %Empty or labels 'L' and 'R'
            else
                ME=MException('labData:Constructor','Sixth argument (beltSpeadReadData) should be a LabTimeSeries object.');
                throw(ME);
            end
            if nargin<7 || isempty(accData)
                this.accData=[];
            elseif isa(accData,'orientedLabTimeSeries')
                this.accData=accData;
            else
                ME=MException('labData:Constructor','Seventh argument (accData) should be an orientedLabTimeSeries object.');
                throw(ME);
            end
            if nargin<8 || isempty(EEGData)
                this.EEGData=[];
            elseif isa(EEGData,'labTimeSeries')
                this.EEGData=EEGData; %Needs to be empty or have labels in the international 10-20 system.
            else
                ME=MException('labData:Constructor','Eigth argument (EEGData) should be a LabTimeSeries object.');
                throw(ME);
            end
            if nargin<9 || isempty(footSwitches)
                this.footSwitchData=[];
            elseif isa(footSwitches,'labTimeSeries')
                this.footSwitchData=footSwitches; %Empty or labels 'L' and 'R'
            else
                ME=MException('labData:Constructor','Ninth argument (footSwitches) should be a LabTimeSeries object.');
                throw(ME);
            end
            
            %---------------
            %Check that all data is from the same time interval: To Do!
            %---------------
            
            
        end
        
        
        
        %Other I/O:
        function partialMarkerData= getMarkerData(this,markerName)
            %returns marker data for input markername
            partialMarkerData=this.getPartialData('markerData',markerName);
        end
        
        function list=getMarkerList(this)
            %returns list of available marker names
            list=this.getLabelList('markerData');
        end
        
        function partialEMGData=getEMGData(this,muscleName)
            partialEMGData=this.getPartialData('EMGData',muscleName);
        end
        
        function list=getEMGList(this)
            list=this.getLabelList('EMGData');
        end
        
        function partialEEGData=getEEGData(this,positionName) %Standard 10-20 nomenclature
            partialEEGData=this.getPartialData('EEGData',positionName);
        end
        
        function list=getEEGList(this)
            list=this.getLabelList('EEGData');
        end
        
        function partialGRFData=getGRFData(this,label)
            partialGRFData=this.getPartialData('GRFData',label);
        end
        
        function list=getGRFList(this)
            list=this.getLabelList('GRFData');
        end
        
        function specificForce=getForce(this,side,axis)
            specificForce=this.getGRFData([side 'F' axis]); %Assuming that labels in GRF data are 'FxL', 'FxR', 'FyL' and so on...
        end
        
        function specificMoment=getMoment(this,side,axis)
            specificMoment=this.getGRFData([side 'M' axis]);
        end
        
        function beltSp=getBeltSpeed(this,side)
            beltSp=this.getPartialData('beltSpeedReadData',side);
        end
        
        
        % Process data method
        function processedData=process(this,subData,eventClass)
            if nargin<3 || isempty(eventClass)
                eventClass=[];
            end
            
            
            % 1) Extract amplitude from emg data if present
            spikeRemovalFlag=0;
            [procEMGData,filteredEMGData] = processEMG(this,spikeRemovalFlag);
            
            % 2) Attempt to interpolate marker data if there is missing data
            % (make into function once we have a method to do this)
            markers=this.markerData;
            if ~isempty(markers)
                %function goes here: check marker data health
            end
            
            % 3) Calculate limb angles
            angleData = calcLimbAngles(this);
            
            % 4) Calculate events from kinematics or force if available
            events = getEvents(this,angleData);
            
            % 5) If 'beltSpeedReadData' is empty, try to generate it
            % from foot markers, if existent
            if isempty(this.beltSpeedReadData)
                this.beltSpeedReadData = getBeltSpeedsFromFootMarkers(this,events);
            end
            
            %6) Get COP, COM and joint torque data.
            [jointMomentsData,COPData,COMData] = TorqueCalculator(this, subData.weight);
            
            % 7) Generate processedTrial object
            processedData=processedTrialData(this.metaData,this.markerData,filteredEMGData,this.GRFData,this.beltSpeedSetData,this.beltSpeedReadData,this.accData,this.EEGData,this.footSwitchData,events,procEMGData,angleData,COPData,COMData,jointMomentsData);
            
            % 8) Calculate adaptation parameters - to be
            % recalculated later!!
            processedData.adaptParams=calcParameters(processedData,subData,eventClass);
            
            
            
        end
        
        function checkMarkerDataHealth(this)
            ts=this.markerData;
            %Check for missing samples (and do nothing?):
            ll=ts.getLabelPrefix;
            dd=ts.getOrientedData;
            for i=1:length(ll)
                l=ll{i};
                aux=any(isnan(dd(:,i,:)),3);
                if any(aux)
                    warning('labData:checkMarkerDataHealth',['Marker ' l ' is missing for ' num2str(sum(aux)*ts.sampPeriod) ' secs.'])
                    for j=1:3
                        dd(aux,i,j)=nanmean(dd(:,i,j)); %Filling gaps just for healthCheck purposes
                    end
                end
            end
            
            %Check for outliers:
            %Do a data translation:
            %refMarker=squeeze(mean(ts.getOrientedData({'LHIP','RHIP'}),2)); %Assuming these markers exist
            %Do a label-agnostic data translation:
            refMarker=squeeze(nanmean(dd,2));
            newTS=ts.translate([-refMarker(:,1:2),zeros(size(refMarker,1),1)]); %Assuming z is a known fixed axis
            %Not agnostic rotation:
            %relData=squeeze(markerData.getOrientedData('RHIP'));
            %Label agnostic data rotation:
            newTS=newTS.alignRotate([refMarker(:,2),-refMarker(:,1),zeros(size(refMarker,1),1)],[0,0,1]);
            medianTS=newTS.median; %Gets the median skeleton of the markers
            
            %With this median skeleton, a minimization can be done to find
            %another label agnostic data rotation that does not depend on
            %estimating the translation velocity:
            
            %Another attempt at label agnostic rotation (not using
            %velocity, but actually some info about the skeleton having
            %Left and Right)
            %l1=cellfun(@(x) x(1:end-1),ts.getLabelsThatMatch('^L'),'UniformOutput',false);
            %l2=cellfun(@(x) x(1:end-1),ts.getLabelsThatMatch('^R'),'UniformOutput',false);
            %relDataOTS=newTS.computeDifferenceOTS([],[],l1(1:3:end),l2(1:3:end));
            %relData=squeeze(nanmedian(relDataOTS.getOrientedData,2)); %Need to work on this
            
            
                      
            %Try to fit a 2-cluster model, to see if some marker labels are
            %switched at some point during experiment
            
            %Assuming single mode/cluster, find outliers by getting stats
            %on distribution of positions/distance and velocities.
        end
        
        function newThis=split(this,t0,t1,newClass) %Returns an object of the same type, unless newClass is specified (it needs to be a subclass)
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
                    newVal=oldVal.split(t0,t1); %Calling labTS.split (or one of the subclass' implementation)
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
        
        function newThis=alignAllTS(this, alignmentVector)
            error('Unimplemented')
            newThis=[];
        end
        
    end
    
    %% Protected methods:
    methods (Access=protected)
        
        function partialData=getPartialData(this,fieldName,labels)
            %returns requested data
            %
            %inputs:
            %fieldName -- looks for property of the instance (see top of
            %file for list of properties)
            %
            %labels -- 
            
            if nargin<3 || isempty(labels)
                eval(['partialData=this.' fieldName ';']);
            else
                eval(['partialData=this.' fieldName '.getDataAsVector(labels);']); %Should I return this as labTS?
            end
        end
        
        function list=getLabelList(this,fieldName)
            eval(['list = this.' fieldName '.labels;']);
        end
        
    end
    
    
end

