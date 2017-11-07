function [out] = computeAngleParameters(strideEvents,stridedAngleData,s)
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
paramLabels={};
description={};
phases={'DS1','EfSwing','LfSwing','DS2','EsSwing','LsSwing'};
desc={'SHS to FTO', 'FTO to mid fast swing', 'mid fast swing to FHS', 'FHS to STO', 'STO to mid slow swing', 'mid slow swing to SHS'};
phases2={'eDS1','lDS1','EfSwing1','EfSwing2','LfSwing1','LfSwing2','eDS2','lDS2','EsSwing1','EsSwing2','LsSwing1','LsSwing2'};
desc2={'SHS to mid DS1','mid DS1 to FTO', 'FTO to 1/4 fast swing','1/4 to mid fast swing', 'mid fast swing to 3/4','3/4 fast swing to FHS', 'FHS to mid DS2', 'mid DS2 to STO', 'STO to 1/4 slow swing','1/4  to mid slow swing','mid slow swing to 3/4','3/4 slow swing to SHS'};
%% Parameter list and description (per angle!)
labelSuff=[repmat({'Angle'},1,numel(phases2))]; %Reserving 12 phases for 's' paramters

%labelSuff=[labelSuff strcat('p',regexp(num2str(1:6),' +','split')) strcat('s',regexp(num2str(1:12),' +','split'))]; 
%'p' parameters were deprecated becase they can be expressed as a function of 's' parameters. The numerical difference between the two is <1e-8, which is less than 1%%of the minimum value observed in practice
%labelSuff=[labelSuff strcat('t',regexp(num2str(1:12),' +','split')) strcat('e',regexp(num2str(1:12),' +','split'))]; %These two need to be deprecated.
%keyboard
%%
N=length(stridedAngleData);
labs=stridedAngleData{1}.labels;
paramData=nan(N,length(labs),length(labelSuff));
paramLabels=cell(length(labs),length(labelSuff));
description=cell(length(labs),length(labelSuff));

%Define parameter names and descriptions:
for j=1:length(labs) %Angles
    if strcmp(labs{j}(1),s)
        l='s';
    else
        l='f';
    end
    phaseS=0;
     for k=1:length(labelSuff) %Computing each param
        if strcmp(labelSuff{k},'Angle')
            phaseS=phaseS+1;
            description{j,k}=['Average of angle' labs{j} ' from ' desc2{phaseS}];
            paramLabels{j,k}=[l labs{j}(2:end) labelSuff{k} num2str(phaseS)];
        
        end
          
     end
end

for i=1:N %For each stride
    Time=stridedAngleData{i}.Time;
    labs=stridedAngleData{i}.labels;
    Data=stridedAngleData{i}.Data;
   
    for j=1:length(labs) %Angles
        mData=Data(:,j);
        phaseS=0;
        for k=1:length(labelSuff) %Computing each param
            relIdx=1:length(Time);

                    if strcmp(labelSuff{k},'Angle') %Mean EMG per phase (12 phases)
                        phaseS=phaseS+1;
                        relIdx=Time<=eventTimes2(i,phaseS+1) & Time>=eventTimes2(i,phaseS); %Computing mean for 1 of 12 phases
                        paramData(i,j,k)=mean(mData(relIdx));
                    end
%                    
              
        end
    end
end
%% Create parameterSeries
out=parameterSeries(paramData(:,:),paramLabels(:),[],description(:));  
end

