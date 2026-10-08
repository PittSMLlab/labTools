function D = computeDiffMatrix(pos)
%Gets position data as N markers x 3D x M frames and for each frame
%computes all pairwise differences btw marker components, returns Nx3xNxM
[N,dim,M] = size(pos);
D = bsxfun(@minus,reshape(pos,[N,dim,1,M]), ...
    reshape(permute(pos,[2,1,3]),[1,dim,N,M]));
end

