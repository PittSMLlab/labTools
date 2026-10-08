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
eventNo   = mode(sum(sum(this.Data(:, aaux), 1), 2));
nStrides  = size(this.Data, 3);
eventType = nan(eventNo, 1);
for ev = 1:eventNo
    aux = nan(nStrides, 1);
    for k = 1:nStrides % Going over strides
        % Time index of first ev events in stride k
        eventIdx = find(sum(this.Data(:, aaux, k), 2) == 1, ev, 'first');
        if length(eventIdx) == ev % Checking that I found ev events
            aux(k) = find(this.Data(eventIdx(ev), aaux, k), 1, 'first');
        end
    end
    % Rounding is to break possible ties (very unlikely)
    eventType(ev) = round(median(aux, 'omitnan'));
end
histogram = nan(nStrides, eventNo);
ii        = eventType;
aux       = zeros(eventNo, 1);
newLabels = cell(size(ii));
for ev = 1:length(ii)
    aux(ii(ev)) = aux(ii(ev)) + 1;
    if aux(ii(ev)) == 1
        newLabels{ev} = this.labels{ii(ev)};
    else
        newLabels{ev} = [this.labels{ii(ev)} num2str(aux(ii(ev)))];
    end
end

for st = 1:nStrides
    [eventTimeIndex, eventType] = find(this.Data(:, aaux, st));
    if length(eventTimeIndex) ~= length(newLabels)
        warning(['alignedTS:logicalHist: Stride ' num2str(st) ...
            ' has more or less events than expected (expecting ' ...
            num2str(length(newLabels)) ', but got ' ...
            num2str(length(eventTimeIndex)) '). Discarding.']);
        histogram(st, :) = nan;
    else
        % FIXME: check event order by using the labels.
        [eventTimeIndex, auxInds] = sort(eventTimeIndex);
        if all(ii == eventType(auxInds))
            histogram(st, :) = eventTimeIndex;
        else
            warning(['alignedTS:logicalHist: Stride ' num2str(st) ...
                ' has events in different order than expected ' ...
                '(expecting ' num2str(ii') ', but got ' ...
                num2str(eventType(auxInds)') '). Discarding.']);
        end
    end
end
end

