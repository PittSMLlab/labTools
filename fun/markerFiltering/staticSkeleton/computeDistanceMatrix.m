function [D] = computeDistanceMatrix(pos)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

if size(pos,3)==1
    [N,dim]=size(pos);
    %D=squareform(pdist(pos,'euclidean'));
    D=sqrt(squeeze(sum(bsxfun(@minus,pos,reshape(pos',[1,dim,N])).^2,2)));
else
    [N,dim,M]=size(pos);
%     D=nan(N,N,M);
%     for i=1:M
%         D(:,:,i)=computeDistanceMatrix(pos(:,:,i));
%     end 
    [E] = computeDiffMatrix(pos);
    D=sqrt(squeeze(sum(E.^2,2)));
end
end

