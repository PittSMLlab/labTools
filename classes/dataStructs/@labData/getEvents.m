function events = getEvents(trialData,angleData,perceptualFlag)

file=getSimpleFileName(trialData.metaData.rawDataFilename);

if isempty(trialData.markerData.orientation)
    warning('Assuming default orientation of axes for marker data.');
    orientation=orientationInfo([0,0,0],'x','y','z',1,1,1);
else
    orientation=trialData.markerData.orientation;
end

if ~isempty(angleData)
    [kinLHS,kinRHS,kinLTO,kinRTO] = getEventsFromAngles(trialData,angleData,orientation);
else
    [kinLHS,kinRHS,kinLTO,kinRTO] = deal(false(10,1)); %length 10 to prevent errors downstream
end
 

if strcmpi(trialData.metaData.type,'OG') || strcmpi(trialData.metaData.type,'NIM') %Overground Trial, default is to use limb angles to calculate events
    
    [LHSevent,LHSeventKin]=deal(kinLHS); %Make a redundant compy to make kinematic events deafault
    [RHSevent,RHSeventKin]=deal(kinRHS);
    [LTOevent,LTOeventKin]=deal(kinLTO);
    [RTOevent,RTOeventKin]=deal(kinRTO);
    
    LHSeventForce=false(length(LHSevent),1); %No force events, fill with logical 0's
    RHSeventForce=false(length(RHSevent),1);
    LTOeventForce=false(length(LTOevent),1);
    RTOeventForce=false(length(RTOevent),1);
    
    t0=trialData.markerData.Time(1);
    Ts=trialData.markerData.sampPeriod;
    
%     t0=trialData.GRFData.Time(1);
%     Ts=trialData.GRFData.sampPeriod;
else %Treadmill trial
    
    if isempty(trialData.GRFData) || isempty(trialData.GRFData.Data) %No force data, default events calculatd from marker data (not labeled as kin events though!!) 
        disp(['No ground reaction forces data in ' file '. Using marker data to compute events.'])
        
%         LtoePos=trialData.getMarkerData({['LTOE' orientation.foreaftAxis],['LTOE' orientation.updownAxis],['LTOE' orientation.sideAxis]});
%         LtoePos=[orientation.foreaftSign* LtoePos(:,1),orientation.updownSign*LtoePos(:,2),orientation.sideSign*LtoePos(:,3)];
%         RtoePos=trialData.getMarkerData({['RTOE' orientation.foreaftAxis],['RTOE' orientation.updownAxis],['RTOE' orientation.sideAxis]});
%         RtoePos=[orientation.foreaftSign* RtoePos(:,1),orientation.sideSign*RtoePos(:,2),orientation.updownSign*RtoePos(:,3)];
        
        LtoePos = trialData.markerData.getDataAsVector({'LTOE'});
        RtoePos = trialData.markerData.getDataAsVector({'LTOE'});
        
%         LanklePos=trialData.getMarkerData({['LANK' orientation.foreaftAxis],['LANK' orientation.updownAxis],['LANK' orientation.sideAxis]});
%         LanklePos=[orientation.foreaftSign* LanklePos(:,1),orientation.sideSign*LanklePos(:,2),orientation.updownSign*LanklePos(:,3)];
%         RanklePos=trialData.getMarkerData({['RANK' orientation.foreaftAxis],['RANK' orientation.updownAxis],['RANK' orientation.sideAxis]});
%         RanklePos=[orientation.foreaftSign* RanklePos(:,1),orientation.sideSign*RanklePos(:,2),orientation.updownSign*RanklePos(:,3)];
        
        LanklePos = trialData.markerData.getDataAsVector({'LANK'});
        RanklePos = trialData.markerData.getDataAsVector({'RANK'});
        
        if trialData.markerData.isaLabel('LHEEx')
