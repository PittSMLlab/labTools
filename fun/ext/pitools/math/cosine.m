function C = cosine(X,Y)
%COSINE Cosine of the angle between vectors.
%
%   C = COSINE(X,Y) returns the cosine of the angle between the columns of X
% and the columns of Y: C(a,b) = X(:,a)'*Y(:,b)/(norm(X(:,a))*norm(Y(:,b))).
% For vectors this is a scalar. COSINE(X) uses Y = X.
%
% Inputs:
%   X - M x A matrix (or vector)
%   Y - (optional) M x B matrix (default: X)
%
% Outputs:
%   C - A x B matrix of cosines
%
% Toolbox Dependencies: None

if nargin == 1
    Y = X;
end

C = (X'*Y)./sqrt(sum(X.^2,1)'*sum(Y.^2,1));

end
