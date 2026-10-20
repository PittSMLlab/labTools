function [newThis,baseValues,typeList] = ...
    removeBiasV4(this,refConditions,normalizeFlag,padWithNaNFlag, ...
    numStrides,medianFlag)
%REMOVEBIASV4 Remove the baseline of every parameter (last N strides).
%
%   [newThis,baseValues,typeList] = REMOVEBIASV4(this,refConditions,
% normalizeFlag,padWithNaNFlag,numStrides,medianFlag) is REMOVEBIASV3 with a
% selectable baseline window and statistic: the baseline is the mean (or
% median) of every parameter over the last |numStrides| good strides of the
% baseline condition. This is the implementation behind
% ADAPTATIONDATA.REMOVEBIAS. Without refConditions, the baseline is the
% condition whose name contains 'base' and the trial type (found with
% GETCONDITIONSTHATMATCHV2). Columns that must not change (bad, good, trial,
% initTime, finalTime, direction, the stride-quality reason columns,
% triageOutlier and HandrailHolding) are copied unchanged.
%
% Inputs:
%   this           - adaptationData object
%   refConditions  - baseline condition name(s) or number(s), one per trial
%                    type; [] searches by name (default [])
%   normalizeFlag  - 0 subtracts the baseline, 1 divides by it (default 0)
%   padWithNaNFlag - passed to GETEARLYLATEDATA_V2 (default false)
%   numStrides     - negative: use the last |numStrides| strides, exempting
%                    the very last 5 and the first 1; -100 (H-reflex) uses
%                    them all (default -40)
%   medianFlag     - 1 uses the median, otherwise the mean (default 0)
%
% Outputs:
%   newThis    - adaptationData object with the bias removed
%   baseValues - types x parameters baseline values (NaN if none)
%   typeList   - cell array of the trial types, in the order of baseValues
%
% Toolbox Dependencies: None
%
% See also REMOVEBIASV3, ADAPTATIONDATA.REMOVEBIAS, GETEARLYLATEDATA_V2,
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

if nargin < 4 || isempty(padWithNaNFlag)
    padWithNaNFlag = false;
end

if nargin < 5 || isempty(numStrides)
    numStrides = -40;   % default last 40 strides (backward compatibility)
end

if nargin < 6 || isempty(medianFlag)
    medianFlag = 0;   % default is to use mean for the baseline behavior
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

hreflexNumStrides = -100; % H-reflex baseline: last 100 strides (10 stimuli)
exemptLast        = 5;
exemptFirst       = 1;
for itype = 1:length(types)
    allTrials = find(strcmp(this.trialTypes,types{itype}));
    if isempty(refConditions)
        baseCond = this.metaData.getConditionsThatMatchV2('base', ...
            types{itype});
    else
        if iscell(refConditions) & length(refConditions) > 1
            warning(['More than one base condition was provided/found. ' ...
                'Using only the first one.'])
            disp('List of baseline conditions provided:')
            disp(refConditions)
            baseCond = refConditions{1};
        end
        baseCond = refConditions{itype};
    end

    %Remove baseline tendencies from all itype trials
    if ~isempty(baseCond)
        % OG and TM are treated the same: the baseline is the last
        % numStrides strides of the condition
        if numStrides == hreflexNumStrides
            % no strides exempted
            base = getEarlyLateData_v2(this.removeBadStrides,labels, ...
                baseCond,0,numStrides,0,0,padWithNaNFlag);
        else
            % exempting the very last 5 and the first 1
            % TODO: source? an earlier comment said the first 10
            base = getEarlyLateData_v2(this.removeBadStrides,labels, ...
                baseCond,0,numStrides,exemptLast,exemptFirst, ...
                padWithNaNFlag);
        end
        if medianFlag == 1
            base = median(squeeze(base{1}), 'omitnan');
        else
            base = mean(squeeze(base{1}), 'omitnan');
        end

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
