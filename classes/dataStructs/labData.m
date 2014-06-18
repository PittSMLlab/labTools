classdef labData
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
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
    
    properties(Constant)
        build=2; %Last changed on Feb 28th, 2014 by pai
    end
    
    %%
    methods
        
        %Constructor:
        function this=labData(metaData,markerData,EMGData,GRFData,beltSpeedSetData,beltSpeedReadData,accData,EEGData,footSwitches)
            %----------------
            
            %if nargin<1 || isempty(metaData)
            %    this.metaData=labMetaData(); %I think this should be mandatory and fail instead of putting an empty metaData.
            %end
            if isa(metaData,'labMetaData')
                this.metaData=metaData;
            else
                ME=MException('labData:Constructor','First argument (metaData) should be a labMetaData object.');
                throw(ME)
            end
            if nargin<2 || isempty(markerData)
                this.markerData=[];
            elseif isa(markerData,'orientedLabTimeSeries')
                this.markerData=markerData; %Needs to be empty or have labels {'Lxxx*', 'Rxxx*'}, where 'xxx' is a 2 or 3-letter abbreviation from the list: {'ANK','TOE','HEE','KNE','TIB','THI','PEL','HIP','SHO','ELB','WRI'} or {'HEA*'}
            else
                ME=MException('labData:Constructor','Second argument (markerData) should be an orientedLabMetaData object.');
                throw(ME);
            end
            if nargin<3 || isempty(EMGData)
                this.EMGData=[];
            elseif isa(EMGData,'labTimeSeries')
                this.EMGData=EMGData; %Needs to be empty or have labels {'Lxxx', 'Rxxx'}, where 'xxx' is a 2 or 3-letter abbreviation from the list: {'TA','PER','SOL','MG','BF','RF','VM','TFL','GLU'}
            else
                ME=MException('labData:Constructor','Third argument (EMGData) should be an labMetaData object.');
                throw(ME);
            end
            if nargin<4 || isempty(GRFData)
                this.GRFData=[];
            elseif isa(GRFData,'orientedLabTimeSeries')
                this.GRFData=GRFData; %Needs to be empty or have labels {'F*L','F*R','M*R','M*L'}, where '*' is either 'x', 'y' or 'z'
            else
                ME=MException('labData:Constructor','Fourth argument (GRFData) should be an orientedLabMetaData object.');
                throw(ME);
            end
            if nargin<5 || isempty(beltSpeedSetData)
                this.beltSpeedSetData=[];
            elseif isa(beltSpeedSetData,'labTimeSeries')
                this.beltSpeedSetData=beltSpeedSetData; %Empty or labels 'L' and 'R'
            else
                ME=MException('labData:Constructor','Fifth argument (beltSpeedSetData) should be an labMetaData object.');
                throw(ME);
            end
            if nargin<6 || isempty(beltSpeedReadData)
                this.beltSpeedReadData=[];
            elseif isa(beltSpeedReadData,'labTimeSeries')
                this.beltSpeedReadData=beltSpeedReadData; %Empty or labels 'L' and 'R'
            else
                ME=MException('labData:Constructor','Sixth argument (beltSpeadReadData) should be an labMetaData object.');
                throw(ME);
            end
            if nargin<7 || isempty(accData)
                this.accData=[];
            elseif isa(accData,'orientedLabTimeSeries')
                this.accData=accData;
            else
                ME=MException('labData:Constructor','Seventh argument (accData) should be an orientedLabMetaData object.');
                throw(ME);
            end
            if nargin<8 || isempty(EEGData)
                this.EEGData=[];
            elseif isa(EEGData,'labTimeSeries')
                this.EEGData=EEGData; %Needs to be empty or have labels in the international 10-20 system.
            else
                ME=MException('labData:Constructor','Eigth argument (EEGData) should be an labMetaData object.');
                throw(ME);
            end
            if nargin<9 || isempty(footSwitches)
                this.footSwitchData=[];
            elseif isa(footSwitches,'labTimeSeries')
                this.footSwitchData=footSwitches; %Empty or labels 'L' and 'R'
            else
                ME=MException('labData:Constructor','Ninth argument (footSwitches) should be an labMetaData object.');
                throw(ME);
            end
  
            %---------------
            %Check that all data is from the same time interval: To Do!
            %---------------

            
        end
        
        
        
        %Other I/O:
        function partialMarkerData= getMarkerData(this,markerName)
            partialMarkerData=this.getPartialData('markerData',markerName);
        end
        
        function list=getMarkerList(this)
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
            beltSp=this.getPartialData(this,'beltSpeedReadData',side);
        end
        
        
        % Process data method
        function processedData=process(this)
            trialData=this;
            % 1) Extract amplitude from emg data if present
                emg=trialData.EMGData;
                if ~isempty(emg)
                f_cut=10; %Hz
                [procEMG,f_cut,BW,notchList] = extractMuscleActivityFromEMG(emg.Data,emg.sampFreq,f_cut); 
                procInfo=processingInfo(BW,f_cut,notchList);
                procEMGData=processedEMGTimeSeries(procEMG,emg.Time(1),emg.sampPeriod,emg.labels,procInfo);
                w=warning('off','labTS:resample');
                %procEMGData=procEMGData.resample(1.2/(2*f_cut)); %Resample with 20% margin to avoid aliasing
                w=warning('on','labTS:resample');
                else
                    procEMGData=[];
                end
                
            % 2) Attempt to interpolate marker data if there is missing
            % data
            markers=trialData.markerData;
            if ~isempty(markers)
                
            end
                

            % 3) Calculate events from kinematics or force if available
                if isempty(trialData.GRFData) %No force data
                    disp(['No ground reaction forces data in trial. Using marker data to compute events.'])

                    if isempty(trialData.markerData.orientation)
                        warning('Assuming default orientation of axes for marker data.');
                        orientation=orientationInfo([0,0,0],'x','y','z',1,1,1);
                    else
                        orientation=trialData.markerData.orientation;
                    end
                    LtoePos=trialData.getMarkerData({['LTOE' orientation.foreaftAxis],['LTOE' orientation.updownAxis],['LTOE' orientation.sideAxis]});
                    LtoePos=[orientation.foreaftSign* LtoePos(:,1),orientation.sideSign*LtoePos(:,2),orientation.updownSign*LtoePos(:,3)];
                    RtoePos=trialData.getMarkerData({['RTOE' orientation.foreaftAxis],['RTOE' orientation.updownAxis],['RTOE' orientation.sideAxis]});
                    RtoePos=[orientation.foreaftSign* RtoePos(:,1),orientation.sideSign*RtoePos(:,2),orientation.updownSign*RtoePos(:,3)];
                    
                    
                        LanklePos=trialData.getMarkerData({['LANK' orientation.foreaftAxis],['LANK' orientation.updownAxis],['LANK' orientation.sideAxis]});
                        LanklePos=[orientation.foreaftSign* LanklePos(:,1),orientation.sideSign*LanklePos(:,2),orientation.updownSign*LanklePos(:,3)];
                        RanklePos=trialData.getMarkerData({['RANK' orientation.foreaftAxis],['RANK' orientation.updownAxis],['RANK' orientation.sideAxis]});
                        RanklePos=[orientation.foreaftSign* RanklePos(:,1),orientation.sideSign*RanklePos(:,2),orientation.updownSign*RanklePos(:,3)];

                    if trialData.markerData.isaLabel('LHEEx')
                        LheelPos=trialData.getMarkerData({['LHEE' orientation.foreaftAxis],['LHEE' orientation.updownAxis],['LHEE' orientation.sideAxis]});
                        LheelPos=[orientation.foreaftSign* LheelPos(:,1),orientation.sideSign*LheelPos(:,2),orientation.updownSign*LheelPos(:,3)];
                        RheelPos=trialData.getMarkerData({['RHEE' orientation.foreaftAxis],['RHEE' orientation.updownAxis],['RHEE' orientation.sideAxis]});
                        RheelPos=[orientation.foreaftSign* RheelPos(:,1),orientation.sideSign*RheelPos(:,2),orientation.updownSign*RheelPos(:,3)];
                    else
                        disp('No heel markers. Using ankle markers instead to compute events.')
                        LheelPos=LanklePos;
                        RheelPos=RanklePos;
                    end
                    fs_kin=trialData.markerData.sampFreq;

                    [LHSevent,RHSevent,LTOevent,RTOevent] = getEventsFromToeAndHeel(LtoePos,LheelPos,RtoePos,RheelPos,fs_kin); %EVENTS from a mix of kinematics;
                    t0=trialData.markerData.Time(1);
                    Ts=trialData.markerData.sampPeriod;
                else %Calculate from GRFData
                    upAxis=trialData.GRFData.orientation.updownAxis;
                    upSign=trialData.GRFData.orientation.updownSign;
                    FzL=upSign*trialData.getForce('L',upAxis);
                    FzR=upSign*trialData.getForce('R',upAxis);
                    [LHSevent,RHSevent,LTOevent,RTOevent] = getEventsFromForces(FzL,FzR,trialData.GRFData.sampFreq);
                    t0=trialData.GRFData.Time(1);
                    Ts=trialData.GRFData.sampPeriod;
                end
                events=labTimeSeries([LHSevent,RHSevent,LTOevent,RTOevent],t0,Ts,{'LHS','RHS','LTO','RTO'});

                % 4) If 'beltSpeedReadData' is empty, try to generate it
                % from foot markers, if existent
                if isempty(trialData.beltSpeedReadData) && ~isempty(trialData.markerData)
                    beltSpeedReadData=labTimeSeries(NaN(size(events.Data,1),2),events.Time(1),events.sampPeriod,{'L','R'});
                    LHS=events.getDataAsVector('LHS');
                    LTO=events.getDataAsVector('LTO');
                    RHS=events.getDataAsVector('RHS');
                    RTO=events.getDataAsVector('RTO');
                    LHEEspeed=[0;trialData.markerData.sampFreq * diff(trialData.markerData.getDataAsVector(['LHEE' trialData.markerData.orientation.foreaftAxis]))];
                    RHEEspeed=[0;trialData.markerData.sampFreq * diff(trialData.markerData.getDataAsVector(['RHEE' trialData.markerData.orientation.foreaftAxis]))];
                    speed=labTimeSeries([LHEEspeed,RHEEspeed],trialData.markerData.Time(1),trialData.markerData.sampPeriod,{'L','R'});
                    idxLHS=find(LHS);
                    for i=1:length(idxLHS)
                        idxNextLTO=find(LTO & events.Time>events.Time(idxLHS(i)),1);
                        if ~isempty(idxNextLTO)
                            beltSpeedReadData.Data(idxLHS(i):idxNextLTO,1)=median(speed.split(events.Time(idxLHS(i)),events.Time(idxNextLTO)).getDataAsVector('L'));
                        end
                    end
                    idxRHS=find(RHS);
                    for i=1:length(idxRHS)
                        idxNextRTO=find(RTO & events.Time>events.Time(idxRHS(i)),1);
                        if ~isempty(idxNextRTO)
                            beltSpeedReadData.Data(idxRHS(i):idxNextRTO,2)=median(speed.split(events.Time(idxRHS(i)),events.Time(idxNextRTO)).getDataAsVector('R'));
                        end
                    end
                end
                
            % 5) Generate processedTrial object    
                processedData=processedTrialData(trialData.metaData,trialData.markerData,trialData.EMGData,trialData.GRFData,trialData.beltSpeedSetData,trialData.beltSpeedReadData,trialData.accData,trialData.EEGData,trialData.footSwitchData,events,procEMGData);
        end
        
        function newThis=split(this,t0,t1,newClass) %Returns an object of the same type, unless newClass is specified (it needs to be a subclass)
           newThis=[]; %Just to avoid Matlab saying this is not defined
           cname=class(this);
           if nargin<4
               metaData=derivedMetaData(labDate.genIDFromClock,labDate.getCurrent,'labData.split','partialInterval',['Splice of ' this.metaData.description],'Auto-generated',this.metaData);
                eval(['newThis=' cname '(metaData);']); %Call empty constructor of same class
           else
               metaData=strideMetaData(labDate.genIDFromClock,labDate.getCurrent,'labData.split','partialInterval',['Splice of ' this.metaData.description],'Auto-generated',this.metaData); %Should I call a different metaData constructor depending on ne
                eval(['newThis=' newClass '(metaData);']); %Call empty constructor of same class
           end
           auxLst=properties(cname);
           for i=1:length(auxLst)
               eval(['oldVal=this.' auxLst{i} ';']) %Should try to do this only if the property is not dependent, otherwise, I'm computing things I don't need
               if isa(oldVal,'labTimeSeries')
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

    end
    
    %% Protected methods:
    methods (Access=protected)
        
       function partialData=getPartialData(this,fieldName,labels)
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

