function OGspeed = getOGspeed(expData)
%must load subject before running function

%detemine overground baseline trials
OGtrials=cell2mat(expData.metaData.trialsInCondition(expData.metaData.getConditionIdxsFromName('OG base')))

speeds=[];

for i=1:length(OGtrials) %loop through each og trail
    
    trialData=expData.data{OGtrials(i)};
    orientation=expData.data{OGtrials(i)}.markerData.orientation;
    
    %get hip marker data (only in fore-aft direction)
    newMarkerData = trialData.markerData.getDataAsVector({['RHIP' orientation.foreaftAxis],['LHIP' orientation.foreaftAxis]});
    rhip=newMarkerData(:,1);
    lhip=newMarkerData(:,2);
    avghip = (rhip+lhip)./2;

    %Get hip velocity
    HipVel = diff(avghip);

    %Clean up velocities to remove artifacts of marker drop-outs
    HipVel(abs(HipVel)>50) = 0;

    %Use hip velocity to determine when subject is up to median speed
    midHipVel = nanmedian(abs(HipVel));
    walking = abs(HipVel)>midHipVel;
    % Eliminate walking or turn around phases shorter than 0.5 seconds
    [walking] = deleteShortPhases(walking,trialData.markerData.sampFreq,0.5);

    % split walking into individual bouts
    walkingSamples = find(walking);

    %find samples when subject starts and stops walking
    if ~isempty(walkingSamples)
        start= [walkingSamples(1) walkingSamples(find(diff(walkingSamples)~=1)+1)'];
        stop = [walkingSamples(diff(walkingSamples)~=1)' walkingSamples(end)];
    else
        warning('Subject was not walking during one of the overground trials');
        return
    end
    
    %find walking speed in m/s
    sampDiff=stop-start;
    distanceDiff=avghip(stop)-avghip(start); 
    speeds= [speeds; (distanceDiff/1000)./(sampDiff'/trialData.markerData.sampFreq)] %distance divided by 1000 to convert to m, samples converted to seconds by dividing by samp freq
end

OGspeed=nanmean(abs(speeds));
