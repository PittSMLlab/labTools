function stdTS = stdRobust(this, strideIdxs)
%STDROBUST Computes robust standard deviation.
%
%   stdTS = stdRobust(this) computes IQR-based robust standard deviation
%
%   stdTS = stdRobust(this, strideIdxs) computes for specified strides
%
% Inputs:
%   this       - alignedTimeSeries object
%   strideIdxs - vector of stride indices (optional, default: all)
%
% Outputs:
%   stdTS - alignedTimeSeries with robust std values
%
%   Note: IQR-based std computation: std ≈ IQR / 1.35
%
% Toolbox Dependencies: Statistics and Machine Learning Toolbox
%
% See also IQR, STD.

if nargin > 1 && ~isempty(strideIdxs)
    this.Data = this.Data(:, :, strideIdxs);
end
% IQR-based std computation
iqrToStd = 1.35; % IQR of a normal distribution is ~1.349 std
stdTS    = this.iqr .* (1 / iqrToStd);
end

