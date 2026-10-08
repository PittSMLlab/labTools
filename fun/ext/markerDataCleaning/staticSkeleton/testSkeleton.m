%testSkeleton

%% Load some data
pos = 10*randn(54,5)*randn(5,1000) + randn(54,1000);
pos = reshape(pos,18,3,1000);
[N,D,M] = size(pos);
%% LEarn skeleton
[m,R] = sk3Dlearn(pos);

%% Enforce it
P    = eye(N*D);
xMLE = nan(N*D,M);
for fr = 1:M
    fr
    xMLE(:,fr) = sk3Denforce(reshape(pos(:,:,fr),N*D,1),P,m(:),R,W);
end

%% Compare


xMLE = reshape(xMLE,N,D,M);

err = xMLE-pos;
imagesc(mean(err,3))