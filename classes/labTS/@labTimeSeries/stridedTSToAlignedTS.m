function [alignedTS, originalDurations] = ...
    stridedTSToAlignedTS(stridedTS, N)
%stridedTSToAlignedTS  Converts strided TS to aligned TS
%
%   [alignedTS, originalDurations] = stridedTSToAlignedTS(stridedTS,
%   N) converts cell array of strided timeseries to aligned timeseries
%
%   Inputs:
%       stridedTS - cell array (strides x phases) of labTimeSeries
%       N - vector of sample counts for each phase
%
%   Outputs:
%       alignedTS - alignedTimeSeries object
%       originalDurations - matrix of original phase durations
%
%   Note: Deprecated. Use labTS.align()
%
%   See also: align, splitByEvents, alignedTimeSeries

error('labTS:stridedTSToAlignedTS', 'Deprecated. Use labTS.align();');
% To be used after splitByEvents
if numel(stridedTS) ~= 0
    if ~islogical(stridedTS{1}.Data)
        aux = zeros(sum(N), size(stridedTS{1}.Data, 2),size(stridedTS, 1));
    else
        aux = false(sum(N), size(stridedTS{1}.Data, 2),size(stridedTS, 1));
    end
    Nstrides = size(stridedTS, 1);
    Nphases = size(stridedTS, 2);
    originalDurations = nan(Nstrides, Nphases);
    for i = 1:Nstrides % Going over strides
        M = [0, cumsum(N)];
        for j = 1:Nphases % Going over aligned phases
            if isa(stridedTS{i, j}, 'labTimeSeries')
                originalDurations(i, j) = stridedTS{i, j}.timeRange;
                if ~isempty(stridedTS{i, j}.Data) && ...
                        sum(~isnan(stridedTS{i, j}.Data(:, 1))) > 1
                    aa = resampleN(stridedTS{i, j}, N(j));
                    aux(M(j) + 1:M(j + 1), :, i) = aa.Data;
                else
                    % Separating by strides returned empty labTimeSeries,
                    % possibly because of events in disorder
                    if islogical(stridedTS{i, j}.Data)
                        aux(M(j) + 1:M(j + 1), :, i) = false;
                    else
                        aux(M(j) + 1:M(j + 1), :, i) = NaN;
                    end
                end
            else
                error('labTimeSeries:stridedTSToAlignedTS', ...
                    ['First argument is not a cell array of ' ...
                    'labTimeSeries. Element i = ' num2str(i) ', j = ' ...
                    num2str(j)]);
            end
        end
    end
    % Need to populate this field properly
    alignmentLabels = cell(size(N));
    % On May 2nd 2017, Pablo changed to have sampling time = 1 [time
    % vector now counts samples]
    alignedTS = alignedTimeSeries(0, 1, aux, stridedTS{1}.labels, N, ...
        alignmentLabels);
else
    alignmentLabels = cell(size(N));
    alignedTS = ...
        alignedTimeSeries(0, 1, zeros(0, 0), [], N, alignmentLabels);
    originalDurations = [];
end
end

