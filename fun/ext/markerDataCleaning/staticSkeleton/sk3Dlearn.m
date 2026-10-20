function [m,R] = sk3Dlearn(pos)
%SK3DLEARN Learn a naive-Bayes 3-D static skeleton model.
%
%   [m,R] = SK3DLEARN(pos) returns the model such that the pairwise
% component differences W*pos(:,:,i) ~ N(m,R), with the mean m and the
% per-marker variances R computed over the frames.
%
% Inputs:
%   pos - N markers x d coordinates x M frames positions
%
% Outputs:
%   m - N x N x d mean pairwise component differences
%   R - N x (N*d) variances of those differences (naive Bayes: no
%       covariance between differences)
%
% Toolbox Dependencies: None
%
% See also SK3DDETECT, SK3DENFORCE, SKDISTLEARN.

[N,d,M] = size(pos);
D = computeDiffMatrix(pos); %Will be NxdxNxM
D = permute(D,[1,3,2,4]); %NxNxdxM
m = mean(D, 4, 'omitnan');
R = nan(N,N*d); %Naive bayes
for mrkr = 1:N %For each marker, compute mean vector, and its cov
    R(mrkr,:) = var(reshape(D(mrkr,:,:,:),N*d,M), [], 2, ...
        'omitnan'); %Nx(Nd)x(Nd)
end

end
