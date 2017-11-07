 function [procEMGData,filteredEMGData] = processEMG(trialData,spikeFlag)

emg=trialData.EMGData;
if isprop(emg,'processingInfo')
    warning('Trying to re-process already processed EMG data, this can lead to over-smoothing. Skipping.')
    filteredEMGData=emg;
    procEMGData=trialData.procEMGData;
    return
    %If you really want to re-process EMG data, you should get the RAW EMG!
end

if ~isempty(emg)
    quality=sparse([],[],[],size(emg.Data,1),size(emg.Data,2),round(.01*numel(emg.Data)));%Pre-allocating for 1% spikes total.
    
    %Step 0: remove samples outside the [-5,5]e-3 range (+- 5mv): this was
    %included on March 12th because P0011 was presenting huge (1e5) spikes
    %that are obviously caused by some data corruption. We may want to go
    %back and re-process from scratch, but it was only in a short time
    %period (~200ms) so decided to clip, issue warning, and add new quality
    %category.
    aaux=abs(emg.Data)>=5e-3; %Set +-5mV as normal range, although good EMG signals rarely go above 2mV
    if any(any(aaux))
        quality(aaux)=4;
        warning(['Found samples outside the normal range (+-5e-3), sensor '  ' was probably loose.'])
    end
    aaux=abs(emg.Data)>=6e-3; %Delsys claims the sensor range is +-5.5mV, but samples up to 5.9mV do appear
    if any(any(aaux))
        quality(aaux)=8;
        emg.Data(aaux)=0;
        warning('Found samples outside the valid range (+-6e-3). Clipping.')
    end
    
    
    %Step 1: interpolate missing samples
    emg=emg.substituteNaNs('linear');
    
    if any(isnan(emg.Data(:)))
        error('processEMG:isNaN','Some samples in the EMG data are NaN, the filters will fail'); %FIXME!
    end
	
    
    %Step 1.5: Find spikes and remove them by setting them to 0
    %load('../matData/subP0001.mat')
    %template=expData.data{1}.EMGData.getPartialDataAsVector('LGLU',235.695,235.755);

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
