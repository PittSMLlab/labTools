%% Generate H-Reflex Calibration Recruitment Curves During the Experiment
% author: NWB
% date (started): 05 May 2024
% purpose: to extract the M-wave and H-wave amplitudes from the H-reflex
% calibration EMG data shortly after the creation of the calibration trial
% C3D file in a Vicon Nexus software processing pipeline during an
% experiment.
% NOTE: this processing script uses 'SL_Realtime.m' as a template to use
% the Vicon Nexus sofware tools.

%% 1. Load the C3D File Data
try     % if Vicon Nexus is running with a file open, use that
    % Vicon Nexus must be open, offline, and the desired trial loaded
    vicon = ViconNexus();
    [path,filename] = vicon.GetTrialName; % ask Nexus which trial is open
    id = vicon.GetSubjectName;  % retrieve participant / session ID
catch   % use below two lines when processing c3d files not open in Nexus
    commandwindow();
    [filename,path] = uigetfile('*.c3d', ...
        'Please select the c3d file of interest:');
    compsPath = strsplit(path,filesep);
    guessID = compsPath(contains(compsPath,'SA'));
    id = inputdlg({'Enter the Participant / Session ID:'},'ID',[1 50], ...
        guessID);
end
id = id{1};
[~,filename,ext] = fileparts(filename);
trialNum = filename(end-1:end); % last two characters of file name are #
filename = [filename '.c3d'];
mkdir([path 'HreflexCalFigs']);
pathFigs = [path 'HreflexCalFigs'];

H = btkReadAcquisition([path filename]);
% using the same method as labtools, retrieve the analog data
[analogs,analogsInfo] = btkGetAnalogs(H);

%% 2. Retrieve User Input Data
% TODO: use the feature of the stimulator to set the current output
% based on the voltage of the trigger pulse to eliminate the need for
% asking the user to input the stimulation amplitudes
prompt = { ...
    'Enter the EMG sensor muscles in sensor number order:', ...
    ['Should stimulation trigger pulse data be used to identify ' ...
    'artifact peak times? (''1'' = true, ''0'' = false)'], ...
    ... 'Was trial a walking calibration? (''1'' = true, ''0'' = false)', ...
    'Enter the right leg stimulation amplitudes (numbers only):', ...
    'Enter the left leg stimulation amplitudes (numbers only):', ...
    ['Stimulation Artifact Threshold (V) (NOTE: only relevant if not ' ...
    'using stim trigger pulse):'], ...
    ['Minimum Time Between Stimulation Pulses (s) (NOTE: only relevant' ...
    ' if not using stim trigger pulse):']};
dlgtitle = 'H-Reflex Calibration Input';
fieldsize = [1 200; 1 200; 1 200; 1 200; 1 200; 1 200];
% TODO: set the below initial values to whatever we would expect to use
% during the calibration trial; for now set to values used for SAS01V02
% (with the amplitudes being the best guess based on memory)
definput = { ...
    ['RTAP RTAD NA RPER RMG RLG LTAP LTAD LPER LMG LLG RSOL LSOL NA NA' ...
    ' sync1'], ...
    '1', ...
    '8 12 16 16 20 16 16 18 18', ... '8 8 12 12 16 16 20 20 24 24', ...
    '8 12 16 16 20 16 16 18 18', ... '8 8 12 12 16 16 20 20 24 24', ...
    '0.0003', ...
    '5'};
answer = inputdlg(prompt,dlgtitle,fieldsize,definput);

% TODO: add input argument checks
EMGList1 = strsplit(answer{1},' ');
if isempty(EMGList1)    % if no EMG labels input, ...
    error(['No EMG labels have been provided. It is not possible to ' ...
        'generate H-reflex recruitment curves without EMG data.']);
end
% isCalWalking = logical(str2double(answer{2}));
shouldUseStimTrig = logical(str2double(answer{2}));
ampsStimR = str2num(answer{3});
ampsStimL = str2num(answer{4});
threshStimArtifact = str2double(answer{5});% stimulation artifact threshold
threshStimTimeSep = str2double(answer{6}); % at least 5 sec between stim

numStimR = length(ampsStimR);   % number of times stimulated right leg
numStimL = length(ampsStimL);   % number of times stimulated left leg

%% 3. Retrieve EMG Data
% NOTE: below is copied directly from 'loadTrials.m'
% below are the muscle names (abbrev.) in the desired order
% NOTE: thigh and hip muscles have been removed since not currently
% relevant for the Spinal Adaptation project
orderedMuscleList = {'PER','TA','TAP','TAD','SOL','MG','LG'};
orderedEMGList={};
for j = 1:length(orderedMuscleList)
    orderedEMGList{end+1}=['R' orderedMuscleList{j}];
    orderedEMGList{end+1}=['L' orderedMuscleList{j}];
