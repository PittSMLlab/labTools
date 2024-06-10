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
    [path,filenameWOExt] = vicon.GetTrialName;   % get trial open in Nexus
    filenameWExt = [filenameWOExt '.c3d'];
    guessID = vicon.GetSubjectNames;    % retrieve participant / session ID
catch   % use below two lines when processing c3d files not open in Nexus
    commandwindow();
    [filenameWExt,path] = uigetfile('*.c3d', ...
        'Please select the c3d file of interest:');
    compsPath = strsplit(path,filesep);
    compsPath = compsPath(cellfun(@(x) ~isempty(x),compsPath));
    guessID = compsPath(contains(compsPath,'SA'));
    if isempty(guessID)
        guessID = compsPath(end);
    end
end
id = inputdlg({'Enter the Participant / Session ID:'},'ID',[1 50], ...
    guessID);   % verify ID with user first
id = id{1};
[~,filename] = fileparts(filenameWExt);
trialNum = filename(end-1:end); % last two characters of file name are #
pathFigs = [path 'HreflexCalFigs' filesep];
if ~exist(pathFigs,'dir')       % if figure folder doesn't exist, ...
    mkdir(pathFigs);            % make it
end

H = btkReadAcquisition([path filenameWExt]);
% using the same method as labtools, retrieve the analog data
[analogs,analogsInfo] = btkGetAnalogs(H);

%% 2. Retrieve User Input Data
% TODO: use the feature of the stimulator to set the current output
% based on the voltage of the trigger pulse to eliminate the need for
% asking the user to input the stimulation amplitudes
prompt = { ...
    ['Enter the EMG sensor muscles in sensor number order for all 16 ' ...
    'sensors of Box 1 (using ''NA'' for sensors not in use):'], ...
    ['Should stimulation trigger pulse data be used to identify ' ...
    'artifact peak times? (''1'' = true (TM calibration where all ' ...
    'triggers in Vicon are valid and have a stim current written ' ...
    'down), ''0'' = false (otherwise))'], ...
    'Enter the right leg stimulation amplitudes (numbers only):', ...
    'Enter the left leg stimulation amplitudes (numbers only):', ...
    ['Stimulation Artifact Threshold (V) (NOTE: only relevant if not ' ...
    'using stim trigger pulse):'], ...
    ['Minimum Time Between Stimulation Pulses (s) (NOTE: only relevant' ...
    ' if not using stim trigger pulse):']};
dlgtitle = 'H-Reflex Calibration Input';
fieldsize = [1 200; 1 200; 1 200; 1 200; 1 200; 1 200];

filesConf = dir([pathFigs id 'Config*.mat']);
fnamesConf = {filesConf.name};
fnameConf = [id 'Config' trialNum '.mat'];
if isempty(fnamesConf)  % if no configuration file exists, ...
    % use the default values for the input
    definput = { ...
        ['RTAP RTAD NA RPER RMG RLG RSOL LTAP LTAD LPER LMG LLG LSOL ' ...
        'NA NA sync1'], ...                     muscle list
        '1', ...                                should use stim trig pulse?
        ['5 5 5 7 7 7 9 9 9 11 11 11 12 12 12 13 13 13 14 14 14 16 16 ' ...
        '16 18 18 18 21 21 21 25 25 25'], ...   right leg stim amplitudes
        ['5 5 5 7 7 7 9 9 9 11 11 11 12 12 12 13 13 13 14 14 14 16 16 ' ...
        '16 18 18 18 21 21 21 25 25 25'], ...   left leg stim amplitudes
        '0.0003', ...                           stim artifact threshold
        '5'};                                 % min. time between stimuli
elseif any(strcmpi(fnamesConf,fnameConf))   % if current trial file, ...
    load([pathFigs fnameConf],'answer');    % load configuration
    definput = answer;                      % set default input to config
elseif ~isempty(fnamesConf) % if there is config but not current trial, ...
    load([pathFigs fnamesConf{end}],'answer');  % load config of last trial
    definput = answer;                      % set default input to config
else    % otherwise, ...
    % do something else
end

answer = inputdlg(prompt,dlgtitle,fieldsize,definput);
% if config file does not exist (save new file) or if it does exist but ...
% has changed (overwrite previous file), ...
if ~isfile([pathFigs fnameConf]) || (isfile([pathFigs fnameConf]) && ...
        ~isequal(definput,answer))
    save([pathFigs fnameConf],'answer','analogs','analogsInfo','H', ...
        'id','path','pathFigs','trialNum','filenameWExt','fnameConf');
