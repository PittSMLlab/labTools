function results = getForceResults(SMatrix, params, groups, ...
        maxPerturb, plotFlag, indivFlag, removeBias)
%GETFORCERESULTS Compute force-parameter adaptation results per group.
%
%   Loads adaptation data for each subject from SMatrix, computes
% group-level force-parameter results for several adaptation epochs,
% and returns group means and standard errors. Optionally runs group
% statistics and generates bar plots.
%
% Inputs:
%   SMatrix    - Struct with group fields; each group has an ID field
%                and an adaptData cell array of adaptationData objects
%   params     - Cell array of parameter name strings to analyse
%   groups     - Cell array of group name strings; defaults to all
%                fields of SMatrix when empty
%   maxPerturb - (unused) maximum perturbation value
%   plotFlag   - If provided and non-empty, generate bar plots
%   indivFlag  - If provided and non-empty, overlay individual subjects
%   removeBias - Set to 0 to skip bias removal; default removes bias
%
% Outputs:
%   results - Struct with sub-structs for each adaptation epoch (avg,
%             se, indiv, p fields): DelFAdapt, DelFDeAdapt, TMSteady,
%             TMafter, TMSteadyWBias, TMafterWBias, SlowBase, FastBase,
%             MidBase, BaseAdapDiscont, BasePADiscont,
%             SpeedAdapDiscont, SpeedSSDiscont, SpeedPADiscont, EarlyA,
%             LateP, Washout2, FlatWash, PLearn, lenA
%
% Toolbox Dependencies: None
%
% See also BARGROUPS.

catchNumPts     = 3;   % catch %#ok<NASGU>
steadyNumPts    = 40;  % end of adaptation
transientNumPts = 5;   % OG and washout

if nargin < 3 || isempty(groups)
    groups = fields(SMatrix);
end
ngroups = length(groups);

%% Initialize outputs

results.DelFAdapt.avg        = [];
results.DelFAdapt.se         = [];
results.DelFDeAdapt.avg      = [];
results.DelFDeAdapt.se       = [];

results.TMSteady.avg         = [];
results.TMSteady.se          = [];
results.TMafter.avg          = [];
results.TMafter.se           = [];
results.TMSteadyWBias.avg    = [];
results.TMSteadyWBias.se     = [];
results.TMafterWBias.avg     = [];
results.TMafterWBias.se      = [];

results.SlowBase.avg = [];
results.SlowBase.se  = [];
results.FastBase.avg = [];
results.FastBase.se  = [];
results.MidBase.avg  = [];
results.MidBase.se   = [];

results.BaseAdapDiscont.avg  = [];
results.BaseAdapDiscont.se   = [];
results.BasePADiscont.avg    = [];
results.BasePADiscont.se     = [];
results.SpeedAdapDiscont.avg = [];
results.SpeedAdapDiscont.se  = [];
results.SpeedSSDiscont.avg   = [];
results.SpeedSSDiscont.se    = [];
results.SpeedPADiscont.avg   = [];
results.SpeedPADiscont.se    = [];

results.EarlyA.avg = [];
results.EarlyA.se  = [];
results.LateP.avg  = [];
results.LateP.se   = [];

results.Washout2.avg = [];
results.Washout2.se  = [];
results.FlatWash.avg = [];
results.FlatWash.se  = [];
results.PLearn.avg   = [];
results.PLearn.se    = [];
results.lenA.avg     = [];
results.lenA.se      = [];

%% Compute per-group results

for gg = 1:ngroups

    subjects = SMatrix.(groups{gg}).ID;

    DelFAdapt        = [];
    DelFDeAdapt      = [];
    FBase            = [];
    SBase            = [];
    MBase            = [];
    TMSteady         = [];
    tmafter          = [];
    BaseAdapDiscont  = [];
    BasePADiscont    = [];
    TMSteadyWBias    = [];
    tmafterWBias     = [];
    SpeedAdapDiscont = [];
    SpeedPADiscont   = [];
    EarlyA           = [];
    LateP            = [];
    washout2         = [];
    FlatWash         = [];
    plearn           = [];
    lenA             = [];
    SpeedSSDiscont   = [];

    for ss = 1:length(subjects)
        adaptData = SMatrix.(groups{gg}).adaptData{ss};

        adaptData = adaptData.removeBadStrides();
                %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% %         if  ~exist('removeBias') || removeBias==1
