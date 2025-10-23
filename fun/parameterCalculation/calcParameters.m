function out = calcParameters(trialData,subData,eventClass, ...
    initEventSide,parameterClasses)
%CALCPARAMETERS calculate stride-by-stride parameters for later analysis
%
%INPUTS:
%trialData: 'processedTrialData' object
%subData: 'subjectData' object
%eventClass (optional): string containing the event class prefix:
%   {'force','kin',''} (default: '', OG: kinematics, TM: forces)
%initEventSide (optional): 'L' or 'R' (default: trialData.metaData.refLeg)
%
%To add a new parameter, update the 'paramLabels' cell and ensure the label
%is the same as the variable name where the data assigned in the code.
%(e.g., in 'paramlabels': 'swingTimeSlow',
%in code: swingTimeSlow(t) = timeSHS2 - timeSTO;)
%
%NOTE: if adding a slow and fast version of a parameter, make sure 'Fast'
%and 'Slow' appear at the end of the respective parameter names. See
%existing parameter names as an example.

file = getSimpleFileName(trialData.metaData.rawDataFilename);

% if fewer than three input arguments or no 'eventClass' input, ...
if nargin < 3 || isempty(eventClass)
    eventClass = '';                        % set to default value
end
% if fewer than four input arguments or no 'initEventSide' input, ...
if nargin < 4 || isempty(initEventSide)
    refLeg = trialData.metaData.refLeg;     % retrieve from trial meta data
else                                        % otherwise, ...
    refLeg = initEventSide;                 % use provided input argument
end
% if fewer than five input arguments or no 'parameterClasses' input, ...
if nargin < 5 || isempty(parameterClasses)
    parameterClasses = {'basic','temporal','spatial','rawEMG', ...
        'procEMG','force'};                 % compute default parameters
elseif ischar(parameterClasses)             % otherwise, ...
    parameterClasses = {parameterClasses};  % compute requested parameters
end

%% Separate Data by Stride & Identify Gait Events for Each Stride
% one 'stride' contains the events: SHS, FTO, FHS, STO, SHS2, FTO2
if refLeg == 'R'            % if reference leg is right, ...
    s = 'R';                % set slow leg to right
    f = 'L';                % TODO: substitute with 'getOtherLeg()'
elseif refLeg == 'L'        % if reference leg is left, ...
    s = 'L';                % set slow leg to left
    f = 'R';                % TODO: substitute with 'getOtherLeg()'
else                        % otherwise, ...
    ME = MException('MakeParameters:refLegError', ...
        ['the refLeg/initEventSide property of metaData must be ' ...
        'either ''L'' or ''R''.']);
    throw(ME);
end

% define the events that will be used for all further computations
eventTypes = {[s 'HS'],[f 'TO'],[f 'HS'],[s 'TO']};
eventTypes = strcat(eventClass,eventTypes);
eventLabels = {'SHS','FTO','FHS','STO'};
triggerEvent = eventTypes{1};

% initialize stride information variables
[numStrides,initTime,endTime] = getStrideInfo(trialData,triggerEvent);
% arrayedEvents = trialData.getArrayedEvents(eventTypes);
if numStrides == 0          % if there are no strides in the trial, ...
    % TODO: consider initializing 'parameterSeries' object with all
    % parameters and zero strides instead of as empty
    disp(['Warning: No strides detected in ' file]);    % display warning
    out = parameterSeries([],{},[],{}); % output empty 'parameterSeries'
    return;
end
stridedEventData = cell(numStrides,1);
stridedAngleData = cell(numStrides,1);

% extract binned angle data and stride-by-stride gait event times
eventTimes = nan(numStrides,length(eventTypes));
for st = 1:numStrides                       % for each stride in trial, ...
    % below conditional added by Digna de Kam to bin angle data
    if ~isempty(trialData.angleData)        % if angle data present, ...
        stridedAngleData{st} = ...            retrieve binned data
            trialData.angleData.split(initTime(st),endTime(st));
    end

    % stridedMarkerData{st} = in.('markerData').split(initTime(st),endTime(st));
    stridedEventData{st} = ...
        trialData.gaitEvents.split(initTime(st),endTime(st));
    for ev = 1:length(eventTypes)           % for each gait event type, ...
        aux = stridedEventData{st}.getDataAsVector(eventTypes{ev});
        % find next two events of the type
        % HH: it is pointless to find the next two events, since find will
        % still return a value even if it only finds one.
        aux = find(aux,2,'first');
        % HH: maybe instead we should check if aux has a length of two
        if ~isempty(aux)                    % if data present, ...
            eventTimes(st,ev) = stridedEventData{st}.Time(aux(1));
        end
    end
