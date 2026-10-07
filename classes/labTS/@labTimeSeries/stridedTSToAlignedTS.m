function [alignedTS, originalDurations] = ...
    stridedTSToAlignedTS(stridedTS, N)
%STRIDEDTSTOALIGNEDTS Converts strided TS to aligned TS.
%
%   [alignedTS, originalDurations] = stridedTSToAlignedTS(stridedTS, N)
% converts cell array of strided timeseries to aligned timeseries
%
% Inputs:
%   stridedTS - cell array (strides x phases) of labTimeSeries
%   N         - vector of sample counts for each phase
%
% Outputs:
%   alignedTS         - alignedTimeSeries object
%   originalDurations - matrix of original phase durations
%
%   Note: Deprecated. Use labTS.align()
%
% Toolbox Dependencies: None
%
% See also ALIGN, SPLITBYEVENTS, ALIGNEDTIMESERIES.

error('labTS:stridedTSToAlignedTS', 'Deprecated. Use labTS.align();');
% To be used after splitByEvents
if numel(stridedTS) ~= 0
    if ~islogical(stridedTS{1}.Data)
        aux = zeros(sum(N), size(stridedTS{1}.Data, 2),size(stridedTS, 1));
    else
        aux = false(sum(N), size(stridedTS{1}.Data, 2),size(stridedTS, 1));
    end
    Nstrides          = size(stridedTS, 1);
    Nphases           = size(stridedTS, 2);
    originalDurations = nan(Nstrides, Nphases);
    for ii = 1:Nstrides % Going over strides
        M = [0, cumsum(N)];
        for jj = 1:Nphases % Going over aligned phases
            if isa(stridedTS{ii, jj}, 'labTimeSeries')
                originalDurations(ii, jj) = stridedTS{ii, jj}.timeRange;
                if ~isempty(stridedTS{ii, jj}.Data) && ...
                        sum(~isnan(stridedTS{ii, jj}.Data(:, 1))) > 1
                    aa = resampleN(stridedTS{ii, jj}, N(jj));
                    aux(M(jj) + 1:M(jj + 1), :, ii) = aa.Data;
                else
                    % Separating by strides returned empty labTimeSeries,
                    % possibly because of events in disorder
                    if islogical(stridedTS{ii, jj}.Data)
                        aux(M(jj) + 1:M(jj + 1), :, ii) = false;
                    else
                        aux(M(jj) + 1:M(jj + 1), :, ii) = NaN;
                    end
                end
            else
                error('labTimeSeries:stridedTSToAlignedTS', ...
                    ['First argument is not a cell array of ' ...
                    'labTimeSeries. Element i = ' num2str(ii) ', j = ' ...
                    num2str(jj)]);
            end
        end
    end
    % Need to populate this field properly
    alignmentLabels = cell(size(N));
    % Sampling time is 1, so the time vector counts samples.
    alignedTS = alignedTimeSeries(0, 1, aux, stridedTS{1}.labels, N, ...
        alignmentLabels);
else
    alignmentLabels = cell(size(N));
    alignedTS = ...
        alignedTimeSeries(0, 1, zeros(0, 0), [], N, alignmentLabels);
    originalDurations = [];
end
end

