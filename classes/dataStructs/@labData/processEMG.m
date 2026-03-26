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
    % Pre-allocate sparse quality matrix; sized for ~10% spikes total
    quality = sparse([], [], [],  size(emg.Data, 1), size(emg.Data, 2), ...
        round(0.1 * numel(emg.Data)));

    % ---- Step 0: Remove samples outside the [-5, 5] mV range --------
    % Included on March 12th because P0011 was presenting huge (1e5)
    % spikes obviously caused by data corruption. We may want to go back
    % and re-process from scratch, but it was only in a short time period
    % (~200 ms) so decided to clip, issue a warning, and add a new
    % quality category.

    % Flag samples exceeding the normal +-5 mV range; good EMG signals
    % rarely exceed +-2 mV, so this threshold catches loose sensors
    looseSensorMask = sparse(abs(emg.Data) >= 5e-3);
    badSampleFrac   = sum(looseSensorMask) ./ size(looseSensorMask, 1);
    highBadSampleChanMask = badSampleFrac > 0.01;
    if any(highBadSampleChanMask)   % > 1% bad samples: NOT GOOD
        disp('Channels with more than 1% bad samples (!):');
        for chan = find(highBadSampleChanMask)
            disp([emg.labels{chan} '(' ...
                num2str(round(badSampleFrac(chan) * 1000) / 10) '% bad)']);
            if abs(mean(emg.Data(:, chan), 'omitnan')) > 0.01
                warning(['Check raw data: non-zero signal offset ' ...
                    'detected for this channel. The channel mean ' ...
                    'will be subtracted to continue.']);
                emg.Data(:, chan) = emg.Data(:, chan) - ...
                    mean(emg.Data(:, chan), 'omitnan');
                % Re-check bad sample fraction after mean subtraction
                looseSensorMask   = sparse(abs(emg.Data) >= 5e-3);
                badSampleFrac     = sum(looseSensorMask) ./ ...
                    size(looseSensorMask, 1);
                highBadSampleChanMask = badSampleFrac > 0.01; %#ok<NASGU>
                disp([emg.labels{chan} '(' ...
                    num2str(round(badSampleFrac(chan) * 1000) / 10) ...
                    '% bad after mean adjustment)']);
            end
        end
        % error(['Some channels showed more than 1% bad samples, ' ...
        %     'that is NOT GOOD. Please review the data']);
    end
    if any(looseSensorMask, 'all')
        quality = 4 * looseSensorMask + quality;
        warning(['Found samples outside the normal range (+-5 mV). ' ...
            'Sensor may have been loose.']);
    end
    % Delsys claims the sensor range is +-5.5 mV, but samples up to
    % 5.9 mV do appear; clip anything at or beyond +-6 mV
    saturationMask = sparse(abs(emg.Data) >= 6e-3);
    if any(saturationMask, 'all')
        quality                   = 4 * saturationMask + quality;
        emg.Data(saturationMask)  = 0;
        warning(['Found samples outside the valid hardware range ' ...
            '(+-6 mV). Clipping affected samples.']);
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
        load('template.mat'); %#ok<LOAD>
        spikeThreshold = 0.95;  % cross-correlation threshold
        for chan = 1:length(emg.labels)
            whitenFlag = 0; % Not used until whitening is further tested
            [corrCoeff, templateMatchIdx, ~, ~] = ...
                findTemplate(template, emg.Data(:, chan), whitenFlag);
            threshExceededIdx = find(abs(corrCoeff) > spikeThreshold);
            if ~isempty(threshExceededIdx)
                % Discard consecutive events, keeping the first in each
                % sequence. Single-event sequences are discarded on
                % purpose (probably spurious).
                spikeStartIdx = threshExceededIdx( ...
                    diff(threshExceededIdx) == 1 & ...
                    diff(diff([-Inf; threshExceededIdx])) < 0);
                if numel(spikeStartIdx) > ...
                        round(0.01 * size(emg.Data, 1) / length(template))
                    warning(['Found spikes in more than 1% of total ' ...
                        'signal length. Probably not good.']);
                end
                templateMatchIdx = templateMatchIdx(spikeStartIdx); %#ok<NASGU>
            else
                spikeStartIdx = [];
            end
            for spike = 1:length(spikeStartIdx)
                % Set spike region to zero
                spikeEndIdx = min([spikeStartIdx(spike) + ...
                    length(template) - 1, size(emg.Data, 1)]);
                quality(spikeStartIdx(spike):spikeEndIdx, chan) = 2;
                emg.Data(spikeStartIdx(spike):spikeEndIdx, chan) = 0;
            end
        end
    end

    % ---- Step 2: Extract amplitude envelope ----------------------------
    fCut = 10;  % Hz
    [procEMG, filteredEMG, filterList, procList] = ...
        extractMuscleActivityFromEMG(emg.Data, emg.sampFreq, fCut);

    % ---- Step 3: Create processedEMGTimeSeries objects -----------------
    procInfo    = processingInfo([filterList, procList]);
    procEMGData = processedEMGTimeSeries(procEMG, emg.Time(1), ...
        emg.sampPeriod, emg.labels, procInfo);
    procInfo        = processingInfo(filterList);
    filteredEMGData = processedEMGTimeSeries(filteredEMG, emg.Time(1), ...
        emg.sampPeriod, emg.labels, procInfo);

    % ---- Step 4: Update quality info, incorporating pre-existing -------
    if ~isempty(emg.Quality)    % if pre-existing quality info exists, ...
        filteredEMGData.Quality               = emg.Quality;
        filteredEMGData.Quality(quality == 2) = 2;
        filteredEMGData.Quality(quality == 3) = 4;
        filteredEMGData.Quality(quality == 3) = 8;
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

