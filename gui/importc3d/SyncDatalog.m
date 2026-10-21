function rawExpData = SyncDatalog(rawExpData, syncImgSavePath)
%SYNCDATALOG Synchronize the datlog with rawExpData using the force signal.
%
%   For each treadmill ('TM') trial, upsamples the datlog's left and right
% vertical forces to the C3D force sampling rate and finds the delay that
% best aligns them with the raw LFz and RFz channels (finddelay). The
% delay of the leg with the better correlation is stored in the trial's
% datlog as dataLogTimeOffsetBest (s; positive means the datlog started
% after rawExpData, the usual case unless the trial was cut in Vicon),
% and the per-leg delays as dataLogTimeOffsetL and dataLogTimeOffsetR.
% Non-TM trials and trials whose datlog has no force data are skipped. If
% neither leg correlates above 0.90, a dialog (questdlg) asks which leg
% to trust, or to abort with an error.
%
%   Side effects: creates syncImgSavePath if missing and saves one figure
% per synchronized trial there ('Trial## Sync' as .fig and .png), silently
% overwriting same-named files from an earlier run (see DATA_OUTPUTS.md);
% closes all figures, clears the command window, and clears all variables
% except its own (a memory workaround, see the FIXME in the code).
%
% Inputs:
%   rawExpData      - rawExperimentData object with the datlog loaded in
%                     rawExpData.metaData.datlog{trial}
%   syncImgSavePath - char, directory to save the datlog sync result
%                     figures
%
% Outputs:
%   rawExpData - the input object with each synchronized trial's datlog
%                (in metaData.datlog{trial} and in
%                data{trial}.metaData.datlog) updated with
%                dataLogTimeOffsetL, dataLogTimeOffsetR, and
%                dataLogTimeOffsetBest
%
% Examples:
%   rawExpData = SyncDatalog(rawExpData, syncImgSavePath);
%   % synced treadmill read time:
%   TMReadSyncedTime = ...
%       rawExpData.metaData.datlog{trial}.dataLogTimeOffsetBest + ...
%       rawExpData.metaData.datlog{trial}.TreadmillCommands.read(:,5);
%
% Toolbox Dependencies:
%   Signal Processing Toolbox (finddelay)
%   Statistics and Machine Learning Toolbox (corr)
%
% See also SEPCONDSINEXPBYAUDIOCUE, LOADSUBJECT.

% $Author: Shuqi Liu $	$Date: 2024/05/22 13:24:55 $	$Revision: 0.1 $
% Copyright: Sensorimotor Learning Laboratory 2024

%% Create a save folder if doesn't exist.
if ~isfolder(syncImgSavePath)
    mkdir(syncImgSavePath)
end

%% find time shifts btw datlog F and rawExpData F
trials = cell2mat(rawExpData.metaData.trialsInCondition);

for trialIdx = trials
    %FIXME: Close all figures and remove intermediate variables to free up
    %some memory in matlab.
    %There seems to be a memory issue since summer 2025. During c3d2mat,
    %the PC will run out of memory which is shown as OutOfMemory,
    %OutOfHeapSpace, or png file failed to write rrors.
    %A better solution is needed to identify why we are running out of
    %memory or do we have a memory leak
    %Since we don't know the cause now, will try close the figures and
    %remove variables to make the code run for now.
    close all; clc;
    clearvars -except rawExpData syncImgSavePath trialIdx trials

    if ~strcmpi(rawExpData.data{trialIdx}.metaData.type, 'TM')
        continue; %skip non TM trials, no force data
    end

    % Find force from data log and upsample to 2000Hz
    datlog = rawExpData.metaData.datlog{trialIdx};
    try
        totalTime = datlog.forces.data(end,5); % in seconds
    catch ME
        warning(['No force data found in datlog for trial %d. Ignore ' ...
            'datlog synching for this trial.'], trialIdx)
        continue
    end

    currTrial = rawExpData.data{trialIdx};
    sampleFrq = currTrial.GRFData.sampFreq;
    intervalAt2000 = 0:1/sampleFrq:totalTime;

    % NOTE: the datlog occasionally logs two force packets with the same
    % relative time stamp (or a NaN time), which makes interp1 error with
    % "Sample points must be unique". Keep the first sample at each
    % finite time stamp so the datlog can still be synchronized.
    forceData = datlog.forces.data;
    forceData = forceData(isfinite(forceData(:,5)), :);
    [~, idxUnique] = unique(forceData(:,5));    % sorted, first occurrence
    numDropped = size(datlog.forces.data, 1) - numel(idxUnique);
    if numDropped > 0
        warning(['Trial %d: dropped %d datlog force samples with ' ...
            'duplicate or non-finite time stamps before syncing.'], ...
            trialIdx, numDropped);
    end
    forceData = forceData(idxUnique, :);

    %1st arg is time, 2nd arg is data,
    %{'frame #','U time','Rfz','Lfz','Relative Time'}
    FL_datlog = interp1(forceData(:,5), forceData(:,4), ...
        intervalAt2000)';
    FR_datlog = interp1(forceData(:,5), forceData(:,3), ...
        intervalAt2000)';

    % find force data from rawExpData.
    %TODO: add new labels here
    labelIdx = ismember(currTrial.GRFData.labels, {'LFz', 'RFz'});
    force_rawData = currTrial.GRFData.Data(:,labelIdx);
