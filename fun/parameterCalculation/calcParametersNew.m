function out = calcParametersNew(trialData,subData)
in=trialData;
%in must be an object of the class processedlabData
%
%To add a new parameter, it must be added to the paramLabels cell and the
%label must be the same as the variable name the data is saved to within
%the code. (ex: in paramlabels: 'swingTimeSlow', in code: swingTimeSlow(t)=timeSHS2-timeSTO;)
%note: if adding a slow and fast version of one parameter, make sure 'Fast'
%and 'Slow' appear at the end of the respective parameter names. See
%existing parameter names as an example.


% one "stride" contains the events: SHS,FTO,FHS,STO,SHS2,FTO2
% see lab tools user guide for a helpful visual of events.
paramlabels = {'good',...       Flag indicating whether the stride has events in the expected order or not
    'initTime',...
    'finalTime',...
    'swingTimeSlow',...         time from STO to SHS2 (in s)
    'swingTimeFast',...         time from FTO to FHS (in s)
    'stanceTimeSlow',...        time from SHS to STO (in s)
    'stanceTimeFast',...        time from FHS to FTO (in s)
    'doubleSupportSlow',...     time from FHS to STO (in s)
    'doubleSupportFast',...     time from SHS to FTO (in s)
    'stepTimeSlow',...          time from FHS to SHS2 (in s)
    'stepTimeFast',...          time from SHS to FHS (in s)
    'toeOffSlow',...            time from STO to FTO2 (in s)
    'toeOffFast',...            time from FTO to STO (in s)
    'strideTimeSlow',...        time from SHS to SHS2 (in s)
    'strideTimeFast',...        time from FTO to FTO2 (in s)
    'cadenceSlow',...           1/strideTimeSlow (in Hz)
    'cadenceFast',...           1/strideTimeFast (in Hz)
    'stepCadenceSlow',...       1/stepTimeSlow (in Hz)
    'stepCadenceFast',...       1/stepTimeFast (in Hz)
    'doubleSupportPctSlow',...  (doubleSupportSlow/strideTimeSlow)*100
    'doubleSupportPctFast',...  (doubleSupportFast/strideTimeFast)*100
    'doubleSupportDiff',...     doubleSupportSlow-doubleSupportFast (in s)    
    'stepTimeDiff',...          stepTimeFast-stepTimeSlow (in s)
    'stanceTimeDiff',...        stanceTimeSlow-stanceTimeFast (in s)
    'swingTimeDiff',...         swingTimeFast-swingTimeSlow (in s)
    'doubleSupportAsym',...     (doubleSupportPctFast-doubleSupportPctSlow)/(doubleSupportPctFast+doubleSupportPctSlow)
    'Tout',...                  stepTimeDiff/strideTimeSlow
    'Tgoal',...                 stanceTimeDiff/strideTimeSlow
    'TgoalSW',...               swingTimeDiff/strideTimeSlow (should be same as Tgoal)
    'direction',...             -1 if walking towards window, 1 if walking towards door (implemented for OG bias removal and coordinate rotation)
    'hipPos',...                average hip position of stride (should be nearly constant on treadmill - implemented for OG bias removal) (in mm)
    'stepLengthSlow',...        distance between ankle markers (relative to avg hip marker) at SHS2 (in mm)
    'stepLengthFast',...        distance between ankel markers (relative to hip) at FHS (in mm)
    'alphaSlow',...             ankle placement of slow leg at SHS2 (realtive to avg hip marker) (in mm)
	'alphaTemp',...             ankle placement of slow leg at SHS (realtive to avg hip marker) (in mm)
    'alphaFast',...             ankle placement of fast leg at FHS (in mm)
    'alphaAngSlow',...          slow leg angle (hip to ankle with respect to vertical) at SHS2 (in deg)
    'alphaAngFast',...          fast leg angle at FHS (in deg)
    'betaSlow',...              ankle placement of slow leg at STO (relative avg hip marker) (in mm)
    'betaFast',...              ankle placement of fast leg at FTO2 (in mm)
	'XSlow',...                 ankle postion of the slow leg @FHS (in mm)
    'XFast',...                 ankle position of Fast leg @SHS (in mm)
	'RFastPos',...              Ratio of FTO/FHS
    'RSloWPos',...              Ratio of STO/SHS
    'RFastPosSHS',...           Ratio of fank@SHS/FHS
    'RSlowPosFHS',...           Ratio of sank@FHS/SHS
    'betaAngSlow',...           slow leg angle at STO (in deg)
    'betaAngFast',...           fast leg angle at FTO (in deg)
    'stanceRangeSlow',...       alphaSlow - betaSlow (i.e. total distance covered by slow ankle relative to hip during stance) (in mm)
    'stanceRangeFast',...       alphaFast - betaFast (in mm)
    'stanceRangeAngSlow',...    |alphaAngSlow| + |betaAngSlow| (i.t total angle swept out by slow leg during stance) (in deg)
    'stanceRangeAngFast',...    |alphaAngFast| + |betaAngFast| (in deg)
    'swingRangeSlow',...        total distance covered by slow ankle marker realtive to hip from STO to SHS2 (in mm)
    'swingRangeFast',...        total distance covered by fast ankle marker realtive to hip from FTO to FHS (in mm)
    'omegaSlow',...             angle between legs at SHS2 (in deg)
    'omegaFast',...             angle between legs at FHS (in deg)
    'alphaRatioSlow',...        alphaSlow/(alphaSlow+alphaFast)
    'alphaRatioFast',...        alphaFast/(alphaSlow+alphaFast)
    'alphaDeltaSlow',...        slow leg angle at SHS2 - fast leg angle at FHS (in deg)
    'alphaDeltaFast',...        fast leg angle at FHS - slow leg angle at SHS (in deg)
    'stepLengthDiff',...        stepLengthFast-stepLengthSlow (in mm)
    'stepLengthDiff2D',...      two-dimensional version of stepLengthDiff (in mm)
    'stepLengthAsym',...        Step length difference (fast-slow), divided by sum
    'stepLengthAsym2D',...      two-dimensional step length difference (fast-slow), divided by sum
    'angularSpreadDiff',...     omegaFast-omegaSlow (in deg)
    'angularSpreadAsym',...     angular spread difference / sum
    'Sout',...                  Alpha difference (fast-slow), divided by alpha sum
    'Serror',...                alphaRatioSlow-alphaRatioFast
    'SerrorOld',...             alphaRatioFast/alphaRatioSlow
    'Sgoal',...                 (stanceRangeAngFast-stanceRangeAngSlow)/stanceRangeAngFast
    'angleOfOscillationAsym',...(alhpaAngFast+betaAngFast)/2-(alphaAngSlow+betaAngSlow)/2
    'phaseShift',...            parcent of stride that one angle trace is shifted with respect to the other for max correlation
    'phaseShiftPos',...         same as phaseShift, but uses ankle pos trace instead of angles
    'spatialContribution',...   Relative position of ankle markers at ipsi-lateral HS (i.e. slow ankle at SHS minus fast ankle at FHS)
    'stepTimeContribution',...  Average belt speed times step time difference
    'velocityContribution',...  Average step time times belt speed difference
    'netContribution',...       Sum of the previous three
    'spatialContributionAlt',...   Same as before, divided by cadence, to get velocity units instead of length units
    'stepTimeContributionAlt',...  
    'velocityContributionAlt',...  
    'netContributionAlt',...  
    'spatialContributionNorm',...   Same as before, divided by equivalentSpeed, so we get a dimensionless parameter
    'stepTimeContributionNorm',...  
    'velocityContributionNorm',...  
    'netContributionNorm',... 
    'spatialContributionNorm2',...   Alternative normalization: spatialContribution/(stepLengthFast+stepLengthSlow)
    'stepTimeContributionNorm2',...  
    'velocityContributionNorm2',...  
    'netContributionNorm2',...  With this normalization, netContributionNorm2 shoudl be IDENTICAL to stepLengthAsym
    'equivalentSpeed',...       Relative speed of hip to feet, 
    'singleStanceSpeedSlow',... Relative speed of hip to slow ankle during contralateral swing
    'singleStanceSpeedFast',... Relative speed of hip to fast ankle during contralateral swing
    'singleStanceSpeedSlowAbs',...  Absolute speed of slow ankle during contralateral swing
    'singleStanceSpeedFastAbs',...  Absolute speed of fast ankle during contralateral swing
    'stepSpeedSlow',...         Ankle relative to hip, from iHS to cHS
    'stepSpeedFast',...         Ankle relative to hip, from iHS to cHS
    'stanceSpeedSlow',...       Ankle relative to hip, during ipsilateral stance
    'stanceSpeedFast',...       Ankle relative to hip, during ipsilateral stance
    'avgRotation',...           Angle that the coordinates were rotated by
    }; 

