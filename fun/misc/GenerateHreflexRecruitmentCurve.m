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
% Vicon Nexus must be open, offline, and the desired trial loaded
vicon = ViconNexus();
[path,filename] = vicon.GetTrialName; % ask Nexus which trial is open
filename = [filename '.c3d'];

% use the below two lines when processing c3d files not open in Nexus:
% commandwindow();
% [filename,path] = uigetfile('*.c3d', ...
%     'Please select the c3d file of interest:');
H = btkReadAcquisition([path filename]);

% using the same method as Labtools, retrieve the analog data
[analogs,analogsInfo] = btkGetAnalogs(H);

%% 2. Retrieve User Input Data

% TODO: Use the feature of the stimulator to set the current output
% based on the voltage of the trigger pulse to eliminate the need for
% asking the user to input the stimulation amplitudes

prompt = { ...
    'Enter the EMG sensor muscles in sensor number order:', ...
    'Was trial a walking calibration? (''1'' = true, ''0'' = false)', ...
    'Enter the right leg stimulation amplitudes (numbers only):', ...
    'Enter the left leg stimulation amplitudes (numbers only):', ...
    'Stimulation Artifact Threshold (V):', ...
    'Minimum Time Between Stimulation Pulses (s):'};
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

% TODO: add input argument checks (e.g., throw error if EMG is left blank)
EMGList1 = strsplit(answer{1},' ');
isCalWalking = boolean(str2double(answer{2}));
ampsStimR = str2num(answer{3});
ampsStimL = str2num(answer{4});
threshStimArtifact = str2double(answer{5});% stimulation artifact threshold
threshStimTimeSep = str2double(answer{6}); % at least 5 sec between stim

numStimR = length(ampsStimR);   % number of times stimulated right leg
numStimL = length(ampsStimL);   % number of times stimulated left leg

%% Retrieve EMG Data
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

EMGData = [];
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

syncIdx=strncmpi(EMGList,'Sync',4); %Compare first 4 chars in string list
sync=allData(:,syncIdx);