%     force_rawData = [zeros(24000,2);force_rawData]; %if both fail could
%     try to pad some zeros in the beginnign to see if that helps.

    % attempt to align the signals.
    % delay from t2-t1, if >0, means t2 started later or t1 has fewer data
    tL = finddelay(FL_datlog, force_rawData(:,1));
    tR = finddelay(FR_datlog, force_rawData(:,2)); %delay from t2-t1
    %in theory tL and tR should be very similar

    % %use Matlab's built function to align to the earliest signal (this
    % %should be the same to our manual approach when force_rawData starts
    % %early), we want more control to always shift datlog only regardless
    % %of which signal is easier, so will use our own approach. Remove
    % %comments for debugging and checking plot1 below.
    % [aligndataLogL, alignFRawL] = alignsignals( ...
    %     FL_datlog,force_rawData(:,1));
    % [aligndataLogR, alignFRawR] = alignsignals( ...
    %     FR_datlog,force_rawData(:,2));

%     %this should be true, the raw exp data doesn't need to be padded,
%     %unless th trial has been cut short manually in post-processing in
%     %Vicon
%     alignedToRawL = all(alignFRawL == force_rawData(:,1));
%     %this should be true, the raw exp data doesn't need to be padded
%     alignedToRawR = all(alignFRawR == force_rawData(:,2));
%     %not aligned properly, raw data is shorter (should never happen)
%     if ~alignedToRawL
%         warning(['Raw data for L is shorter than data log. This ' ...
%             'should never happen. \n'])
%     end
%     %not aligned properly, raw data is shorter (should never happen)
%     if ~alignedToRawR
%         warning(['Raw data for R is shorter than data log. This ' ...
%             'should never happen. \n'])
%     end

    %% Calculate a parameter to measure how good is the sync
    if tL > 0
        %select from delay and forward in raw forces
        FL_raw_aligned = force_rawData(tL:end,1);
        %truncate end
        [sync, refSync] = truncateToSameLength(FL_datlog, FL_raw_aligned);
        FL_datlog = [zeros(tL,1); FL_datlog]; %padd datlog in the front
    else %Force actually have fewer samples
        %truncate end
        [sync, refSync] = truncateToSameLength( ...
            FL_datlog(-tL:end), force_rawData(:,1));
        %trim datlog in the front, always align to force.
        FL_datlog = FL_datlog(-tL:end);
        warning(['Trial %d The raw data starts before or had more ' ...
            'samples than datlog. This should not happen unless the ' ...
            'trial has been cut in Vicon. Recommend fixing it.'], trialIdx)
    end
    gain1 = refSync' / sync(:,1)';
    sync = sync * gain1;
    signalCorrL = corr(sync, refSync);

    if tR > 0
        %select from delay and forward in raw forces
        FR_raw_aligned = force_rawData(tR:end,2);
        %truncate end
        [sync, refSync] = truncateToSameLength(FR_datlog, FR_raw_aligned);
        FR_datlog = [zeros(tR,1); FR_datlog]; %padd datlog in the front
    else %Force actually have fewer samples
        %truncate end
        [sync, refSync] = truncateToSameLength( ...
            FR_datlog(-tR:end), force_rawData(:,2));
        %trim datlog in the front, always align to force.
        FR_datlog = FR_datlog(-tR:end);
        warning(['Trial %d The raw data starts before or had more ' ...
            'samples than datlog. This should not happen unless the ' ...
            'trial has been cut in Vicon. Recommend fixing it.'], trialIdx)
    end
    gain1 = refSync' / sync(:,1)';
    sync = sync * gain1;
    signalCorrR = corr(sync, refSync);

    if signalCorrL >= signalCorrR
        %this is the best delay to match signal, choose the one with
        %better correlation
        datlogDelay = tL;
    else
        datlogDelay = tR;
    end

