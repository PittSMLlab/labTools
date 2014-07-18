function [equalizedEMG,weights] = equalizeMuscleActivity(strides,M,weights,emgList)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
%INPUT: 
%strides needs to be a cell array of strideData objects!.
%M is the number of samples for the time-normalized data.


%% Equalize EMG activity of good steps, timeNormalize them & save in matrix to be factorized (synergy analysis)!
    
    th=10;
    %Construct matrices for data
    NL=length(strides);
    for i=1:NL
        aux=strides{i}.procEMGData;
        LprocEMG(:,:,i)=aux.resampleN(M).getDataAsVector(emgList);
    end
    
    %Find mean, median, std & check for abnormal EMG activity
    meanL=mean(LprocEMG,3);
    medianL=median(LprocEMG,3);
    stdL=std(LprocEMG,0,3);
    stdL=max(stdL,.2);

    %Discard abnormal steps & compute equalizing weights
    auxL=(LprocEMG-repmat(meanL,[1,1,NL]))./repmat(stdL,[1,1,NL]);
    newBadL=any(sum(auxL>th,1)>5,2);
    LprocEMG=LprocEMG(:,:,~newBadL);
    disp(['Discarded ' num2str(sum(newBadL)) ' steps for unusual EMG activity'])

    
    %If data is baseline, compute normalization coefficients (gains).
    if nargin<3 || isempty(weights)
        wL=columnNorm(columnNorm(LprocEMG,2,3),2,1); %Shouldn't this be affected by the number of steps that we actually have? (sometime there are less than N)
    else
        wL=weights;
    end
    
    %Equalize data
    finalNL=size(LprocEMG,3);
    LprocEMG=LprocEMG./repmat(wL,[M,1,finalNL]);


weights=wL;
equalizedEMG=(LprocEMG).*(LprocEMG>=0); %Negatives samples may ocurr because of the interpolation, getting rid of that

end

