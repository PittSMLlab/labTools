function [markerLogL,totalLogL] = skDistdetect(data,m,R)
[N,d,M]=size(data);
[D] = computeDistanceMatrix(data); %Will be NxNxM
missing=squeeze(any(isnan(data),2));
clear data
D=D-m; %Subtracting mean
C=R+1e3*max(abs(R(:)))*eye(N);
auxScores=D.^2 ./C;
totalLogL=squeeze(nanmean(nanmean(nanmean(auxScores))));
%markerLogL=nan(N,M);
markerLogL=squeeze(nanmedian(reshape(auxScores,N,N,M),2));
%markerLogL=squeeze(mean(reshape(auxScores,N,N*d,M),2));
markerLogL(missing)=-10;

end