end

EMG = [];
relData = [];
relDataTemp = [];
fieldList = fields(analogs);
idxList = [];
for j=1:length(fieldList)
    if  ~isempty(strfind(fieldList{j},'EMG'))  %Getting fields that start with 'EMG' only
        relDataTemp=[relDataTemp,analogs.(fieldList{j})];
        idxList(end+1)=str2num(fieldList{j}(strfind(fieldList{j},'EMG')+3:end));
        analogs=rmfield(analogs,fieldList{j}); %Just to save memory space
    end
end
emptyChannels1=cellfun(@(x) contains(x,'NA') || contains(x,'sync'),EMGList1);
EMGList1 = EMGList1(~emptyChannels1);
relData(:,idxList)=relDataTemp; %Re-sorting to fix the 1,10,11,...,2,3 count that Matlab does
relData=relData(:,~emptyChannels1);
EMGList=EMGList1;

%Check if names match with expectation, otherwise query user
for k=1:length(EMGList)
    while sum(strcmpi(orderedEMGList,EMGList{k}))==0 && ~strcmpi(EMGList{k}(1:4),'sync')
        aux= inputdlg(['Did not recognize muscle name, please re-enter name for channel ' num2str(k) ' (was ' EMGList{k} '). Acceptable values are ' cell2mat(strcat(orderedEMGList,', ')) ' or ''sync''.'],'s');
        if k<=length(EMGList1)
            EMGList1{idxList(k)}=aux{1}; %This is to keep the same message from being prompeted for each trial processed.
        end
        EMGList{k}=aux{1};
    end
end

%For some reasing the naming convention for analog pins is not kept
%across Nexus versions:
fieldNames=fields(analogs);

refSync=analogs.(fieldNames{cellfun(@(x) ~isempty(strfind(x,'Pin3')) | ~isempty(strfind(x,'Pin_3')) | ~isempty(strfind(x,'Raw_3')),fieldNames)});

EMGfrequency=analogsInfo.frequency;
allData=relData;

%Pre-process:
[refSync] = clipSignals(refSync(:),.1); %Clipping top & bottom samples (1 out of 1e3!)
refAux=medfilt1(refSync,20);
%refAux(refAux<(median(refAux)-5*iqr(refAux)) | refAux>(median(refAux)+5*iqr(refAux)))=median(refAux);
refAux=medfilt1(diff(refAux),10);
clear auxData*

%Sorting muscles (orderedEMGList was created previously) so that they are always stored in the same order
orderedIndexes=zeros(length(orderedEMGList),1);
for j=1:length(orderedEMGList)
    for k=1:length(EMGList)
        if strcmpi(orderedEMGList{j},EMGList{k})
            orderedIndexes(j)=k;
            break;
        end
    end
end
orderedIndexes=orderedIndexes(orderedIndexes~=0); %Avoiding missing muscles
aux=zeros(length(EMGList),1);
aux(orderedIndexes)=1;
if any(aux==0) && ~all(strcmpi(EMGList(aux==0),'sync'))
    warning(['loadTrials: Not all of the provided muscles are in the ordered list, ignoring ' EMGList{aux==0}])
end
allData(allData==0)=NaN; %Eliminating samples that are exactly 0: these are unavailable samples
EMG=labTimeSeries(allData(:,orderedIndexes),0,1/EMGfrequency,EMGList(orderedIndexes)); %Throw away the synch signal
clear allData* relData* auxData*

%% 4. Retrieve Ground Reaction Force (GRF) Data If It Exists
relData=[];
forceLabels ={};
units={};
fieldList=fields(analogs);
forceLabelIdx = contains(fieldList,'Force_Fz'); % only care about Fz
forceLabelIdx = find(forceLabelIdx,2,'first');  % FP 1 (Left) & 2 (Right)
hasForces = ~isempty(forceLabelIdx);
if hasForces     % if force data found, ...
    for j=1:length(forceLabelIdx)   % for each relevant force label, ...
        forceLabels{end+1} = fieldList{forceLabelIdx(j)};    % add label
        units{end+1} = eval(['analogsInfo.units.', ...
            fieldList{forceLabelIdx(j)}]);
        relData = [relData analogs.(fieldList{forceLabelIdx(j)})];
    end
    GRF = labTimeSeries(relData,0, ...
        1/analogsInfo.frequency,forceLabels);
    GRF.DataInfo.Units = units;
else    % otherwise, set force data to be empty, ...
    GRF = [];
