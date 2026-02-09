function data = getSample(this, timePoints, method)
%getSample  Samples timeseries at arbitrary timepoints
%
%   data = getSample(this, timePoints) samples the timeseries at
%   specified time points using linear interpolation
%
%   data = getSample(this, timePoints, method) uses specified
%   interpolation method
%
%   Inputs:
%       this - labTimeSeries object
%       timePoints - vector or array of time points to sample
%       method - interpolation method: 'linear' or 'closest'
%                (optional, default: 'linear' for numeric, 'closest'
%                for logical)
%
%   Outputs:
%       data - sampled data with same dimensions as timePoints in
%              first dimensions, followed by number of labels
%
%   Note: NaN and Inf timepoints return NaN. Out-of-range points
%         return NaN.
%
%   See also: resample, resampleN, synchTo

% This does not seem efficient: we are creating a timeseries object
% (from native Matlab) and using its resample method.
if nargin < 3 || isempty(method)
    if isa(this.Data(1, 1), 'logical')
        method = 'closest';
    else
        method = 'linear';
    end
end

if ~isempty(timePoints)
    M = length(this.labels);
    switch method
        case 'linear'
            data = nan(numel(timePoints), M);
            % Excluding NaNs, Infs, & out-of-range times from interpolation
            notNaNIdxs = ~isnan(timePoints) & ~isinf(timePoints) & ...
                timePoints < this.Time(end) & timePoints > this.Time(1);
            [notNaNTimes, sorting] = ...
                sort(timePoints(notNaNIdxs), 'ascend');
            % Using timeseres.resample which does linear interp by default
            newTS = resample(this, notNaNTimes, this.Time(1), 1);
            newTS.Data(sorting, :) = newTS.Data;
            data(notNaNIdxs, :) = newTS.Data;
        case 'closest'
            data = nan(numel(timePoints), M);
            aux = this.getIndexClosestToTimePoint(timePoints(:));
            inds = ~isnan(aux);
            aux = aux(inds); % Eliminating NaNs
            % This would be the new data in the simplest case.
            newData = this.Data(aux, :);
            initData = newData;
            % But, if two samples map to the same timePoint (sub-sampling)
            % and that timePoint corresponds to an event, just keep the
            % closest one, to avoid repeating events.
            % Unique samples that contain an event
            trueEventSamples = ...
                unique(aux(any(newData, 2) & [diff(aux); 1] == 0));
            tt = this.Time(trueEventSamples);
            for i = 1:length(trueEventSamples)
                mappedInds = find(aux == trueEventSamples(i));
                relevantTimePoints = timePoints(mappedInds);
                Dt = abs(tt(i) - relevantTimePoints);
                % The find() is needed to resolve ties
                jj = find(Dt == min(Dt), 1, 'first');
                mappedInds(jj) = [];
                newData(mappedInds, :) = 0;
            end
            data(inds, :) = newData;
            % % Sanity check, this can be deprecated if no errors found by
            % % Jan 1st 2018. [implemented Sept 11 2017]
            % % Check that #events did not change:
            % if any(sum(newData) ~= sum(this.split(min(timePoints(:)) - ...
            %         this.sampPeriod / 2, max(timePoints(:)) + ...
            %         this.sampPeriod).Data))
            %     error(['Something went wrong when resampling: number ' ...
            %         'of events changed']);
            % end
            % % Check that no event is present at a sample
            % % where it was previously not:
            % if any(any(newData & ~initData))
            %     error(['Something went wrong when resampling: event ' ...
            %         'location changed']);
            % end
            % TODO: add interpft1 interpolation as possible method,
            % provided that the timepoints are equally spaced.
    end
    % Can't have sparse ND matrices (WHY??)
    data = reshape(full(data), [size(timePoints), M]);
else
    data = [];
end
end

