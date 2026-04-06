function out = calcParameters(trialData, subData, eventClass, ...
    initEventSide, parameterClasses)
% calcParameters  Compute stride-by-stride parameters for analysis.
%
%   Computes adaptation parameters on a stride-by-stride basis for a
% single processed trial, including temporal, spatial, EMG, GRF, H-
% reflex, and perceptual task parameters. Returns a parameterSeries
% object containing all requested parameter classes, with each stride
% labeled as good or bad based on event quality and duration criteria.
%
% To add a new parameter, update the paramLabels cell and ensure the
% label matches the variable name where the data is assigned in the
% code (e.g., in paramLabels: 'swingTimeSlow'; in code:
% swingTimeSlow(t) = timeSHS2 - timeSTO).
%
% Note: If adding slow and fast versions of a parameter, ensure
%   'Fast' and 'Slow' appear at the end of the respective parameter
%   names. See existing parameter names as examples.
%
%   Inputs:
%     trialData        - processedTrialData object containing gait
%                        events, marker, EMG, and GRF data
%     subData          - subjectData object containing subject weight
%                        and other anthropometric information
%     eventClass       - (optional) String specifying the gait event
%                        detection method. Defaults to '' if omitted:
%                          ''      - default (TM: forces, OG: kinematics)
%                          'kin'   - strictly from kinematics
%                          'force' - strictly from forces
%     initEventSide    - (optional) 'L' or 'R'; side for the initial
%                        gait event. Defaults to
%                        trialData.metaData.refLeg if omitted or empty
%     parameterClasses - (optional) String or cell array of strings
%                        specifying which parameter classes to compute.
%                        Defaults to all classes if omitted:
%                          'basic'    - event type, bad/good flags, trial
%                                       number, initial/final event times
%                          'temporal' - temporal gait parameters
%                          'spatial'  - spatial gait parameters
%                          'rawEMG'   - raw EMG parameters
%                          'procEMG'  - processed EMG parameters
%                          'force'    - treadmill force parameters
%
%   Outputs:
%     out - parameterSeries object containing all stride-by-stride
%           parameters with good/bad stride labels
%
%   Toolbox Dependencies:
%     None
%
%   See also: parameterSeries, processedTrialData, labData/process,
%     computeTemporalParameters, computeSpatialParameters,
%     computeEMGParameters, computeForceParameters,
%     computeHreflexParameters, computePercParameters, getStrideInfo

arguments
    trialData        (1,1)
    subData          (1,1)
    eventClass       (1,:) char = ''
    initEventSide    (1,:) char = ''
    parameterClasses = {'basic', 'temporal', 'spatial', ...
        'rawEMG', 'procEMG', 'force'}
end

file = getSimpleFileName(trialData.metaData.rawDataFilename);

% Resolve the reference leg from initEventSide or trial metadata
if isempty(initEventSide)
    refLeg = trialData.metaData.refLeg;
else
    refLeg = initEventSide;
end

if isempty(parameterClasses) %if provided but it's empty, use default value
    parameterClasses = {'basic', 'temporal', 'spatial', ...
        'rawEMG', 'procEMG', 'force'};
elseif ischar(parameterClasses) % Convert a single parameter class string to a cell array
    parameterClasses = {parameterClasses};
end

%% Separate Data by Stride and Identify Gait Events for Each Stride
% One 'stride' contains the events: SHS, FTO, FHS, STO, SHS2, FTO2
if refLeg == 'R'                % if reference leg is right, ...
    s = 'R';                    % set slow leg to right
    f = 'L';                    % TODO: substitute with 'getOtherLeg()'
elseif refLeg == 'L'            % if reference leg is left, ...
    s = 'L';                    % set slow leg to left
    f = 'R';                    % TODO: substitute with 'getOtherLeg()'
else                            % otherwise, ...
    ME = MException('MakeParameters:refLegError', ...
        ['the refLeg/initEventSide property of metaData must be ' ...
        'either ''L'' or ''R''.']);
    throw(ME);
end

% Define the events used for all further computations
eventTypes   = {[s 'HS'], [f 'TO'], [f 'HS'], [s 'TO']};
eventTypes   = strcat(eventClass, eventTypes);
eventLabels  = {'SHS', 'FTO', 'FHS', 'STO'};
triggerEvent = eventTypes{1};

% Initialize stride information variables
[numStrides, initTime, endTime] = getStrideInfo(trialData, triggerEvent);
% arrayedEvents = trialData.getArrayedEvents(eventTypes);
if numStrides == 0              % if there are no strides in trial, ...
    % TODO: consider initializing 'parameterSeries' object with all
    % parameters and zero strides instead of as empty
    disp(['Warning: No strides detected in ' file]);
    out = parameterSeries([], {}, [], {});
    return;
