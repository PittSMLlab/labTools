function adaptParams = calcAdaptParams(this)
%CALCADAPTPARAMS Re-computes adaptation parameters
%
%   adaptParams = calcAdaptParams(this) calculates adaptation parameters
% from the current data and returns them as a parameterSeries object.
%
% Inputs:
%   this - processedLabData object
%
% Outputs:
%   adaptParams - parameterSeries object containing adaptation parameters
%
% Toolbox Dependencies: None
%
% See also PARAMETERSERIES, CALCPARAMETERS.

adaptParams = calcParameters(this);
end

