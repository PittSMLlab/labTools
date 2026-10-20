function [p, postHocMatrix] = anova(this, params, groupIdxs, dispOpt)
%ANOVA Performs one-way ANOVA on parameters.
%
%   [p, postHocMatrix] = anova(this, params, groupIdxs) performs one-way
% ANOVA among groups and post-hoc analysis
%
%   [p, postHocMatrix] = anova(this, params, groupIdxs, dispOpt) controls
% display
%
% Inputs:
%   this      - parameterSeries object
%   params    - string or cell array of parameter names to analyze
%   groupIdxs - cell array of stride index vectors, one per group
%   dispOpt   - display option for anova1: 'on' or 'off' (optional, default:
%               'off')
%
% Outputs:
%   p             - vector of p-values, one per parameter
%   postHocMatrix - cell array of post-hoc comparison matrices
%                   (Tukey-Kramer), one per parameter
%
% Toolbox Dependencies: Statistics and Machine Learning Toolbox
%
% See also ANOVA1, MULTCOMPARE.

if nargin < 4 || isempty(dispOpt)
    dispOpt = 'off';
end
strides = cell2mat(groupIdxs);
Ngroups = length(groupIdxs);
for ii = 1:Ngroups
    groupID{ii} = ii * ones(size(groupIdxs{ii}));
end
groupID = cell2mat(groupID);
if isa(params, 'char')
    params = {params};
end
Nparams       = length(params);
aux           = this.getDataAsPS([], strides);
postHocMatrix = cell(Nparams, 1);
for ii = 1:Nparams
    postHocMatrix{ii} = nan(Ngroups);
    relevantData = aux.getDataAsVector(params(ii));
    [p(ii), ANOVATAB, STATS] = anova1(relevantData, groupID, dispOpt);
    % Default post-hoc is tukey-kramer
    [c, MEANS, H, GNAMES] = multcompare(STATS);
    postHocMatrix{ii}(sub2ind(Ngroups * [1, 1], c(:, 1), c(:, 2))) = ...
        c(:, 6);
end
end

