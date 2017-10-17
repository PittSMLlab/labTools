function [newThis,baseValues,typeList]=removeBiasV3(this,refConditions,normalizeFlag)
% removeBias('condition') or removeBias({'Condition1','Condition2',...})
% removes the median value of EVERY parameter (phaseShift, temporal parameters, etc included!)
% from each trial that is the same type as the condition entered. If no
% condition is specified, then the condition name that contains both the
% type string and the string 'base' is used as the baseline condition.
%INPUT:
%this: adaptationData object
%conditions: list of conditions to be used as reference for bias removal,
%if none given, will search for conditions that contain the string 'base'
%
%TO DO: see what happens when 2+ conditions of the same type are entered
%TO DO: see what happens when 0 conditions are given for a certain type
%TODO: implement a check of conditions such that only one condition per
%trialType is accepted

conds=this.metaData.conditionName;
if nargin<2 || isempty(refConditions)
    warning('No condition names passed to removeBiasV3, will find reference conditions by name search.')
    refConditions=[];
end
%if nargin>1 && ~isempty(conditions) %Ideally, number of conditions given should be the same as the amount of types that exist (i.e. one for OG, one for TM, ...)
    %convert input to standardized format
    if isa(refConditions,'char')
        refConditions={refConditions};
    elseif isa(refConditions,'double')
        refConditions=conds(refConditions);
    end
    % validate condition(s)
    cInput=refConditions(this.isaCondition(refConditions));
%end
if nargin<3 || isempty(normalizeFlag)
    normalizeFlag=0;
end


trialsInCond=this.metaData.trialsInCondition;
% trialTypes=this.data.trialTypes;
trialTypes=this.trialTypes; %Pablo added this on 5/18 and a function in adaptationData that makes this code back compatible
types=unique(trialTypes(~cellfun(@isempty,trialTypes)));
labels=this.data.labels; %all labels
baseValues=NaN(length(types),length(labels));
newData=nan(size(this.data.Data));

for itype=1:length(types)
    allTrials=find(strcmp(this.trialTypes,types{itype}));
    if isempty(refConditions)
        [baseCond]=this.metaData.getConditionsThatMatch('base',types{itype});
    else
        baseCond=refConditions{itype};
    end
    if length(baseCond)>1
        warning('More than one base condition was provided/found. Using only the first one.')
        disp('List of baseline conditions provided:')
        disp(baseCond)
        baseCond=baseCond{1};
    end
    %Remove baseline tendencies from all itype trials
    if ~isempty(baseCond)
        switch upper(types{itype})
            case 'OG'
                if normalizeFlag==0
                    try
                        baseTrials=this.getTrialsInCond(baseCond);
                        newData(:,:)=removeOGbias(this,allTrials,baseTrials);
                        baseValues(itype,:)=NaN; %Need to replace this with the value actually extracted from OG trials
                    catch
                        error('Failed to remove OG bias. Likely problem is that bias was already removed for this adaptationData object.')
                    end
                end %Nop for normalizeBias in OG trials

            otherwise %'TM' and any other
              %TODO: switch to using getBaseData()
                base=getEarlyLateData_v2(this.removeBadStrides,labels,baseCond,0,-40,5,10); %Last 40, exempting very last 5 and first 10
                base=nanmean(squeeze(base{1}));
                [data, inds]=this.getParamInTrial(labels,allTrials);
                if normalizeFlag==0
                    %added lines to ensure that if certain parameters never
                    %have a baseline to remove the bias, they are not assigned
                    %as NaN from the bsxfun @minus.
                    %data(isnan(data))=-100000;
                    base(isnan(base))=0;%do not subtract a bias if there is no bias to remove
                    newData(inds,:)=bsxfun(@minus,data,base); %Substracting baseline
                    base(base==0)=nan;
                else
                    base(isnan(base))=1;%do not subtract a bias if there is no bias to remove
                    newData(inds,:)=bsxfun(@rdivide,data,base); %Dividing by baseline
                    base(base==1)=nan;
                end
                %newData(isnan(data))=nan;
                baseValues(itype,:)=base;
        end
    else
        warning(['No ' types{itype} ' baseline trials detected. Bias not removed from ' types{itype} ' trials.'])
        [~, inds]=this.getParamInTrial(labels,allTrials);
        newData(inds,:)=this.data.Data(inds,:);
    end
end
%fix any parameters that should not have bias removal
[~,idxs]=this.data.isaParameter({'bad','good','trial','initTime','finalTime','direction'});
if ~isempty(idxs)
    newData(:,idxs(idxs>0))=this.data.Data(:,idxs(idxs>0));
end

%Construct parameterSeries and maintain backwards compatibility:
if isa(this.data,'paramData')
    newParamData=paramData(newData,labels,this.data.indsInTrial,this.data.trialTypes);
else
    newParamData=parameterSeries(newData,labels,this.data.hiddenTime,this.data.description);
end
newThis=adaptationData(this.metaData,this.subData,newParamData);
typeList=types;

end