% %             adaptData=adaptData.removeBiasV3;
% %         end
        nSubs = length(subjects);
        %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        % Calculate parameters — with bias included
        %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        AANamesWBias = adaptData.metaData.conditionName( ...
            find(cellfun(@(x) ~isempty(x), ...
                regexp(lower(adaptData.metaData.conditionName), ...
                'ada')), 1, 'first'));
        ADataWBias = adaptData.getParamInCond(params, AANamesWBias);

        if strcmp(groups(gg), 'InclineStroke')
            EarlyPANamesWBias = adaptData.metaData.conditionName( ...
                find(cellfun(@(x) ~isempty(x), ...
                    regexp(lower(adaptData.metaData.conditionName), ...
                    'catch'))));
            LatePANamesWBias = adaptData.metaData.conditionName( ...
                find(cellfun(@(x) ~isempty(x), ...
                    regexp(lower(adaptData.metaData.conditionName), ...
                    'TM base'))));
            PDataEarlyWBias = adaptData.getParamInCond( ...
                params, EarlyPANamesWBias);
            PDataLateWBias = adaptData.getParamInCond( ...
                params, LatePANamesWBias);
        else
            PANamesWBias = adaptData.metaData.conditionName( ...
                find(cellfun(@(x) ~isempty(x), ...
                    regexp(lower(adaptData.metaData.conditionName), ...
                    'ada')), 1, 'first') + 1);
            if strcmp(PANamesWBias, 'catch')
                PANamesWBias = adaptData.metaData.conditionName( ...
                    find(cellfun(@(x) ~isempty(x), ...
                        regexp(lower( ...
                        adaptData.metaData.conditionName), ...
                        'ada')), 2, 'first') + 1);
            end
            PDataWBias = adaptData.getParamInCond(params, PANamesWBias);
        end
% %         %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%         if  ~exist('removeBias') || removeBias==1
%             adaptData=adaptData.removeBiasV3;
%         end
%         nSubs=length(subjects);
%         %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        if isempty(find(cellfun(@(x) ~isempty(x), ...
                regexp(lower(adaptData.metaData.conditionName), ...
                'fast'))))
            FBaseData = NaN * ones(1, length(params));
        else
            FBaseData = adaptData.getParamInCond(params, 'fast');
        end

        if isempty(find(cellfun(@(x) ~isempty(x), ...
                regexp(lower(adaptData.metaData.conditionName), ...
                'slow'))))
            SBaseData = NaN * ones(1, length(params));
        else
            SBaseData = adaptData.getParamInCond(params, 'slow');
        end

        if isempty(find(cellfun(@(x) ~isempty(x), ...
                regexp(lower(adaptData.metaData.conditionName), ...
                'tm base'))))
            MBaseData = NaN * ones(1, length(params));
        else
            MBaseData = adaptData.getParamInCond(params, 'TM base');
        end

% % %         %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        if  ~exist('removeBias') || removeBias == 1
            adaptData = adaptData.removeBiasV3();
        end
        nSubs = length(subjects);
% % %
% % %         %%Calculate Params

        % Adaptation parameters
        %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        AANames = adaptData.metaData.conditionName( ...
            find(cellfun(@(x) ~isempty(x), ...
                regexp(lower(adaptData.metaData.conditionName), ...
                'ada')), 1, 'first'));
        AData  = adaptData.getParamInCond(params, AANames);
        EarlyA = [EarlyA; mean(AData(1:20, :), 1, 'omitnan')]; %#ok<AGROW>
        %EarlyA=[EarlyA; nanmean(AData(1:5,:))];%NORMAL WAY
        %tempTT=adaptData.getParamInCond(params,'TM base');
        lenA = [lenA; length(AData) .* ones(1, length(params))]; %#ok<AGROW>
        %          %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%         EarlyAtemp=[]; %New and probably temporary!
