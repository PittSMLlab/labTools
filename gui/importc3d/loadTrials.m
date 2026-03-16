function trials = loadTrials(trialMD, fileList, secFileList, info)
% loadTrials  Generates rawTrialData instances for each trial.
%
%   Reads kinematic, force, and EMG data from C3D files for each trial
% in the experimental session. For each trial, the function imports
% analog and marker data via the Biomechanics Toolkit (BTK), processes
% ground reaction forces, synchronizes and sorts EMG channels, processes
% accelerometer data, and packages everything into a rawTrialData object.
%
%   When secondary C3D files (PC2 EMG) are expected for the session but
% missing for individual trials, those trials are processed with NaN-
% filled PC2 channels so that all rawTrialData objects in the session
% share a consistent channel layout.
%
%   Inputs:
%     trialMD     - Cell array of trialMetaData objects; cell index
%                   corresponds to trial number
%     fileList    - Cell array of C3D file paths (without extension)
%                   containing kinematic and force data; index
%                   corresponds to trial number
%     secFileList - Cell array of secondary file paths (without extension)
%                   containing EMG data from a second PC; empty entries
%                   indicate no secondary file for that trial
%     info        - Struct of session information returned by GetInfoGUI
%
%   Outputs:
%     trials - Cell array of rawTrialData objects; cell index
%              corresponds to trial number
%
%   Toolbox Dependencies:
%     Signal Processing Toolbox      (medfilt1)
%     Statistics and Machine Learning Toolbox (zscore)
%     BTK - Biomechanics Toolkit     (btkReadAcquisition, btkGetAnalogs,
%                                     btkGetMarkers; external dependency)
%
%   See also: rawTrialData, loadSubject, getTrialMetaData

arguments
    trialMD     cell
    fileList    cell
    secFileList cell
    info        (1,1) struct
end

% -----------------------------------------------------------------------
%  Named constants — centralised here for easy tuning
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

% Integer downsampling factor applied to accelerometer data;
% reduces the native EMG-system rate to approximately 150 Hz
accDownsampleFactor = 13;

% Duration (seconds) of the start and end segments shown in the
% sync diagnostic figure subplots
syncPlotDuration  = 3;

% -----------------------------------------------------------------------

% orientationInfo(offset, foreaftAx, sideAx, updownAx, foreaftSign, ...
%     sideSign, updownSign);
% check signs! this is used in biomechanics calculations
orientation = orientationInfo([0 0 0], 'y', 'x', 'z', 1, 1, 1);

% Define list of expected/accepted muscles in the desired order
orderedMuscleList = {'PER', 'TA', 'TAP', 'TAD', 'SOL', 'MG', 'LG', ...
    'RF', 'VM', 'VL', 'BF', 'SEMB', 'SEMT', 'ADM', 'GLU', 'TFL', ...
    'ILP', 'SAR', 'HIP'};
orderedEMGList = {};
for j = 1:length(orderedMuscleList)
    orderedEMGList{end+1} = ['R' orderedMuscleList{j}];
    orderedEMGList{end+1} = ['L' orderedMuscleList{j}];
end

% Determine whether the session expects data from a second PC at all;
% used to detect trials with missing PC2 files vs. single-PC sessions
sessionHasPC2 = any(~cellfun(@isempty, secFileList));

% Pre-allocate output cell array to avoid repeated dynamic growth
trialNums = cell2mat(info.trialnums);
trials    = cell(1, max(trialNums));

