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
        
        function COPData=computeCOP(this)
            COPData=COPCalculator(this.GRFData);
        end
        
        function COMData=computeCOM(this)
            [COMData] = COMCalculator(this.markerData);
        end
        
        function [COPData,COPL,COPR]=computeCOPAlt(this,noFilterFlag)
            if nargin<2 || isempty(noFilterFlag)
                noFilterFlag=1;
            end
            this=this.GRFData;
            warning('orientedLabTimeSeries:computeCOP','This only works for GRFData that was obtained from the Bertec instrumented treadmill');
            [COPL,FL,~]=computeHemiCOP(this,'L',noFilterFlag);
            [COPR,FR,~]=computeHemiCOP(this,'R',noFilterFlag);
            COPL.Data(any(isinf(COPL.Data)|isnan(COPL.Data),2),:)=0;
            COPR.Data(any(isinf(COPR.Data)|isnan(COPR.Data),2),:)=0;
            newData=bsxfun(@rdivide,(bsxfun(@times,COPL.Data,FL(:,3))+bsxfun(@times,COPR.Data,FR(:,3))),FL(:,3)+FR(:,3));
            COP=orientedLabTimeSeries(newData,this.Time(1),this.sampPeriod,orientedLabTimeSeries.addLabelSuffix(['COP']),this.orientation);
            COPData=COP.medianFilter(5).substituteNaNs.lowPassFilter(30);
        end
        
        function [momentData,COP,COM]=computeTorques(this,subjectWeight)
            if nargin<2 || isempty(subjectWeight)
                warning('Subject weight not given, estimating from GRFs. This will fail miserably if z-axis force is not representative of weight.')
                subjectWeight=estimateSubjectBodyWeight(this);
            end
           [ momentData,COP,COM ] = TorqueCalculator(this, subjectWeight); 
        end
        
        function bodyWeight=estimateSubjectBodyWeight(this)
            bodyWeight=-nanmean(sum(this.GRFData.getDataAsVector({'LFz','RFz'}),2))/9.8; %Taking forces in z-axis and averaging to estimate subject weight
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
            [jointMomentsData,COPData,COMData] = this.computeTorques(subData.weight);
            
            % 7) Generate processedTrial object
            processedData=processedTrialData(this.metaData,this.markerData,filteredEMGData,this.GRFData,this.beltSpeedSetData,this.beltSpeedReadData,this.accData,this.EEGData,this.footSwitchData,events,procEMGData,angleData,COPData,COMData,jointMomentsData);
            
            % 8) Calculate adaptation parameters - to be
            % recalculated later!!
            processedData.adaptParams=calcParameters(processedData,subData,eventClass);
            
            
            
        end
        
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
                partialData=this.(fieldName);
            else
                partialData=this.(fieldName).getDataAsVector(labels);
            end
        end
        
        function list=getLabelList(this,fieldName)
            list=this.(fieldName).labels;
        end
        
        %COP calculation as used by the ALTERNATIVE version
        function [COP,F,M]=computeHemiCOP(this,side,noFilterFlag)
            this=this.GRFData;
            %Warning: this only works if GRF data is stored here
            warning('orientedLabTimeSeries:computeCOP','This only works for GRFData that was obtained from the Bertec instrumented treadmill');
            if nargin>2 && ~isempty(noFilterFlag) && noFilterFlag==1
                F=squeeze(this.getDataAsOTS([side 'F']).getOrientedData);
                M=squeeze(this.getDataAsOTS([side 'M']).getOrientedData);
            else
            F=this.getDataAsOTS([side 'F']).medianFilter(5).substituteNaNs;
            F=F.lowPassFilter(20).thresholdByChannel(-100,[side 'Fz'],1);
            F=squeeze(F.getOrientedData);
            M=this.getDataAsOTS([side 'M']).medianFilter(5).substituteNaNs;
            M=M.lowPassFilter(20);
            M=squeeze(M.getOrientedData);
            F(abs(F(:,3))<100,:)=0; %Thresholding to avoid artifacts
            end
            %I believe this should work for all forceplates in the world:
            %aux=bsxfun(@rdivide,cross(F,M),(sum(F.^2,2)));
            %t=-aux(:,3)./F(:,3);
            %COP=orientedLabTimeSeries(aux+t.*F,this.Time(1),this.sampPeriod,orientedLabTimeSeries.addLabelSuffix([side 'COP']),this.orientation);
            %This is Bertec Treadmill specific:
            aux(:,1)=(-15*F(:,1)-M(:,2))./F(:,3);
            aux(:,2)=(15*F(:,2)+M(:,1))./F(:,3);
            aux(:,3)=0;
            if strcmp(side,'R')
                aux(:,1)=aux(:,1)-977.9; %Flipping and offsetting to match reference axis of L-forceplate
            end
            aux(:,2)=-aux(:,2)+1619.25; %Flipping & adding offset to match lab's reference axis sign
            aux(:,1)=aux(:,1)+25.4; %Adding offset to lab's reference origin
            COP=orientedLabTimeSeries(aux,this.Time(1),this.sampPeriod,orientedLabTimeSeries.addLabelSuffix([side 'COP']),this.orientation);
           
        end
        
    end
    
    
end

