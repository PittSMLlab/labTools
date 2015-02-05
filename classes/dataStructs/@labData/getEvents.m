function events = getEvents(trialData,angleData)

file=getSimpleFileName(trialData.metaData.rawDataFilename);

if isempty(trialData.markerData.orientation)
    warning('Assuming default orientation of axes for marker data.');
    orientation=orientationInfo([0,0,0],'x','y','z',1,1,1);
else
    orientation=trialData.markerData.orientation;
end

if strcmpi(trialData.metaData.type,'OG') %Overground Trial, use limb angles to calculate events
    [LHSevent,RHSevent,LTOevent,RTOevent] = getEventsFromAngles(trialData,angleData,orientation);
    t0=trialData.markerData.Time(1);
    Ts=trialData.markerData.sampPeriod;
else %Treadmill trial
    noForce=false;
    if isempty(trialData.GRFData) || isempty(trialData.GRFData.Data) %No force data
        noForce=true;
    end
    if noForce
        disp(['No ground reaction forces data in ' file '. Using marker data to compute events.'])
        
        LtoePos=trialData.getMarkerData({['LTOE' orientation.foreaftAxis],['LTOE' orientation.updownAxis],['LTOE' orientation.sideAxis]});
        LtoePos=[orientation.foreaftSign* LtoePos(:,1),orientation.updownSign*LtoePos(:,2),orientation.sideSign*LtoePos(:,3)];
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
            disp(['No heel markers in ' file '. Using ankle markers instead to compute events.'])
            LheelPos=LanklePos;
            RheelPos=RanklePos;
        end
        fs_kin=trialData.markerData.sampFreq;
        [LHSevent,RHSevent,LTOevent,RTOevent] = getEventsFromToeAndHeel(LtoePos,LheelPos,RtoePos,RheelPos,fs_kin); %EVENTS from a mix of kinematics;
        t0=trialData.markerData.Time(1);
        Ts=trialData.markerData.sampPeriod;
    else        
        upAxis=trialData.GRFData.orientation.updownAxis;
        upSign=trialData.GRFData.orientation.updownSign;
        FzL=upSign*trialData.getForce('L',upAxis);
        FzR=upSign*trialData.getForce('R',upAxis);
        
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
        t0=trialData.GRFData.Time(1);
        Ts=trialData.GRFData.sampPeriod;
    end
end

events=labTimeSeries(sparse([LHSevent,RHSevent,LTOevent,RTOevent]),t0,Ts,{'LHS','RHS','LTO','RTO'});