if ~isempty(sync) %Only proceeding with synchronization if there are sync signals
    %Clipping top & bottom 0.1%
    [sync] = clipSignals(sync,.1);
    N=size(sync,1);
    aux=medfilt1(sync,20,[],1); %Median filter to remove spikes
    %aux(aux>(median(aux)+5*iqr(aux)) | aux <(median(aux)-5*iqr(aux)))=median(aux(:)); %Truncating samples outside the median+-5*iqr range
    aux=medfilt1(diff(aux),10,[],1);
    if secondFile
        [~,timeScaleFactor,lagInSamples,~] = matchSignals(aux(:,1),aux(:,2));
        %                 [~,timeScaleFactor,lagInSamples,~] = matchSignals(refAux,aux(:,2));
        newRelData2 = resampleShiftAndScale(relData2,timeScaleFactor,lagInSamples,1); %Aligning relData2 to relData1. There is still the need to find the overall delay of the EMG system with respect to forceplate data.
    end
    [~,timeScaleFactorA,lagInSamplesA,~] = matchSignals(refAux,aux(:,1));
    newRelData = resampleShiftAndScale(relData,1,lagInSamplesA,1);
    if secondFile
        newRelData2 = resampleShiftAndScale(newRelData2,1,lagInSamplesA,1);
        %                 [~,timeScaleFactor,lagInSamples,~] = matchSignals(refAux,aux(:,2)); %DMMO and ARL change to deal w aligment
        %                 newRelData2 = resampleShiftAndScale(newRelData2,1,lagInSamples,1);  %DMMO and ARL change to deal w aligment
        % %
    end
    
    %Only keeping matrices of same size to one another:
    if secondFile
        [auxData, auxData2] = truncateToSameLength(newRelData,newRelData2);
        clear newRelData*
        allData=[auxData,auxData2];
        clear auxData*
    else
        allData=newRelData;
    end
    
    %Finding gains through least-squares on high-pass filtered synch
    %signals (why using HPF for gains and not for synch?)
    [refSync] = clipSignals(refSync(:),.1);
    refSync=idealHPF(refSync,0); %Removing DC only
    [allData,refSync]=truncateToSameLength(allData,refSync);
    sync=allData(:,syncIdx);
    [sync] = clipSignals(sync,.1);
    sync=idealHPF(sync,0);
    gain1=refSync'/sync(:,1)';
    indStart=round(max([lagInSamplesA+1,1]));
    reducedRefSync=refSync(indStart:end);
    indStart=round(max([lagInSamplesA+1,1]));
    reducedSync1=sync(indStart:end,1)*gain1;
    E1=sum((reducedRefSync-reducedSync1).^2)/sum(refSync.^2); %Computing error energy as % of original signal energy, only considering the time interval were signals were simultaneously recorded.
    if secondFile
        gain2=refSync'/sync(:,2)';
        indStart=round(max([lagInSamplesA+1+lagInSamples,1]));
        reducedRefSync2=refSync(indStart:end);
        %                 indStart=round(max([lagInSamplesA+1+lagInSamples,1]));
        reducedSync2=sync(indStart:end,2)*gain2;
        E2=sum((reducedRefSync2-reducedSync2).^2)/sum(refSync.^2);
        %Comparing the two bases' synchrony mechanism (not to ref signal):
        %reducedSync1a=sync(max([lagInSamplesA+1+lagInSamples,1,lagInSamplesA+1]):end,1)*gain1;
        %reducedSync2a=sync(max([lagInSamplesA+1+lagInSamples,1,lagInSamplesA+1]):end,2)*gain2;
        %E3=sum((reducedSync1a-reducedSync2a).^2)/sum(refSync.^2);
    else
        E2=0;
        gain2=NaN;
        timeScaleFactor=NaN;
        lagInSamples=NaN;
    end
    
    %Analytic measure of alignment problems
    disp(['Sync complete: mismatch signal energy (as %) was ' num2str(100*E1,3) ' and ' num2str(100*E2,3) '.'])
    disp(['Sync parameters to ref. signal were: gains= ' num2str(gain1,4) ', ' num2str(gain2,4) '; delays= ' num2str(lagInSamplesA/EMGfrequency,3) 's, ' num2str((lagInSamplesA+lagInSamples)/EMGfrequency,3) 's']);
    disp(['Typical sync parameters are: gains= -933.3 +- 0.2 (both); delays= -0.025s +- 0.001, 0.014 +- 0.002'])
    disp(['Sync parameters between PCs were: gain= ' num2str(gain1/gain2,4) '; delay= ' num2str((lagInSamples)/EMGfrequency,3) 's; sampling mismatch (ppm)= ' num2str(1e6*(1-timeScaleFactor),3)]);
    disp(['Typical sync parameters are: gain= 1; delay= 0.040s; sampling= 35 ppm'])
    if isnan(E1) || isnan(E2) || E1>.01 || E2>.01 %Signal difference has at least 1% of original signal energy
        warning(['Time alignment doesnt seem to have worked: signal mismatch is too high in trial ' num2str(t) '.'])
        h=figure;
        subplot(2,2,[1:2])
        hold on
        title(['Trial ' num2str(t) ' Synchronization'])
        time=[0:length(refSync)-1]*1/EMGfrequency;
        plot(time,refSync)
        plot(time,sync(:,1)*gain1,'r')
        if secondFile
            plot(time,sync(:,2)*gain2,'g')
        end
        leg1=['sync1, delay=' num2str(lagInSamplesA/EMGfrequency,3) 's, gain=' num2str(gain1,4) ', mismatch(%)=' num2str(100*E1,3)];
        leg2=['sync2, delay=' num2str((lagInSamplesA+lagInSamples)/EMGfrequency,3) 's, gain=' num2str(gain2,4) ', mismatch(%)=' num2str(100*E2,3)];
        legend('refSync',leg1,leg2)
        hold off
        subplot(2,2,3)
        T=round(3*EMGfrequency); %To plot just 3 secs at the beginning and at the end
        if T<length(refSync)
            hold on
            plot(time(1:T),refSync(1:T))
            plot(time(1:T),sync(1:T,1)*gain1,'r')
            if secondFile
                plot(time(1:T),sync(1:T,2)*gain2,'g')
            end
            hold off
            subplot(2,2,4)
            hold on
            plot(time(end-T:end),refSync(end-T:end))
            plot(time(end-T:end),sync(end-T:end,1)*gain1,'r')
            if secondFile
                plot(time(end-T:end),sync(end-T:end,2)*gain2,'g')
            end
            hold off
        end
        s=inputdlg('If sync parameters between signals look fine and mismatch is below 5%, we recommend yes.','Please confirm that you want to proceed like this (y/n).');
        switch s{1}
            case {'y','Y','yes'}
                disp(['Using signals in a possibly unsynchronized way!.'])
                close(h)
            case {'n','N','no'}
                error('loadTrials:EMGCouldNotBeSynched','Could not synchronize EMG data, stopping data loading.')
        end
    end
    
    %Plot to CONFIRM VISUALLY if alignment worked:
    h=figure;
    subplot(2,2,[1:2])
    hold on
    title(['Trial ' num2str(t) ' Synchronization'])
    time=[0:length(refSync)-1]*1/EMGfrequency;
    plot(time,refSync)
    plot(time,sync(:,1)*gain1,'r')
    leg1=['sync1, delay=' num2str(lagInSamplesA/EMGfrequency,3) 's, gain=' num2str(gain1,4) ', mismatch(%)=' num2str(100*E1,3)];
    if secondFile
        plot(time,sync(:,2)*gain2,'g')
        leg2=['sync2, delay=' num2str((lagInSamplesA+lagInSamples)/EMGfrequency,3) 's, gain=' num2str(gain2,4) ', mismatch(%)=' num2str(100*E2,3)];
        legend('refSync',leg1,leg2)
    else
        legend('refSync',leg1)
    end
    hold off
    subplot(2,2,3)
    T=round(3*EMGfrequency); %To plot just 3 secs at the beginning and at the end
    if T<length(refSync)
        hold on
        plot(time(1:T),refSync(1:T))
        plot(time(1:T),sync(1:T,1)*gain1,'r')
        if secondFile
            plot(time(1:T),sync(1:T,2)*gain2,'g')
        end
        %legend('refSync',['sync1, delay=' num2str(lagInSamplesA/analogsInfo.frequency,3) 's'],['sync2, delay=' num2str((lagInSamplesA+lagInSamples)/analogsInfo.frequency,3)  's'])
        hold off
        subplot(2,2,4)
        hold on
        plot(time(end-T:end),refSync(end-T:end))
        plot(time(end-T:end),sync(end-T:end,1)*gain1,'r')
        if secondFile
            plot(time(end-T:end),sync(end-T:end,2)*gain2,'g')
        end
        %legend('refSync',['sync1, delay=' num2str(lagInSamplesA/analogsInfo.frequency,3) 's'],['sync2, delay=' num2str((lagInSamplesA+lagInSamples)/analogsInfo.frequency,3)  's'])
        hold off
    end
    saveFig(h,'./',['Trial ' num2str(t) ' Synchronization'])
    %         uiwait(h)
