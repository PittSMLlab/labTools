function [xMLE] = skDistlearnenforce(x,P,s,R)
%Given a prior estimate x with uncertainty P (normal dist) of some variable x, and the
%relative position model given by s, R [W*x~N(s,diag(R))], computes the optimal
%(bayesian) estimate of x
%If elements of x are NaN, they are considered 'missing' and assigned an
%arbitrary value with (numerically) infinite uncertainty
[N,d]=size(x);

%Deal with NaNs in data:
idx=isnan(x(:));
x(idx)=0;
aux=zeros(N*d,1);
aux(idx)=1;
P=P+1e15*max(P(:))*diag(aux);

%Iterate: linearize, find optimal solution
endFlag=false;
changeTh=1e-3;
xMLE=x(:); %Nd x 1
%Reshaping parameters for updateKF:
y=zeros(N^2*d,1);s=s(:);R=diag(R(:));x=x(:);
xMLE=x; %Init guess
while ~endFlag
  %Linearize distance constraints:
  [off,W]=linearizeDist(reshape(xMLE,N,d));
  %Optimal bayesian solution around linearized point:
  [xMLE,PMLE]=updateKF(W,R,x,P,s-off(:),y);
  change=sqrt(sum((xMLE-lastXMLE(:)).^2));
  endFlag=change<changeTh;
end
end

function [Do,W]=linearizeDist(xo)
  %Computes an approximation of the function
  %D=computedDistanceMatrix(x) around x=xo
  %As: D(:) ~ Do(:) + W*x(:)
  %Assumed xo is Nxd
  [N,d]=size(x);
  D=computedDistanceMatrix(xo);
  G1=reshape(x,N,1,d)./D;
  G2=reshape(x,1,N,d)./D;
  W1=zeros(N,N,N,d);
  W2=zeros(N,N,N,d);
  for i=1:N
    W1(i,:,i,:)=G1(:,i,:);
    W2(:,i,i,:)=G2(:,i,:);
  end
  %Need to reshape G/pad with 0's, so W is NxNxNd
  W=W1-W2; %NxNxNxd
  W=reshape(W,N^2,N*d);
  Do=D-W*x(:); %N^2x1
end

function testLinearization(xo)
D=computedDistanceMatrix(xo);
[Do,W]=linearizeDist(xo);
e=1e-3;
p=e*randn(numel(xo),1);
x=xo(:)+p;
D1=computeDistanceMatrix(x);
D1app=Do(:)+W*x;

%Check: D1 ~ D1app
norm(D1(:)-D1app) %Should be very small
end
