function [out] = computeEMGParameters(strideEvents,stridedProcEMG)
%%
timeSHS=strideEvents.tSHS;
timeFTO=strideEvents.tFTO;
timeFHS=strideEvents.tFHS;
timeSTO=strideEvents.tSTO;
timeSHS2=strideEvents.tSHS2;
eventTimes=[timeSHS timeFTO .5*(timeFTO+timeFHS) timeFHS timeSTO .5*(timeSTO+timeSHS2) timeSHS2];
paramLabels={};
description={};
phases={'DS1','EfSwing','LfSwing','DS2','EsSwing','LsSwing'};
desc={'SHS to FTO', 'FTO to mid fast swing', 'mid fast swing to FHS', 'FHS to STO', 'STO to mid slow swing', 'mid slow swing to SHS'};
%%
N=length(stridedProcEMG);
data=nan(N,30*16);
for i=1:N
    counter=0;
    Time=stridedProcEMG{i}.Time;
    labs=stridedProcEMG{i}.labels;
    Data=stridedProcEMG{i}.Data;
    Qual=stridedProcEMG{i}.Quality;
    for j=1:length(labs) %Muscles
        for k=1:6 %6 phases
            counter=counter+1;
            if i==1
            paramLabels{counter}=[labs{j} 'p' num2str(k)];
            description{counter}=['Average of proc EMG data in muscle ' labs{j} ' from ' desc{k}];
            end
            data(i,counter)=mean(Data(Time<=eventTimes(i,k+1) & Time>=eventTimes(i,k),j));
            if ~isempty(Qual) & any(Qual(Time<=eventTimes(i,k+1) & Time>=eventTimes(i,k),j)~=0) %Quality points to bad muscle
                data(i,counter)=nan;
            end
        end
        
        %Other metrics: max, min, gait cycle avg., SNR
        counter=counter+1;
        counter0=counter;
        if i==1
        paramLabels{counter}=[labs{j} 'max'];
        description{counter}=['Peak proc EMG in muscle ' labs{j}];
        end
        data(i,counter)=max(Data(:,j));
        
        counter=counter+1;
        if i==1
        paramLabels{counter}=[labs{j} 'min'];
        description{counter}=['Min proc EMG in muscle ' labs{j}];
        end
        data(i,counter)=min(Data(:,j));
        
        counter=counter+1;
        if i==1
        paramLabels{counter}=[labs{j} 'med'];
        description{counter}=['Median proc EMG in muscle ' labs{j}];
        end
        data(i,counter)=median(Data(:,j));
        
        counter=counter+1;
        if i==1
        paramLabels{counter}=[labs{j} 'avg'];
        description{counter}=['Average (mean) proc EMG in muscle ' labs{j}];
        end
        data(i,counter)=mean(Data(:,j));
        
        counter=counter+1;
        if i==1
        paramLabels{counter}=[labs{j} 'var'];
        description{counter}=['Variance of proc EMG in muscle ' labs{j}];
        end
        data(i,counter)=var(Data(:,j),0); %Unbiased
        
        counter=counter+1;
        if i==1
        paramLabels{counter}=[labs{j} 'skw'];
        description{counter}=['Skewness proc EMG in muscle ' labs{j}];
        end
        data(i,counter)=skewness(Data(:,j),0); %Unbiased estimation
        
        counter=counter+1;
        if i==1
        paramLabels{counter}=[labs{j} 'kur'];
        description{counter}=['Kurtosis proc EMG in muscle ' labs{j}];
        end
        data(i,counter)=kurtosis(Data(:,j),0); %Unbiased estimation
        
        counter=counter+1;
        if i==1
        paramLabels{counter}=[labs{j} 'iqr'];
        description{counter}=['Inter-quartile range in proc EMG in muscle ' labs{j}];
        end
        data(i,counter)=iqr(Data(:,j));
        
        
        
        counter=counter+1;
        if i==1
        paramLabels{counter}=[labs{j} 'snr'];
        description{counter}=['Energy of proc EMG divided by base noise energy (in dB) for muscle ' labs{j}];
        end
        data(i,counter)=20*log10(mean(Data(:,j).^2)/min(Data(:,j))^2);
        
        counter=counter+1;
        if i==1
        paramLabels{counter}=[labs{j} 'bad'];
        description{counter}=['Signals if EMG quality was anything other than good (no missing, no spikes, no out-of-range) for muscle ' labs{j}];
        end
        if ~isempty(Qual)
        data(i,counter)=sum(unique(Qual(:,j))); %Quality codes used are powers of 2, which allows for 8 different codes (int8). Sum of unique appearances allows to keep track of all codes at the same time.
        else
            data(i,counter)=0;
        end
    end
end

%% Create parameterSeries
out=parameterSeries(data(:,1:length(paramLabels)),paramLabels,[],description);        

end

