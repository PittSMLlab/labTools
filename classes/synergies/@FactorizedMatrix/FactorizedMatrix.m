classdef FactorizedMatrix
    %FACTORIZEDMATRIX Low-rank factorization of a matrix.
    %
    %   Represents a matrix H (MxN) as H_ij = sum_k u_ki v_kj, with k in
    % [1:p], p < M and p < N. The factorization is exact only if rank(H) <=
    % p. Both vector sets are indexed with the reduced dimension first: u_ki
    % is stored as dim1Vectors and v_kj as dim2Vectors. Tensors are also
    % supported, as H_ijl = sum_k u_ki v_kjl, where the v are tensors with
    % one dimension fewer than H.
    %
    % FactorizedMatrix properties:
    %   dim1Vectors         - first factor, reduced dimension first
    %   dim2Vectors         - second factor, reduced dimension first
    %   name                - display name (default 'Unnamed')
    %   factorizationMethod - method that produced the factors
    %   originalDimension   - lesser of M and N (dependent)
    %   matrixSize          - size of the factorized matrix (dependent)
    %   reducedDimension    - p, the number of factors (dependent)
    %   factorizedMatrix    - product of the factors (dependent)
    %   paramCount          - number of parameters in the factors
    %                         (dependent)
    %
    % FactorizedMatrix methods:
    %   FactorizedMatrix      - constructor
    %   getErrorMatrix        - original minus factorized matrix
    %   errorNorm             - norm of the error matrix
    %   percentError          - error norm relative to the original norm
    %   errorNormPerColumn    - error norm of each column
    %   errorNormPerRow       - error norm of each row
    %   errorNormPerDim       - error norm along a dimension
    %   percentErrorPerColumn - relative error of each column
    %   percentErrorPerRow    - relative error of each row
    %   transpose             - factorization of the transposed matrix
    %   sort                  - reorders the factors
    %   plot                  - plots both factors
    %   ppcaLikelihood        - log-likelihood under probabilistic PCA
    %   factorize             - factorizes a matrix or tensor (static)
    %
    % Toolbox Dependencies: Statistics and Machine Learning Toolbox
    %
    % See also SYNERGYANALYSIS, NNMF, PCA.

    % TODO: support factorizations of 3 or more elements, H_ijl = sum_k
    % u_ik v_jk w_lk, by letting dim2Vectors be a FactorizedMatrix
    % (feasibility unknown).


    properties
        %originalMatrix=zeros(3);
        dim1Vectors = zeros(3,1);
        dim2Vectors = zeros(1,3);
        name = 'Unnamed';
        factorizationMethod = 'Unknown';
    end
    properties(Dependent = true)
        originalDimension %This is the lesser of M and N
        matrixSize %This is size(originalMatrix)
        reducedDimension %this is p
        factorizedMatrix %Product of Dim1Vectors and Dim2Vectors
        %errorMatrix %Difference between original and factorized
        paramCount %Number of parameters in the factorization
    end

    methods
        %Constructor
        function this = FactorizedMatrix(originalSize,dim1vectors, ...
            dim2vectors,factMethod,name) %Last two are optional
            %FACTORIZEDMATRIX Constructor for FactorizedMatrix class.
            %
            %   this = FactorizedMatrix(originalSize, dim1vectors,
            % dim2vectors) checks that the factors are consistent with each
            % other and with originalSize, warns if the factors have more
            % degrees of freedom than the full matrix, and stores them.
            % dim1vectors may be given transposed.
            %
            %   NOTE: a mismatch between the factors and originalSize is
            % thrown inside a try block whose catch calls keyboard, which
            % stops in the debugger instead of propagating the error.
            %
            % Inputs:
            %   originalSize - vector with the size of the full matrix
            %   dim1vectors  - first factor
            %   dim2vectors  - second factor
            %   factMethod   - factorization method name (optional, char)
            %   name         - display name (optional, char)
            %
            % Outputs:
            %   this - FactorizedMatrix object
            %
            % Toolbox Dependencies: None

            if nargin < 3
                ME = MException( ...
                    'FactorizedMatrix:ConstructorNotEnoughArgs', ...
                    'Not enough arguments');
                throw(ME)
            end
            if numel(originalSize) ~= prod(size(originalSize))
                ME = MException( ...
                    'FactorizedMatrix:ConstructorBadSizeArgument', ...
                    ['The originalSize argument has to be a vector ' ...
                    'containing the size of the full matrix.']);
                throw(ME)
            end
            %this.originalMatrix=original; %Should not allow matrices that
            %have singleton dimensions in the middle (i.e., not the first
            %nor the last dimension), since it gives problems when checking
            %for size and/or reconstructing the matrix.
            %Check consistency of given arguments & assign
            %Given in the expected orientation
            if size(dim1vectors(:,:),1) == size(dim2vectors(:,:),1)
                this.dim1Vectors = dim1vectors;
                this.dim2Vectors = dim2vectors;
                %Given transposed, which implies dim1Vectors is a 2D matrix
            elseif size(dim1vectors,2) == size(dim2vectors(:,:),1)
                this.dim1Vectors = dim1vectors';
                this.dim2Vectors = dim2vectors;
            else %Inconsistent sizes
                ME = MException( ...
                    'FactorizedMatrix:ConstructorInconsistentFactors', ...
                    'The sizes of the factors are inconsistent.');
                throw(ME);
            end

            %Check if there is actually dimension reduction
            if (numel(this.dim1Vectors)+numel( ...
                    this.dim2Vectors)) >= prod(originalSize)
                warning(['The factorized matrix is not reduced from ' ...
                    'its full form (factors DoF > matrix DoF).'])
            end

            %Check consistency with originalMatrix size
            size1   = size(this.dim1Vectors);
            size2   = size(this.dim2Vectors);
            auxSize = [size1(2:end) size2(2:end)];
            try
                if ~isempty(originalSize) && ...
                        prod(auxSize) ~= prod(originalSize)
                    ME = MException( ...
                        ['FactorizedMatrix:Constructor' ...
                        'InconsistentMatrix'], ...
                        ['The sizes of the factors and the provided ' ...
                        'original matrix are inconsistent.']);
                    throw(ME);
                end
            catch
                keyboard
            end

            if nargin > 3 && isa(factMethod,'char')
                this.factorizationMethod = factMethod;
            else
                disp(['FactorizedMatrix Constructor: factorization ' ...
                    'method not given or is not a string. Ignoring.'])
            end
            if nargin > 4 && isa(name,'char')
                this.name = name;
            else
                disp(['FactorizedMatrix Constructor: name not given or ' ...
                    'is not a string. Ignoring.'])
            end

        end

        %Getters for dependent
        function origDim = get.originalDimension(this)
            %GET.ORIGINALDIMENSION Lesser of the two matrix dimensions.
            %
            % Inputs:
            %   this - FactorizedMatrix object
            %
            % Outputs:
            %   origDim - min(M, N) for the factorized M x N matrix
            %
            % Toolbox Dependencies: None

            origDim = ...
                min([size(this.dim1Vectors(:,:),2), ...
                size(this.dim2Vectors(:,:),2)]);
        end
        function matrixSize = get.matrixSize(this)
            %GET.MATRIXSIZE Size of the factorized matrix.
            %
            % Inputs:
            %   this - FactorizedMatrix object
            %
            % Outputs:
            %   matrixSize - size of the matrix the factors represent
            %
            % Toolbox Dependencies: None

            %matrixSize=size(this.originalMatrix); %Old way
            s1         = size(this.dim1Vectors);
            s2         = size(this.dim2Vectors);
            matrixSize = [s1(2:end) s2(2:end)];
        end
        function reducedDim = get.reducedDimension(this)
            %GET.REDUCEDDIMENSION Number of factors p.
            %
            % Inputs:
            %   this - FactorizedMatrix object
            %
            % Outputs:
            %   reducedDim - size of dim2Vectors along the first dimension
            %
            % Toolbox Dependencies: None

            reducedDim = size(this.dim2Vectors,1);
        end
        function factMat = get.factorizedMatrix(this)
            %GET.FACTORIZEDMATRIX Matrix reconstructed from the factors.
            %
            % Inputs:
            %   this - FactorizedMatrix object
            %
            % Outputs:
            %   factMat - product of the factors, reshaped to matrixSize
            %
            % Toolbox Dependencies: None

            factMat = this.dim1Vectors(:,:)'*this.dim2Vectors(:,:);
            factMat = reshape(factMat,this.matrixSize);
        end

        function paramCount = get.paramCount(this)
            %GET.PARAMCOUNT Number of parameters in the factors.
            %
            % Inputs:
            %   this - FactorizedMatrix object
            %
            % Outputs:
            %   paramCount - numel(dim1Vectors) + numel(dim2Vectors)
            %
            % Toolbox Dependencies: None

            paramCount = numel(this.dim1Vectors)+numel(this.dim2Vectors);
        end

        %Other:
        function errorMat = getErrorMatrix(this,originalMatrix)
            %GETERRORMATRIX Original minus factorized matrix.
            %
            % Inputs:
            %   this           - FactorizedMatrix object
            %   originalMatrix - matrix that was factorized
            %
            % Outputs:
            %   errorMat - originalMatrix minus factorizedMatrix
            %
            % Toolbox Dependencies: None

            errorMat = originalMatrix-this.factorizedMatrix;
        end

        function errorMat = errorMatrix(this,originalMatrix)
            %ERRORMATRIX Deprecated alias of getErrorMatrix.
            %
            %   Warns and calls getErrorMatrix.
            %
            % Inputs:
            %   this           - FactorizedMatrix object
            %   originalMatrix - matrix that was factorized
            %
            % Outputs:
            %   errorMat - originalMatrix minus factorizedMatrix
            %
            % Toolbox Dependencies: None
            %
            % See also GETERRORMATRIX.

            warning('FactorizedMatrix:errorMatrix', ...
                'This method is deprecated, use getErrorMatrix instead.')
            errorMat = this.getErrorMatrix(originalMatrix);
        end

        function errNorm = errorNorm(this,originalMatrix,method)
            %ERRORNORM Norm of the error matrix.
            %
            %   NOTE: the default for method ('fro') is applied only when
            % nargin < 2, so a call with originalMatrix but no method
            % errors.
            %
            % Inputs:
            %   this           - FactorizedMatrix object
            %   originalMatrix - matrix that was factorized
            %   method         - norm type passed to norm (default 'fro')
            %
            % Outputs:
            %   errNorm - norm of the error matrix
            %
            % Toolbox Dependencies: None

            if nargin < 2
                method = 'fro';
            end
            eM      = this.getErrorMatrix(originalMatrix);
            errNorm = norm(eM(:,:),method);
        end
        function percErr = percentError(this,originalMatrix,method)
            %PERCENTERROR Error norm relative to the original norm.
            %
            %   NOTE: the default for method ('fro') is applied only when
            % nargin < 2, so a call with originalMatrix but no method
            % errors.
            %
            % Inputs:
            %   this           - FactorizedMatrix object
            %   originalMatrix - matrix that was factorized
            %   method         - norm type passed to norm (default 'fro')
            %
            % Outputs:
            %   percErr - errorNorm divided by norm(originalMatrix)
            %
            % Toolbox Dependencies: None

            if nargin < 2
                method = 'fro';
            end
            percErr = this.errorNorm(originalMatrix, ...
                method)/norm(originalMatrix(:,:),method);
        end
        function errNormC = errorNormPerColumn(this,originalMatrix,method)
            %ERRORNORMPERCOLUMN Norm of each column of the error matrix.
            %
            %   NOTE: the default for method (2) is applied only when nargin
            % < 2.
            %
            % Inputs:
            %   this           - FactorizedMatrix object
            %   originalMatrix - matrix that was factorized
            %   method         - norm type passed to columnNorm (default 2)
            %
            % Outputs:
            %   errNormC - row vector with the error norm of each column
            %
            % Toolbox Dependencies: None

            if nargin < 2
                method = 2;
            end
            eM       = this.errorMatrix(originalMatrix);
            errNormC = columnNorm(eM(:,:),method,1);
        end
        function errNormR = errorNormPerRow(this,originalMatrix,method)
            %ERRORNORMPERROW Norm of each row of the error matrix.
            %
            %   NOTE: the default for method (2) is applied only when nargin
            % < 2.
            %
            % Inputs:
            %   this           - FactorizedMatrix object
            %   originalMatrix - matrix that was factorized
            %   method         - norm type passed to columnNorm (default 2)
            %
            % Outputs:
            %   errNormR - error norm of each row
            %
            % Toolbox Dependencies: None

            if nargin < 2
                method = 2;
            end
            eM       = this.errorMatrix(originalMatrix);
            errNormR = columnNorm(eM(:,:),method,2);
        end
        function errNormPerDim = errorNormPerDim(this,originalMatrix, ...
            method,dim)
            %ERRORNORMPERDIM Norm of the error matrix along one dimension.
            %
            % Inputs:
            %   this           - FactorizedMatrix object
            %   originalMatrix - matrix that was factorized
            %   method         - norm type
            %   dim            - dimension kept as the index of the result
            %
            % Outputs:
            %   errNormPerDim - error norm for each index of dimension dim
            %
            % Toolbox Dependencies: None

            eM = this.errorMatrix(originalMatrix);
            errNormPerDim = FactorizedMatrix.matNormPerDim(eM,method,dim);
        end
        function percErrC = percentErrorPerColumn(this,originalMatrix, ...
            method)
            %PERCENTERRORPERCOLUMN Relative error norm of each column.
            %
            %   NOTE: the default for method (2) is applied only when nargin
            % < 2.
            %
            % Inputs:
            %   this           - FactorizedMatrix object
            %   originalMatrix - matrix that was factorized
            %   method         - norm type (default 2)
            %
            % Outputs:
            %   percErrC - errorNormPerColumn divided by the column norms of
            %              originalMatrix
            %
            % Toolbox Dependencies: None

            if nargin < 2
                method = 2;
            end
            percErrC = this.errorNormPerColumn(originalMatrix, ...
                method)./columnNorm(originalMatrix(:,:),method,1);
        end
        function percErrR = percentErrorPerRow(this,originalMatrix,method)
            %PERCENTERRORPERROW Relative error norm of each row.
            %
            %   NOTE: the call to errorNormPerRow passes only method, so
            % this method errors as written.
            %
            % Inputs:
            %   this           - FactorizedMatrix object
            %   originalMatrix - matrix that was factorized
            %   method         - norm type (default 2)
            %
            % Outputs:
            %   percErrR - error norm of each row divided by the row norms
            %              of originalMatrix
            %
            % Toolbox Dependencies: None

            if nargin < 2
                method = 2;
            end
            percErrR = ...
                this.errorNormPerRow(method)./columnNorm( ...
                originalMatrix(:,:),method,2);
        end
        function percErrPerDim = percErrPerDim(this,originalMatrix, ...
            method,dim)
            %PERCERRPERDIM Relative error norm along one dimension.
            %
            %   NOTE: errorMatrix is called without originalMatrix, so this
            % method errors as written.
            %
            % Inputs:
            %   this           - FactorizedMatrix object
            %   originalMatrix - matrix that was factorized
            %   method         - norm type
            %   dim            - dimension kept as the index of the result
            %
            % Outputs:
            %   percErrPerDim - error norm divided by the norm of
            %                   originalMatrix
            %
            % Toolbox Dependencies: None

            percErrPerDim = ...
                FactorizedMatrix.matNormPerDim(this.errorMatrix,method, ...
                dim)./FactorizedMatrix.matNormPerDim(originalMatrix, ...
                method,dim);
        end
        function logL = pPCAlogL(this)
            %PPCALOGL Placeholder for the probabilistic PCA log-likelihood.
            %
            % Inputs:
            %   this - FactorizedMatrix object
            %
            % Outputs:
            %   logL - NaN (not implemented)
            %
            % Toolbox Dependencies: None
            %
            % See also PPCALIKELIHOOD.

            logL = NaN; % TODO: not implemented
        end

        %Modifiers:
        function newThis = transpose(this)
            %TRANSPOSE Factorization of the transposed matrix.
            %
            %   Swaps dim1Vectors and dim2Vectors. For tensors (more than
            % two dimensions) it warns and transposes the tensor as indexed
            % with (:,:).
            %
            % Inputs:
            %   this - FactorizedMatrix object
            %
            % Outputs:
            %   newThis - FactorizedMatrix named '<name> Transposed'
            %
            % Toolbox Dependencies: None

            if length(this.matrixSize) < 3
                newThis = FactorizedMatrix(this.matrixSize, ...
                    this.dim2Vectors,this.dim1Vectors, ...
                    this.factorizationMethod,[this.name ' Transposed']);
            else
                warning(['Matrix is actually a high-dimensional (>3) ' ...
                    'tensor, cannot transpose as is. Will transpose ' ...
                    'the tensor as returned by indexing as (:,:)']);
                size1         = size(this.dim1Vectors);
                size2         = size(this.dim2Vectors);
                newMatrixSize = [size2(2:end) size1(2:end)];
                newThis = FactorizedMatrix(newMatrixSize, ...
                    this.dim2Vectors,this.dim1Vectors, ...
                    this.factorizationMethod,[this.name ' Transposed']);
            end
        end

        function newThis = sort(this,newOrder)
            %SORT Reorders the factors.
            %
            %   If newOrder does not have one entry per factor, a warning is
            % issued and the object is returned unchanged.
            %
            %   NOTE: the sorted object is built from this.factMethod, which
            % is not a property of the class, so a valid reordering errors
            % as written.
            %
            % Inputs:
            %   this     - FactorizedMatrix object
            %   newOrder - permutation of 1:reducedDimension
            %
            % Outputs:
            %   newThis - FactorizedMatrix with the factors in the new order
            %
            % Toolbox Dependencies: None

            if numel(newOrder) == this.reducedDimension
                newDim1 = this.dim1Vectors(newOrder,:);
                newDim1 = reshape(newDim1,size(this.dim1Vectors));
                newDim2 = this.dim2Vectors(newOrder,:);
                newDim2 = reshape(newDim2,size(this.dim2Vectors));
                newThis = FactorizedMatrix(this.matrixSize,newDim1, ...
                    newDim2,this.factMethod,this.name);
            else
                newThis = this;
                warning('FactorizedMatrix:sort', ...
                    ['The newOrder vector is not of the appropriate ' ...
                    'size, ignoring.'])
            end
        end

        %Display
        function [figHandle,plotHandles1,plotHandles2] = ...
            plot(this,plotHandles1,plotHandles2,colors)
            %PLOT Plots both factors, one column of subplots per factor.
            %
            %   The upper subplot of factor k bars dim2Vectors(k,:); the
            % lower one draws every repetition of dim1Vectors(k,:,:) with
            % their mean in bold. Tensors with more than three dimensions in
            % dim1Vectors, or more than two in dim2Vectors, are not
            % supported.
            %
            % Inputs:
            %   this         - FactorizedMatrix object
            %   plotHandles1 - subplot handles for the second factor
            %                  (optional)
            %   plotHandles2 - subplot handles for the first factor
            %                  (optional)
            %   colors       - cell array of RGB colors cycled over the
            %                  factors (optional)
            %
            % Outputs:
            %   figHandle    - figure handle (gcf if usable handles were
            %                  given)
            %   plotHandles1 - subplot handles for the second factor
            %   plotHandles2 - subplot handles for the first factor
            %
            % Toolbox Dependencies: None

            N = this.reducedDimension;
            %No handles
            if nargin < 3 || isempty(plotHandles1) || isempty(plotHandles2)
                figHandle = figure();
                for ii = 1:N
                    plotHandles1(ii) = subplot(3,N,[ii N+ii]);
                    plotHandles2(ii) = subplot(3,N,2*N+ii);
                end
            else
                if (length(plotHandles1) == this.reducedDimension) && ...
                        (length(plotHandles2) == this.reducedDimension)
                    figHandle = gcf;
                else %Non consistent handles, ignoring
                    figHandle = figure();
                    for ii = 1:N
                        plotHandles1(ii) = subplot(3,N,[ii N+ii]);
                        plotHandles2(ii) = subplot(3,N,2*N+ii);
                    end
                end
            end
            if nargin < 4 || isempty(colors)
                colors = {[0,0.4,1],[0,1,1],[0,1,0],[1,1,0],[1,0.2,0], ...
                    [1,0,1],[0.5,0.5,0.5],[0,0.6,0],[0,0.5,1]};
            end
            %------------
            for ii = 1:N
                subplot(plotHandles1(ii))
                hold on
                bar(this.dim2Vectors(ii,:),'FaceColor', ...
                    colors{mod(ii,length(colors))+1})
                %freezeColors %external function!
                hold off
                subplot(plotHandles2(ii))
                hold on
                for jj = 1:size(this.dim1Vectors,3)
                    plot(this.dim1Vectors(ii,:,jj),'Color', ...
                        colors{mod(ii,length(colors))+1})
                end
                plot(mean(this.dim1Vectors(ii,:,:),3),'LineWidth',2, ...
                    'Color',[0.5,0.5,0.8].*colors{mod(ii,length(colors))+1})
                hold off
            end

        end

        %Likelihood under ppca framework
        function logL = ppcaLikelihood(this,originalMatrix)
            %PPCALIKELIHOOD Log-likelihood of data under probabilistic PCA.
            %
            %   Calls the external ppcaLikelihood function with the factors
            % as coefficients and scores.
            %
            % Inputs:
            %   this           - FactorizedMatrix object
            %   originalMatrix - data that was factorized
            %
            % Outputs:
            %   logL - log-likelihood
            %
            % Toolbox Dependencies: None

            coeff  = this.dim2Vectors(:,:);
            scores = this.dim1Vectors(:,:);
            data   = permute(originalMatrix,[3,1,2]);
            logL   = ppcaLikelihood(data(:,:)',coeff,scores);
        end

    end %Normal methods


    methods(Static)
        %Generate factorizations:
        function newObj = factorize(matrix,dimInd,method,newDim,name)
            %FACTORIZE Factorizes a matrix or tensor.
            %
            %   The matrix is reshaped to 2-D by grouping its first dimInd
            % dimensions against the rest and factorized with method: 'nnmf'
            % (non-negative factorization with multiple replicates through
            % myNNMF), 'pca' (uncentered), or 'ica' (not implemented; the
            % factors are empty).
            %
            % Inputs:
            %   matrix - numeric array to factorize
            %   dimInd - last dimension of the first factor; must be less
            %            than ndims(matrix)
            %   method - 'nnmf', 'pca', or 'ica'
            %   newDim - number of factors to keep
            %   name   - display name (optional)
            %
            % Outputs:
            %   newObj - FactorizedMatrix of the given matrix
            %
            % Toolbox Dependencies: Statistics and Machine Learning Toolbox

            if nargin < 5
                name = '';
            end
            %DimInd should be strictly less than the dim of matrix (i.e.
            %dimInd < ndims(matrix)
            if dimInd >= ndims(matrix)
                error('FactorizedMatrix:factorize', ...
                    ['dimInd input argument has to be strictly less ' ...
                    'than the dimensions of the matrix, as it ' ...
                    'establishes the last dimension that will be part ' ...
                    'of the first factorized tensor, and there has to ' ...
                    'be at least one extra dimension for the second ' ...
                    'tensor.'])
            end
            matSize = size(matrix);
            aux = reshape(matrix, ...
                [prod(matSize(1:dimInd)), prod(matSize(dimInd+1:end))]);

            nnmfReplicates = 5; % TODO: source?

            switch method
                case 'nnmf'
                    %Parallel processing & multiple replicates.
                    [tensor1,tensor2] = myNNMF(aux,newDim, ...
                        nnmfReplicates,'always');
                    %[tensor1,tensor2]=nnmf(aux,newDim);
                    tensor1 = reshape(tensor1',[newDim matSize(1:dimInd) ]);
                    tensor2 = reshape(tensor2, ...
                        [newDim matSize(dimInd+1:end)]);
                case 'pca'
                    [tensor2,tensor1] = ...
                        pca(aux,'Centered','off','NumComponents',newDim);
                    tensor1 = reshape(tensor1',[newDim matSize(1:dimInd) ]);
                    tensor2 = reshape(tensor2', ...
                        [newDim matSize(dimInd+1:end)]);
                case 'ica'
                    % TODO: not implemented
                    tensor1 = [];
                    tensor2 = [];
            end
            newObj = FactorizedMatrix(size(matrix),tensor1,tensor2, ...
                method,name);
        end

    end %Static methods

    methods (Static, Access = private)
        function mnpd = matNormPerDim(mat,method,dim)
            %MATNORMPERDIM Norm of an array along one dimension.
            %
            % Inputs:
            %   mat    - numeric array
            %   method - norm type passed to columnNorm
            %   dim    - dimension kept as the index of the result
            %
            % Outputs:
            %   mnpd - norm of the entries for each index of dimension dim
            %
            % Toolbox Dependencies: None

            aux  = permute(mat,[dim, 1:dim-1 ,dim+1:ndims(mat)]);
            aux  = aux(:,:);
            mnpd = columnNorm(aux,method,2);
            %s=size(mat);
            %mnpd=reshape(mnpd,s([1:dim-1 ,dim+1:ndims(mat)]));
        end
    end

end %classdef

