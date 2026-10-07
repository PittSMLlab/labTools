function [figHandle, plotHandles] = plotStridedTimeSeries( ...
    stridedTS, figHandle, plotHandles)
%PLOTSTRIDEDTIMESERIES Plots strided timeseries.
%
%   [figHandle, plotHandles] = plotStridedTimeSeries(stridedTS) plots
% strided timeseries data
%
%   [figHandle, plotHandles] = plotStridedTimeSeries(stridedTS, figHandle,
% plotHandles) uses existing handles
%
% Inputs:
%   stridedTS   - cell array of strided timeseries
%   figHandle   - figure handle (optional)
%   plotHandles - subplot handles (optional)
%
% Outputs:
%   figHandle   - figure handle
%   plotHandles - array of subplot handles
%
% Toolbox Dependencies: None
%
% See also PLOT, STRIDEDTSTOALIGNEDTS, ALIGNEDTIMESERIES/PLOT.

if nargin < 2
    figHandle = [];
end
if nargin < 3
    plotHandles = [];
end
maxStrideDuration = 1.5; % s, TODO: source?
N         = 2^ceil(log2(maxStrideDuration / stridedTS{1}.sampPeriod));
structure = labTimeSeries.stridedTSToAlignedTS(stridedTS, N);
% Using the alignedTimeSeries plot function
[figHandle, plotHandles] = plot(structure, figHandle, plotHandles);
end

