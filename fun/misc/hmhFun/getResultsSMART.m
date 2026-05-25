function results = getResultsSMART(SMatrix, params, groups, ...
    maxPerturb, plotFlag, indivFlag)
%GETRESULTSSMART Compute adaptation results with strides-to-SS and
% forgetting metrics.
%
%   Computes standard adaptation outcome measures (catch, steady state,
% after-effects, transfer, washout) plus percent-forgetting between
% adaptation blocks and strides-to-steady-state per group.
%
% Inputs:
%   SMatrix    - Struct with group fields, each a groupAdaptationData
%                object (from makeSMatrixV2)
%   params     - Cell array of parameter name strings
%   groups     - Cell array of group name strings; defaults to all
%                fields of SMatrix when empty
%   maxPerturb - If 1, use smoothedMax for after-effects; else use mean
%   plotFlag   - Logical; if true, create bar plots
%   indivFlag  - Logical; if true, overlay individual subjects on bars
%
% Outputs:
%   results - Struct with outcome-measure fields, each containing avg,
%             se, and indiv sub-structs
%
% Toolbox Dependencies: None
%
% See also CALCSTRIDES2SS, SMOOTHEDMAX, BARGROUPS, GETRESULTS.

catchNumPts     = 3;   % catch
steadyNumPts    = 40;  % end of adaptation
transientNumPts = 5;   % OG and washout

if nargin < 3 || isempty(groups)
    groups = fields(SMatrix);
end
ngroups = length(groups);

results.OGbase.avg  = [];
results.OGbase.se   = [];
results.TMbase.avg  = [];
results.TMbase.se   = [];

results.AvgAdaptBeforeCatch.avg = [];
results.AvgAdaptBeforeCatch.se  = [];
results.AvgAdaptAll.avg         = [];
results.AvgAdaptAll.se          = [];
results.ErrorsOut.avg           = [];
results.ErrorsOut.se            = [];

results.TMsteadyBeforeCatch.avg = [];
results.TMsteadyBeforeCatch.se  = [];
results.catch.avg               = [];
results.catch.se                = [];
results.TMsteady.avg            = [];
results.TMsteady.se             = [];
results.OGafter.avg             = [];
results.OGafter.se              = [];
results.TMafter.avg             = [];
results.TMafter.se              = [];
results.Transfer.avg            = [];
results.Transfer.se             = [];
results.Washout.avg             = [];
results.Washout.se              = [];
results.Transfer2.avg           = [];
results.Transfer2.se            = [];
results.Washout2.avg            = [];
results.Washout2.se             = [];

%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ From CJS
results.Strides2SS.avg = [];
results.Strides2SS.se  = [];
results.PerForget.avg  = [];
results.PerForget.se   = [];
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