end
stridedEventData = cell(numStrides, 1);
stridedAngleData = cell(numStrides, 1);

% Extract binned angle data and stride-by-stride gait event times
eventTimes = nan(numStrides, length(eventTypes));
for st = 1:numStrides           % for each stride in trial, ...
    % Conditional added by Digna de Kam to bin angle data
    if ~isempty(trialData.angleData)    % if angle data present, ...
        stridedAngleData{st} = ...      % retrieve binned angle data
            trialData.angleData.split(initTime(st), endTime(st));
    end

    % stridedMarkerData{st} = in.('markerData').split( ...
    %     initTime(st), endTime(st));
    stridedEventData{st} = ...
        trialData.gaitEvents.split(initTime(st), endTime(st));
    for ev = 1:length(eventTypes)   % for each gait event type, ...
        aux = stridedEventData{st}.getDataAsVector(eventTypes{ev});
        % Find next two events of the type.
        % HH: it is pointless to find the next two events, since find
        % will still return a value even if it only finds one.
        aux = find(aux, 2, 'first');
        % HH: maybe instead we should check if aux has a length of two
        if ~isempty(aux)            % if data present, ...
            eventTimes(st, ev) = stridedEventData{st}.Time(aux(1));
        end
    end
end
% TODO: improve by searching for any remaining events after last stride
eventTimes2 = [eventTimes(2:end, :); nan(1, size(eventTimes, 2))];
for ev = 1:length(eventTypes)       % for each gait event type, ...
    % Generate a structure of 'tSHS', 'tFTO', etc.
    strideEvents.(['t' upper(eventLabels{ev})]) = eventTimes(:, ev);
    strideEvents.(['t' upper(eventLabels{ev}) '2']) = eventTimes2(:, ev);
end

%% Compute Parameters
% Times of the SHS, FTO, FHS, FTO, SHS2, and FTO2 events (in order)
extendedEventTimes = [eventTimes eventTimes2(:, 1:2)];
% Average all gait event times if available
times = mean(extendedEventTimes, 2, 'omitnan');
% Initialize output 'parameterSeries' object
out = parameterSeries(zeros(length(times), 0), {}, times, {});
% Compute stride duration (seconds) as time between SHS and SHS2
strideDuration = diff(extendedEventTimes(:, [1 5]), 1, 2);
% Five criteria to determine whether a stride is 'bad':
%   1. Any event times are 'NaN' (i.e., missing gait event)
%   2. Difference between any two consecutive event times is negative
%   3. Stride duration > 1.5 * median stride duration of the trial
%   4. Stride duration < 0.4 seconds (stride too short)
%   5. Stride duration > 2.5 seconds (stride too long)
% TODO: NWB found that 2.5 seconds may be too stringent for slower older
% adult walkers and 1.5 * median may be a sufficient threshold to exclude
% outliers (especially in overground trials); consider removing criterion 5
bad = any(isnan(extendedEventTimes), 2)                       | ...
    any(diff(extendedEventTimes, 1, 2) < 0, 2)                | ...
    (strideDuration > 1.5*median(strideDuration, 'omitnan'))  | ...
    (strideDuration < 0.4)                                    | ...
    (strideDuration > 2.5);

%% Extract Basic Parameters and Save to Output parameterSeries Object
if any(strcmpi(parameterClasses, 'basic'))  % if adding basic params,...
    try                             % try initializing trial number
        % need to FIX, but data is currently unavailable on 'trialMetaData'
        trial = str2double(trialData.metaData.rawDataFilename(end-1:end));
    catch
        warning('calcParametersNew:gettingTrialNumber', ['Could not ' ...
            'determine trial number from metaData, setting to NaN.']);
        trial = nan;
    end
    trial = repmat(trial, length(bad), 1);

    initTime  = extendedEventTimes(:, 1);   % initial SHS times
    finalTime = extendedEventTimes(:, 6);   % final FTO2 times

    if strcmp(eventClass, '')           % if default event method, ...
        % Determine type of event detection used for this trial
        Event = full(trialData.gaitEvents.Data);
        if isequal(Event(:, 1), Event(:, 5))
            % Use forces
            eventType = 2 * ones(length(finalTime), 1);
        elseif isequal(Event(:, 1), Event(:, 9))
            % Use kinematics
            eventType = 1 * ones(length(finalTime), 1);
        end
    elseif strcmp(eventClass, 'kin')    % if using kinematics, ...
        eventType = 1 * ones(length(finalTime), 1);
    elseif strcmp(eventClass, 'force')  % if using forces, ...
        eventType = 2 * ones(length(finalTime), 1);
    end

    % Add 'basic' parameters to output 'parameterSeries' object
    data   = [eventType bad ~bad trial initTime finalTime];
    labels = {'eventType', 'bad', 'good', 'trial', ...
        'initTime', 'finalTime'};
    description = {'1 kinematics, 2 forces', ...
        ['True if events are missing, disordered, or if stride ' ...
        'time is too long or too short.'], ...
        'Opposite of bad.', ...
        'Original trial number for stride', ...
        'Time of initial event (SHS), with respect to trial beginning.',...
        'Time of final event (FTO2), with respect to trial beginning.'};
    basic = parameterSeries(data, labels, times, description);
    out   = cat(out, basic);
