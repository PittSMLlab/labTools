%% Load
mList={'TA','PER','SOL','MG','LG','SEMT','SEMB','BF','VM','VL','RF','ADM','HIP','GLU','TFL'};
labels=[strcat('R',mList) strcat('L',mList)];
ts=allEMG{1,4}.getDataAsTS(labels);
e=allEvents{1,4};
%From here on we assume there is a TS loaded on ts, and events on e
ts2=allEMG{1,1}.getDataAsTS(labels);
e2=allEvents{1,1};

%% Discretize timeseries:
eventLabel={'FHS','STO','SHS','FTO'};
N=[2,4,2,4];
[DTS,bad]=ts.discretize(e,eventLabel,N);
[DTS2,bad]=ts2.discretize(e2,eventLabel,N);

%% Plot a checkerboard:
DTS.plotCheckerboard

%% Normalize (wrt mean of DTS2), and do checkerboard again:
b=max(DTS2.mean.Data);
DTS.Data=DTS.Data./b;
DTS2.Data=DTS2.Data./b;

DTS.plotCheckerboard
DTS2.plotCheckerboard

%% Checkerboard of difference:
DTS_=DTS-DTS2.mean;
DTS_.plotCheckerboard