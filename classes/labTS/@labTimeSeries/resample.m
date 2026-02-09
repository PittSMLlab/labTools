function newThis = resample(this, newTs, newT0, hiddenFlag)
%resample  Resamples timeseries to different sampling period
%
%   newThis = resample(this, newTs, newT0) resamples the timeseries to
%   new sampling period starting at newT0
%
%   newThis = resample(this, newTs, newT0, hiddenFlag) allows
%   non-uniform resampling when hiddenFlag = 1
%
%   Inputs:
%       this - labTimeSeries object
%       newTs - new sampling period (or time vector if hiddenFlag = 1)
%       newT0 - new initial time
%       hiddenFlag - if 1, allows non-uniform resampling (optional,
%                    default: 0)
%
%   Outputs:
%       newThis - resampled labTimeSeries
%
%   Note: Resampling using only the new sampling period is no longer
%         supported. Use resampleN to interpolate keeping exact same
%         time range.
%
%   See also: resampleN, getSample

this.Quality = []; % So Quality is not resampled if it exists
if nargin < 3 || isempty(newT0)
    error('labTS:resample', ...
        ['Resampling using only the new sampling period as argument ' ...
        'is no longer supported. Use resampleN if you want to ' ...
        'interpolate keeping the exact same time range.']);
end
if nargin < 4 || isempty(hiddenFlag) || hiddenFlag == 0
    % hiddenFlag allows to do non-uniform sampling
    if newTs > this.sampPeriod
        warning('labTS:resample', ...
            'Under-sampling data, be careful of aliasing!');
    end
    % Pablo I. (4/4/2015) No longer think this is a good idea. If we are
    % explicitly trying to do uniform resampling on the same range, should
    % use resampleN. Otherwise, if we try to synch two signals, and there
    % is an offset in initial time, this returns something else.
    newN = ceil(this.timeRange / newTs) + 1;
    % newThis = resampleN(this, newN);
    newTime = newT0:newTs:this.Time(end);
    if ~isa(this.Data(1, 1), 'logical')
        newThis = this.resample@timeseries(newTime);
        newThis = labTimeSeries( ...
            newThis.Data, newThis.Time(1), newTs, this.labels);
    else % logical timeseries
        newThis = resampleLogical(this, newTs, newT0, newN);
        % Can be this deprecated in favor of just using getSample()
        % for a logical TS?
    end
    % this allows for non-uniform resampling, and returns timeseries object
elseif hiddenFlag == 1
    % Warning: Treating newTs argument as vector containing timepoints, not
    % sampling period. Super-class resampling returns super-class object.
    newThis = this.resample@timeseries(newTs);
else
    error('labTS:resample', 'HiddenFlag argument has to be 0 or 1');
end
end