end
% TODO: improve by searching for any remaining events after the last stride
eventTimes2 = [eventTimes(2:end,:); nan(1,size(eventTimes,2))];
for ev = 1:length(eventTypes)               % for each gait event type, ...
    % generate a structure of 'tSHS', 'tFTO', etc.
    strideEvents.(['t' upper(eventLabels{ev})]) = eventTimes(:,ev);
    strideEvents.(['t' upper(eventLabels{ev}) '2']) = eventTimes2(:,ev);
end

%% Compute Parameters
% time of the SHS, FTO, FHS, FTO, SHS2, and FTO2 events (in that order)
extendedEventTimes = [eventTimes eventTimes2(:,1:2)];
% average all gait event times if available
times = mean(extendedEventTimes,2,'omitnan');
% initialize output 'parameterSeries' object
out = parameterSeries(zeros(length(times),0),{},times,{});
% compute duration (seconds) of stride as time difference between SHS2, SHS
strideDuration = diff(extendedEventTimes(:,[1 5]),1,2);
% five criteria to determine whether a stride is 'bad':
%   1. any event times are 'NaN' (i.e., missing gait event)
%   2. difference between any two consecutive gait event times is negative
%   3. stride duration > 1.5 * median stride duration of the trial
%   4. stride duration < 0.4 seconds (i.e., stride too short)
%   5. stride duration > 2.5 seconds (i.e., stride too long)
% TODO: NWB found that 2.5 seconds may be too stringent for slower older
% adult walkers and 1.5 * median may be a sufficient threshold to exclude
% outliers (especially in overground trials); consider removing criterion
bad = any(isnan(extendedEventTimes),2) | ...
    any(diff(extendedEventTimes,1,2) < 0,2) | ...
    (strideDuration > 1.5*median(strideDuration,'omitnan')) | ...
    (strideDuration < 0.4) | (strideDuration > 2.5);

%% Extract Basic Parameters & Save to Output 'parameterSeries' Object
if any(strcmpi(parameterClasses,'basic'))   % if adding 'basic' params, ...
    try                                     % try initializing trial number
        % need to FIX, but data is currently unavailable on 'trialMetaData'
        trial = str2double(trialData.metaData.rawDataFilename(end-1:end));
    catch
        warning('calcParametersNew:gettingTrialNumber',['Could not ' ...
            'determine trial number from metaData, setting to NaN.']);
        trial = nan;                        % set trial to 'NaN'
    end
    trial = repmat(trial,length(bad),1);    % repeat number for each stride

    initTime = extendedEventTimes(:,1);     % initial times (all SHS times)
    finalTime = extendedEventTimes(:,6);    % finale times (all FTO2 times)

    if strcmp(eventClass,'')                % if default event method, ...
        % determine type of event detection used for this trial
        Event = full(trialData.gaitEvents.Data);
        if isequal(Event(:,1),Event(:,5))
            eventType = 2 * ones(length(finalTime),1);  % use forces
        elseif isequal(Event(:,1),Event(:,9))
            eventType = 1 * ones(length(finalTime),1);  % use kinematics
        end
    elseif strcmp(eventClass,'kin')         % if using kinematics, ...
        eventType = 1 * ones(length(finalTime),1);      % set to '1'
    elseif strcmp(eventClass,'force')       % if using forces, ...
        eventType = 2 * ones(length(finalTime),1);      % set to '2'
    end

    % add 'basic' parameters to output 'parameterSeries' object
    data = [eventType bad ~bad trial initTime finalTime];
    labels = {'eventType','bad','good','trial','initTime','finalTime'};
    description = {'1 kinematics, 2 forces', ...
        'True if events are missing, disordered or if stride time is too long or too short.', ...
        'Opposite of bad.', ...
        'Original trial number for stride', ...
        'Time of initial event (SHS), with respect to trial beginning.', ...
        'Time of final event (FTO2), with respect to trial beginning.'};
    basic = parameterSeries(data,labels,times,description);
    out = cat(out,basic);
