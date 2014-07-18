%Test of FactorizedMatrix class
clearvars

%% Example 1: normal 2D matrix
original=abs(randn(100,5));
[dim1vectors,dim2vectors]=nnmf(original,3);
factMethod='NNMF';
name='TestFactMatrix1';
this=FactorizedMatrix(original,dim1vectors,dim2vectors,factMethod,name) %Last two are optional
origDim=this.originalDimension
matSize=this.matrixSize
redDim=this.reducedDimension
factMat=this.factorizedMatrix;
errorMat=this.errorMatrix;
errNorm=this.errorNorm('fro')
percErr=this.percentError('fro')
errPerCol=this.errorNormPerColumn(2);
errPerRow=this.errorNormPerRow(2);
percErrC=this.percentErrorPerColumn(2);
percErrR=this.percentErrorPerRow(2);
newThis=this.transpose


%% Example 2: 3D matrix
original=abs(randn(9,256,2));
k=5;
[dim1vectors,dim2vectors]=nnmf(original(:,:),k);
factMethod='NNMF';
name='TestFactMatrix2';
this=FactorizedMatrix(original,dim1vectors,reshape(dim2vectors,[k,size(original,2),size(original,3)]),factMethod,name) %Last two are optional
origDim=this.originalDimension
matSize=this.matrixSize
redDim=this.reducedDimension
factMat=this.factorizedMatrix;
errorMat=this.errorMatrix;
errNorm=this.errorNorm('fro')
percErr=this.percentError('fro')
errPerCol=this.errorNormPerColumn(2);
errPerRow=this.errorNormPerRow(2);
percErrC=this.percentErrorPerColumn(2);
percErrR=this.percentErrorPerRow(2);
newThis=this.transpose %Should throw warning

%% Example 3: 5D matrix

original=abs(randn(10,8,9,256,2));
factMethod='Fake';
name='TestFactMatrix3';
this=FactorizedMatrix(original,abs(randn(5,10,8,9)),abs(randn(5,256,2)),factMethod,name) %Last two are optional
%Alt:
this=FactorizedMatrix.factorize(original,3,'nnmf',5)
origDim=this.originalDimension
matSize=this.matrixSize
redDim=this.reducedDimension
factMat=this.factorizedMatrix;
errorMat=this.errorMatrix;
errNorm=this.errorNorm('fro')
percErr=this.percentError('fro')
errPerCol=this.errorNormPerColumn(2);
errPerRow=this.errorNormPerRow(2);
percErrC=this.percentErrorPerColumn(2);
percErrR=this.percentErrorPerRow(2);
newThis=this.transpose %Should throw waringn