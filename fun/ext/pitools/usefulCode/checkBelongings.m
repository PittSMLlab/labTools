function flag = checkBelongings(idx1, idx2)
%CHECKBELONGINGS Check pair-wise uniqueness of two index vectors.
%
%   Returns true if no two elements share the same (idx1, idx2) pair,
%   i.e. there is no i and j such that idx1(i)==idx1(j) && idx2(i)==idx2(j).
%   The idx vectors represent group/cluster memberships, and this function
%   verifies a Pauli-exclusion-like constraint: no two elements may have
%   identical belongings in both groups simultaneously.
%
% Inputs:
%   idx1 - integer vector of group memberships (first grouping)
%   idx2 - integer vector of group memberships (second grouping);
%          must be the same length as idx1
%
% Outputs:
%   flag - true if the exclusion criterion is satisfied, false otherwise;
%          empty ([]) if the inputs fail validation
%
% Toolbox Dependencies: None
%
% See also CROSSTAB.

%% Validate Inputs
if length(idx1) ~= numel(idx1) || length(idx2) ~= numel(idx2)
    disp('Error in checkBelongings: inputs are not vectors')
    flag = [];
    return
end
if length(idx1) ~= length(idx2)
    disp('Error in checkBelongings: vectors are not of the same size')
    flag = [];
    return
end

%% Check Belongings
Nelem = length(idx1);
%M = sparse([], [], [], max(idx1), max(idx2), Nelem^2);
%for ii = 1:length(idx1)
%    M(idx1(ii), idx2(ii)) = M(idx1(ii), idx2(ii)) + 1;
%end
M = crosstab(idx1, idx2);

if any(M(:) > 1)
    flag = false;
else
    flag = true;
end
end