end

%% 3. Extract User Input Parameters
% TODO: add more input checks
EMGList1 = strsplit(answer{1},' '); % list of EMG muscle labels
if isempty(EMGList1)                % if no EMG labels input, ...
    error(['No EMG labels have been provided. It is not possible to ' ...
        'generate H-reflex recruitment curves without EMG data.']);
end
% currently using below as a proxy for standing vs. walking trials
shouldUseStimTrig = logical(str2double(answer{2}));
ampsStimR = str2num(answer{3});
ampsStimL = str2num(answer{4});
threshStimArtifact = str2double(answer{5});% stimulation artifact threshold
threshStimTimeSep = str2double(answer{6}); % time between stim

numStimR = length(ampsStimR);   % number of times stimulated right leg
numStimL = length(ampsStimL);   % number of times stimulated left leg

%% 4. Retrieve EMG Data
% TODO: Consider making each data retrieval its own separate function for
% modularity and easy access and use for future applications
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

%% 5. Retrieve Ground Reaction Force (GRF) Data If It Exists
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

%% 6. Retrieve H-Reflex Stimulator Pin Data If It Exists
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

% clear analogs* %Save memory space, no longer need analog data, it was already loaded

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

%% 7. Define H-Reflex Calibration Trial Parameters
% NOTE: should always be same across trials and should be same for forces
period = EMG.sampPeriod;    % sampling period
threshSamps = threshStimTimeSep / period;  % convert to samples

%% 8. Identify Locations of the Stimulation Artifacts
% extract relevant EMG data
% TODO: still need to handle case of only recording data from one leg
% during a trial (i.e., only want to compute parameters and plot one leg)

% MG is the muscle used for the H-reflex
hasMG = contains(EMG.labels,'MG');
if ~any(hasMG)  % if no medial gastrocnemius muscle data, ...
    error('There is no medial gastrocnemius muscle data present.');
else            % otherwise, ...
    if sum(hasMG) == 2  % if data from both MG's present, ...
        EMG_LMG = EMG.Data(:,contains(EMG.labels,'LMG'));
        EMG_RMG = EMG.Data(:,contains(EMG.labels,'RMG'));
    elseif contains(EMG.labels{hasMG},'L')  % if left MG only, ...
        EMG_LMG = EMG.Data(:,contains(EMG.labels,'LMG'));
    elseif contains(EMG.labels{hasMG},'R')  % if right MG only, ...
        EMG_RMG = EMG.Data(:,contains(EMG.labels,'RMG'));
    else                % otherwise, ...
        % throw an error
    end
end

% use proximal TA to determine stim artifact time
hasTAP = contains(EMG.labels,'TAP');
if ~any(hasTAP) % if no proximal tibialis anterior muscle data, ...
    error('There is no tibialis anterior muscle data present.');
else            % otherwise, ...
    if sum(hasTAP) == 2  % if data from both TAP's present, ...
        EMG_LTAP = EMG.Data(:,contains(EMG.labels,'LTAP'));
        EMG_RTAP = EMG.Data(:,contains(EMG.labels,'RTAP'));
    elseif contains(EMG.labels{hasTAP},'L')  % if left TAP only, ...
        EMG_LTAP = EMG.Data(:,contains(EMG.labels,'LTAP'));
    elseif contains(EMG.labels{hasTAP},'R')  % if right TAP only, ...
        EMG_RTAP = EMG.Data(:,contains(EMG.labels,'RTAP'));
    else                % otherwise, ...
        % throw an error
    end
end

% if missing any of the EMG signals used below, ...
if any(isempty([EMG_LTAP EMG_RTAP EMG_LMG EMG_RMG]))
    % TODO: update handling of cases when one or more of these signals is
    % missing (e.g., only conducting calibration on one leg)
    error('Missing one or more EMG signals.');
end

times = EMG.Time;   % if want to plot, can use the time array

% TODO: implement check for if forces should be used in case of standing on
% the treadmill but not walking during calibration
% NOTE: using 'shouldUseStimTrig' as a proxy for walking trials where
% useful forces are present
% if forces are present and useful to examine (i.e., walking trial), ...
if hasForces && shouldUseStimTrig
    GRFRFz = GRF.Data(:,contains(GRF.labels,'fz2','IgnoreCase',true));
    GRFLFz = GRF.Data(:,contains(GRF.labels,'fz1','IgnoreCase',true));
end

