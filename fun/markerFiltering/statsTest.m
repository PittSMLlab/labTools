%% Load some file with marker data

%load()
md=expData.data{10}.markerData;
labs={'RHIP','LHIP','LANK','RANK'};
labs={'LANK','RANK'}
dd=md.getOrientedData(labs);
clear allX allV expData

%% Get some stats:
%Model 1): static (v=0 prediction)
x=dd;
s1=size(x,2);
s2=size(x,3);
x_1=cat(1,zeros(1,s1,s2),x(1:end-1,:,:));
x_2=cat(1,zeros(1,s1,s2),x_1(1:end-1,:,:));
x_3=cat(1,zeros(1,s1,s2),x_2(1:end-1,:,:));
v=(x_1-x_2)/md.sampPeriod;
v_1=cat(1,zeros(1,s1,s2),v(1:end-1,:,:));
v_2=cat(1,zeros(1,s1,s2),v_1(1:end-1,:,:));
a=(v-v_1)/md.sampPeriod;
a=.5*(v-v_2)/md.sampPeriod; %more robust estimator of a




%% Model 3: same as 2, but with temporal exponential discounting of velocity
N=150;
Xhist=x;
tau=20;
lag=1;
clear all*
for mode=[1:3]

    allX{mode}=nan(s1*s2,N);
    allV{mode}=nan(s1*s2,N);
    allXm{mode}=nan(s1*s2,N);
    allVm{mode}=nan(s1*s2,N);

    for n=1:N
        if mode<=3
            [nextX,meanV] = predictv2(x,n,mode,tau,lag);
            errv=diff(Xhist(n:end,:)) -(nextX(1:end-n,:)-meanV(1:end-n,:)); 
        else
            [nextX,meanV] = predict(x,n,mode-3,tau,lag);
            errv=diff(Xhist(n:end,:)) -meanV(1:end-n,:); 
        end
        errx=Xhist(n+2:end,:)-nextX(2:end-n,:); 
        sdx=nanstd(errx);
        allX{mode}(:,n)=sdx(:);
        allXm{mode}(:,n)=nanmean(errx);

        sdv=nanstd(errv(N-n+1:end,:,:));
        allV{mode}(:,n)=sdv(:);
        allVm{mode}(:,n)=nanmean(errv(:,:));
    end
end

%%
close all
clear p
figure;
for j=1:3
    for k=1:length(allX)
        if ~isempty(allX{k})
        switch k
            case 1
                cc=[1 0 0];
            case 2
                cc=[0 1 0];
            case 3
                cc=[0 0 1];
            otherwise
                cc=.7*ones(1,3);
        end
            
        subplot(3,2,j*2-1)
        hold on
            switch j
                case 1
                    title('X estim')
                case 2
                    title('Y estim')
                case 3
                    title('Z estim')
            end
        set(gca,'YScale','log')
        set(gca,'XScale','log')
        set(gca,'XLim',[0 150])
        auxX=bsxfun(@rdivide,allX{k}(j:3:end,:).^2,[1:N]);
        auxV=allV{k}(j:3:end,:).^2;
        auxXm=allXm{k}(j:3:end,:);
        auxVm=allVm{k}(j:3:end,:);
        auxL=md.labels(j:3:end);
        plot(1:N,nanmean(auxX,1),'.','Color',cc)
        %plot(1:N,nanmean(abs(auxXm),1),'o','Color',cc)
        plot(1:N,auxX,'Color',cc)
        for i=1:size(auxX,1)
            text(N,auxX(i,end),labs(i),'Color',cc)
        end
        ylabel(['\sigma ^2 /N (mm^2/sample)'])
        grid on
        subplot(3,2,j*2)
        hold on
        switch j
            case 1
                title('vX estim')
            case 2
                title('vY estim')
            case 3
                title('vZ estim')
        end
        %set(gca,'YScale','log')
        set(gca,'XLim',[0 40])
        p(k)=plot(1:N,nanmean(auxV,1),'x','Color',cc);
        %plot(1:N,nanmean(abs(auxVm),1),'*','Color',cc)
        %plot(1:N,auxV,'Color',cc)
        for i=1:size(auxX,1)
            text(N,auxV(i,end),['v' labs{i}],'Color',cc)
        end
        ylabel(['\sigma^2 (mm^2/sample)'])
        grid on
        end
    end
end
%legend(p,'Constant model (v=0)','Linear dynamics (v=cte)',['v(T) discount , \tau=' num2str(tau) ', lag=' num2str(lag)],'a=cte')