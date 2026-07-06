function results = getResults(Study, params, groups, ...
    maxPerturb, plotFlag, indivFlag)
%GETRESULTS Compute standard adaptation outcome measures per group.
%
%   For each subject in each group, computes a set of epoch-level
% outcome measures (baseline, catch, steady state, after-effects,
% transfer, washout) and returns group means and SEs.
%
% Inputs:
%   Study      - Struct with group fields, each having ID and adaptData
%                fields (as produced by makeSMatrixV2)
%   params     - Cell array of parameter name strings
%   groups     - Cell array of group name strings; defaults to all
%                fields of Study when empty
%   maxPerturb - If 1, use smoothedMax for after-effects; else use mean
%   plotFlag   - Logical; if true (default), create bar plots and build
%                per-parameter indiv structs
%   indivFlag  - Logical; if true, overlay individual subjects on bars
%
% Outputs:
%   results - Struct with one field per outcome measure; each field
%             has avg (nGroups×nParams), se (same), and indiv sub-struct
%
% Toolbox Dependencies: None
%
% See also SMOOTHEDMAX, BARGROUPS, GETRESULTSSMART.

catchNumPts     = 5;   % catch
steadyNumPts    = 40;  % end of adaptation
transientNumPts = 5;   % OG and washout

nParams = length(params);

if nargin < 3 || isempty(groups)
    groups = fields(Study);
end
nGroups = length(groups);

if nargin < 5 || isempty(plotFlag)
    plotFlag = 1;
end

outcomeMeasures = ...
    {'OGbase', ...
    'TMbase', ...
    'AvgAdaptBeforeCatch', ...
    'AvgAdaptAll', ...
    'ErrorsOut', ...
    'AdaptExtentBeforeCatch', ...
    'Catch', ...
    'AdaptIndex', ...
    'OGafter', ...       % First 5 strides
    'OGafterEarly', ...  % From 6 to 20
    'OGafterLate', ...
    'AvgOGafter', ...
    'TMafter', ...
    'TMafterEarly', ...
    'TMafterLate', ...
    'Transfer', ...
    'Washout', ...
    'Washout2', ...
    'Transfer2', ...
    };

for ii = 1:length(outcomeMeasures)
    results.(outcomeMeasures{ii}).avg = NaN(nGroups, nParams);
    results.(outcomeMeasures{ii}).se  = NaN(nGroups, nParams);
end