% NOTE: it does not work to use stim trigger pulse to retrieve peak times
% if stimulator is disabled during trial (because there will be trigger
% pulse but participant will not have been stimulated)
% if there is stimulation trigger pulse data and it should be used to
% identify the locations of the artifact peaks, ...
if shouldUseStimTrig && hasStimTrig
    indsStimArtifact = Hreflex.extractStimArtifactIndsFromTrigger( ...
        times,{EMG_RTAP,EMG_LTAP},HreflexStimPin);
    locsR = indsStimArtifact{1};
    locsL = indsStimArtifact{2};

    if (numStimR ~= length(locsR)) || (numStimL ~= length(locsL))
        error(['The number of stimulation trigger pulses does not ' ...
            'match the number of input stimulation amplitudes.']);
    end

    Hreflex.plotStimArtifactPeaks(times,{EMG_RTAP,EMG_LTAP}, ...
        {locsR,locsL},id,trialNum,pathFigs);
else
    warning(['No stimulation trigger signal being used. Artifact ' ...
        'identification may not be as accurate.']);

    [~,locsR] = findpeaks(EMG_RTAP,'NPeaks',numStimR, ...
        'MinPeakHeight',threshStimArtifact,'MinPeakDistance',threshSamps);
    [~,locsL] = findpeaks(EMG_LTAP,'NPeaks',numStimL, ...
        'MinPeakHeight',threshStimArtifact,'MinPeakDistance',threshSamps);

    Hreflex.plotStimArtifactPeaks(times,{EMG_RTAP,EMG_LTAP}, ...
        {locsR,locsL},id,trialNum,threshStimArtifact,pathFigs);
end

% ask user if would like to continue after verifying artifact detection
shouldCont = inputdlg({['Would you like to continue the script (i.e., ' ...
    'was artifact detection accurate, ''1'' = true, ''0'' = false)?']}, ...
    '',[1 80],{'1'});
shouldCont = logical(str2double(shouldCont{1}));
if ~shouldCont  % if should not continue with the script, ...
    return;     % return from script so user can rerun artifact detection
end

%% 9. Plot All Stimuli to Verify the Waveforms & Timing (Via GRFs)
snipStart = -0.005; % 5 ms before artifact peak
snipEnd = 0.045;    % 45 ms after artifact peak
timesSnippet = snipStart:period:snipEnd;
numSamps = length(timesSnippet);

