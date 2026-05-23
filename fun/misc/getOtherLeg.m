function f=getOtherLeg(s)
    switch s
        case 'L'
            f='R';
        case 'R'
            f='L';
        case 's'
            f='f';
        case 'f'
            f='s';
    end
%GETOTHERLEG Return the label for the opposite leg or pace.
%
%   Maps single-character leg/pace labels to their opposites:
% 'L' ↔ 'R' and 's' (slow) ↔ 'f' (fast).
%
% Inputs:
%   s - single-character label ('L', 'R', 's', or 'f')
%
% Outputs:
%   f - single-character label for the opposite leg or pace
%
% Toolbox Dependencies: None
%
% See also GETEVENTS.
end
