function autoRenameDatlog(datlogFolder, viconDataFolder)
% autoRenameDatlog using timestamps and trial names from .x1d files in
% the viconDataFolder
% 1. Will first create a back up folder within the datlogFolder with the
% folder name 'datlog-original'
% 2. Then Will rename the datlog file that's the best match within a
% +-1min window of each .x1d file under viconDataFolder. If found, will
% rename the corresponding datlog file as Trial##.mat
% If no match found will skip (.e.,g if no match for Trial10.x1d
% in the datlog file that has time stamp within +-1mins, will not have a
% datlog file renamed as Trial10.mat)
%
% OUTPUTARGS = none
%
% [INPUTARGS]:
%   - datlogFolder: string of the full path to the datlog files copied
%       from an experiment session
%   - viconDataFolder: string of the full path to the vicon files copied
%       from an experiment session, should include .x1d files for each
%       trial that you collected.
%
%
% Examples:
%   dataDir = '/Volumes/Research/Shuqi/NirsAutomaticityStudy/Data';
%   autoRenameDatlog(fullfile(dataDir, 'AUF01', 'V02', 'datlog'), ...
%       fullfile(dataDir, 'AUF01', 'V02', 'Vicon'))
%   This will rename AUF01V02's datlog to be Trial## matching the .x1d file
%   in Vicon folder
% This function can be called standalone or as part of the c3d2mat call
% after finding the datlog folder is present in getTrialMetaData(info)
%
% See also: labTools/gui/importc3d/getTrialMetaData.m
%
% $Author: Shuqi Liu $	$Date: 2025/11/03 12:32:31 $	$Revision: 0.1 $
% Copyright: Sensorimotor Learning Laboratory 2025

%% Filter out valid vicon trials
% Trial##.x1d only; ignore calibration and other trials that may have
% been created during setup
viconFiles = dir(viconDataFolder);%nx1 struct where n = number of files
x1dFileLoc = false(size(viconFiles));
for ii = 1:length(viconFiles)
    %only get Trial##.x1d
    if endsWith(viconFiles(ii).name, '.x1d') ...
            && startsWith(viconFiles(ii).name, 'Trial')
        x1dFileLoc(ii) = true; %set this location as true for indexing
    end
end

x1dFiles = viconFiles(x1dFileLoc);
clear viconFiles x1dFileLoc ii %clear temp variables

%% Now also get the datlog files, filter out the directory files
datlogFiles = dir(datlogFolder);
%filter out the directory entries
datlogFileLoc = true(size(datlogFiles));
for ii = 1:length(datlogFiles)
    if datlogFiles(ii).isdir %filter out the directories
        datlogFileLoc(ii) = false;
    end
end
datlogFiles = datlogFiles(datlogFileLoc);
clear datlogFileLoc ii

%% Sort both by time in ascending order to speed up the search
[~, index] = sortrows([datlogFiles.datenum].');
datlogFiles = datlogFiles(index);
clear index
[~, index] = sortrows([x1dFiles.datenum].');
x1dFiles = x1dFiles(index);
clear index
%extract the datenum in an array for easier calculation later
datlogDateNums = nan(length(datlogFiles), 1);
for ii = 1:length(datlogFiles)
    datlogDateNums(ii) = datlogFiles(ii).datenum;
end

%% Look for a match that's closet and also within 1mins
secPerDay   = 86400; % seconds per day (datenum is in days)
maxMatchSec = 60;    % max datlog/x1d time difference for a match (s)
% first time start at row 1, next time start from the last found location
searchStartIdx = 1;
srcFileName    = cell(length(x1dFiles), 1);
destFileName   = cell(length(x1dFiles), 1);
% print out the best match time in seconds to visually check if you
% agree with the findings
bestMatch      = nan(length(x1dFiles), 1);
for ii = 1:numel(x1dFiles)
    differences = abs( ...
        datlogDateNums(searchStartIdx:end) - x1dFiles(ii).datenum);
    %find dates within 60s, serialdate * 86400 = seconds
    validLoc = differences * secPerDay <= maxMatchSec;
    if ~any(validLoc)
        %nothing within 1mins found, skip, this happens if a faulty trial
        %was started in Vicon but matlab didn't get time to start yet to
        %creat a datlog. Or if we manually clicked start/stop in Vicon
        warning(['Skipping %s, because no datlog within 1mins of x1d ' ...
            'file date time found.'], x1dFiles(ii).name)
        continue
    end
    % Find the minimum difference and its index
    [bestMatch(ii), min_idx] = min(differences(validLoc));
    idxInOriginalFiles = searchStartIdx:length(datlogDateNums);
    idxInOriginalFiles = idxInOriginalFiles(validLoc); %number indexing
    %find the idx within the valid index
    idxInOriginalFiles = idxInOriginalFiles(min_idx);
    srcFileName{ii}  = datlogFiles(idxInOriginalFiles).name;
    destFileName{ii} = x1dFiles(ii).name;
    searchStartIdx   = idxInOriginalFiles + 1;
end

%display match results for visual inspection
matchResults = table();
matchResults.src = srcFileName;
matchResults.dest = destFileName;
matchResults.timeDiffInSec = bestMatch * secPerDay;
matchResults

% %% Method2. Look for cloest match. Invalid.
% %Finding closet match is not enough bc some trials simply don't have a
% %datlog and closet match at this point may be 5-10mins away, and we are
% %matching a trial that could be valid later on an invalid .x1d file
% %all are availble to use, once a match is found mark it false to avoid
% %repeat
% unusedFiles = true(size(datlogDateNums));
% srcFileName = cell(length(x1dFiles),1);
% destFileName = cell(length(x1dFiles),1);
% bestMatch = nan(length(x1dFiles),1);
% for i = 1:numel(x1dFiles)
%     % Calculate absolute differences between A(i) and all elements in B
%     differences = abs(datlogDateNums(unusedFiles) - x1dFiles(i).datenum);
%
%     % Find the minimum difference and its index
%     [bestMatch(i), min_idx] = min(differences);
%     idxInOriginalFiles = find(unusedFiles);
%     %find the idx within the valid index
%     idxInOriginalFiles = idxInOriginalFiles(min_idx);
%     unusedFiles(idxInOriginalFiles) = false;
%     srcFileName{i} = datlogFiles(idxInOriginalFiles).name;
%     destFileName{i} = x1dFiles(i).name;
% end

%% Now first make a copy of the original datlogs for recovery, and
% rename to be trial## format.
datlogBackupFolder = fullfile(datlogFolder, 'datlog-original');
if ~isfolder(datlogBackupFolder)
    mkdir(datlogBackupFolder)
end
%copy all content into a subfolder
copyfile(fullfile(datlogFolder, '*'), datlogBackupFolder)

for ii = 1:numel(srcFileName)
    %no empty means a valid file exist to be renamed
    if ~isempty(srcFileName{ii})
        movefile(fullfile(datlogFolder, srcFileName{ii}), ...
            fullfile(datlogFolder, ...
            strrep(destFileName{ii}, '.x1d', '.mat')))
    end
end
end
