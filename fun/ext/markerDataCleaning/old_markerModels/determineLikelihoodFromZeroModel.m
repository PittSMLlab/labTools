function [lp,p] = determineLikelihoodFromZeroModel(X,D,sD)
%DETERMINELIKELIHOODFROMZEROMODEL Marker log-likelihoods under a zero model.
%
%   [lp,p] = DETERMINELIKELIHOODFROMZEROMODEL(X,D,sD) computes, for each
% marker and frame, a log-likelihood under the zero model (naive Bayes),
% which assumes independent Gaussian distributions for each distance
% between markers. The value is a pseudo log-likelihood (the negative
% root of a squared Mahalanobis distance), averaged over the other
% markers. Errors if D or sD is not N x N or X is not N x 3 x M.
%
% Inputs:
%   X  - N x 3 x M marker positions (N markers sampled M times)
%   D  - N x N expected distances between the markers
%   sD - N x N standard deviations of the distances across time
%
% Outputs:
%   lp - N x M log-likelihood of each marker in each sample
%   p  - empty (not implemented)
%
% Toolbox Dependencies: None
%
% See also CREATEZEROMODEL, GETBESTRECONSFROMZEROMODEL.

[N,tres,M] = size(X);
if size(D,1) ~= N || ~issquare(D)
    error()
end
if size(sD,1) ~= N || ~issquare(sD)
    error()
end
if tres ~= 3
    error()
end

lp = nan(N,M);
%D=D+eye(size(D));
%sD=sD+eye(size(D));
for fr = 1:M %For each frame
    dist = computeDistanceMatrix(X(:,:,fr));
    %./(sqrt(2*pi)*sD(:)); %Fake log-likelihood: it is a mahalanobis
    %distance squared
    pp   = (-(dist(:)-D(:)).^2./(2*sD(:).^2));
    pp   = reshape(pp,N,N);
    lp(:,fr) = mean(-sqrt(-pp), 'omitnan');
end

p = [];

end

function bool = issquare(D)
%ISSQUARE True if the matrix has as many rows as columns.
%
% Inputs:
%   D - matrix
%
% Outputs:
%   bool - true if size(D,1) == size(D,2)
%
% Toolbox Dependencies: None

bool = size(D,1) == size(D,2);
end

