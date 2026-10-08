function [m,R] = skDistlearn(pos)
%SKDISTLEARN Learn a naive-Bayes pairwise-distance skeleton model.
%
%   [m,R] = SKDISTLEARN(pos) returns the model such that the pairwise
% distances W*d(pos(:,:,i)) ~ N(m,R), with the mean m and the variances R
% computed over the frames. W is a selection matrix that reduces the
% complexity.
%
% Inputs:
%   pos - N markers x d coordinates x M frames positions
%
% Outputs:
%   m - N x N mean pairwise distances
%   R - N x N variances of the pairwise distances (naive Bayes)
%
% Toolbox Dependencies: None
%
% See also SKDISTDETECT, SKDISTENFORCE, SK3DLEARN.

[N,d,M] = size(pos);
D = computeDistanceMatrix(pos); %NxNxM
m = mean(D, 3, 'omitnan');
R = nan(N,N); %Naive bayes
for mrkr = 1:N %For each marker, compute mean vector, and its cov
    R(mrkr,:) = var(reshape(D(mrkr,:,:),N,M), [], 2, 'omitnan'); %Nx(N)x(Nd)
end
end
