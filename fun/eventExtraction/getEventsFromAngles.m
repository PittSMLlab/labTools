function [LHSevent,RHSevent,LTOevent,RTOevent] = getEventsFromAngles(trialData,angleData,orientation)

pad = 25; %this is the minimum number of samples two events can be apart
nsamples = trialData.markerData.Length;
[LHSevent,RHSevent,LTOevent,RTOevent]=deal(false(nsamples,1));

%Get angle traces
rdata = angleData.getDataAsVector({'RLimb'});
ldata = angleData.getDataAsVector({'LLimb'});

if strcmpi(trialData.metaData.type,'OG') || strcmpi(trialData.metaData.type,'NIM')
    %Get fore-aft hip positions
    newMarkerData = trialData.markerData.getDataAsVector({['RHIP' orientation.foreaftAxis],['LHIP' orientation.foreaftAxis]});
    rhip=newMarkerData(:,1);
    lhip=newMarkerData(:,2);
    
    avghip = (rhip+lhip)./2;
    
    %Get hip velocity
    HipVel = diff(avghip);
    
    %Clean up velocities to remove artifacts of marker drop-outs
    HipVel(abs(HipVel)>50) = 0;
    
    %Use hip velocity to determine when subject is walking
    midHipVel = nanmedian(abs(HipVel));
    walking = abs(HipVel)>0.5*midHipVel;
    % Eliminate walking or turn around phases shorter than 0.25 seconds
    [walking] = deleteShortPhases(walking,trialData.markerData.sampFreq,0.25);
    
    % split walking into individual bouts
    walkingSamples = find(walking);
    
    if ~isempty(walkingSamples)
        StartStop = [walkingSamples(1) walkingSamples(diff(walkingSamples)~=1)'...
            walkingSamples(find(diff(walkingSamples)~=1)+1)' walkingSamples(end)];
        StartStop = sort(StartStop);
    else
        warning('Subject was not walking during one of the overground trials');
        return
    end
else
     StartStop= [1 length(rdata)];
end


RightTO = [];
RightHS = [];
LeftHS = [];
LeftTO = [];

for i = 1:2:(length(StartStop))
    
    %find HS/TO for right leg
    %Finds local minimums and maximums.
    start = StartStop(i);
    stop = StartStop(i+1);
    
    if strcmpi(trialData.metaData.type,'OG') && median(HipVel(start:stop))>0 % in our lab, walking towards door
        % Reverse angles for walking towards lab door (this is to make angle
        % maximums HS and minimums TO, as they are when on treadmill)
        rdata(start:stop) = -rdata(start:stop);
        ldata(start:stop) = -ldata(start:stop);
    end
    
     if strcmpi(trialData.metaData.type,'NIM') && median(HipVel(start:stop))>0 % in our lab, walking towards door
        % Reverse angles for walking towards lab door (this is to make angle
        % maximums HS and minimums TO, as they are when on treadmill)
        rdata(start:stop) = -rdata(start:stop);
        ldata(start:stop) = -ldata(start:stop);
    end
    
    
    
    startHS = start;
    startTO  = start;
    
    %Find all maximum (HS)
    while (startHS<stop)
        RHS = FindKinHS(startHS,stop,rdata,pad);
        RightHS = [RightHS RHS];
        startHS = RHS+1;
    end
    
    %Find all minimum (TO)
    while (startTO<stop)
        RTO = FindKinTO(startTO,stop,rdata,pad);
        RightTO = [RightTO RTO];
        startTO = RTO+1;
    end
    
     RightTO(RightTO == start | RightTO == stop) = [];
     RightHS(RightHS == start | RightHS == stop) = [];
    
    %% find HS/TO for left leg
    startHS = start;
    startTO  = start;
    
    %find all maximum (HS)
    while (startHS<stop)
        LHS = FindKinHS(startHS,stop,ldata,pad);
        LeftHS = [LeftHS LHS];
        startHS = LHS+pad;
    end
    
    %find all minimum (TO)
    while (startTO<stop)
        LTO = FindKinTO(startTO,stop,ldata,pad);
        LeftTO = [LeftTO LTO];
        startTO = LTO+pad;
    end
    
     LeftTO(LeftTO == start | LeftTO == stop)=[];
     LeftHS(LeftHS == start | LeftHS == stop)=[];
end

% Remove any events due to marker dropouts
RightTO(rdata(RightTO)==0)=[];
RightHS(rdata(RightHS)==0)=[];
LeftTO(rdata(LeftTO)==0)=[];
LeftHS(rdata(LeftHS)==0)=[];

%% added by Yashar on 10/8/2019 to remove the end of OG walking based on
% global postion in the right Hip y direction

RightHip = trialData.markerData.getDataAsVector({'RHIPy'});
LeftHip = trialData.markerData.getDataAsVector({'LHIPy'});
body_yPos = (RightHip+LeftHip)/2;

isDataNewLab = 1;
if isDataNewLab == 1
    y_max = 4500;
    y_min = -2500;
else
    y_max = 7000;
    y_min = 0;
end
y_up_ind = find(body_yPos >= y_max);
y_low_ind = find(body_yPos <= y_min);


RightTO_up = ismember(RightTO,intersect(RightTO,y_up_ind));
RightTO(RightTO_up)=[];
RightHS_up = ismember(RightHS,intersect(RightHS,y_up_ind));
RightHS(RightHS_up)=[];
LeftTO_up = ismember(LeftTO,intersect(LeftTO,y_up_ind));
LeftTO(LeftTO_up)=[];
LeftHS_up = ismember(LeftHS,intersect(LeftHS,y_up_ind));
LeftHS(LeftHS_up)=[];



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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%