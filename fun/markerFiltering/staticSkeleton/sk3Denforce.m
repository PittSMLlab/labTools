function [xMLE] = sk3Denforce(x,P,s,R)
%Given a prior estimate x with uncertainty P (normal dist) of some variable x, and the
%relative position model given by s, R [W*x~N(s,diag(R))], computes the optimal
%(bayesian) estimate of x
%If elements of x are NaN, they are considered 'missing' and assigned an
%arbitrary value with (numerically) infinite uncertainty
[N,D]=size(x);
W = computeDiffMatrix(N);
Z=sparse(zeros(size(W)));

%Deal with NaNs in data:
idx=isnan(x(:));
x(idx)=0;
aux=zeros(N*D,1);
aux(idx)=1;
P=P+1e15*max(P(:))*diag(aux);

[xMLE,PMLE]=updateKF([W Z Z;Z W Z; Z Z W],diag(R(:)),x(:),P,s(:),zeros(size(W,1)*D,1)); %Optimal bayesian update
end

