function Y = smoothedMax(X,N,vector)
%SMOOTHEDMAX finds the maximum value of an N-pt running average 
%   For vectors, smoothedMax(X,N) returns the largest value of the N-pt 
%   running  average of X. For matrixes, smoothedMax(X,N) takes an N-pt running
%   average of each column and returens the largest value within each column.
%
%   xMax=smoothedMax(X,N,dataVector) returns the values of the N-pt
%   running average of X in the same location as the largest value of the
%   N-pt running average of dataVector if dataVector is a column vector that has
%   the same length as the columns of X.

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