end

clear relData

%% 5. Retrieve H-Reflex Stimulator Pin Data If It Exists
if shouldUseStimTrig    % if stimulation trigger data should be used, ...
    % NOTE: the below code block is copied from loadTrials (implemented by SL)
    relData = [];
    stimLabels = {};
    units = {};
    fieldList = fields(analogs);
    stimLabelIdx = cellfun(@(x) ~isempty(x), ...
        regexp(fieldList,'^Stimulator_Trigger_Sync_'));
    stimLabelIdx = find(stimLabelIdx);
    hasStimTrig = ~isempty(stimLabelIdx);
    if hasStimTrig	% if stimulator trigger sync data found, ...
        for st = 1:length(stimLabelIdx) % for each stim trigger pin, ...
            stimLabels{end+1} = fieldList{stimLabelIdx(st)};	% add the label
            units{end+1} = eval(['analogsInfo.units.', ...
                fieldList{stimLabelIdx(st)}]);
            relData = [relData analogs.(fieldList{stimLabelIdx(st)})];
        end
        HreflexStimPin = labTimeSeries(relData,0, ...
            1/analogsInfo.frequency,stimLabels);

        % verify that the # of frames matches that of the GRF data
        if ~isempty(GRF)    % if there is GRF data present, ...
            if (GRF.Length ~= HreflexStimPin.Length)
                error(['Hreflex stimulator pins have different length than' ...
                    'GRF data. This should never happen. Data is compromised.']);
            end
        end
    else
        warning(['User indicated stimulation trigger data should be ' ...
            'used to identify the artifact peak times, but no trigger ' ...
            'pulse data is present.']);
        HreflexStimPin = [];
    end
end

clear analogs* %Save memory space, no longer need analog data, it was already loaded

%% Extract Events
% TODO: add back in to script if helpful to check the times to verify
% stimulation is during single stance if it is a walking calibration trial

% [~,~,lfz] = intersect('LFz',forceLabels);
% [~,~,rfz] = intersect('RFz',forceLabels);
%
% [LHS,RHS,LTO,RTO] = getEventsFromForces(forces(:,lfz),forces(:,rfz),100);

%% Save the Data
% TODO: implement if valuable for this script

% try
%     RTdata = struct();%initialize save structure
%     RTdata.trialname = filename;
%     RTdata.path = path;
%     RTdata.creationdate = clock;
%     RTdata.forcedata = forces;
%     RTdata.forcelabels = forceLabels;
%     RTdata.markerdata = markers;
%     RTdata.markerlabels = markerList;
%     RTdata.Rsteplengths = Rgamma;
%     RTdata.Lsteplengths = Lgamma;
%     RTdata.Rcadence = Rcadence;
%     RTdata.Lcadence = Lcadence;
%     RTdata.Rsteptime = Rsteptime;
%     RTdata.Lsteptime = Lsteptime;
%     RTdata.time = time;
%
%     fn = strrep(datestr(clock),'-','');
%
%     filesave = [path fn(1:9) '_' filename(1:end-4) '_SL_Realtime'];
%
%     save(filesave,'RTdata');
% catch ME
%     throw(ME)
% end

%% 6. Define H-Reflex Calibration Trial Parameters
% NOTE: should always be the same across trials
period = EMG.sampPeriod;    % sampling period
threshSamps = threshStimTimeSep / period;  % convert to samples
% M-wave is contained by interval 5ms - 20ms
% H-wave is contained by interval 20ms - 50ms
indStartM = 0.005 / period;        % 5 ms after stim artifact in samples
indEndM = (0.020 - period) / period;
indStartH = 0.020 / period;        % 20 ms
indEndH = 0.050 / period;          % 50 ms

%% 7. Identify Locations of the Stimulation Artifacts
% extract relevant EMG data
EMG_LTAP = EMG.Data(:,contains(EMG.labels,'ltap', ...
    'IgnoreCase',true));  % use proximal TA to determine stim artifact time
EMG_RTAP = EMG.Data(:,contains(EMG.labels,'rtap', ...
    'IgnoreCase',true));
% MG is the muscle used for the H-reflex
EMG_LMG = EMG.Data(:,contains(EMG.labels,'lmg','IgnoreCase',true));
EMG_RMG = EMG.Data(:,contains(EMG.labels,'rmg','IgnoreCase',true));
EMG_LSOL = EMG.Data(:,contains(EMG.labels,'lsol', ...
    'IgnoreCase',true));  % in case want to explore SOL H-reflex
EMG_RSOL = EMG.Data(:,contains(EMG.labels,'rsol', ...
    'IgnoreCase',true));
