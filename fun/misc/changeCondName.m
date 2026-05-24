function changeCondName(subID, oldNames, newNames)
%CHANGECONDNAME Rename conditions in an adaptationData params file.
%
%   For each subject in SUBID, loads the corresponding params file,
% replaces every condition name in OLDNAMES with the corresponding
% name in NEWNAMES, and saves the updated file back to disk.
%
% Inputs:
%   subID    - string or cell array of strings; subject ID prefix
%              (characters preceding 'params' in the filename)
%   oldNames - string or cell array of condition names to replace
%   newNames - string or cell array of replacement condition names;
%              must be the same length as oldNames
%
% Outputs:
%   (none) — modifies params files on disk in-place
%
% Toolbox Dependencies: None
%
% See also ADAPTATIONDATA.

%% Validate inputs
if isa(subID, 'char')
    subID = {subID};
elseif ~(isa(subID, 'cell') && isa(subID{1}, 'char'))
    ME = MException('changeCondName:inputMismatch', ...
        'subID needs to be a string or cell array of strings.');
    throw(ME);
end

if isa(oldNames, 'char')
    oldNames = {oldNames};
elseif ~(isa(oldNames, 'cell') && isa(oldNames{1}, 'char'))
    ME = MException('changeCondName:inputMismatch', ...
        'oldNames needs to be a string or cell array of strings.');
    throw(ME);
end

if isa(newNames, 'char')
    newNames = {newNames};
elseif ~(isa(newNames, 'cell') && isa(newNames{1}, 'char'))
    ME = MException('changeCondName:inputMismatch', ...
        'newNames needs to be a string or cell array of strings.');
    throw(ME);
end

if length(oldNames) ~= length(newNames)
    ME = MException('changeCondName:badInput', ...
        'oldNames and newNames inputs must be the same length.');
    throw(ME);
end

%% Rename conditions in each subject's params file
for ii = 1:length(subID)
    try
        load([subID{ii} 'params.mat'])
    catch
        ME = MException('changeCondName:badInput', ...
            ['The params file for ' subID{ii} ' does not appear ' ...
            'to be in your current folder.']);
        throw(ME);
    end

    for jj = 1:length(oldNames)
        ind = find(ismember( ...
            adaptData.metaData.conditionName, oldNames(jj)));
        if isempty(ind)
            warning([subID{ii} '''s file does not contain condition ''' ...
                oldNames{jj} ''' and was not replaced with ''' ...
                newNames{jj} ''''])
            continue
        else
            adaptData.metaData.conditionName{ind} = newNames{jj};
        end
    end
    save([subID{ii} 'params.mat'], 'adaptData', '-v7.3')
end
end
