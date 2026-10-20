function [decomposition, meanValue, avgStride, ...
    trial2trialVariability] = energyDecomposition(this)
%ENERGYDECOMPOSITION Decomposes variance.
%
%   [decomposition, meanValue, avgStride, trial2trialVariability] =
% energyDecomposition(this) decomposes variance into mean, average stride
% pattern, and trial-to-trial variability
%
% Inputs:
%   this - alignedTimeSeries object
%
% Outputs:
%   decomposition          - variance decomposition results
%   meanValue              - mean value component
%   avgStride              - average stride pattern component
%   trial2trialVariability - trial-to-trial variability component
%
% Toolbox Dependencies: None
%
% See also GETVARIANCEDECOMPOSITION.

alignedData = this.Data;
[decomposition, meanValue, avgStride, trial2trialVariability] = ...
    getVarianceDecomposition(alignedData);
end

