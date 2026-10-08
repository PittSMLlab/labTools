function out = computeTSStatParameters(tsData, strideEvents)
%COMPUTETSSTATPARAMETERS Compute summary statistics per stride.
%
%   Computes stride-by-stride summary statistics for each channel of a
% labTimeSeries and returns a parameterSeries object that can be
% concatenated with other parameter series objects (e.g., from
% computeTemporalParameters).
%
% Inputs:
%   tsData       - labTimeSeries object containing channel data
%   strideEvents - N-by-K matrix of stride event times (seconds),
%                  where N is the number of strides; the first
%                  column is used to slice tsData into strides
%
% Outputs:
%   out - parameterSeries object containing, for each channel, the
%         following statistics per stride: max, min, avg (mean),
%         var (variance), med (median), snr (signal-to-noise ratio
%         in dB), and bad (data-quality flag)
%
% Toolbox Dependencies:
%   None
%
% See also COMPUTESPATIALPARAMETERS, COMPUTETEMPORALPARAMETERS,
%   COMPUTEFORCEPARAMETERS, PARAMETERSERIES, CALCPARAMETERS.

arguments
    tsData       (1,1)
    strideEvents (:,:) double
end

%% Statistic Labels
% 'skw', 'kur', and 'iqr' are excluded -- never used and slow to compute
statSuffixes = {'max', 'min', 'avg', 'var', 'med', 'snr', 'bad'};

%% Slice Time Series and Allocate Arrays
slicedTS = tsData.sliceTS(strideEvents(:, 1), 0);  % first event only

numStrides    = length(slicedTS);
numStats      = length(statSuffixes);
channelLabels = tsData.labels;
numChannels   = length(channelLabels);
paramData     = nan(numStrides, numChannels, numStats);
paramLabels   = cell(numChannels, numStats);
description   = cell(numChannels, numStats);

%% Build Parameter Labels and Descriptions
for ch = 1:numChannels
    for stat = 1:numStats
        paramLabels{ch, stat} = ...
            [channelLabels{ch} statSuffixes{stat}];
        if strcmp(statSuffixes{stat}, 'bad')
            description{ch, stat} = [ ...
                'Signals if quality was anything other than good ' ...
                '(no missing, no spikes, no out-of-range) for muscle ' ...
                channelLabels{ch}];
        else
            description{ch, stat} = [ ...
                statSuffixes{stat} ' in timeseries ' ...
                channelLabels{ch}];
        end
    end
end

%% Compute Per-Stride Statistics
for st = 1:numStrides
    strideData = slicedTS{st}.Data;
    strideQual = slicedTS{st}.Quality;
    for ch = 1:numChannels
        channelData = strideData(:, ch);
        if ~isempty(strideQual)
            qualColumn = strideQual(:, ch);
        else
            qualColumn = 0;
        end
        for stat = 1:numStats
            switch statSuffixes{stat}
                case 'max'
                    %description{ch,stat}=['Peak proc EMG in muscle ' ...
                    %    channelLabels{ch}];
                    paramData(st, ch, stat) = max(channelData);
                case 'min'
                    %description{ch,stat}=['Min proc EMG in muscle ' ...
                    %    channelLabels{ch}];
                    paramData(st, ch, stat) = min(channelData);
                case 'iqr'
                    %description{ch,stat}=[ ...
                    %    'Inter-quartile range of proc EMG in muscle ' ...
                    %    channelLabels{ch}];
                    paramData(st, ch, stat) = iqr(channelData);
                case 'avg'
                    %description{ch,stat}=[ ...
                    %    'Avg. (mean) of proc EMG in muscle ' ...
                    %    channelLabels{ch}];
                    paramData(st, ch, stat) = mean(channelData);
                case 'var'
                    %description{ch,stat}=[ ...
                    %    'Variance of proc EMG in muscle ' ...
                    %    channelLabels{ch}];
                    paramData(st, ch, stat) = ...
                        var(channelData, 0);  % unbiased
                case 'skw'
                    %description{ch,stat}=[ ...
                    %    'Skewness of proc EMG in muscle ' ...
                    %    channelLabels{ch}];
                    paramData(st, ch, stat) = ...
                        skewness(channelData, 0);  % unbiased
                case 'kur'
                    %description{ch,stat}=[ ...
                    %    'Kurtosis of proc EMG in muscle ' ...
                    %    channelLabels{ch}];
                    paramData(st, ch, stat) = ...
                        kurtosis(channelData, 0);  % unbiased
                case 'med'
                    %description{ch,stat}=[ ...
                    %    'Median of proc EMG in muscle ' channelLabels{ch}];
                    paramData(st, ch, stat) = median(channelData);
                case 'snr'
                    %description{ch,stat}=[ ...
                    %    'Energy of proc EMG divided by base noise ' ...
                    %    'energy (in dB) for muscle ' channelLabels{ch}];
                    % TODO: min() may be near zero after low-pass
                    %   filtering; verify this is a valid SNR estimate
                    paramData(st, ch, stat) = 20 * log10( ...
                        mean(channelData.^2) / min(channelData)^2);
                case 'bad'
                    % quality codes are powers of 2 (up to 8 per int8);
                    % summing unique values tracks all issues at once
                    paramData(st, ch, stat) = ...
                        sum(unique(qualColumn));
            end
        end
    end
end

%% Output Computed Parameters
out = parameterSeries(paramData(:, :), paramLabels(:), [], description(:));

end

