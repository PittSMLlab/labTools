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
for i = 1:length(timeBreakpoints) - 1
    if isnan(timeBreakpoints(i)) || isnan(timeBreakpoints(i + 1)) || ...
            timeBreakpoints(i + 1) < timeBreakpoints(i)
        % Preventing overload of annoying warnings
        warning('off');
    end
    slicedTS{i} = this.split(timeBreakpoints(i) - timeMargin, ...
        timeBreakpoints(i + 1) + timeMargin);
    warning('on');
end
initTime = timeBreakpoints(1:end - 1) - timeMargin;
duration = diff(timeBreakpoints) + 2 * timeMargin;
end