% store H-reflex snippets to plot them together
snippetsHreflexR = nan(numStimR,numSamps);
snippetsHreflexL = nan(numStimL,numSamps);
% store force snippets to plot them together
snippetsForceRR = nan(numStimR,numSamps);   % ipsi to stim
snippetsForceRL = nan(numStimR,numSamps);   % contra to stim
snippetsForceLL = nan(numStimL,numSamps);
snippetsForceLR = nan(numStimL,numSamps);
% plot the right leg stimuli
% TODO: add checks for trials without stimuli for one leg or the other
for stR = 1:numStimR    % for each right leg stimulus, ...
    winPlotR = (locsR(stR) + (snipStart/period)):(locsR(stR) + (snipEnd/period));
    timesWinPlotR = times(winPlotR);
    snippetsHreflexR(stR,:) = EMG_RMG(winPlotR);
    if hasForces && shouldUseStimTrig
        snippetsForceRR(stR,:) = GRFRFz(winPlotR);
        snippetsForceRL(stR,:) = GRFLFz(winPlotR);
    end

    % snipsStimAllMuscles = [EMG_RTAP(winPlotR); EMG_RMG(winPlotR); ...
    %     EMG_RSOL(winPlotR)];
    % ymin = min(snipsStimAllMuscles,[],'all');
    % ymax = max(snipsStimAllMuscles,[],'all');

    % TODO: make showing snippet plots an input so that user can decide
    %     figure('Units','normalized','OuterPosition',[0 0 1 1]);

    % TODO: throw error if EMG arrays and GRF arrays are different length
    % (should be identical since sampled at the same rate)
    %     if hasForces
    %         tl = tiledlayout(5,1,'TileSpacing','tight');
    %
    %         nexttile; hold on;
    %         xline(times(locsR(stR)),'k','LineWidth',2);
    %         plot(timesWinPlotR,GRFRFz(winPlotR));
    %         xlim([timesWinPlotR(1) timesWinPlotR(end)]);
    %         hold off;
    %         ylabel('Force (N)');
    %         title('Right Fz');
    %
    %         nexttile; hold on;
    %         xline(times(locsR(stR)),'k','LineWidth',2);
    %         plot(timesWinPlotR,GRFLFz(winPlotR));
    %         xlim([timesWinPlotR(1) timesWinPlotR(end)]);
    %         hold off;
    %         ylabel('Force (N)');
    %         title('Left Fz');
    %     else
    %         tl = tiledlayout(3,1,'TileSpacing','tight');
    %     end
    %
    %     ax1 = nexttile; hold on;
    %     xline(times(locsR(stR)),'k','LineWidth',2);
    %     xline(times(locsR(stR)+indStartM),'b');
    %     xline(times(locsR(stR)+indEndM),'b');
    %     xline(times(locsR(stR)+indStartH),'g');
    %     xline(times(locsR(stR)+indEndH),'g');
    %     % only plot the stimulation artifact threshold if it is used
    %     % if ~(hasStimTrig && shouldUseStimTrig)
    %         yline(threshStimArtifact,'r','Stim Artifact Thresh');
    %     % end
    %     plot(timesWinPlotR,EMG_RTAP(winPlotR));
    %     title('Right TA - Proximal');
    %     hold off;
    %
    %     ax2 = nexttile; hold on;
    %     xline(times(locsR(stR)),'k','LineWidth',2);
    %     xline(times(locsR(stR)+indStartM),'b');
    %     xline(times(locsR(stR)+indEndM),'b');
    %     xline(times(locsR(stR)+indStartH),'g');
    %     xline(times(locsR(stR)+indEndH),'g');
    %     plot(timesWinPlotR,EMG_RMG(winPlotR));
    %     ylabel('Raw EMG (V)');
    %     title('Right MG');
    %     hold off;
    %
    %     ax3 = nexttile; hold on;
    %     xline(times(locsR(stR)),'k','LineWidth',2);
    %     xline(times(locsR(stR)+indStartM),'b');
    %     xline(times(locsR(stR)+indEndM),'b');
    %     xline(times(locsR(stR)+indStartH),'g');
    %     xline(times(locsR(stR)+indEndH),'g');
    %     plot(timesWinPlotR,EMG_RSOL(winPlotR));
    %     title('Right SOL');
    %     hold off;
    %
    %     linkaxes([ax1 ax2 ax3]);
    %     xlabel(tl,'time (s)');
    %     xlim([timesWinPlotR(1) timesWinPlotR(end)]);
    %     ylim([ymin ymax]);
    %     title(tl,[id ' - Right Leg - Trial' trialNum ' - Stim ' num2str(stR)]);
    %     saveas(gcf,[pathFigs id '_StimEMGSnippets_RightLeg_Trial' trialNum ...
    %         '_Stim' num2str(stR) '.png']);
    %     saveas(gcf,[pathFigs id '_StimEMGSnippets_RightLeg_Trial' trialNum ...
    %         '_Stim' num2str(stR) '.fig']);
    %     close;
end

