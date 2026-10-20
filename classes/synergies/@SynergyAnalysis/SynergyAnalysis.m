classdef SynergyAnalysis
    %SYNERGYANALYSIS Dimensionality analysis of muscle synergies.
    %
    %   Factorizes training data into 1 to Nmuscles synergies with
    % FactorizedMatrix.factorize and reconstructs testing data from the
    % training synergies. Data are arrays with time in the first dimension,
    % steps in the second, and muscles in the last.
    %
    % SynergyAnalysis properties:
    %   trainingFactorizations - cell array of FactorizedMatrix, one per
    %                            dimension
    %   testingFactorizations  - cell array of cell arrays of
    %                            FactorizedMatrix
    %   muscleList             - cell array of muscle names
    %   trainingData           - training data array
    %   testingData            - testing data array
    %   trainingResiduals      - error matrices of the training fits
    %                            (dependent)
    %   testingResiduals       - error matrices of the testing fits
    %                            (dependent)
    %   synergySets            - training synergies per dimension
    %                            (dependent)
    %
    % SynergyAnalysis methods:
    %   SynergyAnalysis - constructor
    %   factorizeNewTestingData - adds testing data
    %   getFactorization - testing and training factorization of a dimension
    %   getRandomDataReconstructionPerformance - reconstruction of random
    %                                            data
    %   assessDimensionality - reconstruction error versus dimension
    %   plot - plots the testing factorization
    %   coefExtrFromSyn - activations from fixed synergies (static)
    %
    % Toolbox Dependencies: Parallel Computing Toolbox
    %
    % See also FACTORIZEDMATRIX.

    properties
        %cell array of length N, each containing a factorizedMatrix
        trainingFactorizations = {};
        %cell array cell arrays of length N, each containing a
        %factorizedMatrix
        testingFactorizations = {};
        muscleList = {};
        trainingData = {}; %Plain matrix, unnecessary?
        testingData = {}; %Plain matrix, unnecessary?
    end
    properties(Dependent)
        trainingResiduals %cell array of matrices, unnecessary?
        testingResiduals %cell array of matrices, unnecessary?
        synergySets %cell array of SynergySet, unnecessary?
    end

    methods
        %Constructor
        function this = SynergyAnalysis(testingData,trainingData, ...
            muscleList,name,method)
            %SYNERGYANALYSIS Constructor for SynergyAnalysis class.
            %
            %   this = SynergyAnalysis(testingData, trainingData,
            % muscleList) factorizes trainingData for every number of
            % synergies from 1 to the number of muscles, and testingData (if
            % not empty) with the training synergies.
            %
            % Inputs:
            %   testingData  - testing array (time x steps x muscles), may
            %                  be empty
            %   trainingData - training array (time x steps x muscles)
            %   muscleList   - cell array of muscle names
            %   name         - prefix for the factorization names (optional)
            %   method       - 'nnmf' or 'pca' (optional, default 'nnmf')
            %
            % Outputs:
            %   this - SynergyAnalysis object
            %
            % Toolbox Dependencies: Statistics and Machine Learning Toolbox

            if nargin < 5 || isempty(method)
                method = 'nnmf';
            end
            if nargin < 4 || isempty(name)
                name = '';
            end
            %Check that size of testingData and trainingData are the same

            %Dim 1 is time, dim 2 are steps, dim 3 are muscles (muscles
            %have to be in the last dimension for the factorization to be
            %done properly with this code).
            for dim = 1:size(trainingData,3) %Factorizing from 1 to Nmuscles
                %Compute synergies from training data
                %The second argument has to be the dimension corresponding
                %to the muscles dim-1.
                trainingFactorizations{dim} = ...
                    FactorizedMatrix.factorize(trainingData,2,method, ...
                    dim,[name '_trainingSet_dim' num2str(dim)]);
            end
            this.trainingFactorizations = trainingFactorizations;
            this.muscleList = muscleList;
            this.trainingData = trainingData;
            %Compute coefs from synergies and testing data
            if ~isempty(testingData)
                this = factorizeNewTestingData(this,testingData,method, ...
                    name);
            end
        end

        %Extract coefs for testingData
        function newThis = factorizeNewTestingData(this,testingData, ...
            method,name)
            %FACTORIZENEWTESTINGDATA Adds a testing data set.
            %
            %   Extracts the activations of testingData from the training
            % synergies of every dimension and stores the factorizations and
            % the data.
            %
            % Inputs:
            %   this        - SynergyAnalysis object
            %   testingData - testing array (time x steps x muscles)
            %   method      - 'nnmf' or 'pca'
            %   name        - prefix for the factorization names (optional)
            %
            % Outputs:
            %   newThis - SynergyAnalysis with the new testing
            %             factorizations
            %
            % Toolbox Dependencies: Parallel Computing Toolbox
            %
            % See also COEFEXTRFROMSYN.

            if nargin < 4 || isempty(name)
                name = '';
            end
            % TODO: check that testingData and trainingData have compatible
            % dimensions.

            %
            N = length(this.testingFactorizations);
            %Factorizing from 1 to Nmuscles
            for dim = 1:size(this.trainingData,3)
                %Compute coefs from synergies and testing data
                reshapedData = reshape(testingData, ...
                    [size(testingData,1)*size(testingData,2), ...
                    size(testingData,3)]);
                coefs = ...
                    SynergyAnalysis.coefExtrFromSyn(reshapedData, ...
                    this.trainingFactorizations{dim}.dim2Vectors,method);
                reshapedCoefs = reshape(coefs, ...
                    [dim,size(testingData,1),size(testingData,2)]);
                testFactorizations{dim} = ...
                    FactorizedMatrix(size(testingData),reshapedCoefs, ...
                    this.trainingFactorizations{dim}.dim2Vectors,method, ...
                    [name '_dim' num2str(dim)]);
            end
            this.testingFactorizations{N+1} = testFactorizations;
            this.testingData{N+1} = testingData;
            newThis = this;
        end

        %Misc IO
        %Returns a single factorization, if dim is not given, returns the
        %chosenDim factorization
        function [testFactorization,trainFactorization] = ...
            getFactorization(this,dim)
            %GETFACTORIZATION Factorizations of one dimension.
            %
            %   NOTE: the body reads testFactorizations and
            % trainFactorizations, which are not properties (they are
            % testingFactorizations and trainingFactorizations), and
            % chooseDim is not implemented, so the method errors as written.
            %
            % Inputs:
            %   this - SynergyAnalysis object
            %   dim  - number of synergies (default chooseDim)
            %
            % Outputs:
            %   testFactorization  - testing FactorizedMatrix
            %   trainFactorization - training FactorizedMatrix
            %
            % Toolbox Dependencies: None

            if nargin < 2
                dim = this.chooseDim;
            end
            testFactorization  = this.testFactorizations{1}{dim};
            trainFactorization = this.trainFactorizations{dim};
        end

        %Others
        function [cumEigPdf,margEigPdf,totalVarPdf,overexplanationPdf, ...
            meanPdf] = getRandomDataReconstructionPerformance(this, ...
            randomMethod,factMethod)
            %GETRANDOMDATARECONSTRUCTIONPERFORMANCE Random-data fits.
            %
            %   Generates random data with the 'spectralMatch' (spectrum of
            % the training data) or 'timeShift' (time-shifted training data)
            % method, factorizes it with factMethod, and returns the
            % distributions computed by the empiric*EigDistributions*
            % functions. Uses 10000 repetitions (200 for 'timeShift' with
            % 'nnmf').
            %
            %   NOTE: the empiric*EigDistributions* and
            % createUnstructuredParametersFromData functions are not in this
            % repository; the output descriptions below follow the variable
            % names.
            %
            % Inputs:
            %   this         - SynergyAnalysis object
            %   randomMethod - 'spectralMatch' or 'timeShift'
            %   factMethod   - 'pca', 'uncentPCA', or 'nnmf'
            %
            % Outputs:
            %   cumEigPdf          - distribution of the cumulative
            %                        eigenvalues
            %   margEigPdf         - distribution of the marginal
            %                        eigenvalues
            %   totalVarPdf        - distribution of the total variance
            %   overexplanationPdf - distribution of the overexplanation
            %   meanPdf            - distribution of the mean
            %
            % Toolbox Dependencies: None

            Nreps = 10000;
            switch randomMethod
                case 'spectralMatch'
                    if strcmpi(factMethod,'nnmf')
                        disp(['Cannot use NNMF with spectrally matched ' ...
                            'data since positivity constraints are ' ...
                            'not satisfied. Using uncentered PCA instead.'])
                        factMethod = 'uncentPCA';
                    end
                    sizes = size(this.trainingData);
                    [mu,sigma,filter] = ...
                        createUnstructuredParametersFromData( ...
                        reshape(this.trainingFactorizations{ ...
                        1}.originalMatrix,prod(sizes(1:2)),sizes(3)));
                    switch factMethod
                        case 'pca'
                            centering = true;
                        case 'uncentPCA'
                            centering = false;
                        otherwise
                            throw(MException( ...
                                ['SynAnalysisRandomRec:' ...
                                'UnrecognizedFactMethod'], ...
                                ['Unrecognized method for factorizing ' ...
                                'random data: options are pca, ' ...
                                'uncentPCA and nnmf.']))
                    end
                    [cumEigPdf,margEigPdf,totalVarPdf, ...
                        overexplanationPdf, ...
                        meanPdf] = empiricPCAEigDistributionsFiltered( ...
                        mu,sigma,prod(sizes(1:2)),Nreps,filter,[], ...
                        'normal',true,centering);

                case 'timeShift'
                    switch factMethod
                        case 'nnmf'
                            Nreps = 200;
                            sizes = size(this.trainingData);
                            [cumEigPdf,margEigPdf,totalVarPdf, ...
                                overexplanationPdf, ...
                                meanPdf] = ...
                                empiricNNMFEigDistributionsTimeShifted( ...
                                reshape(this.trainingFactorizations{ ...
                                1}.originalMatrix,prod(sizes(1:2)), ...
                                sizes(3)),Nreps);
                        case 'pca'
                            centering = true;
                            sizes     = size(this.trainingData);
                            [cumEigPdf,margEigPdf,totalVarPdf, ...
                                overexplanationPdf, ...
                                meanPdf] = ...
                                empiricPCAEigDistributionsTimeShifted( ...
                                reshape(this.trainingFactorizations{ ...
                                1}.originalMatrix,prod(sizes(1:2)), ...
                                sizes(3)),Nreps,centering);
                        case 'uncentPCA'
                            centering = false;
                            sizes     = size(this.trainingData);
                            [cumEigPdf,margEigPdf,totalVarPdf, ...
                                overexplanationPdf, ...
                                meanPdf] = ...
                                empiricPCAEigDistributionsTimeShifted( ...
                                reshape(this.trainingFactorizations{ ...
                                1}.originalMatrix,prod(sizes(1:2)), ...
                                sizes(3)),Nreps,centering);
                        otherwise
                            throw(MException( ...
                                ['SynAnalysisRandomRec:' ...
                                'UnrecognizedFactMethod'], ...
                                ['Unrecognized method for factorizing ' ...
                                'random data: options are pca, ' ...
                                'uncentPCA and nnmf.']))
                    end
                otherwise
                    throw(MException( ...
                        'SynAnalysisRandomRec:UnrecognizedRandomMethod', ...
                        ['Unrecognized method for generating random ' ...
                        'data: options are timeShift and spectralMatch']))
            end
        end

        dim = chooseDim(this) %TODO

        function [errTrain,errTest,fh] = ...
            assessDimensionality(this,plotFlag,fh,names)
            %ASSESSDIMENSIONALITY Reconstruction error by dimension.
            %
            %   Computes the Frobenius norm of the error matrix of each
            % factorization relative to the norm of the data, for training
            % and testing data, and plots the squared errors unless plotFlag
            % is 0.
            %
            % Inputs:
            %   this     - SynergyAnalysis object
            %   plotFlag - plot the errors (default true)
            %   fh       - existing figure handle (optional)
            %   names    - prefix for the legend entries (optional)
            %
            % Outputs:
            %   errTrain - normalized training error per dimension
            %   errTest  - normalized testing error per dimension
            %   fh       - figure handle
            %
            % Toolbox Dependencies: None

            if nargin < 4 || isempty(names)
                names = '';
            end
            %First: find error norm as a function of dimension for training
            %and testing
            %data

            auxTrain = norm(this.trainingData(:,:),'fro');
            auxTest  = norm(this.testingData(:,:),'fro');
            for ii = 1:this.testingFactorizations{1}.originalDimension
                eM = this.trainingFactorizations{ii}.getErrorMatrix( ...
                    this.trainingData);
                errTrain(ii) = norm(eM(:,:),'fro')/auxTrain;
                eM = this.testingFactorizations{ii}.getErrorMatrix( ...
                    this.testingData);
                errTest(ii) = norm(eM(:,:),'fro')/auxTest;
            end

            if nargin < 2 || (~isempty(plotFlag) && plotFlag ~= 0)
                if nargin > 2
                    figure(fh)
                else
                    fh = figure;
                end
                hold on
                p = plot(errTrain.^2,'DisplayName', ...
                    [names 'Training Data'],'LineWidth',2);
                plot(errTest.^2,'--','DisplayName', ...
                    [names 'Testing Data'],'LineWidth',2,'Color', ...
                    get(p,'Color'))
                xlabel('Dims.')
                ylabel('Normalized reconstruction error squared')
                hold off
                p = get(gca,'Children');
                legend(p);
            end


        end

        %Display
        function [figHandle,plotHandles1,plotHandles2] = ...
            plot(this,plotHandles1,plotHandles2,colors,dim)
            %PLOT Plots the testing factorization of one dimension.
            %
            %   Calls FactorizedMatrix.plot on the testing factorization of
            % dimension dim and labels the muscles.
            %
            % Inputs:
            %   this         - SynergyAnalysis object
            %   plotHandles1 - subplot handles for the second factor
            %                  (optional)
            %   plotHandles2 - subplot handles for the first factor
            %                  (optional)
            %   colors       - cell array of RGB colors (optional)
            %   dim          - number of synergies (default chooseDim)
            %
            % Outputs:
            %   figHandle    - figure handle
            %   plotHandles1 - subplot handles for the second factor
            %   plotHandles2 - subplot handles for the first factor
            %
            % Toolbox Dependencies: None

            %Plotting the testing data only
            if nargin < 5
                dim = this.chooseDim;
            end
            if nargin < 4
                colors = [];
            end
            if nargin < 3
                plotHandles1 = [];
                plotHandles2 = [];
            end
            [figHandle,plotHandles1,plotHandles2] = ...
                plot(this.testingFactorizations{dim},plotHandles1, ...
                plotHandles2,colors);
            for ii = 1:length(plotHandles1)
                subplot(plotHandles1(ii))
                set(plotHandles1(ii),'XTick', ...
                    1:this.testingFactorizations{dim}.matrixSize(end), ...
                    'XTickLabels',this.muscleList,'XTickLabelRotation',90)
                axis tight
            end
        end

        %Getters for dependent properties

        function trainRes = get.trainingResiduals(this)
            %GET.TRAININGRESIDUALS Training error matrices.
            %
            % Inputs:
            %   this - SynergyAnalysis object
            %
            % Outputs:
            %   trainRes - cell array with one error matrix per dimension
            %
            % Toolbox Dependencies: None

            for ii = 1:length(this.trainingFactorizations)
                trainRes{ii} = ...
                    this.trainingFactorizations{ii}.errorMatrix( ...
                    this.trainingData);
            end
        end

        function testRes = get.testingResiduals(this)
            %GET.TESTINGRESIDUALS Testing error matrices.
            %
            % Inputs:
            %   this - SynergyAnalysis object
            %
            % Outputs:
            %   testRes - cell array (per testing set) of cell arrays (per
            %             dimension) of error matrices
            %
            % Toolbox Dependencies: None

            for jj = 1:length(this.testingFactorizations)
                for ii = 1:length(this.testingFactorizations{1})
                    testRes{jj}{ii} = ...
                        this.testingFactorizations{jj}{ii}.errorMatrix( ...
                        this.testingData);
                end
            end
        end

        function ss = get.synergySets(this)
            %GET.SYNERGYSETS Training synergies of every dimension.
            %
            % Inputs:
            %   this - SynergyAnalysis object
            %
            % Outputs:
            %   ss - cell array with the dim2Vectors of each training
            %        factorization
            %
            % Toolbox Dependencies: None

            for ii = 1:length(this.trainingFactorizations)
                ss{ii} = this.trainingFactorizations{ii}.dim2Vectors;
            end
        end

    end

    methods(Static)

        function dim1Vectors = coefExtrFromSyn(data,dim2Vectors,method)
            %COEFEXTRFROMSYN Activations for fixed synergies.
            %
            %   Solves data = act * dim2Vectors for act. With 'nnmf' the
            % activations are constrained to be nonnegative (lsqnonneg, run
            % in parallel); with 'pca' the unconstrained solution is used
            % and a warning is issued if the residual exceeds that expected
            % from random reconstructions. Opens a parallel pool if none is
            % running and closes it afterwards.
            %
            % Inputs:
            %   data        - samples x muscles matrix
            %   dim2Vectors - synergies x muscles matrix
            %   method      - 'nnmf' or 'pca'
            %
            % Outputs:
            %   dim1Vectors - synergies x samples matrix of activations
            %
            % Toolbox Dependencies: Parallel Computing Toolbox

            solverTol = 1e-4; % TODO: source?
            opts = optimset('display','off','TolFun', ...
                solverTol/size(data,2)^2,'TolX',solverTol);

            poolFlag = 0;
            if isempty(gcp('nocreate'))
                parpool
                poolFlag = 1;
            end

            coefs = [];
            switch method
                case 'nnmf'
                    parfor ii = 1:size(data,1)
                        x0 = ones(size(dim2Vectors,1),1);
                        coefs(:,ii) = ...
                            lsqnonneg(dim2Vectors',data(ii,:)',opts);
                    end
                case 'pca'
                    coefs = (data/dim2Vectors)';
                    %Check minimum convergence (if using N dimensions):
                    %Checking for reconstruction levels to be at least
                    %random reconstruction expected values
                    if (norm(data-coefs'*dim2Vectors,'fro')/norm(data, ...
                            'fro')) > (1-size(coefs,1)/size(data,2))
                        warning('SynegyAnalysis:coefExtrFromSyn', ...
                            ['Residuals from lsq is higher than ' ...
                            'expected from random reconstructions, ' ...
                            'there is a probable issue with algorithm ' ...
                            'convergence.'])
                    end
                otherwise
                    error('SynergyAnalysis:coefExtrFromSyn', ...
                        ['Not implemented for the desired method: ' method])
            end

            dim1Vectors = coefs;
            if poolFlag == 1
                delete(gcp('nocreate'))
            end
        end

    end
end
