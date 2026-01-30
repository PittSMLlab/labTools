function [plotHandle, offset, ampCoefs] = plotCellAvg(strides, ...
    field, N, sync_norm, ampNorm, plotHandle, side, color, offset, plotEv)
%plotCellAvg  Plots average and std of stride cell array
%
%   [plotHandle, offset, ampCoefs] = plotCellAvg(strides, field,
%   N, sync_norm, ampNorm, plotHandle, side, color, offset,
%   plotEv) plots the mean and standard deviation of data from
%   multiple strides
%
%   Inputs:
%       strides - cell array of strideData objects
%       field - name of field to plot (e.g., 'procEMGData')
%       N - number of samples for time normalization
%       sync_norm - synchronization normalization flag (0 =
%                   none, 1 = swing/stance, 2 = 4 phases)
%       ampNorm - amplitude normalization (0 = none, 1 =
%                 normalize, or vector of coefficients)
%       plotHandle - subplot handle for plotting
%       side - 'L', 'R', or cell array of labels to plot
%       color - RGB color vector for plot
%       offset - vertical offset between traces
%       plotEv - flag to plot event markers (default: 0)
%
%   Outputs:
%       plotHandle - handle to plot axes
%       offset - vertical offset used
%       ampCoefs - amplitude normalization coefficients used
%
%   See also: plotCell, cell2mat

% Plot cellarray of stride data
if nargin < 10
    plotEv = 0;
end

if nargin > 5 && ~isempty(plotHandle)
    subplot(plotHandle);
end

eval(['testField = strides{1}.' field ';']);
data = strideData.cell2mat(strides, field, N);
if numel(ampNorm) > 1
    ampCoefs = ampNorm; % Should check that numel == size(data, 2)
    ampNorm = 1;
else
    ampCoefs = [];
end

if isa(testField, 'labTimeSeries')
    eval(['labels = strides{1}.' field '.getLabels;']);
    if strcmp(field, 'procEMGData')
        data = data * 8;
    end

    if nargin > 6 && ~isempty(side)
        indLabels = false(size(labels));
        for i = 1:length(labels)
            if isa(side, 'char') % Assuming it is only 'L' or 'R'
                if strcmp(labels{i}(1), side)
                    % Only the specified side labels
                    indLabels(i) = true;
                end
            elseif isa(side, 'cell') && isa(side{1}, 'char')
                % List of labels
                if any(strcmp(labels{i}, side))
                    % Only the specified side labels
                    indLabels(i) = true;
                end
            else
                indLabels(i) = false; % No labels
            end
        end
    else
        indLabels = true(size(labels)); % All labels
    end

    if nargin < 7
        color = [0.5, 0.5, 0.5];
    end

    % Do the plot:
    raw = data(:, indLabels == 1, :); % Just one side muscles
    % auxMax = auxMax(:, indLabels == 1, :);
    hold on;

    switch sync_norm
        case 0 % Do nothing

        case 1 % Renormalize to swing/stance
            % To Do
        case 2 % Renormalize to 4 phases
            % To Do
    end

    switch ampNorm
        case 0 % Do nothing
            if nargin > 8 && ~isempty(offset)
                mOffset = offset;
            else
                mOffset = 2 * max(abs(raw(:)));
            end
            ampCoefs = 0;
        case 1 % Normalize amplitude to [0, 1] for EACH
            % label/component of data
            if isempty(ampCoefs)
                ampCoefs = mean(max(abs(raw), [], 1), 3);
            end
            raw = 0.9 * raw ./ repmat(ampCoefs, size(raw, 1), 1, ...
                size(raw, 3));
            mOffset = 2;
    end

    % Plot
    auxMusc = mOffset * repmat([0:size(raw, 2) - 1], size(raw, 1), 1);
    plot([0:N - 1] / N, auxMusc + mean(raw, 3), 'Color', ...
        [0.5, 0.5, 0.8] .* color, 'LineWidth', 2);
    haa = plot([0:N - 1] / N, auxMusc + mean(raw, 3) + ...
        std(raw, [], 3), 'Color', color, 'LineWidth', 1);
    uistack(haa, 'bottom');
    haa = plot([0:N - 1] / N, auxMusc + mean(raw, 3) - ...
        std(raw, [], 3), 'Color', color, 'LineWidth', 1);
    uistack(haa, 'bottom');

    if plotEv == 1
        % Add events
        events = strideData.cell2mat(strides, 'gaitEvents', N);
        eventLabels = strides{1}.gaitEvents.getLabels;
        idx = strcmp(eventLabels, 'LHS');
        LHSev = round(sum([1:N]' .* mean(events(:, idx == 1, :), 3)));
        idx = strcmp(eventLabels, 'RHS');
        RHSev = round(sum([1:N]' .* mean(events(:, idx == 1, :), 3)));
        idx = strcmp(eventLabels, 'LTO');
        LTOev = round(sum([1:N]' .* mean(events(:, idx == 1, :), 3)));
        idx = strcmp(eventLabels, 'RTO');
        RTOev = round(sum([1:N]' .* mean(events(:, idx == 1, :), 3)));
        plot((LHSev - 1) / N, auxMusc(LHSev, :) + ...
            mean(raw(LHSev, :, :), 3), 's', 'Color', color);
        plot((RHSev - 1) / N, auxMusc(RHSev, :) + ...
            mean(raw(RHSev, :, :), 3), 's', 'Color', color);
        plot((LTOev - 1) / N, auxMusc(LTOev, :) + ...
            mean(raw(LTOev, :, :), 3), 's', 'Color', color);
        plot((RTOev - 1) / N, auxMusc(RTOev, :) + ...
            mean(raw(RTOev, :, :), 3), 's', 'Color', color);
    end

    set(gca, 'YTick', mOffset * [0:size(raw, 2) - 1], ...
        'YTickLabel', labels(indLabels == 1));
    axis([0 1 -mOffset / 2 mOffset * size(raw, 2) - mOffset / 2]);
    xlabel('% stride');
    ax1 = gca;
    % Add secondary axes for scale: (fancy, matters only if amp is
    % not normalized)
    ax2 = axes('Position', get(ax1, 'Position'), ...
        'XAxisLocation', 'top', 'YAxisLocation', 'right', ...
        'Color', 'none', 'XColor', 'r', 'YColor', 'r');
    linkaxes([ax1, ax2], 'xy');
    auxTick = [-mOffset / 2:mOffset / 4:...
        (mOffset * size(raw, 2) - mOffset / 2)];
    % auxTick(1:4:end) = [];
    for i = 1:length(auxTick)
        if mod(i, 4) == 1
            auxTickLabel{i} = '';
        else
            auxTickLabel{i} = (mod(i - 1, 4) - 2) * mOffset / 4;
        end
    end
    set(ax2, 'YTick', auxTick, 'YTickLabel', auxTickLabel);
    set(ax2, 'XTick', []);
    hold off;
    offset = mOffset;
end
end

