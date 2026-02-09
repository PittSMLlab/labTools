function newThis = resampleLogical(this, newTs, newT0, newN)
%resampleLogical  Resamples logical timeseries
%
%   newThis = resampleLogical(this, newTs, newT0, newN) resamples a
%   logical (event) timeseries to new sampling
%
%   Inputs:
%       this - labTimeSeries object with logical data
%       newTs - new sampling period
%       newT0 - new initial time
%       newN - new number of samples
%
%   Outputs:
%       newThis - resampled labTimeSeries with logical data
%
%   Note: Can this be deprecated in favor of resample with 'logical'
%         method?
%
%   See also: resample, resampleN, getSample

% newN = floor((this.Time(end) - newT0) / newTs + 1);
% TODO: Can this be deprecated in favor of resample with 'logical' method?
newTime = [0:newN - 1] * newTs + newT0;
newN = length(newTime);
% Sparse logical array of size newN x size(this.Data, 2) and room for
% up to size(this.Data, 2) true elements.
newData = sparse([], [], false, newN, size(this.Data, 2), newN);
for i = 1:size(this.Data, 2) % Go over event labels
    oldEventTimes = this.Time(this.Data(:, i)); % Find time of old events
    % Find closest index in new event
    closestNewEventIndexes = round((oldEventTimes - newT0) / newTs) + 1;
    % It could happen in case of down-sampling that the closest new
    % index falls outside the range
    if any(closestNewEventIndexes > newN)
        % Option 1: set it to the last available sample (this would no
        % longer be 'rounding')
        closestNewEventIndexes(closestNewEventIndexes > newN) = newN;
        % Option 2: eliminate event, as it falls outside range. This may
        % cause failure of other functions that rely on down-sampling of
        % events not changing the number of events
        closestNewEventIndexes(closestNewEventIndexes > newN) = [];
    end
    newData(closestNewEventIndexes, i) = true;
end
newThis = labTimeSeries(newData, newT0, newTs, this.labels);
end

