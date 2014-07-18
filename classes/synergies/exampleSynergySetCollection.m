%Test example of SynergySetCollection

%Create:
muscleList={'TA','PER','SOL','MG','RF','VM','BF','TFL','GLU'};
content={SynergySet(randn(3,9),muscleList),SynergySet(randn(4,9),muscleList),SynergySet(randn(6,9),muscleList);
        SynergySet(randn(4,9),muscleList),SynergySet(randn(3,9),muscleList),SynergySet(randn(3,9),muscleList);
        SynergySet(randn(3,9),muscleList),SynergySet(randn(3,9),muscleList),SynergySet(randn(3,9),muscleList);
        SynergySet(randn(3,9),muscleList),SynergySet(randn(3,9),muscleList),SynergySet(randn(3,9),muscleList);
        SynergySet(randn(3,9),muscleList),SynergySet(randn(3,9),muscleList),SynergySet(randn(3,9),muscleList)};
    
indexCats={'Subject','Condition'};
indexLabels{1}={'1','2','3','4','5'};
indexLabels{2}={'B','A','P'};
s=SynergySetCollection(content,indexCats,indexLabels);

%Probe some methods:
s.content
s.indexCategories
s.indexLabels
s.getCollectionDim
s.getCollectionSize
s.getSynergyDim
s.isSorted
s %Calls display
s.getSetLabels(8)
s.getSetLabels([3,2])
s.getContentAsSet %Calls display from SynergySet