% plot the left leg stimuli
for stL = 1:numStimL    % for each left leg stimulus, ...
    winPlotL = (locsL(stL) + (snipStart/period)):(locsL(stL) + (snipEnd/period));
    timesWinPlotL = times(winPlotL);
    snippetsHreflexL(stL,:) = EMG_LMG(winPlotL);
    if hasForces && shouldUseStimTrig
        snippetsForceLL(stL,:) = GRFLFz(winPlotL);
        snippetsForceLR(stL,:) = GRFRFz(winPlotL);
    end

    % snipsStimAllMuscles = [EMG_LTAP(winPlotL); EMG_LMG(winPlotL); ...
    %     EMG_LSOL(winPlotL)];
    % ymin = min(snipsStimAllMuscles,[],'all');
    % ymax = max(snipsStimAllMuscles,[],'all');

    %     figure('Units','normalized','OuterPosition',[0 0 1 1]);
    %     tl = tiledlayout(5,1,'TileSpacing','tight');
    %
    %     if hasForces    % if force data is present, ...
    %         nexttile; hold on;
    %         xline(times(locsL(stL)),'k','LineWidth',2);
    %         plot(timesWinPlotL,GRFLFz(winPlotL));
    %         xlim([timesWinPlotL(1) timesWinPlotL(end)]);
    %         hold off;
    %         ylabel('Force (N)');
    %         title('Left Fz');
    %
    %         nexttile; hold on;
    %         xline(times(locsL(stL)),'k','LineWidth',2);
    %         plot(timesWinPlotL,GRFRFz(winPlotL));
    %         xlim([timesWinPlotL(1) timesWinPlotL(end)]);
    %         hold off;
    %         ylabel('Force (N)');
    %         title('Right Fz');
    %     end
    %
    %     ax1 = nexttile; hold on;
    %     xline(times(locsL(stL)),'k','LineWidth',2);
    %     xline(times(locsL(stL)+indStartM),'b');
    %     xline(times(locsL(stL)+indEndM),'b');
    %     xline(times(locsL(stL)+indStartH),'g');
    %     xline(times(locsL(stL)+indEndH),'g');
    %     yline(threshStimArtifact,'r','Stim Artifact Thresh');
    %     plot(timesWinPlotL,EMG_LTAP(winPlotL));
    %     title('Left TA - Proximal');
    %     hold off;
    %
    %     ax2 = nexttile; hold on;
    %     xline(times(locsL(stL)),'k','LineWidth',2);
    %     xline(times(locsL(stL)+indStartM),'b');
    %     xline(times(locsL(stL)+indEndM),'b');
    %     xline(times(locsL(stL)+indStartH),'g');
    %     xline(times(locsL(stL)+indEndH),'g');
    %     plot(timesWinPlotL,EMG_LMG(winPlotL));
    %     ylabel('Raw EMG (V)');
    %     title('Left MG');
    %     hold off;
    %
    %     ax3 = nexttile; hold on;
    %     xline(times(locsL(stL)),'k','LineWidth',2);
    %     xline(times(locsL(stL)+indStartM),'b');
    %     xline(times(locsL(stL)+indEndM),'b');
    %     xline(times(locsL(stL)+indStartH),'g');
    %     xline(times(locsL(stL)+indEndH),'g');
    %     plot(timesWinPlotL,EMG_LSOL(winPlotL));
    %     title('Left SOL');
    %     hold off;
    %
    %     linkaxes([ax1 ax2 ax3]);
    %     xlabel(tl,'time (s)');
    %     xlim([timesWinPlotL(1) timesWinPlotL(end)]);
    %     ylim([ymin ymax]);
    %     title(tl,[id ' - Left Leg - Trial' trialNum ' - Stim ' num2str(stL)]);
    %     saveas(gcf,[pathFigs id '_StimEMGSnippets_LeftLeg_Trial' trialNum ...
    %         '_Stim' num2str(stL) '.png']);
    %     saveas(gcf,[pathFigs id '_StimEMGSnippets_LeftLeg_Trial' trialNum ...
    %         '_Stim' num2str(stL) '.fig']);
    %     close;
end

%% 10.1 Plot All Snippets for Each Leg Together in One Figure
% if force data present and should use the stimulation trigger signal to
% localize the artifact peaks (using as proxy for walking trial), ...
if hasForces && shouldUseStimTrig
    Hreflex.plotSnippets(timesSnippet,{[snippetsForceRR; ...
        snippetsForceRL],[snippetsForceLL; snippetsForceLR], ...
        snippetsHreflexR,snippetsHreflexL},{'Force (N)','Force (N)', ...
        'MG Raw EMG (V)','MG Raw EMG (V)'}, ...
        {'Right & Left Fz - Right Stim','Left & Right Fz - Left Stim', ...
        'Right MG','Left MG'},id,trialNum,pathFigs);
else        % otherwise, do not plot the forces
    Hreflex.plotSnippets(timesSnippet,{snippetsHreflexR, ...
        snippetsHreflexL},{'Raw EMG (V)','Raw EMG (V)'}, ...
        {'Right MG','Left MG'},id,trialNum,pathFigs);
end

%% 10.2 Plot Snippets for a Given Amplitude for Each Leg Together
% TODO: move the finding of unique amplitudes and indices up here, make
% this a helper function to reduce code duplication
% TODO: Add dots to show the min and max picked out for each wave to see if
% first/last points (i.e., if makes sense)

%% 11. Compute M-wave & H-wave Amplitude (assuming waveforms are correct)
% TODO: reject measurements if GRF reveals not in single stance
amps = Hreflex.computeHreflexAmplitudes({EMG_RMG;EMG_LMG},indsStimArtifact);

ampsMwaveR = amps{1,1};
ampsHwaveR = amps{1,2};
ampsNoiseR = amps{1,3};
ampsMwaveL = amps{2,1};
ampsHwaveL = amps{2,2};
ampsNoiseL = amps{2,3};

