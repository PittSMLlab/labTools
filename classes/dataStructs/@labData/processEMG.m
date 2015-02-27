function [procEMGData,filteredEMGData] = processEMG(trialData)

emg=trialData.EMGData;
if ~isempty(emg)
    %Step 1: interpolate missing samples
    emg=emg.substituteNaNs('linear');
    
    if any(isnan(emg.Data(:)))
        error('processEMG:isNaN','Some samples in the EMG data are NaN, the filters will fail'); %FIXME!
    end
    %Step 2: do amplitude extraction
    f_cut=10; %Hz
    [procEMG,filteredEMG,filterList,procList] = extractMuscleActivityFromEMG(emg.Data,emg.sampFreq,f_cut);
    
    %Step 3: create processedEMGTimeSeries object
    procInfo=processingInfo([filterList, procList]);
    procEMGData=processedEMGTimeSeries(procEMG,emg.Time(1),emg.sampPeriod,emg.labels,procInfo);
    procInfo=processingInfo(filterList);
    filteredEMGData=processedEMGTimeSeries(filteredEMG,emg.Time(1),emg.sampPeriod,emg.labels,procInfo);
    %w=warning('off','labTS:resample');
    %procEMGData=procEMGData.resample(1.2/(2*f_cut)); %Resample with 20% margin to avoid aliasing
    %w=warning('on','labTS:resample');
else
    procEMGData=[];
    filteredEMGData = [];
end