else
    warning('No sync signals were present, using data as-is.')
end


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
EMGData=labTimeSeries(allData(:,orderedIndexes),0,1/EMGfrequency,EMGList(orderedIndexes)); %Throw away the synch signal
clear allData* relData* auxData*

%% Retrieve H-Reflex Stimulator Pin Data If It Exists
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
    HreflexStimPinData = labTimeSeries(relData,0, ...
        1/analogsInfo.frequency,stimLabels);
    
    % TODO: retrieve GRF data if helpful for verifying stim occurred during
    % stance phase during walking calibration trials
    % verify that the # of frames matches that of the GRF data
    % if ~isempty(GRFData)    % if there is GRF data present, ...
    %     if (GRFData.Length ~= HreflexStimPinData.Length)
    %         error(['Hreflex stimulator pins have different length than' ...
    %             'GRF data. This should never happen. Data is compromised.']);
    %     end
    % end
else
    HreflexStimPinData = [];
end

%% Retrieve Ground Reaction Force (GRF) Data If It Exists
% relData=[];
% forceLabels ={};
% units={};
% fieldList=fields(analogs);
% showWarning = false;
% for j=1:length(fieldList);%parse analog channels by force, moment, cop
%     %if strcmp(fieldList{j}(end-2),'F') || strcmp(fieldList{j}(end-2),'M') %Getting fields that end in F.. or M.. only
%     if strcmp(fieldList{j}(1),'F') || strcmp(fieldList{j}(1),'M') || ~isempty(strfind(fieldList{j},'Force')) || ~isempty(strfind(fieldList{j},'Moment'))
%         if ~strcmpi('x',fieldList{j}(end-1)) && ~strcmpi('y',fieldList{j}(end-1)) && ~strcmpi('z',fieldList{j}(end-1))
%             warning(['loadTrials:GRFs','Found force/moment data that does not correspond to any of the expected directions (x,y or z). Discarding channel ' fieldList{j}])
%         else
%             switch fieldList{j}(end)%parse devices
%                 case '1' %Forces/moments ending in '1' area assumed to be of left treadmill belt
%                     forceLabels{end+1} = ['L',fieldList{j}(end-2:end-1)];
%                     units{end+1}=eval(['analogsInfo.units.',fieldList{j}]);
%                     relData=[relData,analogs.(fieldList{j})];
%                 case '2' %Forces/moments ending in '2' area assumed to be of right treadmill belt
%                     forceLabels{end+1} = ['R',fieldList{j}(end-2:end-1)];
%                     units{end+1}=eval(['analogsInfo.units.',fieldList{j}]);
%                     relData=[relData,analogs.(fieldList{j})];
%                 case '4'%Forces/moments ending in '4' area assumed to be of handrail
%                     forceLabels{end+1} = ['H',fieldList{j}(end-2:end-1)];
%                     units{end+1}=eval(['analogsInfo.units.',fieldList{j}]);
%                     relData=[relData,analogs.(fieldList{j})];
%                 otherwise
%                     showWarning=true;%%HH moved warning outside loop on 6/3/2015 to reduce command window output
%             end
%             analogs=rmfield(analogs,fieldList{j}); %Just to save memory space
%         end
%     end
% end
% if showWarning
%     warning(['loadTrials:GRFs','Found force/moment data in trial ' filename ' that does not correspond to any of the expected channels (L=1, R=2, H=4). Data discarded.'])
% end
%
% forces = relData;
%
% clear analogs* %Save memory space, no longer need analog data, it was already loaded
% clear relData

