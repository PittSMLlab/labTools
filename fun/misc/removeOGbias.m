function newData = removeOGbias(adaptData,OGtrials,OGbaseTrials)
%Over ground baseline data are ordered based on where the subject was
%located in the lab during each particular gait cycle. The data is then
%characterized spatially and a bias is removed form all overground data
%taking spatial dependancies into account.

labels=adaptData.data.labels;

%seperate data based on walking direction
baseOG1=[];
baseOG2=[];
baseData=adaptData.getParamInTrial(labels,OGbaseTrials);
baseHipVel=adaptData.getParamInTrial('direction',OGbaseTrials);
baseHipPos=adaptData.getParamInTrial('hipPos',OGbaseTrials);
for i=1:size(baseData,1)
    if baseHipVel(i)<0
        baseOG1 = [baseOG1; i baseHipPos(i) baseData(i,:)];
    else
        baseOG2 = [baseOG2; i baseHipPos(i) baseData(i,:)];
    end
end
allOG1=[];
allOG2=[];
[allData,inds]=adaptData.getParamInTrial(labels,OGtrials);
allHipVel=adaptData.getParamInTrial('direction',OGtrials);
allHipPos=adaptData.getParamInTrial('hipPos',OGtrials);
for i=1:size(allData,1)
    if allHipVel(i)<0
        allOG1 = [allOG1; i allHipPos(i) allData(i,:)];
    else
        allOG2 = [allOG2; i allHipPos(i) allData(i,:)];
    end
end

%Modal baseline tendency
baseOG1=sortrows(baseOG1,2); %ordered based on hip pos
baseOG1Fit=bin_dataV1(baseOG1,5); %runnning average of 5 data points
baseOG2=sortrows(baseOG2,2);
baseOG2Fit=bin_dataV1(baseOG2,5);

for i=1:size(allOG1,1)
    [~, ind]=min(abs(baseOG1Fit(:,2)-allOG1(i,2)));%find Fit point that is closest to data point i spatially
    bias=baseOG1Fit(ind,:);
    allOG1(i,3:end)=allOG1(i,3:end)-bias(3:end); %do not remove bias from time index or position (hence '3:end')
end
for i=1:size(allOG2,1)
    [~, ind]=min(abs(baseOG2Fit(:,2)-allOG2(i,2)));
    bias=baseOG2Fit(ind,:);
    allOG2(i,3:end)=allOG2(i,3:end)-bias(3:end);
end
newOG=sortrows([allOG1; allOG2],1); %re-order based on time points
newData(inds,:)=newOG(:,3:end); %first two columns are just for book keeping, do not get saved.

end