% if missing any of the EMG signals used below, ...
if any(isempty([EMG_LTAP EMG_RTAP EMG_LMG EMG_RMG EMG_LSOL EMG_RSOL]))
    % TODO: update handling of cases when one or more of these signals is
    % missing (e.g., if only conducting calibration on one leg or not using
    % the Soleus sensor)
    error('Missing one or more EMG signals.');
end

times = EMG.Time;   % if want to plot, can use the time array

if hasForces
    GRFRFz = GRF.Data(:,contains(GRF.labels,'fz2','IgnoreCase',true));
    GRFLFz = GRF.Data(:,contains(GRF.labels,'fz1','IgnoreCase',true));
end

% NOTE: it does not work to use stim trigger pulse to retrieve peak times
% if stimulator is turned off during trial (because there will be trigger
% pulse but participant will not have been stimulated)
% if there is stimulation trigger pulse data and it should be used to
% identify the locations of the artifact peaks, ...
if shouldUseStimTrig && hasStimTrig
    % threshold to determine rising edge of stimulation trigger pulse
    threshVolt = 2.5;
    % extract all stimulation trigger data for each leg
    stimTrigR = HreflexStimPin.Data(:,contains(HreflexStimPin.labels, ...
        'right','IgnoreCase',true));
    stimTrigL = HreflexStimPin.Data(:,contains(HreflexStimPin.labels, ...
        'left','IgnoreCase',true));
    indsStimRAll = find(stimTrigR > threshVolt);
    indsStimLAll = find(stimTrigL > threshVolt);

    % determine which indices correspond to the start of a new stimulus pulse
    % (i.e., there is a jump in index greater than 1, not just the next sample)
    indsNewPulseR = diff([0; indsStimRAll]) > 1;
    indsNewPulseL = diff([0; indsStimLAll]) > 1;

    % determine time since start of trial when stim pulse started (rising edge)
    stimTimeRAbs = HreflexStimPin.Time(indsStimRAll(indsNewPulseR));
    stimTimeLAbs = HreflexStimPin.Time(indsStimLAll(indsNewPulseL));

    % find the indices of the EMG data corresponding to the onset of the
    % stimulation trigger pulse
    indsEMGStimOnsetRAbs = arrayfun(@(x) find(x == times),stimTimeRAbs);
    indsEMGStimOnsetLAbs = arrayfun(@(x) find(x == times),stimTimeLAbs);
    if (numStimR ~= length(indsEMGStimOnsetRAbs)) || ...
            (numStimL ~= length(indsEMGStimOnsetlAbs))
        error(['The number of stimulation trigger pulses does not ' ...
            'match the number of input stimulation amplitudes.']);
    end

    % initialize array of indices determined by the stim artifact
    locsR = nan(size(indsEMGStimOnsetRAbs));
    locsL = nan(size(indsEMGStimOnsetLAbs));

    winStim = 0.1;  % +/- 100 ms of the onset of the stim trigger pulse

    for stR = 1:numStimR    % for each right leg stimulus, ...
        winSearch = (indsEMGStimOnsetRAbs(stR) - (winStim/period)): ...
            (indsEMGStimOnsetRAbs(stR) + (winStim/period));
        [~,indMaxTAP] = max(EMG_RTAP(winSearch));   % find artifact peak
        timesWin = times(winSearch);
        timeStimStart = timesWin(indMaxTAP);
        locsR(stR) = find(times == timeStimStart);
    end

    for stL = 1:numStimL
        winSearch = (indsEMGStimOnsetLAbs(stL) - (winStim/period)): ...
            (indsEMGStimOnsetLAbs(stL) + (winStim/period));
        [~,indMaxTAP] = max(EMG_LTAP(winSearch));
        timesWin = times(winSearch);
        timeStimStart = timesWin(indMaxTAP);
        locsL(stL) = find(times == timeStimStart);
    end

    % TODO: add plotting for this method for visual verification that
    % correct times have been selected
