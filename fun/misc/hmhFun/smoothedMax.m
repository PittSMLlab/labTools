function Y = smoothedMax(X,N,vector)
if nargin>2
    if isempty(X)
        newX=NaN(1,size(X,2));
        newVector=NaN;
    elseif size(X,1)<N
        newX=nanmean(X);
        newVector=nanmean(vector);
    else
        [newX,~]=binData(X,N);
        [newVector,~]=binData(vector,N);
    end
    [~,maxLoc]=max(abs(newVector),[],1);
    Y=newX(maxLoc,:);
else
    if isempty(X)
        newX=NaN(1,size(X,2));        
    elseif size(X,1)<N
        newX=nanmean(X,1);        
    else
        [newX,~]=binData(X,N);        
    end
    [~,maxLoc]=max(abs(newX),[],1);
    ind=sub2ind(size(newX),maxLoc*ones(1,size(X,2)),1:size(X,2));
    Y=newX(ind,:);
end


end

%SMOOTHEDMAX Find the maximum of an N-point running average.
%
%   For vectors, smoothedMax(X, N) returns the largest value of the
% N-point running average of X. For matrices, takes an N-point running
% average of each column and returns the largest value within each
% column.
%
%   smoothedMax(X, N, vector) returns the values of the N-point running
% average of X at the location of the largest absolute value in the
% N-point running average of vector. vector must be a column vector with
% the same number of rows as X.
%
% Inputs:
%   X      - Numeric matrix or vector to evaluate
%   N      - Integer window width for the running average
%   vector - (Optional) Column vector with size(X,1) rows; when provided,
%            the peak location is taken from this vector rather than X
%
% Outputs:
%   Y - Row vector of smoothed-max values, one per column of X
%
% Toolbox Dependencies: None
%
% See also BINDATA, BIN_DATAV1.

