function adaptParams = calcAdaptParams(this)
%calcAdaptParams  Re-computes adaptation parameters
%
%   adaptParams = calcAdaptParams(this) calculates adaptation
%   parameters from the current data and returns them as a
%   parameterSeries object.
%
%   Inputs:
%       this - processedLabData object
%
%   Outputs:
%       adaptParams - parameterSeries object containing
%                     adaptation parameters
%
%   See also: parameterSeries, calcParameters

adaptParams = calcParameters(this);
end