else
    warning(['No stimulation trigger signal being used. Artifact ' ...
        'identification may not be as accurate.']);

    % if want to plot the peaks to check, run without output arguments
    figure('Units','normalized','OuterPosition',[0 0 1 1]);
    tl = tiledlayout('vertical','TileSpacing','tight');

    nexttile; hold on;
    findpeaks(EMG_RTAP,'NPeaks',numStimR, ...
        'MinPeakHeight',threshStimArtifact,'MinPeakDistance',threshSamps);
    yline(threshStimArtifact,'r','Stim Artifact Thresh');
    hold off;
    title(['Right TAP - Trial' trialNum]);

    nexttile; hold on;
    findpeaks(EMG_LTAP,'NPeaks',numStimL, ...
        'MinPeakHeight',threshStimArtifact,'MinPeakDistance',threshSamps);
    yline(threshStimArtifact,'r','Stim Artifact Thresh');
    hold off;
    title(['Left TAP - Trial' trialNum]);

    xlabel(tl,'sample number');
    ylabel(tl,'Raw Voltage (V)');
    title(tl,[id ' - Stimulation Artifact Peak Finding']);
    saveas(gcf,[pathFigs id '_StimArtifactPeakFinding.png']);
    saveas(gcf,[pathFigs id '_StimArtifactPeakFinding.fig']);

    [~,locsR] = findpeaks(EMG_RTAP,'NPeaks',numStimR, ...
        'MinPeakHeight',threshStimArtifact,'MinPeakDistance',threshSamps);
    [~,locsL] = findpeaks(EMG_LTAP,'NPeaks',numStimL, ...
        'MinPeakHeight',threshStimArtifact,'MinPeakDistance',threshSamps);
end

%% 8. Plot All Stimuli to Verify the Waveforms & Timing (Via GRFs)
snipStart = -0.005; % 5 ms before artifact peak
snipEnd = 0.045;    % 45 ms after artifact peak
timesSnippet = snipStart:period:snipEnd;
numSamps = length(timesSnippet);

% store the snippets to plot them together
snippetsHreflexR = nan(numStimR,numSamps);
snippetsHreflexL = nan(numStimL,numSamps);
% plot the right leg stimuli
% TODO: add checks for trials without stimuli for one leg or the other
for stR = 1:numStimR    % for each right leg stimulus, ...
    winPlotR = (locsR(stR) + (snipStart/period)):(locsR(stR) + (snipEnd/period));
    timesWinPlotR = times(winPlotR);
    snipsStimAllMuscles = [EMG_RTAP(winPlotR); EMG_RMG(winPlotR); ...
        EMG_RSOL(winPlotR)];
    ymin = min(snipsStimAllMuscles,[],'all');
    ymax = max(snipsStimAllMuscles,[],'all');

    figure('Units','normalized','OuterPosition',[0 0 1 1]);
    tl = tiledlayout('vertical','TileSpacing','tight');

    % TODO: throw error if EMG arrays and GRF arrays are different length
    % (should be identical since sampled at the same rate)
    if hasForces
        nexttile; hold on;
        xline(times(locsR(stR)),'k','LineWidth',2);
        plot(timesWinPlotR,GRFRFz(winPlotR));
        xlim([timesWinPlotR(1) timesWinPlotR(end)]);
        hold off;
        ylabel('Force (N)');
        title('Right Fz');

        nexttile; hold on;
        xline(times(locsR(stR)),'k','LineWidth',2);
        plot(timesWinPlotR,GRFLFz(winPlotR));
        xlim([timesWinPlotR(1) timesWinPlotR(end)]);
        hold off;
        ylabel('Force (N)');
        title('Left Fz');
    end

    ax1 = nexttile; hold on;
    xline(times(locsR(stR)),'k','LineWidth',2);
    xline(times(locsR(stR)+indStartM),'b');
    xline(times(locsR(stR)+indEndM),'b');
    xline(times(locsR(stR)+indStartH),'g');
    xline(times(locsR(stR)+indEndH),'g');
    % only plot the stimulation artifact threshold if it is used
    % if ~(hasStimTrig && shouldUseStimTrig)
        yline(threshStimArtifact,'r','Stim Artifact Thresh');
    % end
    plot(timesWinPlotR,EMG_RTAP(winPlotR));
    title('Right TA - Proximal');
    hold off;

    snippetsHreflexR(stR,:) = EMG_RMG(winPlotR);
    ax2 = nexttile; hold on;
    xline(times(locsR(stR)),'k','LineWidth',2);
    xline(times(locsR(stR)+indStartM),'b');
    xline(times(locsR(stR)+indEndM),'b');
    xline(times(locsR(stR)+indStartH),'g');
    xline(times(locsR(stR)+indEndH),'g');
    plot(timesWinPlotR,EMG_RMG(winPlotR));
    ylabel('Raw EMG (V)');
    title('Right MG');
    hold off;

    ax3 = nexttile; hold on;
    xline(times(locsR(stR)),'k','LineWidth',2);
    xline(times(locsR(stR)+indStartM),'b');
    xline(times(locsR(stR)+indEndM),'b');
    xline(times(locsR(stR)+indStartH),'g');
    xline(times(locsR(stR)+indEndH),'g');
    plot(timesWinPlotR,EMG_RSOL(winPlotR));
    title('Right SOL');
    hold off;

    linkaxes([ax1 ax2 ax3]);
    xlabel(tl,'time (s)');
    xlim([timesWinPlotR(1) timesWinPlotR(end)]);
    ylim([ymin ymax]);
    title(tl,[id ' - Right Leg - Trial' trialNum ' - Stim ' num2str(stR)]);
    saveas(gcf,[pathFigs id '_StimEMGSnippets_RightLeg_Trial' trialNum ...
        '_Stim' num2str(stR) '.png']);
    saveas(gcf,[pathFigs id '_StimEMGSnippets_RightLeg_Trial' trialNum ...
        '_Stim' num2str(stR) '.fig']);
    close;