%     %% Option 2 (this works too). Calculate sync error.
%     %(Logic copied from loadTrials when synchronizing EMG with forces, I
%     %do not fully understand what I'm doing here)
%     refSync = force_rawData(:,1);
%     refSync = refSync(tL:end); %choose the aligned portion
%     sync = FL_datlog;%[zeros(tL,1);FL_datlog];
%
%     [refSync] = clipSignals(refSync(:),.1);
%     refSync=idealHPF(refSync,0); %Removing DC only
%     [sync,refSync]=truncateToSameLength(sync,refSync);
%
%     [sync] = clipSignals(sync,.1);
%     sync=idealHPF(sync,0);
%     gain1=refSync'/sync(:,1)';
%     reducedRefSync=refSync;
%     reducedSync1=sync*gain1;
%     %Computing error energy as % of original signal energy, only
%     %considering the time interval were signals were simultaneously
%     %recorded.
%     E1=sum((reducedRefSync-reducedSync1).^2)/sum(refSync.^2);

    %% Plot to visualize alignment.
    % % 1. Plot data from the align function call to compare with matlab
    % % aligned data, not really needed, just to make sure i'm not plotting
    % % something wrong.
    % figure(); hold on;
    % plot(aligndataLogL,'LineWidth',2,'DisplayName','AlignedData');
    % plot(alignFRawL(:,1),'DisplayName','RawExpL');

    % 2. Plot manually padded version (always shift datlog to match raw)
    f = figure('units', 'normalized', 'outerposition', [0 0 1 1]);
    subplot(2,1,1);
    hold on;
    plot([FL_datlog], 'LineWidth', 1.5, 'DisplayName', 'AlignedDatlogL');
    plot(force_rawData(:,1), 'DisplayName', 'RawExpL');
    title(sprintf('FL Corr: %.2f', signalCorrL))
    legend();
    subplot(2,1,2); hold on;
    plot([FR_datlog], 'LineWidth', 1.5, 'DisplayName', 'AlignedDatlogR');
    plot(force_rawData(:,2), 'DisplayName', 'RawExpR');
    title(sprintf('FR Corr: %.2f', signalCorrR))
    sgtitle(sprintf('Trial%02d Sync', trialIdx))

    % %3. Plot the raw/unaligned data, for debugging purpose.
    %     figure(); hold on;
    % plot(force_rawData(:,1),'DisplayName','RawExpF'); legend()
    % subplot(3,1,3); hold on;
    % plot(FL_datlog_raw,'DisplayName','DataLogF');
    % legend()

    %If sync is bad, give a pop up
    minSyncCorr = 0.90; % this is a rather arbitrary number
    if signalCorrL <= minSyncCorr && signalCorrR <= minSyncCorr
        %give 3 options and default to L
        answer = questdlg(['Which one syncs better (choose the one ' ...
            'with higher correlation and looks better; if both are ' ...
            'bad, choose none to abort)?'], ...
            '', ...
            'L', 'R', 'None (abort)', 'L');
        % Handle response
        switch answer
            case 'L'
                %none of them is great, still choose to match with the best
                %one available.
                datlogDelay = tL;
                warning(['Trial %d Data log sync correlation is below ' ...
                    '0.90. Choose %s as the reference (r=%.4f)'], ...
                    trialIdx, answer, signalCorrL)
            case 'R'
                datlogDelay = tR;
                warning(['Trial %d Data log sync correlation is below ' ...
                    '0.90. Choose %s as the reference (r=%.4f)'], ...
                    trialIdx, answer, signalCorrR)
            case 'None (abort)'
                error(['SyncDatlog:Datlog CouldNotBeSynched. Could not ' ...
                    'synchronize Datlog data, stopping data loading.'])
        end
    end

    saveas(f, fullfile(syncImgSavePath, ...
        sprintf('Trial%02d Sync', trialIdx)))
    saveas(f, fullfile(syncImgSavePath, ...
        [sprintf('Trial%02d Sync', trialIdx) '.png']))

    %% Save the time offset into the datlog and in rawExpData.metadata
    datlog.dataLogTimeOffsetL = tL / sampleFrq; %in seconds
    datlog.dataLogTimeOffsetR = tR / sampleFrq; %in seconds
    datlog.dataLogTimeOffsetBest = datlogDelay / sampleFrq; %in seconds.

    %update to have the log with time shift info.
    rawExpData.metaData.datlog{trialIdx} = datlog;
    %most likely redundant but need it for perceptual task syncronization
    %later
    rawExpData.data{trialIdx}.metaData.datlog = datlog;
end

end
