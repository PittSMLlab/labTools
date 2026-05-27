function [C] = cosine(X,Y)
%Calculates the cosine of vectors X,Y, or if they are matrices, the
%column-wise matrix of cosines

if nargin==1
    Y=X;
end

C=(X'*Y)./sqrt(sum(X.^2,1)'*sum(Y.^2,1));

end