%% 12. Compute Means and H/M Ratios for Unique Stimulation Amplitudes
ampsStimRU = unique(ampsStimR);
ampsStimLU = unique(ampsStimL);
% Gaussian fit function for fitting average H-wave amplitude data
% based on equation 2 (section 2.4. Curve fitting from Brinkworth et al.,
% Journal of Neuroscience Methods, 2007)
fun = @(x,xdata)x(1).*exp(-((((((xdata).^(x(3)))-x(4))./(x(2))).^2)./2));
avgsHwaveR = arrayfun(@(x) mean(ampsHwaveR(ampsStimR == x),'omitmissing'),ampsStimRU);
% TODO: alternate approach would be to convert the mean H-wave amplitudes
% to integer "frequencies" for each stim amplitude and fit a normal dist.
% pdR = fitdist(ampsStimRU','Normal', ...
%     'Frequency',round((avgsHwaveR / max(avgsHwaveR)) * 10000));
% initialize coefficients
coefsR0 = [max(avgsHwaveR) std(ampsStimRU) 1 mean(ampsStimRU)];
% coefsR = lsqcurvefit(fun,coefsR0,ampsStimRU,avgsHwaveR);
avgsMwaveR = arrayfun(@(x) mean(ampsMwaveR(ampsStimR == x),'omitmissing'),ampsStimRU);
avgsHwaveL = arrayfun(@(x) mean(ampsHwaveL(ampsStimL == x),'omitmissing'),ampsStimLU);
% pdL = fitdist(ampsStimLU','Normal', ...
%     'Frequency',round((avgsHwaveL / max(avgsHwaveL)) * 10000));
coefsL0 = [max(avgsHwaveL) std(ampsStimLU) 1 mean(ampsStimLU)];
% coefsL = lsqcurvefit(fun,coefsL0,ampsStimLU,avgsHwaveL);
avgsMwaveL = arrayfun(@(x) mean(ampsMwaveL(ampsStimL == x),'omitmissing'),ampsStimLU);
% TODO: verify that these values will always be sorted in ascending order
% and, if not, sort them

ratioR = ampsHwaveR ./ ampsMwaveR;
ratioL = ampsHwaveL ./ ampsMwaveL;
avgsRatioR = arrayfun(@(x) mean(ratioR(ampsStimR == x)),ampsStimRU);
avgsRatioL = arrayfun(@(x) mean(ratioL(ampsStimL == x)),ampsStimLU);

%% Plot the Noise Distributions for Both Legs

% compute four times the noise floor (75th percentile) to determine whether
% to send the participant home or not (at least one leg must exceed
% threshold)
threshNoiseR = 4 * mean(ampsNoiseR); % 4 * prctile(ampsNoiseR,75);
threshNoiseL = 4 * mean(ampsNoiseL); % 4 * prctile(ampsNoiseL,75);

figure; hold on;
histogram(ampsNoiseR*1000,0.00:0.05:0.30,'Normalization','probability');
xline(mean(ampsNoiseR*1000),'r',sprintf('Mean = %.2f mV', ...
    mean(ampsNoiseR*1000)),'LineWidth',2);
xline(median(ampsNoiseR*1000),'g',sprintf('Median = %.2f mV', ...
    median(ampsNoiseR*1000)),'LineWidth',2);
xline(prctile(ampsNoiseR*1000,75),'k',sprintf( ...
    '75^{th} Percentile = %.2f mV',prctile(ampsNoiseR*1000,75)),'LineWidth',2);
hold off;
axis([0 0.3 0 0.8]);
xlabel('Noise Amplitude Peak-to-Peak (mV)');
ylabel('Proportion of Stimuli');
title([id ' - Trial' trialNum ' - Right Leg - Noise Distribution']);
saveas(gcf,[pathFigs id '_NoiseDistribution_Trial' trialNum ...
    '_RightLeg.png']);
saveas(gcf,[pathFigs id '_NoiseDistribution_Trial' trialNum ...
    '_RightLeg.fig']);

figure; hold on;
histogram(ampsNoiseL*1000,0.00:0.05:0.30,'Normalization','probability');
xline(mean(ampsNoiseL*1000),'r',sprintf('Mean = %.2f mV', ...
    mean(ampsNoiseL*1000)),'LineWidth',2);
xline(median(ampsNoiseL*1000),'g',sprintf('Median = %.2f mV', ...
    median(ampsNoiseL*1000)),'LineWidth',2);
xline(prctile(ampsNoiseL*1000,75),'k',sprintf( ...
    '75^{th} Percentile = %.2f mV',prctile(ampsNoiseL*1000,75)),'LineWidth',2);
hold off;
axis([0 0.3 0 0.8]);
xlabel('Noise Amplitude Peak-to-Peak (mV)');
ylabel('Proportion of Stimuli');
title([id ' - Trial' trialNum ' - Left Leg - Noise Distribution']);
saveas(gcf,[pathFigs id '_NoiseDistribution_Trial' trialNum ...
    '_LeftLeg.png']);