for tr = trialNums                      % for each trial, ...
    % FIXME: close all figures and remove intermediate variables to
    % free up some memory in MATLAB.
    % There seems to be a memory issue since summer 2025. During
    % c3d2mat, the PC will run out of memory, shown as OutOfMemory,
    % OutOfHeapSpace, or png file failed to write errors. A better
    % solution is needed to identify why we are running out of memory
    % or if we have a memory leak. Since the cause is not yet known,
    % closing figures and removing variables is a temporary workaround
    % to allow the code to run.
    close('all');
    clc();
    clearvars -except trialMD fileList secFileList info tr ...
        orderedEMGList orientation trials sessionHasPC2 trialNums ...
        medFiltKernel medFiltDiffKernel clipPercentile ...
        syncMismatchThreshold accDownsampleFactor syncPlotDuration;

    % Import C3D data using BTK (Biomechanics Toolkit)
    H = btkReadAcquisition([fileList{tr} '.c3d']);
    [analogs, analogsInfo] = btkGetAnalogs(H);

    % Load secondary PC file if present; flag missing file separately
    % from single-PC sessions so PC2 channels can be NaN-filled
    secondFile  = false;
    pc2Missing  = false;
    secFilePath = [secFileList{tr} '.c3d'];
    if isfile(secFilePath)              % if C3D files (EMG) on PC2,...
        H2 = btkReadAcquisition(secFilePath);
        [analogs2, analogsInfo2] = btkGetAnalogs(H2);
        secondFile = true;              % indicate two PCs of EMG data
    elseif sessionHasPC2                % PC2 expected but file absent
        pc2Missing = true;
        warning('loadTrials:missingPC2', ...
            ['Secondary C3D file is missing for trial ' num2str(tr) '. '...
            'PC2 EMG channels will be filled with NaN for this trial to'...
            'maintain a consistent channel layout across the session.']);
    end

    %% Process Ground Reaction Force (GRF) Data
    if info.forces          % if there is force data in the trial, ...
        % Must be defined to prevent errors when 'otherwise' skipped
        showWarning = false;
        relData     = [];
        forceLabels = {};
        units       = {};
        fieldList   = fieldnames(analogs);

        % Collect all raw analog channels for offset calibration
        rawMask  = startsWith(fieldList, 'Raw');
        ttt      = fieldList(rawMask);
        rawCells = cellfun(@(f) analogs.(f), ttt, 'UniformOutput', false);
        raws = [rawCells{:}];
        raws = zscore(raws);

        % Fixed force plate label prefixes for channels 3-7;
        % channels 1 and 2 are belt-dependent (see below)
        fpPrefixMap = containers.Map( ...
            {'3', '4', '5', '6', '7'}, {'H', 'FP4', 'FP5', 'FP6', 'FP7'});

        % For each force, moment, center of pressure (COP) channel, ...
        for j = 1:length(fieldList)

            % Skip fields that are not force or moment channels
            isForceOrMoment = ...
                strcmp(fieldList{j}(1), 'F')    || ...
                strcmp(fieldList{j}(1), 'M')    || ...
                contains(fieldList{j}, 'Force') || ...
                contains(fieldList{j}, 'Moment');
            if ~isForceOrMoment
                continue;
            end

            % Skip and warn for channels without a valid axis label
            hasValidAxis = ...
                strcmpi('x', fieldList{j}(end-1)) || ...
                strcmpi('y', fieldList{j}(end-1)) || ...
                strcmpi('z', fieldList{j}(end-1));
            if ~hasValidAxis
                warning(['loadTrials:GRFs' ...
                    'Found force/moment data that does not correspond ' ...
                    'to any of the expected directions (x, y, or z). ' ...
                    'Discarding channel ' fieldList{j}]);
                continue;
            end

            % Resolve the force plate label prefix from the channel
            % suffix digit. Channels 1 and 2 are belt-dependent:
            % normal walking assigns channel 1 to Left and channel 2
            % to Right; backward walking swaps this assignment.
            % Channels 3-7 use fixed prefixes from the lookup table.
            chSuffix = fieldList{j}(end);
            if strcmp(chSuffix, '1')        % belt FP: left or right
                if info.backwardCheck == 1
                    prefix = 'R';           % backward: ch1 = right
                else
                    prefix = 'L';           % normal:   ch1 = left
                end
            elseif strcmp(chSuffix, '2')    % belt FP: right or left
                if info.backwardCheck == 1
                    prefix = 'L';           % backward: ch2 = left
                else
                    prefix = 'R';           % normal:   ch2 = right
                end
            elseif isKey(fpPrefixMap, chSuffix)
                prefix = fpPrefixMap(chSuffix);
            else
                % Unrecognized channel suffix; set warning flag and
                % remove field to keep analogs clean, then skip the
                % label/data append. Warning is deferred outside the
                % loop to reduce command window output (HH, 6/3/2015)
                showWarning = true;
                analogs     = rmfield(analogs, fieldList{j});
                continue;
            end

            % Append label, units, and data for this valid channel,
            % then remove the field to free memory
            forceLabels{end+1} = [prefix fieldList{j}(end-2:end-1)];
            units{end+1}       = analogsInfo.units.(fieldList{j});
            relData            = [relData analogs.(fieldList{j})];
            analogs            = rmfield(analogs, fieldList{j});
        end
        if showWarning
            warning(['loadTrials:GRFs' ...
                'Found force/moment data in trial ' num2str(tr) ...
                ' that does not correspond to any of the expected ' ...
                'channels (L=1, R=2, H=4). Data discarded.']);
        end

        % Sanity check: offset calibration — verify that force values
        % from analog pins have zero mode and correct scale/units.
        try
            % map=[1:6,8:13,46:51]; % Forces and moments to
            % corresponding pin in. Not current. Pablo, 22/11/2019.
            list = {'LFx', 'LFy', 'LFz', 'LMx', 'LMy', 'LMz', ...
                'RFx', 'RFy', 'RFz', 'RMx', 'RMy', 'RMz', ...
                'HFx', 'HFy', 'HFz', 'HMx', 'HMy', 'HMz'};
            offset                 = nan(size(list));
            gain                   = nan(size(list));
            trueOffset             = nan(size(list));
            differenceInForceUnits = nan(size(list));
            m                      = nan(size(list));
            tol = 10;   % N or N.m
            for j = 1:length(list)
                k = find(strcmp(forceLabels, list{j}));
                if ~isempty(k)
                    aux = fieldnames(analogs);
                    % idx=num2str(map(k)); % Hardcoded map of input
                    % pins to forces/moments. Outdated.
                    [~, idx] = max(abs(relData(:, k)' * raws));
                    idx          = ttt{idx}(end);
                    pinFieldMask = ~cellfun(@isempty, ...
                        regexp(aux, ['Pin_' idx '$']));
                    raw  = analogs.(aux{pinFieldMask});
                    proc = relData(:, k);
                    % figure; plot(raw,proc,'.') % Finally found
                    % where c3d2mat plots were coming from
                    rel = find(proc ~= 0);
                    if ~isempty(rel)
                        % Can be used for thresholding
                        m(j)  = 4 * prctile(abs(proc(rel)), 1);
                        coef  = polyfit(raw(rel), proc(rel), 1);
                        % Could be rounded to 2 sig. figs.
                        gain(j)   = coef(1);
                        offset(j) = -coef(2) / coef(1);
                        % histcounts requires bin edges, not centers;
                        % shift center vector by half a bin width to
                        % form edges for equivalent binning behavior.
                        % find(..., 1) picks the lowest-valued bin
                        % center deterministically when counts are tied.
                        C        = -1:0.001:1;
                        binWidth = C(2) - C(1);
                        edges    = (C(1) - binWidth/2) : ...
                            binWidth : (C(end) + binWidth/2);
                        Hh            = histcounts(raw, edges);
                        trueOffset(j) = C(find(Hh == max(Hh), 1));
                        differenceInForceUnits(j) = ...
                            gain(j) * (trueOffset(j) - offset(j));
                    end
                    switch list{j}(2)
                        case 'F'    % forces
                            ttol  = tol;
                            units = 'N';
                        case 'M'    % moments (in N.mm)
                            ttol  = tol * 1000;
                            units = 'N.mm';
                        otherwise
                            error('');
                    end
                    if differenceInForceUnits(j) > ttol
                        % figure % Commented out by MGR 01/24/24
                        % hold on
                        % plot(raw(rel),proc(rel),'.')
                        % plot([-0.01 0.01], ...
                        %     ([-0.01 0.01]+offset(j))*gain(j))
                        % hold off
                        % a=questdlg(['When loading ' list{j} ...
                        %   ' there appears to be a non-zero mode ' ...
                        %   '(offset). Calculated offset is ' ...
                        %   num2str(differenceInForceUnits(j)) ' ' ...
                        %   units '. Please confirm that you want ' ...
                        %   'to subtract this offset.']);
                        a = 'No';
                        switch a
                            case 'Yes'
                                relData(:, k) = ...
                                    gain(j) * (raw - trueOffset(j));
                                % Threshold using tolerance; should
                                % never be less than 2*ttol
                                relData(abs(relData(:, k)) < ...
                                    4*ttol, k) = 0;
                            case 'No'
                                % nop
                            otherwise
                                error('');
                        end
                    end
                end
            end
        catch ME
            warning('loadTrials:GRFs', ...
                ['Could not perform offset check for trial ' ...
                num2str(tr) '. Proceeding with data as is. ' ...
                'Error: ' ME.message]);
        end

        % Create 'labTimeSeries' object
        % (data, t0, Ts, labels, orientation)
        % If fewer than three forces and moments per TM FP, warn
        if size(relData, 2) < 12
            warning('loadTrials:GRFs', ...
                ['Did not find all GRFs for the two belts ' ...
                'in trial ' num2str(tr)]);
        end
        GRFData = orientedLabTimeSeries(relData, 0, ...
            1/analogsInfo.frequency, forceLabels, orientation);
        GRFData.DataInfo.Units = units;
    else
        GRFData = [];
    end
    clear relData* raws;

    %% Process EMG and Accelerometer Data (Two Files / Two PCs)
    if info.EMGs
        % -- Primary file (PC 1)
        if info.Nexus == 1
            relData   = [];
            fieldList = fieldnames(analogs);

            % Identify all EMG channel fields, parse their channel
            % numbers, extract data, and remove fields to save memory
            emgMask     = contains(fieldList, 'EMG');
            emgFields   = fieldList(emgMask);
            idxList     = cellfun(@(f) ...
                str2double(f(strfind(f, 'EMG')+3:end)), emgFields);
            emgCells    = cellfun(@(f) analogs.(f), emgFields, ...
                'UniformOutput', false);
            relDataTemp = [emgCells{:}];
            analogs     = rmfield(analogs, emgFields);

            emptyChannels1 = cellfun(@isempty, info.EMGList1);
            EMGList1       = info.EMGList1(~emptyChannels1);
            % Re-sort to fix 1,10,11,...,2,3 ordering from MATLAB
            relData(:, idxList) = relDataTemp;
            relData = relData(:, ~emptyChannels1);
            EMGList = EMGList1;

            % -- Secondary file (PC 2)
            idxList2 = [];
            if secondFile
                fieldList = fieldnames(analogs2);

                % Identify all EMG channel fields, parse their channel
                % numbers, extract data, and remove to save memory
                emgMask2     = contains(fieldList, 'EMG');
                emgFields2   = fieldList(emgMask2);
                idxList2     = cellfun(@(f) ...
                    str2double(f(strfind(f, 'EMG')+3:end)), emgFields2);
                emgCells2    = cellfun(@(f) analogs2.(f), emgFields2,...
                    'UniformOutput', false);
                relDataTemp2 = [emgCells2{:}];
                analogs2     = rmfield(analogs2, emgFields2);

                emptyChannels2 = cellfun(@isempty, info.EMGList2);
                % Use names only for channels in the file
                EMGList2 = info.EMGList2(~emptyChannels2);
                % Re-sort to fix 1,10,11,...,2,3 ordering
                relData2(:, idxList2) = relDataTemp2;
                relData2 = relData2(:, ~emptyChannels2);
                EMGList  = [EMGList1, EMGList2];
            elseif pc2Missing
                % PC2 file absent: derive channel metadata from session
                % info so the EMG channel layout remains consistent.
                % NaN data is appended to allData after sync processing
                % (EMGList is updated there to avoid a column mismatch
                % between allData and syncIdx during sync computation).
                emptyChannels2 = cellfun(@isempty, info.EMGList2);
                EMGList2 = info.EMGList2(~emptyChannels2);
                % idxList2 is empty; info.EMGList2 is not updated in
                % the name-validation loop when pc2Missing is true
            end
        elseif info.EMGworks == 1
            [analogs, EMGList, relData, relData2, secondFile, ...
                analogsInfo2, emptyChannels1, emptyChannels2, ...
                EMGList1, EMGList2] = getEMGworksdata( ...
                info.EMGList1, info.EMGList2, ...
                info.secEMGworksdir_location, ...
                info.EMGworksdir_location, fileList{tr});
        end

        % Check if muscle names match expectations; query user if not.
        % When pc2Missing, only PC1 names (in EMGList = EMGList1) are
        % validated here; PC2 names from info.EMGList2 are assumed
        % valid since they were set in a prior session or in the GUI.
        for k = 1:length(EMGList)
            while sum(strcmpi(orderedEMGList, EMGList{k})) == 0 ...
                    && ~strcmpi(EMGList{k}(1:4), 'sync')
                aux = inputdlg( ...
                    ['Did not recognize muscle name, please ' ...
                    're-enter name for channel ' num2str(k) ...
                    ' (was ' EMGList{k} '). Acceptable values ' ...
                    'are ' cell2mat(strcat(orderedEMGList, ', ')) ...
                    ' or ''sync''.'], 's');
                if k <= length(EMGList1)
                    info.EMGList1{idxList(k)} = aux{1};
                elseif ~pc2Missing
                    % Only update info when PC2 data was actually
                    % loaded; idxList2 is empty when pc2Missing
                    info.EMGList2{idxList2(k-length(EMGList1))} = aux{1};
                end
                EMGList{k} = aux{1};
            end
        end

        % Locate the reference sync pin channel; the naming convention
        % is not kept consistently across Nexus versions, so all three
        % known variants are checked simultaneously using contains with
        % a string array, which operates directly on the cell array
        fieldNames  = fieldnames(analogs);
        refSyncMask = contains(fieldNames, {'Pin3', 'Pin_3', 'Raw_3'});
        refSync     = analogs.(fieldNames{refSyncMask});

        % Check for frequency mismatch between the two PCs
        if secondFile
            if abs(analogsInfo.frequency - analogsInfo2.frequency) ...
                    > eps
                warning(['Sampling rates from the two computers are ' ...
                    'different, down-sampling one under the assumption '...
                    'that sampling rates are multiples of each other.']);
                % Assume sampling rates are multiples of one another
                if analogsInfo.frequency > analogsInfo2.frequency
                    % First set is the up-sampled one; reducing
                    P       = analogsInfo.frequency / ...
                        analogsInfo2.frequency;
                    R       = round(P);
                    relData = relData(1:R:end, :);
                    refSync = refSync(1:R:end);
                    EMGfrequency = analogsInfo2.frequency;
                else
                    P        = round(analogsInfo2.frequency / ...
                        analogsInfo.frequency);
                    R        = round(P);
                    relData2 = relData2(1:R:end, :);
                    EMGfrequency = analogsInfo.frequency;
                end
                if abs(R - P) > 1e-7
                    error('loadTrials:unmatchedSamplingRatesForEMG', ...
                        ['The different EMG files are sampled at ' ...
                        'different rates and they are not multiples' ...
                        ' of one another.']);
                end
            else
                EMGfrequency = analogsInfo.frequency;
            end
        else
            EMGfrequency = analogsInfo.frequency;
        end

        % Keep only matrices of the same size.
        % When pc2Missing, only PC1 data is in allData during sync;
        % PC2 NaN columns are appended after sync processing below.
        if secondFile
            [auxData, auxData2] = truncateToSameLength(relData, relData2);
            allData = [auxData, auxData2];
            clear auxData*;
        else
            allData = relData;
        end

        % Pre-process reference sync signal: clip outliers, then
        % median-filter the signal and its derivative
        refSync = clipSignals(refSync(:), clipPercentile);
        refAux  = medfilt1(refSync, medFiltKernel);
        % refAux(refAux<(median(refAux)-5*iqr(refAux)) | ...
        %     refAux>(median(refAux)+5*iqr(refAux)))=median(refAux);
        refAux = medfilt1(diff(refAux), medFiltDiffKernel);
        clear auxData*;

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
                [~, timeScaleFactor, lagInSamples, ~] = ...
                    matchSignals(aux(:, 1), aux(:, 2));
                % [~,timeScaleFactor,lagInSamples,~] = ...
                %     matchSignals(refAux,aux(:,2));
                % Align relData2 to relData1; overall delay of EMG
                % system re. force plate data still to be determined
                newRelData2 = resampleShiftAndScale( ...
                    relData2, timeScaleFactor, lagInSamples, 1);
            end
            [~, ~, lagInSamplesA, ~] = matchSignals(refAux, aux(:, 1));
            newRelData = resampleShiftAndScale( ...
                relData, 1, lagInSamplesA, 1);
            if secondFile
                newRelData2 = resampleShiftAndScale( ...
                    newRelData2, 1, lagInSamplesA, 1);
                % [~,timeScaleFactor,lagInSamples,~] = ...
                %     matchSignals(refAux,aux(:,2)); % DMMO/ARL change
                % newRelData2 = resampleShiftAndScale( ...
                %     newRelData2,1,lagInSamples,1); % DMMO/ARL change
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
            refSync = idealHPF(refSync, 0);    % remove DC only
            [allData, refSync] = truncateToSameLength(allData, refSync);
            sync = allData(:, syncIdx);
            sync = clipSignals(sync, clipPercentile);
            sync = idealHPF(sync, 0);
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
            disp(['Sync parameters to ref. signal were: gains= ' ...
                num2str(gain1, 4) ', ' num2str(gain2, 4) '; delays= ' ...
                num2str(lagInSamplesA/EMGfrequency, 3) 's, ' ...
                num2str((lagInSamplesA+lagInSamples)/EMGfrequency,3) 's']);
            disp(['Typical sync parameters are: ' ...
                'gains= -933.3 +- 0.2 (both); ' ...
                'delays= -0.025s +- 0.001, 0.014 +- 0.002']);
            disp(['Sync parameters between PCs were: gain= ' ...
                num2str(gain1/gain2, 4) '; delay= ' ...
                num2str(lagInSamples/EMGfrequency, 3) ...
                's; sampling mismatch (ppm)= ' ...
                num2str(1e6*(1-timeScaleFactor), 3)]);
            disp(['Typical sync parameters are: gain= 1; ' ...
                'delay= 0.040s; sampling= 35 ppm']);

            % Warn and prompt the user if mismatch energy exceeds the
            % threshold. The pipeline halts here to allow inspection
            % of the sync figure before deciding to proceed or abort.
            if isnan(E1) || isnan(E2) || ...
                    E1 > syncMismatchThreshold || ...
                    E2 > syncMismatchThreshold
                warning('loadTrials:syncMismatchHigh', ...
                    ['[Trial %d] EMG sync mismatch energy is high ' ...
                    '(PC1: %.2f%%, PC2: %.2f%%). At least one PC ' ...
                    'exceeds the threshold of %.0f%%. Synchronization ' ...
                    'quality may be poor. Inspect the sync figure for ' ...
                    'trial %d before deciding whether to proceed.'], ...
                    tr, 100*E1, 100*E2, 100*syncMismatchThreshold, tr);
                h = plotSyncFigure(tr, refSync, sync, gain1, gain2, ...
                    lagInSamplesA, lagInSamples, E1, E2, EMGfrequency, ...
                    secondFile, syncPlotDuration);
                s = inputdlg( ...
                    ['If sync parameters between signals look fine and '...
                    'mismatch is below 5%, we recommend yes.'], ...
                    'Please confirm that you want to proceed (y/n).');
                switch s{1}
                    case {'y', 'Y', 'yes'}
                        disp(['Using signals in a possibly ' ...
                            'unsynchronized way!.']);
                        close(h);
                    case {'n', 'N', 'no'}
                        error( ...
                            'loadTrials:EMGCouldNotBeSynched', ...
                            ['[Trial %d] Could not synchronize EMG ' ...
                            'data. Processing stopped at user request ' ...
                            'after sync mismatch of PC1: %.2f%%, PC2: ' ...
                            '%.2f%%.'], tr, 100*E1, 100*E2);
                end
            end

            % Plot to visually confirm alignment, then save the figure.
            h = plotSyncFigure(tr, refSync, sync, ...
                gain1, gain2, lagInSamplesA, lagInSamples, ...
                E1, E2, EMGfrequency, secondFile, syncPlotDuration);
            saveFig(h, ...
                [fullfile(info.save_folder, 'EMGSyncFile') filesep], ...
                ['Trial ' num2str(tr) ' Synchronization']);
            % uiwait(h)
        else
            warning('loadTrials:noSyncSignals', ...
                ['[Trial %d] No sync signals were present. ' ...
                'Using data as-is without time alignment.'], tr);
        end

        % When the PC2 file was missing for this trial, append NaN
        % columns to allData and update EMGList now that sync
        % processing is complete and allData columns match EMGList.
        if pc2Missing
            nPC2ch  = sum(~emptyChannels2);
            allData = [allData, NaN(size(allData, 1), nPC2ch)];
            EMGList = [EMGList, EMGList2];
        end

        % Map each entry of orderedEMGList to its column position in
        % EMGList using case-insensitive matching via ismember with
        % lower(), which is equivalent to the original strcmpi loop.
        % Zero entries (muscles absent from this session) are removed.
        [~, orderedIndexes] = ismember( ...
            lower(orderedEMGList(:)), lower(EMGList(:)));
        orderedIndexes = orderedIndexes(orderedIndexes ~= 0);

        % Identify EMGList channels not present in orderedEMGList;
        % warn if any are found that are not sync signals
        inOrdered = ismember(lower(EMGList(:)), lower(orderedEMGList(:)));
        if any(~inOrdered) && ~all(strcmpi(EMGList(~inOrdered), 'sync'))
            warning(['loadTrials: Not all of the provided muscles ' ...
                'are in the ordered list, ignoring ' EMGList{~inOrdered}]);
        end

        % Set exactly-zero samples to NaN (unavailable samples)
        allData(allData == 0) = NaN;
        % Discard sync signal; store remainder as EMGData object
        EMGData = labTimeSeries(allData(:, orderedIndexes), 0, ...
            1/EMGfrequency, EMGList(orderedIndexes));
        clear allData* relData* auxData*;

        %% Process Accelerometer Data
        % -- Primary file (PC 1)
        if info.Nexus == 1
            relData   = [];
            fieldList = fieldnames(analogs);

            % Identify ACC fields and loop only over those, assigning
            % each channel into a 3D array (samples × channel × axis).
            % rmfield is called once on all ACC fields after the loop.
            accMask   = contains(fieldList, 'ACC');
            accFields = fieldList(accMask);
            for j = 1:length(accFields)
                accPos = strfind(accFields{j}, 'ACC');
                chIdx  = str2double(accFields{j}(accPos+4:end));
                switch accFields{j}(accPos+3)
                    case 'X',  axIdx = 1;
                    case 'Y',  axIdx = 2;
                    case 'Z',  axIdx = 3;
                end
                relData(:, chIdx, axIdx) = analogs.(accFields{j});
            end
            analogs = rmfield(analogs, accFields);

            relData = permute(relData(:, ~emptyChannels1, :), [1, 3, 2]);
            relData = relData(:, :);
            % Downsample if frequency changed during EMG processing
            if EMGfrequency ~= analogsInfo.frequency
                P       = analogsInfo.frequency / EMGfrequency;
                R       = round(P);
                relData = relData(1:R:end, :);
            end
            % Apply time alignment correction
            if ~isempty(sync)
                relData = resampleShiftAndScale( ...
                    relData, 1, lagInSamplesA, 1);
            end

            % -- Secondary file (PC 2)
            relData2 = [];
            if secondFile
                fieldList = fieldnames(analogs2);

                % Identify ACC fields and assign into 3D array;
                % rmfield is called once after the loop
                accMask2   = contains(fieldList, 'ACC');
                accFields2 = fieldList(accMask2);
                for j = 1:length(accFields2)
                    accPos = strfind(accFields2{j}, 'ACC');
                    chIdx  = str2double(accFields2{j}(accPos+4:end));
                    switch accFields2{j}(accPos+3)
                        case 'X',  axIdx = 1;
                        case 'Y',  axIdx = 2;
                        case 'Z',  axIdx = 3;
                    end
                    relData2(:, chIdx, axIdx) = analogs2.(accFields2{j});
                end
                analogs2 = rmfield(analogs2, accFields2);

                relData2 = permute( ...
                    relData2(:, ~emptyChannels2, :), [1, 3, 2]);
                relData2 = relData2(:, :);
                % Downsample if frequency changed
                if EMGfrequency ~= analogsInfo2.frequency
                    P        = analogsInfo2.frequency / EMGfrequency;
                    R        = round(P);
                    relData2 = relData2(1:R:end, :);
                end
                % Apply time alignment correction
                if ~isempty(sync)
                    % Align relData2 to relData1
                    relData2 = resampleShiftAndScale( ...
                        relData2, timeScaleFactor, lagInSamples, 1);
                    relData2 = resampleShiftAndScale( ...
                        relData2, 1, lagInSamplesA, 1);
                    [auxData, auxData2] = ...
                        truncateToSameLength(relData, relData2);
                    clear relData*;
                    allData = [auxData, auxData2];
                    clear auxData*;
                else
                    allData = [relData, relData2]; % no sync, two files
                end
            else
                allData = relData;
                % When PC2 file was missing, append NaN columns for
                % PC2 ACC channels (3 axes per channel) so that all
                % trials have the same accelerometer channel layout
                if pc2Missing
                    nPC2acc = 3 * sum(~emptyChannels2);
                    allData = [allData, NaN(size(allData, 1), nPC2acc)];
                end
            end

            % Assign ACC channel name labels.
            % At this point EMGList includes both PC1 and (when
            % applicable) PC2 names, so ACCList covers all channels.
            ACCList = {};
            for j = 1:length(EMGList)
                ACCList{end+1} = [EMGList{j} 'x'];
                ACCList{end+1} = [EMGList{j} 'y'];
                ACCList{end+1} = [EMGList{j} 'z'];
            end

            % Downsample by accDownsampleFactor to approximately
            % 150 Hz (closer to original 148 Hz rate)
            % (where does this get upsampled? why?)
            accData = orientedLabTimeSeries( ...
                allData(1:accDownsampleFactor:end, :), 0, ...
                accDownsampleFactor/EMGfrequency, ACCList, orientation);
            % Note: orientation is local and unique to each sensor,
            % which is affixed to a body segment
        elseif info.EMGworks == 1
            % [ACCList, allData, analogsInfo] = getEMGworksdataAcc( ...
            %     info.EMGList2, info.secEMGworksdir_location, ...
            %     info.EMGworksdir_location, fileList{tr}, ...
            %     emptyChannels1, emptyChannels2, EMGList);
            % Samplingfrequency = analogsInfo.frequency;
            accData = [];
            % accData = orientedLabTimeSeries( ...
            %     allData(1:accDownsampleFactor:end,:), 0, ...
            %     Samplingfrequency, ACCList, orientation);
        end
        clear allData* relData* auxData*;
    else
        EMGData = [];
        accData = [];
    end

    %% Add H-Reflex Stimulator Pin If Present
    relData   = [];
    fieldList = fieldnames(analogs);

    % Identify stimulator trigger fields and extract labels, units,
    % and data in one pass using cellfun, avoiding a growth loop
    stimMask   = startsWith(fieldList, 'Stimulator_Trigger_Sync_');
    stimFields = fieldList(stimMask);
    if ~isempty(stimFields)         % if there is a stimulator pin, ...
        stimLabels = stimFields';
        stimCells  = cellfun(@(f) analogs.(f), stimFields, ...
            'UniformOutput', false);
        relData    = [stimCells{:}];
        % NOTE: second argument is time offset (zero, like force data)
        % third argument is sampling period (1/frequency)
        HreflexStimPinData = labTimeSeries( ...
            relData, 0, 1/analogsInfo.frequency, stimLabels);
        if ~isempty(GRFData)        % if there is GRF data, ...
            % Verify data length matches GRF data
            if GRFData.Length ~= HreflexStimPinData.Length
                error(['Hreflex stimulator pin data has a ' ...
                    'different length than GRF data. This should ' ...
                    'never happen. Data is compromised.']);
            end
        end
    else                            % otherwise, ...
        HreflexStimPinData = [];
    end

    %% Process Motion Capture Marker Data
    % Clear analog data to free memory; no longer needed after loading
    clear analogs*;
    if info.kinematics          % if there is kinematic data, ...
        [markers, markerInfo] = btkGetMarkers(H);
        relData    = [];
        fieldList  = fieldnames(markers);
        markerList = {};

        % Check that required marker labels are present in .c3d files
        mustHaveLabels = {'LHIP', 'RHIP', 'LANK', 'RANK', 'RHEE', ...
            'LHEE', 'LTOE', 'RTOE', 'RKNE', 'LKNE'};
        labelPresent = false(1, length(mustHaveLabels));
        for i = 1:length(fieldList)
            newFieldList{i} = findLabel(fieldList{i});
            labelPresent    = labelPresent + ...
                ismember(mustHaveLabels, newFieldList{i});
        end

        % If any required labels are missing, terminate with error
        % if any(~labelPresent)
        %     missingLabels = find(~labelPresent);
        %     str = ' ';
        %     for j = missingLabels
        %         str = [str ', ' mustHaveLabels{j}];
        %     end
        %     ME = MException('loadTrials:markerDataError', ...
        %         ['Marker data does not contain:' str ...
        %         '. Edit ''findLabel'' code to fix.']);
        %     throw(ME);
        % end

        % Alternatively, prompt user to map any missing labels
        if any(~labelPresent)
            missingLabels    = find(~labelPresent);
            potentialMatches = ...
                newFieldList(~ismember(newFieldList, mustHaveLabels));
            for j = missingLabels
                choice = menu( ...
                    [{['WARNING: the marker label ' mustHaveLabels{j}]},...
                    {' was not found, but is necessary for'}, ...
                    {'future calculations. Please indicate which'}, ...
                    {[' marker corresponds to the ' ...
                    mustHaveLabels{j} ' label:']}], ...
                    [potentialMatches {'NaN'}]);
                if choice == 0
                    ME = MException( ...
                        'loadTrials:markerDataError', ...
                        ['Operation terminated by user while ' ...
                        'finding names of necessary labels.']);
                    throw(ME);
                elseif choice > length(potentialMatches)
                    % nop
                    warning('loadTrials:missingRequiredMarker', ...
                        ['A required marker (' mustHaveLabels{j} ...
                        ') was missing from the marker list. This will '...
                        'be problematic when computing parameters.']);
                else
                    % Map the chosen label to the required label
                    addMarkerPair( ...
                        mustHaveLabels{j}, potentialMatches{choice});
                end
            end
        end

        for j = 1:length(fieldList)
            % Skip unlabeled markers (Vicon 'C_' prefix)
            if length(fieldList{j}) > 2 && ...
                    ~strcmp(fieldList{j}(1:2), 'C_')
                relData = [relData, markers.(fieldList{j})];
                % Standardize marker name via findLabel
                markerLabel       = findLabel(fieldList{j});
                markerList{end+1} = [markerLabel 'x'];
                markerList{end+1} = [markerLabel 'y'];
                markerList{end+1} = [markerLabel 'z'];
            end
            % Remove processed marker to save memory
            markers = rmfield(markers, fieldList{j});
        end
        % Force missing marker data to NaN
        relData(relData == 0) = NaN;
        markerData = orientedLabTimeSeries(relData, 0, ...
            1/markerInfo.frequency, markerList, orientation);
        clear relData;
        markerData.DataInfo.Units = markerInfo.units.ALLMARKERS;
    else
        markerData = [];
    end

    %% Construct rawTrialData Object
    % rawTrialData(metaData, markerData, EMGData, GRFData,
    %     beltSpeedSetData, beltSpeedReadData, accData, EEGData,
    %     footSwitches, HreflexStimPinData)
    trials{tr} = rawTrialData(trialMD{tr}, markerData, EMGData, ...
        GRFData, [], [], accData, [], [], HreflexStimPinData);

end

end

% ============================================================
% ==================== Local Functions =======================
% ============================================================

function h = plotSyncFigure(tr, refSync, sync, gain1, gain2, ...
    lagInSamplesA, lagInSamples, E1, E2, EMGfrequency, ...
    secondFile, syncPlotDuration)
% plotSyncFigure  Creates a 4-panel EMG synchronization diagnostic figure.
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
%     tr               - Trial number (used in the figure title)
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
%   See also: loadTrials

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
title(tl, {['Trial ' num2str(tr) ' Synchronization'], syncQualityStr});

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

