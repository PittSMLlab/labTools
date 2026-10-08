function [D,sD,meanPos,biasPos] = createZeroModel(inputData)
%CREATEZEROMODEL Build a naive-Bayes "zero model" of marker distances.
%
%   [D,sD,meanPos,biasPos] = CREATEZEROMODEL(inputData) models each
% pairwise marker distance as an independent Gaussian: D holds the median
% distance over frames and sD a robust standard deviation (1.4826 times
% the median absolute deviation). meanPos is the median marker position.
% When biasPos is requested, every frame is reconstructed with
% GETBESTRECONSFROMZEROMODEL and biasPos is the mean difference between
% the reconstructed and the measured positions; otherwise it is zeros.
%
% Inputs:
%   inputData - N x 3 x M positions, or an orientedLabTimeSeries (its
%               oriented data is used). A char (c3d file name) is not
%               implemented.
%
% Outputs:
%   D       - N x N median pairwise distances
%   sD      - N x N robust standard deviations of the distances
%   meanPos - N x 3 median marker positions
%   biasPos - N x 3 mean reconstruction bias (zeros when not requested)
%
% Toolbox Dependencies: Statistics and Machine Learning Toolbox (mad)
%
% See also DETERMINELIKELIHOODFROMZEROMODEL, GETBESTRECONSFROMZEROMODEL.

if isa(inputData,'char') %Assume it is the name of a .c3d file
    %Load c3d using btk, to be done
    %Assume it is a timeseries containing 3D data
elseif isa(inputData,'orientedLabTimeSeries')
    X = inputData.getOrientedData;
else %Assume it is a Nx3xM matrix
    X = inputData;
end

madToSigma = 1.4826; % sigma/MAD ratio of a normal distribution
[N,dim,M] = size(X);
dist = nan(N,N,M);
for fr = 1:M
    dist(:,:,fr) = computeDistanceMatrix(X(:,:,fr));
end



%D=trimmean(dist,10,'round',3); %Mean across 3rd dim, ...
%    trimming 10% of extreme values
D  = median(dist, 3, 'omitnan');
%Computes the median absolute deviation, as a more robust estimation of
%std() when outliers are present. madToSigma is the factor between sigma
%and mad in a normal dist
sD = madToSigma*mad(dist,1,3);


meanPos = median(inputData, 3, 'omitnan');

if nargout > 3
    altPos = nan(size(inputData));
    for fr = 1:size(inputData,3)
        altPos(:,:,fr) = getBestReconsFromZeroModel(inputData(:,:,fr),D, ...
            sD,meanPos);
    end
    biasPos = mean(altPos-inputData, 3, 'omitnan');
else
    biasPos = zeros(N,dim);
end

end

