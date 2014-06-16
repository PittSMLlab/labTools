classdef rawTrialData
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    %%
    properties (SetAccess=private)
        metaData %trialMetaData type
        markerData %labTS
        EMGData %labTS
        EEGData %labTS
        GRFData %labTS
        accData %labTS
        beltSpeedSetData %labTS, sent commands to treadmill
        beltSpeedReadData %labTS, speed read from treadmill
        footSwitchData %labTS
        GRFOrientationInfo; %orientationInfo
        markerOrientationInfo; %orientationInfo
    end
    
    properties(Constant)
        build=2; %Last changed on Feb 26th, 2014 by pai
    end
    
    %%
    methods
        
        %Constructor:
        function this=rawTrialData(metaData,markerData,EMGData,GRFData,beltSpeedSetData,beltSpeedReadData,accData,EEGData,GRFOrientation,markerOrientation,footSwitches)
            %----------------
            if nargin<10 || isempty(footSwitches)
                footSwitches=[];
            end
            if nargin<8 || isempty(GRFOrientation)
                GRFOrientation=[];
            end
            if nargin<9 || isempty(markerOrientation)
                markerOrientation=[];
            end
            if nargin<7 || isempty(accData)
                accData=[];
            end
            if nargin<5 || isempty(beltSpeedSetData)
                beltSpeedSetData=[];
            end
            if nargin<6 || isempty(beltSpeedReadData)
                beltSpeedReadData=[];
            end
            if nargin<4 || isempty(GRFData)
                GRFData=[];
            end
            if nargin<8 || isempty(EEGData)
                EEGData=[];
            end
            if nargin<3 || isempty(EMGData)
                EMGData=[];
            end
            if nargin<2 || isempty(markerData)
                markerData=[];
            end
            if isempty(metaData)
                metaData=[];
            end   
            %---------------
            this.metaData=metaData;
            this.GRFData=GRFData; %Needs to be empty or have labels {'F*L','F*R','M*R','M*L'}, where '*' is either 'x', 'y' or 'z'
            this.EEGData=EEGData; %Needs to be empty or have labels in the international 10-20 system.
            this.EMGData=EMGData; %Needs to be empty or have labels {'Lxxx', 'Rxxx'}, where 'xxx' is a 2 or 3-letter abbreviation from the list: {'TA','PER','SOL','MG','BF','RF','VM','TFL','GLU'}
            this.markerData=markerData; %Needs to be empty or have labels {'Lxxx*', 'Rxxx*'}, where 'xxx' is a 2 or 3-letter abbreviation from the list: {'ANK','TOE','HEE','KNE','TIB','THI','PEL','HIP','SHO','ELB','WRI'} or {'HEA*'}
            this.beltSpeedSetData=beltSpeedSetData; %Empty or labels 'L' and 'R'
            this.beltSpeedReadData=beltSpeedReadData; %Empty or labels 'L' and 'R'
            this.accData=accData; %??
            this.GRFOrientationInfo=GRFOrientation;
            this.markerOrientationInfo=markerOrientation;
            this.footSwitchData=footSwitches; %Empty or labels 'L' and 'R'
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
            specificForce=this.getGRFData(['F' axis side]); %Assuming that labels in GRF data are 'FxL', 'FxR', 'FyL' and so on... 
        end
        
        function specificMoment=getMoment(this,side,axis)
            specificMoment=this.getGRFData(['M' axis side]);
        end
        
        function beltSp=getBeltSpeed(this,side)
            beltSp=this.getPartialData(this,'beltSpeedReadData',side);
        end
        
        function cond=getTrialCondition(this)
            cond=this.metaData.condition;
        end
        
        function descrip=getTrialDescription(this)
            descrip=this.metaData.description;
        end
        
        
        % Process data method
        function processedTrial=process(this)
            trialData=this;
            % 1) Extract amplitude from emg data
                emg=trialData.EMGData;
                f_cut=10; %Hz
                [procEMG] = extractMuscleActivityFromEMG(emg.Data,emg.sampFreq,f_cut); 
                procEMGData=labTimeSeries(procEMG,emg.Time(1),emg.sampPeriod,emg.labels);
                w=warning('off','labTS:resample');
                procEMGData=procEMGData.resample(1.2/(2*f_cut)); %Resample with 20% margin to avoid aliasing
                w=warning('on','labTS:resample');

            % 2) Calculate events from kinematics or force if available
                if isempty(trialData.GRFData) %No force data
                    disp(['No ground reaction forces data in trial. Using marker data to compute events.'])

                    if isempty(trialData.markerOrientationInfo)
                        warning('Assuming default orientation of axes for marker data.');
                        orientation=orientationInfo([0,0,0],'x','y','z',1,1,1);
                    else
                        orientation=trialData.markerOrientationInfo;
                    end
                    LtoePos=trialData.getMarkerData({['LTOE' orientation.foreaftAxis],['LTOE' orientation.sideAxis],['LTOE' orientation.updownAxis]});
                    LtoePos=[orientation.foreaftSign* LtoePos(:,1),orientation.sideSign*LtoePos(:,2),orientation.updownSign*LtoePos(:,3)];
                    RtoePos=trialData.getMarkerData({['RTOE' orientation.foreaftAxis],['RTOE' orientation.sideAxis],['RTOE' orientation.updownAxis]});
                    RtoePos=[orientation.foreaftSign* RtoePos(:,1),orientation.sideSign*RtoePos(:,2),orientation.updownSign*RtoePos(:,3)];
                    
                    
                        LanklePos=trialData.getMarkerData({['LANK' orientation.foreaftAxis],['LANK' orientation.sideAxis],['LANK' orientation.updownAxis]});
                        LanklePos=[orientation.foreaftSign* LanklePos(:,1),orientation.sideSign*LanklePos(:,2),orientation.updownSign*LanklePos(:,3)];
                        RanklePos=trialData.getMarkerData({['RANK' orientation.foreaftAxis],['RANK' orientation.sideAxis],['RANK' orientation.updownAxis]});
                        RanklePos=[orientation.foreaftSign* RanklePos(:,1),orientation.sideSign*RanklePos(:,2),orientation.updownSign*RanklePos(:,3)];

                    if trialData.markerData.isaLabel('LHEEx')
                        LheelPos=trialData.getMarkerData({['LHEE' orientation.foreaftAxis],['LHEE' orientation.sideAxis],['LHEE' orientation.updownAxis]});
                        LheelPos=[orientation.foreaftSign* LheelPos(:,1),orientation.sideSign*LheelPos(:,2),orientation.updownSign*LheelPos(:,3)];
                        RheelPos=trialData.getMarkerData({['RHEE' orientation.foreaftAxis],['RHEE' orientation.sideAxis],['RHEE' orientation.updownAxis]});
                        RheelPos=[orientation.foreaftSign* RheelPos(:,1),orientation.sideSign*RheelPos(:,2),orientation.updownSign*RheelPos(:,3)];
                    else
                        disp('No heel markers. Using ankle markers instead to compute events.')
                        LheelPos=LanklePos;
                        RheelPos=RanklePos;
                    end
                    fs_kin=trialData.markerData.sampFreq;

                    [LHSevent,RHSevent,LTOevent,RTOevent] = getEventsFromToeAndHeel(LtoePos,LheelPos,RtoePos,RheelPos,fs_kin); %EVENTS from a mix of kinematics;
                    t0=trialData.markerData.Time(1);
                    fs=trialData.markerData.sampFreq;
                else %Calculate from GRFData
                    FzL=trialData.getForce('L','z');
                    FzR=trialData.getForce('R','z');
                    [LHSevent,RHSevent,LTOevent,RTOevent] = getEventsFromForces(FzL,FzR,fs_forces);
                    t0=trialData.GRFData.Time(1);
                    fs=trialData.GRFData.sampFreq;
                end
                events=labTimeSeries([LHSevent,RHSevent,LTOevent,RTOevent],t0,fs,{'LHS','RHS','LTO','RTO'});

            % 3) Generate processedTrial object    
                processedTrial=processedTrialData(this,events,procEMGData);
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

