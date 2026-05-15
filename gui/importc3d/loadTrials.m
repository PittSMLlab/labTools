function trials = loadTrials(trialMD, fileList, secFileList, info)
% loadTrials  Generates rawTrialData instances for each trial.
%
%   Reads kinematic, force, and EMG data from C3D files for each trial
% in the experimental session. For each trial, the function imports
% analog and marker data via the Biomechanics Toolkit (BTK), delegates
% ground reaction force processing to processGRFData, synchronizes and
% sorts EMG channels via syncEMGData, processes accelerometer data, and
% packages everything into a rawTrialData object.
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
%     BTK - Biomechanics Toolkit     (btkReadAcquisition, btkGetAnalogs,
%                                     btkGetMarkers; external dependency)
%
%   See also: rawTrialData, loadSubject, getTrialMetaData,
%   syncEMGData, processGRFData

arguments
    trialMD     cell
    fileList    cell
    secFileList cell
    info        (1,1) struct
end

% -----------------------------------------------------------------------
%  Named constants — centralised here for easy tuning
% -----------------------------------------------------------------------

% Integer downsampling factor applied to accelerometer data;
% reduces the native EMG-system rate to approximately 150 Hz
accDownsampleFactor = 13;

% Maximum fractional deviation from an integer ratio when checking
% that two PC sampling rates are exact multiples of one another
rateRatioTolerance = 1e-7;

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
for jj = 1:length(orderedMuscleList)
    orderedEMGList{end+1} = ['R' orderedMuscleList{jj}];
    orderedEMGList{end+1} = ['L' orderedMuscleList{jj}];
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
        accDownsampleFactor rateRatioTolerance;

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
    [GRFData, analogs] = processGRFData(analogs, analogsInfo, info, tr);

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

        if ~exist('relData2', 'var')
            relData2 = [];
        end
        [allData, sync, lagInSamplesA, lagInSamples, ...
            timeScaleFactor] = syncEMGData( ...
            relData, relData2, refSync, EMGList, EMGfrequency, ...
            secondFile, tr, info.save_folder);

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
        isSync    = cellfun( ...
            @(x) ~isempty(regexpi(x, '^sync', 'once')), EMGList(~inOrdered));
        if any(~inOrdered) && ~all(isSync)
            ignoredLabels = strjoin(EMGList(~inOrdered & ~isSync), ', ');
            warning(['loadTrials: Some provided EMG channels are not ' ...
                'in the ordered list and will be ignored: ' ignoredLabels]);
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
            for jj = 1:length(accFields)
                accPos = strfind(accFields{jj}, 'ACC');
                chIdx  = str2double(accFields{jj}(accPos+4:end));
                switch accFields{jj}(accPos+3)
                    case 'X',  axIdx = 1;
                    case 'Y',  axIdx = 2;
                    case 'Z',  axIdx = 3;
                end
                relData(:, chIdx, axIdx) = analogs.(accFields{jj});
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
                for jj = 1:length(accFields2)
                    accPos = strfind(accFields2{jj}, 'ACC');
                    chIdx  = str2double(accFields2{jj}(accPos+4:end));
                    switch accFields2{jj}(accPos+3)
                        case 'X',  axIdx = 1;
                        case 'Y',  axIdx = 2;
                        case 'Z',  axIdx = 3;
                    end
                    relData2(:, chIdx, axIdx) = analogs2.(accFields2{jj});
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
            for jj = 1:length(EMGList)
                ACCList{end+1} = [EMGList{jj} 'x'];
                ACCList{end+1} = [EMGList{jj} 'y'];
                ACCList{end+1} = [EMGList{jj} 'z'];
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
        for ii = 1:length(fieldList)
            newFieldList{ii} = findLabel(fieldList{ii});
            labelPresent     = labelPresent + ...
                ismember(mustHaveLabels, newFieldList{ii});
        end

        % If any required labels are missing, terminate with error
        % if any(~labelPresent)
        %     missingLabels = find(~labelPresent);
        %     str = ' ';
        %     for jj = missingLabels
        %         str = [str ', ' mustHaveLabels{jj}];
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
            for jj = missingLabels
                choice = menu( ...
                    [{['WARNING: the marker label ' mustHaveLabels{jj}]},...
                    {' was not found, but is necessary for'}, ...
                    {'future calculations. Please indicate which'}, ...
                    {[' marker corresponds to the ' ...
                    mustHaveLabels{jj} ' label:']}], ...
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
                        ['A required marker (' mustHaveLabels{jj} ...
                        ') was missing from the marker list. This ' ...
                        'will be problematic when computing ' ...
                        'parameters.']);
                else
                    % Map the chosen label to the required label
                    addMarkerPair( ...
                        mustHaveLabels{jj}, potentialMatches{choice});
                end
            end
        end

        for jj = 1:length(fieldList)
            % Skip unlabeled markers (Vicon 'C_' prefix)
            if length(fieldList{jj}) > 2 && ...
                    ~strcmp(fieldList{jj}(1:2), 'C_')
                relData = [relData, markers.(fieldList{jj})];
                % Standardize marker name via findLabel
                markerLabel       = findLabel(fieldList{jj});
                markerList{end+1} = [markerLabel 'x'];
                markerList{end+1} = [markerLabel 'y'];
                markerList{end+1} = [markerLabel 'z'];
            end
            % Remove processed marker to save memory
            markers = rmfield(markers, fieldList{jj});
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


