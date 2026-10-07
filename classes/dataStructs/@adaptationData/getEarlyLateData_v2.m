function dataPoints = getEarlyLateData_v2(this, labels, conds, ...
    removeBiasFlag, numberOfStrides, exemptLast, exemptFirst, ...
    padWithNaNFlag)
%GETEARLYLATEDATA_V2 Get the earliest and latest strides of conditions.
%
%   Selects the first and/or last strides of each condition (optionally
% skipping the very first/last ones), applies the requested bias
% handling, and returns the parameter values at those strides.
%
% Inputs:
%   this            - adaptationData object
%   labels          - parameter labels to return (char or cellstr);
%                     [] (default) returns all labels
%   conds           - condition name(s) (char or cell array)
%   removeBiasFlag  - 1 (default) remove bias, 2 normalize bias, 0 none
%   numberOfStrides - vector of any size with the number of strides per
%                     group: positive values take the first N strides,
%                     negative values the last N, zero gives an empty
%                     group (default [5, -20])
%   exemptLast      - strides skipped at the end of each condition
%                     (default 5)
%   exemptFirst     - strides skipped at the start of each condition
%                     (default 0); only applies to positive values of
%                     numberOfStrides
%   padWithNaNFlag  - passed to GETDATAFROMINDS (default false)
%
% Outputs:
%   dataPoints - cell array with one cell per entry of numberOfStrides
%
% Toolbox Dependencies: None
%
% Example:
%   dataPoints = adaptData.getEarlyLateData_v2({'Sout'}, {'TM base'}, ...
%       1, [5, -20], 5);
%
% See also GETEARLYLATEIDXS, GETDATAFROMINDS, REMOVEBIAS, NORMALIZEBIAS.

defaultStrides     = [5, -20];  % first 5 and last 20
defaultExemptLast  = 5;
defaultExemptFirst = 0;

if isa(conds, 'char')
    conds = {conds};
elseif ~isa(conds, 'cell') || ~all(cellfun(@(x) (isa(x, 'char') || ...
        isa(x, 'cell')), conds))
    error('adaptationData:getEarlyLateData', ...
        'Conditions must be a string or a cell array containing strings.');
end
if nargin < 2
    labels = []; % empty labels are interpreted as ALL labels down-stream
elseif ~isempty(labels) && (~(isa(labels, 'char') || ...
        (isa(labels, 'cell') && all(cellfun(@(x) isa(x, 'char'), ...
        labels)))))
    error('adaptationData:getEarlyLateData', ...
        'Labels must be a string or a cell array containing strings.')
end
if nargin < 5 || isempty(numberOfStrides)
    numberOfStrides = defaultStrides;
end
if nargin < 6 || isempty(exemptLast)
    Ne = defaultExemptLast;
else
    Ne = exemptLast;
end
if nargin < 7 || isempty(exemptFirst)
    Nf = defaultExemptFirst;
else
    Nf = exemptFirst;
end
if nargin < 4 || isempty(removeBiasFlag)
    removeBiasFlag = 1; % default: bias removal
else
    %this=adaptData;
end
if nargin < 8
    padWithNaNFlag = false;
end

% NOTE: bad strides are deliberately not removed here; that would change
% the number of strides in the middle of a request for data.
%this=this.removeBadStrides;
inds = this.getEarlyLateIdxs(conds, numberOfStrides, Ne, Nf);
switch removeBiasFlag
    case 1
        this = this.removeBias();
    case 2
        this = this.normalizeBias();
    case 0
        %nop
    otherwise
        error('Unexpected value for removeBiasFlag')
end
dataPoints = this.getDataFromInds(inds, labels, padWithNaNFlag);

end
