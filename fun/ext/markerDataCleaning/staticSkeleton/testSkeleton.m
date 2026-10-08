%TESTSKELETON Try the 3-D static skeleton model on synthetic data.
%
%   Generates random marker data (18 markers, 3-D, 1000 frames), learns
%   the skeleton with SK3DLEARN, enforces it frame by frame with
%   SK3DENFORCE and plots the mean error.
%
% NOTE: stale script. W is never defined and SK3DENFORCE takes four
% arguments, so the enforce step errors.
%
% Toolbox Dependencies: None
%
% See also SK3DLEARN, SK3DENFORCE.

%% Load some data
pos = 10*randn(54,5)*randn(5,1000) + randn(54,1000);
pos = reshape(pos,18,3,1000);
[N,D,M] = size(pos);
%% Learn skeleton
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