function barGroups(Study, results, groups, params, epochs, ...
    indivFlag, colorOrder, mode)
%BARGROUPS Make a bar plot comparing groups across epochs and parameters.
%
%   Creates a subplot grid of bar charts — one subplot per (parameter,
% epoch) combination. Bars represent group means with error bars for
% standard error. Optionally overlays individual subject data points.
%
% Inputs:
%   Study      - Struct with group fields, each containing an ID field
%                with subject identifiers
%   results    - Struct with epoch fields; each epoch has avg (groups ×
%                params), se (same size), and indiv sub-struct
%   groups     - Cell array of group name strings
%   params     - Cell array of parameter name strings
%   epochs     - Cell array of epoch name strings
%   indivFlag  - Logical; if true, overlay individual subject data points
%   colorOrder - K×3 matrix of RGB colors (one row per group/subject);
%                defaults to poster_colors if empty or not 3-column
%   mode       - Display mode: 1 = filled bars, 2 = error bars only
%
% Outputs:
%   None (creates a figure)
%
% Toolbox Dependencies: None
%
% See also OPTIMIZEDSUBPLOT, POSTER_COLORS.

% TODO: accept a group array different from the groups in results

if nargin < 8 || isempty(mode)
    mode = 1;
end
if nargin < 7 || isempty(colorOrder) || size(colorOrder, 2) ~= 3
    poster_colors;
    colorOrder = [p_red;    p_orange; p_fade_green; p_fade_blue; ...
                  p_plum;   p_green;  p_blue;        p_fade_red;  ...
                  p_lime;   p_yellow; p_gray;         p_black;     ...
                  [1 1 1]];
end

% Grey color scale for individual-subject overlay
greyOrder = [0   0   0;   1   1   1;   0.5 0.5 0.5; ...
             0.2 0.2 0.2; 0.9 0.9 0.9; 0.1 0.1 0.1; ...
             0.8 0.8 0.8; 0.3 0.3 0.3; 0.7 0.7 0.7];

ngroups  = length(groups);
numPlots = length(epochs) * length(params);
numE     = length(epochs);
ah       = optimizedSubPlot(numPlots, length(params), numE, ...
    'lr', 12, 10, 12);
plotIdx  = 1;

for pp = 1:length(params)
    limy = [];
    for ep = 1:numE
        axes(ah(plotIdx)); %#ok<LAXES>
        hold on
        for gg = 1:ngroups
            nSubs = length(Study.(groups{gg}).ID);
            ind   = find(strcmp(fields(Study), groups{gg}));
            switch mode
                case 1
                    if nargin > 5 && indivFlag
                        bar(gg, results.(epochs{ep}).avg(gg, pp), ...
                            'facecolor', greyOrder(ind, :));
                        for ss = 1:nSubs
                            aux = results.(epochs{ep}).indiv.(params{pp});
                            aux = aux(aux(:, 1) == gg, 2);
                            plot(gg, aux(ss), '*', ...
                                'Color', colorOrder(ss, :))
                        end
                    else
                        bar(gg, results.(epochs{ep}).avg(gg, pp), ...
                            'facecolor', colorOrder(ind, :));
                    end
                case 2
                    %nop
            end
        end
        switch mode
            case 1
                errorbar(results.(epochs{ep}).avg(:, pp), ...
                    results.(epochs{ep}).se(:, pp), '.', ...
                    'LineWidth', 2, 'Color', 'k')
            case 2
                errorbar(results.(epochs{ep}).avg(:, pp), ...
                    results.(epochs{ep}).se(:, pp), ...
                    'LineWidth', 2, 'Color', 'k')
        end
        set(gca, 'Xtick', 1:ngroups, 'XTickLabel', groups, ...
            'fontSize', 12)
        axis tight
        limy = [limy get(gca, 'Ylim')]; %#ok<AGROW>
        ylabel(params{pp})
        title(epochs{ep})
        plotIdx = plotIdx + 1;
    end
    set(ah(pp * numE - (numE - 1):pp * numE), ...
        'Ylim', [min(limy) max(limy)])
    set(gcf, 'Renderer', 'painters');
end

end
