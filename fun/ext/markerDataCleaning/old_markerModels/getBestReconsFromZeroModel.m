function altPos = getBestReconsFromZeroModel(measuredPos,D,sD,meanPos, ...
    markersForReconstruction,biasPos)
%GETBESTRECONSFROMZEROMODEL Reconstruct marker positions with a zero model.
%
%   altPos = GETBESTRECONSFROMZEROMODEL(measuredPos,D,sD,meanPos)
% re-estimates the position of every marker from its distances to the
% other markers, weighted by the inverse of the zero-model standard
% deviations. Markers are processed from the least to the most likely one;
% each reconstructed position replaces the measurement as a reference for
% the next marker.
%
%   GETBESTRECONSFROMZEROMODEL(...,markersForReconstruction,biasPos)
% reconstructs only the listed markers (default: all) and adds biasPos to
% the result (default: zeros).
%
% NOTE: calls GETROTATIONANDTRANSLATION and GETPOSITIONFROMDISTANCES, which
% are not in the repository.
%
% Inputs:
%   measuredPos              - N x 3 measured marker positions
%   D                        - N x N expected distances between markers
%   sD                       - N x N standard deviations of the distances
%   meanPos                  - N x 3 reference (mean) marker positions
%   markersForReconstruction - (optional) indices of markers to
%                              reconstruct (default: all)
%   biasPos                  - (optional) N x 3 bias added to the result
%                              (default: zeros)
%
% Outputs:
%   altPos - N x 3 reconstructed marker positions
%
% Toolbox Dependencies: None
%
% See also CREATEZEROMODEL, DETERMINELIKELIHOODFROMZEROMODEL.

minRefMarkers = 4; % keep at least 4 reference markers
X2 = measuredPos;
[~,~,x0] = getRotationAndTranslation(meanPos(1:size(measuredPos,1),:), ...
    measuredPos);

%If marker list not given, reconstructing everything
if nargin < 5 || isempty(markersForReconstruction)
    markersForReconstruction = 1:size(measuredPos,1);
end
X2alt = X2;
if nargin < 6 || isempty(biasPos)
    biasPos = zeros(size(measuredPos));
end

measuredLike = determineLikelihoodFromZeroModel(X2alt,D,sD);
measuredLike(isnan(measuredLike)) = -1e3; % TODO: source?
%Sorting likelihoods of measuredMarkers that need to be reconstructed
[~,markerOrder] = sort(measuredLike(markersForReconstruction),1,'ascend');
lp = determineLikelihoodFromZeroModel(measuredPos,D,sD);

kP     = X2;
kD     = D(:,markersForReconstruction);
sD2    = sD+diag(nan*diag(sD));
sD     = sqrt(sD.^2+0); %Adding some uncertainty for measurement errors (?)
selfSD = min(sD2,[],1).*exp((lp+1));
%Weight for same-marker will be inversely related to likelihood of
%measurement. Likelihood ~-1 weights measurement as the best reference
%marker, -2 weights it 1/e, -3 weights it 1/e^2
selfSD = 1e3*ones(size(selfSD)) % TODO: source? (no semicolon: prints)
kSD    = sD+diag(selfSD);
kSD    = kSD(:,markersForReconstruction);

for ii = 1:length(markerOrder)
    %Marker to reconstruct
    marker = markersForReconstruction(markerOrder(ii));

    w  = 1./kSD(:,marker);
    w  = w/sum(w, 'omitnan');
    wS = sort(w,'descend');

    %Eliminating missing markers & very-low weights (preserving at least 4
    %reference markers)
    idx = any(isnan(kP),2) | isnan(kD(:,marker)) | isnan(w) | ...
        (w < (1/length(w)) & w < wS(minRefMarkers));
    X2alt(marker,:) = getPositionFromDistances(kP(~idx,:), ...
        kD(~idx,marker),w(~idx),x0(marker,:)); %Estimated reconstruction
    kP = X2alt; %Update
end
altPos = X2alt+biasPos;

end

