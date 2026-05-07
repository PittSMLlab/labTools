function [LHS,RHS,LTO,RTO] = getEventsFromStance(stanceL,stanceR)
%GETEVENTSFROMSTANCE Retrieve gait events from stance phase logical vectors.
%
%   Detects heel-strike (HS) and toe-off (TO) events for left and right
% legs by finding rising and falling edges of the stance phase signals.
%
% Inputs:
%   stanceL - N×1 logical, left stance phase (true = stance)
%   stanceR - N×1 logical, right stance phase (true = stance)
%
% Outputs:
%   LHS - N×1 logical, left heel-strike events
%   RHS - N×1 logical, right heel-strike events
%   LTO - N×1 logical, left toe-off events
%   RTO - N×1 logical, right toe-off events
%
% Toolbox Dependencies: None
%
% See also GETEVENTSFROMFORCES, GETEVENTSFROMTOENANDHEEL.

% first step:
LTO = ([false; diff(double(stanceL)) == -1]);   % & stanceR;
LHS = ([false; diff(double(stanceL)) == 1]);    % & stanceR;
RTO = ([false; diff(double(stanceR)) == -1]);   % & stanceL;
RHS = ([false; diff(double(stanceR)) == 1]);    % & stanceL;

end

