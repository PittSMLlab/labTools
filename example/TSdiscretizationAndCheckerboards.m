%TSDISCRETIZATIONANDCHECKERBOARDS Example: discretize and align time series; plot EMG checkerboards.
%
%   Demonstrates labTimeSeries discretization, stride alignment, and
% checkerboard plotting for EMG data. Assumes 'expData' exists in the
% workspace with procEMGData and gaitEvents on trials 4 and 6.

%% Load EMG data and events
mList = {'TA', 'PER', 'SOL', 'MG', 'LG', 'SEMT', 'SEMB', 'BF', ...
    'VM', 'VL', 'RF', 'HIP', 'GLU', 'TFL'};
mList   = mList(end:-1:1);
labels  = [strcat('R', mList) strcat('L', mList)];
labels1 = [strcat('F', mList) strcat('S', mList)];
ts  = expData.data{6}.procEMGData ...
    .renameLabels(labels1, labels).getDataAsTS(labels);
e   = expData.data{6}.gaitEvents;
ts2 = expData.data{4}.procEMGData ...
    .renameLabels(labels1, labels).getDataAsTS(labels);
e2  = expData.data{4}.gaitEvents;

%% Discretize time series into strides
eventLabel = {'LHS', 'RTO', 'RHS', 'LTO'};
N = [2, 4, 2, 4];
[DTS, bad]  = ts.discretize(e, eventLabel, N);
[DTS2, bad] = ts2.discretize(e2, eventLabel, N);

%% Align time series instead
N = [16, 48, 16, 48] * 2;
[DTS, bad]  = ts.align(e, eventLabel, N);
[DTS2, bad] = ts2.align(e2, eventLabel, N);

%% Plot checkerboard
DTS.plotCheckerboard()

%% Normalize to DTS2 mean and replot
b = max(DTS2.mean.Data);

DTS.Data  = DTS.Data ./ b;
DTS2.Data = DTS2.Data ./ b;

DTS.plotCheckerboard()
DTS2.plotCheckerboard()

%% Plot difference checkerboard
DTS_ = DTS - DTS2.mean;
DTS_.plotCheckerboard()
