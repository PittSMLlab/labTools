function beltSpeedReadData = getBeltSpeedsFromFootMarkers(trialData,events)
%GETBELTSPEEDSFROMFOOTMARKERS Estimate belt speeds from heel markers.
%
%   beltSpeedReadData = getBeltSpeedsFromFootMarkers(trialData, events)
% estimates each belt's speed from the fore-aft heel marker speed. For
% every heel strike, the stance-leg heel speed is the median over that
% leg's single stance (from the contralateral toe-off to the next
% contralateral heel strike); that value is assigned to the samples from
% the heel strike to the ipsilateral toe-off. Strides with an incomplete
% event sequence stay NaN. If either heel marker is missing, a warning is
% issued and [] is returned.
%
% Inputs:
%   trialData - rawTrialData with markerData (heel markers LHEE and RHEE)
%               and metaData.rawDataFilename
%   events    - labTimeSeries with LHS, RHS, LTO, RTO event labels
%
% Outputs:
%   beltSpeedReadData - labTimeSeries with labels 'L' and 'R' sampled at
%                       the event time base (NaN where not estimated), or
%                       [] if the heel markers are missing
%
% Toolbox Dependencies: None
%
% See also LABTIMESERIES, LABDATA/GETEVENTS.

LHS = events.getDataAsVector('LHS');
LTO = events.getDataAsVector('LTO');
RHS = events.getDataAsVector('RHS');
RTO = events.getDataAsVector('RTO');

if trialData.markerData.isaLabel('LHEEx') && ...
        trialData.markerData.isaLabel('RHEEx')
    LHEEspeed = [0;trialData.markerData.sampFreq * ...
        diff(trialData.markerData.getDataAsVector(['LHEE' ...
        trialData.markerData.orientation.foreaftAxis]))];
    RHEEspeed = [0;trialData.markerData.sampFreq * ...
        diff(trialData.markerData.getDataAsVector(['RHEE' ...
        trialData.markerData.orientation.foreaftAxis]))];
else
    slashes = find(trialData.metaData.rawDataFilename == '\' | ...
        trialData.metaData.rawDataFilename == '/');
    file    = trialData.metaData.rawDataFilename((slashes(end)+1):end);
    warning([ ...
        'There are missing heel markers. Belt speed read Data not ' ...
        'calculated for ',file]);
    beltSpeedReadData = [];
    return
end
beltSpeedReadData = labTimeSeries(NaN(size(events.Data,1),2), ...
    events.Time(1),events.sampPeriod,{'L','R'});

speed  = labTimeSeries([LHEEspeed,RHEEspeed], ...
    trialData.markerData.Time(1),trialData.markerData.sampPeriod,{'L','R'});
idxLHS = find(LHS);
for st = 1:length(idxLHS)
    idxNextLTO = find(LTO & events.Time > events.Time(idxLHS(st)),1);
    idxNextRTO = find(RTO & events.Time > events.Time(idxLHS(st)),1);
    idxNextRHS = find(RHS & events.Time > events.Time(idxLHS(st)),1);
    if ~isempty(idxNextLTO) && ~isempty(idxNextRTO) && ...
            ~isempty(idxNextRHS) && ...
            events.Time(idxNextRHS) > events.Time(idxNextRTO)
        aux = speed.split(events.Time(idxNextRTO),events.Time(idxNextRHS));
        %if ~isempty( ...
        %    aux.Data)
        % To avoid 'not a labeled time series' message when the events
        % fall within two consecutive samples
        %Only considering median absolute speed on single stance phase
        beltSpeedReadData.Data(idxLHS(st):idxNextLTO,1) = ...
            median(aux.getDataAsVector('L'));
        %else
        %    beltSpeedReadData.Data(idxLHS(i):idxNextLTO,1)=NaN;
        %end
    end
end
idxRHS = find(RHS);
for st = 1:length(idxRHS)
    idxNextRTO = find(RTO & events.Time > events.Time(idxRHS(st)),1);
    idxNextLTO = find(LTO & events.Time > events.Time(idxRHS(st)),1);
    idxNextLHS = find(LHS & events.Time > events.Time(idxRHS(st)),1);
    if ~isempty(idxNextRTO) && ~isempty(idxNextLTO) && ...
            ~isempty(idxNextLHS) && ...
            events.Time(idxNextLHS) > events.Time(idxNextLTO)
        aux = speed.split(events.Time(idxNextLTO),events.Time(idxNextLHS));
        %if ~isempty(aux.Data)
        %Only considering median absolute speed on single stance phase
        beltSpeedReadData.Data(idxRHS(st):idxNextRTO,2) = ...
            median(aux.getDataAsVector('R'));
        %else
        %    beltSpeedReadData.Data(idxRHS(i):idxNextRTO,2)=NaN;
        %end
    end
end
