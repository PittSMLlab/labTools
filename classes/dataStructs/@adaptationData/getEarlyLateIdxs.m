function [inds, names] = getEarlyLateIdxs(this, conds, numberOfStrides, ...
    exemptLast, exemptFirst)
%GETEARLYLATEIDXS Get stride indices of the earliest/latest strides.
%
%   Finds, for each condition, the indices of the first and/or last
% strides, optionally skipping the very first/last ones. If a condition
% has fewer strides than requested, the remaining entries are NaN.
%
% NOTE: exemptLast and exemptFirst are used as given below; the defaults
% computed in Ne/Nf (5 and 0) are never applied, so both must be passed.
%
% Inputs:
%   this            - adaptationData object
%   conds           - condition name(s) (char or cell array)
%   numberOfStrides - vector of any size with the number of strides per
%                     group: positive values take the first N strides,
%                     negative values the last N, zero gives an empty
%                     group (default [-5, 20])
%   exemptLast      - strides skipped at the end of each condition
%   exemptFirst     - strides skipped at the start of each condition
%
% Outputs:
%   inds  - cell array, one cell per entry of numberOfStrides, each a
%           strides x conditions matrix of indices
%   names - cell array of group names per entry of numberOfStrides and
%           condition
%
% Toolbox Dependencies: None
%
% See also GETEARLYLATEDATA_V2, GETINDSINCONDITION.

if isa(conds, 'char')
    conds = {conds};
elseif ~isa(conds, 'cell') || ~all(cellfun(@(x) (isa(x, 'char') || ...
        isa(x, 'cell')), conds))
    error('adaptationData:getEarlyLateData', ...
        'Conditions must be a string or a cell array containing strings.');
end
nConds = length(conds);
if nargin < 3 || isempty(numberOfStrides)
    numberOfStrides = [-5, 20];
end
dataPoints = cell(size(numberOfStrides));
if nargin < 4 || isempty(exemptLast)
    Ne = 5;
else
    Ne = exemptLast; % TODO: Check that it is positive
end
if nargin < 5 || isempty(exemptFirst)
    Nf = 0;
else
    Nf = exemptFirst; % TODO: Check that it is positive
end

conditionIdxs = this.getConditionIdxsFromName(conds);
inds = cell(length(numberOfStrides), 1);
indsAux = this.getIndsInCondition(conditionIdxs);
for jj = 1:length(numberOfStrides)
    inds{jj} = nan(abs(numberOfStrides(jj)), nConds);
    pr = [];
    switch sign(numberOfStrides(jj))
        case -1
            pr = 'Last ';
        case 2
            pr = 'First ';
    end
    pr = [pr num2str(abs(numberOfStrides(jj)))];
    for con = 1:nConds

        names{jj}{con} = [pr ' ' conds(con)];
        % First: find if there is a condition with a similar name to
        % the one given

        N = length(indsAux{con});
        if numberOfStrides(jj) < 0 % last N strides
            relInds = indsAux{con}(max([N - exemptLast + ...
                numberOfStrides(jj) + 1, 1]):N - exemptLast);
        else % first N
            relInds = indsAux{con}(exemptFirst + 1:min([exemptFirst + ...
                numberOfStrides(jj), N]));
        end
        % This allows for there to exist less strides than requested
        inds{jj}(1:length(relInds), con) = relInds;
        if length(relInds) < abs(numberOfStrides)
            warning(['Requested ' num2str(abs(numberOfStrides)) ...
                ' strides for ' this.subData.ID ' but after removing ' ...
                'the exempt ones, there are only ' ...
                num2str(length(relInds))])
        end
    end
end

end
