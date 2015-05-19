function [newThis,baseValues,typeList]=removeBiasV2(this,conditions)
% removeBias('condition') or removeBias({'Condition1','Condition2',...})
% removes the median value of EVERY parameter (phaseShift, temporal parameters, etc included!)
% from each trial that is the same type as the condition entered. If no
% condition is specified, then the condition name that contains both the
% type string and the string 'base' is used as the baseline condition.
%TO DO: see what happens when 2+ conditions of the same type are entered
%TO DO: see what happens when 0 conditions are given for a certain type

conds=this.metaData.conditionName;
if nargin>1 %Ideally, number of conditions given should be the same as the amount of types that exist (i.e. one for OG, one for TM, ...)
    %convert input to standardized format
    if isa(conditions,'char')
        conditions={conditions};
    elseif isa(conditions,'double')
        conditions=conds(conditions);
    end
    % validate condition(s)    
    cInput=conditions(this.isaCondition(conditions));
end

trialsInCond=this.metaData.trialsInCondition;
trialTypes=this.data.trialTypes;
trialTypes=this.trialTypes; %Pablo added this on 5/18 and a function in adaptationData that makes this code back compatible
types=unique(trialTypes(~cellfun(@isempty,trialTypes)));
labels=this.data.labels;
baseValues=NaN(length(types),length(labels));
newData=nan(size(this.data.Data));
for itype=1:length(types)
    allTrials=[];
    baseTrials=[];
    %for each type, make array of all trials in that type and an array of
    %baseline trials.
    for c=1:length(conds)
        trials=trialsInCond{c};
        if all(strcmpi(trialTypes(trials),types{itype}))
            allTrials=[allTrials trials];
            if nargin<2 || isempty(conditions)
                %if no conditions were entered, this just searches all
                %condition names for the string 'base' and the Type string
                if ~isempty(strfind(lower(conds{c}),'base')) && ~isempty(strfind(lower(conds{c}),lower(types{itype})))
                    baseTrials=[baseTrials trials];
                elseif ~isempty(strfind(lower(conds{c}),'base'))
                    baseTrials=[baseTrials trials];
                end
            else
                if any(ismember(cInput,conds{c}))
                    baseTrials=[baseTrials trials];
                end
            end
        end
    end
    %Remove baseline tendencies from all itype trials   
    if ~isempty(baseTrials)
        if strcmpi(types{itype},'OG')
            %[~, inds]=this.getParamInTrial(labels,allTrials);
            newData(:,:)=removeOGbias(this,allTrials,baseTrials);
            baseValues(itype,:)=NaN; %Need to replace this with the value actually extracted from OG trials
        else
%             base=nanmedian(this.getParamInTrial(labels,baseTrials));
            aux=(this.getParamInTrial(labels,baseTrials));
            %Last (upto) 40 strides, excepting the very last 5 and first 10
            if size(aux,1)>50
                N=40;
                base=nanmean(aux(end-N+1:end-5,:));
                %base=nanmean(base);
            else
                base=nanmean(aux(10:end,:));
               % base=nanmean(base);
               
            end
            [data, inds]=this.getParamInTrial(labels,allTrials);
            newData(inds,:)=data-repmat(base,length(inds),1);
            baseValues(itype,:)=base;
        end
    else
        warning(['No ' types{itype} ' baseline trials detected. Bias not removed from ' types{itype} ' trials.'])
        [~, inds]=this.getParamInTrial(labels,allTrials);
        newData(inds,:)=this.data.Data(inds,:);
    end
end
%fix any parameters that should not have bias removal
[~,idxs]=this.data.isaParameter({'bad','good','trial','initTime','finalTime'});
if ~isempty(idxs)
    try
    newData(:,idxs(idxs>0))=this.data.Data(:,idxs(idxs>0));
    catch
        a=1;
    end
end

if isa(this.data,'paramData')
    newParamData=paramData(newData,labels,this.data.indsInTrial,this.data.trialTypes);
else
    newParamData=parameterSeries(newData,labels,this.data.hiddenTime,this.data.description);
end
newThis=adaptationData(this.metaData,this.subData,newParamData);
typeList=types;

end