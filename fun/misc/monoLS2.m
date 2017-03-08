function [z] = monoLS2(y,p,monotonicDerivativeFlag,regularizeFlag)
%Same as monoLS, but framing the problem differently, to avoid
%ill-conditioned situations
if nargin<2 || isempty(p)
    p=2;
end
if nargin<3 || isempty(monotonicDerivativeFlag)
    monotonicDerivativeFlag=0;
end
if nargin<4 || isempty(regularizeFlag) || monotonicDerivativeFlag==0 
    %No regularization allowed if only one derivative is being forced,
    %otherwise we may lose monotonicity
    regularizeFlag=0;
else
    regularizeFlag=0;
    warning('monoLS2 doesn''t work well with regularization, ignoring.')
end

if numel(y)~=length(y) %More than 1 vector (matrix input, acting along columns)
    z=nan(size(y));
    for i=1:size(y,2)
        z(:,i)=monoLS2(y(:,i),p,monotonicDerivativeFlag,regularizeFlag);
    end
    
else %Vector input-data
    z=nan(size(y));    
    y=y(:); %Column vector
    idx=isnan(y);
    if ~all(idx)
    y=y(~idx);

    %Determine if data is increasing or decreasing:
    pp=polyfit([1:numel(y)]',y,1);
    s=sign(pp(1));

    %To make it simple, we flip the data so that it is always increasing & positive
    if s>0
        y=-y; %Data is now decreasing, f'<0
    end
    a=min(y)-1;
    y=y-a; %Data is now f>0 & f'<0
    y=flipud(y); %Data is now f>0, f'>0, as I inverted the 'x' axis

    %Optimization
    %First, construct matrix that computes data from optimized variables: (By induction!)
    if monotonicDerivativeFlag<numel(y)
        A=eye(numel(y));
        B=diag(ones(size(y)))-diag(ones(length(y)-1,1),1); %This computes 1st derivative
        B(end,:)=[];
        b=zeros(size(B,1),1); %This enforces positivity of 1st der
        for i=1:monotonicDerivativeFlag
            Baux=B(end-numel(y)+1+i:end-1,:)-B(end-numel(y)+i+2:end,:); %Computes succesive derivatives
            baux=1e-12*ones(size(Baux,1),1);
            B=[B;-Baux];
            b=[b;baux];
        end
    else
        error('Cannot force the sign of so many derivatives!')
    end
    pp=polyfit([0:numel(y)-1]',y,1); %Fit a line to use as initial estimate: a line is always admissible!
    w0=pp(2)+pp(1)*[0:numel(y)-1]';
    Aeq=[];
    beq=[];
    if regularizeFlag~=0 %Forcing the value of the m-th derivative (m=monotonicDerivativeFlag+1), 
       %which is the last constrained one, to be exactly 0 for the last n=regularizeFlag samples.
       %This avoids over-fitting to the first few datapoints (especially the
       %1st). %It is equivalent to reducing the size of the vector w() to be estimated.
       Aeq=zeros(regularizeFlag,length(w0));
       Aeq(:,end-regularizeFlag+1:end)=eye(regularizeFlag); 
       beq=zeros(regularizeFlag,1);
    end

    opts=optimoptions('fmincon','Display','off','SpecifyObjectiveGradient',true);
    w1=fmincon(@(x) cost(y,A,x,p),w0,B,b,Aeq,beq,zeros(size(w0)),[],[],opts); 
    zz=A*w1;
    
    
    %Dealing with some ill-conditioned cases, in which a line is better
    %than the solution found:
    if norm(zz-y,p)>norm(A*w0-y,p)
       zz=A*w0;
    end

    %Invert the flipping and positivization
    zz=flipud(zz);
    zz=zz+a;
    if s>0
        zz=-zz;
    end
    
    %Reconstructing data by adding the NaN values that were present
    z(~idx)=zz;
    else
        z=y; %All elements are NaN
    end
end
end

function [f,g,h]=cost(y,A,w,p)
    f=norm(y-A*w,p)^p;
    g=p*sign(A*w-y)'.*abs(A*w-y)'.^(p-1) *A;
    h=p*(p-1)*A'*A;
end