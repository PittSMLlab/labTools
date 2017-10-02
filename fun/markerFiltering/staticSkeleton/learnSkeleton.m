function [m,R,W] = learnSkeleton(pos)
%Returns model such that W*pos(:,:,i) ~ N(m,R)
[N,d,M]=size(pos);
[D] = computeDiffMatrix(pos);
m=nanmean(D,4);
m=reshape(permute(m,[1,3,2]),N^2,d);

W1=zeros(N,N,N);

for i=1:N
    for j=[1:i-1,i+1:N]
        W1(i,j,i)=1;
        W1(i,j,j)=-1;
    end
end
W=sparse(reshape(W1,N^2,N));
clear W1

aux=nan(size(W,1),d,M);



for i=1:M
aux(:,:,i)=W*pos(:,:,i);
end
R=cov(reshape(aux,d*N^2,M)');
R=R+1e3*max(R(:))*eye(size(R));

Z=sparse(size(W,1),size(W,2));
W=[W Z Z; Z W Z; Z Z W];
%Discard irrelevant entries: to reduce the computational complexity
%TODO


end

