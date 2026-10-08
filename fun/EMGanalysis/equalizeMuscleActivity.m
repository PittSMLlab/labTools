function [equalizedData,weights] = ...
    equalizeMuscleActivity(alignedStrides,weights)
%EQUALIZEMUSCLEACTIVITY Divide each channel of aligned strides by a weight.
%
%   Divides the aligned EMG strides by one weight per channel so that all
% channels carry comparable energy. With no weights given, each channel is
% divided by its summed squared amplitude over time and strides.
%
% Inputs:
%   alignedStrides - array of aligned strides; time x channels x strides
%   weights        - (optional) weight per channel, broadcast against
%                    alignedStrides (default: summed squares per channel)
%
% Outputs:
%   equalizedData - alignedStrides divided by weights
%   weights       - the weights that were used
%
% Toolbox Dependencies: None

if nargin < 2 || isempty(weights)
    weights = sum(sum(alignedStrides.^2,1),3);
end

equalizedData = bsxfun(@rdivide,alignedStrides,weights);

end