for gg = 1:ngroups

    subjects = SMatrix.(groups{gg}).ID;

    OGbase     = [];
    TMbase     = [];
    avgAdaptBC = [];
    avgAdaptAll = [];
    errorsOut  = [];
    tmsteadyBC = [];
    tmCatch    = [];
    tmsteady   = [];
    ogafter    = [];
    tmafter    = [];
    transfer   = [];
    washout    = [];
    transfer2  = [];
    washout2   = [];

    %~~~~~~~~~~~
    perforget  = [];
    Strides2SS = [];
    %~~~~~~~~~~~

    for ss = 1:length(subjects)
        adaptData = SMatrix.(groups{gg}).adaptData{ss};
        adaptData = adaptData.removeBadStrides();
        adaptData = adaptData.removeBias();

        if nargin > 3 && maxPerturb == 1

            stepAsymData = adaptData.getParamInCond( ...
                'stepLengthAsym', 'OG base');
            OGbaseData   = adaptData.getParamInCond(params, 'OG base');
            OGbase = [OGbase; smoothedMax(OGbaseData(1:10, :), ...
                transientNumPts, stepAsymData(1:10))]; %#ok<AGROW>

            stepAsymData = adaptData.getParamInCond( ...
                'stepLengthAsym', 'TM base');
            TMbaseData   = adaptData.getParamInCond(params, 'TM base');
            if isempty(TMbaseData)
                stepAsymData = adaptData.getParamInCond( ...
                    'stepLengthAsym', {'slow base', 'fast base'});
                TMbaseData   = adaptData.getParamInCond( ...
                    params, {'slow base', 'fast base'});
            end
            TMbase = [TMbase; smoothedMax(TMbaseData(1:10, :), ...
                transientNumPts, stepAsymData(1:10))]; %#ok<AGROW>

            stepAsymData = adaptData.getParamInCond( ...
                'stepLengthAsym', 'catch');
            tmcatchData  = adaptData.getParamInCond(params, 'catch');
            tmCatch = [tmCatch; smoothedMax(tmcatchData, ...
                transientNumPts, stepAsymData)]; %#ok<AGROW>

            stepAsymData = adaptData.getParamInCond( ...
                'stepLengthAsym', 'OG post');
            ogafterData  = adaptData.getParamInCond(params, 'OG post');
            ogafter = [ogafter; smoothedMax(ogafterData(1:10, :), ...
                transientNumPts, stepAsymData(1:10))]; %#ok<AGROW>

            stepAsymData = adaptData.getParamInCond( ...
                'stepLengthAsym', 'TM post');
            tmafterData  = adaptData.getParamInCond(params, 'TM post');
            tmafter = [tmafter; smoothedMax(tmafterData(1:10, :), ...
                transientNumPts, stepAsymData(1:10))]; %#ok<AGROW>

        else

            % If there are overground trials
            if isempty(cellfun(@(x) strcmp(x, 'OG base'), ...
                    adaptData.metaData.conditionName)) == 0
                OGbaseData = adaptData.getParamInCond( ...
                    params, 'OG base');
                OGbase = [OGbase; ...
                    mean(OGbaseData(1:transientNumPts, :), ...
                        'omitnan')]; %#ok<AGROW>
            end

            if isempty(cellfun(@(x) strcmp(x, 'OG post'), ...
                    adaptData.metaData.conditionName)) == 0
                ogafterData = adaptData.getParamInCond( ...
                    params, 'OG post');
                ogafter = [ogafter; ...
                    mean(ogafterData(1:transientNumPts, :), ...
                        'omitnan')]; %#ok<AGROW>
            end

            if isempty(cellfun(@(x) strcmp(x, 'TM base'), ...
                    adaptData.metaData.conditionName)) == 0
                TMbaseData = adaptData.getParamInCond( ...
                    params, 'TM base');
            else
                TMbaseData = adaptData.getParamInCond( ...
                    params, {'slow base', 'fast base'});
            end
            TMbase = [TMbase; ...
                mean(TMbaseData(1:transientNumPts, :), ...
                    'omitnan')]; %#ok<AGROW>

            % If there is a catch
            if isempty(cellfun(@(x) strcmp(x, 'catch'), ...
                    adaptData.metaData.conditionName)) == 0
                tmcatchData = adaptData.getParamInCond( ...
                    params, 'catch');
                if isempty(tmcatchData)
                    newtmcatchData = NaN(1, length(params));
                elseif size(tmcatchData, 1) < 3
                    newtmcatchData = mean(tmcatchData, 'omitnan');
                else
                    newtmcatchData = mean( ...
                        tmcatchData(1:catchNumPts, :), 'omitnan');
                    %newtmcatchData=mean(tmcatchData,'omitnan');
                end
                tmCatch = [tmCatch; newtmcatchData]; %#ok<AGROW>
            end

            if isempty(cellfun(@(x) strcmp(x, 'TM post'), ...
                    adaptData.metaData.conditionName)) == 0
                tmafterData = adaptData.getParamInCond( ...
                    params, 'TM post');
                tmafter = [tmafter; ...
                    mean(tmafterData(1:transientNumPts, :), ...
                        'omitnan')]; %#ok<AGROW>
            end
        end

        % If there is a catch
        if isempty(cellfun(@(x) strcmp(x, 'catch'), ...
                adaptData.metaData.conditionName)) == 0
            adapt1Data = adaptData.getParamInCond(params, 'adaptation');
            tmsteadyBC = [tmsteadyBC; ...
                mean(adapt1Data( ...
                    (end-5) - steadyNumPts + 1:(end-5), :), ...
                    'omitnan')]; %#ok<AGROW>

            if isempty(cellfun(@(x) strcmp(x, 're-adaptation'), ...
                    adaptData.metaData.conditionName)) == 0
                adapt2Data = adaptData.getParamInCond( ...
                    params, 're-adaptation');
                if isempty(adapt2Data)
                    adapt2Data = adaptData.getParamInCond( ...
                        params, 'readaptation');
                end
                tmsteady = [tmsteady; ...
                    mean(adapt2Data( ...
                        (end-5) - steadyNumPts + 1:(end-5), :), ...
                        'omitnan')]; %#ok<AGROW>
            end

            avgAdaptBC = [avgAdaptBC; ...
                mean(adapt1Data, 'omitnan')]; %#ok<AGROW>

            adaptAllData = adaptData.getParamInCond( ...
                params, {'adaptation', 're-adaptation'});
            avgAdaptAll = [avgAdaptAll; ...
                mean(adaptAllData, 'omitnan')]; %#ok<AGROW>
        else
            adapt2Data = adaptData.getParamInCond( ...
                params, 'adaptation');
            tmsteady = [tmsteady; ...
                mean(adapt2Data( ...
                    (end-5) - steadyNumPts + 1:(end-5), :), ...
                    'omitnan')]; %#ok<AGROW>
        end

        %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        % Compute percent-forgetting (CJS, 07/2015)
        test = adaptData.metaData.conditionName;
        test(cellfun(@isempty, test)) = {''};
        epoch       = find(ismember(test, 'adaptation') == 1);
        wantedtrials = adaptData.metaData.trialsInCondition{epoch};
        forgetB1Data = adaptData.getParamInTrial( ...
            params, wantedtrials(1));
        forgetB2Data = adaptData.getParamInTrial( ...
            params, wantedtrials(2));
        forgetB3Data = adaptData.getParamInTrial( ...
            params, wantedtrials(3));
        forgetB4Data = adaptData.getParamInTrial( ...
            params, wantedtrials(4));

        idxNET  = find(strcmp(params, 'netContributionNorm2'));
        idxVELO = find(strcmp(params, 'velocityContributionNorm2'));
        idxGOOD = find(strcmp(params, 'good'));

        if isempty(idxNET) == 0
            minvalues        = zeros(1, length(params)); %#ok<NASGU>
            minValue(idxNET) = abs( ...
                tmsteady(ss, idxVELO) - tmsteady(ss, idxNET));
            forgetB1Data = forgetB1Data + ...
                repmat(minValue, length(forgetB1Data), 1);
            forgetB2Data = forgetB2Data + ...
                repmat(minValue, length(forgetB2Data), 1);
            forgetB3Data = forgetB3Data + ...
                repmat(minValue, length(forgetB3Data), 1);
            forgetB4Data = forgetB4Data + ...
                repmat(minValue, length(forgetB4Data), 1);
        end

        per = [...
            (mean(forgetB1Data(end-29:end-10, :), 'omitnan') - ...
             mean(forgetB2Data(1:5, :), 'omitnan')) ./ ...
             mean(forgetB1Data(end-29:end-10, :), 'omitnan'); ...
            (mean(forgetB2Data(end-29:end-10, :), 'omitnan') - ...
             mean(forgetB3Data(1:5, :), 'omitnan')) ./ ...
             mean(forgetB2Data(end-29:end-10, :), 'omitnan'); ...
            (mean(forgetB3Data(end-29:end-10, :), 'omitnan') - ...
             mean(forgetB4Data(1:5, :), 'omitnan')) ./ ...
             mean(forgetB3Data(end-29:end-10, :), 'omitnan')];

        perforget = [perforget; ...
            100 * mean(per, 'omitnan')]; %#ok<AGROW>

        if isempty(idxGOOD) == 0
            perforget = tmsteady;
        end
        %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        % Compute strides-to-steady-state (CJS, 07/2015)
        if isempty(idxNET) == 0
            Strides2SS = [Strides2SS; CalcStrides2SS(adaptAllData, ...
                tmsteady(ss, :), params, 0, ...
                adaptData.subData.ID)]; %#ok<AGROW>
        else
            Strides2SS = [Strides2SS; ...
                NaN .* ones(1, length(params))]; %#ok<AGROW>
        end

        if isempty(idxGOOD) == 0
            Strides2SS = tmsteady;
        end
        %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        mu    = mean(TMbaseData, 'omitnan');
        sigma = std(TMbaseData, 0, 'omitnan');
        upper = mu + 2 .* sigma;
        lower = mu - 2 .* sigma;
        for ii = 1:length(params)
            outside(ii) = sum( ...
                adapt1Data(:, ii) > upper(ii) | ...
                adapt1Data(:, ii) < lower(ii)); %#ok<AGROW>
        end
        errorsOut = [errorsOut; ...
            100 .* (outside ./ size(adapt1Data, 1))]; %#ok<AGROW>
    end

    % If there is OG walking — calculate relative after-effects
    if isempty(cellfun(@(x) strcmp(x, 'OG post'), ...
            adaptData.metaData.conditionName)) == 0
        idx = find(strcmp(params, 'stepLengthAsym'));
        if ~isempty(idx)
            transfer = [transfer; ...
                100 * (ogafter ./ ...
                    (tmCatch(:, idx) * ones(1, length(params))))]; %#ok<AGROW>
        else
            transfer = [transfer; 100 * (ogafter ./ tmCatch)]; %#ok<AGROW>
        end
        transfer2 = [transfer2; ...
            100 * (ogafter ./ tmsteady)]; %#ok<AGROW>
    end

    washout  = [washout;  100 - (100 * (tmafter ./ tmCatch))];   %#ok<AGROW>
    washout2 = [washout2; 100 - (100 * (tmafter ./ tmsteady))];  %#ok<AGROW>

    nSubs = length(subjects);

    results.OGbase.avg(end+1, :) = mean(OGbase, 1, 'omitnan');
    results.OGbase.se(end+1, :)  = std(OGbase, 0, 1, 'omitnan') ./ sqrt(nSubs);

    results.TMbase.avg(end+1, :) = mean(TMbase, 1, 'omitnan');
    results.TMbase.se(end+1, :)  = std(TMbase, 0, 1, 'omitnan');

    results.AvgAdaptBeforeCatch.avg(end+1, :) = ...
        mean(avgAdaptBC, 1, 'omitnan');
    results.AvgAdaptBeforeCatch.se(end+1, :)  = ...
        std(avgAdaptBC, 0, 1, 'omitnan') ./ sqrt(nSubs);

    results.AvgAdaptAll.avg(end+1, :) = mean(avgAdaptAll, 1, 'omitnan');
    results.AvgAdaptAll.se(end+1, :)  = ...
        std(avgAdaptAll, 0, 1, 'omitnan') ./ sqrt(nSubs);

    results.ErrorsOut.avg(end+1, :) = mean(errorsOut, 1, 'omitnan');
    results.ErrorsOut.se(end+1, :)  = ...
        std(errorsOut, 0, 1, 'omitnan') ./ sqrt(nSubs);

    results.TMsteadyBeforeCatch.avg(end+1, :) = ...
        mean(tmsteadyBC, 1, 'omitnan');
    results.TMsteadyBeforeCatch.se(end+1, :)  = ...
        std(tmsteadyBC, 0, 1, 'omitnan') ./ sqrt(nSubs);

    results.catch.avg(end+1, :) = mean(tmCatch, 1, 'omitnan');
    results.catch.se(end+1, :)  = ...
        std(tmCatch, 0, 1, 'omitnan') ./ sqrt(nSubs);

    results.TMsteady.avg(end+1, :) = mean(tmsteady, 1, 'omitnan');
    results.TMsteady.se(end+1, :)  = ...
        std(tmsteady, 0, 1, 'omitnan') ./ sqrt(nSubs);

    results.OGafter.avg(end+1, :) = mean(ogafter, 1, 'omitnan');
    results.OGafter.se(end+1, :)  = ...
        std(ogafter, 0, 1, 'omitnan') ./ sqrt(nSubs);

    results.TMafter.avg(end+1, :) = mean(tmafter, 1, 'omitnan');
    results.TMafter.se(end+1, :)  = ...
        std(tmafter, 0, 1, 'omitnan') ./ sqrt(nSubs);

    results.Transfer.avg(end+1, :) = mean(transfer, 1, 'omitnan');
    results.Transfer.se(end+1, :)  = ...
        std(transfer, 0, 1, 'omitnan') ./ sqrt(nSubs);

    results.Washout.avg(end+1, :) = mean(washout, 1, 'omitnan');
    results.Washout.se(end+1, :)  = ...
        std(washout, 0, 1, 'omitnan') ./ sqrt(nSubs);

    results.Transfer2.avg(end+1, :) = mean(transfer2, 1, 'omitnan');
    results.Transfer2.se(end+1, :)  = ...
        std(transfer2, 0, 1, 'omitnan') ./ sqrt(nSubs);

    results.Washout2.avg(end+1, :) = mean(washout2, 1, 'omitnan');
    results.Washout2.se(end+1, :)  = ...
        std(washout2, 0, 1, 'omitnan') ./ sqrt(nSubs);

    results.PerForget.avg(end+1, :) = mean(perforget, 1, 'omitnan');
    results.PerForget.se(end+1, :)  = ...
        std(perforget, 0, 1, 'omitnan') ./ sqrt(nSubs);

    results.Strides2SS.avg(end+1, :) = mean(Strides2SS, 1, 'omitnan');
    results.Strides2SS.se(end+1, :)  = ...
        std(Strides2SS, 0, 1, 'omitnan') ./ sqrt(nSubs);

    % NOTE: The results.(m).indiv struct layout is structured this way
    % for compatibility with SPSS export.
    if gg == 1
        for pp = 1:length(params)
            results.OGbase.indiv.(params{pp})  = ...
                [gg * ones(nSubs, 1) OGbase(:, pp)];
            results.TMbase.indiv.(params{pp})  = ...
                [gg * ones(nSubs, 1) TMbase(:, pp)];
            results.AvgAdaptBeforeCatch.indiv.(params{pp}) = ...
                [gg * ones(nSubs, 1) avgAdaptBC(:, pp)];
            results.AvgAdaptAll.indiv.(params{pp}) = ...
                [gg * ones(nSubs, 1) avgAdaptAll(:, pp)];
            results.ErrorsOut.indiv.(params{pp}) = ...
                [gg * ones(nSubs, 1) errorsOut(:, pp)];
            results.TMsteadyBeforeCatch.indiv.(params{pp}) = ...
                [gg * ones(nSubs, 1) tmsteadyBC(:, pp)];
            results.catch.indiv.(params{pp})   = ...
                [gg * ones(nSubs, 1) tmCatch(:, pp)];
            results.TMsteady.indiv.(params{pp}) = ...
                [gg * ones(nSubs, 1) tmsteady(:, pp)];
            results.OGafter.indiv.(params{pp}) = ...
                [gg * ones(nSubs, 1) ogafter(:, pp)];
            results.TMafter.indiv.(params{pp}) = ...
                [gg * ones(nSubs, 1) tmafter(:, pp)];
            results.Transfer.indiv.(params{pp}) = ...
                [gg * ones(nSubs, 1) transfer(:, pp)];
            results.Washout.indiv.(params{pp}) = ...
                [gg * ones(nSubs, 1) washout(:, pp)];
            results.Transfer2.indiv.(params{pp}) = ...
                [gg * ones(nSubs, 1) transfer2(:, pp)];
            results.Washout2.indiv.(params{pp}) = ...
                [gg * ones(nSubs, 1) washout2(:, pp)];
            results.Strides2SS.indiv.(params{pp}) = ...
                [gg * ones(nSubs, 1) Strides2SS(:, pp)];
            results.PerForget.indiv.(params{pp}) = ...
                [gg * ones(nSubs, 1) perforget(:, pp)];
        end
    else
        for pp = 1:length(params)
            results.OGbase.indiv.(params{pp})( ...
                end+1:end+nSubs, 1:2) = ...
                [gg * ones(nSubs, 1) OGbase(:, pp)];
            results.TMbase.indiv.(params{pp})( ...
                end+1:end+nSubs, 1:2) = ...
                [gg * ones(nSubs, 1) TMbase(:, pp)];
            results.AvgAdaptBeforeCatch.indiv.(params{pp})( ...
                end+1:end+nSubs, 1:2) = ...
                [gg * ones(nSubs, 1) avgAdaptBC(:, pp)];
            results.AvgAdaptAll.indiv.(params{pp})( ...
                end+1:end+nSubs, 1:2) = ...
                [gg * ones(nSubs, 1) avgAdaptAll(:, pp)];
            results.ErrorsOut.indiv.(params{pp})( ...
                end+1:end+nSubs, 1:2) = ...
                [gg * ones(nSubs, 1) errorsOut(:, pp)];
            results.TMsteadyBeforeCatch.indiv.(params{pp})( ...
                end+1:end+nSubs, 1:2) = ...
                [gg * ones(nSubs, 1) tmsteadyBC(:, pp)];
            results.catch.indiv.(params{pp})( ...
                end+1:end+nSubs, 1:2) = ...
                [gg * ones(nSubs, 1) tmCatch(:, pp)];
            results.TMsteady.indiv.(params{pp})( ...
                end+1:end+nSubs, 1:2) = ...
                [gg * ones(nSubs, 1) tmsteady(:, pp)];
            results.OGafter.indiv.(params{pp})( ...
                end+1:end+nSubs, 1:2) = ...
                [gg * ones(nSubs, 1) ogafter(:, pp)];
            results.TMafter.indiv.(params{pp})( ...
                end+1:end+nSubs, 1:2) = ...
                [gg * ones(nSubs, 1) tmafter(:, pp)];
            results.Transfer.indiv.(params{pp})( ...
                end+1:end+nSubs, 1:2) = ...
                [gg * ones(nSubs, 1) transfer(:, pp)];
            results.Washout.indiv.(params{pp})( ...
                end+1:end+nSubs, 1:2) = ...
                [gg * ones(nSubs, 1) washout(:, pp)];
            results.Transfer2.indiv.(params{pp})( ...
                end+1:end+nSubs, 1:2) = ...
                [gg * ones(nSubs, 1) transfer2(:, pp)];
            results.Washout2.indiv.(params{pp})( ...
                end+1:end+nSubs, 1:2) = ...
                [gg * ones(nSubs, 1) washout2(:, pp)];
            results.Strides2SS.indiv.(params{pp}) = ...
                [gg * ones(nSubs, 1) Strides2SS(:, pp)];
            results.PerForget.indiv.(params{pp}) = ...
                [gg * ones(nSubs, 1) perforget(:, pp)];
        end
    end
end

%% Plot
if nargin > 4 && plotFlag
    epochs = {'TMsteady', 'catch', 'OGafter', 'TMafter'};
    if nargin > 5
        barGroups(SMatrix, results, groups, params, epochs, indivFlag)
    else
        barGroups(SMatrix, results, groups, params, epochs)
    end

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
