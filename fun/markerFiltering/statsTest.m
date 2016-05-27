%% Load some file with marker data

load()
md=expData.data{6}.markerData;
dd=md.getOrientedData;

%% Get some stats:
%Model 1): static (v=0 prediction)
figure
err=diff(dd);
hist(err,[-10:1:10])
std(err,[],1)
sd=nanstd(err,[],1);
mean(sd(:))
%% Model 2): v=cte based on previous samples, with constant sampling rate
x=dd;
v=cat(1,zeros(1,18,3),diff(dd)/md.sampPeriod);
figure
errx=diff(x)-v(1:end-1,:,:)*md.sampPeriod;
hist(errx,[-10:1:10])
sdx=nanstd(errx,[],1);
mean(sdx(:))
errv=diff(v)*md.sampPeriod;
figure
hist(errv,[-10:1:10])
sdv=nanstd(errv,[],1);
mean(sdv(:))