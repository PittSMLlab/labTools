function out = calcParameters(in)
%in must be an object of the class processedlabData
%
%To add a new parameter, it must be added to the paramLabels
%cell and the label must be the same as the variable name the data is saved
%to. (ex: in paramlabels: 'swingTimeSlow', in code: swingTimeSlow(i)=timeSHS2-timeSTO;)

paramlabels = {'good',... %Flag indicating whether the stride has events in the expected order or not
    'swingTimeSlow',...
    'swingTimeFast',...
    'stanceTimeSlow',...
    'stanceTimeFast',...
    'doubleSupportSlow',...
    'doubleSupportFast',...
    'stepTimeSlow',...
    'stepTimeFast',...
    'toeOffSlow',...
    'toeOffFast',...
    'strideTimeSlow',...
    'strideTimeFast',...
    'cadenceSlow',...
    'cadenceFast',...
    'stepCadenceSlow',...
    'stepCadenceFast',...
    'doubleSupportPctSlow',...
    'doubleSupportPctFast',...
    'doubleSupportDiff',...
    'stepTimeDiff',...
    'stanceTimeDiff',...
    'swingTimeDiff',...
    'doubleSupportAsym',...
    'Tout',... %Step time difference divided by stride time
    'Tgoal',... %Stance time diff, divided by stride time
    'TgoalSW',... %Swing time diff, divided by stride time (should be same as Tgoal)
    'stepLengthSlow',...
    'stepLengthFast',...
    'alphaSlow',... %Leg angle (hip to angle with respect to vertical) at slow leg HS
    'alphaFast',... %Leg angle at fast leg HS
    'betaSlow',...
    'betaFast',...
    'rangeSlow',...
    'rangeFast',...
    'omegaSlow',...
    'omegaFast',...
    'alphaRatioSlow',...
    'alphaRatioFast',...
    'alphaDeltaSlow',...
    'alphaDeltaFast',...
    'stepLengthDiff',...
    'stepLengthAsym',... %Step length difference, divided by sum
    'angularSpreadDiff',...
    'angularSpreadAsym',...
    'Sout',... %Alpha difference, divided by alpha sum
    'Serror',... 
    'SerrorOld',...
    'Sgoal',...
    'angleOfOscillationAsym',...
    'phaseShift',...
    'phaseShiftPos',...
    'spatialContribution',... %Relative position of ankle markers at ipsi-lateral HS (i.e. slow ankle at SHS minus fast ankle at FHS)
    'stepTimeContribution',... %Average belt speed times step time difference
    'velocityContribution',... %Average step time times belt speed difference
    'netContribution'}; %Sum of the previous three, should be equal to stepLengthAsym

%make the time series have a time vectpr as small as possible so that
% a) it does not take up an unreasonable amount of space
% b) the paramaters can be plotted along with the GRF/kinematic data and
% the events used to create each data point can be distinguished.
sampPeriod=0.2;
f_params=1/sampPeriod;

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
aux=SHS+2*FTO+3*FHS+4*STO; %This should get events in the sequence 1,2,3,4,1... with 0 for non-events

%find median stride time
medStride=median(diff(eventsTime(find(SHS))));

paramTSlength=floor(length(eventsTime)*f_params/f_events);

%itialize all parameters so that they are all the same length as the events
numParams=length(paramlabels);
for i=1:numParams
    eval([paramlabels{i},'=NaN(paramTSlength,1);'])
end
data=zeros(paramTSlength,numParams);

%get kinematics
f_kin=in.markerData.sampFreq;
%get orientation
if isempty(in.markerData.orientation)
    warning('Assuming default orientation of axes for marker data.');
    orientation=orientationInfo([0,0,0],'x','y','z',1,1,1);
else
    orientation=in.markerData.orientation;
