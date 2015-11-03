classdef SynergyAnalysis
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        trainingFactorizations={}; %cell array of length N, each containing a factorizedMatrix
        testingFactorizations={}; %cell array cell arrays of length N, each containing a factorizedMatrix
        muscleList={};
        trainingData={}; %Plain matrix, unnecessary?
        testingData={}; %Plain matrix, unnecessary?
    end
    properties(Dependent)
       trainingResiduals %cell array of matrices, unnecessary?
       testingResiduals %cell array of matrices, unnecessary?
       synergySets %cell array of SynergySet, unnecessary?
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
            
            %Dim 1 is time, dim 2 are steps, dim 3 are muscles (muscles
            %have to be in the last dimension for the factorization to be
            %done properly with this code).
            for dim=1:size(trainingData,3) %Factorizing from 1 to Nmuscles
                %Compute synergies from training data
                trainingFactorizations{dim}=FactorizedMatrix.factorize(trainingData,2,method,dim,[name '_trainingSet_dim' num2str(dim)]); %The second argument has to be the dimension corresponding to the muscles dim-1.
            end
            this.trainingFactorizations=trainingFactorizations;
            this.muscleList=muscleList;
            this.trainingData=trainingData;
            %Compute coefs from synergies and testing data
            if ~isempty(testingData)
                this=factorizeNewTestingData(this,testingData,method,name);
            end
        end
        
        %Extract coefs for testingData
        function newThis=factorizeNewTestingData(this,testingData,method,name)
            if nargin<4 || isempty(name)
                name='';
            end
           %Check that new testingData and  have compatible
           %dimensions
           %DOXY
           
           %
           N=length(this.testingFactorizations);
           for dim=1:size(this.trainingData,3) %Factorizing from 1 to Nmuscles
                %Compute coefs from synergies and testing data
                reshapedData=reshape(testingData,[size(testingData,1)*size(testingData,2),size(testingData,3)]);
                [coefs] = SynergyAnalysis.coefExtrFromSyn(reshapedData,this.trainingFactorizations{dim}.dim2Vectors,method);
                reshapedCoefs=reshape(coefs,[dim,size(testingData,1),size(testingData,2)]);
                testFactorizations{dim}=FactorizedMatrix(size(testingData),reshapedCoefs,this.trainingFactorizations{dim}.dim2Vectors,method,[name '_dim' num2str(dim)]);
            end
            this.testingFactorizations{N+1}=testFactorizations;
            this.testingData{N+1}=testingData;
            newThis=this;
        end
        
        %Misc IO
        function [testFactorization,trainFactorization]=getFactorization(this,dim) %Returns a single factorization, if dim is not given, returns the chosenDim factorization
            if nargin<2
                dim=this.chooseDim;
            end
            testFactorization=this.testFactorizations{1}{dim};
            trainFactorization=this.trainFactorizations{dim};
        end
        
        %Others
        function [cumEigPdf,margEigPdf,totalVarPdf,overexplanationPdf,meanPdf] = getRandomDataReconstructionPerformance(this,randomMethod,factMethod)
            Nreps=10000;
            switch randomMethod
                case 'spectralMatch'
                    if strcmpi(factMethod,'nnmf')
                        disp('Cannot use NNMF with spectrally matched data since positivity constraints are not satisfied. Using uncentered PCA instead.')
                        factMethod='uncentPCA';
                    end
                    sizes=size(this.trainingData);
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
                            Nreps=200;
                            sizes=size(this.trainingData);
                            [cumEigPdf,margEigPdf,totalVarPdf,overexplanationPdf,meanPdf] = empiricNNMFEigDistributionsTimeShifted(reshape(this.trainingFactorizations{1}.originalMatrix,prod(sizes(1:2)),sizes(3)),Nreps);
                        case 'pca'
                            centering=true;
                            sizes=size(this.trainingData);
                            [cumEigPdf,margEigPdf,totalVarPdf,overexplanationPdf,meanPdf] = empiricPCAEigDistributionsTimeShifted(reshape(this.trainingFactorizations{1}.originalMatrix,prod(sizes(1:2)),sizes(3)),Nreps,centering);
                        case 'uncentPCA'
                            centering=false;
                            sizes=size(this.trainingData);
                            [cumEigPdf,margEigPdf,totalVarPdf,overexplanationPdf,meanPdf] = empiricPCAEigDistributionsTimeShifted(reshape(this.trainingFactorizations{1}.originalMatrix,prod(sizes(1:2)),sizes(3)),Nreps,centering);
                        otherwise
                            throw(MException('SynAnalysisRandomRec:UnrecognizedFactMethod','Unrecognized method for factorizing random data: options are pca, uncentPCA and nnmf.'))
                    end
                otherwise
                    throw(MException('SynAnalysisRandomRec:UnrecognizedRandomMethod','Unrecognized method for generating random data: options are timeShift and spectralMatch'))
            end
        end
                                  
        dim=chooseDim(this) %TODO
        
        function [errTrain,errTest,fh]=assessDimensionality(this,plotFlag,fh,names)
            if nargin <4 || isempty(names)
                names='';
            end
            %First: find error norm as a function of dimension for training and testing
            %data

            auxTrain=norm(this.trainingData(:,:),'fro');
            auxTest=norm(this.testingData(:,:),'fro');
            for i=1:this.testingFactorizations{1}.originalDimension
                eM=this.trainingFactorizations{i}.getErrorMatrix(this.trainingData);
                errTrain(i)=norm(eM(:,:),'fro')/auxTrain;
                eM=this.testingFactorizations{i}.getErrorMatrix(this.testingData);
                errTest(i)=norm(eM(:,:),'fro')/auxTest;
            end

            if nargin<2 || (~isempty(plotFlag) && plotFlag~=0)
                if nargin>2
                    figure(fh)
                else
                    fh=figure;
                end
            hold on
            p=plot(errTrain.^2,'DisplayName',[names 'Training Data'],'LineWidth',2);
            plot(errTest.^2,'--','DisplayName',[names 'Testing Data'],'LineWidth',2,'Color',get(p,'Color'))
            xlabel('Dims.')
            ylabel('Normalized reconstruction error squared')
            hold off
            p=get(gca,'Children');
            legend(p);
            end


        end
        
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
               set(plotHandles1(i),'XTick',1:this.testingFactorizations{dim}.matrixSize(end),'XTickLabels',this.muscleList,'XTickLabelRotation',90)
               axis tight
           end
        end
        
        %Getters for dependent properties
        
        function trainRes=get.trainingResiduals(this)
            for i=1:length(this.trainingFactorizations)
               trainRes{i}=this.trainingFactorizations{i}.errorMatrix(this.trainingData); 
            end
        end
        
        function testRes=get.testingResiduals(this)
            for j=1:length(this.testingFactorizations)
                for i=1:length(this.testingFactorizations{1})
                   testRes{j}{i}=this.testingFactorizations{j}{i}.errorMatrix(this.testingData); 
                end
            end
        end

        function ss=get.synergySets(this)
            for i=1:length(this.trainingFactorizations)
               ss{i}=this.trainingFactorizations{i}.dim2Vectors; 
            end
        end
        
    end
    
    methods(Static)
        
       function [dim1Vectors] = coefExtrFromSyn(data,dim2Vectors,method)
            %solves the least squares problem data=syn*act; subject to the
            %non-negativity of the activations.

            opts= optimset('display','off','TolFun',1e-4/size(data,2)^2,'TolX',1e-4);

            poolFlag=0;
            if isempty(gcp('nocreate'))
                parpool
                poolFlag=1;
            end

            coefs=[];
            switch method
                case 'nnmf'
                    parfor i=1:size(data,1)
                        x0=ones(size(dim2Vectors,1),1);
                        coefs(:,i) = lsqnonneg(dim2Vectors',data(i,:)',opts);
                    end
                case 'pca'
                    coefs=(data/dim2Vectors)';
                    %Check minimum convergence (if using N dimensions):
                    if (norm(data-coefs'*dim2Vectors,'fro')/norm(data,'fro'))>(1-size(coefs,1)/size(data,2)) %Checking for reconstruction levels to be at least random reconstruction expected values
                        warning('SynegyAnalysis:coefExtrFromSyn','Residuals from lsq is higher than expected from random reconstructions, there is a probable issue with algorithm convergence.')
                    end
                otherwise
                    error('SynergyAnalysis:coefExtrFromSyn',['Not implemented for the desired method: ' method])
            end
            
            dim1Vectors=coefs;
            if poolFlag==1
                delete(gcp('nocreate'))
            end
       end
        
    end
end
