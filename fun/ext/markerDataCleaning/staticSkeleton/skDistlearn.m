function [m,R] = skDistlearn(pos)
%Returns model such that W*d(pos(:,:,i)) ~ N(m,R)
%W is a selection matrix to reduce complexity
[N,d,M] = size(pos);
D = computeDistanceMatrix(pos); %NxNxM
m = mean(D, 3, 'omitnan');
R = nan(N,N); %Naive bayes
for mrkr = 1:N %For each marker, compute mean vector, and its cov
    R(mrkr,:) = var(reshape(D(mrkr,:,:),N,M), [], 2, 'omitnan'); %Nx(N)x(Nd)
end
end
