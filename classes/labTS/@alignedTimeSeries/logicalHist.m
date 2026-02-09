function [histogram, newLabels] = logicalHist(this)
%logicalHist  Generates histogram from logical event data
%
%   [histogram, newLabels] = logicalHist(this) creates histogram of
%   event timing across strides
%
%   Inputs:
%       this - alignedTimeSeries object with logical data
%
%   Outputs:
%       histogram - matrix of event sample indices (strides x events)
%       newLabels - cell array of event labels
%
%   Note: Assumes all aligned TS contain same events in same order
%
%   See also: mean, std

% TODO: Check this is a logical alignedTS
% TODO: determine number of expected events. Currently this is as many
% events as stride 1 has. May be problematic if stride one is invalid.
aaux = cellfun(@(x) isempty(x), strfind(this.labels, 'force')) & ...
    cellfun(@(x) isempty(x), strfind(this.labels, 'kin'));
% Mode of the # of events per stride, assuming this is what should
% happen on every stride.
eventNo = mode(sum(sum(this.Data(:, aaux), 1), 2));
nStrides = size(this.Data, 3);
eventType = nan(eventNo, 1);
for i = 1:eventNo
    aux = nan(nStrides, 1);
    for k = 1:nStrides % Going over strides
        % Time index of first i events in stride k
        eventIdx = find(sum(this.Data(:, aaux, k), 2) == 1, i, 'first');
        if length(eventIdx) == i % Checking that I found i events
            aux(k) = find(this.Data(eventIdx(i), aaux, k), 1, 'first');
        end
    end
    % Rounding is to break possible ties (very unlikely)
    eventType(i) = round(nanmedian(aux));
end
histogram = nan(nStrides, eventNo);
ii = eventType;
aux = zeros(eventNo, 1);
newLabels = cell(size(ii));
for i = 1:length(ii)
    aux(ii(i)) = aux(ii(i)) + 1;
    if aux(ii(i)) == 1
        newLabels{i} = this.labels{ii(i)};
    else
        newLabels{i} = [this.labels{ii(i)} num2str(aux(ii(i)))];
    end
end

for i = 1:nStrides
    [eventTimeIndex, eventType] = find(this.Data(:, aaux, i));
    if length(eventTimeIndex) ~= length(newLabels)
        warning(['alignedTS:logicalHist: Stride ' num2str(i) ...
            ' has more or less events than expected (expecting ' ...
            num2str(length(newLabels)) ', but got ' ...
            num2str(length(eventTimeIndex)) '). Discarding.']);
        histogram(i, :) = nan;
    else
        % FIXME: check event order by using the labels.
        [eventTimeIndex, auxInds] = sort(eventTimeIndex);
        if all(ii == eventType(auxInds))
            histogram(i, :) = eventTimeIndex;
        else
            warning(['alignedTS:logicalHist: Stride ' num2str(i) ...
                ' has events in different order than expected ' ...
                '(expecting ' num2str(ii') ', but got ' ...
                num2str(eventType(auxInds)') '). Discarding.']);
        end
    end
end
end

