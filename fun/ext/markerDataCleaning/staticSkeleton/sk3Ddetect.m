function [markerLogL,totalLogL] = sk3Ddetect(data,m,R)
%SK3DDETECT Score markers against a 3-D static skeleton model.
%
%   [markerLogL,totalLogL] = SK3DDETECT(data,m,R) scores each marker in
% every frame by the squared deviation of its pairwise 3-D component
% differences from the model mean m, scaled by the (regularized) variance
% R. Markers that are missing (NaN) in a frame get a score of -10.
%
% Inputs:
%   data - N markers x 3 coordinates x M frames positions
%   m    - N x N x 3 mean pairwise component differences (from SK3DLEARN)
%   R    - N x (3N) variances of those differences (from SK3DLEARN)
%
% Outputs:
%   markerLogL - N x M per-marker score (median over its pairs)
%   totalLogL  - per-frame score (mean over all pairs)
%
% Toolbox Dependencies: None
%
% See also SK3DLEARN, SK3DENFORCE, SKDISTDETECT.

[N,d,M] = size(data);
D       = computeDiffMatrix(data); %Will be NxdxNxM
missing = squeeze(any(isnan(data),2));
clear data
D         = permute(D,[1,3,2,4]); %NxNxdxM
R         = reshape(R,N,N,d);
D         = D-m; %Subtracting mean
C         = R+1e3*max(abs(R(:)))*eye(N); % TODO: source?
auxScores = D.^2 ./C;



totalLogL = squeeze(mean(mean(mean(auxScores, 'omitnan'), 'omitnan'), ...
    'omitnan'));
%markerLogL=nan(N,M);
markerLogL = squeeze(median(reshape(auxScores,N,N*d,M), 2, 'omitnan'));
%markerLogL=squeeze(mean(reshape(auxScores,N,N*d,M),2));


markerLogL(missing) = -10; % TODO: source?

end

