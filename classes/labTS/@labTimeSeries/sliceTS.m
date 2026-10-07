function [slicedTS, initTime, duration] = sliceTS(this, ...
    timeBreakpoints, timeMargin)
%sliceTS  Slices at given time breakpoints
%
%   [slicedTS, initTime, duration] = sliceTS(this, timeBreakpoints,
%   timeMargin) slices a single timeseries into cell array of smaller
%   timeseries at given breakpoints
%
%   Inputs:
%       this - labTimeSeries object
%       timeBreakpoints - vector of time points for slicing
%       timeMargin - time margin to add before/after each slice
%
%   Outputs:
%       slicedTS - cell array of sliced timeseries
%       initTime - vector of initial times for each slice
%       duration - vector of durations for each slice
%
%   See also: split, splitByEvents

slicedTS = cell(1, length(timeBreakpoints) - 1);
for ii = 1:length(timeBreakpoints) - 1
    if isnan(timeBreakpoints(ii)) || isnan(timeBreakpoints(ii + 1)) || ...
            timeBreakpoints(ii + 1) < timeBreakpoints(ii)
        % Preventing overload of annoying warnings
        warning('off');
    end
    slicedTS{ii} = this.split(timeBreakpoints(ii) - timeMargin, ...
        timeBreakpoints(ii + 1) + timeMargin);
    warning('on');
end
initTime = timeBreakpoints(1:end - 1) - timeMargin;
duration = diff(timeBreakpoints) + 2 * timeMargin;
end

