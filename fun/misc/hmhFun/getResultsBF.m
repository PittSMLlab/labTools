function results = getResultsBF(SMatrix, groups, plotFlag, indivFlag)
%GETRESULTSBF Compute body-frame perception results per group.
%
%   Loads each subject's bilateral-force perception data file, organises
% hit rates by target step length (short, medium, long), and computes
% group-level means and standard errors for two after-effect windows and
% three step-length map conditions.
%
% Inputs:
%   SMatrix   - Struct with group fields; each group has an ID field
%               listing subject ID strings
%   groups    - Cell array of group name strings; defaults to all fields
%               of SMatrix when empty
%   plotFlag  - Logical; if true, create bar plots
%   indivFlag - Logical; if true, overlay individual subjects on bars
%
% Outputs:
%   results - Struct with fields BFafter1, BFafter2, MapShort, MapMid,
%             MapLong; each has avg, se, indiv sub-structs
%
% Toolbox Dependencies: None
%
% See also BARGROUPS, GETHITS.

params = {'SlowLeg', 'FastLeg'};

catchNumPts     = 3;   % catch
steadyNumPts    = 40;  % end of adaptation
transientNumPts = 5;   % OG and Washout

if nargin < 3 || isempty(groups)
    groups = fields(SMatrix);
end
ngroups = length(groups);

results.BFafter1.avg = [];
results.BFafter1.se  = [];
results.BFafter2.avg = [];
results.BFafter2.se  = [];
results.MapShort.avg = [];
results.MapShort.se  = [];
results.MapMid.avg   = [];
results.MapMid.se    = [];
results.MapLong.avg  = [];
results.MapLong.se   = [];

