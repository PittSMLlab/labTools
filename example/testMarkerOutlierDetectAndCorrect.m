%testSkeleton
%% Load data
load('./data/LI16_Trial9_expData.mat')
%This marker set is missing LANK during the first ~30secs of trial
labels={'LHIP' 'RHIP' 'LKNE' 'RKNE' 'LANK' 'RANK' 'LTOE' 'RTOE' 'LHEE' 'RHEE' 'RASIS' 'LASIS' 'RPSIS' 'LPSIS' 'RTHI' 'LTHI' 'RSHK' 'LSHNK'};
pos=LI16_Trial9_expData.markerData.getOrientedData(labels);
pos=permute(pos,[2,3,1]);
%% Gen dummy data
% pos=10*randn(54,5)*randn(5,1000) + randn(54,1000);
% pos=reshape(pos,18,3,1000);

%% Learn skeleton from the data from 90 to 190 secs
%This should be reliably labeled data
%Learn skeleton doesn't work well with OG data
[m,R] = sk3Dlearn(pos(:,:,9000:10000));

%% notice that pos(5,:,:) is nan for the first 7600 samples, need to substitute with 0's:
pos(isnan(pos(:)))=0; %Substituting missing markers

%% Check that the skeleton detects the bad marker:
[scores] = sk3Ddetect(pos,m,R);
figure; plot(scores'); legend(labels);

%% Enforce skeleton to fix missing marker: 
[N,D,M]=size(pos);

%Uncertainty matrix:
P=.1*eye(N*D);
for i=1:3
P(5+(i-1)*N,5+(i-1)*N)=1e9;
end
%P(:,5+[0:N:N*D-1])=1e5;

%Find new marker positions:
M1=200;
xMLE=nan(N*D,M1);
for i=1:M1
    [xMLE(:,i)] = sk3Denforce(pos(:,:,i),P,m(:),R+1e3*abs(max(R(:)))*[eye(N) eye(N) eye(N)]);
end
xMLE=reshape(xMLE,N,D,M1);

%% Show old & new scores:
figure; plot(scores'); hold on; plot(correctedScores(5,:),'LineWidth',4);
[correctedScores] = sk3Ddetect(xMLE,m,R);

%% Show old & new mean pos:
auxPos=mean(pos(:,:,1:M1),3);
auxNewPos=mean(xMLE(:,:,1:M1),3);
figure; plot3(auxPos(:,1),auxPos(:,2),auxPos(:,3),'x'); hold on; plot3(auxNewPos(:,1),auxNewPos(:,2),auxNewPos(:,3),'o');

%% Compare


xMLE=reshape(xMLE,N,D,M);

err=xMLE-pos;
imagesc(mean(err,3))