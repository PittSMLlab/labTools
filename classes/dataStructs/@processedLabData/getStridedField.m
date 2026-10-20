function [stridedField, bad, initTime, events] = ...
    getStridedField(this, field, events)
%GETSTRIDEDFIELD Extracts field data organized by stride
%
%   [stridedField, bad, initTime, events] = getStridedField(this, field,
% events) extracts the specified field data and organizes it by stride based
% on the provided events
%
% NOTE: This method is very slow and has been deprecated. Please don't use.
%
% Inputs:
%   this   - processedLabData object
%   field  - name of the data field to extract
%   events - event label or cell array of event labels defining stride
%            boundaries
%
% Outputs:
%   stridedField - cell array of time series data organized by stride
%   bad          - logical vector indicating strides with incomplete or
%                  missing events
%   initTime     - vector of stride start times
%   events       - cell array of event labels used
%
% Toolbox Dependencies: None
%
% See also GETALIGNEDFIELD, GETSTRIDEINFO.

warning('This is very slow and has been deprecated. Please don''t use.');

if isa(events, 'char')
    events = {events};
end

% Step 1: separate strides by the first event
[numStrides, initTime, endTime] = getStrideInfo(this, events{1});
M = numStrides;
N = length(events);

% Step 2: for each stride, find the other events (if any)
intermediateTimes = nan(M, N - 1);
bad = false(M, 1);
for ii = 1:M
    for jj = 1:N - 1
        aux = find(this.gaitEvents.getDataAsVector(events{jj + 1}) & ...
            this.gaitEvents.Time >= initTime(ii) & ...
            this.gaitEvents.Time < endTime(ii));
        if length(aux) == 1 % Found only one event, as expected
            intermediateTimes(ii, jj) = this.gaitEvents.Time(aux);
        else
            bad(ii) = true;
        end
    end
end

% Step 3: slice timeseries
timeBreakpoints = [initTime, intermediateTimes]';
slicedTS        = sliceTS(this.(field), ...
    [timeBreakpoints(:); endTime(end)], 0);

% Step 4: reshape & set to [] the slices which didn't have proper events
stridedField = reshape(slicedTS, N, M)';
end

