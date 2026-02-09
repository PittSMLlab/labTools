function [figHandle, plotHandles] = plotStridedTimeSeries( ...
    stridedTS, figHandle, plotHandles)
%plotStridedTimeSeries  Plots strided timeseries
%
%   [figHandle, plotHandles] = plotStridedTimeSeries(stridedTS) plots
%   strided timeseries data
%
%   [figHandle, plotHandles] = plotStridedTimeSeries(stridedTS,
%   figHandle, plotHandles) uses existing handles
%
%   Inputs:
%       stridedTS - cell array of strided timeseries
%       figHandle - figure handle (optional)
%       plotHandles - subplot handles (optional)
%
%   Outputs:
%       figHandle - figure handle
%       plotHandles - array of subplot handles
%
%   See also: plot, stridedTSToAlignedTS, alignedTimeSeries/plot

if nargin < 2
    figHandle = [];
end
if nargin < 3
    plotHandles = [];
end
N = 2^ceil(log2(1.5 / stridedTS{1}.sampPeriod));
structure = labTimeSeries.stridedTSToAlignedTS(stridedTS, N);
% Using the alignedTimeSeries plot function
[figHandle, plotHandles] = plot(structure, figHandle, plotHandles);
end

