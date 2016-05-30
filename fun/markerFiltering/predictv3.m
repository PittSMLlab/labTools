function [nextX,nextPrevX,fullAn,fullQn] = predictv3(Xhist,n,mode,tau)
%Xhist should be Nx6, where N is
%the number of samples. Xhist(1,:) is the first sample, Xhist(end,:) is the
%last sample in time.
%n is the prediction range in samples.
%tau is the decay rate for temporally discounted models (mode==3)
%lag is 1 or 0. With 0, the very first prediction has temporal discounting,
%with 1, only the second prediction has it.

N=size(Xhist,1);

if nargin<4 || isempty(tau)
    tau=20;
end

switch mode
    case 1 %Constant x, v=0
        A=[1 0; 1 0];
    case 2 %constant v
        A=[2 -1; 1 0];
    case 3 %temp-discounted v
        A=[1+exp(-1/tau) -exp(-1/tau); 2-exp(-1/tau) exp(-1/tau)-1];
end
An=A^n;
%Expanding A to consider 3 independent components per sample:
fullAn=zeros(6);
for j=1:3
    fullAn([j,j+3],[j,j+3])=An;
end

aux=fullAn*Xhist';

nextX=aux(1:3,:)';
nextPrevX=aux(4:6,:)'; 

%Variance of estimator:
Qn=eye(2) * min([1*n^3 n^2*10 n*150]);
aux1=nanmedian(nextX-nextPrevX,1).^2;
qxy=n*max([mean(aux1(1:2)).^2 1]);
qz=min([n 20]);
fullQn=diag([qxy qxy qz qxy qxy qz]);


