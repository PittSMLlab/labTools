%% Load
mList={'TA','PER','SOL','MG','LG','SEMT','SEMB','BF','VM','VL','RF','ADM','HIP','GLU','TFL'};
mList=mList(end:-1:1);
labels=[strcat('R',mList) strcat('L',mList)];
labels1=[strcat('F',mList) strcat('S',mList)];
ts=allEMG{1,4}.renameLabels(labels1,labels).getDataAsTS(labels);
e=allEvents{1,4};
%From here on we assume there is a TS loaded on ts, and events on e
ts2=allEMG{1,3}.renameLabels(labels1,labels).getDataAsTS(labels);
e2=allEvents{1,3};

%% Discretize timeseries:
eventLabel={'FHS','STO','SHS','FTO'};
N=[2,4,2,4];
%[DTS,bad]=ts.discretize(e,eventLabel,N);
%[DTS2,bad]=ts2.discretize(e2,eventLabel,N);

%% Align instead:
N=[16,48,16,48]*2;
[DTS,bad]=ts.align(e,eventLabel,N);
[DTS2,bad]=ts2.align(e2,eventLabel,N);

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