%% Extract Events
% TODO: add back in to script if helpful to check the times to verify
% stimulation is during single stance if it is a walking calibration trial
% [~,~,lfz] = intersect('LFz',forceLabels);
% [~,~,rfz] = intersect('RFz',forceLabels);
%
% [LHS,RHS,LTO,RTO] = getEventsFromForces(forces(:,lfz),forces(:,rfz),100);

%% Save the Data

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

%% 1. Define H-Reflex Calibration Trial Parameters

% NOTE: should always be the same across trials
per = EMGData.sampPeriod;    % sampling period
threshSamps = threshStimTimeSep / per;  % convert to samples
% M-wave is contained by interval 5ms - 20ms
% H-wave is contained by interval 20ms - 50ms
indStartM = 0.005 / per;        % 5 ms after stim artifact in samples
indEndM = (0.020 - per) / per;
indStartH = 0.020 / per;        % 20 ms
indEndH = 0.050 / per;          % 50 ms

%% 2. Identify Locations of the Stimulation Artifacts
% extract relevant EMG data
EMG_LTAP = EMGData.Data(:,contains(EMGData.labels,'ltap', ...
    'IgnoreCase',true));
EMG_RTAP = EMGData.Data(:,contains(EMGData.labels,'rtap', ...
    'IgnoreCase',true));
