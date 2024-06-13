function [rawExpData] = SyncDatalog(rawExpData, syncImgSavePath)
%Synchronize the datlog with the rawExpData using the force signal.
% In each trial's datalog will have a new field datlog.dataLogTimeOffsetBest, 
% which = delay in seconds between (datlog - rawExpData) 
% where positive number means datlog started after rawExpData, which is
% usually the case, unless the trial has been cut in Vicon. 
% This function assume the datlog has already been loaded in
% rawExpData.metaData.datlog{trial} and that object will be updated. 
%
% OUTPUTARGS:
%           -rawExpData: the same rawExpeirmentData object in inputarg with datlog updated
%                   with the new field dataLogTimeOffsetBest
% INPUTARGS: 
%           - rawExpData: rawExperimentData object with datlog loaded.
%           - synImgSavePath: string, the directory to save the datlog sync
%                   result image. 
% Examples: 
% [rawExpData] = SyncDatalog(rawExpData, syncImgSavePath)
% next can do:
% TMReadSyncedTime = rawExpData.metaData.datlog{trial}.dataLogTimeOffsetBest +
% rawExpData.metaData.datlog{trial}.TreadmillCommands.read(:,5)
% 
% See also: SepCondsInExpByAudioCue.m

% $Author: Shuqi Liu $	$Date: 2024/05/22 13:24:55 $	$Revision: 0.1 $
% Copyright: Sensorimotor Learning Laboratory 2024

%% Create a save folder if doesn't exist.
if ~isfolder(syncImgSavePath)
    mkdir(syncImgSavePath)
end

%% find time shifts btw datlog F and rawExpData F
trials = cell2mat(rawExpData.metaData.trialsInCondition);

for trialIdx = trials
    if ~strcmpi(rawExpData.data{trialIdx}.metaData.type,'TM')
        continue; %skip non TM trials, no force data
    end
    
    % Find force from data log and upsample to 2000Hz
    datlog = rawExpData.metaData.datlog{trialIdx};
    try
    totalTime = datlog.forces.data(end,5); % in seconds
    catch ME
        warning('No force data found in datlog for trial %d. Ignore datlog synching for this trial.', trialIdx)
        continue
    end

    currTrial = rawExpData.data{trialIdx};
    sampleFrq = currTrial.GRFData.sampFreq;
    intervalAt2000 = 0:1/sampleFrq:totalTime;
    %1st arg is time, 2nd arg is data,  %{'frame #','U time','Rfz','Lfz','Relative Time'}
    FL_datlog = interp1(datlog.forces.data(:,5),datlog.forces.data(:,4),intervalAt2000)';
    FR_datlog = interp1(datlog.forces.data(:,5),datlog.forces.data(:,3),intervalAt2000)';

    % find force data from rawExpData.
    labelIdx = ismember(currTrial.GRFData.labels,{'LFz','RFz'}); %TODO: add new labels here
    force_rawData = currTrial.GRFData.Data(:,labelIdx);
%     force_rawData = [zeros(24000,2);force_rawData]; %if both fail could
%     try to pad some zeros in the beginnign to see if that helps.

    % attempt to align the signals.
    tL = finddelay(FL_datlog,force_rawData(:,1)); %delay from t2-t1, if >0, means t2 started later or t1 has fewer data
    tR = finddelay(FR_datlog,force_rawData(:,2)); %delay from t2-t1
    %in theory tL and tR should be very similar 
    
    % %use Matlab's built function to align to the earliest signal (this should
    % %be the same to our manual approach when force_rawData starts early),
    % %we want more control to always shift datlog only regardless of which signal is easier,
    % %so will use our own approach. Remove comments for debugging and
    % %checking plot1 below.
    % [aligndataLogL, alignFRawL] = alignsignals(FL_datlog,force_rawData(:,1));
    % [aligndataLogR, alignFRawR] = alignsignals(FR_datlog,force_rawData(:,2));