for gg = 1:ngroups

    subjects = SMatrix.(groups{gg}).ID;

    BFafter1 = [];
    BFafter2 = [];
    MapShort = [];
    MapMid   = [];
    MapLong  = [];

    for ss = 1:length(subjects)
        DATA = load([subjects{ss} '_PerceptionBF_day.mat']);
        eval(['DATA=DATA.' subjects{ss} ';']);

        [rhits, lhits, rts, lts, color] = getHits(DATA); %#ok<ASGLU>

        RDATA = [];
        LDATA = [];

        PossibleTarget = unique(rts{1});
        LLL = max(PossibleTarget);
        SS  = min(PossibleTarget);
        MM  = median(PossibleTarget);

        for zz = 1:length(rts)
            for t = 1:length(rts{zz})
                if rts{zz}(t) == LLL
                    RDATA(t) = 3; %#ok<AGROW>
                elseif rts{zz}(t) == SS
                    RDATA(t) = 1; %#ok<AGROW>
                elseif rts{zz}(t) == MM
                    RDATA(t) = 2; %#ok<AGROW>
                else
                    break
                end
            end

            for t = 1:length(lts{zz})
                if lts{zz}(t) == LLL
                    LDATA(t) = 3; %#ok<AGROW>
                elseif lts{zz}(t) == SS
                    LDATA(t) = 1; %#ok<AGROW>
                elseif lts{zz}(t) == MM
                    LDATA(t) = 2; %#ok<AGROW>
                else
                    break
                end
            end

            t     = 1;
            r     = 1;
            RR{zz} = [0, 0, 0]; %#ok<AGROW>
            while t < length(rts{zz})
                nxtChg = find(RDATA(t:end) ~= RDATA(t), 1, 'first');
                RR{zz}(r, RDATA(t)) = mean( ...
                    rhits{zz}(t:(nxtChg + t - 2)));
                if isnan(RR{zz}(r, RDATA(t)))
                    RR{zz}(r, RDATA(t)) = mean(rhits{zz}(t:end));
                end
                t = find(RDATA(t:end) ~= RDATA(t), 1, 'first') + t - 1;
                if isempty(t)
                    t = length(rts{zz});
                end
                if RR{zz}(r, RDATA(t)) ~= 0
                    r = r + 1;
                end
            end

            t     = 1;
            r     = 1;
            LL{zz} = [0, 0, 0]; %#ok<AGROW>
            while t < length(lts{zz})
                nxtChg = find(LDATA(t:end) ~= LDATA(t), 1, 'first');
                LL{zz}(r, LDATA(t)) = mean( ...
                    lhits{zz}(t:(nxtChg + t - 2)));
                if isnan(LL{zz}(r, LDATA(t)))
                    LL{zz}(r, LDATA(t)) = mean(lhits{zz}(t:end));
                end
                t = find(LDATA(t:end) ~= LDATA(t), 1, 'first') + t - 1;
                if isempty(t)
                    t = length(lts{zz});
                end
                if LL{zz}(r, LDATA(t)) ~= 0
                    r = r + 1;
                end
            end
            clear RDATA LDATA
        end

        DDR{1} = RR{4} - RR{3};
        DDR{2} = mean(RR{5} - RR{2}, 'omitnan');

        DDL{1} = LL{4} - LL{3};
        DDL{2} = mean(LL{5} - LL{2}, 'omitnan');

        if DATA.fastleg == 'r'
            MapShort = [MapShort; DDL{2}(1,1) DDR{2}(1,1)]; %#ok<AGROW>
            MapMid   = [MapMid;   DDL{2}(1,2) DDR{2}(1,2)]; %#ok<AGROW>
            MapLong  = [MapLong;  DDL{2}(1,3) DDR{2}(1,3)]; %#ok<AGROW>
            if rts{3}(1) == SS
                BFafter1 = [BFafter1; DDL{1}(1,1) DDR{1}(1,1)]; %#ok<AGROW>
                BFafter2 = [BFafter2; DDL{1}(1,3) DDR{1}(1,3)]; %#ok<AGROW>
            else
                BFafter1 = [BFafter1; DDL{1}(1,3) DDR{1}(1,3)]; %#ok<AGROW>
                BFafter2 = [BFafter2; DDL{1}(1,1) DDR{1}(1,1)]; %#ok<AGROW>
            end
        elseif DATA.fastleg == 'l'
            MapShort = [MapShort; DDR{2}(1,1) DDL{2}(1,1)]; %#ok<AGROW>
            MapMid   = [MapMid;   DDR{2}(1,2) DDL{2}(1,2)]; %#ok<AGROW>
            MapLong  = [MapLong;  DDR{2}(1,3) DDL{2}(1,3)]; %#ok<AGROW>
            if rts{3}(1) == SS
                BFafter1 = [BFafter1; DDR{1}(1,1) DDL{1}(1,1)]; %#ok<AGROW>
                BFafter2 = [BFafter2; DDR{1}(1,3) DDL{1}(1,3)]; %#ok<AGROW>
            else
                BFafter1 = [BFafter1; DDR{1}(1,3) DDL{1}(1,3)]; %#ok<AGROW>
                BFafter2 = [BFafter2; DDR{1}(1,1) DDL{1}(1,1)]; %#ok<AGROW>
            end
        else
            cprintf('err', 'WARNING: Which leg is fast????');
        end
    end

    nSubs = length(subjects);

    results.BFafter1.avg(end+1, :) = ...
        mean(BFafter1, 1, 'omitnan');
    results.BFafter1.se(end+1, :)  = ...
        std(BFafter1, 0, 1, 'omitnan') ./ sqrt(nSubs);
    results.BFafter2.avg(end+1, :) = ...
        mean(BFafter2, 1, 'omitnan');
    results.BFafter2.se(end+1, :)  = ...
        std(BFafter2, 0, 1, 'omitnan') ./ sqrt(nSubs);
    results.MapShort.avg(end+1, :) = ...
        mean(MapShort, 1, 'omitnan');
    results.MapShort.se(end+1, :)  = ...
        std(MapShort, 0, 1, 'omitnan') ./ sqrt(nSubs);
    results.MapMid.avg(end+1, :)   = ...
        mean(MapMid, 1, 'omitnan');
    results.MapMid.se(end+1, :)    = ...
        std(MapMid, 0, 1, 'omitnan') ./ sqrt(nSubs);
    results.MapLong.avg(end+1, :)  = ...
        mean(MapLong, 1, 'omitnan');
    results.MapLong.se(end+1, :)   = ...
        std(MapLong, 0, 1, 'omitnan') ./ sqrt(nSubs);

    if gg == 1
        for pp = 1:length(params)
            results.BFafter1.indiv.(params{pp}) = ...
                [gg * ones(nSubs, 1) BFafter1(:, pp)];
            results.BFafter2.indiv.(params{pp}) = ...
                [gg * ones(nSubs, 1) BFafter2(:, pp)];
            results.MapShort.indiv.(params{pp}) = ...
                [gg * ones(nSubs, 1) MapShort(:, pp)];
            results.MapMid.indiv.(params{pp})   = ...
                [gg * ones(nSubs, 1) MapMid(:, pp)];
            results.MapLong.indiv.(params{pp})  = ...
                [gg * ones(nSubs, 1) MapLong(:, pp)];
        end
    else
        for pp = 1:length(params)
            results.BFafter1.indiv.(params{pp})( ...
                end+1:end+nSubs, 1:2) = ...
                [gg * ones(nSubs, 1) BFafter1(:, pp)];
            results.BFafter2.indiv.(params{pp})( ...
                end+1:end+nSubs, 1:2) = ...
                [gg * ones(nSubs, 1) BFafter2(:, pp)];
            results.MapShort.indiv.(params{pp})( ...
                end+1:end+nSubs, 1:2) = ...
                [gg * ones(nSubs, 1) MapShort(:, pp)];
            results.MapMid.indiv.(params{pp})( ...
                end+1:end+nSubs, 1:2) = ...
                [gg * ones(nSubs, 1) MapMid(:, pp)];
            results.MapLong.indiv.(params{pp})( ...
                end+1:end+nSubs, 1:2) = ...
                [gg * ones(nSubs, 1) MapLong(:, pp)];
        end
    end
end

%% Statistics
resultNames = fieldnames(results);
for hh = 1:length(resultNames)
    for ii = 1:size(results.BFafter1.avg, 2)
        [~, results.(resultNames{hh}).p(ii)] = ttest( ...
            results.(resultNames{hh}).indiv.(params{ii})(:, 2));
    end
end

%% Plot
if plotFlag
    epochs = {'BFafter1', 'BFafter2', 'MapShort', 'MapMid', 'MapLong'};
    if nargin > 3
        barGroups(SMatrix, results, groups, params, epochs, indivFlag)
    else
        barGroups(SMatrix, results, groups, params, epochs)
    end
end

end
