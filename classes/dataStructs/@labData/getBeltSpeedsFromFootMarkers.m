function beltSpeedReadData = getBeltSpeedsFromFootMarkers(trialData,events)

LHS=events.getDataAsVector('LHS');
LTO=events.getDataAsVector('LTO');
RHS=events.getDataAsVector('RHS');
RTO=events.getDataAsVector('RTO');

if trialData.markerData.isaLabel('LHEEx') && trialData.markerData.isaLabel('RHEEx')
    LHEEspeed=[0;trialData.markerData.sampFreq * diff(trialData.markerData.getDataAsVector(['LHEE' trialData.markerData.orientation.foreaftAxis]))];
    RHEEspeed=[0;trialData.markerData.sampFreq * diff(trialData.markerData.getDataAsVector(['RHEE' trialData.markerData.orientation.foreaftAxis]))];
else
    slashes=find(trialData.metaData.rawDataFilename=='\' | trialData.metaData.rawDataFilename=='/');
    file=trialData.metaData.rawDataFilename((slashes(end)+1):end);
    warning(['There are missing heel markers. Belt speed read Data not calculated for ',file]);
    beltSpeedReadData=[];
    return
end
beltSpeedReadData=labTimeSeries(NaN(size(events.Data,1),2),events.Time(1),events.sampPeriod,{'L','R'});

speed=labTimeSeries([LHEEspeed,RHEEspeed],trialData.markerData.Time(1),trialData.markerData.sampPeriod,{'L','R'});
idxLHS=find(LHS);
for i=1:length(idxLHS)
    idxNextLTO=find(LTO & events.Time>events.Time(idxLHS(i)),1);
    idxNextRTO=find(RTO & events.Time>events.Time(idxLHS(i)),1);
    idxNextRHS=find(RHS & events.Time>events.Time(idxLHS(i)),1);
    if ~isempty(idxNextLTO) && ~isempty(idxNextRTO) && ~isempty(idxNextRHS)
        beltSpeedReadData.Data(idxLHS(i):idxNextLTO,1)=median(speed.split(events.Time(idxNextRTO),events.Time(idxNextRHS)).getDataAsVector('L')); %Only considering median absolute speed on single stance phase
    end
end
idxRHS=find(RHS);
for i=1:length(idxRHS)
    idxNextRTO=find(RTO & events.Time>events.Time(idxRHS(i)),1);
    idxNextLTO=find(LTO & events.Time>events.Time(idxRHS(i)),1);
    idxNextLHS=find(LHS & events.Time>events.Time(idxRHS(i)),1);
    if ~isempty(idxNextRTO) && ~isempty(idxNextLTO) && ~isempty(idxNextLHS)
        beltSpeedReadData.Data(idxRHS(i):idxNextRTO,2)=median(speed.split(events.Time(idxNextLTO),events.Time(idxNextLHS)).getDataAsVector('R')); %Only considering median absolute speed on single stance phase
    end
end
