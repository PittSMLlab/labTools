function xMLE = skDistlearnenforce(x,P,s,R)
%SKDISTLEARNENFORCE Bayesian estimate of positions under a distance model.
%
%   xMLE = SKDISTLEARNENFORCE(x,P,s,R) combines a prior estimate x (normal,
% with covariance P) of the marker positions with the pairwise-distance
% model d(x) ~ N(s,diag(R)). The distance constraints are linearized
% around the current estimate and solved with UPDATEKF until the estimate
% changes by less than 1e-3 or 25 iterations are reached. Elements of x
% that are NaN are treated as missing and given numerically infinite
% uncertainty.
%
% NOTE: the function is named skDistlearnenforce but the file is
% skDistenforce.m, so MATLAB calls it by the file name. UPDATEKF is not in
% the repository.
%
% Inputs:
%   x - N x d prior marker positions (NaN marks a missing element)
%   P - prior covariance of x(:)
%   s - N x N mean pairwise distances
%   R - N x N variances of the pairwise distances
%
% Outputs:
%   xMLE - estimated positions (vectorized, N*d x 1)
%
% Toolbox Dependencies: None
%
% See also SKDISTLEARN, SKDISTDETECT, SK3DENFORCE.

[N,d] = size(x);

%Deal with NaNs in data:
missingScale = 1e15; % makes the uncertainty of missing elements infinite
idx = isnan(x(:));
x(idx) = 0;
aux = zeros(N*d,1);
aux(idx) = 1;
P = P+missingScale*max(P(:))*diag(aux);

%Iterate: linearize, find optimal solution
endFlag  = false;
changeTh = 1e-3;
xMLE     = x(:); %Nd x 1
%Reshaping parameters for updateKF:
y        = zeros(N^2,1);s = s(:);R = diag(R(:));x = x(:);
lastXMLE = x; %Init guess
iter     = 0;
maxIter  = 25;
while ~endFlag && iter < maxIter
    %Linearize distance constraints:
    [off,W] = linearizeDist(reshape(lastXMLE,N,d));
    %Optimal bayesian solution around linearized point:
    [xMLE,PMLE] = updateKF(W,R,x,P,s-off(:),y);
    change   = sqrt(sum((xMLE-lastXMLE(:)).^2));
    endFlag  = change < changeTh;
    lastXMLE = xMLE;
    iter     = iter+1;
end
end

function [Do,W] = linearizeDist(xo)
%LINEARIZEDIST Linearize the pairwise distance matrix around a point.
%
%   [Do,W] = LINEARIZEDIST(xo) approximates D = computeDistanceMatrix(x)
% around x = xo as D(:) ~ Do(:) + W*x(:).
%
% Inputs:
%   xo - N x d positions to linearize around
%
% Outputs:
%   Do - N x N offset term
%   W  - N^2 x (N*d) Jacobian of the distance matrix
%
% Toolbox Dependencies: None
%
% See also COMPUTEDISTANCEMATRIX, TESTLINEARIZATION.

[N,d] = size(xo);
D  = computeDistanceMatrix(xo);
G1 = reshape(xo,N,1,d)./(D+eye(N));
G2 = reshape(xo,1,N,d)./(D+eye(N));
W1 = zeros(N,N,N,d);
W2 = zeros(N,N,N,d);
for mrkr = 1:N
    W1(mrkr,:,mrkr,:) = G1(:,mrkr,:);
    W2(:,mrkr,mrkr,:) = G2(:,mrkr,:);
end
%Need to reshape G/pad with 0's, so W is NxNxNd
W  = W1-W2; %NxNxNxd
W  = reshape(W,N^2,N*d);
Do = D-reshape(W*xo(:),N,N); %NxN
end

function testLinearization(xo)
%TESTLINEARIZATION Check LINEARIZEDIST against a small perturbation.
%
%   TESTLINEARIZATION(xo) perturbs xo by a small random amount and prints
% the norm of the difference between the true and the linearized distance
% matrix, which should be very small.
%
% Inputs:
%   xo - N x d positions to linearize around
%
% Outputs:
%   none (prints the norm of the linearization error)
%
% Toolbox Dependencies: None
%
% See also LINEARIZEDIST.

D = computeDistanceMatrix(xo);
[Do,W] = linearizeDist(xo);
e     = 1e-3;
p     = e*randn(size(xo));
x     = xo+p;
D1    = computeDistanceMatrix(x);
D1app = Do(:)+W*x(:);

%Check: D1 ~ D1app
norm(D1(:)-D1app) %Should be very small
end
