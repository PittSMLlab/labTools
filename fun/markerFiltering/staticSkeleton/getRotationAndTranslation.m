function [R,t,X1proy] = getRotationAndTranslation(X1,X2)
%UNTITLED Summary of this function goes here
%   Returns R and t such that X2~X1*R + t in the LS sense
[N,M]=size(X1);


%My first attempt: works well, but R is an arbitrary matrix, containing
%rotations, reflections and shrinking of axes.
% XX1=[X1 ones(N,1)];
% XX2=[X2 ones(N,1)];
% 
% MR=XX1\XX2;
% 
% R=MR(1:3,1:3);
% t=MR(4,1:3);



%Alt: here R will truly be rotation+reflection matrix
%Algorithm taken from: http://nghiaho.com/?page_id=671
%Which seems to take from Least-Squares Fitting of Two 3-D Point Sets by
%Arun et al. 1987
%Which apparently independently proposed what Kabsch 1976 "A solution for
%the best rotation to relate two sets of vectors" had done
idx=any(isnan(X1),2) | any(isnan(X2),2);
X1a=X1(~idx,:);
X2a=X2(~idx,:);
H=bsxfun(@minus,X1a,mean(X1a))'*bsxfun(@minus,X2a,mean(X2a));
[s,v,d]=svd(H);

R=d*s';
if sign(det(R))<0
    C=eye(3);
    C(3,3)=-1;
    R=d*C*s';
end
R=R';
t=mean(X2a)-mean(X1a)*R;

X1proy=X1*R+t;

end

