function [m,R] = skDistlearn(pos)
%Returns model such that W*d(pos(:,:,i)) ~ N(m,R)
%W is a selection matrix to reduce complexity
[N,d,M]=size(pos);
[D] = computeDistanceMatrix(pos); %NxNxM
m=nanmean(D,3);
R=nan(N,N); %Naive bayes
for i=1:N %For each marker, compute mean vector, and its cov
    R(i,:)=nanvar(reshape(D(i,:,:),N,M),[],2); %Nx(N)x(Nd)
end
end
