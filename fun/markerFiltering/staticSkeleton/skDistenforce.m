function [xMLE] = skDistlearnenforce(x,P,s,R)
%Given a prior estimate x with uncertainty P (normal dist) of some variable x, and the
%relative position model given by s, R [W*x~N(s,diag(R))], computes the optimal
%(bayesian) estimate of x
%If elements of x are NaN, they are considered 'missing' and assigned an
%arbitrary value with (numerically) infinite uncertainty
[N,D]=size(x);

%Deal with NaNs in data:
idx=isnan(x(:));
x(idx)=0;
aux=zeros(N*D,1);
aux(idx)=1;
P=P+1e15*max(P(:))*diag(aux);

%Iterate: linearize, find optimal solution
endFlag=false;
changeTh=1e-3;
while ~endFlag
  W=; %Linearized distance constraints
  [xMLE,PMLE]=updateKF(W,diag(R(:)),x(:),P,s(:),zeros(size(W,1)*D,1)); %Optimal bayesian update
  change=sqrt(sum((xMLE-lastXMLE(:)).^2));
  endFlag=change<changeTh;
end
end
