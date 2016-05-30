function [nextX,nextPrevX,An,Q] = predictv2(Xhist,n,mode,tau,lag)
%Xhist should be NxM, where M is number of variables to predict, and N is
%the number of samples. Xhist(1,:) is the first sample, Xhist(end,:) is the
%last sample in time.
%n is the prediction range in samples.
%tau is the decay rate for temporally discounted models (mode==3)
%lag is 1 or 0. With 0, the very first prediction has temporal discounting,
%with 1, only the second prediction has it.
s=size(Xhist);

if nargin<4 || isempty(tau)
    tau=20;
end
if nargin<5 || isempty(lag)
    lag=1;
end

nextX=nan(s);
nextPrevX=nan(s);
Xhist=Xhist(:,:);
for i=1:size(Xhist,2)
    X=Xhist(:,i);
    prevX=cat(1,0,X(1:end-1));
    switch mode
        case 1 %Constant x, v=0
            A=[1 0; 1 0];
        case 2 %constant v
            A=[2 -1; 1 0];
        case 3 %temp-discounted v
            A=[1+exp(-1/tau) -exp(-1/tau); 2-exp(-1/tau) exp(-1/tau)-1];
    end
    An=A^n;
    aux=An*[X(:)';prevX(:)'];

    nextX(:,i)=aux(1,:);
    nextPrevX(:,i)=aux(2,:); 

    %Variance of estimator:
    Q=eye(2) * min([n^2*400 n*900]);
end

