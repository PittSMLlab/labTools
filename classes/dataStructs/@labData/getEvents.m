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

        % %Sanity check: correct non-zeroed force-plates: % Now we will be
        % doing this inside the even detection
        % if mode(FzL)~=0
        %     disp(['Warning: Left z-axis forces in ' file ' have non-zero mode. Subtracting mode from force data before event detection'])
        %     FzL=FzL-mode(FzL);
        % end
        % if mode(FzR)~=0
        %     disp(['Warning: Right z-axis forces in ' file ' have non-zero mode. Subtracting mode from force data before event detection'])
        %     FzR=FzR-mode(FzR);
        % end

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

        %%

        if perceptualFlag == 1 % If your code is breaking, I am iterating so just comment this out


            % timeLHS = find(LHSeventForce==1)./trialData.GRFData.sampFreq; timeRHS = find(RHSeventForce==1)./trialData.GRFData.sampFreq;
            % timeLTO = find(LTOeventForce==1)./trialData.GRFData.sampFreq;
            timeRTO = find(RTOeventForce==1)./trialData.GRFData.sampFreq; %This has information on the time of each event so its possible to compare to datalog information


            % [LHSstartCue, LHSstopCue, RHSstartCue, RHSstopCue] = getPerceptualEventsFromCues(trialData.metaData.datlog, infoLHSevent, infoRHSevent);

            % Actual frame number for the stride whose time is closer to
            % the perceptual trial start and end cues
            percStartCue = zeros(1, length(RTOeventForce));
            percEndCue = zeros(1, length(RTOeventForce));
            percEndRamp = zeros(1, length(RTOeventForce));

            % Grab auditory cues time from the datlog. This information has to be
            % offset following the synchronization process between datlogs and Nexus
            if sum(contains(fields(trialData.metaData.datlog), 'dataLogTimeOffsetBest'))>0
                startCue = trialData.metaData.datlog.audioCues.start + trialData.metaData.datlog.dataLogTimeOffsetBest;
                endCue = trialData.metaData.datlog.audioCues.stop + trialData.metaData.datlog.dataLogTimeOffsetBest;

                % Compare the start and stop cue times to the events data to
                % match the start and stop of perceptual trial (this will have the frame number)

                if ~isempty(startCue)
                    idxStrideScue = arrayfun(@(x) find((x-timeRTO) >= 0,1,'last'), startCue); % the controller for the experiments increases stride cound starting form RTO.
                    ... start cue should happen after updating both legs, so the RTO after the left leg speed was updated in the task
                        idxStrideEcue = arrayfun(@(x) find((x-timeRTO) >= 0,1,'last'), endCue);

                    % Add logical value where there is an event related to the cues
                    framesRTO = find(RTOeventForce==1);
                    idxFrameStart = framesRTO(idxStrideScue); percStartCue(idxFrameStart) = true;
                    idxFrameEnd = framesRTO(idxStrideEcue); percEndCue(idxFrameEnd) = true;

                    % Currently for Weber Perception I have a ramp down of 3
                    % strides which might change in the future. TODO: make it
                    % more robust such that this is only computed for Weber
                    % Study
                    idxFrameEndRamp = framesRTO(idxStrideEcue+3); percEndRamp(idxFrameEndRamp) = true;

                end
            else %proceed with caution because the relative times in matlab is not synchronized with nexus
                warning("Datalogs can't be synchronized with Nexus data");
            end
        end

    end
end


if perceptualFlag == 1
    events=labTimeSeries(sparse([LHSevent,RHSevent,LTOevent,RTOevent,LHSeventForce,RHSeventForce,LTOeventForce,RTOeventForce,LHSeventKin,RHSeventKin,LTOeventKin,RTOeventKin,percStartCue',percEndCue',percEndRamp'])...
        ,t0,Ts,{'LHS','RHS','LTO','RTO','forceLHS','forceRHS','forceLTO','forceRTO','kinLHS','kinRHS','kinLTO','kinRTO','percStartCue','percEndCue','percEndRamp'});
else
    events=labTimeSeries(sparse([LHSevent,RHSevent,LTOevent,RTOevent,LHSeventForce,RHSeventForce,LTOeventForce,RTOeventForce,LHSeventKin,RHSeventKin,LTOeventKin,RTOeventKin])...
        ,t0,Ts,{'LHS','RHS','LTO','RTO','forceLHS','forceRHS','forceLTO','forceRTO','kinLHS','kinRHS','kinLTO','kinRTO'});
end

end