end

%% Extract Temporal Parameters
if any(strcmpi(parameterClasses, 'temporal'))
    temp = computeTemporalParameters(strideEvents);
    out  = cat(out, temp);
end

%% Extract Spatial Parameters
if any(strcmpi(parameterClasses, 'spatial')) && ...
        ~isempty(trialData.markerData) && ...
        (numel(trialData.markerData.labels) ~= 0)
    spat = computeSpatialParameters( ...
        strideEvents, trialData.markerData, trialData.angleData, s);
    out  = cat(out, spat);
end

%% Extract Harmonic Ratio Parameters
% TODO: add checks to ensure GT markers are present before computing
if ~isempty(trialData.markerData)
    % harmonicRatios = computeHarmonicRatioParameters( ...
    %     strideEvents, trialData.markerData);
    % out = cat(out, harmonicRatios);
end

%% Extract Muscle Activity (EMG) Parameters
if any(strcmpi(parameterClasses, 'rawEMG')) && ~isempty(trialData.EMGData)
    EMG_alt = computeEMGParameters(trialData.EMGData, ...
        trialData.gaitEvents, s, eventTypes);   % classic way
    out = cat(out, EMG_alt);
end

%% Extract Joint Angle Parameters
if ~isempty(trialData.angleData)        % if angle data is present, ...
    angles = computeAngleParameters( ...
        trialData.angleData, trialData.gaitEvents, s, eventTypes);
    out = cat(out, angles);
end

%% Extract Treadmill Force Parameters
if any(strcmpi(parameterClasses, 'force')) && ~isempty(trialData.GRFData)
    force = computeForceParameters( ...
        strideEvents, trialData.GRFData, s, f, subData.weight, ...
        trialData.metaData, trialData.markerData, subData);
    if ~isempty(force.Data)         % if output force data not empty, ...
        out = cat(out, force);
    end
end

%% Extract Overground Force Parameters
% If you encounter a bug with a line of code in this section (e.g.,
% indexing array out of bounds), comment it out to prevent the
% overground forces from being processed and output.

% Only compute these parameters if there are overground force recordings.
OG_names = {'FP4Fz', 'FP5Fz', 'FP6Fz', 'FP7Fz'};
OG_idx = contains(trialData.GRFData.labels, OG_names);

if sum(OG_idx) == length(OG_names) | ...
        (max(trialData.GRFData.Data(:,OG_idx)) - ...
        min(trialData.GRFData.Data(:,OG_idx))) > 100
    % There are differences in forces throughout the experiment, and
    % not a constant value or NaNs.
    force_OGFP.Data = computeForceParameters_OGFP( ...
        strideEvents, trialData.GRFData, s, f, subData.weight, ...
        trialData, trialData.markerData);
    if ~isempty(force_OGFP.Data)
        out = cat(out, force_OGFP);
    end

    force_OGFP_aligned.Data = computeForceParameters_OGFP_aligned( ...
        strideEvents, trialData.GRFData, s, f, subData.weight, ...
        trialData, trialData.markerData);
    if ~isempty(force_OGFP_aligned.Data)
        out = cat(out, force_OGFP_aligned);
    end
end

%% Extract H-Reflex Parameters
fields = fieldnames(trialData);     % retrieve all trialData field names
if any(contains(fields, 'HreflexPin'))  % if 'HreflexPin' exists, ...
    % If there is data in the 'HreflexPin' and 'EMGData' fields, ...
    if ~isempty(trialData.HreflexPin) && ~isempty(trialData.EMGData)
        Hreflex = computeHreflexParameters( ...
            strideEvents, trialData.HreflexPin, trialData.EMGData, s);
        out = cat(out, Hreflex);
    end
