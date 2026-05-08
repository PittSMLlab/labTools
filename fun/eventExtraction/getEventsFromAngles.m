RightTO_low = ismember(RightTO,intersect(RightTO,y_low_ind));
RightTO(RightTO_low)=[];
RightHS_low = ismember(RightHS,intersect(RightHS,y_low_ind));
RightHS(RightHS_low)=[];
LeftTO_low = ismember(LeftTO,intersect(LeftTO,y_low_ind));
LeftTO(LeftTO_low)=[];
LeftHS_low = ismember(LeftHS,intersect(LeftHS,y_low_ind));
LeftHS(LeftHS_low)=[];
%%
% Remove any events that don't make sense
RightTO(rdata(RightTO)>5 | abs(rdata(RightTO))>40)=[];
RightHS(rdata(RightHS)<0 | abs(rdata(RightHS))>40)=[];
LeftTO(ldata(LeftTO)>5 | abs(ldata(LeftTO))>40)=[];
LeftHS(ldata(LeftHS)<0 | abs(ldata(LeftHS))>40)=[];

LHSevent(LeftHS)=true;
RTOevent(RightTO)=true;
RHSevent(RightHS)=true;
LTOevent(LeftTO)=true;

%[consistent] = checkEventConsistency(LHSevent,RHSevent,LTOevent,RTOevent);
%These functions are similar to the built-in 'findpeaks' matlab function.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function HS = FindKinHS(start,stop,ankdata,n)
% find max of limb angle trace

for i = start:stop
    if i == 1
        a = 1;
    elseif (i-n) < 1
        a = 1:i-1;
    else
        a = i-n:i-1;
    end
    if i == stop
        b = stop;
    elseif (i+n) > stop
        b = i+1:stop;
    else
        b = i+1:i+n;
    end
    if all(ankdata(i)>=ankdata(a)) && all(ankdata(i)>=ankdata(b)) %HH added "=" for the very rare case where the two max/min are the same value.
        break;
    end
end
HS = i;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function TO = FindKinTO(start,stop,ankdata,n)
% find mmin of limb angle trace

for i = start:stop
    if i == 1
        a = 1;
    elseif (i-n) < 1
        a = 1:i-1;
    else
        a = i-n:i-1;
    end
    if i == stop
        b = stop;
    elseif (i+n) > stop
        b = i+1:stop;
    else
        b = i+1:i+n;
    end
    if all(ankdata(i)<= ankdata(a)) && all(ankdata(i)<=ankdata(b))
        break;
    end
end
TO = i;
function [LHSevent, RHSevent, LTOevent, RTOevent] = ...
    getEventsFromAngles(trialData, angleData, orientation)

minInterEventSpacing = 25; % min inter-event spacing (samples)
nsamples             = trialData.markerData.Length;
[LHSevent, RHSevent, LTOevent, RTOevent] = deal(false(nsamples, 1));

%% Get angle traces
rdata = angleData.getDataAsVector({'RLimb'});
ldata = angleData.getDataAsVector({'LLimb'});

if strcmpi(trialData.metaData.type, 'OG') ...
        || strcmpi(trialData.metaData.type, 'NIM')
    % get fore-aft hip positions
    newMarkerData = trialData.markerData.getDataAsVector( ...
        {['RHIP' orientation.foreaftAxis], ...
         ['LHIP' orientation.foreaftAxis]});
    rhip = newMarkerData(:, 1);
    lhip = newMarkerData(:, 2);

    avghip = (rhip + lhip) ./ 2;

    % get hip velocity
    HipVel = diff(avghip);

    % clean up velocities to remove artifacts of marker drop-outs
    velArtifactThresh           = 50; % threshold above which velocity is a dropout artifact (mm/frame)
    HipVel(abs(HipVel) > velArtifactThresh) = 0;

    % use hip velocity to determine when subject is walking
    walkVelFrac = 0.5; % fraction of median absolute hip velocity to threshold walking
    midHipVel   = median(abs(HipVel), 'omitnan');
    walking     = abs(HipVel) > walkVelFrac * midHipVel;

    % eliminate walking or turn-around phases shorter than 0.25 seconds
    [walking] = deleteShortPhases(walking, trialData.markerData.sampFreq, 0.25); % min bout duration (s)

    % split walking into individual bouts
    walkingSamples = find(walking);

    if ~isempty(walkingSamples)
        StartStop = [walkingSamples(1) ...
            walkingSamples(diff(walkingSamples) ~= 1)' ...
            walkingSamples(find(diff(walkingSamples) ~= 1) + 1)' ...
            walkingSamples(end)];
        StartStop = sort(StartStop);
    else
        warning('Subject was not walking during one of the overground trials');
        return
    end
