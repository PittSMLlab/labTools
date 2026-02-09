function stdTS = stdRobust(this, strideIdxs)
%stdRobust  Computes robust standard deviation
%
%   stdTS = stdRobust(this) computes IQR-based robust standard
%   deviation
%
%   stdTS = stdRobust(this, strideIdxs) computes for specified strides
%
%   Inputs:
%       this - alignedTimeSeries object
%       strideIdxs - vector of stride indices (optional, default: all)
%
%   Outputs:
%       stdTS - alignedTimeSeries with robust std values
%
%   Note: IQR-based std computation: std ≈ IQR / 1.35
%
%   See also: iqr, std

if nargin > 1 && ~isempty(strideIdxs)
    this.Data = this.Data(:, :, strideIdxs);
end
% IQR-based std computation
stdTS = this.iqr .* (1 / 1.35);
end

