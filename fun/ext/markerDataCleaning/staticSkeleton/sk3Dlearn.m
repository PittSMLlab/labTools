function [m,R] = sk3Dlearn(pos)
%Returns model such that W*pos(:,:,i) ~ N(m,R)
[N,d,M] = size(pos);
D = computeDiffMatrix(pos); %Will be NxdxNxM
D = permute(D,[1,3,2,4]); %NxNxdxM
m = mean(D, 4, 'omitnan');
R = nan(N,N*d); %Naive bayes
for mrkr = 1:N %For each marker, compute mean vector, and its cov
    R(mrkr,:) = var(reshape(D(mrkr,:,:,:),N*d,M), [], 2, ...
        'omitnan'); %Nx(Nd)x(Nd)
end

end