end
%Check that hip and ankle markers are present
if ~isempty(in.angleData)
    %get hip position    
    sHip=in.getMarkerData({[s 'HIP' orientation.foreaftAxis],[s 'HIP' orientation.updownAxis],[s 'HIP' orientation.sideAxis]});
    sHip=[orientation.foreaftSign*sHip(:,1),orientation.updownSign*sHip(:,2),orientation.sideSign*sHip(:,3)];
    fHip=in.getMarkerData({[f 'HIP' orientation.foreaftAxis],[f 'HIP' orientation.updownAxis],[f 'HIP' orientation.sideAxis]});
    fHip=[orientation.foreaftSign*fHip(:,1),orientation.updownSign*fHip(:,2),orientation.sideSign*fHip(:,3)];
    %get ankle position
    sAnk=in.getMarkerData({[s 'ANK' orientation.foreaftAxis],[s 'ANK' orientation.updownAxis],[s 'ANK' orientation.sideAxis]});
    sAnk=[orientation.foreaftSign*sAnk(:,1),orientation.updownSign*sAnk(:,2),orientation.sideSign*sAnk(:,3)];
    fAnk=in.getMarkerData({[f 'ANK' orientation.foreaftAxis],[f 'ANK' orientation.updownAxis],[f 'ANK' orientation.sideAxis]});
    fAnk=[orientation.foreaftSign*fAnk(:,1),orientation.updownSign*fAnk(:,2),orientation.sideSign*fAnk(:,3)];
    %Compute mean hip position (in fore-aft axis)
    meanHipPos=nanmean([sHip(:,1) fHip(:,1)],2);
    %Compute ankle position relative to average hip position
    sAnkPos=sAnk(:,1)-meanHipPos;
    fAnkPos=fAnk(:,1)-meanHipPos;
    %get angle data
    angles=in.angleData.getDataAsVector({[s,'Limb'],[f,'Limb']});
    sAngle=angles(:,1);
    fAngle=angles(:,2);
    
    calcSpatial=true;
