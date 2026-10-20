function [newThis,baseValues,typeList] = ...
    removeBiasV3(this,refConditions,normalizeFlag)
%REMOVEBIASV3 Remove the baseline of every parameter (last 40 strides).
%
%   [newThis,baseValues,typeList] = REMOVEBIASV3(this,refConditions,
% normalizeFlag) subtracts from, or divides, every parameter of all trials
% of a trial type by its mean over the last 40 strides of that type's
% baseline condition, exempting the very last 5 and the first 10 strides and
% ignoring bad strides. Without refConditions, the baseline is the condition
% whose name contains 'base' and the trial type. Prints a warning (and the
% candidates) if several baseline conditions are found and uses the first;
% trial types without a baseline are left unchanged. Columns that must not
% change (bad, good, trial, initTime, finalTime, direction, the
% stride-quality reason columns, triageOutlier and HandrailHolding) are
% copied unchanged.
%
% Inputs:
%   this           - adaptationData object
%   refConditions  - baseline condition name(s) or number(s), one per trial
%                    type; [] searches by name (default [])
%   normalizeFlag  - 0 subtracts the baseline, 1 divides by it (default 0)
%
% Outputs:
%   newThis    - adaptationData object with the bias removed
%   baseValues - types x parameters baseline values (NaN if none)
%   typeList   - cell array of the trial types, in the order of baseValues
%
% Toolbox Dependencies: None
%
% See also REMOVEBIASV4, ADAPTATIONDATA.REMOVEBIAS, GETEARLYLATEDATA_V2,
%   GETSTRIDEQUALITYCONFIG.

conds = this.metaData.conditionName;
if nargin < 2 || isempty(refConditions)
    warning(['No condition names passed to removeBiasV3, will find ' ...
        'reference conditions by name search.'])
    refConditions = [];
end
%if nargin>1 && ~isempty(conditions) %Ideally, ...
% number of conditions given should be the same as the amount of types that
%     exist (i.e. one for OG, one for TM, ...)
%convert input to standardized format
if isa(refConditions,'char')
    refConditions = {refConditions};
elseif isa(refConditions,'double')
    refConditions = conds(refConditions);
end
% validate condition(s)
cInput = refConditions(this.isaCondition(refConditions));
%end
if nargin < 3 || isempty(normalizeFlag)
    normalizeFlag = 0;
end


trialsInCond = this.metaData.trialsInCondition;
% trialTypes=this.data.trialTypes;
% Pablo added this on 5/18 and a function in adaptationData that makes this
%     code back compatible
trialTypes = this.trialTypes;
types      = unique(trialTypes(~cellfun(@isempty,trialTypes)));
labels     = this.data.labels; %all labels
baseValues = NaN(length(types),length(labels));
newData    = nan(size(this.data.Data));

baseNumStrides = -40; % negative = count from the end of the condition
exemptLast     = 5;
exemptFirst    = 10;
for itype = 1:length(types)
    allTrials = find(strcmp(this.trialTypes,types{itype}));
    if isempty(refConditions)
        baseCond = this.metaData.getConditionsThatMatch('base', ...
            types{itype});
    else
        baseCond = refConditions{itype};
    end
    if length(baseCond) > 1
        warning(['More than one base condition was provided/found. ' ...
            'Using only the first one.'])
        disp('List of baseline conditions provided:')
        disp(baseCond)
        baseCond = baseCond{1};
    end
    %Remove baseline tendencies from all itype trials
    if ~isempty(baseCond)
        % OG and TM are treated the same: the baseline is the last 40
        % strides, exempting the very last 5 and the first 10
        base = getEarlyLateData_v2(this.removeBadStrides,labels, ...
            baseCond,0,baseNumStrides,exemptLast,exemptFirst);
        base = mean(squeeze(base{1}), 'omitnan');
        [data, inds] = this.getParamInTrial(labels,allTrials);
        if normalizeFlag == 0
            %added lines to ensure that if certain parameters never
            %have a baseline to remove the bias, they are not assigned
            %as NaN from the bsxfun @minus.
            %do not subtract a bias if there is no bias to remove
            base(isnan(base)) = 0;
            %Substracting baseline
            newData(inds,:) = bsxfun(@minus,data,base);
            base(base == 0) = nan;
        else
            %do not subtract a bias if there is no bias to remove
            base(isnan(base)) = 1;
            %Dividing by baseline
            newData(inds,:) = bsxfun(@rdivide,data,base);
            base(base == 1) = nan;
        end
        baseValues(itype,:) = base;

    else
        warning(['No ' types{itype} ...
            ' baseline trials detected. Bias not removed from ' types{ ...
            itype} ' trials.'])
        [~, inds] = this.getParamInTrial(labels,allTrials);
        newData(inds,:) = this.data.Data(inds,:);
    end
end
%fix any parameters that should not have bias removal
% Also protects stride-quality reason/triage columns (see
% GETSTRIDEQUALITYCONFIG) and 'HandrailHolding' so bias removal does
% not corrupt these binary flag columns.
protectedLabels = [{'bad', 'good', 'trial', 'initTime', ...
    'finalTime', 'direction'}, getStrideQualityConfig().reasonLabels, ...
    {'triageOutlier', 'HandrailHolding'}];
[~,idxs] = this.data.isaParameter(protectedLabels);
if ~isempty(idxs)
    newData(:,idxs(idxs > 0)) = this.data.Data(:,idxs(idxs > 0));
end

%Construct parameterSeries and maintain backwards compatibility:
if isa(this.data,'paramData')
    newParamData = paramData(newData,labels,this.data.indsInTrial, ...
        this.data.trialTypes);
else
    newParamData = parameterSeries(newData,labels,this.data.hiddenTime, ...
        this.data.description);
end
newThis  = adaptationData(this.metaData,this.subData,newParamData);
typeList = types;

end
