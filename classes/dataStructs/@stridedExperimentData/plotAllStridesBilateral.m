function [figHandle, plotHandles] = plotAllStridesBilateral(this, ...
    field, conditions, plotHandles, figHandle)
%PLOTALLSTRIDESBILATERAL Plots bilateral data overlaid.
%
%   [figHandle, plotHandles] = plotAllStridesBilateral(this, field,
% conditions) forces 'L' and 'R' labeled data to be plotted on top
% of each other
%
%   [figHandle, plotHandles] = plotAllStridesBilateral(this, field,
% conditions, plotHandles, figHandle) uses existing plot handles
%
% Inputs:
%   this        - stridedExperimentData object
%   field       - name of field to plot
%   conditions  - vector of condition indices to plot
%   plotHandles - existing subplot handles (optional)
%   figHandle   - existing figure handle (optional)
%
% Outputs:
%   figHandle   - handle to figure
%   plotHandles - array of subplot handles
%
% TODO: implement bilateral overlay; currently this just calls
%       plotAllStrides.
%
% Toolbox Dependencies: None
%
% See also PLOTALLSTRIDES, PLOTAVGSTRIDE.

% Forces 'L' and 'R' to be plotted on top of each other TODO
[figHandle, plotHandles] = plotAllStrides(this, field, conditions, ...
    plotHandles, figHandle);
end

