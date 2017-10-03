%testDistSkeleton
%Idea: same as testSkeleton, use optimal bayesian updates under a normal
%noise model. But in this case, operate in distance space: this is, have a
%model of distances between markers.

%% Load some data
pos=10*randn(54,5)*randn(5,1000) + randn(54,1000);
pos=reshape(pos,18,3,1000);
[N,D,M]=size(pos);
%% LEarn skeleton
[m,R,W] = learnDistSkeleton(pos);

%% Enforce it
P=eye(N*D);
xMLE=nan(N*D,M);
for i=1:M
    i
    [xMLE(:,i)] = enforceDistSkeleton(reshape(pos(:,:,i),N*D,1),P,m(:),R,W);
end

%% Compare


xMLE=reshape(xMLE,N,D,M);

err=xMLE-pos;
imagesc(mean(err,3))