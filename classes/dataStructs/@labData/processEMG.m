function [procEMGData,filteredEMGData] = processEMG(trialData,spikeFlag)
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

            if abs(nanmean(emg.Data(:,i)))>0.01
                warning('Check raw data. non-zero Signal offset. To continue, mean value will be remove mean of the dataß')
                emg.Data(:,i)=emg.Data(:,i)-nanmean(emg.Data(:,i));
    % ---- Step 0: Remove samples outside the [-5, 5] mV range --------
    % Included on March 12th because P0011 was presenting huge (1e5)
    % spikes obviously caused by data corruption. We may want to go back
    % and re-process from scratch, but it was only in a short time period
    % (~200 ms) so decided to clip, issue a warning, and add a new
    % quality category.

    % Set +-5 mV as normal range (good EMG signals rarely exceed 2 mV)
    aaux       = sparse(abs(emg.Data) >= 5e-3);
    badSamples = sum(aaux) ./ size(aaux, 1);
    tt         = badSamples > 0.01;
    if any(tt)      % more than 1% bad samples on a channel: NOT GOOD
        disp('Channels with more than 1% bad samples (!):');
        for i = find(tt)
            disp([emg.labels{i} '(' ...
                num2str(round(badSamples(i) * 1000) / 10) '% bad)']);
                % Set +-5 mV as normal range
                aaux2       = sparse(abs(emg.Data) >= 5e-3);
                badSamples2 = sum(aaux2) ./ size(aaux2, 1);
                tt2         = badSamples2 > 0.01; %#ok<NASGU>
                disp([emg.labels{i} '(' ...
                    num2str(round(badSamples2(i) * 1000) / 10) ...
                    '% bad after mean adjustment)']);
            end
        end
        % error(['Some channels showed more than 1% bad samples, ' ...
        %     'that is NOT GOOD. Please review the data']);
    end

    if any(any(aaux))
        quality = 4 * aaux + quality;
        warning(['Found samples outside the normal range ' ...
            '(+-5e-3 mV), sensor  was probably loose.']);
    end
    % Delsys says sensor range is +-5.5 mV, but samples up to 5.9 mV appear
    aaux = sparse(abs(emg.Data) >= 6e-3);
    if any(any(aaux))
        quality        = 4 * aaux + quality;
        emg.Data(aaux) = 0;
        warning(['Found samples outside the valid range ' ...
            '(+-6e-3 mV). Clipping.']);
    end

    % ---- Step 1: Interpolate missing samples ---------------------------
    emg = emg.substituteNaNs('linear');

    if any(isnan(emg.Data(:)))
        error('processEMG:isNaN', ['Some samples in the EMG data are ' ...
            'NaN, the filters will fail']); % FIXME!
    end

    % ---- Step 1.5: Find spikes and remove by setting them to zero ------
    % load('../matData/subP0001.mat')
    % template = expData.data{1}.EMGData.getPartialDataAsVector( ...
    %     'LGLU', 235.695, 235.755);

    if nargin>1 && ~isempty(spikeFlag) && spikeFlag==1
        load('template.mat');
        for j=1:length(emg.labels)
            whitenFlag=0; %Not used until the whitening mechanism is further tested
            [c,k,~,~] = findTemplate(template,emg.Data(:,j),whitenFlag);
            beta=.95; %Define threshold
            t=find(abs(c)>beta);
            if ~isempty(t)
                t_=t(diff(t)==1 & diff(diff([-Inf;t]))<0); %Discarding consecutive events, keeping the first in each sequence. If sequence consists of a single event, it is DISCARDED (on purpose, as it is probably spurious).
                if numel(t_)>round(.01*size(emg.Data,1)/length(template))
                    warning('Found spikes in more than 1% total signal length. Probably not good.')
                end
                k=k(t_);
            else
                t_=[];
            end
            for i=1:length(t_)
                %Setting to 0s
                t2=min([t_(i)+length(template)-1,size(emg.Data,1)]);
                quality(t_(i):t2,j)=2;
                emg.Data(t_(i):t2,j)=0;
            end
        end
    end

    %Step 2: do amplitude extraction
    f_cut=10; %Hz
    [procEMG,filteredEMG,filterList,procList] = extractMuscleActivityFromEMG(emg.Data,emg.sampFreq,f_cut);

    %Step 3: create processedEMGTimeSeries object
    procInfo=processingInfo([filterList, procList]);
    procEMGData=processedEMGTimeSeries(procEMG,emg.Time(1),emg.sampPeriod,emg.labels,procInfo);
    procInfo=processingInfo(filterList);
    filteredEMGData=processedEMGTimeSeries(filteredEMG,emg.Time(1),emg.sampPeriod,emg.labels,procInfo);

    %Step 4: update quality info on timeseries, incorporating previously
    %existing quality info
    if ~isempty(emg.Quality) %Case where there was pre-existing quality info
        filteredEMGData.Quality=emg.Quality;
        filteredEMGData.Quality(quality==2)=2;
        filteredEMGData.Quality(quality==3)=4;
        filteredEMGData.Quality(quality==3)=8;
        filteredEMGData.QualityInfo.Code=[emg.QualityInfo.Code 2 4 8];
        filteredEMGData.QualityInfo.Description=[emg.QualityInfo.Description, 'spike', 'sensorLoose' ,'outsideValidRange'];
    else
        filteredEMGData.Quality=int8(quality); %Need to cast as int8 because Matlab's timeseries forces this for the quality property
        filteredEMGData.QualityInfo.Code=[0 2 4 8];
        filteredEMGData.QualityInfo.Description={'good', 'spike', 'sensorLoose','outsideValidRange'};
    end
    procEMGData.Quality= filteredEMGData.Quality;
    procEMGData.QualityInfo=filteredEMGData.QualityInfo;

else %Case of empty emg data
    procEMGData=[];
    filteredEMGData = [];
end

end