end

%% Extract Temporal Parameters
if any(strcmpi(parameterClasses,'temporal'))
    temp = computeTemporalParameters(strideEvents);
    out = cat(out,temp);    % concatentate temporal parameters to existing
end

%% Extract Spatial Parameters
if any(strcmpi(parameterClasses,'spatial')) && ...
        ~isempty(trialData.markerData) && ...
        (numel(trialData.markerData.labels) ~= 0)
    spat = computeSpatialParameters(strideEvents,trialData.markerData, ...
        trialData.angleData,s);
    out = cat(out,spat);    % concatentate spatial parameters to existing
end

%% Extract Muscle Activity (EMG) Parameters
if any(strcmpi(parameterClasses,'rawEMG')) && ~isempty(trialData.EMGData)
    EMG_alt = computeEMGParameters(trialData.EMGData, ...
        trialData.gaitEvents,s,eventTypes); % classic way
    out = cat(out,EMG_alt);     % concatentate EMG parameters to existing
end

%% Extract Angles Parameters
if ~isempty(trialData.angleData)            % if angle data is present, ...
    angles = computeAngleParameters(trialData.angleData, ...
        trialData.gaitEvents,s,eventTypes);
    out = cat(out,angles);      % concatentate angle parameters to existing
end

%% Extract (Treadmill) Force Parameters
if any(strcmpi(parameterClasses,'force')) && ~isempty(trialData.GRFData)
    force = computeForceParameters(strideEvents,trialData.GRFData,s,f, ...
        subData.weight,trialData.metaData,trialData.markerData,subData);
    if ~isempty(force.Data)     % if output force data not empty, ...
        out = cat(out,force);   % concatentate force parameters to existing
    end
end

%% Extract (Overground) Force Parameters
% If you encounter a bug with a line of code in this section (e.g.,
% indexing array out of bounds), comment it out, which will prevent the
% overground forces from being processed and output.

% only compute these parameters if there are overground force recordings
OG_names = {'FP4Fz','FP5Fz','FP6Fz','FP7Fz'};
OG_idx = contains(trialData.GRFData.labels,OG_names);

if sum(OG_idx) == length(OG_names) | (max(trialData.GRFData.Data(:,OG_idx)) - min(trialData.GRFData.Data(:,OG_idx))) > 100
    % there are differences in forces throughout the experiment and not a
    % constant value or NaNs
    force_OGFP.Data = computeForceParameters_OGFP( ...
        strideEvents,trialData.GRFData,s,f,subData.weight,trialData, ...
        trialData.markerData);
    if ~isempty(force_OGFP.Data)
        out = cat(out,force_OGFP);      % concatenate OG force parameters
    end

    force_OGFP_aligned.Data = computeForceParameters_OGFP_aligned( ...
        strideEvents,trialData.GRFData,s,f,subData.weight,trialData, ...
        trialData.markerData);
    if ~isempty(force_OGFP_aligned.Data)
        out = cat(out,force_OGFP_aligned);  % concatenate force parameters
    end
end

%% Extract H-Reflex Parameters
fields = fieldnames(trialData); % retrieve all 'trialData' obj. field names
if any(contains(fields,'HreflexPin'))   % if 'HreflexPin' field exists, ...
    % if there is data in the 'HreflexPin' and 'EMGData' fields, ...
    if ~isempty(trialData.HreflexPin) && ~isempty(trialData.EMGData)
        % compute parameters associated with H-reflex stimulation
        Hreflex = computeHreflexParameters(strideEvents, ...
            trialData.HreflexPin,trialData.EMGData,s);
        out = cat(out,Hreflex); % concatentate H-reflex parameters
    end
end

%% Extract Perceptual Task Parameters
slaIdx = strcmpi(spat.labels,'netContributionNorm2');   % SLA param. index
% if there are gait events indicating start / stop of perceptual trial, ...
if any(contains(trialData.gaitEvents.labels,'perc'))
    PerceptualTasks = computePercParameters(trialData,initTime, ...
        endTime,spat.Data(:,slaIdx));
    out = cat(out,PerceptualTasks); % concatenate perceptual parameters
