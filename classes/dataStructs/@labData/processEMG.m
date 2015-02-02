function procEMGData = processEMG(trialData)

emg=trialData.EMGData;
if ~isempty(emg)
    %Step 1: interpolate missing samples
    emg=emg.fillts;
    
    if any(isnan(emg.Data(:)))
        a=1; %FIXME!
    end
    %Step 2: do amplitude extraction
    f_cut=10; %Hz
    [procEMG,f_cut,BW,notchList] = extractMuscleActivityFromEMG(emg.Data,emg.sampFreq,f_cut);
    
    %Step 3: create processedEMGTimeSeries object
    procInfo=processingInfo(BW,f_cut,notchList);
    procEMGData=processedEMGTimeSeries(procEMG,emg.Time(1),emg.sampPeriod,emg.labels,procInfo);
    w=warning('off','labTS:resample');
    %procEMGData=procEMGData.resample(1.2/(2*f_cut)); %Resample with 20% margin to avoid aliasing
    w=warning('on','labTS:resample');
else
    procEMGData=[];
end