%         figure
%         for cat=1:length(params)
%             MedData=medfilt1(AData(:, cat), 10);
%             if strcmp(params(cat), 'FyBF')==1 || (strcmp(params(cat), 'FyPS')==1 && strcmp(groups{g}, 'DeclineYoungAbrupt')==1) || (strcmp(params(cat), 'FyPS')==1 && strcmp(groups{g}, 'FlatYoungAbrupt')==1)
% %                 subplot(2, 2, cat);
% %                 line([0 700],[nanmean(AData((end-5)-steadyNumPts+1:(end-5),cat)) nanmean(AData((end-5)-steadyNumPts+1:(end-5),cat))], 'Color', 'g', 'LineWidth', 5); hold on;
% %                 plot(AData(:, cat), '.k');
% %                 plot(MedData, 'r');
%                 EarlyAtemp=[EarlyAtemp max(MedData(5:100))];
% %                 line([0 700],[max(MedData(5:100)) max(MedData(5:100))],'Color', 'b');
% %                 line([0 700],[nanmean(AData(1:20,cat)) nanmean(AData(1:20,cat))],'Color', 'k', 'LineStyle',':');
% %                 title([subjects{s} params(cat) 'maxed'])
% %                 legend({'SS', 'Raw', 'Median filtered', 'Early', 'old Early'})
%             elseif strcmp(params(cat), 'FyBS')==1  || strcmp(params(cat), 'FyPF')==1 || (strcmp(params(cat), 'FyPS')==1 && strcmp(groups{g}, 'InclineYoungAbrupt')==1)
% %                 subplot(2, 2, cat);line([0 700],[nanmean(AData((end-5)-steadyNumPts+1:(end-5),cat)) nanmean(AData((end-5)-steadyNumPts+1:(end-5),cat))], 'Color', 'g', 'LineWidth', 5); hold on;
% %                 plot(AData(:, cat), '.k');
% %                 plot(MedData, 'r');
%                 EarlyAtemp=[EarlyAtemp min(MedData(5:100))];
% %                 line([0 700],[min(MedData(5:100)) min(MedData(5:100))],'Color', 'b');
% %                 line([0 700],[nanmean(AData(1:20,cat)) nanmean(AData(1:20,cat))],'Color', 'k', 'LineStyle',':');
% %                 title([subjects{s} params(cat) 'mined'])
%             end
%
%             clear MedData
%         end
%         EarlyA=[EarlyA; EarlyAtemp];
%         %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%          %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%         EarlyAtemp=[]; %New and probably temporary!
%         for cat=1:length(params)
%             EarlyAtemp=[EarlyAtemp smoothedMin(abs(AData(1:50, cat)),transientNumPts )];%NOT REALLY SURE IF THIS SHOULD ALWAYS BE MIN
%         end
%         EarlyA=[EarlyA; EarlyAtemp];
%         %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        %AData=adaptData.getParamInCond(params,'adaptation');
        %DelFAdapt=[DelFAdapt; nanmean(AData((end-5)-steadyNumPts+1:(end-5),:))-nanmean(AData(6:6+transientNumPts,:))];
        %DelFAdapt=[DelFAdapt; nanmean(AData(end-44:end-5, :))-nanmean(AData(1:5,:))];%OLD
        %DelFAdapt=[DelFAdapt; nanmean(AData(end-44:end-5, :))-EarlyA(s, :)];%NEW
        %TMSteady=[TMSteady; nanmean(AData(end-44:end-5, :))];%OROGNOAL

        TMSteady = [TMSteady; mean( ...
            AData((end-5)-steadyNumPts+1:(end-5), :), ...
            1, 'omitnan')]; %#ok<AGROW>
        %DelFAdapt=[DelFAdapt; nanmean(AData((end-5)-steadyNumPts+1:(end-5),:))-EarlyA(s, :)];%NEW
        DelFAdapt     = [DelFAdapt; ...
            TMSteady(ss, :) - EarlyA(ss, :)]; %#ok<AGROW>
        TMSteadyWBias = [TMSteadyWBias; mean( ...
            ADataWBias(end-44:end-5, :), 1, 'omitnan')]; %#ok<AGROW>

        % Post-adaptation parameters
        %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        if strcmp(groups(gg), 'InclineStroke')
            EarlyPANames = adaptData.metaData.conditionName( ...
                find(cellfun(@(x) ~isempty(x), ...
                    regexp(lower(adaptData.metaData.conditionName), ...
                    'catch'))));
            LatePANames = adaptData.metaData.conditionName( ...
                find(cellfun(@(x) ~isempty(x), ...
                    regexp(lower(adaptData.metaData.conditionName), ...
                    'TM base'))));
            % CJS --> Where I ought to code transfer if I want to look at
            % this...
            PDataEarly = adaptData.getParamInCond(params, EarlyPANames);
            PDataLate  = adaptData.getParamInCond(params, LatePANames);
            DelFDeAdapt = [DelFDeAdapt; ...
                mean(PDataLate(end-44:end-5, :), 1, 'omitnan') - ...
                mean(PDataEarly(1:5, :), 1, 'omitnan')]; %#ok<AGROW>
            %DelFDeAdapt=[DelFDeAdapt; nanmean(PDataLate(end-44:end-5, :))-nanmean(PDataEarly(1:20,:))];
