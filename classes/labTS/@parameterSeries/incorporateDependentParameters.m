function newThis = incorporateDependentParameters(this, labels)
%incorporateDependentParameters  Adds computed dependent parameters
%
%   newThis = incorporateDependentParameters(this, labels) adds
%   parameters computed from existing parameters using recipes from
%   DependParamRecipes.mat
%
%   Inputs:
%       this - parameterSeries object
%       labels - string or cell array of dependent parameter names to
%                add
%
%   Outputs:
%       newThis - parameterSeries with added parameters
%
%   Note: Loads recipes from 'DependParamRecipes.mat' file
%
%   See also: addNewParameter, computeNewParameter

ff = load('DependParamRecipes.mat', 'fieldList');
fTable = ff.fieldList;
newThis = this;
if isa(labels, 'char')
    labels = {labels};
end
[bool, idxs] = compareLists(fTable(:, 1), labels);
acceptedLabels = labels(bool);
acceptedDesc = fTable(idxs(bool), 4);
acceptedHandles = fTable(idxs(bool), 2);
acceptedParams = fTable(idxs(bool), 3);
if any(~bool)
    warning(['Did not find recipes for some of the labels ' ...
        'provided: ' strjoin(labels(~bool), ', ')]);
end
for i = 1:length(acceptedLabels)
    newThis = addNewParameter(newThis, acceptedLabels{i}, ...
        eval(acceptedHandles{i}), acceptedParams{i}, acceptedDesc{i});
end
end