saveas(gcf,[pathFigs id '_NoiseDistribution_Trial' trialNum ...
    '_LeftLeg.fig']);

%% 12. Plot Recruitment Curve for Both Legs
% TODO: add normal distribution fit to H-wave recruitment curve to pick out
% peak amplitude and current at which peak occurs
% TODO: consider displaying all raw values in mV rather than V
incX = 0.1; % increment for curve fit (in mA)
xR = min(ampsStimRU):incX:max(ampsStimRU);
% yR = fun(coefsR,xR);
xL = min(ampsStimLU):incX:max(ampsStimLU);
% yL = fun(coefsL,xL);

% compute Hmax and I_Hmax for the right and left leg
[hMaxR,indHMaxR] = max(avgsHwaveR); % [hMaxR,indHMaxR] = max(yR);
IhMaxR = ampsStimRU(indHMaxR); % IhMaxR = xR(indHMaxR);
[hMaxL,indHMaxL] = max(avgsHwaveL); % [hMaxL,indHMaxL] = max(yL);
IhMaxL = ampsStimLU(indHMaxL); % IhMaxL = xL(indHMaxL);

[ampsStimR,indsOrderR] = sort(ampsStimR);
ampsHwaveR = ampsHwaveR(indsOrderR);
ampsMwaveR = ampsMwaveR(indsOrderR);

[ampsStimL,indsOrderL] = sort(ampsStimL);
ampsHwaveL = ampsHwaveL(indsOrderL);
ampsMwaveL = ampsMwaveL(indsOrderL);

figure; hold on;
% TODO: Change Vpp threshold line to a noise floor line with the computed
% value printed above the line in mV
% TODO: consider also showing a 4xNoise line for decision making during exp
yline(threshNoiseR,'r','H-Wave V_{pp} Threshold');
plot(ampsStimR,ampsMwaveR,'x','Color',[0.5 0.5 0.5],'MarkerSize',10);
p1 = plot(ampsStimRU,avgsMwaveR,'LineWidth',2,'Color',[0.5 0.5 0.5]);
plot(ampsStimR,ampsHwaveR,'ok','MarkerSize',10);
p2 = plot(ampsStimRU,avgsHwaveR,'k','LineWidth',2);
% p2 = plot(xR,pdf(pdR,xR)*(max(avgsHwaveR)*10),'k','LineWidth',2);
% p3 = plot(xR,yR,'b--','LineWidth',2);
plot([IhMaxR IhMaxR],[0 hMaxR],'k-.');  % vertical line from I_Hmax to Hmax
% add label to vertical line (I_Hmax) shifted up from x-axis by 5% of max y
% value and over from the line by 0.1 mA
% TODO: do not hardcode x offset for label
text(IhMaxR + 0.1,0 + (0.05*max([ampsMwaveR; ampsHwaveR])), ...
    sprintf('I_{H_{max}} = %.1f mA',IhMaxR));
plot([min(ampsStimR)-1 IhMaxR],[hMaxR hMaxR],'k-.');    % horizontal line to Hmax
% add label to horizontal line (Hmax)
text(min(ampsStimR)-1 + 0.1, ...
    hMaxR + (0.05*max([ampsMwaveR; ampsHwaveR])), ...
    sprintf('H_{max} = %.5f V',hMaxR));
hold off;
xlim([min(ampsStimR)-1 max(ampsStimR)+1]);
xlabel('Stimulation Amplitude (mA)');
ylabel('MG EMG Amplitude (V)');
legend([p1 p2],'M-wave','H-wave','Location','best');
title([id ' - Trial' trialNum ' - Right Leg - Recruitment Curve']);
saveas(gcf,[pathFigs id '_HreflexRecruitmentCurve_Trial' ...
    trialNum '_RightLeg.png']);
saveas(gcf,[pathFigs id '_HreflexRecruitmentCurve_Trial' ...
    trialNum '_RightLeg.fig']);