% %             DelFDeAdapt=[DelFDeAdapt; nanmean(PDataLate(6:end-4, :))-nanmean(PDataEarly(1:5,:))];
% %             %DelFDeAdapt=[DelFDeAdapt; nanmean(PDataLate(6:end-4, :))-nanmean(PDataEarly(1:20,:))];
        else
            PANames = adaptData.metaData.conditionName( ...
                find(cellfun(@(x) ~isempty(x), ...
                    regexp(lower(adaptData.metaData.conditionName), ...
                    'ada')), 1, 'first') + 1);
            if strcmp(PANames, 'catch')
                PANames = adaptData.metaData.conditionName( ...
                    find(cellfun(@(x) ~isempty(x), ...
                        regexp(lower( ...
                        adaptData.metaData.conditionName), ...
                        'ada')), 2, 'first') + 1);
            end
            PData = adaptData.getParamInCond(params, PANames);
            %PData=adaptData.getParamInCond(params,'TM post');
            DelFDeAdapt = [DelFDeAdapt; ...
                mean(PData(end-44:end-5, :), 1, 'omitnan') - ...
                mean(PData(1:5, :), 1, 'omitnan')]; %#ok<AGROW>
            %DelFDeAdapt=[DelFDeAdapt; nanmean(PData(end-44:end-5, :))-nanmean(PData(1:20,:))];
        end
        tmafter = [tmafter; mean(PData(1:5, :), 1, 'omitnan')]; %#ok<AGROW>
% %         %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%         tmaftertemp=[]; %New and probably temporary!
%         for cat=1:length(params)
%             tmaftertemp=[tmaftertemp smoothedMax(abs(PData(1:50, cat)),transientNumPts )];
%         end
%         tmafter=[tmafter; tmaftertemp];
% %         %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        tmafterWBias = [tmafterWBias; ...
            mean(PDataWBias(1:5, :), 1, 'omitnan')]; %#ok<AGROW>
        LateP = [LateP; ...
            mean(PData(end-44:end-5, :), 1, 'omitnan')]; %#ok<AGROW>

        % If incline/decline then flat post
        if ~isempty(find(cellfun(@(x) ~isempty(x), ...
                regexp(lower(adaptData.metaData.conditionName), ...
                lower('flat post')))))
            FlatWashoutData = adaptData.getParamInCond( ...
                params, 'flat post');
            FlatWash = [FlatWash; mean( ...
                FlatWashoutData(1:transientNumPts, :), ...
                1, 'omitnan')]; %#ok<AGROW>
        else
            FlatWash = [FlatWash; NaN .* ones(1, length(params))]; %#ok<AGROW>
        end

        % Baseline parameters
        %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        FBase = [FBase; mean(FBaseData(6:end-4, :), 1, 'omitnan')]; %#ok<AGROW>
        SBase = [SBase; mean(SBaseData(6:end-4, :), 1, 'omitnan')]; %#ok<AGROW>
        MBase = [MBase; mean(MBaseData(6:end-4, :), 1, 'omitnan')]; %#ok<AGROW>