end

% plot the left leg stimuli
for stL = 1:numStimL    % for each left leg stimulus, ...
    winPlotL = (locsL(stL) + (snipStart/period)):(locsL(stL) + (snipEnd/period));
    timesWinPlotL = times(winPlotL);
    snipsStimAllMuscles = [EMG_LTAP(winPlotL); EMG_LMG(winPlotL); ...
        EMG_LSOL(winPlotL)];
    ymin = min(snipsStimAllMuscles,[],'all');
    ymax = max(snipsStimAllMuscles,[],'all');

    figure('Units','normalized','OuterPosition',[0 0 1 1]);
    tl = tiledlayout('vertical','TileSpacing','tight');

    if hasForces    % if force data is present, ...
        nexttile; hold on;
        xline(times(locsL(stL)),'k','LineWidth',2);
        plot(timesWinPlotL,GRFLFz(winPlotL));
        xlim([timesWinPlotL(1) timesWinPlotL(end)]);
        hold off;
        ylabel('Force (N)');
        title('Left Fz');

        nexttile; hold on;
        xline(times(locsL(stL)),'k','LineWidth',2);
        plot(timesWinPlotL,GRFRFz(winPlotL));
        xlim([timesWinPlotL(1) timesWinPlotL(end)]);
        hold off;
        ylabel('Force (N)');
        title('Right Fz');
    end

    ax1 = nexttile; hold on;
    xline(times(locsL(stL)),'k','LineWidth',2);
    xline(times(locsL(stL)+indStartM),'b');
    xline(times(locsL(stL)+indEndM),'b');
    xline(times(locsL(stL)+indStartH),'g');
    xline(times(locsL(stL)+indEndH),'g');
    yline(threshStimArtifact,'r','Stim Artifact Thresh');
    plot(timesWinPlotL,EMG_LTAP(winPlotL));
    title('Left TA - Proximal');
    hold off;

    snippetsHreflexL(stL,:) = EMG_LMG(winPlotL);
    ax2 = nexttile; hold on;
    xline(times(locsL(stL)),'k','LineWidth',2);
    xline(times(locsL(stL)+indStartM),'b');
    xline(times(locsL(stL)+indEndM),'b');
    xline(times(locsL(stL)+indStartH),'g');
    xline(times(locsL(stL)+indEndH),'g');
    plot(timesWinPlotL,EMG_LMG(winPlotL));
    ylabel('Raw EMG (V)');
    title('Left MG');
    hold off;

    ax3 = nexttile; hold on;
    xline(times(locsL(stL)),'k','LineWidth',2);
    xline(times(locsL(stL)+indStartM),'b');
    xline(times(locsL(stL)+indEndM),'b');
    xline(times(locsL(stL)+indStartH),'g');
    xline(times(locsL(stL)+indEndH),'g');
    plot(timesWinPlotL,EMG_LSOL(winPlotL));
    title('Left SOL');
    hold off;

    linkaxes([ax1 ax2 ax3]);
    xlabel(tl,'time (s)');
    xlim([timesWinPlotL(1) timesWinPlotL(end)]);
    ylim([ymin ymax]);
    title(tl,[id ' - Left Leg - Trial' trialNum ' - Stim ' num2str(stL)]);
    saveas(gcf,[pathFigs id '_StimEMGSnippets_LeftLeg_Trial' trialNum ...
        '_Stim' num2str(stL) '.png']);
    saveas(gcf,[pathFigs id '_StimEMGSnippets_LeftLeg_Trial' trialNum ...
        '_Stim' num2str(stL) '.fig']);
    close;
end

%% 9. Plot All Snippets for Each Leg Together in One Figure
% TODO: Add GRF snippets if beneficial
ymin = min([snippetsHreflexL; snippetsHreflexR],[],'all');
ymax = max([snippetsHreflexL; snippetsHreflexR],[],'all');

figure('Units','normalized','OuterPosition',[0 0 1 1]);
tl = tiledlayout('vertical','TileSpacing','tight');

