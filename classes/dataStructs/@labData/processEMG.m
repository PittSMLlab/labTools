function [procEMGData, filteredEMGData] = processEMG(trialData, spikeFlag)
% processEMG  Extracts processed and filtered EMG amplitude envelopes
%   from raw trial EMG data.
%
%   Performs quality checks, outlier clipping, optional template-based
% spike removal, NaN interpolation, and bandpass/envelope amplitude
% extraction on the EMG time series in trialData. Returns both a
% filtered envelope and a fully processed (smoothed) envelope.
%
%   If the EMG data already has a processingInfo property, the function
% returns the existing processed data unchanged to avoid over-smoothing.
% To re-process, retrieve the original raw EMG before calling.
%
%   Inputs:
%     trialData - labData object whose EMGData property contains the
%                 raw EMG time series to process
%     spikeFlag - (optional) Logical flag to enable template-based spike
%                 removal. Default: false
%
%   Outputs:
%     procEMGData     - processedEMGTimeSeries with fully processed
%                       amplitude envelope
%     filteredEMGData - processedEMGTimeSeries with filtered (not fully
%                       smoothed) EMG data
%
%   Toolbox Dependencies:
%     Signal Processing Toolbox  (used in extractMuscleActivityFromEMG)
%
%   See also: extractMuscleActivityFromEMG, processedEMGTimeSeries,
%     processingInfo, labData/process

arguments
    trialData  (1,1) labData
    spikeFlag  (1,1) logical = false
end

%% Named Constants
% EMG amplitude thresholds (V).
% Note: Delsys claims a +-5.5 mV max sensor range, but values up to
% 5.9 mV can appear, so the hardware limit is set conservatively at 6 mV.
normalRangeLimit   = 5e-3;  % samples >= this indicate a loose sensor
hardwareRangeLimit = 6e-3;  % samples >= this exceed the hardware range

% Fraction of samples per channel above normalRangeLimit that triggers
% a bad-sample report to the command window
badSampleFracThreshold = 0.01;  % 1%

% Signal mean magnitude above which mean subtraction is applied when a
% channel shows a non-zero DC offset
meanOffsetThreshold = 0.01;     % V

% Low-pass cutoff frequency (Hz) for EMG amplitude envelope extraction
envelopeCutoffFreq = 10;

% Cross-correlation threshold for template-based spike detection
spikeCorrelThreshold = 0.95;

% Whitening flag for template matching (disabled until further tested)
spikeWhitenFlag = false;

% Fraction of total signal length above which the detected spike count
% triggers a warning
spikeHighFracThreshold = 0.01;  % 1%

% Estimated fraction of non-zero entries for sparse quality matrix
% pre-allocation (conservative upper bound)
qualitySparseDensity = 0.1;

% Full path to EMG spike template file; resolved via the MATLAB path so the
% location is explicit without hardcoding a user-specific absolute path
templateFilePath = which('template.mat');

%% Process EMG Data
emg = trialData.EMGData;
if isprop(emg, 'processingInfo')
    warning(['Trying to re-process already processed EMG data, ' ...
        'this can lead to over-smoothing. Skipping.']);
    filteredEMGData = emg;
    procEMGData     = trialData.procEMGData;
    return;
    % If you really want to re-process EMG data, you should use RAW EMG!
end

