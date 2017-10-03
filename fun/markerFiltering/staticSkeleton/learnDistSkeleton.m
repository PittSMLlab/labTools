function [m,R,W] = learnDistSkeleton(pos)
%Returns model such that W*d(pos(:,:,i)) ~ N(m,R)
%W is a selection matrix to reduce complexity
[N,d,M]=size(pos);
[D] = computeDistanceMatrix(pos);
D=reshape(D,N^2,M);

m=nanmean(D,2);

R=nancov((D-m)');
R=R+1e3*max(R(:))*eye(size(R));

%Select relevant entries: TODO
W=eye(length(m));

end

