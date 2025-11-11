function autoRenameDatlog(datlogFolder, viconDataFolder)
    % autoRenameDatlog using timestamps and trial names from .x1d files in the viconDataFolder
    % 1. Will first create a back up folder within the datlogFolder with the
    % folder name 'datlog-original'
    % 2. Then Will rename the datlog file that's the best match within a +-1min window
    % of each .x1d file under viconDataFolder. If found, will rename the corresponding datlog file as
    % Trial##.mat
    % If no match found will skip (.e.,g if no match for Trial10.x1d 
    % in the datlog file that has time stamp within +-1mins, will not have a
    % datlog file renamed as Trial10.mat)
    % 
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
    % Examples: autoRenameDatlog('/Volumes/Research/Shuqi/NirsAutomaticityStudy/Data/AUF01/V02/datlog', '/Volumes/Research/Shuqi/NirsAutomaticityStudy/Data/AUF01/V02/Vicon')
    %   This will rename AUF01V02's datlog to be Trial## matching the .x1d file
    %   in Vicon folder
    % This function can be called standalone or as part of the c3d2mat call
    % after finding the datlog folder is present in getTrialMetaData(info)
    % 
    % See also: labTools/gui/importc3d/getTrialMetaData.m
    %
    % $Author: Shuqi Liu $	$Date: 2025/11/03 12:32:31 $	$Revision: 0.1 $
    % Copyright: Sensorimotor Learning Laboratory 2025
    
    %% Filter out valid vicon trials (Trial##.x1d, ignore calibration and other trials that may have been created during setup)
    viconFiles = dir(viconDataFolder);%nx1 struct where n = number of files
    x1dFileLoc = false(size(viconFiles));
    for i = 1:length(viconFiles)
        %only get Trial##.x1d
        if endsWith(viconFiles(i).name,'.x1d') && startsWith(viconFiles(i).name,'Trial')
            x1dFileLoc(i) = true; %set this location as true for indexing
        end
    end

    x1dFiles = viconFiles(x1dFileLoc);
    clear viconFiles x1dFileLoc i %clear temp variables
    
    %% Now also get the datlog files, filter out the directory files
    datlogFiles = dir(datlogFolder);
    %filter out the directory entries
    datlogFileLoc = true(size(datlogFiles));
    for i = 1:length(datlogFiles)
        if datlogFiles(i).isdir %filter out the directories
            datlogFileLoc(i) = false;
        end
    end
    datlogFiles = datlogFiles(datlogFileLoc);
    clear datlogFileLoc i

    %% Sort both by time in ascending order to speed up the search
    [~,index] = sortrows([datlogFiles.datenum].'); datlogFiles = datlogFiles(index); clear index
    [~,index] = sortrows([x1dFiles.datenum].'); x1dFiles = x1dFiles(index); clear index
    %extract the datenum in an array for easier calculation later
    datlogDateNums = nan(length(datlogFiles),1);
    for i = 1:length(datlogFiles)
        datlogDateNums(i) = datlogFiles(i).datenum;
    end

    %% Look for a match that's closet and also within 1mins
    searchStartIdx = 1; %first time start at row 1, next time start from the last found location
    srcFileName = cell(length(x1dFiles),1);
    destFileName = cell(length(x1dFiles),1);
    bestMatch = nan(length(x1dFiles),1); %print out the best match time in seconds to visually check if you agree with the findings
    for i = 1:numel(x1dFiles)
        differences = abs(datlogDateNums(searchStartIdx:end) - x1dFiles(i).datenum);
        validLoc = differences*86400 <= 60; %find dates within 60s, serialdate * 86400 = seconds
        if ~any(validLoc)
            %nothing within 1mins found, skip, this happens if a faulty trial
            %was started in Vicon but matlab didn't get time to start yet to
            %creat a datlog. Or if we manually clicked start/stop in Vicon
            warning('Skipping %s, because no datlog within 1mins of x1d file date time found.',x1dFiles(i).name)
            continue
        end
        % Find the minimum difference and its index
        [bestMatch(i), min_idx] = min(differences(validLoc));
        idxInOriginalFiles = searchStartIdx:length(datlogDateNums);
        idxInOriginalFiles = idxInOriginalFiles(validLoc); %number indexing
        idxInOriginalFiles = idxInOriginalFiles(min_idx); %find the idx within the valid index
        srcFileName{i} = datlogFiles(idxInOriginalFiles).name;
        destFileName{i} = x1dFiles(i).name;
        searchStartIdx = idxInOriginalFiles + 1;
    end
    
    %display match results for visual inspection
    matchResults = table();
    matchResults.src = srcFileName;
    matchResults.dest = destFileName;
    matchResults.timeDiffInSec = bestMatch * 86400;
    matchResults
    
    % %% Method2. Look for cloest match. Invalid.
    % %Finding closet match is not enough bc some trials simply don't have a
    % %datlog and closet match at this point may be 5-10mins away, and we are matching a trial that could be valid later on an invalid .x1d file
    % unusedFiles = true(size(datlogDateNums)); %all are availble to use, once a match is found mark it false to avoid repeat
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
    %     idxInOriginalFiles = idxInOriginalFiles(min_idx); %find the idx within the valid index
    %     unusedFiles(idxInOriginalFiles) = false;
    %     srcFileName{i} = datlogFiles(idxInOriginalFiles).name;
    %     destFileName{i} = x1dFiles(i).name;
    % end

    %% Now first make a copy of the original datlogs for recovery, and rename to be trial## format. 
    datlogBackupFolder = [datlogFolder filesep 'datlog-original' filesep];
    if ~isfolder(datlogBackupFolder)
        mkdir(datlogBackupFolder)
    end
    copyfile(fullfile(datlogFolder, '*'), datlogBackupFolder) %copy all content into a subfolder

    for i = 1:numel(srcFileName)
        if ~isempty(srcFileName{i}) %no empty means a valid file exist to be renamed
            movefile([datlogFolder filesep srcFileName{i}],[datlogFolder filesep strrep(destFileName{i},'.x1d','.mat')])
        end
    end
end