EMG_LMG = EMGData.Data(:,contains(EMGData.labels,'lmg','IgnoreCase',true));
EMG_RMG = EMGData.Data(:,contains(EMGData.labels,'rmg','IgnoreCase',true));

% if want to plot, can use the time array
times = EMGData.Time;

% if want to plot the peaks to check, run without output arguments
figure('Units','normalized','OuterPosition',[0 0 1 1]);
tl = tiledlayout('vertical','TileSpacing','tight');

nexttile; hold on;
findpeaks(EMG_RTAP,'NPeaks',numStimR, ...
    'MinPeakHeight',threshStimArtifact,'MinPeakDistance',threshSamps);
yline(threshStimArtifact,'r','Stim Artifact Thresh');
hold off;
title(['Right TAP - Trial ' num2str(trialR)]);

nexttile; hold on;
findpeaks(EMG_LTAP,'NPeaks',numStimL, ...
    'MinPeakHeight',threshStimArtifact,'MinPeakDistance',threshSamps);
yline(threshStimArtifact,'r','Stim Artifact Thresh');
hold off;
title(['Left TAP - Trial ' num2str(trialL)]);

xlabel(tl,'sample number');
ylabel(tl,'Raw Voltage (V)');
title(tl,[id ' - Stimulation Artifact Peak Finding']);

% saveas(gcf,[id '_StimArtifactPeakFinding.png']);
% saveas(gcf,[id '_StimArtifactPeakFinding.fig']);

[pksR,locsR] = findpeaks(EMG_RTAP,'NPeaks',numStimR, ...
    'MinPeakHeight',threshStimArtifact,'MinPeakDistance',threshSamps);
[pksL,locsL] = findpeaks(EMG_LTAP,'NPeaks',numStimL, ...
    'MinPeakHeight',threshStimArtifact,'MinPeakDistance',threshSamps);

%% Plot All Stimuli to Verify the Waveforms
snipStart = -0.005; % 5 ms before artifact peak
snipEnd = 0.045;    % 45 ms after artifact peak
timesSnippet = snipStart:per:snipEnd;
numSamps = length(timesSnippet);

% store the snippets to plot them together
snippetsHreflexR = nan(numStimR,numSamps);
snippetsHreflexL = nan(numStimL,numSamps);
% plot the right leg stimuli
% TODO: add checks for trials without stimuli for one leg or the other
for stR = 1:numStimR    % for each right leg stimulus, ...
    % TODO: do not hardcode 10 ms before and 70 ms after stim artifact peak
    winPlotR = (locsR(stR) + (snipStart/per)):(locsR(stR) + (snipEnd/per));
    timesWinPlotR = times(winPlotR);
    snipsStimAllMuscles = [EMG_RTAP(winPlotR); EMG_RMG(winPlotR)];
    ymin = min(snipsStimAllMuscles,[],'all');
    ymax = max(snipsStimAllMuscles,[],'all');
    
    figure('Units','normalized','OuterPosition',[0 0 1 1]);
    tl = tiledlayout('vertical','TileSpacing','tight');
    
    ax1 = nexttile; hold on;
    xline(times(locsR(stR)),'k','LineWidth',2);
    xline(times(locsR(stR)+indStartM),'b');
    xline(times(locsR(stR)+indEndM),'b');
    xline(times(locsR(stR)+indStartH),'g');
    xline(times(locsR(stR)+indEndH),'g');
    yline(threshStimArtifact,'r','Stim Artifact Thresh');
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
    title('Right MG');
    hold off;
    
    linkaxes([ax1 ax2]);
    xlabel(tl,'time (s)');
    ylabel(tl,'MG Raw Voltage (V)');
    xlim([timesWinPlotR(1) timesWinPlotR(end)]);
    ylim([ymin ymax]);
    title(tl,[id ' - Right Leg - Stim ' num2str(stR) ' - EMG']);
    
