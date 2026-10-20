classdef adaptationData
%ADAPTATIONDATA Store all parameters of interest for every stride.
%
%   Objects of this class are generated from experimentData by calling
% experimentData.makeDataObj.
%
% adaptationData properties:
%   metaData - experimentMetaData object (protocol, date, experimenter,
%              conditions, ...)
%   subData  - subjectData object (DOB, sex, height, weight, ...)
%   data     - parameterSeries object
%
% adaptationData methods:
%   removeBias                    - subtract off mean baseline values
%   normalizeBias                 - divide by baseline values
%   getParameterList              - labels of all parameters
%   getParamInTrial               - data of a parameter in a trial
%   getParamInCond                - data of a parameter in a condition
%   isaCondition                  - check whether a condition exists
%   getEarlyLateData              - deprecated; use getEarlyLateData_v2
%   getBias                       - bias removed by removeBias
%   getConditionIdxsFromName      - find conditions by name
%   getIndsInCondition            - data rows of each condition
%   plotParamTimeCourse           - time course of a parameter
%   plotGroupedSubjectsTimeCourse - not functional; use plotAvgTimeCourse
%   plotGroupedSubjects           - deprecated; use plotGroupedSubjectsBars
%   plotGroupedSubjectsBars       - bars of early/late data by group
%   getGroupedData                - early/late data of a group
%   plotAvgTimeCourse             - average time courses by group
%   groupedScatterPlot            - commented out at the end of the file
%   correlations                  - see the Correlations method
%
% Toolbox Dependencies: Statistics and Machine Learning Toolbox
%
% See also EXPERIMENTDATA.

    properties
        %cell array with information related with the experiment (type of
        %protocol, date, experimenter, conditions...)in a experimentMetaData
        %object
        metaData
        %cell array with information of the subject (DOB, sex, height,
        %weight...)in a subjectData object
        subData
        data %cell array of parameterSeries type
    end

    properties(Hidden)
        TMbias_  = [];
        OGbias_  = [];
        INbias_  = [];
        NIMbias_ = [];
    end

    methods
        %Constructor
        function this = adaptationData(meta,sub,data)
            %ADAPTATIONDATA Construct an adaptationData object.
            %
            %   Validates the types of all three inputs and stores them;
            % throws an adaptationData:Constructor error if one has the
            % wrong type.
            %
            % Inputs:
            %   meta - experimentMetaData object
            %   sub  - subjectData object
            %   data - parameterSeries (or legacy paramData) object
            %
            % Outputs:
            %   this - adaptationData object
            %
            % Toolbox Dependencies: None
            %
            % See also EXPERIMENTDATA.MAKEDATAOBJ.

            if nargin > 0 && isa(meta,'experimentMetaData')
                this.metaData = meta;
            else
                ME = MException('adaptationData:Constructor', ...
                    'metaData is not an experimentMetaData type object.');
                throw(ME);
            end

            if nargin > 1 && isa(sub,'subjectData')
                this.subData = sub;
            else
                ME = MException('adaptationData:Constructor', ...
                    'Subject data is not a subjectData type object.');
                throw(ME);
            end

            if nargin > 2 && (isa(data,'parameterSeries') || ...
                    isa(data,'paramData'))
                this.data = data;
            else
                ME = MException('adaptationData:Constructor', ...
                    'Data is not a parameterSeries type object.');
                throw(ME);
            end
        end
        function this = set.data(this,data)
            %SET.DATA Validate and set the data property.
            %
            %   Accepts only a parameterSeries or paramData object;
            % otherwise throws an adaptationData:setData error.
            %
            % Inputs:
            %   this - adaptationData object
            %   data - parameterSeries or paramData object
            %
            % Outputs:
            %   this - adaptationData object with the new data
            %
            % Toolbox Dependencies: None

            if nargin > 1 && (isa(data,'parameterSeries') || ...
                    isa(data,'paramData'))
                this.data = data;
            else
                ME = MException('adaptationData:setData', ...
                    'Data is not a parameterSeries type object.');
                throw(ME);
            end
        end
        function tT = trialTypes(this)
            %TRIALTYPES Get the type of every trial.
            %
            %   Returns the types stored in the parameterSeries when
            % present (newer files). Otherwise guesses each trial's type
            % from the name of its condition: 'OG' if the name contains OG,
            % 'IN' for incline or hill, 'NIM' for NIM, 'mis' if the trial
            % is in no condition, and 'TM' for everything else.
            %
            % Inputs:
            %   this - adaptationData object
            %
            % Outputs:
            %   tT - 1 x Ntrials cell array of trial type names
            %
            % Toolbox Dependencies: None

            if ~isempty(this.data.trialTypes)
                %Tries to read from parameterSeries' trialType field, if it
                %was populated, as we expect it to be with newer versions
                tT = this.data.trialTypes;
            else %If the field was not populated, make an educated guess.
                tT = cell(1,this.metaData.Ntrials);
                for ii = 1:this.metaData.Ntrials
                    condInd = nan;
                    for jj = 1:length(this.metaData.conditionName)
                        if any(this.metaData.trialsInCondition{jj} == ii)
                            condInd = jj;
                            break
                        end
                    end
                    if isnan(condInd)
                        tT{ii} = 'mis';
                    elseif ~isempty(strfind( ...
                            this.metaData.conditionName{condInd},'OG'))
                        tT{ii} = 'OG';
                    elseif ~isempty(strfind( ...
                            this.metaData.conditionName{condInd}, ...
                            'incline')) || ~isempty(strfind( ...
                            this.metaData.conditionName{condInd},'hill'))
                        tT{ii} = 'IN';
                    elseif ~isempty(strfind( ...
                            this.metaData.conditionName{condInd},'NIM'))
                        tT{ii} = 'NIM';
                    else
                        tT{ii} = 'TM';
                    end
                end
            end
        end
        %Modifiers

        % NOTE: removeBiasV2 is slated for deprecation in favor of the
        % simpler removeBiasV3.
        [newThis,baseValues,typeList] = ...
            removeBiasV2(this,conditions,normalizeFlag)
        [newThis,baseValues,typeList] = ...
            removeBiasV3(this,conditions,normalizeFlag)
        [newThis,baseValues,typeList] = ...
            removeBiasV4(this,conditions,normalizeFlag,padWithNaNFlag, ...
            numStrides,medianFlag)

        function [newThis,baseValues,typeList] = ...
            removeBias(this,conditions,padWithNaNFlag,numStrides,medianFlag)
            %REMOVEBIAS Remove the baseline value of every parameter.
            %
            %   For each trial type, subtracts the baseline value of every
            % parameter from all trials of that type. Without conditions,
            % the baseline is the condition whose name contains both the
            % type string and 'base'. Implemented with REMOVEBIASV4; the
            % values removed are stored in the TMbias_, OGbias_, INbias_
            % and NIMbias_ properties (see GETBIAS).
            %
            % Inputs:
            %   this           - adaptationData object
            %   conditions     - condition name(s) to use as reference
            %                    (default: automatic)
            %   padWithNaNFlag - passed to REMOVEBIASV4 (default false)
            %   numStrides     - passed to REMOVEBIASV4 (default [])
            %   medianFlag     - passed to REMOVEBIASV4 (default [])
            %
            % Outputs:
            %   newThis    - adaptationData object with the bias removed
            %   baseValues - baseline values removed, one row per type
            %   typeList   - type of each row of baseValues (TM, OG, IN or
            %                NIM)
            %
            % Toolbox Dependencies: None
            %
            % Example:
            %   [newThis, baseValues, typeList] = ...
            %       adaptData.removeBias('TM base');
            %
            % See also REMOVEBIASV4, NORMALIZEBIAS, GETBIAS.


            if nargin < 2
                conditions = [];
            end

            if nargin < 3
                padWithNaNFlag = false;
            end
            if nargin < 4
                numStrides = [];
            end
            if nargin < 5
                medianFlag = [];
            end
            % NOTE: removeBiasV3 is the alternative implementation:
            %[newThis,baseValues,typeList]=removeBiasV3(this,conditions);
            [newThis,baseValues,typeList] = ...
                removeBiasV4(this,conditions,[],padWithNaNFlag, ...
                numStrides,medianFlag);
            newThis.TMbias_ = baseValues(strcmp(typeList,'TM'),:);
            newThis.OGbias_ = baseValues(strcmp(typeList,'OG'),:);
            newThis.INbias_ = baseValues(strcmp(typeList,'IN'),:);
            newThis.NIMbias_ = baseValues(strcmp(typeList,'NIM'),:);
        end

        function newThis = removeAltBias(this,condName,strideNo, ...
            exemptStrides,medianFlag,normalizeFlag,removeBadFlag)
            %REMOVEALTBIAS Remove the bias computed from a stride subset.
            %
            %   Same as REMOVEBIAS, but the baseline comes from an
            % arbitrary subset of strides (e.g., the first 20 strides of
            % adaptation). The fixed parameters (initTime, finalTime,
            % trial, good, bad) are not modified. Updates the TMbias_ and
            % OGbias_ properties.
            %
            % Inputs:
            %   this          - adaptationData object
            %   condName      - condition name(s)
            %   strideNo      - strides to average; positive values take the
            %                   first N, negative the last N
            %   exemptStrides - strides skipped at both ends of the
            %                   condition
            %   medianFlag    - nonzero to use the median instead of the
            %                   mean (default 0)
            %   normalizeFlag - 0 to subtract the baseline, otherwise divide
            %                   by it (required)
            %   removeBadFlag - nonzero to remove bad strides before
            %                   computing the baseline (default 0)
            %
            % Outputs:
            %   newThis - adaptationData object with the bias removed
            %
            % Toolbox Dependencies: None
            %
            % See also REMOVEBIAS, GETEARLYLATEDATA_V2.

            if nargin < 7 || isempty(removeBadFlag) || removeBadFlag == 0
                base = getEarlyLateData_v2(this,[],condName,0,strideNo, ...
                    exemptStrides,exemptStrides); %Not removing bad strides
            else
                %Removing bad strides for the purpose of baseline
                %computations
                base = getEarlyLateData_v2(this.removeBadStrides(),[], ...
                    condName,0,strideNo,exemptStrides,exemptStrides);
            end

            if nargin < 5 || isempty(medianFlag) || medianFlag == 0
                base = mean(squeeze(base{1}), 'omitnan');
            else
                base = median(squeeze(base{1}), 'omitnan');
            end
            newThis = this;
            dataOld = this.data.Data;
            if normalizeFlag == 0
                %If certain parameters never have a baseline to remove, do
                %not let bsxfun @minus assign them NaN.
                %data(isnan(data))=-100000;
                %do not subtract a bias if there is no bias to remove
                base(isnan(base)) = 0;
                %Substracting baseline
                newData = bsxfun(@minus,dataOld,base);
            else
                %do not subtract a bias if there is no bias to remove
                base(isnan(base)) = 1;
                %Dividing by baseline
                newData = bsxfun(@rdivide,dataOld,base);
            end
            M = newThis.data.fixedParams;
            %Not removing bias for 'fixed' params: initTime, finalTime,
            %trial, good, bad
            newThis.data.Data(:,M+1:end) = ...
                newData(:,newThis.data.fixedParams+1:end);
            %newData(isnan(data))=nan;
            %If no bias was removed before, start from this one
            if isempty(this.TMbias_)
                newThis.TMbias_ = [zeros(1,M) base(M+1:end)];
                newThis.OGbias_ = [zeros(1,M) base(M+1:end)];
            else
                if normalizeFlag == 0
                    newThis.TMbias_ = ...
                        newThis.TMbias_+[zeros(1,M) base(M+1:end)];
                    newThis.OGbias_ = ...
                        newThis.OGbias_+[zeros(1,M) base(M+1:end)];
                else
                    newThis.TMbias_ = ...
                        newThis.TMbias_.*[zeros(1,M) base(M+1:end)];
                    newThis.OGbias_ = ...
                        newThis.OGbias_.*[zeros(1,M) base(M+1:end)];
                end
            end
        end

        function [newThis,baseValues,typeList] = ...
            normalizeBias(this,conditions)
            %NORMALIZEBIAS Divide every parameter by its baseline value.
            %
            %   Calls REMOVEBIASV3 with its normalize flag set.
            %
            % Inputs:
            %   this       - adaptationData object
            %   conditions - condition name(s) to use as reference (default:
            %                automatic)
            %
            % Outputs:
            %   newThis    - normalized adaptationData object
            %   baseValues - baseline values used
            %   typeList   - type of each row of baseValues
            %
            % Toolbox Dependencies: None
            %
            % See also REMOVEBIAS, REMOVEBIASV3.

            if nargin < 2
                conditions = [];
            end
            [newThis,baseValues,typeList] = removeBiasV3(this,conditions,1);
        end

        function newThis = normalizeToBaseline(this,labelPrefix,baseConds2)
            %NORMALIZETOBASELINE Deprecated; always errors.
            %
            %   Use NORMALIZETOBASELINEEPOCH. The code after the error call
            % is the former implementation, which normalized EMG parameters
            % by the last N strides of a baseline condition and created new
            % parameters with the 'Norm' prefix.
            %
            % Inputs:
            %   this        - adaptationData object
            %   labelPrefix - parameter prefix(es)
            %   baseConds2  - baseline condition(s)
            %
            % Outputs:
            %   newThis - never returned
            %
            % Toolbox Dependencies: None
            %
            % See also NORMALIZETOBASELINEEPOCH.

            error('Deprecated. Use normalizeToBaselineEpoch instead.')
            warning(['This function is meant to be used for EMG ' ...
                'parameters only. Use at own risk.'])
            if nargin < 3
                baseConds2 = [];
            end
            if nargin < 2
                error('Need to provide a prefix for parameters')
            end

            if isa(labelPrefix,'char')
                labelPrefix = {labelPrefix};
            end

            if nargin < 2 || isempty(baseConds2)
                [baseConds,tType] = this.getBaseConditions();
            else
                baseConds = baseConds2;
            end
            if length(baseConds) > 1 %More than 1 baseline found
                idx = find(strcmp(tType,'TM'));
                warning(['More than 1 baseline condition found or ' ...
                    'provided. Using the first that matches TM type ' ...
                    'trials: ' baseConds{idx}])
                baseCond = baseConds{idx};
            end
            for ii = 1:length(labelPrefix)
                %First: get all parameters with given prefix
                labels = this.data.getLabelsThatMatch(['^' ...
                    labelPrefix{ii} '\d+$']);
                %Second: get baseline data for those
                baseData    = getBaseData(this,baseCond,labels);
                range       = squeeze(mean(baseData, 2, 'omitnan'));
                rangeValues = [min(range) max(range)];
                this.data = this.data.normalizeToBaseline(labels, ...
                    rangeValues);
            end
            newThis = this;
        end

        function newThis = normalizeToBaselineEpoch(this,labelPrefix, ...
            baseEpoch,noMinNormFlag)
            %NORMALIZETOBASELINEEPOCH Normalize EMG to a baseline epoch.
            %
            %   Takes the last N strides of a baseline epoch and uses their
            % range to normalize the values of each parameter over the
            % whole experiment. Meant for EMG parameters ONLY. Creates NEW
            % parameters with the same name and the 'Norm' prefix. Warns on
            % every call.
            %
            % Inputs:
            %   this          - adaptationData object
            %   labelPrefix   - parameter prefix(es), char or cell array
            %                   (required)
            %   baseEpoch     - epoch dataset created with defineEpochs
            %   noMinNormFlag - 1 to set the minimum of the range to 0
            %                   (default 0)
            %
            % Outputs:
            %   newThis - adaptationData object with the normalized
            %             parameters
            %
            % Toolbox Dependencies: None
            %
            % See also PARAMETERSERIES.LINEARSTRETCH, GETPREFIXEDEPOCHDATA.

            warning(['This function is meant to be used for EMG ' ...
                'parameters only. Use at own risk.'])
            if nargin < 2
                error('Need to provide a prefix for parameters')
            end
            if isa(labelPrefix,'char')
                labelPrefix = {labelPrefix};
            end
            if nargin < 4 || isempty(noMinNormFlag)
                noMinNormFlag = 0;
            end

            [baseData,label] = this.getPrefixedEpochData(labelPrefix, ...
                baseEpoch);
            baseData = reshape(baseData,size(label,1), ...
                numel(labelPrefix));
            rangeValues = [min(baseData); max(baseData)];
            if noMinNormFlag == 1
                rangeValues(1,:) = 0;
            end
            for ii = 1:length(labelPrefix)
                if ismember('Description',baseEpoch.Properties.VarNames)
                    this.data = this.data.linearStretch(label(:,ii), ...
                        rangeValues(:,ii), ...
                        ['baseEcpoh Info: ' baseEpoch.Description{1}]);
                else
                    this.data = this.data.linearStretch(label(:,ii), ...
                        rangeValues(:,ii));
                end
            end
            newThis = this;
        end

        function newThis = removeBaselineEpoch(this,baseEpoch,labels)
            %REMOVEBASELINEEPOCH Remove bias, keeping flag columns intact.
            %
            %   Calls REMOVEBIAS and then restores the columns that must
            % never be bias-corrected: bad, good, trial, initTime,
            % finalTime, direction, the stride-quality reason columns (see
            % GETSTRIDEQUALITYCONFIG), triageOutlier and HandrailHolding.
            % The epoch subtraction itself is commented out: baseEpoch is
            % only used to compute baseData, which is not applied.
            %
            % Inputs:
            %   this      - adaptationData object
            %   baseEpoch - epoch dataset created with defineEpochs
            %   labels    - parameter labels to keep (default: all)
            %
            % Outputs:
            %   newThis - adaptationData object with the bias removed
            %
            % Toolbox Dependencies: None
            %
            % See also REMOVEBIAS, GETSTRIDEQUALITYCONFIG.

            if nargin < 3 || isempty(labels)
                %nop
                labels = this.data.labels;
            else
                this = this.getPartialParameters(labels);
            end
            baseData = this.getEpochData(baseEpoch,labels);
            newThis  = this.removeBias();
            %newThis.data.Data=this.data.Data-baseData';

            %fix any parameters that should not have bias removal
            % Also protects stride-quality reason/triage columns (see
            % GETSTRIDEQUALITYCONFIG) and 'HandrailHolding' so bias
            % removal does not corrupt these binary flag columns.
            protectedLabels = [{'bad', 'good', 'trial', 'initTime', ...
                'finalTime', 'direction'}, ...
                getStrideQualityConfig().reasonLabels, ...
                {'triageOutlier', 'HandrailHolding'}];
            [~,idxs] = this.data.isaParameter(protectedLabels);
            if ~isempty(idxs)
                newThis.data.Data(:,idxs(idxs > 0)) = ...
                    this.data.Data(:,idxs(idxs > 0));
            end

        end

        function newThis = removeBadStrides(this,markAsNaNflag)
            %REMOVEBADSTRIDES Remove/NaN strides flagged as bad.
            %
            %   Thin wrapper around REMOVESTRIDESBYREASON with reasonLabels
            % = {'bad'}: filters (or NaNs) strides using the aggregate
            % 'bad' column only.
            %
            % Inputs:
            %   this          - adaptationData object
            %   markAsNaNflag - true to NaN bad strides instead of removing
            %                   rows (default false)
            %
            % Outputs:
            %   newThis - adaptationData object without the bad strides
            %
            % Toolbox Dependencies: None
            %
            % See also REMOVESTRIDESBYREASON, REMOVEHANDRAILSTRIDES.

            if nargin < 2 || isempty(markAsNaNflag)
                markAsNaNflag = false;
            end
            newThis = this.removeStridesByReason({'bad'},markAsNaNflag);
        end

        function newThis = removeHandrailStrides(this, markAsNaNflag)
            %REMOVEHANDRAILSTRIDES Remove/NaN handrail-held strides.
            %
            %   Opt-in stride-censoring companion to REMOVEBADSTRIDES: ORs
            % the 'HandrailHolding' flag (computed by
            % COMPUTEFORCEPARAMETERS) into 'bad', then removes (or NaNs)
            % those strides via REMOVESTRIDESBYREASON. Returns this
            % unchanged (with a warning) if 'HandrailHolding' is absent or
            % entirely NaN, i.e., no instrumented handrail data was
            % collected for this subject.
            %
            % Inputs:
            %   this          - adaptationData object
            %   markAsNaNflag - true to NaN handrail-held strides instead of
            %                   removing rows (default false)
            %
            % Outputs:
            %   newThis - adaptationData object without handrail-held
            %             strides; unchanged if no handrail data is
            %             available
            %
            % Toolbox Dependencies: None
            %
            % See also REMOVEBADSTRIDES, REMOVESTRIDESBYREASON,
            %   MARKBADWHENMISSINGANY, COMPUTEFORCEPARAMETERS.

            if nargin < 2 || isempty(markAsNaNflag)
                markAsNaNflag = false;
            end
            if isa(this.data, 'paramData')
                % Legacy paramData-backed objects: pass through
                % unchanged, mirroring REMOVEBADSTRIDES.
                newThis = this;
                return;
            end

            aux = this.data;
            [hasHandrail, handrailIdx] = aux.isaLabel('HandrailHolding');
            if ~hasHandrail || all(isnan(aux.Data(:, handrailIdx)))
                warning('adaptationData:noHandrailData', ...
                    ['No handrail-holding data available for this ' ...
                    'subject; returning object unchanged.']);
                newThis = this;
                return;
            end

            % Delegate the OR-with-'bad'-and-censor mechanics to
            % REMOVESTRIDESBYREASON; this reproduces the prior
            % 'newBad = aux.bad | held' logic exactly, since 'bad' is
            % itself one of the OR'd reason columns.
            newThis = this.removeStridesByReason( ...
                {'bad', 'HandrailHolding'}, markAsNaNflag);
        end

        function newThis = addNewParameter(this,newParamLabel,funHandle, ...
            inputParameterLabels,newParamDescription)
            %ADDNEWPARAMETER Add a parameter computed from existing ones.
            %
            %   Useful for trying out new parameters without recomputing
            % all existing parameters.
            %
            % Inputs:
            %   this                 - adaptationData object
            %   newParamLabel        - name of the new parameter
            %   funHandle            - function handle with N input
            %                          variables, whose result is the new
            %                          parameter
            %   inputParameterLabels - N parameter labels that replace the
            %                          variables of funHandle
            %   newParamDescription  - description of the new parameter
            %
            % Outputs:
            %   newThis - adaptationData object with the new parameter
            %
            % Toolbox Dependencies: None
            %
            % Example:
            %   newThis = this.addNewParameter( ...
            %       'newVelocityContribution', ...
            %       @(x, y, z) x./(2*y./z), {'velocityContributionAlt', ...
            %       'stepTimeContribution', 'stepTimeDiff'}, ...
            %       ['velocityContribution normalized to strideTime ' ...
            %       'times average velocity']);
            %
            % See also PARAMETERSERIES.ADDNEWPARAMETER.


            newPS = this.data.addNewParameter(newParamLabel,funHandle, ...
                inputParameterLabels,newParamDescription);
            this.data = newPS;
            newThis = this;
        end

        function newThis = replaceLR(this)
            %REPLACELR Not implemented.
            %
            %   Idea: replace every label that uses L or R by S or F as
            % corresponds, and write the inverse function. Currently
            % returns nothing.
            %
            % Inputs:
            %   this - adaptationData object
            %
            % Outputs:
            %   newThis - never assigned
            %
            % Toolbox Dependencies: None

        end

        function [biasTM,biasOG] = getBias(this,labels)
            %GETBIAS Get the bias removed by REMOVEBIAS.
            %
            %   Warns if the object has not been unbiased, in which case
            % the outputs are not assigned.
            %
            % Inputs:
            %   this   - adaptationData object
            %   labels - parameter labels (default: all)
            %
            % Outputs:
            %   biasTM - bias removed from TM trials
            %   biasOG - bias removed from OG trials
            %
            % Toolbox Dependencies: None
            %
            % See also REMOVEBIAS.

            if isempty(this.TMbias_)
                warning('This adaptationData object is not unbiased.')
                bias = [];
            else
                if nargin > 1 && ~isempty(labels)
                    [boolFlag,idx] = this.data.isaLabel(labels);
                    biasOG = this.OGbias_(idx(boolFlag));
                    biasTM = this.TMbias_(idx(boolFlag));
                else %Fast eval
                    biasOG = this.OGbias_;
                    biasTM = this.TMbias_;
                end
            end
        end

        function newThis = markBadWhenMissingAny(this,labels)
            %MARKBADWHENMISSINGANY Mark strides bad if any label is NaN.
            %
            % Inputs:
            %   this   - adaptationData object
            %   labels - parameter labels to check
            %
            % Outputs:
            %   newThis - adaptationData object with updated bad/good flags
            %
            % Toolbox Dependencies: None
            %
            % See also PARAMETERSERIES.MARKBADWHENMISSINGANY.

            newThis = this;
            newThis.data = newThis.data.markBadWhenMissingAny(labels);
        end

        function newThis = markBadWhenMissingAll(this,labels)
            %MARKBADWHENMISSINGALL Mark strides bad if all labels are NaN.
            %
            % Inputs:
            %   this   - adaptationData object
            %   labels - parameter labels to check
            %
            % Outputs:
            %   newThis - adaptationData object with updated bad/good flags
            %
            % Toolbox Dependencies: None
            %
            % See also PARAMETERSERIES.MARKBADWHENMISSINGALL.

            newThis = this;
            newThis.data = newThis.data.markBadWhenMissingAll(labels);
        end

        function newThis = renameParams(this,oldLabels,newLabels)
            %RENAMEPARAMS Rename parameters.
            %
            %   Labels of oldLabels that exist are replaced by the
            % corresponding newLabels; the others are ignored.
            %
            % Inputs:
            %   this      - adaptationData object
            %   oldLabels - cell array of current labels
            %   newLabels - cell array of new labels, same size as oldLabels
            %
            % Outputs:
            %   newThis - adaptationData object with renamed parameters
            %
            % Toolbox Dependencies: None

            [b,ii] = isaLabel(this.data,oldLabels);
            if any(b)
                newL = this.data.labels;
                newL(ii(b)) = newLabels(b);
                newParam = parameterSeries(this.data.Data,newL, ...
                    this.data.hiddenTime,this.data.description, ...
                    this.data.trialTypes);
                newThis = this;
                newThis.data = newParam;
                %unique(this.data.stridesTrial)
                %unique(newThis.data.stridesTrial)
            else
                newThis = this;
            end

        end

        function newThis = getPartialParameters(this,labels)
            %GETPARTIALPARAMETERS Keep only some parameters.
            %
            % Inputs:
            %   this   - adaptationData object
            %   labels - labels of the parameters to keep
            %
            % Outputs:
            %   newThis - adaptationData object with only those parameters
            %
            % Toolbox Dependencies: None
            %
            % See also REDUCE.

            newThis = this;
            newThis.data = this.data.getDataAsPS(labels);
        end

        function ageInMonths = getSubjectAgeAtExperimentDate(this)
            %GETSUBJECTAGEATEXPERIMENTDATE Get the subject age at testing.
            %
            %   Uses the stored age (years) when available; otherwise
            % computes it from the date of birth (with a privacy warning).
            % Errors if neither is available.
            %
            % Inputs:
            %   this - adaptationData object
            %
            % Outputs:
            %   ageInMonths - subject age in months
            %
            % Toolbox Dependencies: None

            if ~isempty(this.subData.age)
                ageInMonths = this.subData.age*12; %In months
            elseif ~isempty(this.subData.dateOfBirth)
                warning('expData:subjectDOB', ...
                    ['subject metadata contains DOB, this may be a ' ...
                    'privacy issue.'])
                dob         = this.subData.dateOfBirth;
                testData    = this.metaData.date;
                ageInMonths = testData.timeSince(dob);
            else
                error('expData:subjectDOB', ...
                    'Could not establish subject age at experiment time.')
            end
        end

        function newThis = medianFilter(this,N)
            %MEDIANFILTER Median-filter every parameter.
            %
            % Inputs:
            %   this - adaptationData object
            %   N    - filter length
            %
            % Outputs:
            %   newThis - adaptationData object with filtered data
            %
            % Toolbox Dependencies: None
            %
            % See also PARAMETERSERIES.MEDIANFILTER.

            newThis = this;
            newThis.data = this.data.medianFilter(N);
        end

        function newThis = monoLS(this,trialBased,order,Nregularization)
            %MONOLS Apply monotonic least-squares fits to the data.
            %
            %   Fits each trial (trialBased == 1) or each condition
            % separately, replacing columns 6 and onwards of the data (the
            % parameters after the 5 fixed columns).
            %
            % TODO: check that the submodule containing monoLS is in the
            %   path, or this will fail.
            %
            % Inputs:
            %   this            - adaptationData object
            %   trialBased      - 1 to fit per trial, otherwise per
            %                     condition
            %   order           - order of the derivative constraints
            %   Nregularization - regularization parameter
            %
            % Outputs:
            %   newThis - adaptationData object with the fitted data
            %
            % Toolbox Dependencies: None

            newThis = this;
            %For each condition, or trial:
            if trialBased == 1
                t = unique(this.data.getDataAsVector('trial'));
                for ii = 1:length(t)
                    [partialData,indData] = this.getParamInTrial([],t(ii));
                    aux = monoLS(partialData(:,6:end),[],order, ...
                        Nregularization);
                    newThis.data.Data(indData,6:end) = aux;
                end
            else %Condition based
                for ii = 1:length(this.metaData.trialsInCondition)
                    [partialData,indData] = this.getParamInCond([],ii);
                    if ~isempty(partialData)
                        aux = monoLS(partialData(:,6:end),[],order, ...
                            Nregularization);
                        newThis.data.Data(indData,6:end) = aux;
                    end
                end
            end
        end

        function newThis = substituteNaNs(this,method)
            %SUBSTITUTENANS Replace NaN values by interpolation.
            %
            % Inputs:
            %   this   - adaptationData object
            %   method - interpolation method (default 'linear')
            %
            % Outputs:
            %   newThis - adaptationData object without NaNs
            %
            % Toolbox Dependencies: None
            %
            % See also PARAMETERSERIES.SUBSTITUTENANS.

            if nargin < 2 || isempty(method)
                method = 'linear';
            end
            newThis = this;
            newThis.data = this.data.substituteNaNs(method);
        end

        %Other I/O functions:
        function [labelList,descriptionList] = getParameterList(this)
            %GETPARAMETERLIST Get the parameter labels and descriptions.
            %
            % Inputs:
            %   this - adaptationData object
            %
            % Outputs:
            %   labelList       - cell array with the parameter labels
            %   descriptionList - cell array with the parameter descriptions
            %
            % Toolbox Dependencies: None
            %
            % Example:
            %   labelList = adaptData.getParameterList();

            labelList       = this.data.labels;
            descriptionList = this.data.description;
        end

        function [data,inds,auxLabel] = getParamInTrial(this,label,trial)
            %GETPARAMINTRIAL Get the stride data of parameters in a trial.
            %
            %   Warns about, and skips, trial numbers that are not in the
            % experiment.
            %
            % Inputs:
            %   this  - adaptationData object
            %   label - parameter label(s); [] for all
            %   trial - trial number(s)
            %
            % Outputs:
            %   data     - strides x parameters data of the trial(s)
            %   inds     - rows of the data matrix that belong to the
            %              trial(s)
            %   auxLabel - labels of the parameters returned
            %
            % Toolbox Dependencies: None
            %
            % Example:
            %   [data, inds, auxLabel] = ...
            %       adaptData.getParamInTrial('alphaFast', 2);
            %
            % See also GETPARAMINCOND.

            if isempty(label)
                label = getParameterList(this);
            end

            if isa(label,'char')
                auxLabel = {label};
            else
                auxLabel = label;
            end
            % validate label(s)
            [boolFlag,labelIdx] = this.data.isaParameter(auxLabel);

            % validate trial(s)
            trialNum = [];
            for t = trial
                if isempty(this.data.indsInTrial(t))
                    warning(['Trial number ' num2str(t) ...
                        ' is not a trial in this experiment.'])
                else
                    trialNum(end+1) = t;
                end
            end
            %get data
            inds     = cell2mat(this.data.indsInTrial(trialNum));
            data     = this.data.Data(inds,labelIdx(boolFlag == 1));
            auxLabel = this.data.labels(labelIdx(boolFlag == 1));
        end

        function [data,inds,auxLabel,origTrials] = ...
            getParamInCond(this,label,condition,removeBias)
            %GETPARAMINCOND Get parameter stride data in a condition.
            %
            %   Warns about, and skips, conditions that the subject did not
            % perform. Bias removal is no longer supported here: passing
            % removeBias throws an error, so remove the bias first and then
            % call this method.
            %
            % Inputs:
            %   this       - adaptationData object
            %   label      - parameter label(s) (default: all)
            %   condition  - condition name(s) or number(s) (default: all
            %                named conditions)
            %   removeBias - must be empty or omitted
            %
            % Outputs:
            %   data       - strides x parameters data of the condition(s)
            %   inds       - rows of the data matrix that belong to the
            %                condition(s)
            %   auxLabel   - labels of the parameters returned
            %   origTrials - trial index of each stride
            %
            % Toolbox Dependencies: None
            %
            % Example:
            %   data = adaptData.getParamInCond('alphaFast', 'OG base');
            %
            % See also GETPARAMINTRIAL, REMOVEBIAS.


            % if nargin<4 || isempty(removeBias)
            %     removeBias=0;
            % end
            if nargin < 2 || isempty(label)
                label = this.data.labels;
            end
            if isa(label,'char')
                auxLabel = {label};
            else
                auxLabel = label;
            end
            % validate label(s)
            [boolFlag,labelIdx] = this.data.isaParameter(auxLabel);

            % validate condition(s)
            if nargin < 3 || isempty(condition) || ...
                    (~isa(condition,'cell') && any(isnan(condition)))
                condition = ...
                    this.metaData.conditionName(~cellfun(@isempty, ...
                    this.metaData.conditionName));
            end
            condNum = [];
            if isa(condition,'char')
                condition = {condition};
            end

            if isa(condition,'cell')
                condNum = this.metaData.getConditionIdxsFromName(condition);
                if any(isnan(condNum))
                    warning([this.subData.ID ...
                        ' did not perform condition ''' condition{ ...
                        isnan(condNum)} ''''])
                end
                condNum(isnan(condNum)) = [];
            elseif isa(condition,'double')
                condNum = condition;
            else
                ME = MException('AdaptData.getParamInCond', ...
                    'Condition has to be char, cell of char, or double');
                throw(ME)
            end

            %get data
            if nargin > 3 && ~isempty(removeBias) %Default: no bias removal
                error(['Remove bias is no longer supported from within ' ...
                    'getParamInCond. Remove bias first and then call ' ...
                    'this function'])
            end

            trials     = cell2mat(this.metaData.trialsInCondition(condNum));
            inds       = cell2mat(this.data.indsInTrial(trials));
            origTrials = [];
            for ii = 1:length(trials)
                % TODO: purpose unclear
                origTrials(end+1:end+length( ...
                    this.data.indsInTrial(ii))) = ii;
            end
            data     = this.data.Data(inds,labelIdx(boolFlag == 1));
            auxLabel = this.data.labels(labelIdx(boolFlag == 1));
        end

        function [boolFlag,labelIdx] = isaCondition(this,cond)
            %ISACONDITION Check whether conditions exist (case-insensitive).
            %
            %   Warns for every condition the subject did not perform.
            %
            % Inputs:
            %   this - adaptationData object
            %   cond - condition name, cell array of names, or condition
            %          numbers
            %
            % Outputs:
            %   boolFlag - N x 1 logical, true where the condition exists
            %   labelIdx - N x 1 index of each condition (0 if absent)
            %
            % Toolbox Dependencies: None

            if isa(cond,'char')
                auxCond{1} = cond;
            elseif isa(cond,'cell')
                auxCond = cond;
            elseif isa(cond,'double')
                auxCond = this.metaData.conditionName(cond);
            end
            N        = length(auxCond);
            boolFlag = false(N,1);
            labelIdx = zeros(N,1);
            for jj = 1:N
                for ii = 1:length(this.metaData.conditionName)
                    if strcmpi(auxCond{jj},this.metaData.conditionName{ii})
                        boolFlag(jj) = true;
                        labelIdx(jj) = ii;
                        break;
                    end
                end
            end
            for ii = 1:length(boolFlag)
                if boolFlag(ii) == 0
                    warning([this.subData.ID ...
                        ' did not perform condition ''' cond{ ...
                        ii} ''' or the condition is misspelled.'])
                end
            end
        end

        function [veryEarlyPoints,earlyPoints,latePoints] = ...
            getEarlyLateData(this,labels,conds,removeBiasFlag, ...
            earlyNumber,lateNumber,exemptLast)
            %GETEARLYLATEDATA Deprecated; use GETEARLYLATEDATA_V2.
            %
            %   Returns the very early (first 3), early (first earlyNumber)
            % and late (last lateNumber, skipping the last exemptLast)
            % strides of each condition. Warns on every call.
            %
            % Inputs:
            %   this           - adaptationData object
            %   labels         - parameters to return
            %   conds          - condition name(s)
            %   removeBiasFlag - 1 (default) to remove bias, 0 not to
            %   earlyNumber    - strides in the early set (default 5)
            %   lateNumber     - strides in the late set (default 20)
            %   exemptLast     - strides skipped at the end (default 5)
            %
            % Outputs:
            %   veryEarlyPoints - data of the first 3 strides
            %   earlyPoints     - data of the early strides
            %   latePoints      - data of the late strides
            %
            % Toolbox Dependencies: None
            %
            % See also GETEARLYLATEDATA_V2.


            N1 = 3;%all(cellfun(@(x) isa(x,'char'),conds))
            if isa(conds,'char')
                conds = {conds};
            elseif ~isa(conds,'cell') && ...
                    ~all(cellfun(@(x) isa(x,'char'),conds))
                error('adaptationData:getEarlyLateData', ...
                    ['Conditions must be a string or a cell array ' ...
                    'containing strings.']);
            end
            nConds = length(conds);
            if nargin < 2 || ~(isa(labels,'char') || ...
                    (isa(labels,'cell') && ...
                    all(cellfun(@(x) isa(x,'char'),labels)) ))
                error('adaptationData:getEarlyLateData', ...
                    ['Labels must be a string or a cell array ' ...
                    'containing strings.'])
            end
            if nargin < 5 || isempty(earlyNumber)
                N2 = 5; %early number of points
            else
                N2 = earlyNumber;
            end
            if nargin < 6 || isempty(lateNumber)
                N3 = 20; %late number of points
            else
                N3 = lateNumber;
            end
            if nargin < 7 || isempty(exemptLast)
                Ne = 5;
            else
                Ne = exemptLast;
            end
            if nargin < 4 || isempty(removeBiasFlag)
                removeBiasFlag = 1; %Default
            end
            dataPoints = getEarlyLateData_v2(this,labels,conds, ...
                removeBiasFlag,[N1,N2,-N3],Ne,0);
            veryEarlyPoints = dataPoints{1};
            earlyPoints     = dataPoints{2};
            latePoints      = dataPoints{3};
            warning('adaptationData:getEarlyLateData', ...
                ['This function is being deprecated, use ' ...
                'getEarlyLateDatav2 instead'])
        end

        function [data,validStrides,everyStrideData] = ...
            getEpochData(this,epochs,labels,padWithNaNFlag)
            %GETEPOCHDATA Get summary data for a set of epochs.
            %
            %   For each valid epoch, takes the requested strides with
            % GETEARLYLATEDATA_V2 (no bias removal) and summarizes them
            % with the epoch's summary method. Invalid epochs return NaNs
            % with a warning.
            %
            % Inputs:
            %   this           - adaptationData object
            %   epochs         - dataset created with defineEpochs
            %   labels         - parameter name(s)
            %   padWithNaNFlag - pad with NaNs if too few strides (default
            %                    false)
            %
            % Outputs:
            %   data            - length(labels) x length(epochs) summarized
            %                     data
            %   validStrides    - number of strides with data in each epoch
            %   everyStrideData - cell array with the data of every stride
            %                     per epoch
            %
            % Toolbox Dependencies: None
            %
            % Example:
            %   [data, validStrides, everyStrideData] = ...
            %       adaptData.getEpochData(epochs, ...
            %       {'doubleSupportFast'}, 0);
            %
            % See also VALIDATEEPOCHS, GETEARLYLATEDATA_V2.


            %Manage inputs:
            if isa(labels,'char')
                labels = {labels};
            end
            if nargin < 4 || isempty(padWithNaNFlag)
                padWithNaNFlag = false;
            end

            %First: validate epochs:
            valid = this.validateEpochs(epochs);

            %Second: get data
            removeBiasFlag = 0;
            conds          = epochs.Condition;
            numberOfStrides = ...
                epochs.Stride_No .* sign(epochs.EarlyOrLate-0.5);
            exemptLast   = epochs.ExemptLast;
            exemptFirst  = epochs.ExemptFirst;
            data         = nan(length(labels),length(epochs));
            validStrides = nan(length(epochs),1);
            summaryFlag  = epochs.summaryMethod;
            allData      = cell(length(valid),1);
            for ii = 1:length(valid) %Each valid epoch
                if valid(ii)
                    %Get data
                    dataPoints = getEarlyLateData_v2(this,labels, ...
                        conds{ii},removeBiasFlag,numberOfStrides(ii), ...
                        exemptLast(ii),exemptFirst(ii),padWithNaNFlag);
                    %Summarize it:
                    summFun = str2func(summaryFlag{ii});
                    allData{ii} = reshape(dataPoints{1}, ...
                        abs(numberOfStrides(ii)),numel(labels));
                    data(:,ii) = reshape(summFun(allData{ii},1), ...
                        numel(labels),1);
                    %Counting non-nan values for any label involved (if one
                    %parameter is non-nan for a stride, the stride is valid)
                    validStrides(ii) = sum(any(~isnan(allData{ii})));
                else
                    warning('Invalid epoch found, returning NaNs')
                    data(:,ii) = nan(numel(labels),1);
                    allData{ii} = nan(abs(numberOfStrides(ii)), ...
                        numel(labels));
                end
            end
            if nargout > 2
                everyStrideData = allData;
            end
        end

        function flags = validateEpochs(this,epochs)
            %VALIDATEEPOCHS Check that every epoch's condition exists.
            %
            %   Warns for each invalid epoch.
            %
            % Inputs:
            %   this   - adaptationData object
            %   epochs - dataset created with defineEpochs
            %
            % Outputs:
            %   flags - logical column, true for valid epochs
            %
            % Toolbox Dependencies: None

            flags = true(length(epochs),1);
            for ii = 1:length(epochs) %for each epoch
                if this.isaCondition(epochs.Condition(ii)) %all good
                    %nop
                else
                    warning(['Invalid epoch ' ...
                        epochs.Properties.ObsNames{ ...
                        ii} ' for subject ' this.subData.ID])
                    flags(ii) = false;
                end
            end
        end

        function [dataE,labels,allData] = ...
            getPrefixedEpochData(this,labelPrefix,epochs,padWithNaNFlag)
            %GETPREFIXEDEPOCHDATA Get epoch data of prefixed parameters.
            %
            %   Meant for parameters that end in s1...s12, as computed for
            % EMG and angles. The 's' must be included in the prefixes (to
            % allow other options too). Assumes the same suffixes for all
            % prefixes.
            %
            % Inputs:
            %   this           - adaptationData object
            %   labelPrefix    - prefix(es), char or cell array
            %   epochs         - dataset created with defineEpochs
            %   padWithNaNFlag - pad with NaNs (default false)
            %
            % Outputs:
            %   dataE   - data from GETEPOCHDATA
            %   labels  - parameter labels used
            %   allData - data of every stride per epoch
            %
            % Toolbox Dependencies: None
            %
            % See also GETEPOCHDATA.

            if isa(labelPrefix,'char')
                labelPrefix = {labelPrefix};
            end
            if nargin < 4 || isempty(padWithNaNFlag)
                padWithNaNFlag = false;
            end
            %Putting in row form
            labelPrefix = reshape(labelPrefix,1,numel(labelPrefix));
            aux = ...
                this.data.getLabelsThatMatch(['^' labelPrefix{1} ...
                '[ ]?\d+$']); %Assuming same suffix for all
            if isempty(aux)
                error(['Fail: did not find any parameters with the ' ...
                    'given prefixes'])
                return
            end
            Np = length(aux);
            suffixes = cellfun(@(x) x(length(labelPrefix{1})+1:end),aux, ...
                'UniformOutput',false); %Extracting suffixes, I am lazy
            labels = strcat(repmat(labelPrefix,Np,1), ...
                repmat(suffixes,1,length(labelPrefix))); %To do
            [dataE,~,allData] = this.getEpochData(epochs,labels(:), ...
                padWithNaNFlag);
        end

        function conditionIdxs = getConditionIdxsFromName(this, ...
            conditionNames)
            %GETCONDITIONIDXSFROMNAME Find conditions by (similar) name.
            %
            %   Looks for condition names similar to the ones given.
            % conditionNames is a cell array with a string or a cell array
            % of strings in each cell, e.g. {'Base', 'Adap', {'Post',
            % 'wash'}}.
            %
            % Inputs:
            %   this           - adaptationData object
            %   conditionNames - condition names to look for
            %
            % Outputs:
            %   conditionIdxs - index of each condition (NaN if not found)
            %
            % Toolbox Dependencies: None
            %
            % See also EXPERIMENTMETADATA.GETCONDITIONIDXSFROMNAME.

            conditionIdxs = ...
                this.metaData.getConditionIdxsFromName(conditionNames);
        end

        function inds = getIndsInCondition(this,conditionNames)
            %GETINDSINCONDITION Get the data rows of each condition.
            %
            % Inputs:
            %   this           - adaptationData object
            %   conditionNames - condition name(s) or already-resolved
            %                    indices
            %
            % Outputs:
            %   inds - cell array with the row indices of each condition ([]
            %          if absent)
            %
            % Toolbox Dependencies: None

            if isa(conditionNames,'char') || isa(conditionNames,'cell')
                conditionIdxs = ...
                    this.metaData.getConditionIdxsFromName(conditionNames);
            else
                conditionIdxs = conditionNames;
            end
            inds = {};
            for ii = 1:length(conditionIdxs)
                if ~isnan(conditionIdxs)
                    %Get trials in each condition:
                    trials = cell2mat( ...
                        this.metaData.trialsInCondition(conditionIdxs(ii)));
                    %Now, get inds in each trial:
                    inds{ii} = cell2mat(this.data.indsInTrial(trials));
                else
                    inds{ii} = [];
                end
            end
        end

        function trialNums = getTrialsInCond(this,conditionNames)
            %GETTRIALSINCOND Get the trial numbers of conditions.
            %
            % Inputs:
            %   this           - adaptationData object
            %   conditionNames - condition name(s)
            %
            % Outputs:
            %   trialNums - trial numbers of the condition(s)
            %
            % Toolbox Dependencies: None

            trialNums = this.metaData.getTrialsInCondition(conditionNames);
        end

        function newThis = reduce(this, parametersToKeep)
            %REDUCE Keep only some parameters.
            %
            % Inputs:
            %   this             - adaptationData object
            %   parametersToKeep - labels of the parameters to keep
            %
            % Outputs:
            %   newThis - adaptationData object with only those parameters
            %
            % Toolbox Dependencies: None
            %
            % See also GETPARTIALPARAMETERS.

            newThis = this;
            newThis.data = newThis.data.getDataAsPS(parametersToKeep);
        end

        %Stats testing:
        % 1) Multiple groups

        function [p,anovatab,stats,postHoc,postHocEstimate,data] = ...
            anova1(this,param,conds,groupingStrides,exemptFirst,exemptLast)
            %ANOVA1 One-way ANOVA across conditions and stride groups.
            %
            %   Uses Tukey-Kramer post-hoc tests (MULTCOMPARE). Warns that
            % it should be moved to studyData.
            %
            % Inputs:
            %   this            - adaptationData object
            %   param           - parameter label
            %   conds           - condition names
            %   groupingStrides - strides per group (see
            %                     GETEARLYLATEDATA_V2)
            %   exemptFirst     - strides skipped at the start
            %   exemptLast      - strides skipped at the end
            %
            % Outputs:
            %   p               - ANOVA p-value
            %   anovatab        - ANOVA table
            %   stats           - stats struct of ANOVA1
            %   postHoc         - post-hoc p-values between groups
            %   postHocEstimate - post-hoc mean differences
            %   data            - data used
            %
            % Toolbox Dependencies: Statistics and Machine Learning Toolbox
            %
            % See also ANOVA1, MULTCOMPARE, KRUSKALWALLIS.

            warning(['This needs to be moved to studyData or something ' ...
                'like that'])

            %Post-hoc is Bonferroni corrected t-test
            data = getEarlyLateData_v2(this,param,conds,0, ...
                groupingStrides,exemptLast,exemptFirst);
            for ii = 1:length(data)
                group{ii} = repmat([1:length(conds)]',1, ...
                    abs(groupingStrides(ii))) + (ii-1)*length(conds);
            end
            %This concatenates (cat) the data along the second dimension by
            %default, new Data should be a 2-D array of conditionxs x
            %strides
            newData   = cell2mat(data);
            newGroups = cell2mat(group);
            [p,anovatab,stats] = anova1(newData(:),newGroups(:),'off');
            %Tukey-Kramer post-hoc:
            %By default uses tukey-kramer / honest signficant difference
            c = multcompare(stats);
            M = length(conds)*length(groupingStrides);
            postHoc = nan(M);
            postHocEstimate = nan(M);
            postHoc(sub2ind([M,M],c(:,1),c(:,2))) = c(:,6);
            postHocEstimate(sub2ind([M,M],c(:,1),c(:,2))) = c(:,4);
        end

        function [p,anovatab,stats,postHoc,postHocEstimate,data] = ...
            kruskalwallis(this,param,conds,groupingStrides,exemptFirst, ...
            exemptLast)
            %KRUSKALWALLIS Kruskal-Wallis test across stride groups.
            %
            %   The post-hoc test is a Mann-Whitney-Wilcoxon U (rank sum)
            % test; its p-values are not corrected for multiple
            % comparisons. With several parameters, runs once per parameter
            % and returns cell arrays. Warns that it should be moved to
            % studyData.
            %
            % Inputs:
            %   this            - adaptationData object
            %   param           - parameter label(s)
            %   conds           - condition names
            %   groupingStrides - strides per group (see
            %                     GETEARLYLATEDATA_V2)
            %   exemptFirst     - strides skipped at the start
            %   exemptLast      - strides skipped at the end
            %
            % Outputs:
            %   p               - Kruskal-Wallis p-value
            %   anovatab        - test table
            %   stats           - stats struct
            %   postHoc         - post-hoc p-values between groups
            %   postHocEstimate - post-hoc z values
            %   data            - data used
            %
            % Toolbox Dependencies: Statistics and Machine Learning Toolbox
            %
            % See also KRUSKALWALLIS, RANKSUM, ANOVA1.

            warning(['This needs to be moved to studyData or something ' ...
                'like that'])
            if isa(param,'char')
                param = {param};
            end
            if length(param) > 1
                for ii = 1:length(param)
                    [p{ii},anovatab{ii},stats{ii},postHoc{ii}, ...
                        postHocEstimate{ii}, ...
                        data{ii}] = kruskalwallis(this,param{ii},conds, ...
                        groupingStrides,exemptFirst,exemptLast);
                end
            else
                %Post-hoc is a Bonferroni corrected Mann-Whitney-Wilcoxon U
                %(ranked sum) test.
                data = getEarlyLateData_v2(this,param,conds,0, ...
                    groupingStrides,exemptLast,exemptFirst);
                for ii = 1:length(data)
                    group{ii} = repmat([1:length(conds)]',1, ...
                        abs(groupingStrides(ii))) + (ii-1)*length(conds);
                end
                %This concatenates (cat) the data along the second dimension
                %by default, new Data should be a 2-D array of conditionxs x
                %strides
                newData   = cell2mat(data);
                newGroups = cell2mat(group);
                [p,anovatab,stats] = ...
                    kruskalwallis(newData(:),newGroups(:),'off');
                M = length(conds)*length(groupingStrides);
                postHoc = nan(M);
                postHocEstimate = nan(M);
                %Tukey-Kramer post-hoc:
                %c=multcompare(stats); %By default uses tukey-kramer /
                %honest signficant difference
                %postHoc(sub2ind([M,M],c(:,1),c(:,2)))=c(:,6);
                %postHocEstimate(sub2ind([M,M],c(:,1),c(:,2)))=c(:,4);
                %MWW-U post-hoc:
                for ii = 1:M
                    for jj = ii+1:M
                        [p,~,s] = ranksum(newData(newGroups == ii), ...
                            newData(newGroups == jj));
                        postHoc(ii,jj) = p;
                        postHocEstimate(ii,jj) = s.zval;
                    end
                end
            end
        end
        %function [p,data]=twoSampleTtest()
        %
        %end
        %function [p,data]=twoSampleMWWU()
        %
        %end

        %Display functions:
        function [figHandle,plotHandles] = ...
            plotParamTimeCourse(this,label,runningBinSize, ...
            trialMarkerFlag,conditions,medianFlag,plotHandles)
            %PLOTPARAMTIMECOURSE Plot parameter time courses by condition.
            %
            %   Wrapper around PLOTAVGTIMECOURSE for a single
            % adaptationData object.
            %
            % Inputs:
            %   this            - adaptationData object
            %   label           - parameters to plot
            %   runningBinSize  - number of strides averaged per point
            %                     (default 1)
            %   trialMarkerFlag - 1 to mark the trials that compose each
            %                     condition (default 0)
            %   conditions      - conditions to plot (default: all)
            %   medianFlag      - passed to PLOTAVGTIMECOURSE
            %   plotHandles     - axes handles to draw into
            %
            % Outputs:
            %   figHandle   - handle(s) returned by PLOTAVGTIMECOURSE
            %   plotHandles - not assigned
            %
            % Toolbox Dependencies: None
            %
            % Example:
            %   adaptData.plotParamTimeCourse('spatialContribution', 2, 1);
            %
            % See also PLOTAVGTIMECOURSE.

            if isa(label,'char')
                label = {label};
            end
            if nargin < 4 || isempty(trialMarkerFlag)
                trialMarkerFlag = 0;
            end
            if nargin < 3 || isempty(runningBinSize)
                runningBinSize = 1;
            end
            if nargin < 5 || isempty(conditions)
                conditions = this.metaData.conditionName;
            end
            if nargin < 6 || isempty(medianFlag)
                medianFlag = [];
            end
            if nargin < 7
                plotHandles = [];
            end
            figHandle = adaptationData.plotAvgTimeCourse({this}, ...
                label(:)',conditions,runningBinSize,trialMarkerFlag,[], ...
                [],[],[],[],[],medianFlag,plotHandles);
        end

        [inds,names] = getEarlyLateIdxs(this,conds,numberOfStrides, ...
            exemptLast,exemptFirst)

        dataPoints = getEarlyLateData_v2(this,labels,conds, ...
            removeBiasFlag,numberOfStrides,exemptLast,exemptFirst, ...
            padWithNaN)

        [figHandle,plotHandles] = plotParamBarsByConditionsv2(this, ...
            label,number,exemptLast,exemptFirst,condList,mode,plotHandles);

        function dataPoints = getDataFromInds(this,inds,labels, ...
            padWithNaNFlag)
            %GETDATAFROMINDS Get the data at given stride indices.
            %
            %   inds comes from GETEARLYLATEIDXS. Errors if an index is NaN
            % unless padWithNaNFlag is set, in which case those entries are
            % NaN with a warning.
            %
            % Inputs:
            %   this           - adaptationData object
            %   inds           - cell array of stride-index matrices from
            %                    GETEARLYLATEIDXS
            %   labels         - parameter labels (default: all, which is
            %                    faster)
            %   padWithNaNFlag - pad NaN indices with NaNs (default false)
            %
            % Outputs:
            %   dataPoints - cell array of conditions x strides x labels
            %                arrays
            %
            % Toolbox Dependencies: None
            %
            % See also GETEARLYLATEIDXS, GETEARLYLATEDATA_V2.

            if nargin < 3 || isempty(labels)
                data = this.data.Data;
            else
                data = this.data.getDataAsVector(labels);
            end
            if nargin < 4 || isempty(padWithNaNFlag)
                padWithNaNFlag = false;
            end
            nConds  = size(inds{1},2);
            nLabels = size(data,2);

            for jj = 1:length(inds)
                nSteps = size(inds{jj},1);
                %for i=1:nConds
                %    dataPoints{j}(i,:,:)=data(inds{j}(:,i),:);
                %end
                %This line does the same as the for loop commented above:
                if any(isnan(inds{jj}(:)))
                    if ~padWithNaNFlag
                        error('adaptationData:getDataFromInds', ...
                            ['Could not retrieve for subject ' ...
                            this.subData.ID ' because some of the ' ...
                            'indexes given are NaN.'])
                    else
                        %A less drastic option:
                        warning('adaptationData:getDataFromInds', ...
                            ['Index strides for ' this.subData.ID ...
                            ' are NaN. Data will be padded with NaNs.'])
                        inds{jj} = inds{jj}';
                        auxInds = inds{jj}(~isnan(inds{jj}(:)));
                        auxData = nan(numel(inds{jj}),nLabels);
                        auxData(~isnan(inds{jj}(:)),:) = data(auxInds,:);
                        dataPoints{jj} = ...
                            reshape(auxData,nConds,nSteps,nLabels);
                    end
                else
                    dataPoints{jj} = ...
                        reshape(data(inds{jj}',:),nConds,nSteps,nLabels);
                end
            end
        end

        function [fh,ph] = plotTimeAndBars(this,labels,conds,binwidth, ...
            trialMarkerFlag,medianFlag,ph,numberOfStrides,monoLSfitFlag)
            %PLOTTIMEANDBARS Plot time courses next to early/late bars.
            %
            %   Per label, draws the time course (2/3 of the width) and the
            % bars of the selected stride groups (1/3). monoLSfitFlag
            % chooses the monotonic least-squares fits to overlay.
            %
            % Inputs:
            %   this            - adaptationData object
            %   labels          - parameters to plot
            %   conds           - conditions to plot
            %   binwidth        - strides per time-course point
            %   trialMarkerFlag - passed to PLOTPARAMTIMECOURSE
            %   medianFlag      - passed to PLOTPARAMTIMECOURSE
            %   ph              - M x 2 axes handles (default: new figure)
            %   numberOfStrides - stride groups for the bars (see
            %                     GETEARLYLATEDATA_V2)
            %   monoLSfitFlag   - integer 0-3: 0 no fits, 1 condition-based
            %                     fit, 2 trial-based fit, 3 both
            %
            % Outputs:
            %   fh - figure handle
            %   ph - axes handles
            %
            % Toolbox Dependencies: None
            %
            % Example:
            %   adaptData.plotTimeAndBars({'spatialContributionPNorm'}, ...
            %       {'TM base'}, 5, 1, [], [], [5 -40], []);
            %
            % See also PLOTPARAMTIMECOURSE, PLOTPARAMBARSBYCONDITIONSV2.



            fh = figure;

            M = length(labels);
            if nargin < 7 || isempty(ph) || size(ph,1) ~= M || ...
                    size(ph,2) ~= 2
                clear ph
                for ii = 1:M
                    ph(ii,1) = subplot(M,3,[1:2]+3*(ii-1));
                    ph(ii,2) = subplot(M,3,[3]+3*(ii-1));
                end
            end

            %Defaults:
            plotHandles = []; %Not allowed
            exemptFirst = 1;
            exemptLast  = 5;
            mode        = [];

            %Time courses:
            this.plotParamTimeCourse(labels,binwidth,trialMarkerFlag, ...
                conds,medianFlag,ph(:,1));
            %Add condition based monoLS fits if flag=1,3
            if mod(monoLSfitFlag,2) == 1
                % Third plot: use monotonic LS, constraining derivatives up
                % to 2nd order to have no sign changes, using no
                % regularization, and fitting a single function for each
                % condition
                order = 1;
                reg = 1;
                medianAcrossSubj = 0;
                trialBased = 0;
                filterFlag = [medianAcrossSubj,order,reg,trialBased];
                %Changing colors for plot
                colorOrder = repmat(0.6*ones(1,3),3,1);
                binWidth   = 1;
                %Do the plot:
                adaptationData.plotAvgTimeCourse(this,labels,conds, ...
                    binWidth,[],[],[],colorOrder,[],[],[],filterFlag, ...
                    ph(:,1));
            end
            if monoLSfitFlag > 1 %Add trial based monoLS fits if flag=2,3
                % Third plot: use monotonic LS, constraining derivatives up
                % to 2nd order to have no sign changes, using no
                % regularization, and fitting a single function for each
                % TRIAL
                order = 1;
                reg = 1;
                medianAcrossSubj = 0;
                trialBased = 1;
                filterFlag = [medianAcrossSubj,order,reg,trialBased];
                %Changing colors for plot
                colorOrder = repmat(0*ones(1,3),3,1);
                binWidth   = 1;
                %Do the plot:
                adaptationData.plotAvgTimeCourse(this,labels,conds, ...
                    binWidth,[],[],[],colorOrder,[],[],[],filterFlag, ...
                    ph(:,1));
            end


            %Add bars:
            this.plotParamBarsByConditionsv2(labels,numberOfStrides, ...
                exemptLast,exemptFirst,conds,mode,ph(:,2));

            for ii = 1:M
                subplot(ph(ii,1));
                grid on
                axis tight
                aa = axis;
                subplot(ph(ii,2));
                grid on
                ab = axis;
                axis([ab(1:2) aa(3:4)])
                if ii ~= M
                    ph(ii,1).XTickLabel = {};
                    ph(ii,2).XTickLabel = {};
                else
                    subplot(ph(ii,1))
                    legend off
                end
                ph(ii,2).Title.String = labels{ii};
            end
        end

        function [fh,ph,labels,dataE,dataRef] = ...
            plotCheckerboards(this,labelPrefix,epochs,fh,ph,refEpoch, ...
            flipLR, summFlag)
            %PLOTCHECKERBOARDS Plot checkerboards of prefixed parameters.
            %
            %   Meant for parameters that end in s1...s12, as computed for
            % EMG and angles. The 's' must be included in the prefixes.
            % Calls the groupAdaptationData method on a single-subject
            % group.
            %
            % Inputs:
            %   this        - adaptationData object
            %   labelPrefix - parameter prefix(es)
            %   epochs      - dataset created with defineEpochs
            %   fh          - figure handle (default [])
            %   ph          - axes handles (default [])
            %   refEpoch    - reference epoch (default [])
            %   flipLR      - flip left/right (default false)
            %   summFlag    - how to summarize across strides, e.g. mean or
            %                 median (default [])
            %
            % Outputs:
            %   fh      - figure handle
            %   ph      - axes handles
            %   labels  - labels plotted
            %   dataE   - epoch data
            %   dataRef - reference data
            %
            % Toolbox Dependencies: None
            %
            % See also GROUPADAPTATIONDATA.PLOTCHECKERBOARDS.


            if nargin < 7 || isempty(flipLR)
                flipLR = false;
            end
            if nargin < 4
                fh = [];
            end
            if nargin < 5
                ph = [];
            end
            if nargin < 6
                refEpoch = [];
            end
            if nargin < 8
                summFlag = [];
            end
            %Call onto groupAdaptData method
            [fh,ph,labels,dataE,dataRef] = ...
                this.createSingleSubjGroup().plotCheckerboards( ...
                labelPrefix,epochs,fh,ph,refEpoch,flipLR,summFlag);
        end

        function [dataE,dataRef,labels,groups] = ...
            getCheckerboardsData(this,labelPrefix,epochs,refEpoch,flipLR)
            %GETCHECKERBOARDSDATA Get data for checkerboard plots.
            %
            %   Meant for parameters that end in s1...s12, as computed for
            % EMG and angles. The 's' must be included in the prefixes.
            %
            % Inputs:
            %   this        - adaptationData object
            %   labelPrefix - parameter prefix(es)
            %   epochs      - dataset created with defineEpochs
            %   refEpoch    - reference epoch (default [])
            %   flipLR      - flip left/right (default false)
            %
            % Outputs:
            %   dataE   - epoch data
            %   dataRef - reference data
            %   labels  - labels used
            %   groups  - groups used
            %
            % Toolbox Dependencies: None
            %
            % See also GROUPADAPTATIONDATA.GETCHECKERBOARDSDATA.


            if nargin < 5 || isempty(flipLR)
                flipLR = false;
            end

            if nargin < 4
                refEpoch = [];
            end
            %Call onto groupAdaptData method
            [dataE,dataRef,labels,groups] = ...
                this.createSingleSubjGroup().getCheckerboardsData( ...
                labelPrefix,epochs,refEpoch,flipLR);
        end


        function gAD = createSingleSubjGroup(this)
            %CREATESINGLESUBJGROUP Wrap this subject in a group.
            %
            % Inputs:
            %   this - adaptationData object
            %
            % Outputs:
            %   gAD - groupAdaptationData with one subject
            %
            % Toolbox Dependencies: None
            %
            % See also GROUPADAPTATIONDATA.

            gAD = groupAdaptationData({this.subData.ID},{this}, ...
                this.subData.ID);
        end


        function badSubj = RemoveBadMuscles(this,badMuscles)
            %REMOVEBADMUSCLES Set the data of bad muscles to NaN.
            %
            %   For each muscle prefix, sets every matching label (prefix
            % followed by a number) to NaN. Warns and returns early if a
            % prefix matches no label: normalize the data first.
            %
            % Inputs:
            %   this       - adaptationData object
            %   badMuscles - cell array of muscle label prefixes
            %
            % Outputs:
            %   badSubj - adaptationData object with NaN-ed muscles
            %
            % Toolbox Dependencies: None

            badSubj = this;

            for ii = 1:numel(badMuscles)

                badDataIdx = ...
                    find(cellfun(@(x) ~isempty(x), ...
                    regexp(badSubj.data.labels, ...
                    ['^' badMuscles{ii} '[ ]?\d+$'])));

                if isempty(badDataIdx)
                    warning(['Label not found. No muscle removed. Make ' ...
                        'sure that you normalize the data first'])
                    return
                end

                badSubj.data.Data(:,badDataIdx) = nan;

                disp(['Removing (Setting NaN) of ' badMuscles{ii} ...
                    ' from Subject: ' badSubj.subData.ID])

            end

        end

    end




    methods(Static)

        [figHandle,allData] = ...
            plotGroupedSubjectsTimeCourse(adaptDataList,label, ...
            removeBiasFlag,plotIndividualsFlag,condList,earlyNumber, ...
            lateNumber,exemptLast,legendNames)

        %Will deprecate, use plotGroupedSubjectsBars instead.
        [figHandle,allData] = plotGroupedSubjects(adaptDataList,label, ...
            removeBiasFlag,plotIndividualsFlag,condList,earlyNumber, ...
            lateNumber,exemptLast,legendNames)

        [figHandle,allData] = plotGroupedSubjectsBars(adaptDataList, ...
            label,removeBiasFlag,plotIndividualsFlag,condList, ...
            earlyNumber,lateNumber,exemptLast,legendNames, ...
            significanceThreshold,plotHandles,colors)

        varargout = plotAvgTimeCourse(adaptDataList,params,conditions, ...
            binwidth,trialMarkerFlag,indivFlag,indivSubs,colorOrder, ...
            biofeedback,removeBiasFlag,groupNames,medianFlag, ...
            plotHandles,alignEnd,alignIni)

        figHandle = scatterPlotLab(adapDataList,labels,conditionIdxs, ...
            figHandle,marker,binSize,trajectoryColor,removeBias,addID)

        figHandle = Correlations(adapDataList, results,epochx,epochy, ...
            param1,groups,colorOrder,type)

        function [fh,ph,allData] = ...
            plotGroupedTimeAndBars(adaptDataGroups,labels,conds, ...
            binwidth,trialMarkerFlag,indivFlag,indivSubs,colorOrder, ...
            biofeedback,removeBiasFlag,groupNames,medianFlag, ...
            plotHandles,numberOfStrides)
            %PLOTGROUPEDTIMEANDBARS Plot group time courses next to bars.
            %
            %   Per label, draws the group time courses with
            % PLOTAVGTIMECOURSE (2/3 of the width) and the group bars with
            % GROUPADAPTATIONDATA.PLOTMULTIPLEGROUPSBARS (1/3), at a
            % significance threshold of 0.05 and without bias removal.
            %
            % Inputs:
            %   adaptDataGroups - cell array of groupAdaptationData objects
            %   labels          - parameters to plot
            %   conds           - conditions to plot
            %   binwidth        - strides per time-course point
            %   trialMarkerFlag - passed to PLOTAVGTIMECOURSE
            %   indivFlag       - plot individual subjects
            %   indivSubs       - passed to PLOTAVGTIMECOURSE
            %   colorOrder      - group colors (default color_palette)
            %   biofeedback     - passed to PLOTAVGTIMECOURSE
            %   removeBiasFlag  - ignored: bias removal is disallowed
            %   groupNames      - group names for the legend
            %   medianFlag      - use medians
            %   plotHandles     - ignored
            %   numberOfStrides - stride groups for the bars; the second one
            %                     sets the end alignment
            %
            % Outputs:
            %   fh      - figure handle
            %   ph      - M x 2 axes handles
            %   allData - data from PLOTMULTIPLEGROUPSBARS
            %
            % Toolbox Dependencies: None
            %
            % See also PLOTAVGTIMECOURSE,
            %   GROUPADAPTATIONDATA.PLOTMULTIPLEGROUPSBARS.

            fh = figure;

            M = length(labels);
            clear ph
            for ii = 1:M
                ph(ii,1) = subplot(M,3,[1:2]+3*(ii-1));
                ph(ii,2) = subplot(M,3,[3]+3*(ii-1));
            end

            %Defaults:
            plotHandles = []; %Not allowed
            if nargin < 8 || isempty(colorOrder)
                colorScheme
                colorOrder = color_palette;
            end
            plotIndividualsFlag = indivFlag;
            legendNames = [];
            significanceThreshold = 0.05;
            removeBiasFlag = 0; %Disallowing removeBiasFlag
            significancePlotMatrix = [];
            alignEnd = abs(numberOfStrides(2));
            signifPlotMatrixConds = [];
            exemptFirst = 1;
            exemptLast = 5;

            %Time courses:
            adaptData = cellfun(@(x) x.adaptData,adaptDataGroups, ...
                'UniformOutput',false);
            fh = adaptationData.plotAvgTimeCourse(adaptData, ...
                labels,conds,binwidth,trialMarkerFlag,indivFlag, ...
                indivSubs,colorOrder,biofeedback,removeBiasFlag, ...
                groupNames,medianFlag,ph(:,1),alignEnd);

            %Add bars:
            [fh,allData] = ...
                groupAdaptationData.plotMultipleGroupsBars( ...
                adaptDataGroups,labels,removeBiasFlag, ...
                plotIndividualsFlag,conds,numberOfStrides,exemptFirst, ...
                exemptLast,groupNames,significanceThreshold,ph(:,2), ...
                colorOrder,significancePlotMatrix,medianFlag, ...
                signifPlotMatrixConds);

            for ii = 1:M
                subplot(ph(ii,2));
                grid on
                aa = axis;
                subplot(ph(ii,1));
                grid on
                ab = axis;
                axis([ab(1:2) aa(3:4)])
            end
        end

        function [fh,ph,allData] = ...
            plotGroupedTimeAndEpochBars(adaptDataGroups,labels,eps, ...
            binwidth,trialMarkerFlag,indivFlag,indivSubs,colorOrder, ...
            biofeedback,groupNames,medianFlag,removeBaseEpochFlag, ...
            alignEnd,significanceThreshold,posthocGroupFlag, ...
            posthocEpochFlag,posthocGroupByEpochFlag, ...
            posthocEpochByGroupFlag);
            %PLOTGROUPEDTIMEANDEPOCHBARS Group time courses and epoch bars.
            %
            %   Per label, draws the group time courses with
            % PLOTAVGTIMECOURSE (2/3 of the width) and the epoch bars with
            % GROUPADAPTATIONDATA.PLOTMULTIPLEEPOCHBARS (1/3). Bad strides
            % are removed first and, optionally, the baseline epoch.
            %
            % Inputs:
            %   adaptDataGroups         - cell array of groupAdaptationData
            %                             objects
            %   labels                  - parameters to plot
            %   eps                     - epoch dataset created with
            %                             defineEpochs
            %   binwidth                - strides per time-course point
            %   trialMarkerFlag         - passed to PLOTAVGTIMECOURSE
            %   indivFlag               - plot individual subjects
            %   indivSubs               - passed to PLOTAVGTIMECOURSE
            %   colorOrder              - group colors (default
            %                             color_palette)
            %   biofeedback             - passed to PLOTAVGTIMECOURSE
            %   groupNames              - group names for the legend
            %   medianFlag              - use medians
            %   removeBaseEpochFlag     - 1 to remove the first epoch as
            %                             baseline
            %   alignEnd                - passed to PLOTAVGTIMECOURSE
            %   significanceThreshold   - p-value threshold for the bars
            %   posthocGroupFlag        - post-hoc across groups
            %   posthocEpochFlag        - post-hoc across epochs
            %   posthocGroupByEpochFlag - post-hoc across groups within
            %                             epochs
            %   posthocEpochByGroupFlag - post-hoc across epochs within
            %                             groups
            %
            % Outputs:
            %   fh      - figure handle
            %   ph      - M x 2 axes handles
            %   allData - data from PLOTMULTIPLEEPOCHBARS
            %
            % Toolbox Dependencies: None
            %
            % See also PLOTAVGTIMECOURSE,
            %   GROUPADAPTATIONDATA.PLOTMULTIPLEEPOCHBARS.

            fh = figure;



            M = length(labels);
            clear ph
            for ii = 1:M
                ph(ii,1) = subplot(M,3,[1:2]+3*(ii-1));
                ph(ii,2) = subplot(M,3,[3]+3*(ii-1));
            end

            %Defaults:
            if nargin < 8 || isempty(colorOrder)
                colorScheme
                colorOrder = color_palette;
            end

            conds = unique(eps.Condition,'stable');
            % numberOfStrides=eps.Stride_No;
            % for i=1:length(numberOfStrides)
            %     if ~eps.EarlyOrLate(i)
            %         numberOfStrides(i)=-1*numberOfStrides(i);%last strides
            %     end
            % end
            plotIndividualsFlag = indivFlag;
            % significanceThreshold=[];%.05;

            %alignEnd=abs(numberOfStrides(2));

            %exemptFirst=1;
            %exemptLast=5;

            set(ph,'ActivePositionProperty','outerposition')
            %Time courses:
            for ii = 1:length(adaptDataGroups)
                adaptDataGroups{ii} = ...
                    adaptDataGroups{ii}.removeBadStrides();
                if removeBaseEpochFlag == 1
                    adaptDataGroups2{ii} = ...
                        adaptDataGroups{ii}.removeBaselineEpoch(eps(1, ...
                        :),[]);
                else
                    adaptDataGroups2{ii} = adaptDataGroups{ii};
                end

            end
            adaptData = cellfun(@(x) x.adaptData,adaptDataGroups2, ...
                'UniformOutput',false);
            fh = adaptationData.plotAvgTimeCourse(adaptData, ...
                labels,conds,binwidth,trialMarkerFlag,indivFlag, ...
                indivSubs,colorOrder,biofeedback,0,groupNames, ...
                medianFlag,ph(:,1),alignEnd);
            for pl = 1:size(ph,1)
                hold(ph(pl,1))
                title(ph(pl,1),ph(pl,1).YLabel.String);
                ylabel(ph(pl,1),{''})
            end

            %set(ph(:,2),'Clipping','off')
            %Add bars:
            [fh,allData] = ...
                groupAdaptationData.plotMultipleEpochBars( ...
                adaptDataGroups,labels,eps,plotIndividualsFlag, ...
                groupNames,ph(:,2),colorOrder,medianFlag, ...
                significanceThreshold,posthocGroupFlag,posthocEpochFlag, ...
                posthocGroupByEpochFlag,posthocEpochByGroupFlag, ...
                removeBaseEpochFlag);
            for ii = 1:M
                subplot(ph(ii,2));
                grid on
                aa = axis;
                subplot(ph(ii,1));
                grid on
                ab = axis;
                axis([ab(1:2) aa(3:4)])
            end
            set(ph,'FontSize',16,'TitleFontSizeMultiplier',1.1,'XGrid', ...
                'off','YGrid','off');
            set(ph(1:end-1,:),'XTickLabel',{''})
            set(fh,'Color',[1 1 1]);
            %ph(1,1).Legend=ph(end,1).Legend;%ph(end,1).Legend

        end

        function groupData = createGroupAdaptData(adaptDataList, ...
            parametersToKeep, rmvDatlog)
            %CREATEGROUPADAPTDATA Load subjects into a groupAdaptationData.
            %
            %   Loads each file and, if the name is not found, retries with
            % 'Params' and 'params' appended.
            %
            % Inputs:
            %   adaptDataList    - cell array of file names (SubID or
            %                      SubIDparams), e.g. {'AUC01V01params.mat',
            %                      'AUC02V01params.mat'}
            %   parametersToKeep - labels to keep, to make the object
            %                      lighter and avoid running out of memory
            %                      (default: all)
            %   rmvDatlog        - remove the datalog to save storage
            %                      (default true)
            %
            % Outputs:
            %   groupData - groupAdaptationData object
            %
            % Toolbox Dependencies: None
            %
            % Example:
            %   groupData = adaptationData.createGroupAdaptData( ...
            %       {'X1params', 'X2params', 'X3params'});
            %
            % See also GROUPADAPTATIONDATA.


            if nargin < 3 || isempty(rmvDatlog)
                rmvDatlog = true;
            end
            for ii = 1:length(adaptDataList)
                try
                    a = load(adaptDataList{ii});
                catch ME
                    warning(['Could not find filename as provided. ' ...
                        'Trying alternative spellings.'])
                    try
                        a = load([adaptDataList{ii} 'Params']);
                    catch
                        try
                            a = load([adaptDataList{ii} 'params']);
                        catch
                            warning('Alternative spellings failed too.')
                            throw(ME)
                        end
                    end
                end
                if rmvDatlog && isprop(a.adaptData.metaData,'datlog')
                    a.adaptData.metaData.datlog = {};
                end
                data{ii} = a.('adaptData');
                %valid parameters given, now reduce it to only keep the
                %parameters given.
                if nargin >= 2 && ~isempty(parametersToKeep)
                    data{ii} = data{ii}.reduce(parametersToKeep);
                end
                ID{ii} = a.('adaptData').subData.ID;
                clear a %maybe helps with memory
            end
            groupData = groupAdaptationData(ID,data);
        end

        function [veryEarlyPoints,earlyPoints,latePoints,pEarly,pLate, ...
            pChange,pSwitch] = getGroupedData(adaptDataList,label,conds, ...
            removeBiasFlag,earlyNumber,lateNumber,exemptLast);
            %GETGROUPEDDATA Get early/late data for a group of subjects.
            %
            %   Loads the subjects into a groupAdaptationData and returns
            % the first 3, first earlyNumber and last lateNumber strides of
            % each condition, plus paired t-test p-values (single parameter
            % only).
            %
            % Inputs:
            %   adaptDataList  - cell array of subject file names
            %   label          - one parameter label
            %   conds          - condition names
            %   removeBiasFlag - bias removal flag
            %   earlyNumber    - strides in the early set
            %   lateNumber     - strides in the late set
            %   exemptLast     - strides skipped at the end
            %
            % Outputs:
            %   veryEarlyPoints - data of the first 3 strides
            %   earlyPoints     - data of the early strides
            %   latePoints      - data of the late strides
            %   pEarly          - conditions x conditions p-values of the
            %                     early points
            %   pLate           - conditions x conditions p-values of the
            %                     late points
            %   pChange         - p-value of the early-to-late change in
            %                     each condition
            %   pSwitch         - p-value of the change from the end of a
            %                     condition to the start of the next
            %
            % Toolbox Dependencies: Statistics and Machine Learning Toolbox
            %
            % See also GROUPADAPTATIONDATA.GETGROUPEDDATA, TTEST.

            if ~(isa(label,'char') || ...
                    (isa(label,'cell') && length(label) == 1 && ...
                    (isa(label{1},'char'))))
                % TODO: this is NOT true (?); fix
                error('adaptationData:getGroupedData', ...
                    'Only one parameter can be retrieved at a time.');
            end

            %Create a groupAdaptationData object and use it to get the
            %requested data in matrix form:
            groupData = adaptationData.createGroupAdaptData(adaptDataList);
            data = groupData.getGroupedData(label,conds,removeBiasFlag, ...
                [3,earlyNumber,-lateNumber],0,exemptLast);
            earlyPoints     = data{2};
            veryEarlyPoints = data{1};
            latePoints      = data{3};

            %Compute some stats (this may only work properly if
            %length(label)==1)
            if length(label) > 1
                pEarly  = [];
                pLate   = [];
                pChange = [];
                pSwitch = [];
            else
                %Averaging across strides
                aux1    = squeeze(mean(earlyPoints, 2, 'omitnan'));
                aux2    = squeeze(mean(latePoints, 2, 'omitnan'));
                pSwitch = [];
                for ii = 1:size(aux1,1) %For all conditions requested
                    for jj = 1:size(aux1,1)
                        if ii ~= jj
                            %Testing early points across all conds
                            [~,pEarly(ii,jj)] = ...
                                ttest(aux1(ii,:),aux1(jj,:));
                            %Testing late points across all conds
                            [~,pLate(ii,jj)] = ttest(aux2(ii,:),aux2(jj,:));
                        else
                            pEarly(ii,jj) = NaN;
                            pLate(ii,jj) = NaN;
                        end
                    end
                    %Testing changes within each condition
                    [~,pChange(ii)] = ttest(aux1(ii,:),aux2(ii,:));
                    if ii > 1
                        %Testing changes from end of one condition to start
                        %of the next
                        [~,pSwitch(ii-1)] = ttest(aux2(ii-1,:),aux1(ii,:));
                    end
                end
            end
        end

        function this = loadobj(this)
            %LOADOBJ Hide the date of birth when loading an object.
            %
            %   If the subject data contains a date of birth, warns,
            % replaces it by the age at the experiment (in years) and keeps
            % all other subject data. Save the object again to avoid the
            % warning.
            %
            % Inputs:
            %   this - adaptationData object being loaded
            %
            % Outputs:
            %   this - adaptationData object without the date of birth
            %
            % Toolbox Dependencies: None

            if ~isempty(this.subData.dateOfBirth)
                warning('adaptData:subjectDOB', ...
                    ['Subject data contains DOB information for ' ...
                    'subject ' this.subData.ID '. Data will be ' ...
                    'hidden. You should overwrite (save) your file ' ...
                    'with this new version to prevent this warning in ' ...
                    'the future. Please check that all other ' ...
                    'information is intact before overwriting.'])
                %Determine age (in months):
                age = round(this.metaData.date.timeSince( ...
                    this.subData.dateOfBirth));
                %Scrub DOB from subject meta data, save age at experiment
                %time (in years):
                this.subData = subjectData([],this.subData.sex, ...
                    this.subData.dominantLeg,this.subData.dominantArm, ...
                    this.subData.height,this.subData.weight,age/12, ...
                    this.subData.ID);
            end
        end

        % function figHandle=groupedScatterPlot(adaptDataList,labels, ...
        %    conditionIdxs,binSize,figHandle,trajColors,removeBias)
        %
        %     if isa(adaptDataList,'cell')
        %         if ~isa(adaptDataList{1},'cell')
        %             adaptDataList={adaptDataList};
        %         end
        %     elseif isa(adaptDataList,'char')
        %         adaptDataList={{adaptDataList}};
        %     end
        %     Ngroups=length(adaptDataList);
        %
        %     if nargin<7 || isempty(removeBias)
        %         removeBias=0;
        %     end
        %     if nargin<5 || isempty(figHandle)
        %         figHandle=figure;
        %     else
        %         figure(figHandle);
        %         hold on
        %     end
        %     markerList={'x','o','.','+','*','s','v','^','d'};
        %     if nargin<3 || isempty(conditionIdxs)
        %         conditionIdxs=[];
        %     end
        %     if nargin<4 || isempty(binSize)
        %         binSize=[];
        %     end
        %     for g=1:Ngroups
        %         for i=1:length(adaptDataList{g})
        %             r=(i-1)/(length(adaptDataList{g})-1);
        %             if nargin<6 || isempty(trajColors)
        %                 trajColor=[1,0,0] + r*[-1,0,1];
        %             elseif iscell(trajColors)
        %                 trajColor=trajColors{i};
        %             elseif size(trajColors,2)==3
        %                 trajColor=trajColors( ...
        %                     mod(i,size(trajColors,1))+1,:);
        %             else
        %                 warning('Could not interpret trajecColors input')
        %                 trajColor='k';
        %             end
        %             this=adaptDataList{g}{i};
        %             fieldList=fields(this);
        %             a=this.(fieldList{1});
        %             % This gives the possibility to pass condition names
        %             % instead of the indexes for each subject, which
        %             % might be different
        %             if iscell(conditionIdxs)
        %                 conditionIdxs1=getConditionIdxsFromName(a, ...
        %                     conditionIdxs);
        %             else
        %                 conditionIdxs1=conditionIdxs;
        %             end
        %             figHandle=scatterPlotLab(adaptDataList,labels, ...
        %                 conditionIdxs,figHandle, ...
        %                 markerList{mod(i,length(markerList))+1}, ...
        %                 binSize,trajColor,removeBias,1);
        %                figHandle=scatterPlotLab(adaptDataList,labels, ...
        %                 conditionIdxs,figHandle,markerList,binSize,[], ...
        %                 removeBias,1);
        %         end
        %     end
        %
        % end

        [figHandle,allData] = plotGroupedSubjectsBarsv2(adaptDataList, ...
            label,removeBiasFlag,plotIndividualsFlag,condList, ...
            numberOfStrides,exemptFirst,exemptLast,legendNames, ...
            significanceThreshold,plotHandles,colors,medianFlag)
    end %static methods

end