%     alignedToRawL = all(alignFRawL == force_rawData(:,1)); %this should be true, the raw exp data doesn't need to be padded, unless th trial
%   % has been cut short manually in post-processing in Vicon
%     alignedToRawR = all(alignFRawR == force_rawData(:,2)); %this should be true, the raw exp data doesn't need to be padded
%     if ~alignedToRawL %not aligned properly, raw data is shorter (should never happen)
%         warning('Raw data for L is shorter than data log. This should never happen. \n')
%     end
%     if ~alignedToRawR %not aligned properly, raw data is shorter (should never happen)
%         warning('Raw data for R is shorter than data log. This should never happen. \n')
%     end
    
    %% Calculate a parameter to measure how good is the sync
    if tL >0
        FL_raw_aligned = force_rawData(tL:end,1); %select from delay and forward in raw forces
        [sync,refSync]=truncateToSameLength(FL_datlog,FL_raw_aligned);%truncate end
        FL_datlog = [zeros(tL,1);FL_datlog]; %padd datlog in the front
    else %Force actually have fewer samples
        [sync,refSync]=truncateToSameLength(FL_datlog(-tL:end),force_rawData(:,1));%truncate end 
        FL_datlog = FL_datlog(-tL:end); %trim datlog in the front, always align to force.
        warning('Trial %d The raw data starts before or had more samples than datlog. This should not happen unless the trial has been cut in Vicon. Recommend fixing it.',trialIdx)
    end
    gain1=refSync'/sync(:,1)';
    sync=sync*gain1;
    signalCorrL = corr(sync, refSync);
    
    if tR >0
        FR_raw_aligned = force_rawData(tR:end,2); %select from delay and forward in raw forces
        [sync,refSync]=truncateToSameLength(FR_datlog,FR_raw_aligned);%truncate end
        FR_datlog = [zeros(tR,1);FR_datlog]; %padd datlog in the front
    else %Force actually have fewer samples
        [sync,refSync]=truncateToSameLength(FR_datlog(-tR:end),force_rawData(:,2));%truncate end  
        FR_datlog = FR_datlog(-tR:end); %trim datlog in the front, always align to force.
        warning('Trial %d The raw data starts before or had more samples than datlog. This should not happen unless the trial has been cut in Vicon. Recommend fixing it.',trialIdx)
    end
    gain1=refSync'/sync(:,1)';
    sync=sync*gain1;
    signalCorrR = corr(sync, refSync);
    
    if signalCorrL >= signalCorrR
        datlogDelay = tL; %this is the best delay to match signal, choose the one with better correlation
    else
        datlogDelay = tR;
    end
    
%     %% Option 2 (this works too). Calculate sync error.(Logic copied from loadTrials when synchronizing EMG with forces, I do not fully understand what I'm doing here)
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
%     E1=sum((reducedRefSync-reducedSync1).^2)/sum(refSync.^2); %Computing error energy as % of original signal energy, only considering the time interval were signals were simultaneously recorded.
            
    %% Plot to visualize alignment.    
    % % 1. Plot data from the align function call to compare with matlab aligned data, not really needed, just to make sure i'm not plotting something wrong.
    % figure(); hold on;
    % plot(aligndataLogL,'LineWidth',2,'DisplayName','AlignedData');
    % plot(alignFRawL(:,1),'DisplayName','RawExpL');
   
    % 2. Plot manually padded version (always shift datlog to match raw)
    f = figure('units','normalized','outerposition',[0 0 1 1]);
    subplot(2,1,1);
    hold on;
    plot([FL_datlog],'LineWidth',1.5,'DisplayName','AlignedDatlogL');
    plot(force_rawData(:,1),'DisplayName','RawExpL');
    title(sprintf('FL Corr: %.2f',signalCorrL))
    legend();
    subplot(2,1,2); hold on;
    plot([FR_datlog],'LineWidth',1.5,'DisplayName','AlignedDatlogR');
    plot(force_rawData(:,2),'DisplayName','RawExpR');
    title(sprintf('FR Corr: %.2f',signalCorrR))
    sgtitle(sprintf('Trial%02d Sync',trialIdx))

    % %3. Plot the raw/unaligned data, for debugging purpose.
    %     figure(); hold on;
    % plot(force_rawData(:,1),'DisplayName','RawExpF'); legend()
    % subplot(3,1,3); hold on;
    % plot(FL_datlog_raw,'DisplayName','DataLogF');
    % legend()

    %If sync is bad, give a pop up
    if signalCorrL <= 0.90 && signalCorrR <= 0.90 %this is a rather arbitrary number     
        answer = questdlg('Which one syncs better (choose the one with higher correlation and looks better; if both are bad, choose none to abort)?', ...
            '', ...
            'L','R','None (abort)','L'); %give 3 options and default to L
        % Handle response
        switch answer
            case 'L' %none of them is great, still choose to match with the best one available.
                datlogDelay = tL;
                warning('Trial %d Data log sync correlation is below 0.90. Choose %s as the reference (r=%.4f)',trialIdx,answer,signalCorrL)
            case 'R'
                datlogDelay = tR;
                warning('Trial %d Data log sync correlation is below 0.90. Choose %s as the reference (r=%.4f)',trialIdx,answer,signalCorrR)
            case 'None (abort)'
                error('SyncDatlog:Datlog CouldNotBeSynched. Could not synchronize Datlog data, stopping data loading.')
        end
    end
        
    saveas(f,[syncImgSavePath sprintf('Trial%02d Sync',trialIdx)])
    saveas(f,[syncImgSavePath sprintf('Trial%02d Sync',trialIdx) '.png'])
          
    %% Save the time offset into the datlog and in rawExpData.metadata
    datlog.dataLogTimeOffsetL = tL/sampleFrq; %in seconds
    datlog.dataLogTimeOffsetR = tR/sampleFrq; %in seconds
    datlog.dataLogTimeOffsetBest = datlogDelay/sampleFrq; %in seconds.
   
    rawExpData.metaData.datlog{trialIdx} = datlog; %update to have the log with time shift info.
    rawExpData.data{trialIdx}.metaData.datlog = datlog; %most likely redundant but need it for perceptual task syncronization later
end
end