% %         FBase=[FBase; nanmean(FBaseData((end-5)-steadyNumPts+1:(end-5), :))];
% %         SBase=[SBase; nanmean(SBaseData((end-5)-steadyNumPts+1:(end-5), :))];
% %         MBase=[MBase; nanmean(MBaseData((end-5)-steadyNumPts+1:(end-5), :))];

        BaseAdapDiscont = [BaseAdapDiscont; ...
            mean(AData(1:5, :), 1, 'omitnan') - ...
            mean(MBaseData(6:end-4, :), 1, 'omitnan')]; %#ok<AGROW>
        BasePADiscont = [BasePADiscont; ...
            mean(PData(1:5, :), 1, 'omitnan') - ...
            mean(MBaseData(6:end-4, :), 1, 'omitnan')]; %#ok<AGROW>

        fast = find(strcmp(params, {'FyPF'}) + ...
            strcmp(params, {'FyBF'}) + strcmp(params, {'XFast'}));
        slow = find(strcmp(params, {'FyPS'}) + ...
            strcmp(params, {'FyBS'}) + strcmp(params, {'XSlow'}));
        speedBias   = [];
        speedPABias = [];
        for ww = 1:length(fast)
            speedBias(fast(ww))   = FBase(ss, fast(ww));
            speedPABias(fast(ww)) = SBase(ss, fast(ww));
        end
        for ww = 1:length(slow)
            speedBias(slow(ww))   = SBase(ss, slow(ww));
            speedPABias(slow(ww)) = FBase(ss, slow(ww));
        end
        if length(speedBias) < length(params)
            speedBias = [speedBias ...
                zeros(1, length(params) - length(speedBias))]; %#ok<AGROW>
        end
        %SpeedAdapDiscont=[SpeedAdapDiscont; nanmean(ADataWBias(end-44:end-5, :))-speedBias];
        SpeedAdapDiscont = [SpeedAdapDiscont; ...
            mean(ADataWBias(1:5, :), 1, 'omitnan') - speedBias]; %#ok<AGROW>
        SpeedPADiscont = [SpeedPADiscont; ...
            mean(PDataWBias(1:5, :), 1, 'omitnan') - speedBias]; %#ok<AGROW>
        %TMSteady=[TMSteady; nanmean(ADataWBias(end-44:end-5, :))-speedBias];
        %SpeedSSDiscont=[SpeedSSDiscont; nanmean(AData((end-5)-steadyNumPts+1:(end-5),:))-speedBias];
        SpeedSSDiscont = [SpeedSSDiscont; ...
            mean(ADataWBias((end-5)-steadyNumPts+1:(end-5), :), ...
            1, 'omitnan') - speedBias]; %#ok<AGROW>

        clear speedBias
        %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    end

    Breaking = find(strcmp(params, {'FyBS'}) + strcmp(params, {'FyBF'}));
    if ~isempty(Breaking)
        DelFAdapt(:, Breaking)   = -1 .* DelFAdapt(:, Breaking);
        DelFDeAdapt(:, Breaking) = -1 .* DelFDeAdapt(:, Breaking);

        %             if ~all(all(isnan(FBase))) && ~all(all(isnan(SBase))) && ~all(all(isnan(MBase)))
        %             FBase(:, Breaking)=-1.*FBase(:, Breaking);
        %             SBase(:, Breaking)=-1.*SBase(:, Breaking);
        %             MBase(:, Breaking)=-1.*MBase(:, Breaking);
        %             end

        % TMSteady(:, Breaking)=-1.*TMSteady(:, Breaking);

    end

    washout2 = [washout2; 100 - (100 * (tmafter ./ TMSteady))]; %#ok<AGROW>
    plearn   = [plearn;          100 * (tmafter ./ TMSteady)];  %#ok<AGROW>

    results.DelFAdapt.avg(end+1, :)   = mean(DelFAdapt, 1, 'omitnan');
    results.DelFAdapt.se(end+1, :)    = ...
        std(DelFAdapt, 0, 1, 'omitnan') ./ sqrt(nSubs);

    results.DelFDeAdapt.avg(end+1, :) = mean(DelFDeAdapt, 1, 'omitnan');
    results.DelFDeAdapt.se(end+1, :)  = ...
        std(DelFDeAdapt, 0, 1, 'omitnan') ./ sqrt(nSubs);

    results.TMSteady.avg(end+1, :)    = mean(TMSteady, 1, 'omitnan');
    results.TMSteady.se(end+1, :)     = ...
        std(TMSteady, 0, 1, 'omitnan') ./ sqrt(nSubs);

    results.TMafter.avg(end+1, :)     = mean(tmafter, 1, 'omitnan');
    results.TMafter.se(end+1, :)      = ...
        std(tmafter, 0, 1, 'omitnan') ./ sqrt(nSubs);

    results.TMSteadyWBias.avg(end+1, :) = ...
        mean(TMSteadyWBias, 1, 'omitnan');
    results.TMSteadyWBias.se(end+1, :)  = ...
        std(TMSteadyWBias, 0, 1, 'omitnan') ./ sqrt(nSubs);

    results.TMafterWBias.avg(end+1, :) = ...
        mean(tmafterWBias, 1, 'omitnan');
    results.TMafterWBias.se(end+1, :)  = ...
        std(tmafterWBias, 0, 1, 'omitnan') ./ sqrt(nSubs);

    results.FastBase.avg(end+1, :) = mean(FBase, 1, 'omitnan');
    results.FastBase.se(end+1, :)  = ...
        std(FBase, 0, 1, 'omitnan') ./ sqrt(nSubs);

    results.SlowBase.avg(end+1, :) = mean(SBase, 1, 'omitnan');
    results.SlowBase.se(end+1, :)  = ...
        std(SBase, 0, 1, 'omitnan') ./ sqrt(nSubs);

    results.MidBase.avg(end+1, :)  = mean(MBase, 1, 'omitnan');
    results.MidBase.se(end+1, :)   = ...
        std(MBase, 0, 1, 'omitnan') ./ sqrt(nSubs);

    results.BaseAdapDiscont.avg(end+1, :) = ...
        mean(BaseAdapDiscont, 1, 'omitnan');
    results.BaseAdapDiscont.se(end+1, :)  = ...
        std(BaseAdapDiscont, 0, 1, 'omitnan') ./ sqrt(nSubs);

    results.BasePADiscont.avg(end+1, :) = ...
        mean(BasePADiscont, 1, 'omitnan');
    results.BasePADiscont.se(end+1, :)  = ...
        std(BasePADiscont, 0, 1, 'omitnan') ./ sqrt(nSubs);

    results.SpeedAdapDiscont.avg(end+1, :) = ...
        mean(SpeedAdapDiscont, 1, 'omitnan');
    results.SpeedAdapDiscont.se(end+1, :)  = ...
        std(SpeedAdapDiscont, 0, 1, 'omitnan') ./ sqrt(nSubs);

    results.SpeedPADiscont.avg(end+1, :) = ...
        mean(SpeedPADiscont, 1, 'omitnan');
    results.SpeedPADiscont.se(end+1, :)  = ...
        std(SpeedPADiscont, 0, 1, 'omitnan') ./ sqrt(nSubs);

    results.EarlyA.avg(end+1, :) = mean(EarlyA, 1, 'omitnan');
    results.EarlyA.se(end+1, :)  = ...
        std(EarlyA, 0, 1, 'omitnan') ./ sqrt(nSubs);

    results.LateP.avg(end+1, :)  = mean(LateP, 1, 'omitnan');
    results.LateP.se(end+1, :)   = ...
        std(LateP, 0, 1, 'omitnan') ./ sqrt(nSubs);

    results.Washout2.avg(end+1, :) = mean(washout2, 1, 'omitnan');
    results.Washout2.se(end+1, :)  = ...
        std(washout2, 0, 1, 'omitnan') ./ sqrt(nSubs);

    results.FlatWash.avg(end+1, :) = mean(FlatWash, 1, 'omitnan');
    results.FlatWash.se(end+1, :)  = ...
        std(FlatWash, 0, 1, 'omitnan') ./ sqrt(nSubs);

    results.PLearn.avg(end+1, :) = mean(plearn, 1, 'omitnan');
    results.PLearn.se(end+1, :)  = ...
        std(plearn, 0, 1, 'omitnan') ./ sqrt(nSubs);

    results.lenA.avg(end+1, :) = mean(lenA, 1, 'omitnan');
    results.lenA.se(end+1, :)  = ...
        std(lenA, 0, 1, 'omitnan') ./ sqrt(nSubs);

    results.SpeedSSDiscont.avg(end+1, :) = ...
        mean(SpeedSSDiscont, 1, 'omitnan');
    results.SpeedSSDiscont.se(end+1, :)  = ...
        std(SpeedSSDiscont, 0, 1, 'omitnan') ./ sqrt(nSubs);

    % This seems ridiculous, but I don't know of another way to do it
    % without making MATLAB mad. The results.(whatever).indiv structure
    % needs to be in this format to make life easier for using SPSS
    if gg == 1
        for pp = 1:length(params)
            results.DelFAdapt.indiv.(params{pp}) = ...
                [gg * ones(nSubs, 1) DelFAdapt(:, pp)];
            results.DelFDeAdapt.indiv.(params{pp}) = ...
                [gg * ones(nSubs, 1) DelFDeAdapt(:, pp)];
            results.FastBase.indiv.(params{pp}) = ...
                [gg * ones(nSubs, 1) FBase(:, pp)];
            results.SlowBase.indiv.(params{pp}) = ...
                [gg * ones(nSubs, 1) SBase(:, pp)];
            results.MidBase.indiv.(params{pp}) = ...
                [gg * ones(nSubs, 1) MBase(:, pp)];
            results.TMSteady.indiv.(params{pp}) = ...
                [gg * ones(nSubs, 1) TMSteady(:, pp)];
            results.TMafter.indiv.(params{pp}) = ...
                [gg * ones(nSubs, 1) tmafter(:, pp)];
            results.TMSteadyWBias.indiv.(params{pp}) = ...
                [gg * ones(nSubs, 1) TMSteadyWBias(:, pp)];
            results.TMafterWBias.indiv.(params{pp}) = ...
                [gg * ones(nSubs, 1) tmafterWBias(:, pp)];
            results.BaseAdapDiscont.indiv.(params{pp}) = ...
                [gg * ones(nSubs, 1) BaseAdapDiscont(:, pp)];
            results.BasePADiscont.indiv.(params{pp}) = ...
                [gg * ones(nSubs, 1) BasePADiscont(:, pp)];
            results.SpeedAdapDiscont.indiv.(params{pp}) = ...
                [gg * ones(nSubs, 1) SpeedAdapDiscont(:, pp)];
            results.SpeedPADiscont.indiv.(params{pp}) = ...
                [gg * ones(nSubs, 1) SpeedPADiscont(:, pp)];
            results.EarlyA.indiv.(params{pp}) = ...
                [gg * ones(nSubs, 1) EarlyA(:, pp)];
            results.LateP.indiv.(params{pp}) = ...
                [gg * ones(nSubs, 1) LateP(:, pp)];
            results.Washout2.indiv.(params{pp}) = ...
                [gg * ones(nSubs, 1) washout2(:, pp)];
            results.FlatWash.indiv.(params{pp}) = ...
                [gg * ones(nSubs, 1) FlatWash(:, pp)];
            results.PLearn.indiv.(params{pp}) = ...
                [gg * ones(nSubs, 1) plearn(:, pp)];
            results.lenA.indiv.(params{pp}) = ...
                [gg * ones(nSubs, 1) lenA(:, pp)];
            results.SpeedSSDiscont.indiv.(params{pp}) = ...
                [gg * ones(nSubs, 1) SpeedSSDiscont(:, pp)];
        end
    else
        for pp = 1:length(params)
            results.DelFAdapt.indiv.(params{pp})( ...
                end+1:end+nSubs, 1:2) = ...
                [gg * ones(nSubs, 1) DelFAdapt(:, pp)];
            results.DelFDeAdapt.indiv.(params{pp})( ...
                end+1:end+nSubs, 1:2) = ...
                [gg * ones(nSubs, 1) DelFDeAdapt(:, pp)];
            results.FastBase.indiv.(params{pp})( ...
                end+1:end+nSubs, 1:2) = ...
                [gg * ones(nSubs, 1) FBase(:, pp)];
            results.SlowBase.indiv.(params{pp})( ...
                end+1:end+nSubs, 1:2) = ...
                [gg * ones(nSubs, 1) SBase(:, pp)];
            results.MidBase.indiv.(params{pp})( ...
                end+1:end+nSubs, 1:2) = ...
                [gg * ones(nSubs, 1) MBase(:, pp)];
            results.TMSteady.indiv.(params{pp})( ...
                end+1:end+nSubs, 1:2) = ...
                [gg * ones(nSubs, 1) TMSteady(:, pp)];
            results.TMafter.indiv.(params{pp})( ...
                end+1:end+nSubs, 1:2) = ...
                [gg * ones(nSubs, 1) tmafter(:, pp)];
            results.TMSteadyWBias.indiv.(params{pp})( ...
                end+1:end+nSubs, 1:2) = ...
                [gg * ones(nSubs, 1) TMSteadyWBias(:, pp)];
            results.TMafterWBias.indiv.(params{pp})( ...
                end+1:end+nSubs, 1:2) = ...
                [gg * ones(nSubs, 1) tmafterWBias(:, pp)];
            results.BaseAdapDiscont.indiv.(params{pp})( ...
                end+1:end+nSubs, 1:2) = ...
                [gg * ones(nSubs, 1) BaseAdapDiscont(:, pp)];
            results.BasePADiscont.indiv.(params{pp})( ...
                end+1:end+nSubs, 1:2) = ...
                [gg * ones(nSubs, 1) BasePADiscont(:, pp)];
            results.SpeedAdapDiscont.indiv.(params{pp})( ...
                end+1:end+nSubs, 1:2) = ...
                [gg * ones(nSubs, 1) SpeedAdapDiscont(:, pp)];
            results.SpeedPADiscont.indiv.(params{pp})( ...
                end+1:end+nSubs, 1:2) = ...
                [gg * ones(nSubs, 1) SpeedPADiscont(:, pp)];
            results.EarlyA.indiv.(params{pp})( ...
                end+1:end+nSubs, 1:2) = ...
                [gg * ones(nSubs, 1) EarlyA(:, pp)];
            results.LateP.indiv.(params{pp})( ...
                end+1:end+nSubs, 1:2) = ...
                [gg * ones(nSubs, 1) LateP(:, pp)];
            results.Washout2.indiv.(params{pp})( ...
                end+1:end+nSubs, 1:2) = ...
                [gg * ones(nSubs, 1) washout2(:, pp)];
            results.FlatWash.indiv.(params{pp})( ...
                end+1:end+nSubs, 1:2) = ...
                [gg * ones(nSubs, 1) FlatWash(:, pp)];
            results.PLearn.indiv.(params{pp})( ...
                end+1:end+nSubs, 1:2) = ...
                [gg * ones(nSubs, 1) plearn(:, pp)];
            results.lenA.indiv.(params{pp})( ...
                end+1:end+nSubs, 1:2) = ...
                [gg * ones(nSubs, 1) lenA(:, pp)];
            results.SpeedSSDiscont.indiv.(params{pp})( ...
                end+1:end+nSubs, 1:2) = ...
                [gg * ones(nSubs, 1) SpeedSSDiscont(:, pp)];
        end
    end
