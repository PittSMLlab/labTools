function D = computeDistanceMatrix(pos)
%Gets position data as N markers x 3D x M frames and for each frame
%computes all pairwise distances btw markers, returns NxNxM

E = computeDiffMatrix(pos);
D = sqrt(squeeze(sum(E.^2,2)));
end

