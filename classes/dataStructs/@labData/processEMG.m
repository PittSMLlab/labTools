function procEMGData = processEMG(trialData)

emg=trialData.EMGData;
if ~isempty(emg)
    f_cut=10; %Hz
    [procEMG,f_cut,BW,notchList] = extractMuscleActivityFromEMG(emg.Data,emg.sampFreq,f_cut);
    procInfo=processingInfo(BW,f_cut,notchList);
    procEMGData=processedEMGTimeSeries(procEMG,emg.Time(1),emg.sampPeriod,emg.labels,procInfo);
    w=warning('off','labTS:resample');
    %procEMGData=procEMGData.resample(1.2/(2*f_cut)); %Resample with 20% margin to avoid aliasing
    w=warning('on','labTS:resample');
else
    procEMGData=[];
end