function newThis = vectorNorm(this)
%VECTORNORM Computes 2-norm of vectors.
%
%   newThis = vectorNorm(this) computes Euclidean norm of each vector/marker
%
% Inputs:
%   this - orientedLabTimeSeries object
%
% Outputs:
%   newThis - labTimeSeries with vector magnitudes
%
% Toolbox Dependencies: None
%
% See also GETORIENTEDDATA.

newThis = labTimeSeries(sqrt(sum(this.getOrientedData.^2, 3)), ...
    this.Time(1), this.sampPeriod, ...
    strcat(this.getLabelPrefix, '_2-norm'));
end

