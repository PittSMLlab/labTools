function [allData, sync, lagInSamplesA, lagInSamples, ...
    timeScaleFactor] = syncEMGData(relData, relData2, refSync, ...
    EMGList, EMGfrequency, secondFile, trialNum, saveFolder)
%SYNCEMGDATA Synchronize two-PC EMG recordings to a reference signal.
%
%   Aligns PC1 and PC2 EMG data to the force-plate PC reference sync
% pin using cross-correlation-based time alignment (matchSignals).
% Clips and median-filters sync signals before alignment, computes
% least-squares gains and mismatch energies as quality metrics, and
% saves a diagnostic figure. Warns and prompts the user when mismatch
% exceeds 5%.
%
%   When no sync channels are present, allData is returned unchanged
% and all lag/scale outputs default to their neutral values (0 or NaN).
%
% Inputs:
%   relData      - (N×K1) PC1 EMG data matrix
%   relData2     - (N×K2) PC2 EMG data matrix; pass [] when absent
%   refSync      - (N×1) reference sync signal from the force-plate PC
%   EMGList      - (1×M) cell of channel names for the combined data
%   EMGfrequency - sampling frequency in Hz
%   secondFile   - logical; true when a second PC file was loaded
%   trialNum     - trial number for warnings and figure title
%   saveFolder   - folder path for the sync diagnostic figure
%
% Outputs:
%   allData         - synchronized, truncated combined EMG matrix
%   sync            - sync channel columns after alignment ([] if none)
%   lagInSamplesA   - PC1 delay relative to GRF reference (samples)
%   lagInSamples    - PC2 delay relative to PC1 (samples;
%                     NaN if single PC)
%   timeScaleFactor - PC2 clock scale factor (NaN if single PC)
%
% Toolbox Dependencies:
%   Signal Processing Toolbox (medfilt1)
%
% See also LOADTRIALS, MATCHSIGNALS, RESAMPLESHIFTANDSCALE,
%   TRUNCATETOSAMELENGTH, CLIPSIGNALS.

arguments
    relData      (:,:) double
    relData2     (:,:) double
    refSync      (:,1) double
    EMGList      (1,:) cell
    EMGfrequency (1,1) double {mustBePositive}
    secondFile   (1,1) logical
    trialNum     (1,1) double
    saveFolder   (1,:) char
end

% -----------------------------------------------------------------------
%  Named constants — sync tuning parameters
% -----------------------------------------------------------------------

% Kernel length (samples) for the median filter applied to raw sync
% signals before differentiation
medFiltKernel     = 20;

% Kernel length (samples) for the median filter applied to the
% differentiated sync signal used in matchSignals
medFiltDiffKernel = 10;

% Percentile (%) used to symmetrically clip the top and bottom of
% sync signals, removing isolated large-amplitude outliers
clipPercentile    = 0.1;

% Fractional signal-energy threshold above which the sync mismatch
% warning and user confirmation prompt are triggered (5%). When
% mismatch exceeds this threshold the pipeline halts and prompts
% the user to confirm whether to proceed with the available alignment.
syncMismatchThreshold = 0.05;

% Amplitude ratio below which a processed sync derivative is treated
% as flat/dead. Good pins are typically 100-1000x louder than dead ones.
flatSyncThreshold = 1e-4;

% Duration (seconds) of the start and end segments shown in the
% sync diagnostic figure subplots
syncPlotDuration  = 3;

% -----------------------------------------------------------------------

% Initialize outputs to neutral defaults; overwritten when sync signals
% are present and alignment succeeds
lagInSamplesA   = 0;
lagInSamples    = NaN;
timeScaleFactor = NaN;
sync            = [];

%% Assemble Combined Data Matrix
% Keep only matrices of the same size.
% When pc2Missing, only PC1 data is in allData during sync;
% PC2 NaN columns are appended after sync processing in loadTrials.
if secondFile
    [auxData, auxData2] = truncateToSameLength(relData, relData2);
    allData = [auxData, auxData2];
    clear auxData*;
else
    allData = relData;
end