ax1 = nexttile; hold on;
xline(0,'k','LineWidth',2);
xline(indStartM*period,'b');
xline(indEndM*period,'b');
xline(indStartH*period,'g');
xline(indEndH*period,'g');
plot(timesSnippet,snippetsHreflexR);
hold off;
title('Right MG');

ax2 = nexttile; hold on;
xline(0,'k','LineWidth',2);
xline(indStartM*period,'b');
xline(indEndM*period,'b');
xline(indStartH*period,'g');
xline(indEndH*period,'g');
plot(timesSnippet,snippetsHreflexL);
hold off;
title('Left MG');

linkaxes([ax1 ax2]);
xlabel(tl,'time (s)');
ylabel(tl,'MG Raw (V)');
xlim([timesSnippet(1) timesSnippet(end)]);
ylim([ymin ymax]);
title(tl,[id ' - H-Reflex Calibration Waveforms']);
saveas(gcf,[pathFigs id '_HreflexSnippets_Trial' trialNum '.png']);
saveas(gcf,[pathFigs id '_HreflexSnippets_Trial' trialNum '.fig']);

%% 10. Compute M-wave & H-wave Amplitude (assuming waveforms are correct)
% TODO: reject measurements if GRF reveals not in single stance
ampsMwaveR = nan(numStimR,1);
ampsHwaveR = nan(numStimR,1);
ampsMwaveL = nan(numStimL,1);
ampsHwaveL = nan(numStimL,1);

for stR = 1:numStimR    % for each right leg stimulus, ...
    winEMGM = EMG_RMG((locsR(stR)+indStartM):(locsR(stR)+indEndM));
    winEMGH = EMG_RMG((locsR(stR)+indStartH):(locsR(stR)+indEndH));
    ampsMwaveR(stR) = max(winEMGM) - min(winEMGM);
    ampsHwaveR(stR) = max(winEMGH) - min(winEMGH);
end

for stL = 1:numStimL    % for each left leg stimulus, ...
    winEMGM = EMG_LMG((locsL(stL)+indStartM):(locsL(stL)+indEndM));
    winEMGH = EMG_LMG((locsL(stL)+indStartH):(locsL(stL)+indEndH));
    ampsMwaveL(stL) = max(winEMGM) - min(winEMGM);
    ampsHwaveL(stL) = max(winEMGH) - min(winEMGH);
end

%% 11. Compute Means for Unique Stimulation Amplitudes
ampsStimRU = unique(ampsStimR);
ampsStimLU = unique(ampsStimL);
% Gaussian fit function for fitting average H-wave amplitude data
% based on equation 2 (section 2.4. Curve fitting from Brinkworth et al.,
% Journal of Neuroscience Methods, 2007)
fun = @(x,xdata)x(1).*exp(-((((((xdata).^(x(3)))-x(4))./(x(2))).^2)./2));
avgsHwaveR = arrayfun(@(x) mean(ampsHwaveR(ampsStimR == x)),ampsStimRU);
% pdR = fitdist(ampsStimRU','Normal', ...
%     'Frequency',round((avgsHwaveR / max(avgsHwaveR)) * 10000));
% initialize coefficients
coefsR0 = [max(avgsHwaveR) std(ampsStimRU) 1 mean(ampsStimRU)];
coefsR = lsqcurvefit(fun,coefsR0,ampsStimRU,avgsHwaveR);
avgsMwaveR = arrayfun(@(x) mean(ampsMwaveR(ampsStimR == x)),ampsStimRU);
avgsHwaveL = arrayfun(@(x) mean(ampsHwaveL(ampsStimL == x)),ampsStimLU);
% pdL = fitdist(ampsStimLU','Normal', ...
%     'Frequency',round((avgsHwaveL / max(avgsHwaveL)) * 10000));
coefsL0 = [max(avgsHwaveL) std(ampsStimLU) 1 mean(ampsStimLU)];
coefsL = lsqcurvefit(fun,coefsL0,ampsStimLU,avgsHwaveL);
avgsMwaveL = arrayfun(@(x) mean(ampsMwaveL(ampsStimL == x)),ampsStimLU);
% TODO: verify that these values will always be sorted in ascending order

%% 12. Plot Recruitment Curve for Both Legs
% TODO: add normal distribution fit to H-wave recruitment curve to pick out
% peak amplitude and current at which peak occurs

% TODO: do not hardcode x-value (i.e., amplitude) increment for fit
xR = min(ampsStimRU):0.1:max(ampsStimRU);
yR = fun(coefsR,xR);
xL = min(ampsStimLU):0.1:max(ampsStimLU);
yL = fun(coefsL,xL);