if ~isempty(emg)
    % Quality matrix internal encoding used throughout this function:
    %   0 (not set) - good sample
    %   2           - spike (detected by template matching)
    %   3           - loose sensor (|data| in [5, 6) mV)
    %   4           - outside hardware range (|data| >= 6 mV, clipped)
    % In Step 4 these values are mapped to final QualityInfo codes:
    %   quality 3 -> code 4 (sensorLoose)
    %   quality 4 -> code 8 (outsideValidRange)
    quality = sparse([], [], [], size(emg.Data, 1), size(emg.Data, 2), ...
        round(qualitySparseDensity * numel(emg.Data)));

    % ---- Step 0: Flag and handle samples outside expected ranges -------
    % Included March 12th: P0011 had huge (1e5) spikes from data
    % corruption. Only ~200 ms were affected, so clipping was preferred
    % over reprocessing from scratch.

    % Compute fraction of samples above normalRangeLimit per channel
    badSampleFrac         = mean(abs(emg.Data) >= normalRangeLimit, 1);
    highBadSampleChanMask = badSampleFrac > badSampleFracThreshold;

    if any(highBadSampleChanMask)
        disp('Channels with more than 1% bad samples (!):');
        for chan = find(highBadSampleChanMask)
            fprintf('  %s (%.1f%% bad)\n', emg.labels{chan}, ...
                badSampleFrac(chan) * 100);
            if abs(mean(emg.Data(:,chan), 'omitnan')) > meanOffsetThreshold
                warning(['Check raw data: non-zero signal offset ' ...
                    'detected. The channel mean will be subtracted ' ...
                    'to continue.']);
                emg.Data(:, chan) = emg.Data(:, chan) - ...
                    mean(emg.Data(:, chan), 'omitnan');
                % Re-check this channel only after mean subtraction;
                % scoped to avoid a full recompute across all channels
                badSampleFrac(chan) = mean( ...
                    abs(emg.Data(:, chan)) >= normalRangeLimit);
                fprintf('  %s (%.1f%% bad after mean adjustment)\n', ...
                    emg.labels{chan}, badSampleFrac(chan) * 100);
            end
        end
        % error(['Some channels showed more than 1% bad samples, ' ...
        %     'that is NOT GOOD. Please review the data']);
    end

    % Build mutually exclusive quality masks after any mean corrections
    % so that they reflect the corrected data.
    % 'looseSensorOnlyMask' covers [normalRangeLimit, hardwareRangeLimit)
    % and maps to quality value 3; 'saturationMask' covers
    % [hardwareRangeLimit, Inf) and maps to quality value 4.
    looseSensorOnlyMask = sparse(abs(emg.Data) >= normalRangeLimit & ...
        abs(emg.Data) <  hardwareRangeLimit);
    saturationMask = sparse(abs(emg.Data) >= hardwareRangeLimit);

    if any(looseSensorOnlyMask, 'all')
        quality = 3 * looseSensorOnlyMask + quality;
        warning(['Found samples outside the normal range (+-%.0f mV). ' ...
            'Sensor may have been loose.'], normalRangeLimit * 1e3);
    end

    % Delsys claims +-5.5 mV max; samples up to 5.9 mV do appear.
    % Clip samples at or above hardwareRangeLimit and mark as saturated.
    if any(saturationMask, 'all')
        quality                  = 4 * saturationMask + quality;
        emg.Data(saturationMask) = 0;
        warning(['Found samples outside the hardware range (+-%.0f mV).'...
            ' Clipping affected samples.'], hardwareRangeLimit * 1e3);
    end

    % ---- Step 1: Interpolate missing samples ---------------------------
    emg = emg.substituteNaNs('linear');

    if any(isnan(emg.Data), 'all')
        error('processEMG:isNaN', ['Some samples in the EMG data are ' ...
            'NaN, the filters will fail']); % FIXME!
    end

    % ---- Step 1.5: Find spikes and remove by setting them to zero ------
    % load('../matData/subP0001.mat')
    % template = expData.data{1}.EMGData.getPartialDataAsVector( ...
    %     'LGLU', 235.695, 235.755);
    if spikeFlag
        load(templateFilePath, 'template');

        % Accumulate all spike row and column indices across channels for
        % a single bulk quality update after the loop; this avoids the
        % slow sparse range-assignment warning that results from indexing
        % into a sparse matrix with a colon range inside an inner loop
        spikeRowIdx = [];
        spikeColIdx = [];
        for chan = 1:length(emg.labels)
            [corrCoeff, templateMatchIdx, ~, ~] = findTemplate( ...
                template, emg.Data(:, chan), spikeWhitenFlag);
            threshExceededIdx = ...
                find(abs(corrCoeff) > spikeCorrelThreshold);
            if ~isempty(threshExceededIdx)
                % Keep only the first event in each consecutive run;
                % isolated single-sample events are discarded as spurious
                spikeStartIdx = threshExceededIdx( ...
                    diff(threshExceededIdx) == 1 & ...
                    diff(diff([-Inf; threshExceededIdx])) < 0);
                if numel(spikeStartIdx) > round(spikeHighFracThreshold *...
                        size(emg.Data, 1) / length(template))
                    warning(['Found spikes in more than 1% of ' ...
                        'total signal length. Probably not good.']);
                end
                templateMatchIdx = ...
                    templateMatchIdx(spikeStartIdx); %#ok<NASGU>
            else
                spikeStartIdx = [];
            end
            for spike = 1:length(spikeStartIdx)
                % Set spike region to zero
                spikeEndIdx = min([spikeStartIdx(spike) + ...
                    length(template) - 1, size(emg.Data, 1)]);
                newRows = (spikeStartIdx(spike):spikeEndIdx)';
                spikeRowIdx = [spikeRowIdx; newRows]; %#ok<AGROW>
                spikeColIdx = [spikeColIdx; ...
                    repmat(chan, length(newRows), 1)]; %#ok<AGROW>
                emg.Data(spikeStartIdx(spike):spikeEndIdx, chan) = 0;
            end
        end

        % Update quality matrix for all spike samples in one operation
        if ~isempty(spikeRowIdx)
            quality = quality + sparse(spikeRowIdx, spikeColIdx, 2, ...
                size(quality, 1), size(quality, 2));
        end
    end

    % ---- Step 2: Extract amplitude envelope ----------------------------
    [procEMG, filteredEMG, filterList, procList] = ...
        extractMuscleActivityFromEMG( ...
        emg.Data, emg.sampFreq, envelopeCutoffFreq);

    % ---- Step 3: Create processedEMGTimeSeries objects -----------------
    procInfo    = processingInfo([filterList, procList]);
    procEMGData = processedEMGTimeSeries( ...
        procEMG, emg.Time(1), emg.sampPeriod, emg.labels, procInfo);
    procInfo        = processingInfo(filterList);
    filteredEMGData = processedEMGTimeSeries( ...
        filteredEMG, emg.Time(1), emg.sampPeriod, emg.labels, procInfo);

    % ---- Step 4: Update quality info, incorporating pre-existing -------
    if ~isempty(emg.Quality)    % if pre-existing quality info exists, ...
        filteredEMGData.Quality               = emg.Quality;
        filteredEMGData.Quality(quality == 2) = 2;  % spike
        filteredEMGData.Quality(quality == 3) = 4;  % sensorLoose
        filteredEMGData.Quality(quality == 4) = 8;  % outsideValidRange
        filteredEMGData.QualityInfo.Code = [emg.QualityInfo.Code 2 4 8];
        filteredEMGData.QualityInfo.Description = ...
            [emg.QualityInfo.Description, ...
            'spike', 'sensorLoose', 'outsideValidRange'];
    else
        % Cast as int8: MATLAB's timeseries enforces this type for
        % the Quality property
        filteredEMGData.Quality             = int8(quality);
        filteredEMGData.QualityInfo.Code    = [0 2 4 8];
        filteredEMGData.QualityInfo.Description = ...
            {'good', 'spike', 'sensorLoose', 'outsideValidRange'};
    end
    procEMGData.Quality     = filteredEMGData.Quality;
    procEMGData.QualityInfo = filteredEMGData.QualityInfo;

else    % if EMG data is empty, return empty outputs
    procEMGData     = [];
    filteredEMGData = [];
end

end

