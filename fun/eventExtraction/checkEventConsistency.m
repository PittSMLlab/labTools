function isConsistent = checkEventConsistency(LHS, RHS, LTO, RTO)
%CHECKEVENTCONSISTENCY Verify that gait events follow the expected sequence.
%
%   Checks whether the detected heel-strike and toe-off events follow the
% canonical gait cycle order: LHS → RTO → RHS → LTO → repeat. Encodes
% each event type as a power of two so the sequence can be verified by
% inspecting successive differences.
%
% Inputs:
%   LHS - N×1 logical, left heel-strike events
%   RHS - N×1 logical, right heel-strike events
%   LTO - N×1 logical, left toe-off events
%   RTO - N×1 logical, right toe-off events
%
% Outputs:
%   isConsistent - scalar logical, true if event sequence is valid
%
% Toolbox Dependencies: None
%
% See also GETEVENTSFROMSTANCE, GETEVENTSFROMFORCES.

% gait event binary encoding (powers of two for unique difference values)
LHS_CODE = 1;
RTO_CODE = 2;
RHS_CODE = 4;
LTO_CODE = 8;

isConsistent = true;

% encode events; expected sequence: 1, 2, 4, 8, 1, ...
eventSequence = LHS * LHS_CODE + RTO * RTO_CODE ...
    + RHS * RHS_CODE + LTO * LTO_CODE;
nonZeroEvents = eventSequence(eventSequence ~= 0);
eventDiffs    = diff(nonZeroEvents);

% Valid transitions: +1 (LHS→RTO), +2 (RTO→RHS), +4 (RHS→LTO),
% -7 (LTO→LHS wrap: code 8 back to code 1, so 1-8 = -7)
if any((eventDiffs ~= 1) & (eventDiffs ~= 2) ...
        & (eventDiffs ~= 4) & (eventDiffs ~= -7))
    warning('checkEventConsistency:inconsistentEvents', ...
        'Inconsistent gait event sequence detected.');
    isConsistent = false;
end

end