end

%% Update 'bad' Stride Labeling (Only If Basic Parameters Computed)
if any(strcmpi(parameterClasses,'basic'))
    badStart = bad;         % copy 'bad' strides array for later comparison
    % -------------------- REMOVE OUTLIER STRIDES --------------------
    % NOTE: Pablo I. commented this outlier strides block (13 Mar. 2017)
    % with rationale listed of the code block not doing anything (i.e.,
    % defining 'aux' variable, which is not used elsewhere).
    % NOTE: NWB is confused because it appears that this block was doing
    % something, namely updating strides labeled 'bad' based on outliers.
    % TODO: generalize below process to potentially filter any parameter
    % TODO: make this into a method of 'parameterSeries' or 'labTimeSeries'
    % TODO: consider a different method of filtering the parameters
    % cell array of the parameters to use for labeling outlier strides
    % paramsToFilter = {'stepLengthSlow','stepLengthFast', ...
    %     'alphaSlow','alphaFast','alphaTemp','betaSlow','betaFast'};
    % for ii = 1:length(paramsToFilter)       % for specified parameters, ...
    %     aux = out.getDataAsVector(paramsToFilter{ii});  % get param. data
    %     if ~isempty(aux)                    % if no parameter data, ...
    %         aux = aux - runAvg(aux,50);     % remove 50 stride running avg
    %         % criterion 1: if step length, alpha, or beta are larger than
    %         % +/- 3.5x the interquartile range from the median
    %         bad(abs(aux - median(aux,'omitnan')) > 3.5*iqr(aux)) = true;
    %
    %         % criterion 2: ignore the first five strides of any trial
    %         % NOTE: NWB how does this add anything from criterion 1?
    %         inds = find(abs(aux - median(aux,'omitnan')) > 3.5*iqr(aux));
    %         inds = inds(inds > 5);
    %         bad(inds) = true;
    %     end
    %
    % end
    % outlierStrides = find(bad & ~badStart);
    % disp(['Removed ' num2str(numel(outlierStrides)) ...
    %     ' outlier(s) from ' file ' at stride(s) ' ...
    %     num2str(outlierStrides')]);

    % -------------------- REMOVE START / STOP STRIDES --------------------
    % criterion 3: if 'singleStanceSpeed' of BOTH legs is less than
    % 0.05 m/s (i.e., 50 mm/s) (starting / stopping strides, TM trials)
    if strcmp(trialData.metaData.type,'TM')
        aux = out.getDataAsVector( ...
            {'singleStanceSpeedFastAbs','singleStanceSpeedSlowAbs'});
        if ~isempty(aux)    % if parameters not empty arrays, ...
            % label as 'bad' TM strides where moving too slowly
            bad(abs(aux(:,1)) < 50 & abs(aux(:,2)) < 50) = true;
        end
    end

    % criterion 4: if any 'swingRange' < 50mm or if equivalent speed is too
    % small (OG trials only, NOTE: may be problematic for children)
    if strcmp(trialData.metaData.type,'OG')
        % TODO: implement this handling
    end

    % remove outlier strides based on new 'bad' labeling
    [~,idxs] = out.isaParameter({'bad','good'});% parameter column indices
    out.Data(:,idxs) = [bad ~bad];              % update parameters
    % identify strides that are currently marked 'bad' but not previously
    outlierStrides = find(bad & ~badStart);
    % TODO: confusing NWB sees no code removing 'bad' strides from data and
    % why are not all 'bad' strides displayed in below warning?
    disp(['Removed ' num2str(numel(outlierStrides)) ...
        ' stopping/starting strides from ' file ' at stride(s) ' ...
        num2str(outlierStrides')]);

    if any(bad)             % if there are any 'bad' strides in trial, ...
        disp(['Warning: ' num2str(sum(bad)) ' strides of ' file ...
            ' were labeled as bad']);   % display command window warning
    end
end

%% Mask Strides Labeled 'bad' as 'NaN'
% NOTE: this line has been commented out for a while and is unnecessary
% TODO: remove line permanently so users have option of keeping all strides
% only mask parameters in columns 6 to end, leave first five untouched
% out.Data(bad == 1,6:end) = NaN;

end

