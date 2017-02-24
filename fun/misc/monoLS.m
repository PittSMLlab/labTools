function [z] = monoLS(y,p,monotonicDerivativeFlag,regularizeFlag)
%This function does an LS minimization of z-y, subject to z being monotonic
%(or constant?)
y=y(:);
if nargin<2 || isempty(p)
    p=2;
end
if nargin<3 || isempty(monotonicDerivativeFlag)
    monotonicDerivativeFlag=0;
end
if nargin<4 || isempty(regularizeFlag) || monotonicDerivativeFlag==0 
    %No regularization allowed if only one derivative is being forced,
    %otherwise we lose monotonicity
    regularizeFlag=0;
end

%s=sign(median(diff(y)));
pp=polyfit([1:numel(y)]',y,1);
s=sign(pp(1));

%To make it simple, we flip the data so that it is always increasing &
%positive
if s>0
    y=-y; %Data is now decreasing, f'<0
end
a=min(y);
y=y-a; %Data is now f>0 & f'<0
y=flipud(y); %Data is now f>0, f'>0, as I inverted the 'x' axis

%Optimize:
%By induction!
if monotonicDerivativeFlag<numel(y)
    A=tril(ones(numel(y)));
    for i=1:monotonicDerivativeFlag
        A(:,i+1:end)=cumsum(A(:,i+1:end),2,'reverse');
    end
else
    error('Cannot force the sign of so many derivatives!')
end

if regularizeFlag~=0
   A(:,end-regularizeFlag+1:end)=0; 
   %Forcing the value of the m-th derivative (m=monotonicDerivativeFlag+1), 
   %which is the last constrained one, to be exactly 0 for the last
   %m=regularizeFlag samples.
   %This avoids over-fitting to the first few datapoints (especially the
   %1st)
   %It is equivalent to reducing the size of the vector w() to be estimated
   %If m is large enough, then the regression is somewhat
   %self-regularizing, as the constraints are so many that overfitting is
   %unlikely. It may still be relevant if we assume some salt&pepper or
   %outlier noise affecting the very first few samples.
end

%Solver 1: efficient but simple, does not converge for more than 3 derivatives
%opts=optimset('Display','off');
%w=lsqnonneg(A,y,opts);

%Alternative solver: (this would allow us to pose the problem in different,
%perhaps better conditioned, ways)
w0=zeros(size(A,1),1);
opts=optimoptions('quadprog','Display','off');
w=quadprog(A'*A,-y'*A,[],[],[],[],zeros(size(w0)),[],w0,opts);
z=A*w;

%Invert the flipping and positivization
z=flipud(z);
z=z+a;
if s>0
    z=-z;
end

end