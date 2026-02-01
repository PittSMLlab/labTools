function [figHandle, plotHandles] = plotAllStridesBilateral(this, ...
    field, conditions, plotHandles, figHandle)
%plotAllStridesBilateral  Plots bilateral data overlaid
%
%   [figHandle, plotHandles] = plotAllStridesBilateral(this, field,
%   conditions) forces 'L' and 'R' labeled data to be plotted on top
%   of each other
%
%   [figHandle, plotHandles] = plotAllStridesBilateral(this, field,
%   conditions, plotHandles, figHandle) uses existing plot handles
%
%   Inputs:
%       this - stridedExperimentData object
%       field - name of field to plot
%       conditions - vector of condition indices to plot
%       plotHandles - existing subplot handles (optional)
%       figHandle - existing figure handle (optional)
%
%   Outputs:
%       figHandle - handle to figure
%       plotHandles - array of subplot handles
%
%   Note: To Do - implementation currently just calls plotAllStrides
%
%   See also: plotAllStrides, plotAvgStride

% Forces 'L' and 'R' to be plotted on top of each other TODO
[figHandle, plotHandles] = plotAllStrides(this, field, conditions, ...
    plotHandles, figHandle);
end

