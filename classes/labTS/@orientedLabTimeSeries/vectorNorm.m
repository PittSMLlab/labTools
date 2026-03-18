function newThis = vectorNorm(this)
%vectorNorm  Computes 2-norm of vectors
%
%   newThis = vectorNorm(this) computes Euclidean norm of each
%   vector/marker
%
%   Inputs:
%       this - orientedLabTimeSeries object
%
%   Outputs:
%       newThis - labTimeSeries with vector magnitudes
%
%   See also: getOrientedData

newThis = labTimeSeries(sqrt(sum(this.getOrientedData.^2, 3)), ...
    this.Time(1), this.sampPeriod, ...
    strcat(this.getLabelPrefix, '_2-norm'));
end