%make the time series have a time vector as small as possible so that
% a) it does not take up an unreasonable amount of space
% b) the paramaters can be plotted along with the GRF/kinematic data and
% the events used to create each data point can be distinguished.
%sampPeriod=0.2;
%f_params=1/sampPeriod;

if in.metaData.refLeg == 'R'
    s = 'R';
    f = 'L';
elseif in.metaData.refLeg == 'L'
    s = 'L';
    f = 'R';
else
    ME=MException('MakeParameters:refLegError','the refLeg property of metaData must be either ''L'' or ''R''.');
    throw(ME);
end
%% retrieve data from labData object to be used to calculate parameters

%get events
f_events=in.gaitEvents.sampFreq;
events=in.gaitEvents.getDataAsVector({[s,'HS'],[f,'HS'],[s,'TO'],[f,'TO']});
SHS=events(:,1);
FHS=events(:,2);
STO=events(:,3);
FTO=events(:,4);
eventsTime=in.gaitEvents.Time;
eventNumbers=SHS+2*FTO+3*FHS+4*STO; %This should get events in the sequence 1,2,3,4,1... with 0 for non-events

%find median stride time
medStride=median(diff(eventsTime(SHS==1)));

%get orientation
if isempty(in.markerData.orientation)
    warning('Assuming default orientation of axes for marker data.');
    orientation=orientationInfo([0,0,0],'x','y','z',1,1,1);
