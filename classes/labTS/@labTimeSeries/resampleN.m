function newThis = resampleN(this, newN, method)
%resampleN  Resamples to N samples over same time range
%
%   newThis = resampleN(this, newN) performs uniform resampling of
%   data over the same time range using Fourier interpolation
%
%   newThis = resampleN(this, newN, method) uses specified
%   interpolation method
%
%   Inputs:
%       this - labTimeSeries object
%       newN - target number of samples
%       method - 'interpft' (default for numeric), 'logical' (default
%                for logical), 'linear', 'cubic', or any method
%                accepted by interp1
%
%   Outputs:
%       newThis - resampled labTimeSeries with same time range
%
%   Note: Keeps initial time on same value and returns newN time-
%         samples in the time interval of the original timeseries
%
%   See also: resample, interpft1, interp1

if ~isempty(this.Data)
    if nargin < 3 || isempty(method)
        if ~isa(this.Data(1, 1), 'logical')
            method = 'interpft';
        else
            method = 'logical';
        end
    end
    modNewTs = this.timeRange / newN;
    newTimeVec = [0:newN - 1] * modNewTs + this.Time(1);
    switch method
        case 'interpft'
            allNaNIdxs = [];
            if any(isnan(this.Data(:)))
                if any(all(isnan(this.Data)))
                    allNaNIdxs = all(isnan(this.Data));
                    warning(['All data is NaNs for labels ' ...
                        strcat(this.labels{allNaNIdxs}, ' ') ...
                        ', not interpolating those: returning NaNs']);
                end
            end
            % Substituting 0's to allow next line to run without problems
            this.Data(:, allNaNIdxs) = 0;
            % Only if there are still NaNs after the previous step, we will
            % substitute the missing data with linearly interpolated values
            if any(isnan(this.Data(:)))
                warning(['Trying to interpolate data using Fourier ' ...
                    'Transform method (''interpft1''), but data ' ...
                    'contains NaNs (missing values) which will ' ...
                    'propagate to the full timeseries. Substituting ' ...
                    'NaNs with linearly interpolated data.']);
                % Interpolate time-series that are not all NaN (this is,
                % there are just some values missing)
                this = substituteNaNs(this, 'linear');
            end
            % Interpolation is done on a nice(r) way.
            newData = interpft1(this.Data, newN, 1);
            % Replacing the previously filled data with NaNs
            newData(:, allNaNIdxs) = nan;
        case 'logical'
            newThis = resampleLogical(this, modNewTs, this.Time(1), newN);
            newData = newThis.Data;
        otherwise
            % Method is 'linear', 'cubic' or any interp1 accepted methods
            newData = zeros(length(newTimeVec), size(this.Data, 2));
            for i = 1:size(this.Data, 2)
                newData(:, i) = interp1(this.Time, this.Data(:, i), ...
                    newTimeVec, method, nan);
            end
    end
    t0 = this.Time(1);
    newThis = labTimeSeries(newData, t0, modNewTs, this.labels);
else % this.Data == []
    error('labTimeSeries:resampleN', ...
        'Interpolating empty labTimeSeries, impossible.');
end
end