%% Pre-Process Reference Sync Signal
% Clip outliers, then median-filter the signal and its derivative
refSync = clipSignals(refSync(:), clipPercentile);
refAux  = medfilt1(refSync, medFiltKernel);
% refAux(refAux<(median(refAux)-5*iqr(refAux)) | ...
%     refAux>(median(refAux)+5*iqr(refAux)))=median(refAux);
refAux = medfilt1(diff(refAux), medFiltDiffKernel);

%% Identify and Process Sync Channels
syncIdx = strncmpi(EMGList, 'Sync', 4); % compare first 4 chars
sync    = allData(:, syncIdx);

if ~isempty(sync)           % if sync signals present, proceed
    % Clip outliers, then median-filter signal and derivative
    sync = clipSignals(sync, clipPercentile);
    aux  = medfilt1(sync, medFiltKernel, [], 1);
    % aux(aux>(median(aux)+5*iqr(aux)) | ...
    %     aux<(median(aux)-5*iqr(aux)))=median(aux(:));
    aux = medfilt1(diff(aux), medFiltDiffKernel, [], 1);
    if secondFile
        if size(aux, 2) < 2
            warning('syncEMGData:missingPC2SyncChannel', ...
                ['[Trial %d] PC2 has no Sync channel in ' ...
                'allData; using default PC1-to-PC2 ' ...
                'alignment.'], trialNum);
            timeScaleFactor = 1;
            lagInSamples    = 0;
            newRelData2     = relData2;
        elseif isFlatSync(aux(:, 1), refAux, flatSyncThreshold) ...
                || isFlatSync(aux(:, 2), refAux, flatSyncThreshold)
            warning('syncEMGData:flatSyncPin', ...
                ['[Trial %d] Sync pin appears dead or ' ...
                'disconnected; using default PC1-to-PC2 ' ...
                'alignment (timeScaleFactor=1, lagInSamples=0).' ...
                ' Check hardware sync connection.'], trialNum);
            timeScaleFactor = 1;
            lagInSamples    = 0;
            newRelData2     = relData2;
        else
            try
                [~, timeScaleFactor, lagInSamples, ~] = ...
                    matchSignals(aux(:, 1), aux(:, 2));
                % [~,timeScaleFactor,lagInSamples,~] = ...
                %     matchSignals(refAux,aux(:,2));
                % Align relData2 to relData1; overall delay of
                % EMG system re. force plate data still to be
                % determined
                newRelData2 = resampleShiftAndScale( ...
                    relData2, timeScaleFactor, lagInSamples, 1);
            catch ME
                warning('syncEMGData:syncMatchFailed', ...
                    ['[Trial %d] matchSignals failed for ' ...
                    'PC1-to-PC2 sync (%s). Using default ' ...
                    'alignment.'], trialNum, ME.message);
                timeScaleFactor = 1;
                lagInSamples    = 0;
                newRelData2     = relData2;
            end
        end
    end
    if max(abs(refAux)) < eps || ...
            isFlatSync(aux(:, 1), refAux, flatSyncThreshold)
        warning('syncEMGData:flatSyncPin', ...
            ['[Trial %d] refAux or PC1 sync is flat; ' ...
            'using lagInSamplesA=0.'], trialNum);
        lagInSamplesA = 0;
        newRelData    = relData;
        if secondFile
            newRelData2 = resampleShiftAndScale( ...
                newRelData2, 1, lagInSamplesA, 1);
        end
    else
        try
            [~, ~, lagInSamplesA, ~] = ...
                matchSignals(refAux, aux(:, 1));
            newRelData = resampleShiftAndScale( ...
                relData, 1, lagInSamplesA, 1);
            if secondFile
                newRelData2 = resampleShiftAndScale( ...
                    newRelData2, 1, lagInSamplesA, 1);
                % [~,timeScaleFactor,lagInSamples,~] = ...
                %     matchSignals(refAux,aux(:,2)); % DMMO/ARL
                % newRelData2 = resampleShiftAndScale( ...
                %     newRelData2,1,lagInSamples,1); % DMMO/ARL
            end
        catch ME
            warning('syncEMGData:syncMatchFailed', ...
                ['[Trial %d] matchSignals failed for ' ...
                'refAux-to-PC1 sync (%s). Using ' ...
                'lagInSamplesA=0.'], trialNum, ME.message);
            lagInSamplesA = 0;
            newRelData    = relData;
            if secondFile
                newRelData2 = resampleShiftAndScale( ...
                    newRelData2, 1, lagInSamplesA, 1);
            end
        end
    end

    % Keep only matrices of the same size
    if secondFile
        [auxData, auxData2] = ...
            truncateToSameLength(newRelData, newRelData2);
        clear newRelData*;
        allData = [auxData, auxData2];
        clear auxData*;
    else
        allData = newRelData;
    end

    % Find gains via least-squares on high-pass filtered sync
    % signals (why use HPF for gains and not for sync?)
    refSync = clipSignals(refSync(:), clipPercentile);
    refSync = refSync - mean(refSync, 'omitnan');  % remove DC
    [allData, refSync] = truncateToSameLength(allData, refSync);
    sync = allData(:, syncIdx);
    sync = clipSignals(sync, clipPercentile);
    sync = sync - mean(sync, 'omitnan');
    gain1    = refSync' / sync(:, 1)';
    indStart = round(max([lagInSamplesA+1, 1]));
    reducedRefSync = refSync(indStart:end);
    indStart       = round(max([lagInSamplesA+1, 1]));
    reducedSync1   = sync(indStart:end, 1) * gain1;
    % Error energy as % of original signal energy; computed
    % only over the interval of simultaneous recording
    E1 = sum((reducedRefSync - reducedSync1).^2) / ...
        sum(refSync.^2);
    if secondFile
        gain2    = refSync' / sync(:, 2)';
        indStart = round(max([lagInSamplesA+1+lagInSamples, 1]));
        reducedRefSync2 = refSync(indStart:end);
        % indStart = round(max( ...
        %     [lagInSamplesA+1+lagInSamples,1]));
        reducedSync2 = sync(indStart:end, 2) * gain2;
        E2 = sum((reducedRefSync2 - reducedSync2).^2) / ...
            sum(refSync.^2);
        % Comparing the two bases' synchrony mechanism
        % (not to ref signal):
        % reducedSync1a=sync(max([lagInSamplesA+1+ ...
        %     lagInSamples,1,lagInSamplesA+1]):end,1)*gain1;
        % reducedSync2a=sync(max([lagInSamplesA+1+ ...
        %     lagInSamples,1,lagInSamplesA+1]):end,2)*gain2;
        % E3=sum((reducedSync1a-reducedSync2a).^2)/ ...
        %     sum(refSync.^2);
    else
        E2              = 0;
        gain2           = NaN;
        timeScaleFactor = NaN;
        lagInSamples    = NaN;
    end

    % Analytic measure of alignment quality
    disp(['Sync complete: mismatch signal energy (as %) was ' ...
        num2str(100*E1, 3) ' and ' num2str(100*E2, 3) '.']);
    disp(['Sync parameters to ref. signal were: gains = ' ...
        num2str(gain1, 4) ', ' num2str(gain2, 4) '; delays = ' ...
        num2str(lagInSamplesA/EMGfrequency, 3) 's, ' ...
        num2str((lagInSamplesA+lagInSamples)/EMGfrequency, 3) ...
        's']);
    disp(['Typical sync parameters are: ' ...
        'gains = -933.3 +- 0.2 (both); ' ...
        'delays = -0.025s +- 0.001, 0.014 +- 0.002']);
    disp(['Sync parameters between PCs were: gain = ' ...
        num2str(gain1/gain2, 4) '; delay = ' ...
        num2str(lagInSamples/EMGfrequency, 3) ...
        's; sampling mismatch (ppm) = ' ...
        num2str(1e6*(1-timeScaleFactor), 3)]);
    disp(['Typical sync parameters are: gain = 1; ' ...
        'delay = 0.040s; sampling = 35 ppm']);

    % Plot to visually confirm alignment, then save the figure.
    h = plotSyncFigure(trialNum, refSync, sync, gain1, gain2, ...
        lagInSamplesA, lagInSamples, E1, E2, EMGfrequency, ...
        secondFile, syncPlotDuration);
    saveFig(h, ...
        [fullfile(saveFolder, 'EMGSyncFile') filesep], ...
        ['Trial ' num2str(trialNum) ' Synchronization']);

    % Warn and prompt the user if mismatch energy exceeds the
    % threshold. The pipeline halts here to allow inspection
    % of the sync figure before deciding to proceed or abort.
    if isnan(E1) || isnan(E2) || ...
            E1 > syncMismatchThreshold || ...
            E2 > syncMismatchThreshold
        warning('syncEMGData:syncMismatchHigh', ...
            ['[Trial %d] EMG sync mismatch energy is high ' ...
            '(PC1: %.2f%%, PC2: %.2f%%). At least one PC ' ...
            'exceeds the threshold of %.0f%%. Synchronization ' ...
            'quality may be poor. Inspect the sync figure for ' ...
            'trial %d before deciding whether to proceed.'], ...
            trialNum, 100*E1, 100*E2, ...
            100*syncMismatchThreshold, trialNum);
        s = inputdlg( ...
            ['If sync parameters between signals look fine and '...
            'mismatch is below 5%, we recommend yes.'], ...
            'Please confirm that you want to proceed (y/n).');
        switch s{1}
            case {'y', 'Y', 'yes'}
                disp(['Using signals in a possibly ' ...
                    'unsynchronized way!.']);
            case {'n', 'N', 'no'}
                error( ...
                    'syncEMGData:EMGCouldNotBeSynched', ...
                    ['[Trial %d] Could not synchronize EMG ' ...
                    'data. Processing stopped at user request ' ...
                    'after sync mismatch of PC1: %.2f%%, PC2: ' ...
                    '%.2f%%.'], trialNum, 100*E1, 100*E2);
        end
    end
