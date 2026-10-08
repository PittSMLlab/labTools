function [lp,p] = determineLikelihoodFromZeroModel(X,D,sD)
%Computes a likelihood for a set of marker positions given a 'zero-model'
%(naive bayes) which assumes independent gaussian distributions for each
%distance between models.
%------
%INPUTS:
%X is a Nx3xM matrix of N marker positions in 3D, samples M times.
%D is a NxN matrix containing the expected distances between the N markers
%sD is a NxN matrix containing the standard deviation of the distances
%across time
%------
%OUTPUT:
%p is a NxM matrix containing log-likelihoods for each of the N markers in
%each
%of the M samples

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
bool = size(D,1) == size(D,2);
end