% compute Hmax and I_Hmax for the right and left leg
[hMaxR,indHMaxR] = max(yR);
IhMaxR = xR(indHMaxR);
[hMaxL,indHMaxL] = max(yL);
IhMaxL = xL(indHMaxL);

[ampsStimR,indsOrderR] = sort(ampsStimR);
ampsHwaveR = ampsHwaveR(indsOrderR);
ampsMwaveR = ampsMwaveR(indsOrderR);

[ampsStimL,indsOrderL] = sort(ampsStimL);
ampsHwaveL = ampsHwaveL(indsOrderL);
ampsMwaveL = ampsMwaveL(indsOrderL);

figure; hold on;
plot(ampsStimR,ampsMwaveR,'x','Color',[0.5 0.5 0.5],'MarkerSize',10);
p1 = plot(ampsStimRU,avgsMwaveR,'LineWidth',2,'Color',[0.5 0.5 0.5]);
plot(ampsStimR,ampsHwaveR,'ok','MarkerSize',10);
% p2 = plot(ampsStimRU,avgsHwaveR,'k','LineWidth',2);
% p2 = plot(xR,pdf(pdR,xR)*(max(avgsHwaveR)*10),'k','LineWidth',2);
p2 = plot(xR,yR,'k','LineWidth',2);
plot([IhMaxR IhMaxR],[0 hMaxR],'k-.');  % vertical line from I_Hmax to Hmax
% add label to vertical line (I_Hmax) shifted up from x-axis by 5% of max y
% value and over from the line by 0.1 mA
% TODO: do not hardcode x offset for label
text(IhMaxR + 0.1,0 + (0.05*max([ampsMwaveR; ampsHwaveR])), ...
    sprintf('I_{H_{max}} = %.1f mA',IhMaxR));
plot([min(ampsStimR) IhMaxR],[hMaxR hMaxR],'k-.'); % horizontal line to Hmax
% add label to horizontal line (Hmax)
text(min(ampsStimR) + 0.1,hMaxR + (0.05*max([ampsMwaveR; ampsHwaveR])), ...
    sprintf('H_{max} = %.5f V',hMaxR));
hold off;
xlabel('Stimulation Amplitude (mA)');
ylabel('MG EMG Amplitude (V)');
legend([p1 p2],'M-wave','H-wave fit','Location','best');
title([id ' - Trial' trialNum ' - Right Leg - Recruitment Curve']);
saveas(gcf,[pathFigs id '_HreflexRecruitmentCurve_Trial' ...
    trialNum '_RightLeg.png']);
saveas(gcf,[pathFigs id '_HreflexRecruitmentCurve_Trial' ...
    trialNum '_RightLeg.fig']);

figure; hold on;
plot(ampsStimL,ampsMwaveL,'x','Color',[0.5 0.5 0.5],'MarkerSize',10);
p1 = plot(ampsStimLU,avgsMwaveL,'LineWidth',2,'Color',[0.5 0.5 0.5]);
plot(ampsStimL,ampsHwaveL,'ok','MarkerSize',10);
% p2 = plot(ampsStimLU,avgsHwaveL,'k','LineWidth',2);
p2 = plot(xL,yL,'k','LineWidth',2);
plot([IhMaxL IhMaxL],[0 hMaxL],'k-.');  % vertical line from I_Hmax to Hmax
% add label to vertical line (I_Hmax) shifted up from x-axis by 5% of max y
% value and over from the line by 0.1 mA
% TODO: do not hardcode x offset for label
text(IhMaxL + 0.1,0 + (0.05*max([ampsMwaveL; ampsHwaveL])), ...
    sprintf('I_{H_{max}} = %.1f mA',IhMaxL));
plot([min(ampsStimL) IhMaxL],[hMaxL hMaxL],'k-.'); % horizontal line to Hmax
% add label to horizontal line (Hmax)
text(min(ampsStimL) + 0.1,hMaxL + (0.05*max([ampsMwaveL; ampsHwaveL])), ...
    sprintf('H_{max} = %.5f V',hMaxL));
hold off;
xlabel('Stimulation Amplitude (mA)');
ylabel('MG EMG Amplitude (V)');
legend([p1 p2],'M-wave','H-wave fit','Location','best');
title([id ' - Trial' trialNum ' - Left Leg - Recruitment Curve']);
saveas(gcf,[pathFigs id '_HreflexRecruitmentCurve_Trial' ...
    trialNum '_LeftLeg.png']);
saveas(gcf,[pathFigs id '_HreflexRecruitmentCurve_Trial' ...
    trialNum '_LeftLeg.fig']);