for gg = 1:nGroups

    nSubs = length(Study.(groups{gg}).ID);

    for ii = 1:length(outcomeMeasures)
        eval([outcomeMeasures{ii} '=NaN(nSubs,nParams);'])
    end

    AdaptExtent = [];

    for ss = 1:nSubs
        adaptData = Study.(groups{gg}).adaptData{ss};
        adaptData = adaptData.removeBadStrides();
        adaptData.data.Data = medfilt1(adaptData.data.Data);
        adaptData = adaptData.removeBias();

        if nargin > 3 && maxPerturb == 1

            if sum(cellfun(@(x) strcmp(x, 'OG base'), ...
                    adaptData.metaData.conditionName), 'omitnan') == 1
                stepAsymData = adaptData.getParamInCond( ...
                    'stepLengthAsym', 'OG base');
                OGbaseData   = adaptData.getParamInCond( ...
                    params, 'OG base');
                OGbase(ss, :) = smoothedMax(OGbaseData(1:10, :), ...
                    transientNumPts, stepAsymData(1:10));
            end

            stepAsymData = adaptData.getParamInCond( ...
                'stepLengthAsym', 'TM base');
            TMbaseData   = adaptData.getParamInCond(params, 'TM base');
            if isempty(TMbaseData)
                stepAsymData = adaptData.getParamInCond( ...
                    'stepLengthAsym', {'slow base', 'fast base'});
                TMbaseData   = adaptData.getParamInCond( ...
                    params, {'slow base', 'fast base'});
            end
            TMbase(ss, :) = smoothedMax(TMbaseData(1:10, :), ...
                transientNumPts, stepAsymData(1:10));

            if sum(cellfun(@(x) strcmp(x, 'catch'), ...
                    lower(adaptData.metaData.conditionName)), ...
                    'omitnan') == 1
                stepAsymData = adaptData.getParamInCond( ...
                    'stepLengthAsym', 'catch');
                tmcatchData  = adaptData.getParamInCond( ...
                    params, 'catch');
                Catch(ss, :) = smoothedMax( ...
                    tmcatchData, catchNumPts, stepAsymData);
            end

            if sum(cellfun(@(x) strcmp(x, 'OG post'), ...
                    adaptData.metaData.conditionName), 'omitnan') == 1
                stepAsymData = adaptData.getParamInCond( ...
                    'stepLengthAsym', 'OG post');
                ogafterData  = adaptData.getParamInCond( ...
                    params, 'OG post');
                OGafter(ss, :) = smoothedMax(ogafterData(1:10, :), ...
                    transientNumPts, stepAsymData(1:10));
            end

            stepAsymData = adaptData.getParamInCond( ...
                'stepLengthAsym', 'TM post');
            tmafterData  = adaptData.getParamInCond(params, 'TM post');
            TMafter(ss, :) = smoothedMax(tmafterData(1:10, :), ...
                transientNumPts, stepAsymData(1:10));

        else

            if sum(cellfun(@(x) strcmp(x, 'OG base'), ...
                    adaptData.metaData.conditionName), 'omitnan') == 1
                OGbaseData    = adaptData.getParamInCond( ...
                    params, 'OG base');
                OGbase(ss, :) = mean( ...
                    OGbaseData(1:transientNumPts, :), 'omitnan');
            end

            if sum(cellfun(@(x) strcmp(x, 'TM base'), ...
                    adaptData.metaData.conditionName), 'omitnan') == 1
                TMbaseData = adaptData.getParamInCond( ...
                    params, 'TM base');
                if isempty(TMbaseData)
                    TMbaseData = adaptData.getParamInCond( ...
                        params, {'slow base', 'fast base'});
                end
                TMbase(ss, :) = mean( ...
                    TMbaseData(1:transientNumPts, :), 'omitnan');
            end

            if sum(cellfun(@(x) strcmp(x, 'catch'), ...
                    lower(adaptData.metaData.conditionName)), ...
                    'omitnan') == 1
                tmcatchData = adaptData.getParamInCond( ...
                    params, 'catch');
                if isempty(tmcatchData)
                    newtmcatchData = NaN(1, nParams);
                elseif size(tmcatchData, 1) < 3
                    newtmcatchData = mean(tmcatchData, 'omitnan');
                else
                    newtmcatchData = mean( ...
                        tmcatchData(1:catchNumPts, :), 'omitnan');
                    %newtmcatchData=mean(tmcatchData,'omitnan');
                end
                Catch(ss, :) = newtmcatchData;
            end

            if sum(cellfun(@(x) strcmp(x, 'OG post'), ...
                    adaptData.metaData.conditionName), 'omitnan') == 1
                ogafterData      = adaptData.getParamInCond( ...
                    params, 'OG post');
                OGafter(ss, :)      = mean( ...
                    ogafterData(1:transientNumPts, :), 'omitnan');
                OGafterEarly(ss, :) = mean( ...
                    ogafterData(transientNumPts+1: ...
                        transientNumPts+20, :), 'omitnan');
                OGafterLate(ss, :)  = mean( ...
                    ogafterData((end-5)-steadyNumPts+1:(end-5), :), ...
                    'omitnan');
                AvgOGafter(ss, :)   = mean( ...
                    ogafterData(1:min([end 50])), 'omitnan'); %#ok<FNDSB>
            end

            if sum(cellfun(@(x) strcmp(x, 'TM post'), ...
                    adaptData.metaData.conditionName), 'omitnan') == 1
                tmafterData       = adaptData.getParamInCond( ...
                    params, 'TM post');
                TMafter(ss, :)      = mean( ...
                    tmafterData(1:transientNumPts, :), 'omitnan');
                TMafterEarly(ss, :) = mean( ...
                    tmafterData(transientNumPts+1: ...
                        transientNumPts+20, :), 'omitnan');
                TMafterLate(ss, :)  = mean( ...
                    tmafterData((end-5)-steadyNumPts+1:(end-5), :), ...
                    'omitnan');
            end
        end

        if sum(cellfun(@(x) strcmp(x, 'catch'), ...
                lower(adaptData.metaData.conditionName)), ...
                'omitnan') == 1
            adapt1Data           = adaptData.getParamInCond( ...
                params, 'adaptation');
            adapt1Velocity       = adaptData.getParamInCond( ...
                'velocityContributionNorm2', 'adaptation');

            AdaptExtentBeforeCatch(ss, :) = mean( ...
                adapt1Data((end-5)-transientNumPts+1:(end-5), :), ...
                'omitnan');

            idx = find(strcmpi(params, 'stepLengthAsym'));
            if isempty(idx)
                idx = find(strcmpi(params, 'netContributionNorm2'));
            end
            if ~isempty(idx)
                AdaptExtentBeforeCatch(ss, idx) = ...
                    AdaptExtentBeforeCatch(ss, idx) - mean( ...
                    adapt1Velocity((end-2)-transientNumPts+1:(end-2), :), ...
                    'omitnan');
            end

            AvgAdaptBeforeCatch(ss, :) = mean(adapt1Data, 'omitnan');
        end

        adapt2Data = [];
        if sum(cellfun(@(x) strcmp(x, 're-adaptation'), ...
                lower(adaptData.metaData.conditionName)), ...
                'omitnan') == 1
            adapt2Data     = adaptData.getParamInCond( ...
                params, 're-adaptation');
            adapt2Sasym    = adaptData.getParamInCond( ...
                'stepLengthAsym', 're-adaptation');
            adapt2Velocity = adaptData.getParamInCond( ...
                'velocityContributionNorm2', 're-adaptation');
        elseif isempty(adapt2Data)
            adapt2Data     = adaptData.getParamInCond( ...
                params, {'adaptation'});
            adapt2Sasym    = adaptData.getParamInCond( ...
                'stepLengthAsym', 'adaptation');
            adapt2Velocity = adaptData.getParamInCond( ...
                'velocityContributionNorm2', 'adaptation');
        end

        AdaptIndex(ss, :) = mean( ...
            adapt2Data((end-5)-steadyNumPts+1:(end-5), :), 'omitnan');

        idx = find(strcmpi(params, 'stepLengthAsym'));
        if isempty(idx)
            idx = find(strcmpi(params, 'netContributionNorm2'));
        end
        if ~isempty(idx)
            AdaptIndex(ss, idx) = mean( ...
                adapt2Sasym((end-5)-steadyNumPts+1:(end-5), :) - ...
                adapt2Velocity((end-5)-steadyNumPts+1:(end-5), :), ...
                'omitnan');
        end

        AdaptExtent(ss, :) = mean( ...
            adapt2Sasym((end-5)-steadyNumPts+1:(end-5), :) - ...
            adapt2Velocity((end-5)-steadyNumPts+1:(end-5), :), ...
            'omitnan');

        adaptAllData        = adaptData.getParamInCond( ...
            params, {'adaptation', 're-adaptation'});
        AvgAdaptAll(ss, :) = mean(adaptAllData, 'omitnan');

        mu     = mean(TMbaseData, 'omitnan');
        sigma  = std(TMbaseData, 0, 'omitnan');
        upper  = mu + 2 .* sigma;
        lowerb = mu - 2 .* sigma;
        for ii = 1:nParams
            outside(ii) = sum( ...
                adapt1Data(:, ii) > upper(ii) | ...
                adapt1Data(:, ii) < lowerb(ii)); %#ok<AGROW>
        end
        ErrorsOut(ss, :) = 100 .* (outside ./ size(adapt1Data, 1));
    end

    %calculate relative after-effects
    if sum(cellfun(@(x) strcmp(x, 'OG post'), ...
            adaptData.metaData.conditionName), 'omitnan') == 1 && ...
            sum(cellfun(@(x) strcmp(x, 'adaptation'), ...
            lower(adaptData.metaData.conditionName)), ...
            'omitnan') == 1 || ...
            sum(cellfun(@(x) strcmp(x, 're-adaptation'), ...
            lower(adaptData.metaData.conditionName)), ...
            'omitnan') == 1

        idx = find(strcmpi(params, 'stepLengthAsym'));
        if isempty(idx)
            idx = find(strcmpi(params, 'netContributionNorm2'));
        end
        if ~isempty(idx)
            Transfer  = 100 * (OGafter ./ ...
                (Catch(:, idx) * ones(1, nParams)));
        else
            Transfer  = 100 * (OGafter ./ Catch);
        end
        Transfer2 = 100 * (OGafter ./ (AdaptExtent * ones(1, nParams)));
    end

    if sum(cellfun(@(x) strcmp(x, 'adaptation'), ...
            lower(adaptData.metaData.conditionName)), ...
            'omitnan') == 1 || ...
            sum(cellfun(@(x) strcmp(x, 're-adaptation'), ...
            lower(adaptData.metaData.conditionName)), ...
            'omitnan') == 1

        idx = find(strcmpi(params, 'stepLengthAsym'));
        if isempty(idx)
            idx = find(strcmpi(params, 'netContributionNorm2'));
        end
        if ~isempty(idx)
            Washout  = 100 * (1 - (TMafter ./ ...
                (Catch(:, idx) * ones(1, nParams))));
        else
            Washout  = 100 * (1 - (TMafter ./ Catch));
        end
        Washout2 = 100 - (100 * (TMafter ./ ...
            (AdaptExtent * ones(1, nParams))));
    end

    for jj = 1:length(outcomeMeasures)
        eval(['results.(outcomeMeasures{jj}).avg(gg, :) = mean(' ...
            outcomeMeasures{jj} ', 1, ''omitnan'');']);
        eval(['results.(outcomeMeasures{jj}).se(gg, :) = std(' ...
            outcomeMeasures{jj} ' ./ sqrt(nSubs), 0, ''omitnan'');']);
    end

    % NOTE: indiv struct format chosen for SPSS export compatibility.
    if gg == 1
        if plotFlag
            for pp = 1:nParams
                for mm = 1:length(outcomeMeasures)
                    eval(['results.(outcomeMeasures{mm}).indiv.' ...
                        '(params{pp}) = [gg*ones(nSubs,1) ' ...
                        outcomeMeasures{mm} '(:,pp)];'])
                end
            end
        else
            for mm = 1:length(outcomeMeasures)
                eval(['results.(outcomeMeasures{mm}).indiv=' ...
                    '[gg*ones(nSubs,1) ' outcomeMeasures{mm} '];'])
            end
        end
    else
        if plotFlag
            for pp = 1:nParams
                for mm = 1:length(outcomeMeasures)
                    eval(['results.(outcomeMeasures{mm}).indiv.' ...
                        '(params{pp})(end+1:end+nSubs,1:2) = ' ...
                        '[gg*ones(nSubs,1) ' ...
                        outcomeMeasures{mm} '(:,pp)];'])
                end
            end
        else
            for mm = 1:length(outcomeMeasures)
                eval(['results.(outcomeMeasures{mm}).indiv' ...
                    '(end+1:end+nSubs,:)=[gg*ones(nSubs,1) ' ...
                    outcomeMeasures{mm} '];'])
            end
        end
    end
end

%% Plot
if plotFlag
    %     epochs={'AdaptExtent','Catch','OGafter','TMafter'};
    %     if nargin>5
    %         barGroups(Study,results,groups,params,epochs,indivFlag)
    %     else
    %         barGroups(Study,results,groups,params,epochs)
    %     end

    %     epochs={'AvgAdaptBeforeCatch','TMsteadyBeforeCatch','AvgAdaptAll','TMsteady'};
    %     if nargin>5
    %         barGroups(SMatrix,results,groups,params,epochs,indivFlag)
    %     else
    %         barGroups(SMatrix,results,groups,params,epochs)
    %     end

    %     epochs={'AvgAdaptAll','TMsteady','catch','Transfer'};
    %     if nargin>5
    %         barGroups(SMatrix,results,groups,params,epochs,indivFlag)
    %     else
    %         barGroups(SMatrix,results,groups,params,epochs)
    %     end
end

end
