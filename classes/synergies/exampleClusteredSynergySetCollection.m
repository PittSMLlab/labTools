%EXAMPLECLUSTEREDSYNERGYSETCOLLECTION Clustered collection demo.
%
%   Creates a collection, assigns fake cluster indexes, builds the clustered
% collection, and plots it.
%
% Toolbox Dependencies: Statistics and Machine Learning Toolbox
%
% See also CLUSTEREDSYNERGYSETCOLLECTION, SYNERGYSETCOLLECTION.

clear s s2
%Create:
muscleList = {'TA','PER','SOL','MG','RF','VM','BF','TFL','GLU'};
content = {SynergySet(randn(3,9),muscleList), ...
    SynergySet(randn(4,9),muscleList),SynergySet(randn(6,9),muscleList);
    SynergySet(randn(4,9),muscleList),SynergySet(randn(3,9),muscleList), ...
    SynergySet(randn(3,9),muscleList);
    SynergySet(randn(3,9),muscleList),SynergySet(randn(3,9),muscleList), ...
    SynergySet(randn(3,9),muscleList);
    SynergySet(randn(3,9),muscleList),SynergySet(randn(3,9),muscleList), ...
    SynergySet(randn(3,9),muscleList);
    SynergySet(randn(3,9),muscleList),SynergySet(randn(3,9),muscleList), ...
    SynergySet(randn(3,9),muscleList)};

indexCats = {'Subject','Condition'};
indexLabels{1} = {'1','2','3','4','5'};
indexLabels{2} = {'B','A','P'};
s = SynergySetCollection(content,indexCats,indexLabels);

for ii = 1:size(content,1)
    for jj = 1:size(content,2)
        fakeClusteringIndex{ii,jj} = ...
            round(abs(sum(content{ii,jj}.content,2)));
    end
end
s2 = ClusteredSynergySetCollection(fakeClusteringIndex,s.content, ...
    s.indexCategories,s.indexLabels,s.name)
[figHandle,subplotHandles] = s2.plot;