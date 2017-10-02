function [D] = computeDiffMatrix(pos)
[N,dim,M]=size(pos);
D=bsxfun(@minus,reshape(pos,[N,dim,1,M]),reshape(permute(pos,[2,1,3]),[1,dim,N,M]));
end