end

%% Merge InclineStroke groups

StatFlag  = 1; %#ok<NASGU>
resultNames = fieldnames(results);
indiData    = [];
if ~isempty(find(strcmp(groups, 'InclineStroke'))) && ...
        ~isempty(find(strcmp(groups, 'InclineStrokeNoCatch')))
    whereArt = [find(strcmp(groups, 'InclineStroke')) ...
        find(strcmp(groups, 'InclineStrokeNoCatch'))];
    for hh = 1:length(resultNames)
        indiData = [];
        for pp = 1:size(results.DelFAdapt.avg, 2)
            % Change the individual columns so that it shows this
            % group as one
            indivData = results.(resultNames{hh}).indiv.(params{pp});
            Group1 = find(indivData(:, 1) == whereArt(1));
            Group2 = find(indivData(:, 1) == whereArt(2));
            indivData([Group1; Group2], 1) = ...
                whereArt(1) .* ones(length([Group1; Group2]), 1);
            results.(resultNames{hh}).indiv.(params{pp}) = indivData;
            indiData = [indiData ...
                indivData([Group1; Group2], 2)]; %#ok<AGROW>
        end
        % Change the avg and se to reflect one less group and use
        % individual data to recalculate these
        results.(resultNames{hh}).avg(whereArt(1), :) = ...
            mean(indiData, 1, 'omitnan');
        results.(resultNames{hh}).se(whereArt(1), :)  = ...
            std(indiData, 0, 1, 'omitnan') ./ ...
            sqrt(length([Group1; Group2]));
        results.(resultNames{hh}).avg(whereArt(2), :) = [];
        results.(resultNames{hh}).se(whereArt(2), :)  = [];
        % change groups
    end
    groups(whereArt(2)) = [];
