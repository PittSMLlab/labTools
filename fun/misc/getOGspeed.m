function OGspeed = getOGspeed(expData)
%GETOGSPEED Compute mean overground walking speed from hip marker data.
%
%   Identifies overground baseline trials in EXPDATA, uses hip marker
% velocity to isolate walking bouts, and returns the mean absolute
% walking speed in m/s. Subject data must be loaded before calling
% this function.
%
% Inputs:
%   expData - experimentData object with a condition named 'OG base'
%
% Outputs:
%   OGspeed - mean absolute overground walking speed (m/s)
%
% Toolbox Dependencies: None
%
% See also EXPERIMENTDATA, DELETESHORTPHASES.

%% Get overground baseline trial indices
OGtrials = cell2mat(expData.metaData.trialsInCondition( ...
    expData.metaData.getConditionIdxsFromName('OG base')));

speeds = [];

for tr = 1:length(OGtrials)            % for each OG trial, ...
    trialData   = expData.data{OGtrials(tr)};
    orientation = expData.data{OGtrials(tr)}.markerData.orientation;

    % get hip marker data in the fore-aft direction only
    newMarkerData = trialData.markerData.getDataAsVector( ...
        {['RHIP' orientation.foreaftAxis], ...
        ['LHIP' orientation.foreaftAxis]});
    rhip   = newMarkerData(:, 1);
    lhip   = newMarkerData(:, 2);
    avghip = (rhip + lhip) ./ 2;

    % compute hip velocity and remove dropout artifacts (>50 mm/frame)
    HipVel = diff(avghip);
    HipVel(abs(HipVel) > 50) = 0;

    % identify frames at or above median speed
    midHipVel = median(abs(HipVel), 'omitnan');
    walking   = abs(HipVel) > midHipVel;
    % eliminate phases shorter than 0.5 s (turn-around / artifacts)
    walking = deleteShortPhases( ...
        walking, trialData.markerData.sampFreq, 0.5);

    % split walking into individual bouts
    walkingSamples = find(walking);

    if ~isempty(walkingSamples)
        boutStarts = [walkingSamples(1), ...
            walkingSamples(find(diff(walkingSamples) ~= 1) + 1)'];
        boutStops  = [walkingSamples(diff(walkingSamples) ~= 1)', ...
            walkingSamples(end)];
    else
        warning(['Subject was not walking during one of the ' ...
            'overground trials']);
        return
    end

    % compute speed (m/s): hip displacement in mm ÷ 1000, time in s
    sampDiff = boutStops - boutStarts;
    distDiff = avghip(boutStops) - avghip(boutStarts);
    speeds   = [speeds; ...                             %#ok<AGROW>
        (distDiff / 1000) ./ ...
        (sampDiff' / trialData.markerData.sampFreq)];
end

OGspeed = mean(abs(speeds), 'omitnan');
end
