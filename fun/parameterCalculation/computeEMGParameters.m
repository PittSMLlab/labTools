function [out] = computeEMGParameters(strideEvents,stridedProcEMG,s)
%%
timeSHS=strideEvents.tSHS;
timeFTO=strideEvents.tFTO;
timeFHS=strideEvents.tFHS;
timeSTO=strideEvents.tSTO;
timeSHS2=strideEvents.tSHS2;
eventTimes=[timeSHS timeFTO .5*(timeFTO+timeFHS) timeFHS timeSTO .5*(timeSTO+timeSHS2) timeSHS2];
eventTimes2=nan(size(eventTimes,1),13);
eventTimes2(:,1:2:end)=eventTimes;
eventTimes2(:,2:2:end)=.5*(eventTimes(:,1:end-1)+eventTimes(:,2:end));
paramLabels={};
description={};
phases={'DS1','EfSwing','LfSwing','DS2','EsSwing','LsSwing'};
desc={'SHS to FTO', 'FTO to mid fast swing', 'mid fast swing to FHS', 'FHS to STO', 'STO to mid slow swing', 'mid slow swing to SHS'};
phases2={'eDS1','lDS1','EfSwing1','EfSwing2','LfSwing1','LfSwing2','eDS2','lDS2','EsSwing1','EsSwing2','LsSwing1','LsSwing2'};
desc2={'SHS to mid DS1','mid DS1 to FTO', 'FTO to 1/4 fast swing','1/4 to mid fast swing', 'mid fast swing to 3/4','3/4 fast swing to FHS', 'FHS to mid DS2', 'mid DS2 to STO', 'STO to 1/4 slow swing','1/4  to mid slow swing','mid slow swing to 3/4','3/4 slow swing to SHS'};
%%
N=length(stridedProcEMG);
data=nan(N,30*(16+12));
for i=1:N
    counter=0;
    Time=stridedProcEMG{i}.Time;
    labs=stridedProcEMG{i}.labels;
    Data=stridedProcEMG{i}.Data;
    Qual=stridedProcEMG{i}.Quality;
    for j=1:length(labs) %Muscles
        if strcmp(labs{j}(1),s)
            l='s';
        else
            l='f';
        end
        for k=1:6 %6 phases
            counter=counter+1;
            if i==1
            paramLabels{counter}=[l labs{j}(2:end) 'p' num2str(k)];
            description{counter}=['Average of proc EMG data in muscle ' labs{j} ' from ' desc{k}];
            end
            data(i,counter)=mean(Data(Time<=eventTimes(i,k+1) & Time>=eventTimes(i,k),j));
            if ~isempty(Qual) & any(Qual(Time<=eventTimes(i,k+1) & Time>=eventTimes(i,k),j)~=0) %Quality points to bad muscle
                data(i,counter)=nan;
            end
        end
        for k=1:12 %6 phases
            counter=counter+1;
            if i==1
            paramLabels{counter}=[l labs{j}(2:end) 's' num2str(k)];
            description{counter}=['Average of proc EMG data in muscle ' labs{j} ' from ' desc2{k}];
            end
            data(i,counter)=mean(Data(Time<=eventTimes2(i,k+1) & Time>=eventTimes2(i,k),j));
            if ~isempty(Qual) & any(Qual(Time<=eventTimes2(i,k+1) & Time>=eventTimes2(i,k),j)~=0) %Quality points to bad muscle
                data(i,counter)=nan;
            end
        end
        
        %Other metrics: max, min, gait cycle avg., SNR
        counter=counter+1;
        counter0=counter;
        if i==1
        paramLabels{counter}=[l labs{j}(2:end) 'max'];
        description{counter}=['Peak proc EMG in muscle ' labs{j}];
        end
        data(i,counter)=max(Data(:,j));
        
        counter=counter+1;
        if i==1
        paramLabels{counter}=[l labs{j}(2:end) 'min'];
        description{counter}=['Min proc EMG in muscle ' labs{j}];
        end
        data(i,counter)=min(Data(:,j));
        
        counter=counter+1;
        if i==1
        paramLabels{counter}=[l labs{j}(2:end) 'med'];
        description{counter}=['Median proc EMG in muscle ' labs{j}];
        end
        data(i,counter)=median(Data(:,j));
        
        counter=counter+1;
        if i==1
        paramLabels{counter}=[l labs{j}(2:end) 'avg'];
        description{counter}=['Average (mean) proc EMG in muscle ' labs{j}];
        end
        data(i,counter)=mean(Data(:,j));
        
        counter=counter+1;
        if i==1
        paramLabels{counter}=[l labs{j}(2:end) 'var'];
        description{counter}=['Variance of proc EMG in muscle ' labs{j}];
        end
        data(i,counter)=var(Data(:,j),0); %Unbiased
        
        counter=counter+1;
        if i==1
        paramLabels{counter}=[l labs{j}(2:end) 'skw'];
        description{counter}=['Skewness proc EMG in muscle ' labs{j}];
        end
        data(i,counter)=skewness(Data(:,j),0); %Unbiased estimation
        
        counter=counter+1;
        if i==1
        paramLabels{counter}=[l labs{j}(2:end) 'kur'];
        description{counter}=['Kurtosis proc EMG in muscle ' labs{j}];
        end
        data(i,counter)=kurtosis(Data(:,j),0); %Unbiased estimation
        
        counter=counter+1;
        if i==1
        paramLabels{counter}=[l labs{j}(2:end) 'iqr'];
        description{counter}=['Inter-quartile range in proc EMG in muscle ' labs{j}];
        end
        data(i,counter)=iqr(Data(:,j));
        
        
        
        counter=counter+1;
        if i==1
        paramLabels{counter}=[l labs{j}(2:end) 'snr'];
        description{counter}=['Energy of proc EMG divided by base noise energy (in dB) for muscle ' labs{j}];
        end
        data(i,counter)=20*log10(mean(Data(:,j).^2)/min(Data(:,j))^2);
        
        counter=counter+1;
        if i==1
        paramLabels{counter}=[l labs{j}(2:end) 'bad'];
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