end

%% Statistics

%if StatFlag==1
for hh = 1:length(resultNames)
    for ii = 1:size(results.DelFAdapt.avg, 2)
        if size(results.DelFAdapt.avg, 1) == 2
            Group1 = find( ...
                results.(resultNames{hh}).indiv.(params{ii})(:, 1) ...
                == 1);
            Group2 = find( ...
                results.(resultNames{hh}).indiv.(params{ii})(:, 1) ...
                == 2);
            %[~, results.(resultNames{hh}).p(ii)]=ttest(results.(resultNames{hh}).indiv.(params{ii})(Group1, 2), results.(resultNames{hh}).indiv.(params{ii})(Group2, 2));
        else
            [results.(resultNames{hh}).p(ii), ~, stats] = anova1( ...
                results.(resultNames{hh}).indiv.(params{ii})(:, 2), ...
                results.(resultNames{hh}).indiv.(params{ii})(:, 1), ...
                'off');
            results.(resultNames{hh}).postHoc{ii} = [NaN NaN];
            if results.(resultNames{hh}).p(ii) <= 0.05 && ...
                    exist('stats') == 1
                [c, ~, ~, gnames] = multcompare( ...
                    stats, 'CType', 'lsd'); %#ok<ASGLU>
                results.(resultNames{hh}).postHoc{ii} = ...
                    c(find(c(:, 6) <= 0.05), 1:2); %#ok<FNDSB>
                %postHoc{ii-1, hh}=c(find(c(:,6)<=0.05), 1:2);
            end
        end
    end
