%This script shows how to plot individual behavior within a group for a
%given subset of strides (e.g. last 40 of adaptation) or biographical
%parameters (e.g. age).

%Pre-req: a groupAdaptationData object needs to be loaded. Assuming its
%name is gAdaptData

fh=figure;
for i=1:6
    ph(i)=subplot(2,3,i);
end

%% Example 1: compare a single parameter across conditions
param={'netContributionNorm2'};
medianFlag=[]; %MEan used by default
strideNo=[20,-40];
conds={'Wash','Adap'};
exemptNo=5;
regFlag=1;
gAdaptData.plotIndividuals(param,conds,strideNo,exemptNo,medianFlag,ph(1),regFlag);

%% Example 2: compare two parameters in the same set of strides
param={'netContributionNorm2','spatialContributionNorm2'};
medianFlag=[]; %MEan used by default
strideNo=[20];
conds={'Wash'};
exemptNo=5;
regFlag=1; %Regression flag
gAdaptData.plotIndividuals(param,conds,strideNo,exemptNo,medianFlag,ph(2),regFlag);

%% Example 3: compare parameter to biographical data
param={'netContributionNorm2','subage'};
medianFlag=[]; %MEan used by default
strideNo=[20];
conds={'Wash'};
exemptNo=5;
regFlag=1;
gAdaptData.plotIndividuals(param,conds,strideNo,exemptNo,medianFlag,ph(3),regFlag);

%% Example 4: overlaying two groups (assuming gAdaptData2 exists)
param={'netContributionNorm2','spatialContributionNorm2'};
medianFlag=[]; %MEan used by default
strideNo=[20];
conds={'Wash'};
exemptNo=5;
regFlag=1; %Regression flag
gAdaptData.plotIndividuals(param,conds,strideNo,exemptNo,medianFlag,ph(4),regFlag);
gAdaptData2.plotIndividuals(param,conds,strideNo,exemptNo,medianFlag,ph(4),regFlag);

%% Example 5: compare BASELINE behavior of one variable, to early post- of the same
param={'netContributionNorm2'};
medianFlag=1; %MEan used by default
strideNo=[-40,20];
conds={'Base','Wash'};
exemptNo=5;
regFlag=1;
diffFlag=0;
gAdaptData.plotIndividuals(param,conds,strideNo,exemptNo,medianFlag,ph(5),regFlag,diffFlag);

%% Example 6: compare BASELINE behavior of one variable, to CAHANGE in early post WRT to baseline
param={'netContributionNorm2'};
medianFlag=1; %MEan used by default
strideNo=[-40,20];
conds={'Base','Wash'};
exemptNo=5;
regFlag=1;
diffFlag=1;
gAdaptData.plotIndividuals(param,conds,strideNo,exemptNo,medianFlag,ph(6),regFlag,diffFlag);
%% save fig
saveFig(fh,'./','plotIndividualsInGroup')