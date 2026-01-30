


% Method signature only - implementation needed
plotHandles = [];

% function [plotHandle, offset, ampCoefs] = plotCell(strides, field, N, sync_norm, ampNorm, plotHandle, side, color, offset, plotEv) % Plot cellarray of stride data
%     if nargin < 10
%         plotEv = 0;
%     end
%
%     subplot(plotHandle)
%     eval(['testField = strides{1}.' field ';'])
%     data = strideData.cell2mat(strides, field, N);
%     if numel(ampNorm) > 1
%         ampCoefs = ampNorm; % Should check that numel == size(data, 2)
%         ampNorm = 1;
%     else
%         ampCoefs = [];
%     end
%     if isa(testField, 'labTimeSeries')
%         eval(['labels = strides{1}.' field '.getLabels;']);
%         if strcmp(field, 'procEMGData')
%             data = data * 8;
%         end
%
%         if nargin > 6 && ~isempty(side) % Plot only selected side/labels
%             indLabels = false(size(labels));
%             for i = 1:length(labels)
%                 if isa(side, 'char') % Assuming it is only 'L' or 'R'
%                     if strcmp(labels{i}(1), side)
%                         indLabels(i) = true; % Only the specified side labels
%                     end
%                 elseif isa(side, 'cell') && isa(side{1}, 'char') % List of labels
%                     if any(strcmp(labels{i}, side))
%                         indLabels(i) = true; % Only the specified side labels
%                     end
%                 else
%                     indLabels(i) = false; % No labels
%                 end
%             end
%         else
%             indLabels = true(size(labels)); % All labels
%         end
%
%         if nargin < 7
%             color = [.5, .5, .5];
%         end
%         % Do the plot:
%         raw = data(:, indLabels == 1, :); % Just one side muscles
%         % auxMax = auxMax(:, indLabels == 1, :);
%         hold on
%         switch sync_norm
%             case 0 % Do nothing
%
%             case 1 % Renormalize to swing/stance
%                 % To Do
%             case 2 % Renormalize to 4 phases
%                 % To Do
%         end
%         switch ampNorm
%             case 0 % Do nothing
%                 if nargin > 8 && ~isempty(offset)
%                     mOffset = offset;
%                 else
%                     mOffset = 3 * max(abs(raw(:)));
%                 end
%                 ampCoefs = 0;
%             case 1 % Normalize amplitude to [0, 1] for EACH label/component of data
%                 if isempty(ampCoefs)
%                     ampCoefs = max(max(abs(raw), [], 1), [], 3);
%                     if any(ampCoefs == zeros(size(ampCoefs)))
%                         ampCoefs(ampCoefs == 0) = 1 / 100000;
%                     end
%                 end
%                 raw = .9 * raw ./ repmat(ampCoefs, size(raw, 1), 1, size(raw, 3));
%                 mOffset = 3;
%         end
%         for stride = 1:size(raw, 3)
%             % Plot
%             auxMusc = mOffset * repmat([0:size(raw, 2) - 1], size(raw, 1), 1);
%             hh = plot([0:N - 1] / N, auxMusc + raw(:, :, stride), 'Color', color);
%             uistack(hh, 'bottom');
%             if plotEv == 1
%                 % Add events:
%                 auxN = [0:N - 1] / N;
%                 events = strides{stride}.gaitEvents.resampleN(N).getDataAsVector({'LHS', 'RHS', 'LTO', 'RTO'});
%                 plot(auxN(events(:, 1) == 1), auxMusc(events(:, 1) == 1, :) + raw(events(:, 1) == 1, :, stride), 'sy')
%                 plot(auxN(events(:, 2) == 1), auxMusc(events(:, 2) == 1, :) + raw(events(:, 2) == 1, :, stride), 'sm')
%                 plot(auxN(events(:, 3) == 1), auxMusc(events(:, 3) == 1, :) + raw(events(:, 3) == 1, :, stride), 'sk')
%                 plot(auxN(events(:, 4) == 1), auxMusc(events(:, 4) == 1, :) + raw(events(:, 4) == 1, :, stride), 'sg')
%             end
%         end
%         set(gca, 'YTick', mOffset * [0:size(raw, 2) - 1], 'YTickLabel', labels(indLabels == 1));
%         axis([0 1 -mOffset / 2 mOffset * size(raw, 2) - mOffset / 2])
%         xlabel('% stride')
%         ax1 = gca;
%         % Add secondary axes for scale: (fancy, matters only if amp is not normalized)
%         ax2 = axes('Position', get(ax1, 'Position'), ...
%             'XAxisLocation', 'top', ...
%             'YAxisLocation', 'right', ...
%             'Color', 'none', ...
%             'XColor', 'r', 'YColor', 'r');
%         linkaxes([ax1, ax2], 'xy')
%         auxTick = [-mOffset / 2:mOffset / 4:(mOffset * size(raw, 2) - mOffset / 2)];
%         % auxTick(1:4:end) = [];
%         for i = 1:length(auxTick)
%             if mod(i, 4) == 1
%                 auxTickLabel{i} = '';
%             else
%                 auxTickLabel{i} = (mod(i - 1, 4) - 2) * mOffset / 4;
%             end
%         end
%         set(ax2, 'YTick', auxTick, 'YTickLabel', auxTickLabel);
%         set(ax2, 'XTick', []);
%         hold off
%         offset = mOffset;
%     end
% end
end