%     saveas(gcf,[id '_StimEMGSnippets_Trial' num2str(trialR) ...
%         '_RightLeg_Stim' num2str(stR) '.png']);
%     saveas(gcf,[id '_StimEMGSnippets_Trial' num2str(trialR) ...
%         '_RightLeg_Stim' num2str(stR) '.fig']);
end

% plot the left leg stimuli
for stL = 1:numStimL    % for each left leg stimulus, ...
    % TODO: do not hardcode 10 ms before and 70 ms after stim artifact peak
    winPlotL = (locsL(stL) + (snipStart/per)):(locsL(stL) + (snipEnd/per));
    timesWinPlotL = times(winPlotL);
    snipsStimAllMuscles = [EMG_LTAP(winPlotL); EMG_LMG(winPlotL)];
    ymin = min(snipsStimAllMuscles,[],'all');
    ymax = max(snipsStimAllMuscles,[],'all');
    
    figure('Units','normalized','OuterPosition',[0 0 1 1]);
    tl = tiledlayout('vertical','TileSpacing','tight');
    
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
    title('Left MG');
    hold off;
    
    linkaxes([ax1 ax2]);
    xlabel(tl,'time (s)');
    ylabel(tl,'MG Raw Voltage (V)');
    xlim([timesWinPlotL(1) timesWinPlotL(end)]);
    ylim([ymin ymax]);
    title(tl,[id ' - Left Leg - Stim ' num2str(stL) ' - EMG']);
    
%     saveas(gcf,[id '_StimEMGSnippets_Trial' num2str(trialL) ...
%         '_LeftLeg_Stim' num2str(stL) '.png']);
%     saveas(gcf,[id '_StimEMGSnippets_Trial' num2str(trialL) ...
%         '_LeftLeg_Stim' num2str(stL) '.fig']);
end

%% Plot All Snippets for Each Leg Together in One Figure
ymin = min([snippetsHreflexL; snippetsHreflexR],[],'all');
ymax = max([snippetsHreflexL; snippetsHreflexR],[],'all');

figure('Units','normalized','OuterPosition',[0 0 1 1]);
tl = tiledlayout('vertical','TileSpacing','tight');

ax1 = nexttile; hold on;
xline(0,'k','LineWidth',2);
xline(indStartM*per,'b');
xline(indEndM*per,'b');
xline(indStartH*per,'g');
xline(indEndH*per,'g');
plot(timesSnippet,snippetsHreflexR);
hold off;
title('Right MG');

snippetsHreflexL(stL,:) = EMG_LMG(winPlotL);
ax2 = nexttile; hold on;
xline(0,'k','LineWidth',2);
xline(indStartM*per,'b');
xline(indEndM*per,'b');
xline(indStartH*per,'g');
xline(indEndH*per,'g');
plot(timesSnippet,snippetsHreflexL);
hold off;
title('Left MG');

linkaxes([ax1 ax2]);
xlabel(tl,'time (s)');
ylabel(tl,'MG Raw Voltage (V)');
xlim([timesSnippet(1) timesSnippet(end)]);
ylim([ymin ymax]);
title(tl,[id ' - H-Reflex Calibration Waveforms']);

% saveas(gcf,[id '_HreflexSnippets.png']);
% saveas(gcf,[id '_HreflexSnippets.fig']);

%% 3. Compute M-wave & H-wave Amplitude (assuming waveforms are correct)

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

%% 4. Plot Recruitment Curve for Both Legs