else
    orientation=in.markerData.orientation;
end

    calcSpatial=true;
    %Alternative version: interpolating kinematics to eventTimes, so we can
    %use the same indexing.
    directions={orientation.sideAxis,orientation.foreaftAxis,orientation.updownAxis};
    signs=[orientation.sideSign,orientation.foreaftSign,orientation.updownSign];
    markers={'HIP','ANK','TOE'};
    labels={};
    legs={'L','R'};
        for j=1:length(markers)
            for leg=1:2
                for i=1:3
                    labels{end+1}=[legs{leg} markers{j} directions{i}];
                end
            end
        end
    [newMarkerData,labels]=in.markerData.getDataAsTS(labels);
    newMarkerData=newMarkerData.getSample(eventsTime);
    
    
    sHip=nan(length(eventsTime),3);
    fHip=nan(length(eventsTime),3);
    sAnk=nan(length(eventsTime),3);
    fAnk=nan(length(eventsTime),3);
    sToe=nan(length(eventsTime),3);
    fToe=nan(length(eventsTime),3);
    
    legs={s,f};
    legs2={'s','f'};
    for i=1:3 %x,y,z
        for j=1:length(markers)
            for leg=1:2 %1=s, 2=f
                aux=newMarkerData(:,strcmp(labels,[legs{leg} markers{j} directions{i}]));
                if ~isempty(aux) %Missing marker
                    eval([legs2{leg} upper(markers{j}(1)) lower(markers{j}(2:end)) '(:,i)=aux*signs(i);']);
                else
                    warning([[legs{leg} markers{j} directions{i}] ' marker is missing.'])
                end
            end
        end
    end
    
    %get angle data
    if ~isempty(in.angleData)
    newAngleData=in.angleData.getDataAsTS({[s,'Limb'],[f,'Limb']});
    newAngleData=newAngleData.getSample(eventsTime);
    sAngle=newAngleData(:,1);
    fAngle=newAngleData(:,2);
    else
        sAngle=nan(length(eventsTime),1);
        fAngle=nan(length(eventsTime),1);
    end
    

