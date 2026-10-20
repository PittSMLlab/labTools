classdef groupAdaptationData
    %GROUPADAPTATIONDATA Contain the adaptation data of a group of subjects.
    %
    %   groupAdaptationData holds the adaptationData objects of a group of
    % subjects and applies analyses and plots to all of them at once. The
    % methods are grouped in this file as queries (conditions, parameters,
    % stride counts), modifiers (bias removal, normalization, renaming,
    % subject selection), grouped data access, plots, and statistics.
    %
    % groupAdaptationData properties:
    %   ID        - cell array of strings listing subject IDs in the group
    %   adaptData - cell array of adaptationData objects
    %   groupID   - group identifier (dependent)
    %   subjectData - alias of adaptData (dependent)
    %
    % Toolbox Dependencies: Statistics and Machine Learning Toolbox
    %
    % See also EXPERIMENTMETADATA, SUBJECTDATA, ADAPTATIONDATA.

    properties
        % cell array of strings listing subject IDs in the group
        % TODO: should be a dependent property
        ID
        % cell array of adaptationData objects
        % TODO: should be called 'subjectData'
        adaptData
    end

    properties (Dependent)
        groupID
        subjectData
    end

    properties (Hidden)
        hiddenID = '';
    end

    methods
        %% Constructor
        function this = groupAdaptationData(ID,data,groupID)
            %GROUPADAPTATIONDATA Construct a group of subjects.
            %
            %   group = groupAdaptationData(ID, data, groupID) stores the
            % subject IDs and their adaptationData objects, then checks the
            % conditions common to all subjects and their order.
            %
            % Inputs:
            %   ID      - cell array of subject IDs
            %   data    - cell array of adaptationData objects, one per ID
            %   groupID - (optional) group identifier; currently not stored
            %             (see NOTE)
            %
            % Outputs:
            %   this - groupAdaptationData object
            %
            % NOTE: If ID and data differ in length, or data holds anything
            %       other than adaptationData objects, the object is left
            %       empty. groupID is assigned to a local variable, so
            %       groupID falls back to the first character of the first
            %       subject ID.
            %
            % Toolbox Dependencies: None
            %
            % See also ADAPTATIONDATA, GETCOMMONCONDITIONS,
            %          CHECKCOMMONCONDITIONORDER.

            if nargin > 1 && length(ID) == length(data)
                boolFlag = false(1,length(data));
                for ii = 1:length(data)
                    boolFlag(ii) = isa(data{ii},'adaptationData');
                end
                if all(boolFlag)
                    this.ID = ID;
                    this.adaptData = data;
                end
            end

            if nargin < 3 || isempty(groupID)
                %nop
            else
                hiddenID = groupID;
            end

            %Check that condition ordering is the same:
            [conditions,nonCommonConditions] = getCommonConditions(this);
            condOrder = this.checkCommonConditionOrder(conditions);
            %To do: check and display minimum number of strides per common
            %condition
        end

        %% Other Functions
        function out = get.subjectData(this)
            %GET.SUBJECTDATA Return the adaptationData objects of the group.
            %
            %   Alias of the adaptData property.
            %
            % Inputs:
            %   this - groupAdaptationData object
            %
            % Outputs:
            %   out - cell array of adaptationData objects
            %
            % Toolbox Dependencies: None
            %
            % See also ADAPTATIONDATA.

            out = this.adaptData;
        end

        function [conditions,nonCommonConditions] = ...
            getCommonConditions(this,subs)
            %GETCOMMONCONDITIONS Return conditions common to all subjects.
            %
            %   [conditions, nonCommonConditions] =
            % getCommonConditions(this, subs) lists the condition names
            % present for every selected subject, and warns about conditions
            % that are missing for some of them. Names are compared
            % case-insensitively.
            %
            % Inputs:
            %   this - groupAdaptationData object
            %   subs - indices of the subjects to use, or a cell array of
            %          their IDs (default: all)
            %
            % Outputs:
            %   conditions          - cell array of condition names common
            %                         to all selected subjects (as named for
            %                         the first subject)
            %   nonCommonConditions - cell array of lower-case condition
            %                         names found for some but not all
            %                         subjects
            %
            % Toolbox Dependencies: None
            %
            % See also GETALLCONDITIONS, CHECKCOMMONCONDITIONORDER.

            if nargin < 2 || isempty(subs)
                subs = 1:length(this.ID);
            else
                if isa(subs,'cell')
                    subs = find(ismember(this.ID,subs));
                end
            end
            conditions = this.adaptData{subs(1)}.metaData.conditionName;
            conditions = conditions(~cellfun('isempty',conditions));
            for s = 2:length(subs)
                conds = this.adaptData{subs(s)}.metaData.conditionName;
                conds = conds(~cellfun('isempty',conds));
                %check if current subject had conditions other than the rest
                %for c=1:length(conds)
                %    if ~ismember(lower(conds(c)),lower(conditions))
                %        %Subs.(abrevGroup).conditions{end+1}=conditions{c};
                %        disp(['Warning: ' this.ID{subs(s)} ...
                %    ' performed ' conds{c} ...
                %    ', but it was not performed by all subjects.'])
                %    end
                %end
                %check if current subject didn't have a condition that the
                %rest had
                for c = 1:length(conditions)
                    if ~ismember(lower(conditions(c)),lower(conds)) && ...
                            ~isempty(conditions{c})
                        %disp(['Warning: ' this.ID{subs(s)} ...
                        %    ' did not perform ' ...
                        %    conditions{c} ' but '
                        %    strjoin(this.ID(subs(1:s-1)), ...
                        %    ', ') ' did.'])
                        conditions{c} = '';
                    end
                end
                %refresh conditions by removing empty cells (if you remove
                %them above, the for loop doesn't work any more)
                conditions = conditions(~cellfun('isempty',conditions));
            end
            allConditions = getAllConditions(this,subs);
            nonCommonConditions = setdiff(lower(allConditions), ...
                lower(conditions));
            if ~isempty(nonCommonConditions)
                warning('groupAdaptData:nonCommonConds', ...
                    'Found some non-common conditions across subjects')
                disp(nonCommonConditions')
            end
        end

        function commonOrder = checkCommonConditionOrder(this,conditions)
            %CHECKCOMMONCONDITIONORDER Check the common condition order.
            %
            %   commonOrder = checkCommonConditionOrder(this, conditions)
            % compares each subject's condition order with the median order
            % and warns if any subject differs.
            %
            % Inputs:
            %   this       - groupAdaptationData object
            %   conditions - (optional) cell array of condition names
            %                (default: the common conditions)
            %
            % Outputs:
            %   commonOrder - median order of the conditions across
            %                 subjects, or [] if any subject differs
            %
            % Toolbox Dependencies: None
            %
            % See also GETCOMMONCONDITIONS,
            %          EXPERIMENTMETADATA/CHECKCONDITIONORDER.

            if nargin < 2 || isempty(conditions)
                conditions = this.getCommonConditions;
            end
            for ii = 1:length(this.adaptData)
                order(ii,:) = ...
                    this.adaptData{ii}.metaData.checkConditionOrder( ...
                    conditions,true);
            end
            commonOrder = median(order);
            badFlag     = false;
            for ii = 1:length(this.adaptData)
                if any(order(ii,:) ~= commonOrder)
                    warning([ ...
                        'Conditions are not in the same order for all ' ...
                        'subjects in ' ...
                        'the group: subject''s ' num2str( ...
                        ii) ' order is different from the median ' ...
                        'order. This will ' ...
                        'be a problem. Fix it.'])
                    badFlag = true;
                end
            end
            if badFlag
                commonOrder = [];
            end
        end

        function conditions = getAllConditions(this,subs)
            %GETALLCONDITIONS Return all condition names found in the group.
            %
            % Inputs:
            %   this - groupAdaptationData object
            %   subs - indices of the subjects to use, or a cell array of
            %          their IDs (default: all)
            %
            % Outputs:
            %   conditions - sorted cell array of unique lower-case
            %                condition names
            %
            % Toolbox Dependencies: None
            %
            % See also GETCOMMONCONDITIONS.

            if nargin < 2 || isempty(subs)
                subs = 1:length(this.ID);
            else
                if isa(subs,'cell')
                    subs = find(ismember(this.ID,subs));
                end
            end
            conditions = {};
            for s = 1:length(subs)
                conditions = ...
                    [conditions ...
                    lower(this.adaptData{subs(s)}.metaData.conditionName)];
            end
            conditions = conditions(~cellfun('isempty',conditions));
            conditions = unique(conditions);
        end

        function [parameters,descriptions] = getCommonParameters(this,subs)
            %GETCOMMONPARAMETERS Return parameters common to all subjects.
            %
            %   [parameters, descriptions] = getCommonParameters(this, subs)
            % lists the parameter labels present for every selected subject
            % and displays a warning for each parameter that is missing for
            % some subject.
            %
            % Inputs:
            %   this - groupAdaptationData object
            %   subs - indices of the subjects to use, or a cell array of
            %          their IDs (default: all)
            %
            % Outputs:
            %   parameters   - cell array of parameter labels common to all
            %                  selected subjects
            %   descriptions - cell array of the matching descriptions
            %
            % Toolbox Dependencies: None
            %
            % See also GETALLPARAMETERS, ADAPTATIONDATA/GETPARAMETERLIST.

            if nargin < 2 || isempty(subs)
                subs = 1:length(this.ID);
            else
                if isa(subs,'cell')
                    subs = find(ismember(this.ID,subs));
                end
            end
            [parameters,descriptions] = this.adaptData{1}.getParameterList;
            for s = 2:length(subs)
                params = this.adaptData{subs(s)}.getParameterList;
                %check if current subject had parameters other than the rest
                for p = 1:length(params)
                    if ~ismember(params(p),parameters)
                        disp(['Warning: ' this.ID{subs(s)} ' has ' ...
                            params{p} ...
                            ', but it was not computed for all subjects.'])
                    end
                end
                %check if current subject didn't have a parameter that the
                %rest had
                for p = 1:length(parameters)
                    if ~ismember(parameters(p),params)
                        disp(['Warning: '  parameters{p} ...
                            'was not computed for' ...
                            this.ID{subs(s)} ', but was for ' strjoin( ...
                            this.ID(1:subs(1:s-1)),', ') '.'])
                        parameters{p} = '';
                    end
                end
                %refresh parameters by removing empty cells (if you remove
                %them above, the for loop doesn't work any more)
                inds         = find(~cellfun('isempty',parameters));
                parameters   = parameters(inds);
                descriptions = descriptions(inds);
            end
        end

        function [parameters,descriptions] = getAllParameters(this,subs)
            %GETALLPARAMETERS Return all parameters found in the group.
            %
            % Inputs:
            %   this - groupAdaptationData object
            %   subs - indices of the subjects to use, or a cell array of
            %          their IDs (default: all)
            %
            % Outputs:
            %   parameters   - sorted cell array of unique parameter labels
            %   descriptions - cell array of the matching descriptions
            %
            % NOTE: The loop indexes adaptData with its own counter, so subs
            %       only sets how many subjects are read, not which ones.
            %
            % Toolbox Dependencies: None
            %
            % See also GETCOMMONPARAMETERS, ADAPTATIONDATA/GETPARAMETERLIST.

            if nargin < 2 || isempty(subs)
                subs = 1:length(this.ID);
            else
                if isa(subs,'cell')
                    subs = find(ismember(this.ID,subs));
                end
            end
            allParams = {};
            allDesc   = {};
            for s = 1:length(subs)
                [parameters,descriptions] = ...
                    this.adaptData{s}.getParameterList;
                allParams = [allParams(:); parameters];
                allDesc   = [allDesc(:); descriptions];
            end
            [parameters,idx] = unique(allParams);
            descriptions = allDesc(idx);
        end

        function labelList = getLabelsThatMatch(this,exp)
            %GETLABELSTHATMATCH Return parameter labels matching a pattern.
            %
            % Inputs:
            %   this - groupAdaptationData object
            %   exp  - regular expression to match against parameter labels
            %
            % Outputs:
            %   labelList - cell array of matching parameter labels
            %
            % Toolbox Dependencies: None
            %
            % See also GETALLPARAMETERS, REGEXP.

            labelList = this.getAllParameters;
            flags     = cellfun(@(x) ~isempty(x),regexp(labelList,exp));
            labelList = labelList(flags);
        end

        function gID = get.groupID(this)
            %GET.GROUPID Return the group identifier.
            %
            %   Returns the hidden ID if set, otherwise the first character
            % of the first subject's ID.
            %
            % Inputs:
            %   this - groupAdaptationData object
            %
            % Outputs:
            %   gID - group identifier
            %
            % Toolbox Dependencies: None

            if ~isempty(this.hiddenID)
                gID = this.hiddenID;
            else
                %Using first char in first subjects' ID as group ID.
                gID = this.ID{1}(1);
            end
        end

        function [nStrides,labels] = getNumStridesInCond(this,conds)
            %GETNUMSTRIDESINCOND Count strides per subject and condition.
            %
            % Inputs:
            %   this  - groupAdaptationData object
            %   conds - condition name or cell array of condition names
            %
            % Outputs:
            %   nStrides - subjects x conditions matrix of stride counts
            %   labels   - cell array of the condition names
            %
            % Toolbox Dependencies: None
            %
            % See also ADAPTATIONDATA/GETINDSINCONDITION.

            nsubs = length(this.ID);
            if iscell(conds)
                nconds = length(conds);
            else
                nconds = 1;
                conds  = {conds};
            end
            nStrides = NaN(nsubs,nconds);
            labels   = conds;

            for s = 1:nsubs
                for c = 1:nconds
                    nStrides(s,c) = ...
                        length(cell2mat( ...
                        this.adaptData{s}.getIndsInCondition( ...
                        conds{c})));
                end
            end
        end

        function meanSub = getMeanSubject(this)
            %GETMEANSUBJECT Create an average subject (not implemented).
            %
            %   Always raises an Unimplemented error; the code after the
            % error is the unfinished implementation.
            %
            % Inputs:
            %   this - groupAdaptationData object
            %
            % Outputs:
            %   meanSub - adaptationData object of the group average
            %
            % NOTE: Needs getMinSharedNumberOfStrides to be finished first.
            %
            % Toolbox Dependencies: None
            %
            % See also GETMINSHAREDNUMBEROFSTRIDES.

            error('Unimplemented')
            %This requires finisihing getMinSharedNumberOfStrides
            commonConds  = this.getCommonConditions;
            commonParams = this.getCommonParameters;
            commonStrides = this.getMinSharedNumberOfStrides(this, ...
                commonConds);
            data = getGroupedData(this,commonParams,commonConds,0, ...
                numberOfStrides,0,0); %No removal of bias, no exempt strides
            % TODO: fill meta data and subject data fields appropriately
            meanSub = adaptationData(this.adaptData{1}.metaData, ...
                this.adaptData{1}.subData,data);
        end

        function minNumStrides = getMinSharedNumberOfStrides(this, conds)
            %GETMINSHAREDNUMBEROFSTRIDES Unimplemented: min shared strides.
            %
            %   Always raises an Unimplemented error. The intended result is
            % the minimum number of strides that all subjects have for each
            % condition.
            %
            % Inputs:
            %   this  - groupAdaptationData object
            %   conds - (optional) condition names (default: the common
            %           conditions)
            %
            % Outputs:
            %   minNumStrides - minimum number of strides per condition
            %
            % Toolbox Dependencies: None
            %
            % See also GETMEANSUBJECT, GETNUMSTRIDESINCOND.

            error('Unimplemented')
            if nargin < 2 || isempty(conds)
                conds = this.getCommonConditions;
            end
            minNumStrides = nan(size(conds));
            for ii = 1:length(conds)
                minNumStrides(ii) = NaN; % placeholder
            end
        end

        function ageInMonths = getSubjectAgeAtExperimentDate(this)
            %GETSUBJECTAGEATEXPERIMENTDATE Return age at experiment date.
            %
            % Inputs:
            %   this - groupAdaptationData object
            %
            % Outputs:
            %   ageInMonths - age of each subject, as returned by
            %                 adaptationData/getSubjectAgeAtExperimentDate
            %
            % Toolbox Dependencies: None
            %
            % See also ADAPTATIONDATA/GETSUBJECTAGEATEXPERIMENTDATE.

            for ii = 1:length(this.ID)
                ageInMonths(ii) = ...
                    this.adaptData{ii}.getSubjectAgeAtExperimentDate;
            end
        end

        %Modifiers
        function newThis = cat(this,other)
            %CAT Concatenate two groups.
            %
            % Inputs:
            %   this  - groupAdaptationData object
            %   other - groupAdaptationData object
            %
            % Outputs:
            %   newThis - groupAdaptationData object with the subjects of
            %             both groups
            %
            % Toolbox Dependencies: None
            %
            % See also CATGROUPS.

            newThis = groupAdaptationData([this.ID other.ID], ...
                [this.adaptData other.adaptData]);
        end

        function newThis = removeBadStrides(this,markAsNaNflag)
            %REMOVEBADSTRIDES Remove bad strides from every subject.
            %
            %   Applies adaptationData/removeBadStrides to each subject.
            %
            % Inputs:
            %   this          - groupAdaptationData object
            %   markAsNaNflag - (optional) see
            %                   adaptationData/removeBadStrides (default [])
            %
            % Outputs:
            %   newThis - groupAdaptationData object
            %
            % Toolbox Dependencies: None
            %
            % See also ADAPTATIONDATA/REMOVEBADSTRIDES.

            newThis = this;
            if nargin < 2 || isempty(markAsNaNflag)
                markAsNaNflag = [];
            end
            for ii = 1:length(this.ID)
                newThis.adaptData{ii} = ...
                    this.adaptData{ii}.removeBadStrides(markAsNaNflag);
            end
        end

        function newThis = markBadWhenMissingAny(this,labels)
            %MARKBADWHENMISSINGANY Mark strides bad if any label missing.
            %
            %   Applies adaptationData/markBadWhenMissingAny to each
            % subject.
            %
            % Inputs:
            %   this   - groupAdaptationData object
            %   labels - cell array of parameter labels
            %
            % Outputs:
            %   newThis - groupAdaptationData object
            %
            % Toolbox Dependencies: None
            %
            % See also ADAPTATIONDATA/MARKBADWHENMISSINGANY.

            newThis = this;
            for ii = 1:length(this.ID)
                newThis.adaptData{ii} = ...
                    this.adaptData{ii}.markBadWhenMissingAny(labels);
            end
        end

        function newThis = markBadWhenMissingAll(this,labels)
            %MARKBADWHENMISSINGALL Mark strides bad if all labels missing.
            %
            %   Applies adaptationData/markBadWhenMissingAll to each
            % subject.
            %
            % Inputs:
            %   this   - groupAdaptationData object
            %   labels - cell array of parameter labels
            %
            % Outputs:
            %   newThis - groupAdaptationData object
            %
            % Toolbox Dependencies: None
            %
            % See also ADAPTATIONDATA/MARKBADWHENMISSINGALL.

            newThis = this;
            for ii = 1:length(this.ID)
                newThis.adaptData{ii} = ...
                    this.adaptData{ii}.markBadWhenMissingAll(labels);
            end
        end

        function newThis = removeBias(this)
            %REMOVEBIAS Remove the baseline bias from every subject.
            %
            %   Applies adaptationData/removeBias to each subject.
            %
            % Inputs:
            %   this - groupAdaptationData object
            %
            % Outputs:
            %   newThis - groupAdaptationData object
            %
            % Toolbox Dependencies: None
            %
            % See also ADAPTATIONDATA/REMOVEBIAS.

            newThis = this;
            for ii = 1:length(this.ID)
                newThis.adaptData{ii} = this.adaptData{ii}.removeBias;
            end

        end

        function newThis = normalizeBias(this)
            %NORMALIZEBIAS Normalize the baseline bias of every subject.
            %
            %   Applies adaptationData/normalizeBias to each subject.
            %
            % Inputs:
            %   this - groupAdaptationData object
            %
            % Outputs:
            %   newThis - groupAdaptationData object
            %
            % Toolbox Dependencies: None
            %
            % See also ADAPTATIONDATA/NORMALIZEBIAS.

            newThis = this;
            for ii = 1:length(this.ID)
                newThis.adaptData{ii} = this.adaptData{ii}.normalizeBias;
            end

        end

        function newThis = normalizeToBaseline(this,labelPrefix,baseConds2)
            %NORMALIZETOBASELINE Normalize to a baseline condition.
            %
            %   Applies adaptationData/normalizeToBaseline to each subject.
            %
            % Inputs:
            %   this        - groupAdaptationData object
            %   labelPrefix - prefix(es) of the parameters to normalize
            %   baseConds2  - (optional) baseline conditions (default [])
            %
            % Outputs:
            %   newThis - groupAdaptationData object
            %
            % Toolbox Dependencies: None
            %
            % See also ADAPTATIONDATA/NORMALIZETOBASELINE.

            newThis = this;
            if nargin < 3
                baseConds2 = [];
            end
            for ii = 1:length(this.ID)
                newThis.adaptData{ii} = ...
                    this.adaptData{ii}.normalizeToBaseline(labelPrefix, ...
                    baseConds2);
            end

        end
        function this = normalizeToBaselineEpoch(this,labelPrefix, ...
            baseEpoch, ...
            noMinNormFlag)
            %NORMALIZETOBASELINEEPOCH Normalize to a baseline epoch.
            %
            %   Applies adaptationData/normalizeToBaselineEpoch to each
            % subject.
            %
            % Inputs:
            %   this          - groupAdaptationData object
            %   labelPrefix   - prefix(es) of the parameters to normalize
            %   baseEpoch     - baseline epoch definition
            %   noMinNormFlag - (optional) see
            %                   adaptationData/normalizeToBaselineEpoch
            %                   (default 0)
            %
            % Outputs:
            %   this - groupAdaptationData object
            %
            % Toolbox Dependencies: None
            %
            % See also ADAPTATIONDATA/NORMALIZETOBASELINEEPOCH.

            if nargin < 4 || isempty(noMinNormFlag)
                noMinNormFlag = 0;
            end
            for ii = 1:length(this.ID)
                this.adaptData{ii} = ...
                    this.adaptData{ii}.normalizeToBaselineEpoch( ...
                    labelPrefix, ...
                    baseEpoch,noMinNormFlag);
            end
        end

        function this = removeBaselineEpoch(this,baseEpoch,labels)
            %REMOVEBASELINEEPOCH Subtract a baseline epoch.
            %
            %   Applies adaptationData/removeBaselineEpoch to each subject.
            %
            % Inputs:
            %   this      - groupAdaptationData object
            %   baseEpoch - baseline epoch definition
            %   labels    - parameter labels to correct
            %
            % Outputs:
            %   this - groupAdaptationData object
            %
            % Toolbox Dependencies: None
            %
            % See also ADAPTATIONDATA/REMOVEBASELINEEPOCH.

            for ii = 1:length(this.ID)
                this.adaptData{ii} = ...
                    this.adaptData{ii}.removeBaselineEpoch(baseEpoch, ...
                    labels);
            end
        end

        function newThis = removeAltBias(this,condName,strideNo, ...
            exemptStrides, ...
            medianFlag,normalizeFlag)
            %REMOVEALTBIAS Remove an alternative bias from every subject.
            %
            %   Applies adaptationData/removeAltBias to each subject.
            %
            % Inputs:
            %   this          - groupAdaptationData object
            %   condName      - condition used to compute the bias
            %   strideNo      - number of strides used
            %   exemptStrides - strides skipped
            %   medianFlag    - (optional) 1 to use the median (default 0)
            %   normalizeFlag - (optional) see adaptationData/removeAltBias
            %                   (default [])
            %
            % Outputs:
            %   newThis - groupAdaptationData object
            %
            % Toolbox Dependencies: None
            %
            % See also ADAPTATIONDATA/REMOVEALTBIAS.

            newThis = this;
            if nargin < 5
                medianFlag = 0;
            end
            if nargin < 6
                normalizeFlag = [];
            end
            for ii = 1:length(this.ID)
                newThis.adaptData{ii} = ...
                    this.adaptData{ii}.removeAltBias(condName, ...
                    strideNo,exemptStrides,medianFlag,normalizeFlag);
            end
        end

        function newThis = renameParams(this,oldLabels,newLabels)
            %RENAMEPARAMS Rename parameters in every subject.
            %
            %   Applies adaptationData/renameParams to each subject.
            %
            % Inputs:
            %   this      - groupAdaptationData object
            %   oldLabels - cell array of current parameter labels
            %   newLabels - cell array of new parameter labels
            %
            % Outputs:
            %   newThis - groupAdaptationData object
            %
            % Toolbox Dependencies: None
            %
            % See also ADAPTATIONDATA/RENAMEPARAMS.

            for ii = 1:length(this.ID)
                this.adaptData{ii} = ...
                    this.adaptData{ii}.renameParams(oldLabels,newLabels);
            end
            newThis = this;
        end

        function newThis = renameConditions(this,oldNames,newNames)
            %RENAMECONDITIONS Rename conditions in every subject.
            %
            %   Replaces condition names in the metadata of every member of
            % the group. Only exact matches to the old names are replaced;
            % if no exact match is found nothing is replaced and the process
            % continues, with a warning (same as the adaptationData method).
            %
            % Inputs:
            %   this     - groupAdaptationData object
            %   oldNames - cell array of strings, or of cell arrays of
            %              strings with several alternative spellings
            %   newNames - cell array of strings
            %
            % Outputs:
            %   newThis - groupAdaptationData object
            %
            % Toolbox Dependencies: None
            %
            % See also EXPERIMENTMETADATA/REPLACECONDITIONNAMES.

            for ii = 1:length(this.ID)
                this.adaptData{ii}.metaData = ...
                    this.adaptData{ii}.metaData.replaceConditionNames( ...
                    oldNames,newNames);
            end
            newThis = this;
        end

        function newThis = medianFilter(this,N)
            %MEDIANFILTER Apply a median filter to every subject.
            %
            %   Applies adaptationData/medianFilter to each subject.
            %
            % Inputs:
            %   this - groupAdaptationData object
            %   N    - filter length in strides
            %
            % Outputs:
            %   newThis - groupAdaptationData object
            %
            % Toolbox Dependencies: None
            %
            % See also ADAPTATIONDATA/MEDIANFILTER.

            newThis = this;
            for ii = 1:length(this.adaptData)
                newThis.adaptData{ii} = this.adaptData{ii}.medianFilter(N);
            end
        end

        function newThis = addNewParameter(this,newParamLabel,funHandle, ...
            inputParameterLabels,newParamDescription)
            %ADDNEWPARAMETER Add a computed parameter to every subject.
            %
            %   Applies adaptationData/addNewParameter to each subject.
            %
            % Inputs:
            %   this                 - groupAdaptationData object
            %   newParamLabel        - label of the new parameter
            %   funHandle            - function handle that computes the
            %                          parameter
            %   inputParameterLabels - labels of the parameters passed to
            %                          funHandle
            %   newParamDescription  - description of the new parameter
            %
            % Outputs:
            %   newThis - groupAdaptationData object
            %
            % Toolbox Dependencies: None
            %
            % See also ADAPTATIONDATA/ADDNEWPARAMETER.

            newThis = this;
            for ii = 1:length(this.adaptData)
                newThis.adaptData{ii} = ...
                    this.adaptData{ii}.addNewParameter(newParamLabel, ...
                    funHandle, ...
                    inputParameterLabels,newParamDescription);
            end
        end

        function newThis = removeSubs(this,subList)
            %REMOVESUBS Remove subjects from the group.
            %
            %   IDs that are not in the group are skipped with a warning.
            %
            % Inputs:
            %   this    - groupAdaptationData object
            %   subList - cell array of subject IDs to remove
            %
            % Outputs:
            %   newThis - groupAdaptationData object without those subjects
            %
            % Toolbox Dependencies: None
            %
            % See also GETSUBGROUP.

            for sub = 1:length(subList)
                ii = find(strcmp(subList{sub},this.ID));
                if ~isempty(ii)
                    this.ID = this.ID([1:ii-1,ii+1:end]);
                    this.adaptData = this.adaptData([1:ii-1,ii+1:end]);
                else
                    warning(['Subject ' subList{sub} ...
                        ' could not be removed because it is not present'])
                end
            end
            newThis = this;
        end

        function newThis = getSubGroup(this,subList)
            %GETSUBGROUP Return a subgroup of subjects.
            %
            %   The subjects appear in the order of subList. An ID that is
            % not in the group raises groupAdaptationData:getSubGroup.
            %
            % Inputs:
            %   this    - groupAdaptationData object
            %   subList - cell array of subject IDs to keep
            %
            % Outputs:
            %   newThis - groupAdaptationData object with only those
            %             subjects
            %
            % Toolbox Dependencies: None
            %
            % See also REMOVESUBS.

            ii = nan(size(subList));
            for sub = 1:length(subList)
                jj = find(strcmp(subList{sub},this.ID));
                if ~isempty(jj)
                    ii(sub) = jj;
                else
                    error('groupAdaptationData:getSubGroup', ...
                        ['Tried fetching subject ' subList{sub} ...
                        ' but found no matching IDs.'])
                end
            end
            newThis = this;
            newThis.ID = newThis.ID(ii);
            newThis.adaptData = newThis.adaptData(ii);
        end

        %I/O
        function data = getAdaptData(this,subID)
            %GETADAPTDATA Return the adaptationData object of one subject.
            %
            % Inputs:
            %   this  - groupAdaptationData object
            %   subID - subject ID
            %
            % Outputs:
            %   data - adaptationData object, or [] if the subject is not in
            %          the group
            %
            % Toolbox Dependencies: None

            subInd = find(ismember(subID,this.ID));
            if subInd ~= 0
                data = this.adaptData{subInd};
            else
                data = [];
            end
        end

        function [inds,names] = getGroupedInds(this,conds, ...
            numberOfStrides, ...
            exemptFirst,exemptLast)
            %GETGROUPEDINDS Return stride indices of each stride group.
            %
            %   Calls adaptationData/getEarlyLateIdxs for every subject.
            %
            % Inputs:
            %   this            - groupAdaptationData object
            %   conds           - cell array of condition names
            %   numberOfStrides - strides per group: positive values take
            %                     the first N, negative the last N
            %   exemptFirst     - strides skipped at the start
            %   exemptLast      - strides skipped at the end
            %
            % Outputs:
            %   inds  - cell array, stride groups x subjects, of stride
            %           indices
            %   names - cell array of group names
            %
            % Toolbox Dependencies: None
            %
            % See also ADAPTATIONDATA/GETEARLYLATEIDXS, GETGROUPEDDATA.

            %Getting data for each subject in the list
            for subject = 1:length(this.adaptData)
                [inds(:,subject),names] = ...
                    this.adaptData{subject}.getEarlyLateIdxs(conds, ...
                    numberOfStrides, ...
                    exemptLast,exemptFirst);
            end
        end

        function [data,inds] = getGroupedData(this,label,conds, ...
            removeBiasFlag, ...
            numberOfStrides,exemptFirst,exemptLast,padWithNaNFlag)
            %GETGROUPEDDATA Return parameter values for groups of strides.
            %
            % Inputs:
            %   this            - groupAdaptationData object
            %   label           - parameter label(s)
            %   conds           - cell array of condition names
            %   removeBiasFlag  - true to remove the bias first
            %   numberOfStrides - strides per group: positive values take
            %                     the first N, negative the last N
            %   exemptFirst     - strides skipped at the start
            %   exemptLast      - strides skipped at the end
            %   padWithNaNFlag  - (optional) pad short groups with NaN
            %                     (default false)
            %
            % Outputs:
            %   data - cell array, one cell per stride group, of conditions
            %          x strides x labels x subjects arrays
            %   inds - stride indices (see GETGROUPEDINDS)
            %
            % Toolbox Dependencies: None
            %
            % See also GETGROUPEDINDS, GETGROUPEDDATAFROMINDS.

            if removeBiasFlag
                this = this.removeBias;
            end
            if nargin < 8 || isempty(padWithNaNFlag)
                padWithNaNFlag = false;
            end
            [inds,names] = getGroupedInds(this,conds,numberOfStrides, ...
                exemptFirst, ...
                exemptLast);
            data = getGroupedDataFromInds(this,inds,label,padWithNaNFlag);
        end

        function [data,validStrides,allData] = ...
            getEpochData(this,epochs,labels,padWithNaNFlag)
            %GETEPOCHDATA Return data from all subjects for each epoch.
            %
            % Inputs:
            %   this           - groupAdaptationData object
            %   epochs         - epoch definition table (from defineEpochs)
            %   labels         - parameter label or cell array of labels
            %   padWithNaNFlag - (optional) pad short epochs with NaN
            %                    (default false)
            %
            % Outputs:
            %   data         - labels x epochs x subjects array of epoch
            %                  values
            %   validStrides - epochs x subjects matrix of valid-stride
            %                  counts
            %   allData      - cell array, one cell per epoch, of strides x
            %                  labels x subjects arrays
            %
            % Toolbox Dependencies: None
            %
            % See also ADAPTATIONDATA/GETEPOCHDATA.

            %Manage inputs:
            if isa(labels,'char')
                labels = {labels};
            end
            if nargin < 4 || isempty(padWithNaNFlag)
                padWithNaNFlag = false;
            end
            data = nan(length(labels),length(epochs), ...
                length(this.ID));
            validStrides = nan(length(epochs),length(this.ID));
            allData1     = cell(length(epochs),length(this.ID));
            for ii = 1:length(this.ID)
                [data(:,:,ii),validStrides(:,ii),allData1(:,ii)] = ...
                    this.adaptData{ii}.getEpochData(epochs,labels, ...
                    padWithNaNFlag);
            end
            allData = cell(length(epochs),1);

            for jj = 1:length(epochs)
                allData{jj} = reshape(cell2mat(allData1(jj,:)), ...
                    epochs.Stride_No(jj), ...
                    length(labels),length(this.ID));
            end
        end

        function data = getGroupedDataFromInds(this,inds,label, ...
            padWithNaNFlag)
            %GETGROUPEDDATAFROMINDS Return values for stride indices.
            %
            % Inputs:
            %   this           - groupAdaptationData object
            %   inds           - cell array of stride indices (see
            %                    GETGROUPEDINDS)
            %   label          - parameter label(s)
            %   padWithNaNFlag - (optional) pad short groups with NaN
            %                    (default false)
            %
            % Outputs:
            %   data - cell array, one cell per stride group, of conditions
            %          x strides x labels x subjects arrays
            %
            % Toolbox Dependencies: None
            %
            % See also GETGROUPEDINDS, ADAPTATIONDATA/GETDATAFROMINDS.

            if nargin < 4 || isempty(padWithNaNFlag)
                padWithNaNFlag = false;
            end
            data   = cell(size(inds,1),1);
            nConds = size(inds{1,1},2);
            if isa(label,'cell')
                nLabs = length(label);
            else
                nLabs = 1;
            end
            nSubs = length(this.ID);
            %Initialize:
            for ii = 1:length(data)
                %Conds x strideGroups x labels x subs
                data{ii} = zeros(nConds,size(inds{ii,1},1),nLabs,nSubs);
            end
            %Alt: (using the inds data, so we are sure we are actually
            %getting the same strides when calling upon any function)
            for jj = 1:nSubs %For each sub
                allData = this.adaptData{jj}.getDataFromInds(inds(:,jj), ...
                    label, ...
                    padWithNaNFlag);
                for ii = 1:length(data) %For each strideGroup
                    data{ii}(:,:,:,jj) = allData{ii};
                end
            end

        end

        function [biasTM, biasOG] = getGroupedBias(this,label)
            %GETGROUPEDBIAS Return the baseline bias of each subject.
            %
            % Inputs:
            %   this  - groupAdaptationData object
            %   label - parameter label(s)
            %
            % Outputs:
            %   biasTM - labels x subjects matrix of treadmill biases
            %   biasOG - labels x subjects matrix of overground biases
            %
            % Toolbox Dependencies: None
            %
            % See also ADAPTATIONDATA/GETBIAS.

            for ii = 1:length(this.ID)
                [biasTM(:,ii),biasOG(:,ii)] = ...
                    this.adaptData{ii}.getBias(label);
            end
        end

        function [meanData,stdData] = ...
            getAvgGroupedData(this,label,conds, ...
            removeBiasFlag,numberOfStrides,exemptFirst,exemptLast)
            %GETAVGGROUPEDDATA Return mean and std of grouped strides.
            %
            %   Averages the output of GETGROUPEDDATA over strides.
            %
            % Inputs:
            %   this            - groupAdaptationData object
            %   label           - parameter label(s)
            %   conds           - cell array of condition names
            %   removeBiasFlag  - true to remove the bias first
            %   numberOfStrides - strides per group: positive values take
            %                     the first N, negative the last N
            %   exemptFirst     - strides skipped at the start
            %   exemptLast      - strides skipped at the end
            %
            % Outputs:
            %   meanData - conditions x stride groups x labels x subjects
            %              array of means over strides
            %   stdData  - same size array of standard deviations
            %
            % Toolbox Dependencies: None
            %
            % See also GETGROUPEDDATA.

            data = getGroupedData(this,label,conds,removeBiasFlag, ...
                numberOfStrides, ...
                exemptFirst,exemptLast);
            for ii = 1:length(data)
                %conds x strideGroups x parameters x subjects
                meanData(:,ii,:,:) = mean(data{ii}, 2, 'omitnan');
                stdData(:,ii,:,:) = std(data{ii}, [], 2, 'omitnan');
            end
        end

        function newThis = catGroups(this,other)
            %CATGROUPS Concatenate two groups.
            %
            %   Same as CAT.
            %
            % Inputs:
            %   this  - groupAdaptationData object
            %   other - groupAdaptationData object
            %
            % Outputs:
            %   newThis - groupAdaptationData object with the subjects of
            %             both groups
            %
            % Toolbox Dependencies: None
            %
            % See also CAT.

            newThis = groupAdaptationData([this.ID other.ID], ...
                [this.adaptData other.adaptData]);
        end
        %Visualization
        %Scatter
        function [fh,dataAll,idAll] = scatter(this, params, conditions)
            %SCATTER Scatter plot of two or three parameters.
            %
            %   Plots, for every subject and condition, the strides in the
            % space of the given parameters (one color per subject, one
            % marker per condition).
            %
            % Inputs:
            %   this       - groupAdaptationData object
            %   params     - cell array of two or three parameter labels
            %   conditions - cell array of condition names
            %
            % Outputs:
            %   fh      - figure handle
            %   dataAll - plotted values, one row per stride
            %   idAll   - cell array with the subject and condition of each
            %             row of dataAll
            %
            % NOTE: Any other number of parameters raises an error with an
            %       empty message.
            %
            % Toolbox Dependencies: None
            %
            % See also ADAPTATIONDATA/GETPARAMINCOND.

            fh = figure;
            hold on
            colorScheme
            colors = color_palette;
            marker = {'.','x','o','+','*','x'};
            if length(params) > 3 || length(params) < 2
                error('')
            end
            dataAll = [];
            idAll   = [];
            for jj = 1:length(conditions)
                for ii = 1:length(this.ID)
                    dd = this.adaptData{ii}.getParamInCond(params, ...
                        conditions{jj});
                    idAll = ...
                        [idAll repmat({[this.ID{ii} '_' ...
                        conditions{jj}]}, ...
                        1,size(dd,1))];
                    dataAll = [dataAll;dd];
                    switch length(params)
                        case 2
                            pp = plot(dd(:,1),dd(:,2),marker{jj}, ...
                                'Color', ...
                                colors(ii,:));
                            xlabel(params{1})
                            ylabel(params{2})
                        case 3
                            pp = plot3(dd(:,1),dd(:,2),dd(:,3), ...
                                marker{jj},'Color', ...
                                colors(ii,:));
                            xlabel(params{1})
                            ylabel(params{2})
                            zlabel(params{3})
                    end
                    if jj == 1
                        ppp(ii) = pp;
                    end
                end
                %Fake plots to have in legend
                p(jj) = plot(mean(dd(:,1), 'omitnan'), ...
                    mean(dd(:,2), 'omitnan'), ...
                    marker{jj},'Color',0.7*ones(1,3));
            end
            legend([p ppp],[conditions this.ID])
            idAll = idAll';
        end

        %TimeCourses
        function fh = plotAvgTimeCourse(this,params,conditions,binwidth, ...
            trialMarkerFlag,indivFlag,indivSubs,colorOrder,biofeedback, ...
            removeBiasFlag,groupNames,medianFlag,plotHandles)
            %PLOTAVGTIMECOURSE Plot the average time course of the group.
            %
            %   Forwards to adaptationData/plotAvgTimeCourse with the
            % subjects of this group.
            %
            % Inputs:
            %   this            - groupAdaptationData object
            %   params          - cell array of parameter labels
            %   conditions      - (optional) condition names (default: the
            %                     common conditions)
            %   binwidth        - (optional) bin width in strides
            %   trialMarkerFlag - (optional) mark trial boundaries
            %   indivFlag       - (optional) plot individual subjects
            %   indivSubs       - (optional) subjects to plot individually
            %   colorOrder      - (optional) plot colors
            %   biofeedback     - (optional) biofeedback information
            %   removeBiasFlag  - (optional) 1 to remove the bias (default
            %                     0)
            %   groupNames      - (optional) names of the groups
            %   medianFlag      - (optional) 1 to use the median
            %   plotHandles     - (optional) axes handles
            %
            % Outputs:
            %   fh - figure handle
            %
            % Toolbox Dependencies: None
            %
            % See also ADAPTATIONDATA/PLOTAVGTIMECOURSE.

            if nargin < 3 || isempty(conditions)
                conditions = this.getCommonConditions;
            end
            if nargin < 4 || isempty(binwidth)
                binwidth = [];
            end
            if nargin < 5
                trialMarkerFlag = [];
            end
            if nargin < 6
                indivFlag = [];
            end
            if nargin < 7
                indivSubs = [];
            end
            if nargin < 8
                colorOrder = [];
            end
            if nargin < 9
                biofeedback = [];
            end
            if nargin < 10
                removeBiasFlag = 0;%Default = noremoval;
            end
            if nargin < 11
                groupNames = [];
            end
            if nargin < 12
                medianFlag = [];
            end
            if nargin < 13
                plotHandles = [];
            end

            fh = adaptationData.plotAvgTimeCourse(this.adaptData,params, ...
                conditions, ...
                binwidth,trialMarkerFlag,indivFlag,indivSubs,colorOrder, ...
                biofeedback, ...
                removeBiasFlag,groupNames,medianFlag,plotHandles);

        end

        %Bars
        [figHandle,allData] = plotBars(this,label,removeBiasFlag, ...
            plotIndividualsFlag,condList,numberOfStrides,exemptFirst, ...
            exemptLast, ...
            legendNames,significanceThreshold,plotHandles,colors, ...
            signPlotMatrix);

        %Checkerboard:
        function [fh,ph,labels,dataE,dataRef] = ...
            plotCheckerboards(this,labelPrefix,epochs,fh,ph,refEpoch, ...
            flipLR, ...
            summFlag)
            %PLOTCHECKERBOARDS Plot checkerboards of epoch data.
            %
            %   Meant for parameters that end in 's1...s12' (as computed for
            % EMG and angles). The 's' must be included in the label
            % prefixes, to allow for other options too. One checkerboard is
            % drawn per epoch, optionally relative to a reference epoch.
            %
            % Inputs:
            %   this        - groupAdaptationData object
            %   labelPrefix - cell array of parameter label prefixes
            %   epochs      - epoch definition table (from defineEpochs)
            %   fh          - (optional) figure handle (default: new figure)
            %   ph          - (optional) axes handles, one per epoch
            %   refEpoch    - (optional) reference epoch subtracted from
            %                 every epoch
            %   flipLR      - (optional) true to flip left and right; 2 for
            %                 a symmetry plot
            %   summFlag    - (optional) name of the function that averages
            %                 across subjects (default 'nanmean')
            %
            % Outputs:
            %   fh      - figure handle
            %   ph      - axes handles
            %   labels  - parameter labels
            %   dataE   - epoch data (aligned if flipLR is set)
            %   dataRef - reference epoch data, or []
            %
            % Toolbox Dependencies: None
            %
            % See also GETCHECKERBOARDSDATA,
            %          ALIGNEDTIMESERIES/PLOTCHECKERBOARD.

            symmetryFlag = false;
            if nargin < 7 || isempty(flipLR)
                flipLR    = false;
                normalize = false;
            elseif flipLR == 2 %Codeword for doing symmetry plot
                %FlipLR is implicit in doing a symmetry plot
                flipLR       = false;
                symmetryFlag = true;
            else symmetryFlag = false;
            end

            %First, get epoch data:
            %Padding with NaNs
            [dataE,labels] = this.getPrefixedEpochData(labelPrefix, ...
                epochs,true);
            Np = size(labels,1);
            dataE = reshape(dataE,Np,length(labelPrefix),size(dataE,2), ...
                size(dataE,3));

            dataRef = []; %For argout
            if nargin > 5 && ~isempty(refEpoch)
                %Padding with NaNs
                dataRef = this.getPrefixedEpochData(labelPrefix, ...
                    refEpoch, true);
                dataRef = reshape(dataRef,Np,length(labelPrefix),1, ...
                    size(dataRef,3));

                dataE = dataE-dataRef;
            end
            if nargin < 8 || isempty(summFlag)
                summFlag = 'nanmean';
            end
            eval(['fun=@(x) ' summFlag '(x,4);']);
            dataS = fun(dataE);

            %Second: use ATS.plotCheckerboard
            if nargin < 4 || isempty(fh)
                fh = figure();
            end
            for ii = 1:length(epochs)
                if nargin < 5 || isempty(ph) || length(ph) ~= length(epochs)
                    ph(ii) = subplot(length(epochs),1,ii);
                end
                evLabel = {'sHS','','fTO','','','','fHS','','sTO','','',''};
                ATS = alignedTimeSeries(0,1/numel(evLabel), ...
                    dataS(:,:,ii), ...
                    labelPrefix,ones(1,Np),evLabel);
                if flipLR
                    [ATS,iC] = ATS.flipLR;
                elseif symmetryFlag
                    [ATS,iC,iI] = ATS.getaSym;
                end
                ATS.plotCheckerboard(fh,ph(ii));
                axes(ph(ii));
                colorbar off;
                title([epochs.Properties.ObsNames{ii} '[' ...
                    num2str(epochs.Stride_No(ii)) ']'] );
            end
            %Aligning all returned data if we do L/R flip
            if flipLR || symmetryFlag
                dataE(:,iC,:,:) = fftshift(dataE(:,iC,:,:),1);
                if ~isempty(dataRef)
                    dataRef(:,iC,:,:) = fftshift(dataRef(:,iC,:,:),1);
                end
            end
            if symmetryFlag
                dataE = cat(2,dataE(:,iI,:,:)-dataE(:,iC,:,:));
                if ~isempty(dataRef)
                    dataRef = cat(2,dataRef(:,iI,:,:)-dataRef(:,iC,:,:));
                end
            end

        end


        function [dataE,dataRef,labels,groups] = ...
            getCheckerboardsData(this,labelPrefix,epochs,refEpoch, ...
            flipLR,summFlag)
            %GETCHECKERBOARDSDATA Return the data of PLOTCHECKERBOARDS.
            %
            %   Meant for parameters that end in 's1...s12' (as computed for
            % EMG and angles). The 's' must be included in the label
            % prefixes, to allow for other options too.
            %
            % Inputs:
            %   this        - groupAdaptationData object
            %   labelPrefix - cell array of parameter label prefixes
            %   epochs      - epoch definition table (from defineEpochs)
            %   refEpoch    - (optional) reference epoch subtracted from
            %                 every epoch
            %   flipLR      - (optional) true to flip left and right; 2 for
            %                 a symmetry plot
            %   summFlag    - (optional) name of the function that averages
            %                 across subjects (default 'nanmean')
            %
            % Outputs:
            %   dataE   - epoch data (aligned if flipLR is set)
            %   dataRef - reference epoch data, or []
            %   labels  - parameter labels
            %   groups  - group-averaged data used for the plot
            %
            % Toolbox Dependencies: None
            %
            % See also PLOTCHECKERBOARDS.

            symmetryFlag = false;
            if nargin < 5 || isempty(flipLR)
                flipLR    = false;
                normalize = false;
            elseif flipLR == 2 %Codeword for doing symmetry plot
                %FlipLR is implicit in doing a symmetry plot
                flipLR       = false;
                symmetryFlag = true;
            else symmetryFlag = false;
            end

            %First, get epoch data:
            %Padding with NaNs
            [dataE,labels] = this.getPrefixedEpochData(labelPrefix, ...
                epochs,true);
            Np = size(labels,1);
            dataE = reshape(dataE,Np,length(labelPrefix),size(dataE,2), ...
                size(dataE,3));

            dataRef = []; %For argout
            if nargin > 4 && ~isempty(refEpoch)
                %Padding with NaNs
                dataRef = this.getPrefixedEpochData(labelPrefix, ...
                    refEpoch, true);
                dataRef = reshape(dataRef,Np,length(labelPrefix),1, ...
                    size(dataRef,3));
                dataE = dataE-dataRef;
            end

            if nargin < 6 || isempty(summFlag)
                summFlag = 'nanmean';
            end
            eval(['fun=@(x) ' summFlag '(x,4);']);
            dataS = fun(dataE);


            for ii = 1:length(epochs)

                evLabel = {'sHS','','fTO','','','','fHS','','sTO','','',''};
                ATS = alignedTimeSeries(0,1/numel(evLabel), ...
                    dataS(:,:,ii), ...
                    labelPrefix,ones(1,Np),evLabel);
                if flipLR
                    [ATS,iC] = ATS.flipLR;
                elseif symmetryFlag
                    [ATS,iC,iI] = ATS.getaSym;
                end
                groups = ATS.Data;
            end
            %Aligning all returned data if we do L/R flip
            if flipLR || symmetryFlag
                dataE(:,iC,:,:) = fftshift(dataE(:,iC,:,:),1);
                if ~isempty(dataRef)
                    dataRef(:,iC,:,:) = fftshift(dataRef(:,iC,:,:),1);
                end
            end
            if symmetryFlag
                dataE = cat(2,dataE(:,iI,:,:)-dataE(:,iC,:,:), ...
                    dataE(:,iI,:,:)+dataE(:,iC,:,:));
                if ~isempty(dataRef)
                    dataRef = cat(2,dataRef(:,iI,:,:)-dataRef(:,iC,:,:), ...
                        dataRef(:,iI,:,:)+dataRef(:,iC,:,:));
                end
            end

        end

        function [dataE,labels,allData] = ...
            getPrefixedEpochData(this,labelPrefix, ...
            epochs,padWithNaNFlag)
            %GETPREFIXEDEPOCHDATA Return epoch data for label prefixes.
            %
            % Inputs:
            %   this           - groupAdaptationData object
            %   labelPrefix    - cell array of parameter label prefixes
            %   epochs         - epoch definition table (from defineEpochs)
            %   padWithNaNFlag - (optional) pad short epochs with NaN
            %                    (default false)
            %
            % Outputs:
            %   dataE   - labels x epochs x subjects array of epoch values
            %   labels  - matching parameter labels
            %   allData - cell array, one cell per epoch, of strides x
            %             labels x subjects arrays
            %
            % Toolbox Dependencies: None
            %
            % See also ADAPTATIONDATA/GETPREFIXEDEPOCHDATA.

            if nargin < 4 || isempty(padWithNaNFlag)
                padWithNaNFlag = false;
            end
            allData1 = cell(length(epochs),length(this.ID));
            [data1,labels,allData1(:,1)] = ...
                this.adaptData{1}.getPrefixedEpochData(labelPrefix, ...
                epochs, ...
                padWithNaNFlag);
            dataE = nan(size(data1,1),size(data1,2),length(this.ID));
            dataE(:,:,1) = data1;
            for ii = 2:length(this.ID)
                [dataE(:,:,ii),labels,allData1(:,ii)] = ...
                    this.adaptData{ii}.getPrefixedEpochData(labelPrefix, ...
                    epochs, ...
                    padWithNaNFlag);
            end
            allData = cell(length(epochs),1);
            for jj = 1:length(epochs)
                allData{jj} = reshape(cell2mat(allData1(jj,:)), ...
                    epochs.Stride_No(jj), ...
                    numel(labels),length(this.ID));
            end
        end

        %Individuals
        function [fh,ph] = plotIndividuals(this,labels,conds,strideNo, ...
            exemptStrides,medianFlag,ph,regFlag,differenceFlag)
            %PLOTINDIVIDUALS Scatter plot of individual subject averages.
            %
            %   Plots individual averages (or medians) over some subset of
            % strides, one point per subject, for one parameter against
            % another (or the same parameter in two conditions or stride
            % sets).
            %
            % Inputs:
            %   this           - groupAdaptationData object
            %   labels         - parameter name, or cell array of up to two
            %                    names (if only one, the same label is
            %                    compared to itself)
            %   conds          - condition name, or cell array of up to two
            %                    names
            %   strideNo       - scalar or 2-vector with the number of
            %                    strides to use; negative numbers index from
            %                    the end
            %   exemptStrides  - scalar or 2-vector with the strides to
            %                    exempt (no sign: exempted equally from the
            %                    end and the beginning)
            %   medianFlag     - (optional) true to take the median across
            %                    strides (default: mean)
            %   ph             - (optional) axes handle to plot into
            %   regFlag        - (optional) 1 to plot the linear regression
            %                    between the variables (default: no)
            %   differenceFlag - (optional) 1 to subtract the first data set
            %                    from the second before plotting, e.g., to
            %                    compare baseline behavior to change from
            %                    baseline
            %
            % Outputs:
            %   fh - figure handle
            %   ph - axes handle properties
            %
            % NOTE: With differenceFlag set, a third set of labels,
            %       conditions, or strides is allowed (plots 1 against 2
            %       minus 3).
            %
            % Toolbox Dependencies: Statistics and Machine Learning Toolbox

            if ischar(labels)
                labels = {labels};
            end
            if ischar(conds)
                conds = {conds};
            end
            maxK = 2;
            if length(labels) > 2 || length(conds) > 2 || ...
                    length(strideNo) > 2
                if differenceFlag == 1 && length(labels) < 3 && ...
                        length(conds) < 4 && ...
                        length(strideNo) < 4
                    %Three strides sets provided, going to plot 1 vs. (2
                    %minus 3), 2 and 3 need to be for the same parameter
                    maxK = 3;
                else
                    error(['Using more than 2 parameters, conditions, ' ...
                        'or stride ' ...
                        'sets. Cannot do.'])
                end
            end
            auxStr = {'last', '', 'first'};
            while length(labels) < 3 %If we have less than 3 labels,
                %repeat the last label: it works both if a single label is
                %provided,
                %as well as if two are. In the case that user did not
                %specify
                %a third stride subset to subtract (maxK==2) the third one
                %is just
                %ignored
                labels = [labels labels(end)];
            end
            while length(strideNo) < 3
                strideNo = [strideNo strideNo(end)];
            end
            while length(conds) < 3
                conds = [conds conds(end)];
            end
            while length(exemptStrides) < 3
                exemptStrides = [exemptStrides exemptStrides(end)];
            end

            for kk = 1:maxK %Getting data for X & Y
                %Case we are asking for biographical data
                if length(labels{kk}) > 2 && strcmp('sub',labels{kk}(1:3))
                    for jj = 1:length(this.ID)
                        %Needs to be numeric field or it will fail
                        data(1,jj) = ...
                            this.adaptData{jj}.subData.(labels{kk}(4:end));
                    end
                    str = ['Subject ' labels{kk}(4:end)];
                    %Parameter is actually the bias of a parameter
                elseif length(labels{kk}) > 5 && ...
                        (strcmp('biasTM',labels{kk}(1:6)) || ...
                        strcmp('biasOG',labels{kk}(1:6)))
                    %This could fail if the adaptationData contained here is
                    %not unbiased
                    try
                        [biasTM,biasOG] = ...
                            this.getGroupedBias(labels{kk}(7:end));
                        if strcmp(labels{kk}(5:6),'TM')
                            data = biasTM;
                            str  = [{labels{kk}(7:end)}; {'TM bias'}];
                        else
                            data = biasOG;
                            str  = [{labels{kk}(7:end)}; {'OG bias'}];
                        end
                    catch
                        ME = MException( ...
                            'groupAdaptData:plotIndividuals', ...
                            ['Attempted to plot the bias of a ' ...
                            'parameter, but ' ...
                            'adaptationData appears not to be biased']);
                        throw(ME)
                    end

                else %Standard parameter
                    data = getGroupedData(this,labels(kk),conds(kk),0, ...
                        strideNo(kk), ...
                        exemptStrides(kk),exemptStrides(kk));
                    data = squeeze(data{1});
                    str = [labels(kk); ...
                        {[ ' [' auxStr{sign(strideNo(kk))+2} ' ' ...
                        num2str(abs(strideNo(kk))) ' (' num2str( ...
                        exemptStrides(kk)) ') ' conds{kk} ']']}];
                end
                if nargin > 5 && ~isempty(medianFlag) && medianFlag == 1
                    data = median(data, 1, 'omitnan');
                else
                    data = mean(data, 1, 'omitnan');
                end
                eval(['data' num2str(kk) '=data;']);
                eval(['str' num2str(kk) '=str;']);
            end

            if nargin > 8 && ~isempty(differenceFlag) && differenceFlag == 1
                if maxK == 2
                    data2 = data2-data1;
                    str2{1} = [str2{1} ' (diff)'];
                else
                    data2 = data2-data3;
                    str2{2} = [str2{2} ' minus ' str3{2}];
                end
            end

            if nargin < 7 || isempty(ph)
                fh = figure();
            else
                subplot(ph);
            end

            hold on
            p = plot(data1,data2,'o','DisplayName',[this.groupID]);
            text(data1,data2,strcat('-  ',this.ID),'FontSize',8,'Color', ...
                p.Color)
            set(p,'MarkerFaceColor',p.Color);
            p.MarkerEdgeColor = 'None';

            xlabel(str1)
            ylabel(str2)
            p2 = [];
            p3 = [];
            if nargin > 7 && ~isempty(regFlag) && regFlag == 1
                [rho,pval] = corr(data1',data2','type','pearson');
                [rho2,pval2] = corr(data1',data2','type','spearman');
                pp = polyfit1PCA(data1,data2,1); %Best line from PCA
                x  = [min(data1) max(data1)];
                y  = pp(1)*x + pp(2);
                if max(y) > max(data2)
                    [~,ii] = max(y);
                    y(ii) = max(data2);
                    x(ii) = (y(ii)-pp(2))/pp(1);
                end
                if min(y) < min(data2)
                    [~,ii] = min(y);
                    y(ii) = min(data2);
                    x(ii) = (y(ii)-pp(2))/pp(1);
                end
                p2 = plot(x,y,'Color',p.Color,'DisplayName', ...
                    ['s=' sprintf('%.3f',pp(1)) ', r=.' ...
                    sprintf('%03.0f',rho*1000) ...
                    ', p=.' sprintf('%03.0f',pval*1000)]);
                p3 = plot(x,y,'Color',p.Color,'DisplayName', ...
                    ['r_{rnk}=.' sprintf('%03.0f',rho2*1000) ...
                    ', p_{rnk}=.' ...
                    sprintf('%03.0f',pval2*1000)]);
            end
            hold off
            ph = get(gca);
            hl = legend('Location','best');
            set(hl,'FontSize',6)
            set(gca,'Units','Normalized')

        end
        %Stats
        %function []=anova2()
        %
        %end

        %function []=anova1()
        %
        %end

        function [p,table,stats,postHoc,postHocEstimates,data] = ...
            friedman(this,label,conds,groupingStrides,exemptFirst, ...
            exemptLast, ...
            interactionFlag,avgFlag)
            %FRIEDMAN Friedman test of grouped data.
            %
            %   Runs the Friedman test (non-parametric one-way repeated
            % measures ANOVA equivalent) on the grouped data, with each
            % individual as a block. It finds the indices of the desired
            % conditions and strides and calls FRIEDMANI.
            %
            % Inputs:
            %   this            - groupAdaptationData object
            %   label           - parameter label(s)
            %   conds           - cell array of condition names
            %   groupingStrides - strides per group (same absolute value in
            %                     every group: Friedman needs a balanced
            %                     design)
            %   exemptFirst     - strides skipped at the start
            %   exemptLast      - strides skipped at the end
            %   interactionFlag - (optional) 1 for a model with interactions
            %   avgFlag         - (optional) 1 to average strides within a
            %                     group
            %
            % Outputs:
            %   p                - p-value
            %   table            - test table
            %   stats            - test statistics structure
            %   postHoc          - matrix of post-hoc p-values between
            %                      stride groups
            %   postHocEstimates - matrix of the post-hoc estimated
            %                      differences
            %   data             - grouped data used in the test
            %
            % NOTE: If the groups are not balanced, a warning is issued and
            %       the size of the first group is used for all groups.
            %
            % Toolbox Dependencies: Statistics and Machine Learning Toolbox
            %
            % See also FRIEDMANI, ANOVA1RM, GETGROUPEDINDS.

            % TODO: check that the numberOfStrides groups are given in
            % chronological order and that so are the conditions in conds,
            % as the test expects ordered input.

            if nargin < 7
                interactionFlag = [];
            end
            if nargin < 8
                avgFlag = [];
            end
            N = abs(groupingStrides(1));
            M = length(conds)*length(groupingStrides);
            if any(abs(groupingStrides) ~= N) %Friedman has to be balanced
                warning([ ...
                    'Friedman test only supports balanced designs ' ...
                    '(all groups ' ...
                    'should have the same number of strides). Will ' ...
                    'use ' num2str(N) ' strides in all conditions.'])
                groupingStrides = N*sign(groupingStrides);
            end
            inds = this.getGroupedInds(conds,groupingStrides, ...
                exemptFirst,exemptLast);
            inds = cell2mat(inds');
            %Sorting so groups are presented in appearance order.
            [~,ii] = sort(mean(inds, 1, 'omitnan'));
            inds = inds(:,ii);
            inds = mat2cell(inds,N*ones(length(this.ID),1),M);
            [p,table,stats,postHoc,postHocEstimates,data] = ...
                friedmanI(this,label,inds,interactionFlag,avgFlag);
        end

        function [p,table,stats,postHoc,postHocEstimates,data] = ...
            anova1RM(this,label,conds,groupingStrides,exemptFirst, ...
            exemptLast, ...
            interactionFlag,avgFlag)
            %ANOVA1RM One-way repeated-measures ANOVA of grouped data.
            %
            %   Finds the indices of the desired conditions and strides and
            % calls ANOVA1RMI, with each individual as a block.
            %
            % Inputs:
            %   this            - groupAdaptationData object
            %   label           - parameter label(s)
            %   conds           - cell array of condition names
            %   groupingStrides - strides per group (same absolute value in
            %                     every group)
            %   exemptFirst     - strides skipped at the start
            %   exemptLast      - strides skipped at the end
            %   interactionFlag - (optional) 1 for a model with interactions
            %   avgFlag         - (optional) 1 to average strides within a
            %                     group
            %
            % Outputs:
            %   p                - p-value
            %   table            - ANOVA table
            %   stats            - test statistics structure
            %   postHoc          - matrix of post-hoc p-values between
            %                      stride groups
            %   postHocEstimates - matrix of the post-hoc estimated
            %                      differences
            %   data             - grouped data used in the test
            %
            % NOTE: If the groups are not balanced, a warning is issued and
            %       the size of the first group is used for all groups.
            %
            % Toolbox Dependencies: Statistics and Machine Learning Toolbox
            %
            % See also ANOVA1RMI, FRIEDMAN, GETGROUPEDINDS.

            % TODO: check that the numberOfStrides groups are given in
            % chronological order and that so are the conditions in conds,
            % as the test expects ordered input.

            if nargin < 7
                interactionFlag = [];
            end
            if nargin < 8
                avgFlag = [];
            end
            N = abs(groupingStrides(1));
            M = length(conds)*length(groupingStrides);
            if any(abs(groupingStrides) ~= N) %Friedman has to be balanced
                warning([ ...
                    'Anova1-RM test currently only supports balanced ' ...
                    'designs (all ' ...
                    'groups should have the same number of strides). ' ...
                    'Will use ' num2str(N) ' strides in all conditions.'])
                groupingStrides = N*sign(groupingStrides);
            end
            inds = this.getGroupedInds(conds,groupingStrides, ...
                exemptFirst,exemptLast);
            inds = cell2mat(inds');
            %Sorting so groups are presented in appearance order.
            [~,ii] = sort(mean(inds, 1, 'omitnan'));
            inds = inds(:,ii);
            inds = mat2cell(inds,N*ones(length(this.ID),1),M);
            [p,table,stats,postHoc,postHocEstimates,data] = ...
                anova1RMI(this,label,inds,interactionFlag,avgFlag);
        end

        function [p,table,stats,postHoc,postHocEstimates,allData] = ...
            friedmanI(this,label,inds,interactionFlag,avgFlag)
            %FRIEDMANI Friedman test on given stride indices.
            %
            %   Runs the Friedman test (non-parametric one-way repeated
            % measures ANOVA equivalent) for the grouped data. Each
            % individual is a block, and the different index groups are
            % compared to each other.
            %
            % Inputs:
            %   this            - groupAdaptationData object
            %   label           - parameter label(s)
            %   inds            - cell array with one cell per subject, each
            %                     an N x M matrix of stride indices (M
            %                     groups to test, N strides per group)
            %   interactionFlag - (optional) 1 for a model with interactions
            %                     (default 0)
            %   avgFlag         - (optional) 1 to average strides within a
            %                     group (default 0)
            %
            % Outputs:
            %   p                - p-value
            %   table            - test table
            %   stats            - test statistics structure
            %   postHoc          - upper-triangular M x M matrix of p-values
            %                      of pairwise Friedman tests between stride
            %                      groups
            %   postHocEstimates - upper-triangular M x M matrix of the
            %                      differences in mean ranks
            %   allData          - N x subjects x M array of the data tested
            %
            % NOTE: inds follows a different specification from the output
            %       of GETGROUPEDINDS. To convert that output: N =
            %       size(inds{1},1); M = size(inds{1},2)*size(inds,1); inds
            %       = mat2cell(cell2mat(inds'), N*ones(length(this.ID),1),
            %       M).
            %
            % Toolbox Dependencies: Statistics and Machine Learning Toolbox
            %
            % See also FRIEDMAN, GETGROUPEDINDS.

            %Check that the size of inds is the same for all
            %subjects (friedman needs to be balanced)

            %Check that size(inds,1)==#subs

            %Do Friedman
            N = size(inds{1},1); %Number of strides per stride group
            M = size(inds{1},2); %Number of stride groups
            P = length(this.ID); % num of subs
            if isa(label,'char')
                label = {label};
            end
            if nargin < 4 || isempty(interactionFlag)
                interactionFlag = 0; %No interactions is default
            end
            if nargin < 5 || isempty(avgFlag)
                avgFlag = 0;
            end
            switch interactionFlag
                case 1
                    model = 'full';
                case 0
                    model = 'linear';
            end
            if length(label) > 1 %For multiple parameters
                for ii = 1:length(label)
                    [p{ii},table{ii},stats{ii},postHoc{ii}, ...
                        postHocEstimates{ii}, ...
                        allData{ii}] = this.friedmanI(label{ii},inds, ...
                        interactionFlag, ...
                        avgFlag);
                end
            else
                allData = nan(N,P,M);
                for jj = 1:P
                    %Should I be normalizing or removing bias?
                    aux = this.adaptData{jj}.data.getDataAsVector(label);
                    for ii = 1:M
                        allData(:,jj,ii) = aux(inds{jj}(:,ii));
                    end
                end
                if avgFlag == 1
                    allData = mean(allData, 1, 'omitnan');
                    N       = 1;
                end
                %Setting up the data in the shape required by Friedman
                data = reshape(allData,N*P,M);
                %This fails if there are any nan in newData
                [p,table,stats] = friedman(data,N,'off');
                %Post-hoc: more friedman, but on paired columns. As such it
                %may be unnecessary, since the user can have this info by
                %just calling on friedman with the reduced data
                postHoc          = nan(M);
                postHocEstimates = nan(M);
                %Post-hoc: Default is tukey-kramer
                %mm=multcompare(stats,'Dimension',2,'Display','off', ...
                %    'CType','bonferroni');
                %%Post-hoc across stride groups
                %postHoc(sub2ind([M,M],mm(:,1),mm(:,2)))=mm(:,6);
                %postHocEstimates(sub2ind([M,M],mm(:,1),mm(:,2)))=mm(:,4);
                for ii = 1:M
                    for jj = ii+1:M
                        [postHoc(ii,jj),~,s] = ...
                            friedman(data(:,[ii,jj]),N,'off');
                        postHocEstimates(ii,jj) = diff(s.meanranks);
                    end
                end
            end
        end

        function [p,table,stats,postHoc,postHocEstimates,allData] = ...
            anova1RMI(this,label,inds,interactionFlag,avgFlag)
            %ANOVA1RMI One-way RM ANOVA on stride indices.
            %
            %   Runs a one-way repeated-measures ANOVA using each individual
            % as a block, testing across stride groups (e.g., early
            % adaptation vs late baseline).
            %
            % Inputs:
            %   this            - groupAdaptationData object
            %   label           - parameter label(s)
            %   inds            - cell array with one cell per subject, each
            %                     an N x M matrix of stride indices (M
            %                     groups to test, N strides per group)
            %   interactionFlag - (optional) 1 for a model with interactions
            %                     (default 0)
            %   avgFlag         - (optional) 1 to average strides within a
            %                     group (default 0)
            %
            % Outputs:
            %   p                - p-value
            %   table            - ANOVA table
            %   stats            - test statistics structure
            %   postHoc          - M x M matrix of Bonferroni-corrected
            %                      post-hoc p-values between stride groups
            %   postHocEstimates - M x M matrix of the estimated differences
            %                      between stride groups
            %   allData          - N x subjects x M array of the data tested
            %
            % NOTE: inds follows a different specification from the output
            %       of GETGROUPEDINDS. To convert that output: N =
            %       size(inds{1},1); M = size(inds{1},2)*size(inds,1); inds
            %       = mat2cell(cell2mat(inds'), N*ones(length(this.ID),1),
            %       M).
            %
            % Toolbox Dependencies: Statistics and Machine Learning Toolbox
            %
            % See also ANOVA1RM, GETGROUPEDINDS.

            N = size(inds{1},1);%Number of strides per stride group
            M = size(inds{1},2);%Number of strideGroups
            P = length(this.ID); %num of subs = size(inds,2)
            if isa(label,'char')
                label = {label};
            end
            if nargin < 4 || isempty(interactionFlag)
                interactionFlag = 0; %No interactions is default
            end
            if nargin < 5 || isempty(avgFlag)
                avgFlag = 0;
            end
            switch interactionFlag
                case 1
                    model = 'full';
                case 0
                    model = 'linear';
            end
            if length(label) > 1 %For multiple parameters
                for ii = 1:length(label)
                    [p{ii},table{ii},stats{ii},postHoc{ii}, ...
                        postHocEstimates{ii}, ...
                        allData{ii}] = anova1RMI(this,label{ii},inds, ...
                        interactionFlag, ...
                        avgFlag);
                end
            else
                allData = nan(N,P,M);
                for jj = 1:P %For each sub
                    %Should I be normalizing or removing bias?
                    aux = this.adaptData{jj}.data.getDataAsVector(label);
                    for ii = 1:M %For each strideGroup
                        %Strides x sub x strideGroup
                        allData(:,jj,ii) = aux(inds{jj}(:,ii));
                    end
                end
                if avgFlag == 1
                    allData = mean(allData, 1, 'omitnan');
                    N       = 1;
                end
                data        = reshape(allData,N*P,M);
                subID       = repmat(this.ID,N,M);
                strideGroup = repmat([1:M],N*P,1);
                [p,table,stats,~] = anovan(data(:), ...
                    {subID(:) strideGroup(:)}, ...
                    'display','off','random',[1],'varnames', ...
                    {'subID','strideGroup'}, ...
                    'model',model);
                postHoc          = nan(M);
                postHocEstimates = nan(M);
                allData          = data;
                %Post-hoc: Default is tukey-kramer
                mm = multcompare(stats,'Dimension',2,'Display','off', ...
                    'CType', ...
                    'bonferroni'); %Post-hoc across stride groups
                postHoc(sub2ind([M,M],mm(:,1),mm(:,2))) = mm(:,6);
                postHocEstimates(sub2ind([M,M],mm(:,1),mm(:,2))) = mm(:,4);
            end
        end

        function [p,anovatab,stats,postHoc,postHocEstimate,data] = ...
            summaryKW(this,param,conds,groupingStrides,exemptFirst, ...
            exemptLast)
            %SUMMARYKW Kruskal-Wallis test for each subject.
            %
            %   Runs adaptationData/kruskalwallis for each individual and
            % returns the results as cell arrays, one cell per subject.
            %
            % Inputs:
            %   this            - groupAdaptationData object
            %   param           - parameter label
            %   conds           - cell array of condition names
            %   groupingStrides - strides per group
            %   exemptFirst     - strides skipped at the start
            %   exemptLast      - strides skipped at the end
            %
            % Outputs:
            %   p               - cell array of p-values
            %   anovatab        - cell array of test tables
            %   stats           - cell array of test statistics structures
            %   postHoc         - cell array of post-hoc results
            %   postHocEstimate - cell array of post-hoc estimates
            %   data            - cell array of the data tested
            %
            % Toolbox Dependencies: None
            %
            % See also ADAPTATIONDATA/KRUSKALWALLIS.

            for ii = 1:length(this.ID)
                [p{ii},anovatab{ii},stats{ii},postHoc{ii}, ...
                    postHocEstimate{ii},data{ii}] = ...
                    this.adaptData{ii}.kruskalwallis(param,conds, ...
                    groupingStrides, ...
                    exemptFirst,exemptLast);
            end
        end

        function Demographic = GroupDemographics(this)
            %GROUPDEMOGRAPHICS Compute the demographics of the group.
            %
            %   Calculates the number of subjects, the mean and std of age,
            % and the number of males. Used by the GroupDemographics
            % function.
            %
            % Inputs:
            %   this - groupAdaptationData object
            %
            % Outputs:
            %   Demographic - struct with fields N, MeanAge, StdAge, AllAge,
            %                 and NMale
            %
            % Toolbox Dependencies: None
            %
            % See also GROUPDEMOGRAPHICS.

            for s = 1:length(this.adaptData)
                tempAge(s) = [this.adaptData{s}.subData.age];
                if strcmp(lower(this.adaptData{s}.subData.sex), 'male') == 1
                    tempMale(s) = [1];
                elseif strcmp(lower(this.adaptData{s}.subData.sex), ...
                        'female') == 1
                    tempMale(s) = [0];
                end
            end
            Demographic.N = length(tempAge);
            Demographic.MeanAge = mean(tempAge);
            Demographic.StdAge = std(tempAge);
            Demographic.AllAge = tempAge;
            Demographic.NMale = sum(tempMale);
        end

        function RemovedData = RemoveBadMuscles(normalizedGroupData, ...
            badSubjID, ...
            badMuscles )
            %REMOVEBADMUSCLES Set the data of bad muscles to NaN.
            %
            %   Sets to NaN the values of the listed muscles for the listed
            % subjects. Muscles must be removed bilaterally, so both sides
            % must be listed.
            %
            % Inputs:
            %   normalizedGroupData - groupAdaptationData object with
            %                         normalized data
            %   badSubjID           - cell array of subject IDs
            %   badMuscles          - cell array, one cell per subject ID,
            %                         of cell arrays of muscle names
            %
            % Outputs:
            %   RemovedData - groupAdaptationData object with the bad data
            %                 set to NaN
            %
            % NOTE: If a label is not found, a warning is issued and the
            %       function returns before the remaining muscles are
            %       removed; normalize the data first.
            %
            % Toolbox Dependencies: None
            %
            % See also NORMALIZETOBASELINE.

            subjectsToPlot = [];  subjectsToPlotID = [];
            subjectsToPlot{end+1} = normalizedGroupData;
            %     subjectsToPlotID{end+1} = groupID;

            for idxToRemove = 1:numel(badSubjID)

                subjIdx = ...
                    find(contains(subjectsToPlot{end}.ID, ...
                    badSubjID{idxToRemove}));


                if ~isempty(subjIdx)

                    badSubj = subjectsToPlot{end}.adaptData{subjIdx};

                    for ii = 1:numel(badMuscles{idxToRemove})

                        badDataIdx = ...
                            find(cellfun(@(x) ~isempty(x), ...
                            regexp(badSubj.data.labels, ...
                            ['^' badMuscles{idxToRemove}{ii} '[ ]?\d+$'])));

                        if isempty(badDataIdx)
                            warning([ ...
                                'Label not found. No muscle removed. ' ...
                                'Make ' ...
                                'sure that you normalize the data first'])
                            return
                        end

                        badSubj.data.Data(:,badDataIdx) = nan;

                        disp(['Removing (Setting NaN) of ' ...
                            badMuscles{idxToRemove}{ ...
                            ii} ' from Subject: ' badSubj.subData.ID])

                    end
                    subjectsToPlot{end}.adaptData{subjIdx} = badSubj;
                end

            end

            RemovedData = subjectsToPlot{1};

        end
    end

    methods(Static)
        % Several groups visualization
        [figHandle,allData] = plotMultipleGroupsBars(groups,label, ...
            removeBiasFlag,plotIndividualsFlag,condList,numberOfStrides, ...
            exemptFirst,exemptLast,legendNames,significanceThreshold, ...
            plotHandles,colors,significancePlotMatrix,medianFlag, ...
            signifPlotMatrixConds);
        [figHandle,allData] = plotMultipleEpochBars(groups,labels,eps, ...
            plotIndividualsFlag,legendNames,plotHandles,colors, ...
            medianFlag, ...
            significanceThreshold,posthocGroupFlag,posthocEpochFlag, ...
            plothocGroupByEpochFlag,posthocEpochByGroupFlag, ...
            removeBaseEpochFlag);

        % Several groups stats
        [model,btab,wtab,maineff,posthocGroup,posthocEpoch, ...
            posthocEpochByGroup, ...
            posthocGroupByEpoch] = AnovaEpochs(groups,groupsNames,label, ...
            eps, ...
            significanceThreshold)


        function p = compareMultipleGroups(groups,label,condition, ...
            numberOfStrides,exemptFirst,exemptLast)
            %COMPAREMULTIPLEGROUPS Compare two groups with a t-test.
            %
            %   Runs a 2-sample t-test comparing the behavior of parameters
            % across exactly two groups, for a given subset of strides.
            %
            % Inputs:
            %   groups          - cell array of two groupAdaptationData
            %                     objects
            %   label           - cell array of parameter labels
            %   condition       - cell array of condition names
            %   numberOfStrides - strides per group
            %   exemptFirst     - strides skipped at the start
            %   exemptLast      - strides skipped at the end
            %
            % Outputs:
            %   p - conditions x stride groups x labels array of p-values
            %
            % Toolbox Dependencies: Statistics and Machine Learning Toolbox
            %
            % See also GETAVGGROUPEDDATA.

            for jj = 1:length(condition)
                for ii = 1:length(numberOfStrides)
                    for k = 1:length(label)
                        data1 = groups{1}.getAvgGroupedData(label(k), ...
                            condition(jj),0, ...
                            numberOfStrides(ii),exemptFirst,exemptLast);
                        data2 = groups{2}.getAvgGroupedData(label(k), ...
                            condition(jj),0, ...
                            numberOfStrides(ii),exemptFirst,exemptLast);
                        [~,p(jj,ii,k),ci,stats] = ...
                            ttest(squeeze(data1),squeeze(data2));
                    end
                end
            end
        end

        %% Loading
        function this = loadobj(this)
            %LOADOBJ Check the group when loading a saved object.
            %
            %   Retroactive compliance check: runs getCommonConditions and
            % checkCommonConditionOrder on the loaded object.
            %
            % Inputs:
            %   this - groupAdaptationData object being loaded
            %
            % Outputs:
            %   this - groupAdaptationData object
            %
            % Toolbox Dependencies: None
            %
            % See also GETCOMMONCONDITIONS, CHECKCOMMONCONDITIONORDER.

            [conditions,nonCommonConditions] = getCommonConditions(this);
            condOrder = this.checkCommonConditionOrder(conditions);
            %To do: check and display minimum number of strides per common
            %condition
        end

    end
end