else
    warning('syncEMGData:noSyncSignals', ...
        ['[Trial %d] No sync signals were present. ' ...
        'Using data as-is without time alignment.'], trialNum);
end

end

% ============================================================
% ==================== Local Functions =======================
% ============================================================

function h = plotSyncFigure(trialNum, refSync, sync, gain1, gain2, ...
    lagInSamplesA, lagInSamples, E1, E2, EMGfrequency, ...
    secondFile, syncPlotDuration)
%PLOTSYNCFIGURE Creates a 4-panel EMG synchronization diagnostic figure.
%
%   Produces a figure with three panels arranged in a 2×2 tiled layout
% for visually assessing EMG signal alignment quality: a full-length
% overlay of the reference and synchronised signals spanning the top
% row, and close-ups of the first and last syncPlotDuration seconds in
% the bottom-left and bottom-right tiles, respectively. Called for both
% the mismatch-warning prompt and the post-sync confirmation save to
% avoid code duplication.
%
%   Inputs:
%     trialNum         - Trial number (used in the figure title)
%     refSync          - Reference sync signal vector
%     sync             - Matrix of sync signals (columns = PCs)
%     gain1            - Least-squares gain for PC1 sync signal
%     gain2            - Least-squares gain for PC2 sync signal
%     lagInSamplesA    - Sample lag of PC1 relative to reference
%     lagInSamples     - Sample lag of PC2 relative to PC1
%     E1               - Fractional mismatch energy for PC1
%     E2               - Fractional mismatch energy for PC2
%     EMGfrequency     - Sampling frequency of the EMG system (Hz)
%     secondFile       - Logical; true when a second PC file was loaded
%     syncPlotDuration - Duration (s) shown in start/end close-up tiles
%
%   Outputs:
%     h - Handle to the created figure
%
%   See also: SYNCEMGDATA

