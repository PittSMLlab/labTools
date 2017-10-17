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

%% Learn skeleton from the data from 200 to 220 secs
%This should be reliably labeled data
%Learn skeleton doesn't work well with OG data
[m,R] = sk3Dlearn(pos(:,:,20000:22000));
[md,Rd] = skDistlearn(pos(:,:,20000:22000));

%% Check that the skeleton detects the bad marker:
[scores] = sk3Ddetect(pos,m,R);
[scoresD] = skDistdetect(pos,md,Rd);
figure; plot(scores(5,:)'); legend(labels); hold on; plot(scoresD(5,:)');

%% Enforce skeleton to fix missing marker: 
[N,D,M]=size(pos);

%Uncertainty matrix:
P=.1*eye(N*D);

%To simulate an absolutely missing LANK marker:
idx=find(strcmp(labels,'LANK'));
pos2=pos;
pos2(idx,:,:)=NaN;

%Find new marker positions:
M1=M;
xMLE=nan(N*D,M1);
xMLEd=nan(N*D,M1);
for i=1:M1
    [xMLE(:,i)] = sk3Denforce(pos2(:,:,i),P,m(:),R+1e3*abs(max(R(:)))*[eye(N) eye(N) eye(N)]);
    [xMLEd(:,i)] = skDistenforce(pos2(:,:,i),P,md(:),Rd+1e3*abs(max(Rd(:)))*eye(N));
end
xMLE=reshape(xMLE,N,D,M1);
%xMLEd=reshape(xMLEd,N,D,M1);
%% Show old & new scores:
[correctedScores] = sk3Ddetect(xMLE,m,R);
figure; plot(scores(5,:)); hold on; plot(correctedScores(5,:),'LineWidth',4);

%% Show old & new positions:
pos(idx,:,1:10000)=NaN; %This are bad samples
figure;
for i=1:3
    subplot(3,3,3*(i-1)+[1:2])
    plot(squeeze(xMLE(idx,i,:)))
    hold on
    plot(squeeze(pos(idx,i,:)))
    if i==1
        title('Reconstruction values')
    elseif i==3
        xlabel('Time (s)')
    end
    ylabel([('x'+i-1) ' (mm)']);
    
    subplot(3,3,3*i)
    dd=squeeze(xMLE(idx,i,:)-pos(idx,i,:));
    histogram(dd,[-20:1:20])
    if i==1
        title('Histogram of errors')
    elseif i==3
        xlabel('Error (mm)')
    end
    hold on
    text(-19,1500,['\mu=' num2str(nanmean(dd),2)])
    text(-19,1000,['\sigma=' num2str(nanstd(dd),2)])
    text(-19,500,['m=' num2str(nanmedian(dd),2)])
end


%% Show old & new mean pos (notice change in LANK position!):
auxPos=nanmean(pos(:,:,1:M1),3);
auxNewPos=nanmean(xMLE(:,:,1:M1),3);
figure; plot3(auxPos(:,1),auxPos(:,2),auxPos(:,3),'x'); hold on; plot3(auxNewPos(:,1),auxNewPos(:,2),auxNewPos(:,3),'o'); axis equal

%% Compare


xMLE=reshape(xMLE,N,D,M);

err=xMLE-pos;
imagesc(mean(err,3))