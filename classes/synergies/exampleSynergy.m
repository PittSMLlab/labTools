%Test Synergy class creation and display
clear s
s=Synergy(randn(9,1),{'TA','PER','SOL','MG','RF','VM','BF','TFL','GLU'},['']);
handle=s.plot;
s %Equivalent to s.display
s.name
s.name='TestSyn';
s.name
s.muscleList
s.content
s2=s;
s.distance(s2)