% ---- Plot appearance constants ----------------------------------------
% RGB triplets from MATLAB's default color order; orange-red and purple
% are more distinguishable than red and green for color vision deficiency
colorRef  = [0.0000 0.4470 0.7410];    % MATLAB default blue  (refSync)
colorPC1  = [0.8500 0.3250 0.0980];    % MATLAB default orange-red (PC1)
colorPC2  = [0.4940 0.1840 0.5560];    % MATLAB default purple     (PC2)
lineWidth = 1.25;
% -----------------------------------------------------------------------

% Build legend label strings from sync parameters
leg1 = ['sync1, delay=' num2str(lagInSamplesA/EMGfrequency, 3) ...
    's, gain=' num2str(gain1, 4) ', mismatch(%)=' num2str(100*E1, 3)];
leg2 = ['sync2, delay=' ...
    num2str((lagInSamplesA+lagInSamples)/EMGfrequency, 3) 's, gain=' ...
    num2str(gain2, 4) ', mismatch(%)=' num2str(100*E2, 3)];

time = (0:length(refSync)-1) * 1 / EMGfrequency;
% Build the sync quality summary line shown below the main title.
% The PC2 entry is omitted in single-PC sessions. subtitle() is not
% used here for R2021a compatibility; a two-element cell array passed
% to title(tl,...) produces the same two-line result on all supported
% MATLAB versions.
if secondFile
    syncQualityStr = ['PC1 mismatch: ' num2str(100*E1, 3) ...
        '% | PC2 mismatch: ' num2str(100*E2, 3) '%'];
