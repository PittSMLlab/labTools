classdef FactorizedMatrix
    %FactorizedMatrix Represents the factorization of a matrix H (MxN) as: H_ij=
    %\sum_k u_ki v_kj, where the index k is in [1:p], with p<M and p<N.
    %Factorization can only be exact if rank(H)<=p.
    %Notice that both vector sets u_ki and v_kj are indexed such that the
    %first dimension/index corresponds to the reduced dimension and the
    %second one to the represented dimension. u_ki is stores as dim1Vectors
    %and v_kj is stores as dim2Vectors. The factorized matrix can be
    %reconstructed
    
    %Technically, this is programmed in a way that it also supports tensor
    %(dim>2) factorizations of the form: H_ijl = \sum_k u_ik v_kjl, where H
    %is of dim A, u are column vectors, and v are A-1 dimension tensors
    
    %In the future factorization of 3 or more elements such as: H_ijl =
    %\sum_k u_ik v_jk w_lk will be supported, by allowing dim2Vectors to be
    %themselves a factorizedMatrix (CAN I DO THIS??)
    
    
    properties
        %originalMatrix=zeros(3);
        dim1Vectors=zeros(3,1);
        dim2Vectors=zeros(1,3);
        name='Unnamed';
        factorizationMethod='Unknown';
    end
    properties(Dependent=true)
       originalDimension %This is the lesser of M and N
       matrixSize %This is size(originalMatrix)
       reducedDimension %this is p
       factorizedMatrix %Product of Dim1Vectors and Dim2Vectors
       %errorMatrix %Difference between original and factorized
       paramCount %Number of parameters in the factorization
    end
    
    methods
        %Constructor
        function this=FactorizedMatrix(originalSize,dim1vectors,dim2vectors,factMethod,name) %Last two are optional
            if nargin<3
                ME=MException('FactorizedMatrix:ConstructorNotEnoughArgs','Not enough arguments');
                throw(ME)
            end
            if numel(originalSize)~=prod(size(originalSize))
                ME=MException('FactorizedMatrix:ConstructorBadSizeArgument','The originalSize argument has to be a vector containing the size of the full matrix.');
                throw(ME)
            end
            %this.originalMatrix=original; %Should not allow matrices that have singleton dimensions in the middle (i.e., not the first nor the last dimension), since it gives problems when checking for size and/or reconstructing the matrix.
            %Check consistency of given arguments & assign
            if size(dim1vectors(:,:),1)==size(dim2vectors(:,:),1) %Given in the expected orientation
                this.dim1Vectors=dim1vectors;
                this.dim2Vectors=dim2vectors;
            elseif size(dim1vectors,2)==size(dim2vectors(:,:),1) %Given transposed, which implies dim1Vectors is a 2D matrix
                this.dim1Vectors=dim1vectors';
                this.dim2Vectors=dim2vectors;
            else %Inconsistent sizes
                ME=MException('FactorizedMatrix:ConstructorInconsistentFactors','The sizes of the factors are inconsistent.');
                throw(ME);
            end
            
            %Check if there is actually dimension reduction
            if (numel(this.dim1Vectors)+numel(this.dim2Vectors)) >= prod(originalSize)
                warning('The factorized matrix is not reduced from its full form (factors DoF > matrix DoF).')
            end
            
            %Check consistency with originalMatrix size
            size1=size(this.dim1Vectors);
            size2=size(this.dim2Vectors);
            auxSize=[size1(2:end) size2(2:end)];
            try
            if ~isempty(originalSize) && prod(auxSize)~=prod(originalSize)
                ME=MException('FactorizedMatrix:ConstructorInconsistentMatrix','The sizes of the factors and the provided original matrix are inconsistent.');
                throw(ME);
            end
            catch
                keyboard
            end
            
            if nargin>3 && isa(factMethod,'char')
                this.factorizationMethod=factMethod;
            else
                disp('FactorizedMatrix Constructor: factorization method not given or is not a string. Ignoring.')
            end
            if nargin>4 && isa(name,'char')
                this.name=name;
            else
                disp('FactorizedMatrix Constructor: name not given or is not a string. Ignoring.') 
            end
                
        end
        
        %Getters for dependent
        function origDim=get.originalDimension(this)
            origDim=min([size(this.dim1Vectors(:,:),2),size(this.dim2Vectors(:,:),2)]);
        end
        function matrixSize=get.matrixSize(this)
            %matrixSize=size(this.originalMatrix); %Old way
            s1=size(this.dim1Vectors);
            s2=size(this.dim2Vectors);
            matrixSize=[s1(2:end) s2(2:end)];
        end
        function reducedDim=get.reducedDimension(this)
            reducedDim=size(this.dim2Vectors,1);
        end
        function factMat=get.factorizedMatrix(this)
           factMat=this.dim1Vectors(:,:)'*this.dim2Vectors(:,:); 
           factMat=reshape(factMat,this.matrixSize);
        end
        
        function paramCount=get.paramCount(this)
           paramCount=numel(this.dim1Vectors)+numel(this.dim2Vectors); 
        end
        
        %Other:
        function errorMat=getErrorMatrix(this,originalMatrix)
            %error('FactorizedMatrix:errorMatrix','This is no longer a supported property of FactorizedMatrix')
            errorMat=originalMatrix-this.factorizedMatrix;
        end
        
        function errorMat=errorMatrix(this,originalMatrix)
            warning('FactorizedMatrix:errorMatrix','This method is deprecated, use getErrorMatrix instead.')
            errorMat=this.getErrorMatrix(originalMatrix);
        end
        
        function errNorm=errorNorm(this,originalMatrix,method)
            if nargin<2
                method='fro';
            end
            eM=this.getErrorMatrix(originalMatrix);
            errNorm=norm(eM(:,:),method);
        end
        function percErr=percentError(this,originalMatrix,method)
            %error('FactorizedMatrix:percentError','This is no longer a supported method of FactorizedMatrix')
            if nargin<2
                method='fro';
            end
            percErr=this.errorNorm(originalMatrix,method)/norm(originalMatrix(:,:),method);
        end
        function errNormC=errorNormPerColumn(this,originalMatrix,method)
            if nargin<2
                method=2;
            end
            eM=this.errorMatrix(originalMatrix);
            errNormC=columnNorm(eM(:,:),method,1);
        end
        function errNormR=errorNormPerRow(this,originalMatrix,method)
            if nargin<2
                method=2;
            end
            eM=this.errorMatrix(originalMatrix);
            errNormR=columnNorm(eM(:,:),method,2);
        end
        function errNormPerDim=errorNormPerDim(this,originalMatrix,method,dim)
            eM=this.errorMatrix(originalMatrix);
            errNormPerDim= FactorizedMatrix.matNormPerDim(eM,method,dim);
        end
        function percErrC=percentErrorPerColumn(this,originalMatrix,method)
            %error('FactorizedMatrix:percentErrorPerColumn','This is no longer a supported method of FactorizedMatrix')
            if nargin<2
                method=2;
            end
            percErrC=this.errorNormPerColumn(originalMatrix,method)./columnNorm(originalMatrix(:,:),method,1);
        end
        function percErrR=percentErrorPerRow(this,originalMatrix,method)
            %error('FactorizedMatrix:percentErrorPerRow','This is no longer a supported method of FactorizedMatrix')
            if nargin<2
                method=2;
            end
            percErrR=this.errorNormPerRow(method)./columnNorm(originalMatrix(:,:),method,2);
        end
        function percErrPerDim=percErrPerDim(this,originalMatrix,method,dim)
            %error('FactorizedMatrix:percentErrorPerDim','This is no longer a supported method of FactorizedMatrix')
            percErrPerDim = FactorizedMatrix.matNormPerDim(this.errorMatrix,method,dim)./FactorizedMatrix.matNormPerDim(originalMatrix,method,dim);
        end
        function logL=pPCAlogL(this)
           logL=NaN; %To Do 
        end
        
        %Modifiers:
        function newThis=transpose(this)
            if length(this.matrixSize)<3
                newThis=FactorizedMatrix(this.matrixSize,this.dim2Vectors,this.dim1Vectors,this.factorizationMethod,[this.name ' Transposed']);
            else
                warning('Matrix is actually a high-dimensional (>3) tensor, cannot transpose as is. Will transpose the tensor as returned by indexing as (:,:)');
                size1=size(this.dim1Vectors);
                size2=size(this.dim2Vectors);
                newMatrixSize=[size2(2:end) size1(2:end)];
                newThis=FactorizedMatrix(newMatrixSize,this.dim2Vectors,this.dim1Vectors,this.factorizationMethod,[this.name ' Transposed']);
            end
        end
        
        function newThis=sort(this,newOrder)
            if numel(newOrder)==this.reducedDimension
                newDim1=this.dim1Vectors(newOrder,:);
                newDim1=reshape(newDim1,size(this.dim1Vectors));
                newDim2=this.dim2Vectors(newOrder,:);
                newDim2=reshape(newDim2,size(this.dim2Vectors));
                newThis=FactorizedMatrix(this.matrixSize,newDim1,newDim2,this.factMethod,this.name);
            else
               newThis=this;
               warning('FactorizedMatrix:sort','The newOrder vector is not of the appropriate size, ignoring.')
            end
        end
        
        %Display
        function [figHandle,plotHandles1,plotHandles2]=plot(this,plotHandles1,plotHandles2,colors)
            %If dim1Vectors is of dim==3, assuming that second dimension
            %are repetitions of whatever the first dimension represents
            %If dim1Vectors is of dim>3, don't know what to do, not
            %plotting
            %If dim2Vectors is of dim>2 don't know what to do, not plotting
            %------------
            N=this.reducedDimension;
            if nargin<3 || isempty(plotHandles1) || isempty(plotHandles2) %No handles
                figHandle=figure();
                for i=1:N
                	plotHandles1(i)=subplot(3,N,[i N+i]);
                    plotHandles2(i)=subplot(3,N,2*N+i);
                end
            else
                if (length(plotHandles1)==this.reducedDimension) && (length(plotHandles2)==this.reducedDimension)
                    figHandle=gcf;
                else %Non consistent handles, ignoring
                    figHandle=figure();
                    for i=1:N
                        plotHandles1(i)=subplot(3,N,[i N+i]);
                        plotHandles2(i)=subplot(3,N,2*N+i);
                    end
                end
            end
            if nargin<4 || isempty(colors)
                colors={[0,.4,1],[0,1,1],[0,1,0],[1,1,0],[1,.2,0],[1,0,1],[.5,.5,.5],[0,.6,0],[0,.5,1]};
            end
            %------------
            for i=1:N
                subplot(plotHandles1(i))
                hold on
                bar(this.dim2Vectors(i,:),'FaceColor',colors{mod(i,length(colors))+1})
                %freezeColors %external function!
                hold off
                subplot(plotHandles2(i))
                hold on
                for j=1:size(this.dim1Vectors,3)
                	plot(this.dim1Vectors(i,:,j),'Color',colors{mod(i,length(colors))+1})
                end
                plot(mean(this.dim1Vectors(i,:,:),3),'LineWidth',2,'Color',[.5,.5,.8].*colors{mod(i,length(colors))+1})
                hold off
            end
            
        end
        
        %Likelihood under ppca framework
        function logL=ppcaLikelihood(this,originalMatrix)
            coeff=this.dim2Vectors(:,:);
            scores=this.dim1Vectors(:,:);
            data=permute(originalMatrix,[3,1,2]);
            [logL] = ppcaLikelihood(data(:,:)',coeff,scores);
        end
        
    end %Normal methods
    
    
    methods(Static)
        %Generate factorizations:
        function newObj=factorize(matrix,dimInd,method,newDim,name) 
            if nargin<5
                name='';
            end
            %DimInd should be strictly less than the dim of matrix (i.e.
            %dimInd < ndims(matrix)
            if dimInd>=ndims(matrix)
                error('FactorizedMatrix:factorize','dimInd input argument has to be strictly less than the dimensions of the matrix, as it establishes the last dimension that will be part of the first factorized tensor, and there has to be at least one extra dimension for the second tensor.')
            end
            matSize=size(matrix);
            aux=reshape(matrix,[prod(matSize(1:dimInd)), prod(matSize(dimInd+1:end))]);
            
            switch method
                case 'nnmf'
                    [tensor1,tensor2]=myNNMF(aux,newDim,5,'always'); %Parallel processing & multiple replicates.
                    %[tensor1,tensor2]=nnmf(aux,newDim);
                    tensor1=reshape(tensor1',[newDim matSize(1:dimInd) ]);
                    tensor2=reshape(tensor2,[newDim matSize(dimInd+1:end)]);
                case 'pca'
                    [tensor2,tensor1]=pca(aux,'Centered','off','NumComponents',newDim);
                    tensor1=reshape(tensor1',[newDim matSize(1:dimInd) ]);
                    tensor2=reshape(tensor2',[newDim matSize(dimInd+1:end)]);
                case 'ica'
                    %To Do
                    tensor1=[];
                    tensor2=[];
            end
            newObj=FactorizedMatrix(size(matrix),tensor1,tensor2,method,name);
        end
        
    end %Static methods
    
    methods (Static, Access=private)
        function mnpd= matNormPerDim(mat,method,dim)
            aux=permute(mat,[dim, 1:dim-1 ,dim+1:ndims(mat)]);
            aux=aux(:,:);
            mnpd=columnNorm(aux,method,2);
            %s=size(mat);
            %mnpd=reshape(mnpd,s([1:dim-1 ,dim+1:ndims(mat)]));
        end
    end
    
end %classdef

