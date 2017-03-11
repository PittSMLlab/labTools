%This script shows how to plot individual behavior within a group for a
%given subset of strides (e.g. last 40 of adaptation) or biographical
%parameters (e.g. age).

%Pre-req: a groupAdaptationData object needs to be loaded. Assuming its
%name is gAdaptData

fh=figure;
for i=1:9
    ph(i)=subplot(3,3,i);
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

%% Example 6: compare BASELINE behavior of one variable, to CHANGE in early post WRT to baseline
param={'netContributionNorm2'};
medianFlag=1; %MEan used by default
strideNo=[-40,20];
conds={'Base','Wash'};
exemptNo=5;
regFlag=1;
diffFlag=1;
gAdaptData.plotIndividuals(param,conds,strideNo,exemptNo,medianFlag,ph(6),regFlag,diffFlag);

%% Example 7: on unbiased data, compare after-effects to bias behavior (same as example 6, but from data in which bias has been removed!)
param={'netContributionNorm2','biasTMnetContributionNorm2'};
medianFlag=1; %Mean used by default
strideNo=[20];
conds={'Wash'};
exemptNo=5;
regFlag=1;
diffFlag=0;
%gAdaptData=gAdaptData.removeBias; %This is one way to remove bias
gAdaptData=gAdaptData.removeAltBias({'TM base'},-40,5,1,0); %This is an alt way to do it (faster), if we only care about TM trials, it is fine. Uses median of last 40 strides of TM base, exempting very last 5
gAdaptData.plotIndividuals(param,conds,strideNo,exemptNo,medianFlag,ph(7),regFlag,diffFlag);

%% Example 8: Fancy stuff: compare after-effects to change during adaptation (late minus early)
param={'netContributionNorm2','netContributionNorm2'};
medianFlag=1; %Mean used by default
strideNo=[-40,-40,20];
conds={'Base','Adap','Adap'};
exemptNo=5;
regFlag=1;
diffFlag=1;
gAdaptData.plotIndividuals(param,conds,strideNo,exemptNo,medianFlag,ph(8),regFlag,diffFlag);

%% Example 9: Fancier still: compare change during adaptation to other variables change during adaptation, by using removeAltBias in the call
param={'netContributionNorm2','stepTimeContributionNorm2'};
medianFlag=1; %Mean used by default
strideNo=[-40,-40];
conds={'Adap'};
exemptNo=5;
regFlag=1;
diffFlag=1;
gAdaptData=gAdaptData.removeAltBias({'Adap'},20,5,1,0); %This removes the median of the first 20 strides of adaptation, exempting the very first 5: everything will be with respect to early adaptation behavior
%Note that removeAltBias can be called successively and it acts in such a
%way that it is the same as only having made the last call
gAdaptData.plotIndividuals(param,conds,strideNo,exemptNo,medianFlag,ph(9),regFlag,diffFlag);

%% save fig
saveFig(fh,'./','plotIndividualsInGroup')