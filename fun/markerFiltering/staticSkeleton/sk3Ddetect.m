function [markerLogL,totalLogL] = sk3Ddetect(data,m,R)
[N,d,M]=size(data);
[D] = computeDiffMatrix(data); %Will be NxdxNxM
clear data
D=permute(D,[1,3,2,4]); %NxNxdxM
R=reshape(R,N,N,d);
D=D-m; %Subtracting mean
C=R+1e3*max(abs(R(:)))*eye(N);
auxScores=D.^2 ./C;



totalLogL=squeeze(nanmean(nanmean(nanmean(auxScores))));
%markerLogL=nan(N,M);
markerLogL=squeeze(nanmedian(reshape(auxScores,N,N*d,M),2));
%markerLogL=squeeze(mean(reshape(auxScores,N,N*d,M),2));

end

