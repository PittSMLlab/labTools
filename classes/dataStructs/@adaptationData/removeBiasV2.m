function [newThis,baseValues,typeList] = ...
    removeBiasV2(this,refConditions,normalizeFlag)
%REMOVEBIASV2 Deprecated: errors immediately, use REMOVEBIASV3 instead.
%
%   [newThis,baseValues,typeList] = REMOVEBIASV2(this,refConditions,
% normalizeFlag) throws an error before doing anything. The code after the
% error is the earlier implementation, which subtracted (or divided by) the
% mean of the last 40 baseline strides, exempting the very last 5 and the
% first 10, per trial type; it is kept for reference and is not reachable.
%
% Inputs:
%   this           - adaptationData object
%   refConditions  - baseline condition name(s) or number(s) (default [])
%   normalizeFlag  - 0 subtracts the baseline, 1 divides by it (default 0)
%
% Outputs:
%   newThis    - adaptationData object with the bias removed
%   baseValues - types x parameters baseline values
%   typeList   - cell array of the trial types
%
% Toolbox Dependencies: None
%
% See also REMOVEBIASV3, REMOVEBIASV4.

error('This function has been deprecated, please use removeBiasV3 instead')

% TODO: see what happens when 2+ conditions of the same type are entered
% TODO: see what happens when 0 conditions are given for a certain type
% TODO: implement a check of conditions such that only one condition per
%   trialType is accepted

conds = this.metaData.conditionName;
if nargin < 2 || isempty(refConditions)
    warning(['No condition names passed to removeBiasV2, will find ' ...
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

%if length(conditions)>1
%    error('RemoveBiasV2 cannot be called with multiple conditions because
%    of known bug. To remove bias on multiple conditions, call on it on a
%    loop, passing a single condition')
%end

trialsInCond = this.metaData.trialsInCondition;
% trialTypes=this.data.trialTypes;
% Pablo added this on 5/18 and a function in adaptationData that makes this
%     code back compatible
trialTypes = this.trialTypes;
types      = unique(trialTypes(~cellfun(@isempty,trialTypes)));
labels     = this.data.labels; %all labels
baseValues = NaN(length(types),length(labels));
newData    = nan(size(this.data.Data));

for itype = 1:length(types)
    allTrials = [];
    %%% TODO: move this segment to its own function (getTrialsInType)-----
    baseTrials = [];
    %for each type, make array of all trials in that type and an array of
    %baseline trials.
    for c = 1:length(conds)
        trials = trialsInCond{c};
        if all(strcmpi(trialTypes(trials),types{itype}))
            allTrials = [allTrials trials];
            if nargin < 2 || isempty(refConditions)
                %if no conditions were entered, this just searches all
                %condition names for the string 'base' and the Type string
                if ~isempty(strfind(lower(conds{c}),'base')) && ...
                        ~isempty(strfind(lower(conds{c}), ...
                        lower(types{itype})))
                    baseTrials = [baseTrials trials];
                elseif ~isempty(strfind(lower(conds{c}),'base'))
                    baseTrials = [baseTrials trials];
                end
            else
                if any(ismember(cInput,conds{c}))
                    baseTrials = [baseTrials trials];
                end
            end
        end
    end
    %%% ------------------------------------------------------------------

    %Remove baseline tendencies from all itype trials
    if ~isempty(baseTrials)
        switch upper(types{itype})
            case 'OG'
                if normalizeFlag == 0
                    try
                        newData(:,:) = ...
                            removeOGbias(this,allTrials,baseTrials);
                        % Need to replace this with the value actually
                        %     extracted from OG trials
                        baseValues(itype,:) = NaN;
                    catch
                        error(['Failed to remove OG bias. Likely ' ...
                            'problem is that bias was already removed ' ...
                            'for this adaptationData object.'])
                    end
                end %Nop for normalizeBias in OG trials

            otherwise %'TM' and any other
                baseInds = ...
                    cell2mat(this.removeBadStrides.data.indsInTrial( ...
                    baseTrials));
                %Last (upto) 40 strides, excepting the very last 5 and first
                %10
                %---------------------------------------------------------
                %----USING LAST (UP TO) N STRIDES, EXEMPTING THE VERY LAST 5
                N = 40;
                %---------------------------------------------------------
                baseInds = baseInds(max([11,end-N-4]):end-5);
                %Or nanmedian?
                base     = mean(this.data.Data(baseInds,:), 'omitnan');
                [data, inds] = this.getParamInTrial(labels,allTrials);

                if normalizeFlag == 0
                    %added lines to ensure that if certain parameters never
                    %have a baseline to remove the bias, they are not
                    %assigned
                    %as NaN from the bsxfun @minus.
                    %data(isnan(data))=-100000;
                    %do not subtract a bias if there is no bias to remove
                    base(isnan(base)) = 0;
                    %Substracting baseline
                    newData(inds,:) = bsxfun(@minus,data,base);
                else
                    %do not subtract a bias if there is no bias to remove
                    base(isnan(base)) = 1;
                    %Dividing by baseline
                    newData(inds,:) = bsxfun(@rdivide,data,base);
                end
                newData(isnan(data)) = nan;
                base(base == 0) = nan;
                baseValues(itype,:) = base;
        end
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