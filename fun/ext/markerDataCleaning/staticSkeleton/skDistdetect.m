function [markerLogL,totalLogL] = skDistdetect(data,m,R)
%SKDISTDETECT Score markers against a pairwise-distance skeleton model.
%
%   [markerLogL,totalLogL] = SKDISTDETECT(data,m,R) scores each marker in
% every frame by the squared deviation of its pairwise distances from the
% model mean m, scaled by the (regularized) variance R. Markers that are
% missing (NaN) in a frame get a score of -10.
%
% Inputs:
%   data - N markers x d coordinates x M frames positions
%   m    - N x N mean pairwise distances (from SKDISTLEARN)
%   R    - N x N variances of those distances (from SKDISTLEARN)
%
% Outputs:
%   markerLogL - N x M per-marker score (median over its pairs)
%   totalLogL  - per-frame score (mean over all pairs)
%
% Toolbox Dependencies: None
%
% See also SKDISTLEARN, SKDISTENFORCE, SK3DDETECT.

[N,d,M] = size(data);
D       = computeDistanceMatrix(data); %Will be NxNxM
missing = squeeze(any(isnan(data),2));
clear data
D         = D-m; %Subtracting mean
C         = R+1e3*max(abs(R(:)))*eye(N); % TODO: source?
auxScores = D.^2 ./C;
totalLogL = squeeze(mean(mean(mean(auxScores, 'omitnan'), 'omitnan'), ...
    'omitnan'));
%markerLogL=nan(N,M);
markerLogL = squeeze(median(reshape(auxScores,N,N,M), 2, 'omitnan'));
%markerLogL=squeeze(mean(reshape(auxScores,N,N*d,M),2));
markerLogL(missing) = -10; % TODO: source?

end