end
% p(1)=[];
%end
close all

%% Plot

if nargin > 4 && plotFlag

    % FIRST: plot baseline values against catch and transfer
    %%epochs={'TMSteady','TMSteadyWBias', 'DelFAdapt', 'BaseAdapDiscont','TMafter','TMafterWBias','DelFDeAdapt', 'BasePADiscont'};
    %%epochs={'SlowBase','FastBase', 'TMSteadyWBias', 'TMSteady','DelFAdapt', 'BaseAdapDiscont'};
    %epochs={'SlowBase','FastBase', 'TMSteady','DelFAdapt','BaseAdapDiscont'};%, 'BasePADiscont'};
    %%epochs={'TMSteady','SpeedAdapDiscont', 'DelFAdapt','TMafter','SpeedPADiscont', 'DelFDeAdapt'};
    %%epochs={'SlowBase','FastBase', 'TMSteady','DelFAdapt','TMafter','DelFDeAdapt'};
    %epochs={'TMSteady','TMafter', 'DelFDeAdapt', 'DelFAdapt', 'DelFDeAdapt'};
    %epochs={ 'BaseAdapDiscont', 'DelFAdapt', 'TMSteady','TMafter','DelFDeAdapt'};
    %epochs={'SlowBase','FastBase', 'MidBase', 'EarlyA', 'TMSteady','SpeedSSDiscont'};
    epochs = {'DelFAdapt', 'DelFDeAdapt', 'SlowBase', 'FastBase', 'MidBase'};
    %%epochs={'BaseAdapDiscont','DelFDeAdapt'};
    %%epochs={'TMSteady', 'SlowBase', 'FastBase', 'MidBase'};
    if nargin > 5
        barGroups(SMatrix, results, groups, params, epochs, indivFlag)
    else
        barGroups(SMatrix, results, groups, params, epochs)
    end

end

end