%% Find number of strides
lastSHStime=eventsTime(find(SHS,2,'last'));
lastFTOtime=eventsTime(find(FTO,2,'last'));
lastFHStime=eventsTime(find(FHS,1,'last'));
lastSTOtime=eventsTime(find(STO,1,'last'));

%minimum events to construct one stride
if length(lastFTOtime)>1 && ~isempty(lastFHStime) && ~isempty(lastSTOtime) && length(lastSHStime)>1
    maxTime=min([lastFTOtime(1) lastFHStime lastSTOtime lastSHStime(2)]);
    Nstrides=sum(SHS(eventsTime<maxTime));
    inds=find(SHS);    
else
    Nstrides=0;
end

%% Initialize parameters
%paramTSlength=floor(length(eventsTime)*f_params/f_events);
paramTSlength=Nstrides;

%itialize all parameters so that they are all the same length as the events
numParams=length(paramlabels);
for i=1:numParams
    eval([paramlabels{i},'=NaN(paramTSlength,1);'])
end
data=zeros(paramTSlength,numParams);
times=zeros(paramTSlength,1);
%% Calculate parameters

for step=1:Nstrides
    
    %get indices and times
    indSHS=inds(step);
    timeSHS=eventsTime(indSHS);
    indFTO=find((eventsTime>timeSHS)&FTO,1);
    timeFTO=eventsTime(indFTO);
    indFHS=find((eventsTime>timeFTO)&FHS,1);
    timeFHS=eventsTime(indFHS);
    indSTO=find((eventsTime>timeFHS)&STO,1);
    timeSTO=eventsTime(indSTO);
    indSHS2=inds(step+1);
    timeSHS2=eventsTime(indSHS2);
    indFTO2=find((eventsTime>timeSHS2)&FTO,1);
    timeFTO2=eventsTime(indFTO2);
    
    %get mean index - this will be index of param.
    %t=round(mean([indSHS indFTO indFHS indSTO indSHS2 indFTO2])*f_params/f_events);
    t=step;
    times(step)=mean([timeSHS timeFTO timeFHS timeSTO timeSHS2 timeFTO2]);
    
    
    %Check consistency:
    aa=eventNumbers(inds(step):indFTO2); %Get events in this interval
    bb=diff(aa(aa~=0)); %Keep only event samples
    bad(t)= isempty(bb) || any(mod(bb,4)~=1) || (timeSHS2-timeSHS)>1.5*medStride; %Make sure the order and timing of events is good
    good(t)=~bad(t);
    
    if good(t)
        
        %% Temporal Parameters
        
        %%metaDAta
        initTime(t)=timeSHS;
        finalTime(t)=timeFTO2;
        
        %%% intralimb
        
        %swing times
        swingTimeSlow(t)=timeSHS2-timeSTO;
        swingTimeFast(t)=timeFHS-timeFTO;
        %stance times
        stanceTimeSlow(t)=timeSTO-timeSHS;
        stanceTimeFast(t)=timeFTO2-timeFHS;
        %double support times
        doubleSupportSlow(t)=timeSTO-timeFHS;
        doubleSupportFast(t)=timeFTO2-timeSHS2; %PAblo: changed on 11/11/2014 to use the second step instead of the first one, so stance time= step time + double support time with the given indexing.
        %step times (time between heel strikes)
        stepTimeSlow(t)=timeSHS2-timeFHS;
        stepTimeFast(t)=timeFHS-timeSHS;
        %time betwenn toe offs
        toeOffSlow(t)=timeFTO2-timeSTO;
        toeOffFast(t)=timeSTO-timeFTO;
        %stride times
        strideTimeSlow(t)=timeSHS2-timeSHS;
        strideTimeFast(t)=timeFTO2-timeFTO;
        %cadence (stride cycles per s)
        cadenceSlow(t)=1/strideTimeSlow(t);
        cadenceFast(t)=1/strideTimeFast(t);
        %step cadence (steps per s)
        stepCadenceSlow(t)=1/stepTimeSlow(t);
        stepCadenceFast(t)=1/stepTimeFast(t);
        %double support percent
        doubleSupportPctSlow(t)=doubleSupportSlow(t)/strideTimeSlow(t)*100;
        doubleSupportPctFast(t)=doubleSupportFast(t)/strideTimeFast(t)*100;
        
        %%% interlimb
        %note: the decision on Fast-Slow vs Slow-Fast was made based on how
        %the parameter looks when plotted.
        doubleSupportDiff(t)=doubleSupportSlow(t)-doubleSupportFast(t);
        stepTimeDiff(t)=stepTimeFast(t)-stepTimeSlow(t);
        stanceTimeDiff(t)=stanceTimeSlow(t)-stanceTimeFast(t);
        swingTimeDiff(t)=swingTimeFast(t)-swingTimeSlow(t);
        doubleSupportAsym(t)=(doubleSupportPctFast(t)-doubleSupportPctSlow(t))./(doubleSupportPctFast(t)+doubleSupportPctSlow(t));
        Tout(t)=(stepTimeDiff(t))/strideTimeSlow(t);
        Tgoal(t)=(stanceTimeDiff(t))/strideTimeSlow(t);
        TgoalSW(t)=(swingTimeDiff(t))/strideTimeSlow(t);
        
        %% Spatial Parameters
        
        if calcSpatial       
            %Alternative version: interpolating kinematics instead of
            %rounding event times. Therefore, there is no need to find new
            %times or indexes.
           
            
            %find walking direction
            if sAnk(indSHS2,2)<sAnk(indSTO,2)
                direction(t)=-1;
            else
                direction(t)=1;
            end
            
            hipPos(t)= mean([sHip(indSHS,2) fHip(indSHS,2)]);
                         
            %rotate coordinates to be aligned wiht walking dierection                      
            sRotation = calcangle(sAnk(indSHS2,1:2),sAnk(indSTO,1:2),[sAnk(indSTO,1)-100*direction(t) sAnk(indSTO,2)])-90;
            fRotation = calcangle(fAnk(indFHS,1:2),fAnk(indFTO,1:2),[fAnk(indFTO,1)-100*direction(t) fAnk(indFTO,2)])-90;
            
            avgRotation(t) = (sRotation+fRotation)/2;
            
            rotationMatrix = [cosd(avgRotation(t)) -sind(avgRotation(t)) 0; sind(avgRotation(t)) cosd(avgRotation(t)) 0; 0 0 1];
            sAnk(indSHS:indFTO2,:) = (rotationMatrix*sAnk(indSHS:indFTO2,:)')';
            fAnk(indSHS:indFTO2,:) = (rotationMatrix*fAnk(indSHS:indFTO2,:)')';
            sHip(indSHS:indFTO2,:) = (rotationMatrix*sHip(indSHS:indFTO2,:)')';
            fHip(indSHS:indFTO2,:) = (rotationMatrix*fHip(indSHS:indFTO2,:)')';
            
            %Compute mean (across the two markers) hip position (in fore-aft axis)
            meanHipPos=nanmean([sHip(:,2) fHip(:,2)],2);
            meanHipPos2D=[nanmean([sHip(:,1) fHip(:,1)],2) meanHipPos];
            %Compute ankle position relative to average hip position
            sAnkPos=sAnk(:,2)-meanHipPos;
            fAnkPos=fAnk(:,2)-meanHipPos;
            sAnkPos2D=sAnk(:,[1 2])-meanHipPos2D;
            fAnkPos2D=fAnk(:,[1 2])-meanHipPos2D;
            
            % Set all steps to have the same slope (a negative slope during stance phase is assumed)
            if sAnk(indSHS2,2)<sAnk(indSTO,2)
                %Pablo edit 11/6/2014
                %Changed the test: what we really want to know is whether
                %they are walking towards the window or the door, not if
                %the ankle is in front of the hip.
                sAnkPos=-sAnkPos;
                fAnkPos=-fAnkPos;      
                sAnkPos2D=-sAnkPos2D;
                fAnkPos2D=-fAnkPos2D;
            end
            if sAngle(indSHS)<0
                sAngle=-sAngle;
                fAngle=-fAngle;
            end

            %%% Intralimb

            %step lengths (1D)
            stepLengthSlow(t)=sAnkPos(indSHS2)-fAnkPos(indSHS2);
            stepLengthFast(t)=fAnkPos(indFHS)-sAnkPos(indFHS);
            %step length (2D) Express w.r.t the hip -- don't save, for now.
            stepLengthSlow2D=norm(sAnkPos2D(indSHS2,:)-fAnkPos2D(indSHS2,:));
            stepLengthFast2D=norm(fAnkPos2D(indFHS,:)-sAnkPos2D(indFHS,:));

            %Spatial parameters - in meters
            
            %alpha (positive portion of interlimb angle at HS)
            alphaSlow(t)=sAnkPos(indSHS2);
            alphaTemp(t)=sAnkPos(indSHS);
            alphaFast(t)=fAnkPos(indFHS);
            %beta (negative portion of interlimb angle at TO)
            betaSlow(t)=sAnkPos(indSTO);
            betaFast(t)=fAnkPos(indFTO2);
			%position of the ankle market at contra lateral at HS
			XSlow(t)=sAnkPos(indFHS);
            XFast(t)=fAnkPos(indSHS);
            %stacne range (alpha+beta)
            stanceRangeSlow(t)=alphaTemp(t)-betaSlow(t);
            stanceRangeFast(t)=alphaFast(t)-betaFast(t);
            %swing range
            swingRangeSlow(t)=sAnkPos(indSHS2)-sAnkPos(indSTO);
            swingRangeFast(t)=fAnkPos(indFHS)-fAnkPos(indFTO);
			
			%Ratio TO/HS
            RFastPos(t)=abs(betaFast(t)/alphaFast(t));
            RSloWPos(t)=abs(betaSlow(t)/ alphaTemp(t)); 
            
            %Ratio ankle position @HS of contralateral leg/HS
            RFastPosSHS(t)=abs(XFast(t)/alphaFast(t));
            RSlowPosFHS(t)=abs(XSlow(t)/alphaTemp(t));
            
            
            %Spatial parameters - in degrees
            
            %alpha (positive portion of interlimb angle at HS)
            alphaAngSlow(t)=sAngle(indSHS2);
            alphaAngTemp=sAngle(indSHS);
            alphaAngFast(t)=fAngle(indFHS);
            %beta (negative portion of interlimb angle at TO)
            betaAngSlow(t)=sAngle(indSTO);
            betaAngFast(t)=fAngle(indFTO2);
            %range (alpha+beta)
            stanceRangeAngSlow(t)=alphaAngTemp-betaAngSlow(t);
            stanceRangeAngFast(t)=alphaAngFast(t)-betaAngFast(t);
            %interlimb spread at HS
            omegaSlow(t)=abs(sAngle(indSHS2)-fAngle(indSHS2));
            omegaFast(t)=abs(fAngle(indFHS)-sAngle(indFHS));
            %alpha ratios
            alphaRatioSlow(t)=alphaSlow(t)/(alphaSlow(t)+alphaFast(t));
            alphaRatioFast(t)=alphaFast(t)/(alphaSlow(t)+alphaFast(t));
            %delta alphas
            alphaDeltaSlow(t)=sAngle(indSHS2)-fAngle(indFHS); %same as alphaAngSlow(t)-alphaAngFast(t)
            alphaDeltaFast(t)=fAngle(indFHS)-sAngle(indSHS);

            %%% Interlimb

            stepLengthDiff(t)=stepLengthFast(t)-stepLengthSlow(t);
            stepLengthAsym(t)=stepLengthDiff(t)/(stepLengthFast(t)+stepLengthSlow(t));
            stepLengthDiff2D(t)=stepLengthFast2D-stepLengthSlow2D;
            stepLengthAsym2D(t)=stepLengthDiff2D(t)/(stepLengthFast2D+stepLengthSlow2D);
            angularSpreadDiff(t)=omegaFast(t)-omegaSlow(t);
            angularSpreadAsym(t)=angularSpreadDiff(t)/(omegaFast(t)+omegaSlow(t));
            Sout(t)=(alphaFast(t)-alphaSlow(t))/(alphaFast(t)+alphaSlow(t));
            Serror(t)=alphaRatioSlow(t)-alphaRatioFast(t);
            SerrorOld(t)=alphaRatioFast(t)/alphaRatioSlow(t);
            Sgoal(t)=(stanceRangeAngFast(t)-stanceRangeAngSlow(t))/(stanceRangeAngFast(t)+stanceRangeSlow(t));
            centerSlow(t)=(alphaAngSlow(t)+betaAngSlow(t))/2;
            centerFast(t)=(alphaAngFast(t)+betaAngFast(t))/2;
            angleOfOscillationAsym(t)=(centerFast(t)-centerSlow(t));            

            %phase shift (using angles)
            slowlimb=sAngle(indSHS:indSHS2);
            fastlimb=fAngle(indSHS:indSHS2);
            slowlimb=slowlimb-mean(slowlimb);
            fastlimb=fastlimb-mean(fastlimb);
            % Circular correlation
            phaseShift(t)=circCorr(slowlimb,fastlimb);

            %phase shift (using marker locations)
            slowlimb=sAnkPos(indSHS:indSHS2);
            fastlimb=fAnkPos(indSHS:indSHS2);
            slowlimb=slowlimb-mean(slowlimb);
            fastlimb=fastlimb-mean(fastlimb);
            % Circular correlation
            phaseShiftPos(t)=circCorr(slowlimb,fastlimb);

            %% Contribution Calculations

            % Compute spatial contribution (1D)
            spatialFast=fAnkPos(indFHS) - sAnkPos(indSHS);
            spatialSlow=sAnkPos(indSHS2) - fAnkPos(indFHS);    

            % Compute temporal contributions (convert time to be consistent with
            % kinematic sampling frequency)
            ts=(timeFHS-timeSHS); %This rounding should no longer be required, as we corrected indices for kinematic sampling frequency and computed the corresponding times
            tf=(timeSHS2-timeFHS); %This rounding should no longer be required, as we corrected indices for kinematic sampling frequency and computed the corresponding times
            difft=ts-tf;

            dispSlow=abs(sAnkPos(indFHS)-sAnkPos(indSHS));
            dispFast=abs(fAnkPos(indSHS2)-fAnkPos(indFHS));

            velocitySlow=dispSlow/ts; % Velocity of foot relative to hip, should be close to actual belt speed in TM trials
            velocityFast=dispFast/tf;            
            avgVel=mean([velocitySlow velocityFast]);           
            avgStepTime=mean([ts tf]);
            
            spatialContribution(t)=spatialFast-spatialSlow;            
            stepTimeContribution(t)=avgVel*difft;            
            velocityContribution(t)=avgStepTime*(velocitySlow-velocityFast);            
            netContribution(t)=spatialContribution(t)+stepTimeContribution(t)+velocityContribution(t);            
            
            %speed calculations            
            equivalentSpeed(t)=(dispSlow+dispFast)/(ts+tf); %= (ts/tf+ts)*dispSlow/ts + (tf/tf+ts)*dispFast/tf = (ts/tf+ts)*vs + (tf/tf+ts)*vf = weighted average of ipsilateral speeds: if subjects spend much more time over one foot than the other, this might not be close to the arithmetic average

            % Commented on 20/3/2015 by Pablo, new definition (hopefully
            % more robust) below:
%             singleStanceSpeedSlow(t)=abs(sAnkPos(indFTO)-sAnkPos(indFHS))/(round((timeFHS-timeFTO)*f_kin)/f_kin); %Ankle relative to hip, during contralateral swing
%             singleStanceSpeedFast(t)=abs(fAnkPos(indSTO)-fAnkPos(indSHS2))/(round((timeSHS2-timeSTO)*f_kin)/f_kin); %Ankle relative to hip, during contralateral swing
%             
%             singleStanceSpeedSlowAbs(t)=abs(sAnk(indFTO,2)-sAnk(indFHS,2))/(round((timeFHS-timeFTO)*f_kin)/f_kin); %Ankle absolute speed: should be exactly belt speed for TM trials, and exactly 0 on OG
%             singleStanceSpeedFastAbs(t)=abs(fAnk(indSTO,2)-fAnk(indSHS2,2))/(round((timeSHS2-timeSTO)*f_kin)/f_kin); %Ankle absolute speed: should be exactly belt speed for TM trials, and exactly 0 on OG

            singleStanceSpeedSlow(t)=nanmedian(f_events*diff(sAnkPos(indFTO:indFHS)));
            singleStanceSpeedFast(t)=nanmedian(f_events*diff(fAnkPos(indSTO:indSHS2)));

            %singleStanceSpeedSlowAbs(t)=nanmedian(f_events*diff(sAnk(indFTO:indFHS,2)));
            %singleStanceSpeedFastAbs(t)=nanmedian(f_events*diff(fAnk(indSTO:indSHS2,2)));
            sStanceIdxs=indFTO:indFHS;
            fStanceIdxs=indSTO:indSHS2;
            singleStanceSpeedSlowAbs(t)=prctile(f_events*diff(sToe(sStanceIdxs,2)),70);
            singleStanceSpeedFastAbs(t)=prctile(f_events*diff(fToe(fStanceIdxs,2)),70);

            
            stanceSpeedSlow(t)=abs(sAnkPos(indSTO)-sAnkPos(indSHS))/(timeSTO-timeSHS); %Ankle relative to hip, during ipsilateral stance
            stanceSpeedFast(t)=abs(fAnkPos(indFTO)-fAnkPos(indFHS))/(timeFTO2-timeFHS); %Ankle relative to hip, during ipsilateral stance
            
            stepSpeedSlow(t)=dispSlow/ts; %Ankle relative to hip, from iHS to cHS
            stepSpeedFast(t)=dispFast/tf; %Ankle relative to hip, from iHS to cHS
            
            
            %Rotate coordinates back to original so there are not
            %disconinuities within next stride
            rotationMatrix = [cosd(-avgRotation(t)) -sind(-avgRotation(t)) 0; sind(-avgRotation(t)) cosd(-avgRotation(t)) 0; 0 0 1];
            sAnk(indSHS:indFTO2,:) = (rotationMatrix*sAnk(indSHS:indFTO2,:)')';
            fAnk(indSHS:indFTO2,:) = (rotationMatrix*fAnk(indSHS:indFTO2,:)')';
            sHip(indSHS:indFTO2,:) = (rotationMatrix*sHip(indSHS:indFTO2,:)')';
            fHip(indSHS:indFTO2,:) = (rotationMatrix*fHip(indSHS:indFTO2,:)')';
            
            %Alternative and normalized contributions
            spatialContributionAlt(t)=spatialContribution(t)/strideTimeSlow(t);
            stepTimeContributionAlt(t)=stepTimeContribution(t)/strideTimeSlow(t);
            velocityContributionAlt(t)=velocityContribution(t)/strideTimeSlow(t);
            netContributionAlt(t)=netContribution(t)/strideTimeSlow(t);
            spatialContributionNorm(t)=spatialContributionAlt(t)/equivalentSpeed(t);
            stepTimeContributionNorm(t)=stepTimeContributionAlt(t)/equivalentSpeed(t);
            velocityContributionNorm(t)=velocityContributionAlt(t)/equivalentSpeed(t);
            netContributionNorm(t)=netContributionAlt(t)/equivalentSpeed(t);
            spatialContributionNorm2(t)=spatialContribution(t)/(stepLengthFast(t)+stepLengthSlow(t));
            stepTimeContributionNorm2(t)=stepTimeContribution(t)/(stepLengthFast(t)+stepLengthSlow(t));
            velocityContributionNorm2(t)=velocityContribution(t)/(stepLengthFast(t)+stepLengthSlow(t));
            netContributionNorm2(t)=netContribution(t)/(stepLengthFast(t)+stepLengthSlow(t));
            
            
        end
    end
    
end

%% Assign parameters to data matrix
for i=1:numParams
    eval(['data(:,i)=',paramlabels{i},';'])
end

%% Create parameterSeries
%out=labTimeSeries(data,eventsTime(1),sampPeriod,paramlabels);
out=parameterSeries(data,paramlabels,times,cell(size(paramlabels)));

%% Issue bad strides warning
try
    if any(bad)
        [file]= getSimpleFileName(in.metaData.rawDataFilename);
        disp(['Warning: Non consistent event detection in ' num2str(sum(bad)) ' strides of ',file])    
    end
catch
    [file] = getSimpleFileName(in.metaData.rawDataFilename);
    disp(['Warning: No strides detected in ',file])
end