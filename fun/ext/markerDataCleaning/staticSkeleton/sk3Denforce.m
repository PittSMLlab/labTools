function xMLE = sk3Denforce(x,P,s,R)
%SK3DENFORCE Bayesian estimate of marker positions under a skeleton model.
%
%   xMLE = SK3DENFORCE(x,P,s,R) combines a prior estimate x (normal, with
% covariance P) of the marker positions with the relative-position model
% W*x ~ N(s,diag(R)) and returns the optimal (bayesian) estimate. Elements
% of x that are NaN are treated as missing and given numerically infinite
% uncertainty.
%
% NOTE: stale research code. The body calls COMPUTEDIFFMATRIX with a scalar
% and calls UPDATEKF, which is not in the repository; the testSkeleton
% script passes five arguments.
%
% Inputs:
%   x - N x D prior marker positions (NaN marks a missing element)
%   P - prior covariance of x(:)
%   s - mean of the relative-position model
%   R - variances of the relative-position model
%
% Outputs:
%   xMLE - estimated positions (vectorized)
%
% Toolbox Dependencies: None
%
% See also SK3DLEARN, SK3DDETECT, SKDISTENFORCE.

[N,D] = size(x);
W = computeDiffMatrix(N);
Z = sparse(zeros(size(W)));

%Deal with NaNs in data:
missingScale = 1e15; % makes the uncertainty of missing elements infinite
idx = isnan(x(:));
x(idx) = 0;
aux = zeros(N*D,1);
aux(idx) = 1;
P = P+missingScale*max(P(:))*diag(aux);

[xMLE,PMLE] = updateKF([W Z Z;Z W Z; Z Z W],diag(R(:)),x(:),P,s(:), ...
    zeros(size(W,1)*D,1)); %Optimal bayesian update
end

