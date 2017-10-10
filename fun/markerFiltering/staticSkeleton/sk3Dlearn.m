function [m,R] = sk3Dlearn(pos)
%Returns model such that W*pos(:,:,i) ~ N(m,R)
[N,d,M]=size(pos);
[D] = computeDiffMatrix(pos); %Will be NxdxNxM
D=permute(D,[1,3,2,4]); %NxNxdxM









m=nanmean(D,4);
R=nan(N,N*d); %Naive bayes
for i=1:N %For each marker, compute mean vector, and its cov  
    R(i,:)=nanvar(reshape(D(i,:,:,:),N*d,M),[],2); %Nx(Nd)x(Nd)
end

end

