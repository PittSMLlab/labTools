%EXAMPLESYNERGY Example usage of the Synergy class.
%
%   Creates a Synergy, plots it, sets its name, and computes the distance to
% a copy of itself.
%
% Toolbox Dependencies: Statistics and Machine Learning Toolbox
%
% See also SYNERGY, SYNERGYSET.

clear s
s = Synergy(randn(9,1),{'TA','PER','SOL','MG','RF','VM','BF','TFL', ...
    'GLU'},['']);
handle = s.plot;
s %Equivalent to s.display
s.name
s.name = 'TestSyn';
s.name
s.muscleList
s.content
s2 = s;
s.distance(s2)