end

%% Extract Perceptual Task Parameters
slaIdx = strcmpi(spat.labels, 'netContributionNorm2'); % SLA param idx
% If there are gait events indicating start/stop of perceptual trial,...
if any(contains(trialData.gaitEvents.labels, 'perc'))
    PerceptualTasks = computePercParameters( ...
        trialData, initTime, endTime, spat.Data(:, slaIdx));
    out = cat(out, PerceptualTasks);
end

%% Update 'bad' Stride Labeling (Only If Basic Parameters Computed)
if any(strcmpi(parameterClasses, 'basic'))
    badStart = bad;     % copy 'bad' strides array for later comparison

    % ------------------- REMOVE OUTLIER STRIDES ----------------------
    % NOTE: Pablo I. commented this outlier strides block (13 Mar.
    % 2017) with rationale that the code does not do anything (i.e.,
    % it defines an 'aux' variable that is not used elsewhere).
    % NOTE: NWB is confused because it appears this block was doing
    % something, namely updating strides labeled 'bad' based on
    % outliers.
    % TODO: generalize below process to potentially filter any param.
    % TODO: make this a method of 'parameterSeries' or 'labTimeSeries'
    % TODO: consider a different method of filtering the parameters
    % Cell array of parameters to use for labeling outlier strides:
    % paramsToFilter = {'stepLengthSlow', 'stepLengthFast', ...
    %     'alphaSlow', 'alphaFast', 'alphaTemp', ...
    %     'betaSlow', 'betaFast'};
    % for ii = 1:length(paramsToFilter)
    %     aux = out.getDataAsVector(paramsToFilter{ii});
    %     if ~isempty(aux)
    %         aux = aux - runAvg(aux, 50);
    %         % Criterion 1: if step length, alpha, or beta are larger
    %         % than +/- 3.5x the interquartile range from the median
    %         bad(abs(aux-median(aux,'omitnan')) > 3.5*iqr(aux)) = true;
    %
    %         % Criterion 2: ignore the first five strides of any trial
    %         % NOTE: NWB how does this add anything from criterion 1?
    %         inds = find(abs(aux - median(aux,'omitnan')) > 3.5*iqr(aux));
    %         inds = inds(inds > 5);
    %         bad(inds) = true;
    %     end
    % end
    % outlierStrides = find(bad & ~badStart);
    % disp(['Removed ' num2str(numel(outlierStrides)) ...
    %     ' outlier(s) from ' file ' at stride(s) ' ...
    %     num2str(outlierStrides')]);

    % -------------- REMOVE START / STOP STRIDES ----------------------
    % Criterion 3: if 'singleStanceSpeed' of BOTH legs is less than
    % 0.05 m/s (50 mm/s), label as starting/stopping strides (TM only)
    if strcmp(trialData.metaData.type, 'TM')
        aux = out.getDataAsVector( ...
            {'singleStanceSpeedFastAbs', 'singleStanceSpeedSlowAbs'});
        if ~isempty(aux)        % if parameters not empty arrays, ...
            % Label as 'bad' TM strides where moving too slowly
            bad(abs(aux(:, 1)) < 50 & abs(aux(:, 2)) < 50) = true;
        end
    end

    % Criterion 4: if any 'swingRange' < 50 mm or if equivalent speed
    % is too small (OG trials only; may be problematic for children)
    if strcmp(trialData.metaData.type, 'OG')
        % TODO: implement this handling
    end

    % Update 'bad' labeling in the parameterSeries output
    [~, idxs] = out.isaParameter({'bad', 'good'});
    out.Data(:, idxs) = [bad ~bad];
    % Identify strides newly marked 'bad' since the initial labeling
    outlierStrides = find(bad & ~badStart);
    % TODO: confusing — NWB sees no code removing 'bad' strides from
    % data; why are not all 'bad' strides displayed in below warning?
    disp(['Removed ' num2str(numel(outlierStrides)) ...
        ' stopping/starting strides from ' file ' at stride(s) ' ...
        num2str(outlierStrides')]);

    if any(bad)             % if there are any 'bad' strides, ...
        disp(['Warning: ' num2str(sum(bad)) ' strides of ' file ...
            ' were labeled as bad']);
    end
end

%% Mask Strides Labeled 'bad' as 'NaN'
% NOTE: this line has been commented out for a while and is unnecessary
% TODO: remove permanently so users have option of keeping all strides
% Only mask parameters in columns 6 to end, leave first five untouched:
% out.Data(bad == 1, 6:end) = NaN;

end