else
    syncQualityStr = ['PC1 mismatch: ' num2str(100*E1, 3) '%'];
end

h  = figure();
tl = tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
title(tl, {['Trial ' num2str(trialNum) ' Synchronization'], ...
    syncQualityStr});

% -- Full-length overlay spanning the entire top row
nexttile(1, [1 2]);
hold on;
plot(time, refSync, 'Color', colorRef, 'LineWidth', lineWidth);
plot(time, sync(:, 1) * gain1, 'Color', colorPC1, 'LineWidth', lineWidth);
if secondFile
    plot(time, sync(:, 2) * gain2, ...
        'Color', colorPC2, 'LineWidth', lineWidth);
    legend('refSync', leg1, leg2);
else
    legend('refSync', leg1);
end
xlabel('Time (s)');
ylabel('Amplitude');
hold off;

% -- Close-ups of the start and end of the trial (bottom tiles).
% Number of samples covering syncPlotDuration seconds.
T = round(syncPlotDuration * EMGfrequency);
if T < length(refSync)
    nexttile(3);
    hold on;
    plot(time(1:T), refSync(1:T), ...
        'Color', colorRef, 'LineWidth', lineWidth);
    plot(time(1:T), sync(1:T, 1) * gain1, ...
        'Color', colorPC1, 'LineWidth', lineWidth);
    if secondFile
        plot(time(1:T), sync(1:T, 2) * gain2, ...
            'Color', colorPC2, 'LineWidth', lineWidth);
    end
    xlabel('Time (s)');
    ylabel('Amplitude');
    hold off;

    nexttile(4);
    hold on;
    plot(time(end-T:end), refSync(end-T:end), ...
        'Color', colorRef, 'LineWidth', lineWidth);
    plot(time(end-T:end), sync(end-T:end, 1) * gain1, ...
        'Color', colorPC1, 'LineWidth', lineWidth);
    if secondFile
        plot(time(end-T:end), sync(end-T:end, 2) * gain2, ...
            'Color', colorPC2, 'LineWidth', lineWidth);
    end
    xlabel('Time (s)');
    ylabel('Amplitude');
    hold off;
end

end

function flat = isFlatSync(sig, refSig, threshold)
%ISFLATSYNC True when sig appears to be a dead/disconnected sync pin.
%
%   A sync channel is considered flat when the maximum absolute
% amplitude of its processed derivative falls below threshold times
% the maximum amplitude of refSig. refSig should be a channel with
% known-good signal quality (e.g., refAux from the force-plate PC).
%
% Inputs:
%   sig       - processed sync column (column vector)
%   refSig    - reference sync column for amplitude normalisation
%   threshold - fractional amplitude threshold (scalar, > 0)
%
% Outputs:
%   flat - logical scalar; true when sig appears dead or disconnected
%
% Toolbox Dependencies: None
%
% See also SYNCEMGDATA, MATCHSIGNALS.

arguments
    sig       (:,1) double
    refSig    (:,1) double
    threshold (1,1) double {mustBePositive}
end

refAmp = max(abs(refSig));
if refAmp == 0
    flat = true;    % reference is also flat; cannot normalise
else
    flat = max(abs(sig)) < threshold * refAmp;
end
end
