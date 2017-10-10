function [D] = computeDiffMatrix(pos)
if numel(pos)==1
    N=pos;
    W=sparse(N^2,N);
    for i=1:N
        W(N*(i-1)+[1:i-1,i+1:N],i)=-1;
        for j=[1:i-1,i+1:N];
            W(N*(i-1)+j,j)=1;
        end
    end
    D=W;
else
[N,dim,M]=size(pos);
D=bsxfun(@minus,reshape(pos,[N,dim,1,M]),reshape(permute(pos,[2,1,3]),[1,dim,N,M]));
%Equivalent to: D=W*pos;
end

end