else
    calcSpatial=false;    
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
    t=round(mean([indSHS indFTO indFHS indSTO indSHS2 indFTO2])*f_params/f_events);
    
    %Check consistency:
    aa=aux(inds(step):indFTO2); %Get events in this interval
    bb=diff(aa(aa~=0)); %Keep only event samples
    bad(t)= isempty(bb) || any(mod(bb,4)~=1) || (timeSHS2-timeSHS)>1.5*medStride; %Make sure the order of events is good
    good(t)=~bad(t);
    
    if good(t)
        
        %% Temporal Parameters
        
        %%% intralimb
        
        %swing times
        swingTimeSlow(t)=timeSHS2-timeSTO;
        swingTimeFast(t)=timeFHS-timeFTO;
        %stance times
        stanceTimeSlow(t)=timeSTO-timeSHS;
        stanceTimeFast(t)=timeFTO2-timeFHS;
        %double support times
        doubleSupportSlow(t)=timeSTO-timeFHS;
        doubleSupportFast(t)=timeFTO-timeSHS;
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
        cadenceFast(t)=1/strideTimeSlow(t);
        %step cadence (steps per s)
        stepCadenceSlow(t)=1/stepTimeSlow(t);
        stepCadenceFast(t)=1/stepTimeFast(t);
        %double support percent
        doubleSupportPctSlow(t)=doubleSupportSlow(t)/strideTimeSlow(t)*100;
        doubleSupportPctFast(t)=doubleSupportFast(t)/strideTimeFast(t)*100;
        
        %%% interlimb
        
        doubleSupportDiff(t)=doubleSupportSlow(t)-doubleSupportFast(t);
        stepTimeDiff(t)=stepTimeFast(t)-stepTimeSlow(t);
        stanceTimeDiff(t)=stanceTimeSlow(t)-stanceTimeFast(t);
        swingTimeDiff(t)=swingTimeFast(t)-swingTimeSlow(t); %why is this fast-slow when the rest are slow-fast?
        doubleSupportAsym(t)=(doubleSupportPctFast(t)-doubleSupportPctSlow(t))./(doubleSupportPctFast(t)+doubleSupportPctSlow(t));
        Tout(t)=(stepTimeDiff(t))/strideTimeSlow(t);
        Tgoal(t)=(stanceTimeDiff(t))/strideTimeSlow(t);
        TgoalSW(t)=(swingTimeDiff(t))/strideTimeSlow(t);
        
        %% Spatial Parameters
        
        if calcSpatial        
            %revise event indices so that they work with kinematic data if
            %frequencies differ
            CF=f_kin/f_events;
            indSHS=round(indSHS*CF);
            indFTO=round(indFTO*CF);
            indFHS=round(indFHS*CF);
            indSTO=round(indSTO*CF);
            indSHS2=round(indSHS2*CF);
            indFTO2=round(indFTO2*CF);

            % Set all steps to have the same slope (a negative slope during stance phase is assumed)
            if (sAnkPos(indSHS)<0)
                sAnkPos=-sAnkPos;
                fAnkPos=-fAnkPos;
            end
            if sAngle(indSHS)<0
                sAngle=-sAngle;
                fAngle=-fAngle;
            end

            %%% Intralimb

            %step lengths (1D)
            stepLengthSlow(t)=sAnkPos(indSHS2)-fAnkPos(indSHS2);
            stepLengthFast(t)=fAnkPos(indFHS)-sAnkPos(indFHS);
            %step length 2D? Express w.r.t the hip?

            %alpha (positive portion of interlimb angle at HS)
            alphaSlow(t)=sAngle(indSHS2);
            alphaTemp=sAngle(indSHS);
            alphaFast(t)=fAngle(indFHS);
            %beta (negative portion of interlimb angle at TO)
            betaSlow(t)=sAngle(indSTO);
            betaFast(t)=fAngle(indFTO2);
            %range (alpha+beta)
            rangeSlow(t)=alphaTemp-betaSlow(t);
            rangeFast(t)=alphaFast(t)-betaFast(t);
            %interlimb spread at HS
            omegaSlow(t)=abs(sAngle(indSHS2)-fAngle(indSHS2));
            omegaFast(t)=abs(fAnkPos(indFHS)-sAnkPos(indFHS));
            %alpha ratios
            alphaRatioSlow(t)=alphaSlow(t)/(alphaSlow(t)+alphaFast(t));
            alphaRatioFast(t)=alphaFast(t)/(alphaSlow(t)+alphaFast(t));
            %delta alphas
            alphaDeltaSlow(t)=sAngle(indSHS2)-fAngle(indFHS);
            alphaDeltaFast(t)=fAngle(indFHS)-sAngle(indSHS);

            %%% Interlimb

            stepLengthDiff(t)=stepLengthFast(t)-stepLengthSlow(t);
            stepLengthAsym(t)=stepLengthDiff(t)/(stepLengthFast(t)+stepLengthSlow(t));
            angularSpreadDiff(t)=omegaFast(t)-omegaSlow(t);
            angularSpreadAsym(t)=angularSpreadDiff(t)/(omegaFast(t)+omegaSlow(t));
            Sout(t)=(alphaFast(t)-alphaSlow(t))/(alphaFast(t)+alphaSlow(t));
            Serror(t)=alphaRatioSlow(t)-alphaRatioFast(t);
            SerrorOld(t)=alphaRatioFast(t)/alphaRatioSlow(t);
            Sgoal(t)=(rangeFast(t)-rangeSlow(t))/rangeFast(t);
            centerSlow=(alphaSlow(t)+betaSlow(t))/2;
            centerFast=(alphaFast(t)+betaFast(t))/2;
            angleOfOscillationAsym(t)=centerFast-centerSlow;
            %stepLengthAsym2D...

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

            % Compute spatial contribution
            sAnkPosHS=abs(sAnkPos(indSHS));
            fAnklePosHS=abs(fAnkPos(indFHS));
            sAnkPosHS2=abs(sAnkPos(indSHS2));
            spatialFast=fAnklePosHS - sAnkPosHS;
            spatialSlow=sAnkPosHS2 - fAnklePosHS;

            % Compute temporal contributions (convert time to be consistent with
            % kinematic sampling frequency)
            ts=round((timeFHS-timeSHS)*f_kin)/f_kin;
            tf=round((timeSHS2-timeFHS)*f_kin)/f_kin;
            difft=ts-tf;

            dispSlow=abs(sAnkPos(indFHS)-sAnkPos(indSHS));
            dispFast=abs(fAnkPos(indSHS2)-fAnkPos(indFHS));

            velocitySlow=dispSlow/ts; % Velocity of foot relative to hip
            velocityFast=dispFast/tf;
            avgVel=mean([velocitySlow velocityFast]);
            avgStepTime=mean([ts tf]);

            spatialContribution(t)=(spatialFast-spatialSlow);
            stepTimeContribution(t)=avgVel*difft;
            velocityContribution(t)=avgStepTime*(velocitySlow-velocityFast);
            netContribution(t)=spatialContribution(t)+stepTimeContribution(t)+velocityContribution(t);
        end
    end
    
end

for i=1:numParams
    eval(['data(:,i)=',paramlabels{i},';'])
end

out=labTimeSeries(data,eventsTime(1),sampPeriod,paramlabels);

try
    if any(bad)
        slashes=find(in.metaData.rawDataFilename=='\' | in.metaData.rawDataFilename=='/');
        file=in.metaData.rawDataFilename((slashes(end)+1):end);
        disp(['Warning: Non consistent event detection in ' num2str(sum(bad)) ' strides of ',file])    
    end
catch
        slashes=find(in.metaData.rawDataFilename=='\' | in.metaData.rawDataFilename=='/');
        file=in.metaData.rawDataFilename((slashes(end)+1):end);
        disp(['Warning: No strides detected in ',file])
end