%             LheelPos=trialData.getMarkerData({['LHEE' orientation.foreaftAxis],['LHEE' orientation.updownAxis],['LHEE' orientation.sideAxis]});
%             LheelPos=[orientation.foreaftSign* LheelPos(:,1),orientation.sideSign*LheelPos(:,2),orientation.updownSign*LheelPos(:,3)];
%             RheelPos=trialData.getMarkerData({['RHEE' orientation.foreaftAxis],['RHEE' orientation.updownAxis],['RHEE' orientation.sideAxis]});
%             RheelPos=[orientation.foreaftSign* RheelPos(:,1),orientation.sideSign*RheelPos(:,2),orientation.updownSign*RheelPos(:,3)];
            
            LheelPos = trialData.markerData.getDataAsVector({'LHEE'});
            RheelPos = trialData.markerData.getDataAsVector({'RHEE'});
            
        else
            disp(['No heel markers in ' file '. Using ankle markers instead to compute events.'])
            LheelPos=LanklePos;
            RheelPos=RanklePos;
        end
        fs_kin=trialData.markerData.sampFreq;
        [LHSevent,RHSevent,LTOevent,RTOevent] = getEventsFromToeAndHeel(LtoePos,LheelPos,RtoePos,RheelPos,fs_kin); %EVENTS from a mix of kinematics;
        
        LHSeventForce=false(length(LHSevent),1); %No force events, fill with logical 0's
        RHSeventForce=false(length(RHSevent),1);
        LTOeventForce=false(length(LTOevent),1);
        RTOeventForce=false(length(RTOevent),1); 
        
        LHSeventKin=kinLHS;
        RHSeventKin=kinRHS;
        LTOeventKin=kinLTO;
        RTOeventKin=kinRTO;
        
        t0=trialData.markerData.Time(1);        
        Ts=trialData.markerData.sampPeriod;
        
    else        
        upAxis=trialData.GRFData.orientation.updownAxis;
        upSign=trialData.GRFData.orientation.updownSign;
        FzL=upSign*trialData.GRFData.getDataAsVector(['LF',upAxis]);
        FzR=upSign*trialData.GRFData.getDataAsVector(['RF',upAxis]);
        
        %Sanity check: correct non-zeroed force-plates: 
        if mode(FzL)~=0
            disp(['Warning: Left z-axis forces in ' file ' have non-zero mode. Subtracting mode from force data before event detection']) 
            FzL=FzL-mode(FzL);
        end
        if mode(FzR)~=0
            disp(['Warning: Right z-axis forces in ' file ' have non-zero mode. Subtracting mode from force data before event detection']) 
            FzR=FzR-mode(FzR);
        end
        
        [LHSevent,RHSevent,LTOevent,RTOevent] = getEventsFromForces(FzL,FzR,trialData.GRFData.sampFreq);
        
        LHSeventForce=LHSevent; %Make a redundant copy to label as force events
        RHSeventForce=RHSevent;
        LTOeventForce=LTOevent;
        RTOeventForce=RTOevent;        
        
        t0=trialData.GRFData.Time(1);
        Ts=trialData.GRFData.sampPeriod;
        [LHSeventKin,RHSeventKin,LTOeventKin,RTOeventKin] = deal(false(trialData.GRFData.Length,1));
        
        
        % TO DO: use a method to re-sample kinematic events to be consistent
        % with forces.
        CF=trialData.GRFData.sampFreq/trialData.markerData.sampFreq; %correction factor
        LHSeventKin(round((find(kinLHS)-1)*CF+1))=true;
        RHSeventKin(round((find(kinRHS)-1)*CF+1))=true;
        LTOeventKin(round((find(kinLTO)-1)*CF+1))=true;
        RTOeventKin(round((find(kinRTO)-1)*CF+1))=true;

        if perceptualFlag == 1 % If your code is breaking, I am iterating so just comment this out

            infoLHSevent = find(LHSeventForce==1)./trialData.GRFData.sampFreq; %This has information on the time of each even so its possible to compare to datalog information
            infoRHSevent = find(RHSeventForce==1)./trialData.GRFData.sampFreq;

            [LHSstartCue, LHSstopCue, RHSstartCue, RHSstopCue] = getPerceptualEventsFromCues(trialData.metaData.datlog, infoLHSevent, infoRHSevent);

            % Actual frame number for the stride whose time is closer to
            % the perceptual trial start and end cues
            infoLHSevent = find(LHSeventForce==1); 
            infoRHSevent = find(RHSeventForce==1);
            frameLHSstartCue =  infoLHSevent(LHSstartCue ~= 0)';
            frameLHSendCue =  infoLHSevent(LHSstopCue ~= 0)';
            frameRHSstartCue =  infoRHSevent(RHSstartCue ~= 0)';
            frameRHSendCue =  infoRHSevent(RHSstopCue ~= 0)';

            % Initialize the matrices in zeros
            percStartCueL = zeros(1, length(LHSeventForce));
            percStartCueR = zeros(1, length(LHSeventForce));
            percEndCueL = zeros(1, length(LHSeventForce));
            percEndCueR = zeros(1, length(LHSeventForce));

            % Add logical value where there is an event related to the cues

            percStartCueL(frameLHSstartCue) = true;
            percStartCueR(frameRHSstartCue) = true;
            % percEndCueL(frameLHSendCue) = true; % Commented out by MGR
            % 01/25/2024 because I do not want exactly the time of the end
            % cue, but after the ramp down
            % percEndCueR(frameRHSendCue) = true;  

            for i=1:length(frameLHSendCue) % I want this frames to be shifted to 4 strides after given the ramp down after the perceptual task
                idx=find(LHSeventForce(frameLHSendCue(i):end)==1,4);
                frameLHSendCue(i) = frameLHSendCue(i)+idx(end)-1;
                idx2=find(RHSeventForce(frameRHSendCue(i):end)==1,4);
                frameRHSendCue(i) = frameRHSendCue(i)+idx2(end)-1;

            end
            percEndCueL(frameLHSendCue) = true;
            percEndCueR(frameRHSendCue) = true;  
        end
    end
end

if perceptualFlag == 1
    events=labTimeSeries(sparse([LHSevent,RHSevent,LTOevent,RTOevent,LHSeventForce,RHSeventForce,LTOeventForce,RTOeventForce,LHSeventKin,RHSeventKin,LTOeventKin,RTOeventKin,percStartCueL',percEndCueL',percStartCueR',percEndCueR'])...
    ,t0,Ts,{'LHS','RHS','LTO','RTO','forceLHS','forceRHS','forceLTO','forceRTO','kinLHS','kinRHS','kinLTO','kinRTO','percStartL','percEndL','percStartR','percEndR'});
else
    events=labTimeSeries(sparse([LHSevent,RHSevent,LTOevent,RTOevent,LHSeventForce,RHSeventForce,LTOeventForce,RTOeventForce,LHSeventKin,RHSeventKin,LTOeventKin,RTOeventKin])...
    ,t0,Ts,{'LHS','RHS','LTO','RTO','forceLHS','forceRHS','forceLTO','forceRTO','kinLHS','kinRHS','kinLTO','kinRTO'});
end

