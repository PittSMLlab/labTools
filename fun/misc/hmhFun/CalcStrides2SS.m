function Stride2SS = CalcStrides2SS(allValues, SSraw, params, plotFlag, subID)
%CALCSTRIDES2SS Estimate strides-to-steady-state for each parameter.
%
%   Applies a 63.2% threshold criterion to the smoothed time course of
% each parameter in ALLVALUES to identify the stride at which the
% response first reaches steady state.
%
% Inputs:
%   allValues - N×P matrix of raw parameter values (strides × params)
%   SSraw     - 1×P vector of raw steady-state values for each param
%   params    - cell array of parameter name strings (length P)
%   plotFlag  - scalar; if 1, plot time courses with threshold markers
%   subID     - subject ID string for plot titles (or empty)
%
% Outputs:
%   Stride2SS - 1×P vector of stride indices to steady state
%
% Toolbox Dependencies: None
%
% See also BIN_DATAV1.
if isempty(plotFlag) ~= 0 || plotFlag == 1
    figure
end

idxVELO = find(strcmp(params, 'velocityContributionNorm2'));
idxNET  = find(strcmp(params, 'netContributionNorm2'));

%% Smooth data and initialize steady-state values
binWidth     = 20;              % running-average window (strides)
smoothLabel  = 'Whole, BW=20, first not before raw min';
allValuesALL = bin_dataV1(allValues, binWidth);
ss           = SSraw;

for var = 1:length(params)

    % locate minimum within first 20 strides of raw data
    whereIS = find( ...
        allValues(:, var) == min(allValues(1:20, var), [], 'omitnan'), ...
        1, 'first');

    if var == idxNET || var == idxVELO
        % shift NET and VELOCITY curves by their mutual offset
        shifter          = SSraw(idxVELO) - SSraw(idxNET);
        allValuesALL(:, var) = allValuesALL(:, var) + abs(shifter);
        ss(var)          = SSraw(var) + abs(shifter);
    end

    % find first stride at or above 63.2% of steady state (1/e criterion)
    t = find(allValuesALL(:, var) >= ss(var) * 0.632);
    if isempty(t)
        Stride2SS(1, var) = NaN;                %#ok<AGROW>
    else
        % prevent identification before the minimum value
        first_t = t(1);
        knot    = 2;
        while first_t <= whereIS
            first_t = t(knot);
            knot    = knot + 1;
        end
        Stride2SS(1, var) = first_t;            %#ok<AGROW>
    end

    % optional diagnostic plot
    if plotFlag
        subplot(1, length(params), var)
        plot(allValuesALL(:, var), 'b.-', 'MarkerSize', 25);
        hold on
        plot(whereIS:whereIS+9, allValuesALL(whereIS:whereIS+9, var), ...
            'c.', 'MarkerSize', 25);
        hold on
        plot(first_t, allValuesALL(first_t, var), '.r', 'MarkerSize', 25);
        hold on
        line([0 900], [ss(var) ss(var)], ...
            'Color', 'k', 'LineWidth', 1)
        line([0 900], [ss(var)*0.632 ss(var)*0.632], ...
            'Color', 'k', 'LineWidth', 1, 'LineStyle', ':')
        line([0 900], [0 0])

        if subID
            title([subID ': Stride to SS = ' num2str(first_t)]);
        else
            title(['Stride to SS = ' num2str(first_t)]);
        end

        ylabel(params(var))
        xlabel(['Strides (' smoothLabel ')'])
        axis tight
        hold on
    end
end
end
