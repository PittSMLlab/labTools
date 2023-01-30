%% Load some data:
mList={'TA','PER','SOL','MG','LG','SEMT','SEMB','BF','VM','VL','RF','HIP','GLU','TFL'};
mList=mList(end:-1:1);
labels=[strcat('R',mList) strcat('L',mList)];
labels1=[strcat('F',mList) strcat('S',mList)];
ts=expData.data{6}.procEMGData.renameLabels(labels1,labels).getDataAsTS(labels);
e=expData.data{6}.gaitEvents;
%From here on we assume there is a TS loaded on ts, and events on e
ts2=expData.data{4}.procEMGData.renameLabels(labels1,labels).getDataAsTS(labels);
e2=expData.data{4}.gaitEvents;

%% Discretize timeseries:
eventLabel={'LHS','RTO','RHS','LTO'};
N=[2,4,2,4];
[DTS,bad]=ts.discretize(e,eventLabel,N);
[DTS2,bad]=ts2.discretize(e2,eventLabel,N);

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