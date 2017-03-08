function [z] = monoLS(y,p,monotonicDerivativeFlag,regularizeFlag)
%This function does an LS minimization of z-y, subject to z being monotonic
%(or constant?)
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
end

if numel(y)~=length(y) %More than 1 vector (matrix input, acting along columns)
    z=nan(size(y));
    for i=1:size(y,2)
        z(:,i)=monoLS(y(:,i),p,monotonicDerivativeFlag,regularizeFlag);
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
        A=tril(ones(numel(y)));
        %First guess (init) for optimization target:
        w0=zeros(size(A,2),1);
        pp=polyfit([1:numel(y)]',y,1); %Fit a line to use as initial estimate: a line is always admissible!
        w0(1)=pp(2);
        w0(2:end)=pp(1);
        for i=1:monotonicDerivativeFlag
            A(:,i+1:end)=cumsum(A(:,i+1:end),2,'reverse');
            w0(3:end)=0; %If working with 2nd or higher derivative, those derivatives are null for a line
        end
    else
        error('Cannot force the sign of so many derivatives!')
    end

    if regularizeFlag~=0 %Forcing the value of the m-th derivative (m=monotonicDerivativeFlag+1), 
       %which is the last constrained one, to be exactly 0 for the last n=regularizeFlag samples.
       %This avoids over-fitting to the first few datapoints (especially the
       %1st). %It is equivalent to reducing the size of the vector w() to be estimated.
       A(:,end-regularizeFlag+1:end)=[]; 
       w0(end-regularizeFlag+1:end)=[];
    end

    if p==2
        %Solver 1: efficient but simple, does not converge for more than 3 derivatives
        %opts=optimset('Display','off');
        %w=lsqnonneg(A,y,opts);

        %Alternative solver: (this would allow us to pose the problem in different,
        %perhaps better conditioned, ways)
        opts=optimoptions('quadprog','Display','off','Algorithm','trust-region-reflective');
        w=quadprog(A'*A,-y'*A,[],[],[],[],zeros(size(w0)),[],w0,opts);
        zz=A*w;
    else %Generic solver for other norms, which result in non-quadratic programs (solver is slower, but somewhat better)
        opts=optimoptions('fmincon','Display','off','SpecifyObjectiveGradient',true,'Algorithm','trust-region-reflective');
        w1=fmincon(@(x) cost(y,A,x,p),w0,[],[],[],[],zeros(size(w0)),[],[],opts); 
        zz=A*w1;
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
    g=p*(A*w-y)'.^(p-1) *A;
    h=p*(p-1)*A'*A;
end