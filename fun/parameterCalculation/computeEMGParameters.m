function [out] = computeEMGParameters(strideEvents,stridedProcEMG,s)
%This function computes summary parameters per stride based on EMG data.
%The output is a parameterSeries object, which can be concatenated with
%other parameterSeries objects, for example with those from
%computeTemporalParameters.
%See also computeSpatialParameters, computeTemporalParameters,
%computeForceParameters, parameterSeries

%%
timeSHS=strideEvents.tSHS;
timeFTO=strideEvents.tFTO;
timeFHS=strideEvents.tFHS;
timeSTO=strideEvents.tSTO;
timeSHS2=strideEvents.tSHS2;
eventTimes=[timeSHS timeFTO .5*(timeFTO+timeFHS) timeFHS timeSTO .5*(timeSTO+timeSHS2) timeSHS2]; %stride is divided into double supports, and early/late single stances (6 phases)
eventTimes2=nan(size(eventTimes,1),13);
eventTimes2(:,1:2:end)=eventTimes;
eventTimes2(:,2:2:end)=.5*(eventTimes(:,1:end-1)+eventTimes(:,2:end)); %Each of the phases of eventTimes is divided exactly in halves (12 sub-phases)
%paramLabels={};
%description={};
%phases={'DS1','EfSwing','LfSwing','DS2','EsSwing','LsSwing'};
%desc={'SHS to FTO', 'FTO to mid fast swing', 'mid fast swing to FHS', 'FHS to STO', 'STO to mid slow swing', 'mid slow swing to SHS'};
phases2={'eDS1','lDS1','EfSwing1','EfSwing2','LfSwing1','LfSwing2','eDS2','lDS2','EsSwing1','EsSwing2','LsSwing1','LsSwing2'};
Np=numel(phases2);
desc2={'SHS to mid DS1','mid DS1 to FTO', 'FTO to 1/4 fast swing','1/4 to mid fast swing', 'mid fast swing to 3/4','3/4 fast swing to FHS', 'FHS to mid DS2', 'mid DS2 to STO', 'STO to 1/4 slow swing','1/4  to mid slow swing','mid slow swing to 3/4','3/4 slow swing to SHS'};
%% Parameter list and description (per muscle!)
labelSuff={'max','min','avg','var','med','snr','bad'}; %Some stats on channel data, excluded 'skw','kur','iqr' because they are never used and take long to compute
phaseBasedLabelSuff={'s'};%[repmat({'s'},1,Np)]; %Reserving 12 phases for 's' paramters

%labelSuff=[labelSuff strcat('p',regexp(num2str(1:6),' +','split')) strcat('s',regexp(num2str(1:12),' +','split'))]; 
%'p' parameters were deprecated becase they can be expressed as a function of 's' parameters. The numerical difference between the two is <1e-8, which is less than 1%%of the minimum value observed in practice
%labelSuff=[labelSuff strcat('t',regexp(num2str(1:12),' +','split')) strcat('e',regexp(num2str(1:12),' +','split'))]; %These two need to be deprecated.

%%
N=length(stridedProcEMG);

labs=stridedProcEMG{1}.labels;
paramData=nan(N,length(labs),length(labelSuff)+Np*length(phaseBasedLabelSuff));
paramLabels=cell(length(labs),length(labelSuff)+Np*length(phaseBasedLabelSuff));
description=cell(length(labs),length(labelSuff)+Np*length(phaseBasedLabelSuff));
%Define parameter names and descriptions:
for j=1:length(labs) %Muscles
    if strcmp(labs{j}(1),s)
        l='s';
    else
        l='f';
    end
     for k=1:length(labelSuff) %Description for each param NOT phase-based
        if strcmp(labelSuff{k},'bad')
            paramLabels{j,k}=[l labs{j}(2:end) labelSuff{k}];
            description{j,k}=['Signals if EMG quality was anything other than good (no missing, no spikes, no out-of-range) for muscle ' labs{j}];
        else
            paramLabels{j,k}=[l labs{j}(2:end) labelSuff{k}];
            description{j,k}=[labelSuff{k} ' procEMG in muscle ' labs{j}];
        end
        %This gets overwritten for  
     end
     lK=length(labelSuff);
     for k=1:length(phaseBasedLabelSuff) %Phase-based params
        if strcmp(phaseBasedLabelSuff{k},'s')
            for kk=1:Np
                description{j,lK+(k-1)*Np+kk}=['Average of proc EMG data in muscle ' labs{j} ' from ' desc2{kk}];
                paramLabels{j,lK+(k-1)*Np+kk}=[l labs{j}(2:end) phaseBasedLabelSuff{k} num2str(kk)];
            end
        end
     end
end

for i=1:N %For each stride
    Time=stridedProcEMG{i}.Time;
    labs=stridedProcEMG{i}.labels;
    Data=stridedProcEMG{i}.Data;
    Qual=stridedProcEMG{i}.Quality;
    %sP=stridedProcEMG{i}.sampPeriod;
    for j=1:length(labs) %Muscles
        mData=Data(:,j);
        if ~isempty(Qual)
            qq=Qual(:,j);
        else
            qq=0;
        end
        %phaseS=0;
        %Pre-computing relevant indexes for efficiency:
        relIdx=sparse(Np,length(Time));
        relIdx= Time<eventTimes2(i,2:end) & Time>=eventTimes2(i,1:end-1);
        %for k=1:Np
        %    relIdx(k,:)=Time<=eventTimes2(i,k+1) & Time>=eventTimes2(i,k);
        %end
        for k=1:length(labelSuff) %Computing each param
            relIdx=1:length(Time);
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
        for k=1:length(phaseBasedLabelSuff)
            switch(labelSuff{k})
                case 's' %Mean EMG per phase (12 phases)
                    paramData(i,j,:)=mean(mData.*relIdx,2);
                    paramData(i,j,any((qq.*relIdx')~=0))=NaN;
                        %phaseS=phaseS+1;
                        %relIdx=Time<=eventTimes2(i,phaseS+1) & Time>=eventTimes2(i,phaseS); %Computing mean for 1 of 12 phases
                        %description{j,k}=['Average of proc EMG data in muscle ' labs{j} ' from ' desc2{phaseS}];
                        %paramData(i,j,k)=mean(mData(relIdx));
                        %paramData(i,j,k)=mean(mData(relIdx(k,:)));
%                     if ~isempty(Qual) && any(Qual(relIdx(k,:),j)~=0) %Quality points to bad muscle
%                         paramData(i,j,k)=nan;
%                     end
                otherwise
                        %nop
            end 
        end
    end
end
%% Create parameterSeries
out=parameterSeries(paramData(:,:),paramLabels(:),[],description(:));        
end

