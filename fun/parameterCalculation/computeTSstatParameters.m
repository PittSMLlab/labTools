function [out] = computeTSstatParameters(someTS,arrayedEvents)
%This function computes summary parameters per stride based on labTS data.
%The output is a parameterSeries object, which can be concatenated with
%other parameterSeries objects, for example with those from
%computeTemporalParameters. 
%See also computeSpatialParameters, computeTemporalParameters,
%computeForceParameters, parameterSeries

%% Parameter list and description (per muscle!)
labelSuff={'max','min','avg','var','med','snr','bad'}; %Some stats on channel data, excluded 'skw','kur','iqr' because they are never used and take long to compute
%%
slicedTS=someTS.sliceTS(arrayedEvents(:,1),0); %Slicing by first event ONLY
N=length(slicedTS);
Nl=length(labelSuff);
labs=someTS.labels;
paramData=nan(N,length(labs),Nl);
paramLabels=cell(length(labs),Nl);
description=cell(length(labs),Nl);
%Define parameter names and descriptions:
for j=1:length(labs) %Muscles
     for k=1:Nl
        if strcmp(labelSuff{k},'bad')
            paramLabels{j,k}=[labs{j} labelSuff{k}];
            description{j,k}=['Signals if quality was anything other than good (no missing, no spikes, no out-of-range) for muscle ' labs{j}];
        else
            paramLabels{j,k}=[labs{j} labelSuff{k}];
            description{j,k}=[labelSuff{k} ' in timeseries ' labs{j}];
        end
     end
end

for i=1:N %For each stride
    Data=slicedTS{i}.Data;
    Qual=slicedTS{i}.Quality;
    for j=1:length(labs) %Muscles
        mData=Data(:,j);
        if ~isempty(Qual)
            qq=Qual(:,j);
        else
            qq=0;
        end
        for k=1:Nl %Computing each param
            switch labelSuff{k}
                case 'max'
                    %description{j,k}=['Peak proc EMG in muscle ' labs{j}];
                    paramData(i,j,k)=max(mData);
                case 'min'
                    %description{j,k}=['Min proc EMG in muscle ' labs{j}];
                    paramData(i,j,k)=min(mData);
                case 'iqr'
                    %description{j,k}=['Inter-quartile range of proc EMG in muscle ' labs{j}];
                    paramData(i,j,k)=iqr(mData);
                case 'avg'
                    %description{j,k}=['Avg. (mean) of proc EMG in muscle ' labs{j}];
                    paramData(i,j,k)=mean(mData);
                case 'var'
                    %description{j,k}=['Variance of proc EMG in muscle ' labs{j}];
                    paramData(i,j,k)=var(mData,0); %Unbiased
                case 'skw'
                    %description{j,k}=['Skewness of proc EMG in muscle ' labs{j}];
                    paramData(i,j,k)=skewness(mData,0); %Unbiased
                case 'kur'
                    %description{j,k}=['Kurtosis of proc EMG in muscle ' labs{j}];
                    paramData(i,j,k)=kurtosis(mData,0); %Unbiased
                case 'med'
                    %description{j,k}=['Median of proc EMG in muscle ' labs{j}];
                    paramData(i,j,k)=median(mData);
                case 'snr'
                    %description{j,k}=['Energy of proc EMG divided by base noise energy (in dB) for muscle ' labs{j}];
                    paramData(i,j,k)=20*log10(mean(mData.^2)/min(mData)^2); %Is this a good estimate?? Seems like min() will always be very close to zero because of the low-pass filtering and the 'dip' it introduces
                case 'bad'
                    paramData(i,j,k)=sum(unique(qq)); %Quality codes used are powers of 2, which allows for 8 different codes (int8). Sum of unique appearances allows to keep track of all codes at the same time.
            end
        end
    end
end
%% Create parameterSeries
out=parameterSeries(paramData(:,:),paramLabels(:),[],description(:));        
end

