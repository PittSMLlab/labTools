function [xMLE] = enforceSkeleton(x,P,s,R,W)
%Given a prior estimate x with uncertainty P (normal dist) of some variable x, and the
%relative position model given by s, R [W*x~N(s,R)], computes the optimal
%(bayesian) estimate of x

[N,D]=size(x);
[xMLE,PMLE]=updateKF(W,R,x,P,s,zeros(size(W,1),1)); %Optimal bayesian update
end

