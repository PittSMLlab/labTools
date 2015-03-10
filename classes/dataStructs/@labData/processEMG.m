 function [procEMGData,filteredEMGData] = processEMG(trialData,spikeFlag)

emg=trialData.EMGData;
if ~isempty(emg)
    %Step 1: interpolate missing samples
    emg=emg.substituteNaNs('linear');
    
    if any(isnan(emg.Data(:)))
        error('processEMG:isNaN','Some samples in the EMG data are NaN, the filters will fail'); %FIXME!
    end
	
	%Step 1.5: Find spikes and remove them by setting them to 0
    %load('../matData/subP0001.mat')
    %template=expData.data{1}.EMGData.getPartialDataAsVector('LGLU',235.695,235.755);
    quality=sparse([],[],[],size(emg.Data,1),size(emg.Data,2),round(.01*numel(emg.Data)));%Pre-allocating for 1% spikes total.
    if nargin>1 && ~isempty(spikeFlag) && spikeFlag==1
        spikeFlag %This is just for testing
        load('template.mat');
        for j=1:length(emg.labels)
            whitenFlag=0; %Not used until the whitening mechanism is further tested
            [c,k,~,~] = findTemplate(template,emg.Data(:,j),whitenFlag);
            beta=.95; %Define threshold
            t=find(abs(c)>beta);
            if ~isempty(t)
            t_=t(diff(t)==1 & diff(diff([-Inf;t]))<0); %Discarding consecutive events, keeping the first in each sequence. If sequence consists of a single event, it is DISCARDED (on purpose, as it is probably spurious).
            k=k(t_);
            else
                t_=[];
            end
            for i=1:length(t_)
                %Setting to 0s
                quality(t_(i):t_(i)+length(template)-1,j)=2;
                emg.Data(t_(i):t_(i)+length(template)-1,j)=0;
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
        filteredEMGData.QualityInfo.Code=[emg.QualityInfo.Code 2];
        filteredEMGData.QualityInfo.Description=[emg.QualityInfo.Description, 'spike'];
    else
        filteredEMGData.Quality=int8(quality); %Need to cast as int8 because Matlab's timeseries forces this for the quality property
        filteredEMGData.QualityInfo.Code=[0 2];
        filteredEMGData.QualityInfo.Description={'good', 'spike'};
    end
    procEMGData.Quality= filteredEMGData.Quality;
    procEMGData.QualityInfo=filteredEMGData.QualityInfo;
    
else %Case of empty emg data
    procEMGData=[];
    filteredEMGData = [];
end
