function out = calcParameters(trialData,subData,eventClass,initEventSide,parameterClasses)
%out = calcParameters(trialData,subData,eventClass,initEventSide)
%INPUT:
%trialData: processedTrialData object
%subData: subjectData object
%eventClass: string containing the prefix to an existing event class: {'force','kin',''} (Optional, defaults to '')
%initEventSide: 'L' or 'R'. Optional, defaults to trialData.metaData.refLeg
%
%To add a new parameter, it must be added to the paramLabels cell and the
%label must be the same as the variable name the data is saved to within
%the code. (ex: in paramlabels: 'swingTimeSlow', in code: swingTimeSlow(t)=timeSHS2-timeSTO;)
%note: if adding a slow and fast version of one parameter, make sure 'Fast'
%and 'Slow' appear at the end of the respective parameter names. See
%existing parameter names as an example.
[file]= getSimpleFileName(trialData.metaData.rawDataFilename);

if nargin<3 || isempty(eventClass)
    eventClass='';
end
if nargin<5 || isempty(parameterClasses)
    parameterClasses={'basic','temporal','spatial','rawEMG','procEMG','force'};
elseif ischar(parameterClasses)
    parameterClasses={parameterClasses};
end

%% Separate into strides & identify events on each
% one "stride" contains the events: SHS,FTO,FHS,STO,SHS2,FTO2
if nargin<4 || isempty(initEventSide)
    refLeg=trialData.metaData.refLeg;
else
    refLeg=initEventSide; 
end

if refLeg == 'R'
    s = 'R';    f = 'L';
elseif refLeg == 'L'
    s = 'L';    f = 'R';
else
    ME=MException('MakeParameters:refLegError','the refLeg/initEventSide property of metaData must be either ''L'' or ''R''.');
    throw(ME);
end

%Define the events that will be used for all further computations
eventTypes={[s,'HS'],[f,'TO'],[f,'HS'],[s,'TO']};
eventTypes=strcat(eventClass,eventTypes);

eventLables={'SHS','FTO','FHS','STO'};
triggerEvent=eventTypes{1};

%Initialize:
[numStrides,initTime,endTime]=getStrideInfo(trialData,triggerEvent);
if numStrides==0;    
    disp(['Warning: No strides detected in ',file])
    out=parameterSeries([],{},[],{}); %TODO: Perhaps the reasonable thing is to initializate the parameterSeries with all params and 0 strides instead of empty
    return
end
stridedProcEMG=cell(numStrides,1);
stridedRawEMG=cell(numStrides,1);
%stridedMarkerData=cell(max(strideIdxs),1);
stridedEventData=cell(numStrides,1);

%Stride:
%steppedDataArray=separateIntoStrides(in,triggerEvent); %This is 
%computationally expensive to do: it calls the split function for every 
%labTS in trialData. If we only care about some fields, we should try 
%calling split independently for those TSs.
eventTimes=nan(numStrides,length(eventTypes));
eventTimes2=nan(numStrides,length(eventTypes));
for i=1:numStrides
    if ~isempty(trialData.procEMGData)
        stridedProcEMG{i}=trialData.('procEMGData').split(initTime(i),endTime(i));
        stridedRawEMG{i}=trialData.('EMGData').split(initTime(i),endTime(i));
    end
    %stridedMarkerData{i}=in.('markerData').split(initTime(i),endTime(i));
    stridedEventData{i}=trialData.('gaitEvents').split(initTime(i),endTime(i));
    for j=1:length(eventTypes)
        aux=stridedEventData{i}.getDataAsVector(eventTypes{j});
        aux=find(aux,2,'first'); %Finding next two events of the type %HH: it is pointless to find the next two events, since find will still return a value even if it only finds one.
        if ~isempty(aux) %HH: maybe instead we should check if aux is has a length of 2
            eventTimes(i,j)=stridedEventData{i}.Time(aux(1));
        end
    end
end
eventTimes2=[eventTimes(2:end,:);nan(1,size(eventTimes,2))]; %This could be improved by trying to find if there exist any other events after the end of the last stride.
for j=1:length(eventTypes)
    strideEvents.(['t' upper(eventLables{j})])=eventTimes(:,j); %generates a structure of tSHS, tFTO, etc
    strideEvents.(['t' upper(eventLables{j}) '2'])=eventTimes2(:,j);
end

%% Compute params
extendedEventTimes=[eventTimes, eventTimes2(:,1:2)]; %times of SHS, FTO, FHS, FTO, SHS2, FTO2
times=nanmean(extendedEventTimes,2); %This is an average of the times of SHS, FTO, FHS, FTO, SHS2, FTO2 (same as old code), IF available.
out=parameterSeries(zeros(length(times),0),{},times,{});
%initialize the bad/good flag
strideDuration=diff(extendedEventTimes(:,[1,5]),1,2);
bad=any(isnan(extendedEventTimes),2) | any(diff(extendedEventTimes,1,2)<0,2) | (strideDuration >1.5*nanmedian(strideDuration)) | (strideDuration<.4) | (strideDuration>2.5); %Checking for missing events, negative duration phases (wrong event order), too long or too short strides

%% basic parameters to save & initialize parameterSeries
if any(strcmpi(parameterClasses,'basic'))

%initialize trial number
try
    trial=str2double(trialData.metaData.rawDataFilename(end-1:end)); %Need to FIX, but this data is not currently available on trialMetaData
catch
    warning('calcParametersNew:gettingTrialNumber','Could not determine trial number from metaData, setting to NaN.');
    trial=nan;
