clear s

s=SynergySet(randn(5,9),{'TA','PER','SOL','MG','RF','VM','BF','TFL','GLU'});
handle=s.plot;
s.getDim
s.getElements
s %Equivalent to s.display
s.content
s.getPartialContent([1,3,4])
s.getSingleSynergy(1)
%s.getContentAsCollection %Not implemented
s.muscleList
s.name= 'TestSyn';
s.name
s.distance
s.distanceMatrix
