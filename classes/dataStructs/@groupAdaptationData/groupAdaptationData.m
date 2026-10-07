classdef groupAdaptationData
    %groupAdaptaitonData  contains the adaptation data objects for a group
    %of subjects
    %
    %groupAdaptaitonData properties:
    %   ID - cell array of strings listing subject ID's in group
    %   adaptData - cell array of adaptationData objects
    %
    %groupAdaptaitonData Methods:
    %
    %See also: experimentMetaData, subjectData, adaptationData

    properties
        %cell array of strings listing subject ID's in group: should be a
        %dependent property!
        ID
        % cell array of adaptationData objects. This should be called
        % 'subjectData'
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
            out = this.adaptData;
        end

        function [conditions,nonCommonConditions] = ...
            getCommonConditions(this,subs)
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
            labelList = this.getAllParameters;
            flags     = cellfun(@(x) ~isempty(x),regexp(labelList,exp));
            labelList = labelList(flags);
        end

        function gID = get.groupID(this)
            if ~isempty(this.hiddenID)
                gID = this.hiddenID;
            else
                %Using first char in first subjects' ID as group ID.
                gID = this.ID{1}(1);
            end
        end

        function [nStrides,labels] = getNumStridesInCond(this,conds)
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

            error('Unimplemented')
            %This requires finisihing getMinSharedNumberOfStrides
            commonConds  = this.getCommonConditions;
            commonParams = this.getCommonParameters;
            commonStrides = this.getMinSharedNumberOfStrides(this, ...
                commonConds);
            data = getGroupedData(this,commonParams,commonConds,0, ...
                numberOfStrides,0,0); %No removal of bias, no exempt strides
            %Doxy: need to fill meta data and subject data fields
            %appropriately
            meanSub = adaptationData(this.adaptData{1}.metaData, ...
                this.adaptData{1}.subData,data);
        end

        function minNumStrides = getMinSharedNumberOfStrides(this, conds)
            %This function returns the minimum number of strides ALL
            %subjects have for any given condition(s)
            error('Unimplemented')
            if nargin < 2 || isempty(conds)
                conds = this.getCommonConditions;
            end
            minNumStrides = nan(size(conds));
            for ii = 1:length(conds)
                minNumStrides(ii) = NaN; %Doxy
            end
        end

        function ageInMonths = getSubjectAgeAtExperimentDate(this)
            for ii = 1:length(this.ID)
                ageInMonths(ii) = ...
                    this.adaptData{ii}.getSubjectAgeAtExperimentDate;
            end
        end

        %Modifiers
        function newThis = cat(this,other)
            newThis = groupAdaptationData([this.ID other.ID], ...
                [this.adaptData other.adaptData]);
        end

        function newThis = removeBadStrides(this,markAsNaNflag)
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
            newThis = this;
            for ii = 1:length(this.ID)
                newThis.adaptData{ii} = ...
                    this.adaptData{ii}.markBadWhenMissingAny(labels);
            end
        end

        function newThis = markBadWhenMissingAll(this,labels)
            newThis = this;
            for ii = 1:length(this.ID)
                newThis.adaptData{ii} = ...
                    this.adaptData{ii}.markBadWhenMissingAll(labels);
            end
        end

        function newThis = removeBias(this)
            newThis = this;
            for ii = 1:length(this.ID)
                newThis.adaptData{ii} = this.adaptData{ii}.removeBias;
            end

        end

        function newThis = normalizeBias(this)
            newThis = this;
            for ii = 1:length(this.ID)
                newThis.adaptData{ii} = this.adaptData{ii}.normalizeBias;
            end

        end

        function newThis = normalizeToBaseline(this,labelPrefix,baseConds2)
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
            for ii = 1:length(this.ID)
                this.adaptData{ii} = ...
                    this.adaptData{ii}.removeBaselineEpoch(baseEpoch, ...
                    labels);
            end
        end

        function newThis = removeAltBias(this,condName,strideNo, ...
            exemptStrides, ...
            medianFlag,normalizeFlag)
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
            for ii = 1:length(this.ID)
                this.adaptData{ii} = ...
                    this.adaptData{ii}.renameParams(oldLabels,newLabels);
            end
            newThis = this;
        end

        function newThis = renameConditions(this,oldNames,newNames)
            %Replaces names for conditions in all members of the group.
            %Old names is a cell array containing strings, or containing
            %cell arrays of strings with multiple alternative spellings.
            %New names is a cell array of strings.
            %Only exact matches to old names are replaced, and if no exact
            %match is found, then no replacement happens but the process
            %continues (warning thrown, same as adaptationData method)
            for ii = 1:length(this.ID)
                this.adaptData{ii}.metaData = ...
                    this.adaptData{ii}.metaData.replaceConditionNames( ...
                    oldNames,newNames);
            end
            newThis = this;
        end

        function newThis = medianFilter(this,N)
            newThis = this;
            for ii = 1:length(this.adaptData)
                newThis.adaptData{ii} = this.adaptData{ii}.medianFilter(N);
            end
        end

        function newThis = addNewParameter(this,newParamLabel,funHandle, ...
            inputParameterLabels,newParamDescription)
            newThis = this;
            for ii = 1:length(this.adaptData)
                newThis.adaptData{ii} = ...
                    this.adaptData{ii}.addNewParameter(newParamLabel, ...
                    funHandle, ...
                    inputParameterLabels,newParamDescription);
            end
        end

        function newThis = removeSubs(this,subList)
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
            %getEpochData returns data from all subjects for each epoch
            %See also: adaptationData.getEpochData
            %Ex:[data,validStrides, ...
            %    everyStrideData]=getEpochData(studyData,epochs, ...
            %    {'doubleSupportFast'},0);

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
            for ii = 1:length(this.ID)
                [biasTM(:,ii),biasOG(:,ii)] = ...
                    this.adaptData{ii}.getBias(label);
            end
        end

        function [meanData,stdData] = ...
            getAvgGroupedData(this,label,conds, ...
            removeBiasFlag,numberOfStrides,exemptFirst,exemptLast)
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
            newThis = groupAdaptationData([this.ID other.ID], ...
                [this.adaptData other.adaptData]);
        end
        %Visualization
        %Scatter
        function [fh,dataAll,idAll] = scatter(this, params, conditions)
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
            %This is meant to be used with parameters that end in
            %'s1...s12' as are computed for EMG and angles. The 's' must be
            %included in the labelPrefixes (to allow for other options too)
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
            %This is meant to be used with parameters that end in
            %'s1...s12' as are computed for EMG and angles. The 's' must be
            %included in the labelPrefixes (to allow for other options too)
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
            %See also: adaptationData.getPrefixedEpochData
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
            %This function plots individual averages (or medians) for some
            %subset of
            %strides
            %INPUTS:
            %this: a groupAdapatationData object
            %labels: a string, or cell containing up to two parameter names
            %(if only
            %one, assume the same label is being compared to itself)
            %conds: a string, or cell containing up to two condition names
            %(if only one,
            %.. blah)
            %strideNo: a scalar or 2x1 vector, containing the number of
            %strides to be
            %used. Negative numbers indicate indexing from the end
            %exemptStrides: scalar or 2x1 determining how many strides are
            %to be
            %exempted from counting [no sign, exempting equally from end and
            %beginning]
            %medianFlag: whether we take mean or median across strides
            %(mean is default)
            %ph: handles to individual axes to plot
            %regFlag: plot linear regression between variables (default=no)
            %differenceFlag: instead of plotting the second data set as is,
            %subtract the first set from it first. Useful to compare
            %baseline behavior to change from baseline
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
            %Runs Friedman (non-parametric 1-way repeated measures anova
            %equivalent) for the grouped data. Individual ID is considered
            %to be the
            %blocking factor, each individual is
            %considered to be a block.
            %It works by finding the indexes corresponding to
            %conditions/strides
            %desired, and calls on friedmanI.
            %TODO: Should check that numberOfStrides groups are given in
            %chronological order & that so are the conditions in condList
            %as it expects ordered things.

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
            %TODO: Should check that numberOfStrides groups are given in
            %chronological order & that so are the conditions in condList
            %as it expects ordered things.

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
            %Runs Friedman (non-parametric 1-way repeated measures anova
            %equivalent) for the grouped data. Individual ID is considered
            %to be the
            %blocking factor, each individual is
            %considered to be a block, and the different index groups are
            %compared to each other.

            %inds should be a cell with length = #subs and its contents a
            %NxM matrix, where M is the number of groups to be tested and N
            %the number of strides/repetitions in each group
            %Inds here follows a slightly different specification from that
            %returned by getGroupedInds. In order to format the output of
            %that function to the input of this, the following lines need to
            %be executed:
            %N=size(inds{1},1);
            %M=size(inds{1},2)*size(inds,1);
            %inds=mat2cell(cell2mat(inds'),N*ones(length(this.ID),1),M);

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
            %One-way repeated measures anova, using each individual as a
            %block, and testing across stride groups (e.g. early adap vs
            %late
            %base)
            %Inds here follows a slightly different specification from that
            %returned by getGroupedInds. In order to format the output of
            %that function to the input of this, the following lines need to
            %be executed:
            %N=size(inds{1},1);
            %M=size(inds{1},2)*size(inds,1);
            %inds=mat2cell(cell2mat(inds'),N*ones(length(this.ID),1),M);
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
            %Runs kruskal-wallis for each individual, and returns
            %summarized results.
            for ii = 1:length(this.ID)
                [p{ii},anovatab{ii},stats{ii},postHoc{ii}, ...
                    postHocEstimate{ii},data{ii}] = ...
                    this.adaptData{ii}.kruskalwallis(param,conds, ...
                    groupingStrides, ...
                    exemptFirst,exemptLast);
            end
        end

        function Demographic = GroupDemographics(this)
            %Calculates number subjects, mean and std of age and number of
            %males
            %Use in conjuction with "GroupDemographics"
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
            %This is a function that change the values of the "bad" muscle
            %to NaN.

            %This code was developed by SL and updated by DMMO

            %This is a function that change the values of the "bad" muscle
            %to NaN. The
            %subjects and muscle
            %are hard code. Make sure you update this to your needs and that
            %you
            %removed muscle bilaterally

            %This code was developed by SL and updated by DMMO

            subjectsToPlot = [];  subjectsToPlotID = [];
            subjectsToPlot{end+1} = normalizedGroupData; %
            %     subjectsToPlotID{end+1} = groupID;% from SLcode

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

            RemovedData = subjectsToPlot{1}; % from SL code

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
            %2-sample t-test comparing behavior of parameters across groups,
            %for a given
            %subset of strides
            %Check that there are exactly two groups

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
            %Retroactive compliance check!
            [conditions,nonCommonConditions] = getCommonConditions(this);
            condOrder = this.checkCommonConditionOrder(conditions);
            %To do: check and display minimum number of strides per common
            %condition
        end

    end
end
