classdef SynergyAnalysis
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        trainingFactorizations %cell array of length N, each containing a factorizedMatrix
        testingFactorizations %cell array of length N, each containing a factorizedMatrix
        muscleList
    end
    properties(Dependent)
       trainingResiduals %cell array of matrices, unnecessary?
       testingResiduals %cell array of matrices, unnecessary?
       synergySets %cell array of SynergySet, unnecessary?
       trainingData %Plain matrix, unnecessary?
       testingData %Plain matrix, unnecessary?
    end
    
    methods
        %Constructor
        function this=SynergyAnalysis(testingData,trainingData,muscleList,name,method)
            if nargin<5 || isempty(method)
                method='nnmf';
            end
            if nargin<4 || isempty(name)
                name='';
            end
            %Check that size of testingData and trainingData are the same
            
            %Dim 1 is time, dim 2 are steps, dim 3 are muscles
            for dim=1:size(trainingData,3)
                
                %Compute synergies from training data
                trainingFactorizations{dim}=FactorizedMatrix.factorize(trainingData,2,method,dim,[name '_trainingSet_dim' num2str(dim)]);
                %reshapedData=reshape(trainingData,[size(trainingData,1)*size(trainingData,2),size(trainingData,3)]);
                %[syns,coefs,~,~]=getSynergies(reshapedData,dim,5,'always');
                %reshapedCoefs=reshape(coefs',[dim,size(trainingData,1),size(trainingData,2)]);
                %trainingFactorizations{dim}=FactorizedSteppedData(trainingData,reshapedCoefs,syns,'NNMF',[name '_trainingSet_dim' num2str(dim)]);
                
                %Compute coefs from synergies and testing data
                reshapedData=reshape(testingData,[size(testingData,1)*size(testingData,2),size(testingData,3)]);
                [coefs] = SynergyAnalysis.coefExtrFromSyn(reshapedData,trainingFactorizations{dim}.dim2Vectors);
                reshapedCoefs=reshape(coefs,[dim,size(testingData,1),size(testingData,2)]);
                testingFactorizations{dim}=FactorizedMatrix(testingData,reshapedCoefs,trainingFactorizations{dim}.dim2Vectors,method,[name '_testingSet_dim' num2str(dim)]);
            end
            this.trainingFactorizations=trainingFactorizations;
            this.testingFactorizations=testingFactorizations;
            this.muscleList=muscleList;
        end
        
        %Misc IO
        function [testFactorization,trainFactorization]=getFactorization(this,dim) %Returns a single factorization, if dim is not given, returns the chosenDim factorization
            if nargin<2
                dim=this.chooseDim;
            end
            testFactorization=this.testFactorizations{dim};
            trainFactorization=this.testFactorizations{dim};
        end
        
        %Others
        function [randomStats] = getRandomDataReconstructionPerformance(this,randomMethod,factMethod)
            Nreps=50000;
            switch randomMethod
                case 'spectralMatch'
                    if strcmpi(factMethod,'nnmf')
                        disp('Cannot use NNMF with spectrally matched data since positivity constraints are not satisfied. Using uncentered PCA instead.')
                        factMethod='uncentPCA';
                    end
                    sizes=size(this.trainingFactorizations{1}.originalMatrix);
                    [mu,sigma,filter] = createUnstructuredParametersFromData(reshape(this.trainingFactorizations{1}.originalMatrix,prod(sizes(1:2)),sizes(3)));
                    switch factMethod
                        case 'pca'
                            centering=true;
                        case 'uncentPCA'
                            centering=false;
                        otherwise
                            throw(MException('SynAnalysisRandomRec:UnrecognizedFactMethod','Unrecognized method for factorizing random data: options are pca, uncentPCA and nnmf.'))
                    end
                    [cumEigPdf,margEigPdf,totalVarPdf,overexplanationPdf,meanPdf] = empiricPCAEigDistributionsFiltered(mu,sigma,prod(sizes(1:2)),Nreps,filter,[],'normal',true,centering);
                    
                case 'timeShift'
                    switch factMethod
                        case 'nnmf'
                            Nreps=10;
                            sizes=size(this.trainingFactorizations{1}.originalMatrix);
                            [cumEigPdf,margEigPdf,totalVarPdf,overexplanationPdf,meanPdf] = empiricNNMFEigDistributionsTimeShifted(reshape(this.trainingFactorizations{1}.originalMatrix,prod(sizes(1:2)),sizes(3)),Nreps);
                        case 'pca'
                            centering=true;
                            sizes=size(this.trainingFactorizations{1}.originalMatrix);
                            [cumEigPdf,margEigPdf,totalVarPdf,overexplanationPdf,meanPdf] = empiricPCAEigDistributionsTimeShifted(reshape(this.trainingFactorizations{1}.originalMatrix,prod(sizes(1:2)),sizes(3)),Nreps,centering);
                        case 'uncentPCA'
                            centering=false;
                            sizes=size(this.trainingFactorizations{1}.originalMatrix);
                            [cumEigPdf,margEigPdf,totalVarPdf,overexplanationPdf,meanPdf] = empiricPCAEigDistributionsTimeShifted(reshape(this.trainingFactorizations{1}.originalMatrix,prod(sizes(1:2)),sizes(3)),Nreps,centering);
                        otherwise
                            throw(MException('SynAnalysisRandomRec:UnrecognizedFactMethod','Unrecognized method for factorizing random data: options are pca, uncentPCA and nnmf.'))
                    end
                otherwise
                    throw(MException('SynAnalysisRandomRec:UnrecognizedRandomMethod','Unrecognized method for generating random data: options are timeShift and spectralMatch'))
            end
            randomStats.cumEigPdf=cumEigPdf; %Cumulative eigenvalues distribution
            randomStats.margEigPdf=margEigPdf; %Marginal (individual) eigenvalues distribution
            randomStats.totalVarPdf=totalVarPdf; %Distribution of the overall variance of the data
            randomStats.overexplanationPdf=overexplanationPdf; %Distribution of how much variance is being explained by each dimension, normalized by the minimum variance it could explain given the previous dimensions
            randomStats.meanPdf=meanPdf; %Distribution of data mean
        end
                                  
        dim=chooseDim(this)
        
        assessDimensionality(this)
        
        %Display
        function [figHandle,plotHandles1,plotHandles2]=plot(this,plotHandles1,plotHandles2,colors,dim)
            %Plotting the testing data only
           if nargin<5
               dim=this.chooseDim;
           end
           if nargin<4
               colors=[];
           end
           if nargin<3
               plotHandles1=[];
               plotHandles2=[];
           end
           [figHandle,plotHandles1,plotHandles2]=plot(this.testingFactorizations{dim},plotHandles1,plotHandles2,colors);
           for i=1:length(plotHandles1)
               subplot(plotHandles1(i))
               set(plotHandles1(i),'XTick',1:this.testingFactorizations{dim}.matrixSize(end))
               set(plotHandles1(i),'XTickLabels',this.muscleList)
           end
        end
        
        %Getters for dependent properties
        
        function trainRes=get.trainingResiduals(this)
            for i=1:length(this.trainingFactorizations)
               trainRes{i}=this.trainingFactorizations{i}.errorMatrix; 
            end
        end
        
        function testRes=get.testingResiduals(this)
            for i=1:length(this.testingFactorizations)
               testRes{i}=this.testingFactorizations{i}.errorMatrix; 
            end
        end
        
        function trainData=get.trainingData(this)
            trainData=this.trainingFactorizations{1}.originalMatrix;
        end
        
        function testData=get.testingData(this)
            testData=this.testingFactorizations{1}.originalMatrix;
        end
        
        function ss=get.synergySets(this)
            for i=1:length(this.trainingFactorizations)
               ss{i}=this.trainingFactorizations{i}.dim2Vectors; 
            end
        end
        
    end
    
    methods(Static,Access=private)
        
       function [dim1Vectors] = coefExtrFromSyn(data,dim2Vectors)
            %solves the least squares problem data=syn*act; subject to the
            %non-negativity of the activations.

            opts= optimset('display','off','TolFun',.0001/size(data,2)^2,'TolX',.0001);

            poolFlag=0;
            matlabpool size;
            if (ans==0)
                matlabpool open
                poolFlag=1;
            end

            coefs=[];
            parfor i=1:size(data,1)
                x0=ones(size(dim2Vectors,1),1);
                coefs(:,i) = lsqnonneg(dim2Vectors',data(i,:)',opts);
            end
            dim1Vectors=coefs;
            if poolFlag==1
                matlabpool close
            end
       end
        
    end
end