end
trial=repmat(trial,length(bad),1);

%Initialize initTime
initTime=extendedEventTimes(:,1); %SHS
finalTime=extendedEventTimes(:,6); %FTO2

%Initialize parameterSeries
data=[bad,~bad,trial,initTime,finalTime];
labels={'bad','good','trial','initTime','finalTime'};
description={'True if events are missing, disordered or if stride time is too long or too short.', 'Opposite of bad.','Original trial number for stride','Time of initial event (SHS), with respect to trial beginning.','Time of final event (FTO2), with respect to trial beginning.'};
basic=parameterSeries(data,labels,times,description);  
out=cat(out,basic);
end

%% Temporal:
if any(strcmpi(parameterClasses,'temporal'))
[temp] = computeTemporalParameters(strideEvents);
out=cat(out,temp);
end

%% Spatial:
if any(strcmpi(parameterClasses,'spatial')) && ~isempty(trialData.markerData) && (numel(trialData.markerData.labels)~=0)
[spat] = computeSpatialParameters(strideEvents,trialData.markerData,trialData.angleData,s);
out=cat(out,spat);
end

%% EMG:
if any(strcmpi(parameterClasses,'procEMG')) && ~isempty(trialData.procEMGData)
    [emg] = computeEMGParameters(strideEvents,stridedProcEMG,s);
    out=cat(out,emg);
end
if any(strcmpi(parameterClasses,'rawEMG')) && ~isempty(trialData.rawEMGData)
    rawEMG = computeEMGParameters(strideEvents,stridedRawEMG,s);
    %Renaming params & descriptions:
    nLabels=strcat('RAW',rawEMG.labels);
    nDescription=regexprep(rawEMG.description,'proc','raw');
    rawEMG=parameterSeries(rawEMG.Data,nLabels,[],nDescription);
    out=cat(out,rawEMG);
end

%% Force
if any(strcmpi(parameterClasses,'force')) && ~isempty(trialData.GRFData)
    [force] = computeForceParameters(strideEvents,trialData.GRFData,s, f, subData.weight, trialData.metaData, trialData.markerData);

    if ~isempty(force.Data)
        out=cat(out,force);
    end
end

%% Compute an updated bad/good flag based on computed parameters & finding outliers (only if basic parameters are being computed)
if any(strcmpi(parameterClasses,'basic'))
%badStart=bad; %make a copy to compare at the end
%TODO: make this process generalized so that it can filter any parameter
%TODO: make this into a method of parameterSeries or labTimeSeries
%should also consider a different method of filtering...
%paramsToFilter={'stepLengthSlow','stepLengthFast','alphaSlow','alphaFast','alphaTemp','betaSlow','betaFast'};
%Pablo block-commented on MAr 13th 2017, because this part of code was
%doing nothing anyway (only defined the variable named 'aux', which wasn't
%used downstream
% for i=1:length(paramsToFilter)
%     aux=out.getDataAsVector(paramsToFilter{i});
%     if ~isempty(aux) %In case any of these parameters does not exist
%     aux=aux-runAvg(aux,50); % remove effects of adaptation
%     % mark strides bad if values for SL or alpha are larger than 3x the
%     % interquartile range away from the median.
%     %Criteria 1: anything outside +-3.5 interquartile ranges
%     %     bad(abs(aux-nanmedian(aux))>3.5*iqr(aux))=true;
% 
%     %Criteria 2: anything outside +-3.5 interquartile ranges, except the first
%     %5 strides of any trial.
%     % inds=find(abs(aux-nanmedian(aux))>3.5*iqr(aux));
%     %    inds=inds(inds>5);
%     %    bad(inds)=true;
%     end
%     
% end
%Remove outliers according to new values of 'bad':
%[~,idxs]=out.isaParameter({'bad','good'});
%out.Data(:,idxs)=[bad,~bad];
%outlierStrides=find(bad & ~badStart);
%disp(['Removed ' num2str(numel(outlierStrides)) ' outlier(s) from ' file ' at stride(s) ' num2str(outlierStrides')])  

%----------REMOVE STOP/START STRIDES-------------
badStart=bad; %make a copy to compare at the end
%Criteria 3: if on TM trials singleStanceSpeed on BOTH legs is less than .05m/s
%(stopping/starting trials)
if strcmp(trialData.metaData.type,'TM')
    aux=out.getDataAsVector({'singleStanceSpeedFastAbs','singleStanceSpeedSlowAbs'});
    if ~isempty(aux)
        bad(abs(aux(:,1))<50 & abs(aux(:,2))<50)=true; %Moving too slow
    end
end

%Criteria 4: if on OG trials any swingRange< 50mm or if equivalent speed is too small %This may be problematic
%on kids!
if strcmp(trialData.metaData.type,'OG')
    %To be implemented
end

%Remove outliers according to new values of 'bad':
[~,idxs]=out.isaParameter({'bad','good'});
out.Data(:,idxs)=[bad,~bad];
outlierStrides=find(bad & ~badStart);
disp(['Removed ' num2str(numel(outlierStrides)) ' stopping/starting strides from ' file ' at stride(s) ' num2str(outlierStrides')])  

% Issue bad strides warning
if any(bad)    
    disp(['Warning: ' num2str(sum(bad)) ' strides of ',file, ' were labeled as bad'])    
end

end

%% Use 'bad' as mask (necessary?)
%out.Data(bad==1,6:end)=NaN; %First 5 parameters are kept for ID purposes: bad, good, trial, initTime, finalTime
