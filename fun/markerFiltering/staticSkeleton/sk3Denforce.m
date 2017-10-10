function [xMLE] = sk3Denforce(x,P,s,R)
%Given a prior estimate x with uncertainty P (normal dist) of some variable x, and the
%relative position model given by s, R [W*x~N(s,diag(R))], computes the optimal
%(bayesian) estimate of x
[N,D]=size(x);
W=sparse(N^2,N);
for i=1:N
    W((N-1)*i+[0:N-1],i)=1;
    for j=1:N
        W((N-1)*i+j,j)=-1;
    end
end
Z=sparse(zeros(size(W)));
[xMLE,PMLE]=updateKF([W Z Z;Z W Z; Z Z W],diag(R(:)),x(:),P,s(:),zeros(size(W,1)*D,1)); %Optimal bayesian update
end