% compute Hmax and I_Hmax for the right and left leg
[hMaxR,indHMaxR] = max(ampsHwaveR);
IhMaxR = ampsStimR(indHMaxR);
[hMaxL,indHMaxL] = max(ampsHwaveL);
IhMaxL = ampsStimL(indHMaxL);

[ampsStimR,indsOrderR] = sort(ampsStimR);
ampsHwaveR = ampsHwaveR(indsOrderR);
ampsMwaveR = ampsMwaveR(indsOrderR);

[ampsStimL,indsOrderL] = sort(ampsStimL);
ampsHwaveL = ampsHwaveL(indsOrderL);
ampsMwaveL = ampsMwaveL(indsOrderL);

figure; hold on;
plot(ampsStimR,ampsHwaveR,'k','LineWidth',2);
plot(ampsStimR,ampsMwaveR,'LineWidth',2,'Color',[0.5 0.5 0.5]);
% plot([IhMaxR IhMaxR],[0 hMaxR],'k-.');  % vertical line from I_Hmax to Hmax
% add label to vertical line (I_Hmax) shifted up from x-axis by 5% of max y
% value and over from the line by 0.1 mA
% TODO: use one decimal place for I_Hmax
% TODO: do not hardcode x offset for label
% text(IhMaxR + 0.1,0 + (0.05*max([ampsMwaveR; ampsHwaveR])), ...
%     sprintf('I_{H_{max}} = %.1f mA',IhMaxR));
plot([min(ampsStimR) IhMaxR],[hMaxR hMaxR],'k-.'); % horizontal line to Hmax
% add label to horizontal line (Hmax)
text(min(ampsStimR) + 0.1,hMaxR + (0.05*max([ampsMwaveR; ampsHwaveR])), ...
    sprintf('H_{max} = %.5f V',hMaxR));
hold off;
xlabel('Stimulation #'); % xlabel('Stimulation Amplitude (mA)');
ylabel('MG EMG Amplitude (V)');
legend('H-wave','M-wave');
% title([id ' - Right Leg - Recruitment Curve']);
% saveas(gcf,[id '_H-ReflexRecruitmentCurve_Trial' num2str(trialR) ...
%     '_RightLeg.png']);
% saveas(gcf,[id '_H-ReflexRecruitmentCurve_Trial' num2str(trialR) ...
%     '_RightLeg.fig']);

figure; hold on;
plot(ampsStimL,ampsHwaveL,'k','LineWidth',2);
plot(ampsStimL,ampsMwaveL,'LineWidth',2,'Color',[0.5 0.5 0.5]);
% plot([IhMaxL IhMaxL],[0 hMaxL],'k-.');  % vertical line from I_Hmax to Hmax
% add label to vertical line (I_Hmax) shifted up from x-axis by 5% of max y
% value and over from the line by 0.1 mA
% TODO: use one decimal place for I_Hmax
% TODO: do not hardcode x offset for label
% text(IhMaxL + 0.1,0 + (0.05*max([ampsMwaveL; ampsHwaveL])), ...
%     sprintf('I_{H_{max}} = %.1f mA',IhMaxL));
plot([min(ampsStimL) IhMaxL],[hMaxL hMaxL],'k-.'); % horizontal line to Hmax
% add label to horizontal line (Hmax)
text(min(ampsStimL) + 0.1,hMaxL + (0.05*max([ampsMwaveL; ampsHwaveL])), ...
    sprintf('H_{max} = %.5f V',hMaxL));
hold off;
xlabel('Stimulation #'); % xlabel('Stimulation Amplitude (mA)');
ylabel('MG EMG Amplitude (V)');
legend('H-wave','M-wave');
% title([id ' - Left Leg - Recruitment Curve']);
% saveas(gcf,[id '_H-ReflexRecruitmentCurve_Trial' num2str(trialL) ...
%     '_LeftLeg.png']);
% saveas(gcf,[id '_H-ReflexRecruitmentCurve_Trial' num2str(trialL) ...
%     '_LeftLeg.fig']);