else
    StartStop = [1 length(rdata)];
end

RightTO = [];
RightHS = [];
LeftHS  = [];
LeftTO  = [];

for ii = 1:2:(length(StartStop))
    segStart = StartStop(ii);
    segStop  = StartStop(ii + 1);

    if strcmpi(trialData.metaData.type, 'OG') ...
            && median(HipVel(segStart:segStop)) > 0 % walking towards lab door
        % reverse angles so maxima = HS and minima = TO (as on treadmill)
        rdata(segStart:segStop) = -rdata(segStart:segStop);
        ldata(segStart:segStop) = -ldata(segStart:segStop);
    end

    if strcmpi(trialData.metaData.type, 'NIM') ...
            && median(HipVel(segStart:segStop)) > 0 % walking towards lab door
        % reverse angles so maxima = HS and minima = TO (as on treadmill)
        rdata(segStart:segStop) = -rdata(segStart:segStop);
        ldata(segStart:segStop) = -ldata(segStart:segStop);
    end

    startHS = segStart;
    startTO = segStart;

    %% Find HS and TO for right leg
    while (startHS < segStop)
        RHS     = FindKinHS(startHS, segStop, rdata, minInterEventSpacing);
        RightHS = [RightHS RHS]; %#ok<AGROW>
        startHS = RHS + 1;
    end

    while (startTO < segStop)
        RTO     = FindKinTO(startTO, segStop, rdata, minInterEventSpacing);
        RightTO = [RightTO RTO]; %#ok<AGROW>
        startTO = RTO + 1;
    end

    RightTO(RightTO == segStart | RightTO == segStop) = [];
    RightHS(RightHS == segStart | RightHS == segStop) = [];

    %% Find HS and TO for left leg
    startHS = segStart;
    startTO = segStart;

    while (startHS < segStop)
        LHS    = FindKinHS(startHS, segStop, ldata, minInterEventSpacing);
        LeftHS = [LeftHS LHS]; %#ok<AGROW>
        startHS = LHS + minInterEventSpacing;
    end

    while (startTO < segStop)
        LTO    = FindKinTO(startTO, segStop, ldata, minInterEventSpacing);
        LeftTO = [LeftTO LTO]; %#ok<AGROW>
        startTO = LTO + minInterEventSpacing;
    end

    LeftTO(LeftTO == segStart | LeftTO == segStop) = [];
    LeftHS(LeftHS == segStart | LeftHS == segStop) = [];
end

%% Remove events at marker dropout frames
RightTO(rdata(RightTO) == 0) = [];
RightHS(rdata(RightHS) == 0) = [];
LeftTO(rdata(LeftTO) == 0)   = [];
LeftHS(rdata(LeftHS) == 0)   = [];

%% Remove events outside valid y-position range
% added by Yashar on 10/8/2019 to remove end-of-OG-walking events based
% on global position in the right hip y direction
RightHip = trialData.markerData.getDataAsVector({'RHIPy'});
LeftHip  = trialData.markerData.getDataAsVector({'LHIPy'});
body_yPos = (RightHip + LeftHip) / 2;

% y-position limits (mm) depend on lab; Schenley lab has different range
if trialData.metaData.schenleyLab == 1
    SCHENLEY_Y_MAX =  4500; % Schenley lab walkway upper limit (mm)
    SCHENLEY_Y_MIN = -2500; % Schenley lab walkway lower limit (mm)
    y_max = SCHENLEY_Y_MAX;
    y_min = SCHENLEY_Y_MIN;
else
    OTHER_Y_MAX = 7000; % other lab walkway upper limit (mm)
    OTHER_Y_MIN =    0; % other lab walkway lower limit (mm)
    y_max = OTHER_Y_MAX;
    y_min = OTHER_Y_MIN;
end
y_up_ind  = find(body_yPos >= y_max);
y_low_ind = find(body_yPos <= y_min);

RightTO_up = ismember(RightTO, intersect(RightTO, y_up_ind));
RightTO(RightTO_up) = [];
RightHS_up = ismember(RightHS, intersect(RightHS, y_up_ind));
RightHS(RightHS_up) = [];
LeftTO_up  = ismember(LeftTO, intersect(LeftTO, y_up_ind));
LeftTO(LeftTO_up) = [];
LeftHS_up  = ismember(LeftHS, intersect(LeftHS, y_up_ind));
LeftHS(LeftHS_up) = [];

