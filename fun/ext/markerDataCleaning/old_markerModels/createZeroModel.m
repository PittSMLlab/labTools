function [D,sD,meanPos,biasPos] = createZeroModel(inputData)
%UNTITLED6 Summary of this function goes here
%   Detailed explanation goes here

if isa(inputData,'char') %Assume it is the name of a .c3d file
    %Load c3d using btk, to be done
    %Assume it is a timeseries containing 3D data
elseif isa(inputData,'orientedLabTimeSeries')
    X = inputData.getOrientedData;
else %Assume it is a Nx3xM matrix
    X = inputData;
end

[N,dim,M] = size(X);
dist = nan(N,N,M);
for fr = 1:M
    dist(:,:,fr) = computeDistanceMatrix(X(:,:,fr));
end



%D=trimmean(dist,10,'round',3); %Mean across 3rd dim, ...
%    trimming 10% of extreme values
D  = median(dist, 3, 'omitnan');
%Computes the median absolute deviation, as a more robust estimation of
%std() when outliers are present. 1.48 is the factor between sigma and mad
%in a normal dist
sD = 1.4826*mad(dist,1,3);


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

