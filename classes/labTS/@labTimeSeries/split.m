function newThis = split(this, t0, t1)
%split  Returns timeseries between two timepoints
%
%   newThis = split(this, t0, t1) returns a timeseries containing data
%   in the semi-closed interval [t0, t1)
%
%   Inputs:
%       this - labTimeSeries object
%       t0 - start time (inclusive)
%       t1 - end time (exclusive)
%
%   Outputs:
%       newThis - labTimeSeries containing data in [t0, t1)
%
%   Note: Pads with NaN if requested interval extends beyond available
%         data. Returns empty if interval falls between samples.
%
%   See also: sliceTS, getSample

% Need to test this chunk of code before enabling:
% if isnan(t0) || isnan(t1)
%     warning('labTS:split', 'One of the interval limits is NaN.
%         Returning empty TS.')
%     newTS = [];
%     return
% end

% Check t0 >= Time(1)
% Check t1 <= Time(end)
initT = this.Time(1) - eps;
% finalT = this.Time(end) + eps; % SL commented out, this will throw
% warning when trying to get the last sample the original intention
% was good to do [t0, t1) to avoid repeated sample, but the last
% sample (Time(end)) was never retrievable with this approach.
% To get the last sample without warning.
finalT = this.Time(end) + this.sampPeriod;
if ~(t0 >= initT && t1 <= finalT)
    if (t1 < initT) || (t0 >= finalT)
        % ME = MException('labTS:split', 'Given time interval is not
        %     (even partially) contained within the time series.');
        % throw(ME);
        warning('LabTS:split', ...
            ['Requested interval [' num2str(t0) ',' num2str(t1) ...
            '] is fully outside the timeseries. Padding with NaNs.']);
    else
        warning('LabTS:split', ...
            ['Requested interval [' num2str(t0) ',' num2str(t1) ...
            '] is not completely contained in TimeSeries. Padding ' ...
            'with NaNs.']);
    end
end
% Find portion of requested interval that falls within the
% timeseries' time vector (if any).
i1 = find(this.Time >= t0, 1);
% Explicitly NOT including the final sample, so that the time series
% is returned as the semi-closed interval [t0, t1). This avoids
% repeated samples if we ask for [t0, t1) and then for [t1, t2) SL:
% this will never be able to find the last sample if set t1 =
% this.Time(end) + eps, this.Time(end) < t1 evaluates to false (eps
% is machine precision, too small to make the boolean eval true? This
% may be a Matlab precision issue)
i2 = find(this.Time < t1, 1, 'last');
% This happens when the whole timeseries is outside the range
if isempty(i1) || isempty(i2)
    i1 = 1;
    i2 = 0;
    % When this happens the last included sample precedes the first
    % included one, which happens, because of rounding, when asking for a
    % very small interval (smaller than the sample period).
elseif i2 < i1
    warning('LabTS:split', ...
        ['Requested interval [' num2str(t0) ',' num2str(t1) ...
        '] falls completely within two samples: returning empty ' ...
        'timeSeries.']);
end
% In case the requested time interval is larger than the timeseries'
% actual time vector, pad with NaNs:
% Case we are requesting time-samples preceding the timeseries' start-time
if (this.Time(1) - t0) > eps
    % Extra samples to be added at the beginning
    ia = floor((this.Time(1) - t0) / this.sampPeriod);
else
    ia = 0;
end
% Case we are requesting time-samples following the timeseries' end-time
if (t1 - this.Time(end)) > eps
    % Extra samples to be added at the end
    ib = floor((t1 - this.Time(end)) / this.sampPeriod);
else
    ib = 0;
end
if ~islogical(this.Data(1, 1))
    newThis = labTimeSeries([nan(ia, size(this.Data, 2)); ...
        this.Data(i1:i2, :); nan(ib, size(this.Data, 2))], ...
        this.Time(i1) - this.sampPeriod * ia, this.sampPeriod,this.labels);
else
    newThis = labTimeSeries([false(ia, size(this.Data, 2)); ...
        this.Data(i1:i2, :); false(ib, size(this.Data, 2))], ...
        this.Time(i1) - this.sampPeriod * ia, this.sampPeriod,this.labels);
end
if ~isempty(this.Quality)
    newThis.QualityInfo = this.QualityInfo;
    k = find(strcmp(this.QualityInfo.Description, 'missing'));
    newThis.Quality = [k * ones(ia, size(this.Quality, 2)); ...
        this.Quality(i1:i2, :); k * ones(ib, size(this.Quality, 2))];
end
end

