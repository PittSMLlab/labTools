function [Y] = demean(X)

aux=mean(X,1);
Y=X(:,:)-repmat(aux(:,:),[size(X,1),1]);
Y=reshape(Y,size(X));
%DEMEAN Remove the column-wise mean from a matrix.
%
%   Subtracts the mean of each column from the corresponding column of X.
% NaN values are ignored when computing the mean.
%
% Inputs:
%   X - (N×C) double, input data matrix
%
% Outputs:
%   Y - (N×C) double, mean-subtracted data (same size as X)
%
% Toolbox Dependencies: None
%
% See also COLUMNNORM.

end

