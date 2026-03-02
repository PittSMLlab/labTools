function trials = loadTrials(trialMD, fileList, secFileList, info)
% loadTrials  Generates rawTrialData instances for each trial.
%
%   Reads kinematic, force, and EMG data from C3D files for each trial
% in the experimental session. For each trial, the function imports
% analog and marker data via the Biomechanics Toolkit (BTK), processes
% ground reaction forces, synchronizes and sorts EMG channels, processes
% accelerometer data, and packages everything into a rawTrialData object.
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

for tr = cell2mat(info.trialnums)       % for each trial, ...
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
        orderedEMGList orientation trials;

    % Import C3D data using BTK (Biomechanics Toolkit)
    H = btkReadAcquisition([fileList{tr} '.c3d']);
    [analogs, analogsInfo] = btkGetAnalogs(H);
    secondFile = false;
    if ~isempty(secFileList{tr})        % if C3D files (EMG) on PC2, ...
        H2 = btkReadAcquisition([secFileList{tr} '.c3d']);
        [analogs2, analogsInfo2] = btkGetAnalogs(H2);
        secondFile = true;              % indicate two PCs of EMG data
    end

    %% Process Ground Reaction Force (GRF) Data
    if info.forces          % if there is force data in the trial, ...
        % Must be defined to prevent errors when 'otherwise' skipped
        showWarning = false;
        relData     = [];
        forceLabels = {};
        units       = {};
        fieldList   = fieldnames(analogs);
        fL   = cellfun(@(x) ~isempty(x), regexp(fieldList, '^Raw'));
        ttt  = fieldList(fL);
        raws = [];
        for ii = 1:length(ttt)
            raws = [raws analogs.(ttt{ii})]; % extract raw analog data
        end
        raws = zscore(raws);
        % For each force, moment, center of pressure (COP) channel, ...
        for j = 1:length(fieldList)
            % If field starts with 'F', 'M', or contains
            % 'Force'/'Moment', process it
            if strcmp(fieldList{j}(1), 'F') || ...
                    strcmp(fieldList{j}(1), 'M') || ...
                    ~isempty(strfind(fieldList{j}, 'Force')) || ...
                    ~isempty(strfind(fieldList{j}, 'Moment'))
                if ~strcmpi('x', fieldList{j}(end-1)) && ...
                        ~strcmpi('y', fieldList{j}(end-1)) && ...
                        ~strcmpi('z', fieldList{j}(end-1))
                    warning(['loadTrials:GRFs' ...
                        'Found force/moment data that does not ' ...
                        'correspond to any of the expected ' ...
                        'directions (x, y, or z). Discarding ' ...
                        'channel ' fieldList{j}]);
                else
                    switch fieldList{j}(end)    % parse force channels
                        case '1'    % left (fwd) / right (bwd) TM FP
                            if info.backwardCheck == 1
                                forceLabels{end+1} = ...
                                    ['R' fieldList{j}(end-2:end-1)];
                            else
                                forceLabels{end+1} = ...
                                    ['L' fieldList{j}(end-2:end-1)];
                            end
                            units{end+1} = ...
                                analogsInfo.units.(fieldList{j});
                            relData = ...
                                [relData analogs.(fieldList{j})];
                        case '2'    % right (fwd) / left (bwd) TM FP
                            if info.backwardCheck == 1
                                forceLabels{end+1} = ...
                                    ['L' fieldList{j}(end-2:end-1)];
                            else
                                forceLabels{end+1} = ...
                                    ['R' fieldList{j}(end-2:end-1)];
                            end
                            units{end+1} = ...
                                analogsInfo.units.(fieldList{j});
                            relData = ...
                                [relData analogs.(fieldList{j})];
                        case '3'    % handrail forces / moments
                            forceLabels{end+1} = ...
                                ['H' fieldList{j}(end-2:end-1)];
                            units{end+1} = ...
                                analogsInfo.units.(fieldList{j});
                            relData = ...
                                [relData analogs.(fieldList{j})];
                        case '4'    % other force plate, just in case
                            forceLabels{end+1} = ...
                                ['FP4' fieldList{j}(end-2:end-1)];
                            units{end+1} = ...
                                analogsInfo.units.(fieldList{j});
                            relData = ...
                                [relData analogs.(fieldList{j})];
                        case '5'    % other force plate, just in case
                            forceLabels{end+1} = ...
                                ['FP5' fieldList{j}(end-2:end-1)];
                            units{end+1} = ...
                                analogsInfo.units.(fieldList{j});
                            relData = ...
                                [relData analogs.(fieldList{j})];
                        case '6'    % other force plate, just in case
                            forceLabels{end+1} = ...
                                ['FP6' fieldList{j}(end-2:end-1)];
                            units{end+1} = ...
                                analogsInfo.units.(fieldList{j});
                            relData = ...
                                [relData analogs.(fieldList{j})];
                        case '7'    % other force plate, just in case
                            forceLabels{end+1} = ...
                                ['FP7' fieldList{j}(end-2:end-1)];
                            units{end+1} = ...
                                analogsInfo.units.(fieldList{j});
                            relData = ...
                                [relData analogs.(fieldList{j})];
                        otherwise
                            % HH moved warning outside loop on
                            % 6/3/2015 to reduce command window output
                            showWarning = true;
                    end
                    % Remove processed channel to save memory
                    analogs = rmfield(analogs, fieldList{j});
                end
            end
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
                    idx = ttt{idx}(end);
                    iii = find(cellfun(@(x) ~isempty(x), ...
                        regexp(aux, ['Pin_' idx '$'])));
                    raw  = analogs.(aux{iii});
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
                        C  = [-1:0.001:1];
                        Hh = hist(raw, C);
                        trueOffset(j) = C(Hh == max(Hh));
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
                ['Could not perform offset check. ' ...
                'Proceeding with data as is.']);
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
            relData     = [];
            relDataTemp = [];
            fieldList   = fieldnames(analogs);
            idxList     = [];
            for j = 1:length(fieldList)
                % Get fields that contain 'EMG' only
                if ~isempty(strfind(fieldList{j}, 'EMG'))
                    relDataTemp = [relDataTemp, ...
                        analogs.(fieldList{j})];
                    idxList(end+1) = str2num(fieldList{j}( ...
                        strfind(fieldList{j}, 'EMG')+3:end));
                    % Remove field to save memory
                    analogs = rmfield(analogs, fieldList{j});
                end
            end
            emptyChannels1 = cellfun(@(x) isempty(x), info.EMGList1);
            EMGList1       = info.EMGList1(~emptyChannels1);
            % Re-sort to fix 1,10,11,...,2,3 ordering from MATLAB
            relData(:, idxList) = relDataTemp;
            relData = relData(:, ~emptyChannels1);
            EMGList = EMGList1;

            % -- Secondary file (PC 2)
            relDataTemp2 = [];
            idxList2     = [];
            if secondFile
                fieldList = fieldnames(analogs2);
                for j = 1:length(fieldList)
                    % Get fields that contain 'EMG' only
                    if ~isempty(strfind(fieldList{j}, 'EMG'))
                        relDataTemp2 = [relDataTemp2, ...
                            analogs2.(fieldList{j})];
                        idxList2(end+1) = str2num(fieldList{j}( ...
                            strfind(fieldList{j}, 'EMG')+3:end));
                        % Remove field to save memory
                        analogs2 = rmfield(analogs2, fieldList{j});
                    end
                end
                emptyChannels2 = ...
                    cellfun(@(x) isempty(x), info.EMGList2);
                % Use names only for channels in the file
                EMGList2 = info.EMGList2(~emptyChannels2);
                % Re-sort to fix 1,10,11,...,2,3 ordering
                relData2(:, idxList2) = relDataTemp2;
                relData2 = relData2(:, ~emptyChannels2);
                EMGList  = [EMGList1, EMGList2];
            end
        elseif info.EMGworks == 1
            [analogs, EMGList, relData, relData2, secondFile, ...
                analogsInfo2, emptyChannels1, emptyChannels2, ...
                EMGList1, EMGList2] = getEMGworksdata( ...
                info.EMGList1, info.EMGList2, ...
                info.secEMGworksdir_location, ...
                info.EMGworksdir_location, fileList{tr});
        end

        % Check if muscle names match expectations; query user if not
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
                else
                    info.EMGList2{idxList2(k-length(EMGList1))} = ...
                        aux{1};
                end
                EMGList{k} = aux{1};
            end
        end

        % Note: analog pin naming convention is not kept consistently
        % across Nexus versions
        fieldNames = fieldnames(analogs);
        refSync    = analogs.(fieldNames{cellfun( ...
            @(x) ~isempty(strfind(x, 'Pin3'))  | ...
            ~isempty(strfind(x, 'Pin_3')) | ...
            ~isempty(strfind(x, 'Raw_3')), fieldNames)});

        % Check for frequency mismatch between the two PCs
        if secondFile
            if abs(analogsInfo.frequency - analogsInfo2.frequency) ...
                    > eps
                warning(['Sampling rates from the two computers ' ...
                    'are different, down-sampling one under the ' ...
                    'assumption that sampling rates are multiples ' ...
                    'of each other.']);
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
                    error( ...
                        'loadTrials:unmatchedSamplingRatesForEMG', ...
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

        % Keep only matrices of the same size
        if secondFile
            [auxData, auxData2] = ...
                truncateToSameLength(relData, relData2);
            allData = [auxData, auxData2];
            clear auxData*;
        else
            allData = relData;
        end

        % Pre-process reference sync signal
        % Clip top and bottom 0.1% of samples (1 out of 1e3)
        refSync = clipSignals(refSync(:), 0.1);
        refAux  = medfilt1(refSync, 20);
        % refAux(refAux<(median(refAux)-5*iqr(refAux)) | ...
        %     refAux>(median(refAux)+5*iqr(refAux)))=median(refAux);
        refAux = medfilt1(diff(refAux), 10);
        clear auxData*;

        syncIdx = strncmpi(EMGList, 'Sync', 4); % compare first 4 chars
        sync    = allData(:, syncIdx);

        if ~isempty(sync)           % if sync signals present, proceed
            % Clip top and bottom 0.1%
            sync = clipSignals(sync, 0.1);
            N    = size(sync, 1);
            aux  = medfilt1(sync, 20, [], 1); % median filter for spikes
            % aux(aux>(median(aux)+5*iqr(aux)) | ...
            %     aux<(median(aux)-5*iqr(aux)))=median(aux(:));
            aux = medfilt1(diff(aux), 10, [], 1);
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
            [~, timeScaleFactorA, lagInSamplesA, ~] = ...
                matchSignals(refAux, aux(:, 1));
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
            refSync = clipSignals(refSync(:), 0.1);
            refSync = idealHPF(refSync, 0);    % remove DC only
            [allData, refSync] = ...
                truncateToSameLength(allData, refSync);
            sync = allData(:, syncIdx);
            sync = clipSignals(sync, 0.1);
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
                indStart = round( ...
                    max([lagInSamplesA+1+lagInSamples, 1]));
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
            disp(['Sync complete: mismatch signal energy (as %) ' ...
                'was ' num2str(100*E1, 3) ' and ' ...
                num2str(100*E2, 3) '.']);
            disp(['Sync parameters to ref. signal were: gains= ' ...
                num2str(gain1, 4) ', ' num2str(gain2, 4) ...
                '; delays= ' ...
                num2str(lagInSamplesA/EMGfrequency, 3) 's, ' ...
                num2str((lagInSamplesA+lagInSamples)/ ...
                EMGfrequency, 3) 's']);
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

            % Warn if mismatch exceeds 1% of original signal energy
            if isnan(E1) || isnan(E2) || E1 > 0.01 || E2 > 0.01
                warning(['Time alignment doesnt seem to have ' ...
                    'worked: signal mismatch is too high in ' ...
                    'trial ' num2str(tr) '.']);
                h = figure();
                subplot(2, 2, [1:2]);
                hold on;
                title(['Trial ' num2str(tr) ' Synchronization']);
                time = [0:length(refSync)-1] * 1/EMGfrequency;
                plot(time, refSync);
                plot(time, sync(:, 1) * gain1, 'r');
                if secondFile
                    plot(time, sync(:, 2) * gain2, 'g');
                end
                leg1 = ['sync1, delay=' ...
                    num2str(lagInSamplesA/EMGfrequency, 3) ...
                    's, gain=' num2str(gain1, 4) ...
                    ', mismatch(%)=' num2str(100*E1, 3)];
                leg2 = ['sync2, delay=' ...
                    num2str((lagInSamplesA+lagInSamples)/ ...
                    EMGfrequency, 3) 's, gain=' ...
                    num2str(gain2, 4) ', mismatch(%)=' ...
                    num2str(100*E2, 3)];
                legend('refSync', leg1, leg2);
                hold off;
                subplot(2, 2, 3);
                T = round(3 * EMGfrequency);    % 3 secs to plot
                if T < length(refSync)
                    hold on;
                    plot(time(1:T), refSync(1:T));
                    plot(time(1:T), sync(1:T, 1) * gain1, 'r');
                    if secondFile
                        plot(time(1:T), sync(1:T, 2) * gain2, 'g');
                    end
                    hold off;
                    subplot(2, 2, 4);
                    hold on;
                    plot(time(end-T:end), refSync(end-T:end));
                    plot(time(end-T:end), ...
                        sync(end-T:end, 1) * gain1, 'r');
                    if secondFile
                        plot(time(end-T:end), ...
                            sync(end-T:end, 2) * gain2, 'g');
                    end
                    hold off;
                end
                s = inputdlg( ...
                    ['If sync parameters between signals look ' ...
                    'fine and mismatch is below 5%, we ' ...
                    'recommend yes.'], ...
                    'Please confirm that you want to proceed (y/n).');
                switch s{1}
                    case {'y', 'Y', 'yes'}
                        disp(['Using signals in a possibly ' ...
                            'unsynchronized way!.']);
                        close(h);
                    case {'n', 'N', 'no'}
                        error( ...
                            'loadTrials:EMGCouldNotBeSynched', ...
                            ['Could not synchronize EMG data, ' ...
                            'stopping data loading.']);
                end
            end

            % Plot to visually confirm that alignment worked
            h = figure();
            subplot(2, 2, [1:2]);
            hold on;
            title(['Trial ' num2str(tr) ' Synchronization']);
            time = [0:length(refSync)-1] * 1/EMGfrequency;
            plot(time, refSync);
            plot(time, sync(:, 1) * gain1, 'r');
            leg1 = ['sync1, delay=' ...
                num2str(lagInSamplesA/EMGfrequency, 3) ...
                's, gain=' num2str(gain1, 4) ...
                ', mismatch(%)=' num2str(100*E1, 3)];
            if secondFile
                plot(time, sync(:, 2) * gain2, 'g');
                leg2 = ['sync2, delay=' ...
                    num2str((lagInSamplesA+lagInSamples)/ ...
                    EMGfrequency, 3) 's, gain=' ...
                    num2str(gain2, 4) ', mismatch(%)=' ...
                    num2str(100*E2, 3)];
                legend('refSync', leg1, leg2);
            else
                legend('refSync', leg1);
            end
            hold off;
            subplot(2, 2, 3);
            T = round(3 * EMGfrequency);    % 3 secs to plot
            if T < length(refSync)
                hold on;
                plot(time(1:T), refSync(1:T));
                plot(time(1:T), sync(1:T, 1) * gain1, 'r');
                if secondFile
                    plot(time(1:T), sync(1:T, 2) * gain2, 'g');
                end
                % legend('refSync',['sync1, delay=' ...
                %     num2str(lagInSamplesA/ ...
                %     analogsInfo.frequency,3) 's'], ...
                %     ['sync2, delay=' num2str((lagInSamplesA+ ...
                %     lagInSamples)/analogsInfo.frequency,3) 's'])
                hold off;
                subplot(2, 2, 4);
                hold on;
                plot(time(end-T:end), refSync(end-T:end));
                plot(time(end-T:end), ...
                    sync(end-T:end, 1) * gain1, 'r');
                if secondFile
                    plot(time(end-T:end), ...
                        sync(end-T:end, 2) * gain2, 'g');
                end
                % legend('refSync',['sync1, delay=' ...
                %     num2str(lagInSamplesA/ ...
                %     analogsInfo.frequency,3) 's'], ...
                %     ['sync2, delay=' num2str((lagInSamplesA+ ...
                %     lagInSamples)/analogsInfo.frequency,3) 's'])
                hold off;
            end
            saveFig(h, ...
                [fullfile(info.save_folder, 'EMGSyncFile') filesep], ...
                ['Trial ' num2str(tr) ' Synchronization']);
            %         uiwait(h)
        else
            warning('No sync signals were present, using data as-is.');
        end

        % Sort muscles into orderedEMGList order for consistent storage
        orderedIndexes = zeros(length(orderedEMGList), 1);
        for j = 1:length(orderedEMGList)
            for k = 1:length(EMGList)
                if strcmpi(orderedEMGList{j}, EMGList{k})
                    orderedIndexes(j) = k;
                    break;
                end
            end
        end
        % Remove entries for missing muscles
        orderedIndexes = orderedIndexes(orderedIndexes ~= 0);
        aux = zeros(length(EMGList), 1);
        aux(orderedIndexes) = 1;
        if any(aux == 0) && ~all(strcmpi(EMGList(aux == 0), 'sync'))
            warning(['loadTrials: Not all of the provided muscles ' ...
                'are in the ordered list, ignoring ' ...
                EMGList{aux == 0}]);
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
            idxList   = [];
            fieldList = fieldnames(analogs);
            for j = 1:length(fieldList)
                % Get fields that contain 'ACC' only
                if ~isempty(strfind(fieldList{j}, 'ACC'))
                    idxList(j) = str2num(fieldList{j}( ...
                        strfind(fieldList{j}, 'ACC')+4:end));
                    switch fieldList{j}( ...
                            strfind(fieldList{j}, 'ACC')+3)
                        case 'X',  aux = 1;
                        case 'Y',  aux = 2;
                        case 'Z',  aux = 3;
                    end
                    relData(:, idxList(j), aux) = ...
                        analogs.(fieldList{j});
                    % Remove field to save memory
                    analogs = rmfield(analogs, fieldList{j});
                end
            end
            relData = permute(relData(:, ~emptyChannels1, :), ...
                [1, 3, 2]);
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
            idxList2 = [];
            if secondFile
                fieldList = fieldnames(analogs2);
                for j = 1:length(fieldList)
                    % Get fields that contain 'ACC' only
                    if ~isempty(strfind(fieldList{j}, 'ACC'))
                        idxList2(j) = str2num(fieldList{j}( ...
                            strfind(fieldList{j}, 'ACC')+4:end));
                        switch fieldList{j}( ...
                                strfind(fieldList{j}, 'ACC')+3)
                            case 'X',  aux = 1;
                            case 'Y',  aux = 2;
                            case 'Z',  aux = 3;
                        end
                        relData2(:, idxList2(j), aux) = ...
                            analogs2.(fieldList{j});
                        % Remove field to save memory
                        analogs2 = rmfield(analogs2, fieldList{j});
                    end
                end
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
            end

            % Assign ACC channel name labels (no empty fields to drop)
            ACCList = {};
            for j = 1:length(EMGList)
                ACCList{end+1} = [EMGList{j} 'x'];
                ACCList{end+1} = [EMGList{j} 'y'];
                ACCList{end+1} = [EMGList{j} 'z'];
            end

            % Downsample to ~150 Hz (closer to original 148 Hz rate)
            % (where does this get upsampled? why?)
            accData = orientedLabTimeSeries( ...
                allData(1:13:end, :), 0, 13/EMGfrequency, ...
                ACCList, orientation);
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
            %     allData(1:13:end,:), 0, Samplingfrequency, ...
            %     ACCList, orientation);
        end
        clear allData* relData* auxData*;
    else
        EMGData = [];
        accData = [];
    end

    %% Add H-Reflex Stimulator Pin If Present
    relData      = [];
    stimLabels   = {};
    units        = {};
    fieldList    = fieldnames(analogs);
    stimLabelIdx = cellfun(@(x) ~isempty(x), ...
        regexp(fieldList, '^Stimulator_Trigger_Sync_'));
    stimLabelIdx = find(stimLabelIdx);
    if ~isempty(stimLabelIdx)       % if there is a stimulator pin, ...
        for j = 1:length(stimLabelIdx)
            stimLabels{end+1} = fieldList{stimLabelIdx(j)};
            units{end+1}      = ...
                analogsInfo.units.(fieldList{stimLabelIdx(j)});
            relData = [relData analogs.(fieldList{stimLabelIdx(j)})];
        end
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
                    [{['WARNING: the marker label ' ...
                    mustHaveLabels{j}]}, ...
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
                        ') was missing from the marker list. ' ...
                        'This will be problematic when computing ' ...
                        'parameters.']);
                else
                    % Map the chosen label to the required label
                    addMarkerPair(mustHaveLabels{j}, ...
                        potentialMatches{choice});
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