figure; hold on;
yline(threshNoiseL,'r','H-Wave V_{pp} Threshold');
plot(ampsStimL,ampsMwaveL,'x','Color',[0.5 0.5 0.5],'MarkerSize',10);
p1 = plot(ampsStimLU,avgsMwaveL,'LineWidth',2,'Color',[0.5 0.5 0.5]);
plot(ampsStimL,ampsHwaveL,'ok','MarkerSize',10);
p2 = plot(ampsStimLU,avgsHwaveL,'k','LineWidth',2);
% p3 = plot(xL,yL,'b--','LineWidth',2);
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
xlim([min(ampsStimL)-1 max(ampsStimL)+1]);
xlabel('Stimulation Amplitude (mA)');
ylabel('MG EMG Amplitude (V)');
legend([p1 p2],'M-wave','H-wave','Location','best');
title([id ' - Trial' trialNum ' - Left Leg - Recruitment Curve']);
saveas(gcf,[pathFigs id '_HreflexRecruitmentCurve_Trial' ...
    trialNum '_LeftLeg.png']);
saveas(gcf,[pathFigs id '_HreflexRecruitmentCurve_Trial' ...
    trialNum '_LeftLeg.fig']);

%% 13. Plot Ratio of H-wave to M-wave amplitude
% compute Ratio_max and I_Ratio_max for the right and left leg
[ratioMaxR,indRatioMaxR] = max(avgsRatioR);
IRatioMaxR = ampsStimRU(indRatioMaxR);
[ratioMaxL,indRatioMaxL] = max(avgsRatioL);
IRatioMaxL = ampsStimLU(indRatioMaxL);

ratioR = ratioR(indsOrderR);
ratioL = ratioL(indsOrderL);

figure; hold on;
% yline(threshWaveAmp,'r','V_{pp} Threshold');
plot(ampsStimR,ratioR,'ok','MarkerSize',10);
plot(ampsStimRU,avgsRatioR,'k','LineWidth',2);
plot([IRatioMaxR IRatioMaxR],[0 ratioMaxR],'k-.');  % vertical line from I_Ratio_max to Ratio_max
% add label to vertical line (I_Ratio_max) shifted up from x-axis by 5% of
% max y value and over from the line by 0.1 mA
% TODO: do not hardcode x offset for label
text(IRatioMaxR + 0.1,0 + (0.05*max(ratioR)), ...
    sprintf('I_{Ratio_{max}} = %.1f mA',IRatioMaxR));
plot([min(ampsStimR) IRatioMaxR],[ratioMaxR ratioMaxR],'k-.'); % horizontal line to Ratio_max
% add label to horizontal line (Ratio_max)
text(min(ampsStimR) + 0.1,ratioMaxR + (0.05*max(ratioR)), ...
    sprintf('Ratio_{max} = %.5f',ratioMaxR));
hold off;
xlim([min(ampsStimR)-1 max(ampsStimR)+1]);
xlabel('Stimulation Amplitude (mA)');
ylabel('H:M Ratio');
title([id ' - Trial' trialNum ' - Right Leg']);
saveas(gcf,[pathFigs id '_HreflexRatioCurve_Trial' trialNum ...
    '_RightLeg.png']);
saveas(gcf,[pathFigs id '_HreflexRatioCurve_Trial' trialNum ...
    '_RightLeg.fig']);

figure; hold on;
% yline(threshWaveAmp,'r','V_{pp} Threshold');
plot(ampsStimL,ratioL,'ok','MarkerSize',10);
plot(ampsStimLU,avgsRatioL,'k','LineWidth',2);
plot([IRatioMaxL IRatioMaxL],[0 ratioMaxL],'k-.');  % vertical line from I_Ratio_max to Ratio_max
% add label to vertical line (I_Ratio_max) shifted up from x-axis by 5% of
% max y value and over from the line by 0.1 mA
% TODO: do not hardcode x offset for label
text(IRatioMaxL + 0.1,0 + (0.05*max(ratioL)), ...
    sprintf('I_{Ratio_{max}} = %.1f mA',IRatioMaxL));
plot([min(ampsStimL) IRatioMaxL],[ratioMaxL ratioMaxL],'k-.'); % horizontal line to Ratio_max
% add label to horizontal line (Ratio_max)
text(min(ampsStimL) + 0.1,ratioMaxL + (0.05*max(ratioL)), ...
    sprintf('Ratio_{max} = %.5f',ratioMaxL));
hold off;
xlim([min(ampsStimL)-1 max(ampsStimL)+1]);
xlabel('Stimulation Amplitude (mA)');
ylabel('H:M Ratio');
title([id ' - Trial' trialNum ' - Left Leg']);
saveas(gcf,[pathFigs id '_HreflexRatioCurve_Trial' trialNum ...
    '_LeftLeg.png']);
saveas(gcf,[pathFigs id '_HreflexRatioCurve_Trial' trialNum ...
    '_LeftLeg.fig']);

