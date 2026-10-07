function dataPoints = getEarlyLateData_v2(this, labels, conds, ...
    removeBiasFlag, numberOfStrides, exemptLast, exemptFirst)
%GETEARLYLATEDATA_V2 Variant that slices strides itself (..._v2_.m).
%
%   Variant of GETEARLYLATEDATA_V2 that slices the strides itself
% instead of delegating to GETEARLYLATEIDXS and GETDATAFROMINDS. It
% removes bad strides first, removes bias with REMOVEBIASV2, and prints
% a message for each condition that is not found.
%
% NOTE: the function is declared as getEarlyLateData_v2, but MATLAB
% dispatches on the file name (getEarlyLateData_v2_.m).
%
% Inputs:
%   this            - adaptationData object
%   labels          - parameter labels to return (char or cellstr);
%                     required
%   conds           - condition name(s) (char or cell array)
%   removeBiasFlag  - 1 (default) remove bias; other values are passed
%                     to REMOVEBIASV2
%   numberOfStrides - vector of any size with the number of strides per
%                     group: positive values take the first N strides,
%                     negative values the last N, zero gives an empty
%                     group (default [-5, 20])
%   exemptLast      - strides skipped at the end of each condition
%                     (default 5)
%   exemptFirst     - strides skipped at the start of each condition
%                     (default 0)
%
% Outputs:
%   dataPoints - cell array with one cell per entry of numberOfStrides,
%                each conditions x strides x labels
%
% Toolbox Dependencies: None
%
% Example:
%   dataPoints = adaptData.getEarlyLateData_v2_({'Sout'}, ...
%       {'TM base'}, 1, [5, -20], 5);
%
% See also GETEARLYLATEDATA_V2, GETEARLYLATEIDXS, REMOVEBIASV2.

earlyPoints     = [];
veryEarlyPoints = [];
latePoints      = [];
N1 = 3;%all(cellfun(@(x) isa(x,'char'),conds))
if isa(conds, 'char')
    conds = {conds};
elseif ~isa(conds, 'cell') || ~all(cellfun(@(x) (isa(x, 'char') || ...
        isa(x, 'cell')), conds))
    error('adaptationData:getEarlyLateData', ...
        'Conditions must be a string or a cell array containing strings.');
end
nConds = length(conds);
if nargin < 2 || ~(isa(labels, 'char') || (isa(labels, 'cell') && ...
        all(cellfun(@(x) isa(x, 'char'), labels))))
    error('adaptationData:getEarlyLateData', ...
        'Labels must be a string or a cell array containing strings.')
end
if nargin < 5 || isempty(numberOfStrides)
    numberOfStrides = [-5, 20];
end
dataPoints = cell(size(numberOfStrides));
if nargin < 6 || isempty(exemptLast)
    Ne = 5;
else
    Ne = exemptLast;
end
if nargin < 7 || isempty(exemptFirst)
    Nf = 0;
else
    Nf = exemptFirst;
end
if nargin < 4 || isempty(removeBiasFlag) || removeBiasFlag == 1
    this = this.removeBadStrides();
    removeBiasFlag = 1; % default
else
    %this=adaptData;
end

%this=this.removeBadStrides;
inds = this.getEarlyLateIdxs(conds, numberOfStrides, exemptLast, ...
    exemptFirst);
this = this.removeBiasV2([], removeBiasFlag);
conditionIdxs = this.getConditionIdxsFromName(conds);
for jj = 1:length(numberOfStrides)
    for con = 1:nConds
        %dataPoints{j}(i,:.:)=
        % First: find if there is a condition with a similar name to the
        % one given
        condIdx = conditionIdxs(con);
        % No bias removal: it was already done
        aux = this.getParamInCond(labels, conditionIdxs(con), 0);
        N = size(aux, 1);
        if ~isempty(condIdx) && ~isempty(aux)
            data = nan(abs(numberOfStrides(jj)), length(labels));
            if numberOfStrides(jj) <= 0 % last N strides
                % Gets the last numberOfStrides(jj) strides, exempting
                % the very last Ne, and allows for fewer strides being
                % available than requested.
                data(1:min([N - Ne, abs(numberOfStrides(jj))]), :) = ...
                    aux(max([1, end - Ne + numberOfStrides(jj) + 1]): ...
                    end - Ne, :);
            else
                data(1:min([N - Nf, abs(numberOfStrides(jj))]), :) = ...
                    aux(Nf + 1:min([Nf + numberOfStrides(jj), N]), :);
            end
            dataPoints{jj}(con, 1:abs(numberOfStrides(jj)), :) = data;
        else
            disp(['Condition ' conds{con} ' not found for subject ' ...
                this.subData.ID])
            dataPoints{jj}(con, 1:abs(numberOfStrides(jj)), :) = NaN;
        end
    end
end

end
