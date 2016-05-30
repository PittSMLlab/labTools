%% 
%load()
md=expData.data{10}.markerData;
labs={'RHIP','LHIP','LANK','RANK'};
dd=md.getOrientedData(labs);
d2=md.getOrientedData({'LASIS'});
d3=md.getOrientedData({'RTHI'});
clear allX allV expData

%% Generate random dataset
x=dd(1:10000,:,:);
%Drop markers
%10% drops
ii=randi(size(x,1),round(size(x,1)*.01),size(dd,2));
for i=1:size(dd,2)
    for k=1:size(ii,1)
x(ii(k,i)+[1:20],i,:)=nan;
    end
end

%Mislabel
for k=1:10 %10 intervals of mislabeling
    i1=randi([5 30]);
    i2=randi(size(x,1));
    x(i2+[1:i1],2,:)=d2(i2+[1:i1],1,:); %Mislabeling with LHIP LASIS
end

%Add noise
x=x+3*randn(size(x));

%% Do Kalman prediction
estimX=zeros(6,size(x,1),4);
covarX=nan(6,6,size(x,1),4);
tau=[10 10 25 25];
lag=1;
mode=3;
delay=1;

n=1;
qxy=n;
qz=min([.5*n 100]);
Qns{1}=diag([qxy qxy qz qxy qxy qz]); %For hips, which are slow moving
qxy=10*qxy;
qz=10*qz;
Qns{2}=diag([qxy qxy qz qxy qxy qz]); %For anks
%Initialize:
for i=1:4
estimX(1:3,1,i)=x(1,i,:);
covarX(:,:,1,i)=eye(6)*1e6;
end

for k=[1:4] %Over all markers
    for i=2:size(x,1)
        %Predict step:
        [nextX,nextPrevX,An,Qn] = predictv3(estimX(:,i-1,k)',delay,mode,tau(k));
        prediction=[nextX';nextPrevX'];
        Qn=Qns{ceil(k/2)}; %Ignoring Qn provided by predict
        predictionCovar=An*covarX(:,:,i-1,k)*An'+Qn;
        if k<3
            %Here I would like to put an upper bound on z-axis uncertainty
        end
        
        %Update:
        readX=squeeze(x(i,k,:));
        C=[eye(3) zeros(3)];
        R=eye(3)*100;
        
        %MAP estimation for mislabeling: %Idea for improving: use a
        %hand-labeled skeleton to get some stronger priors
        err=readX-C*prediction; 
        R1=eye(3)*1e6;
        L1= exp(-.5*err.*diag(R1).^(-1).*err)./sqrt(diag(R1));%Likelihood of observation given mislabeling, computed for EACH component independently
        R2=C*predictionCovar*C'+R;
        L2= exp(-.5*err.*diag(R2).^(-1).*err)./sqrt(diag(R2));%Likelihood of observation given mislabeling, computed for EACH component independently
        P=.1; %Prior for mislabeling
        pm= L1*P./(L1*P+ L2*(1-P)); %Posterior for mislabeling
        if any(pm>.5) %Mislabeling
            R=R1;
        elseif any(L1>L2) %No MAP mislabeling, but there is MLE mislabeling
           %R=100*diag(err.^2); 
           %R=3*C*predictionCovar*C'; %With this, each read is at most
        %considered in equal footing with prediction. If the read is good,
        %it is actually much more precise than that, but if it is bad, then
        %ir may be helpful to not be so trusting.
        end
        
        
        if ~any(isnan(readX))
            K=predictionCovar*C'*pinv(C*predictionCovar*C'+R);
            estimation=prediction + K*(readX - C*prediction); 
            estimationCovar=(eye(6) -K*C)*predictionCovar;
        else
            estimation=prediction;
            estimationCovar=predictionCovar;
        end
        
        %Store estimation:
        estimX(:,i,k)=estimation;
        covarX(:,:,i,k)=estimationCovar;
        
    end
end

%% Do some plots
close all
figure
for k=1:4
    subplot(2,2,k)
    hold on
    plot(squeeze(x(:,k,:)),'x'); %Plot original readings
    plot(estimX(1:3,:,k)','-.'); %Plot filtered
    for j=1:3
        aux=estimX(j,:,k)'+squeeze(sqrt(covarX(j,j,:,k)));
        aux1=estimX(j,:,k)'-squeeze(sqrt(covarX(j,j,:,k)));
       patch([1:size(x,1) size(x,1):-1:1],[aux; flipud(aux1)],.7*ones(1,3),'FaceAlpha',.5,'EdgeColor','none') 
    end
end