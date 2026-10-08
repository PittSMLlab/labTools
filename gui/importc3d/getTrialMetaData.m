function [trialMD,fileList,secFileList,datlogExist] = getTrialMetaData(info)
%GETTRIALMETADATA Create trialMetaData objects and file lists for a session.
%
%   Builds one trialMetaData object per trial of the experiment, plus the
% C3D file lists (primary PC and secondary EMG PC) that LOADTRIALS reads.
% Assumes C3D files are named basename01, ..., basename10, ... Looks for
% a datlog folder ('datalog', 'datalogs', 'datlog', or 'datlogs', case
% insensitive) in info.dir_location and info.save_folder. If one exists,
% each trial's datlog .mat file is loaded into its trial meta data; when
% a trial's datlog file is missing, AUTORENAMEDATLOG renames the datlog
% files by timestamp (this copies and renames files in the datlog
% folder), and an error is thrown if the file is still missing.
%
% Inputs:
%   info - struct, session information returned by GetInfoGUI. Fields
%          used: dir_location, save_folder, secdir_location, basename,
%          cond, trialnums, numoftrials, trialObs (optional),
%          conditionNames, conditionDescriptions, refLeg, type,
%          schenleyLab, perceptualTasks, and ExpDescription
%
% Outputs:
%   trialMD     - cell array of trialMetaData objects; cell index
%                 corresponds to trial number
%   fileList    - cell array of C3D file paths (without extension)
%                 containing kinematic and force data
%   secFileList - cell array of file paths (without extension)
%                 containing EMG data from a second PC; '' if none
%   datlogExist - logical, true if a datlog folder was found (the datlogs
%                 are synchronized later)
%
% Toolbox Dependencies:
%   None
%
% See also TRIALMETADATA, AUTORENAMEDATLOG, LOADSUBJECT.

%% Initialize outputs
dirStr = info.dir_location;
basename = info.basename;

% initialize output parameters to empty cell arrays
fileList = {};
secFileList = {};
trialMD = {};

%% Locate the datlog folder
% check if 'datalog' folder exists in 'save_folder' or 'dir_location'
datlogExist = false;                    % boolean for data log existance
filesInDir = [dir(info.dir_location); dir(info.save_folder)];
for fi = 1:numel(filesInDir)            % for each file in directory, ...
    % search data logs with various naming conventions
    datlogExist = ismember(lower(filesInDir(fi).name), ...
        {'datalog','datalogs','datlog','datlogs'});
    if datlogExist                      % if data log files exist, ...
        % retrieve folder for later loading
        datalogFolder = fullfile(filesInDir(fi).folder, ...
            filesInDir(fi).name);
        break;
    end
end

%% Build the trial meta data for each condition and trial
for cond = sort(info.cond)              % for each exp. condition, ...
    for t = info.trialnums{cond}        % for each trial in condition, ...
        % assumes C3D files are named basename01, ..., basename10, ...
        filename = fullfile(dirStr, [basename sprintf('%02d', t)]);

        if datlogExist                  % if data logs exist, ...
            filenameDatlog = fullfile(datalogFolder, ...
                [basename sprintf('%02d', t) '.mat']);
            if ~isfile(filenameDatlog)
                % datlog folder exists but the file for this trial doesn't,
                % first try to rename the datlogs to see if that helps.
                fprintf(['\nDatalog folder exists (%s) but could not ' ...
                    'find datalog file for trial: %s. Attempt to ' ...
                    'rename all the datlog files now.\n'], ...
                    datalogFolder, [basename sprintf('%02d', t)]);
                autoRenameDatlog(datalogFolder, info.dir_location);
                fprintf(['\nAuto renaming datlog complete. Check the ' ...
                    'matchResults to validate if it matches your ' ...
                    'intuition\n']);
            end

            try % now try loading data log
                % open data log for this specific condition
                info.datlog{cond} = load(filenameDatlog);
            catch ME
                error(['Datalog folder exists (%s) but could not find ' ...
                    'datalog file for trial: %s even after renaming ' ...
                    'attempt. Maybe this datlog file was not copied? ' ...
                    'Check your Vicon x1d files and datlog files for ' ...
                    'this participant.'], ...
                    datalogFolder, [basename sprintf('%02d', t)]);
            end
        end
        fileList{t} = filename;

        % EMG may come from a single file (no second directory)
        if ~isempty(info.secdir_location)   % if no second directory, ...
            if t < 10                       % if fewer than ten trials, ...
                % append '0' to file name
                secFileList{t} = fullfile(info.secdir_location, ...
                    [basename '0' num2str(t)]);
            else                            % otherwise, ...
                secFileList{t} = fullfile(info.secdir_location, ...
                    [basename num2str(t)]);
            end
        else                                % otherwise, ...
            secFileList{t} = '';            % set to empty string
        end

        if ~isfield(info,'trialObs')        % if no trial observations, ...
            info.trialObs = cell(info.numoftrials,1);
        end

        % if this is a perceptual task and the data log files exist, ...
        if info.perceptualTasks == 1 || datlogExist
            % constructor: (name,desc,obs,refLeg,cond,filename,type)
            trialMD{t} = trialMetaData(info.conditionNames{cond}, ...
                info.conditionDescriptions{cond},info.trialObs{t}, ...
                info.refLeg,cond,filename,info.type{cond}, ...
                info.schenleyLab,info.perceptualTasks, ...
                info.ExpDescription,info.datlog{cond});
        else
            trialMD{t} = trialMetaData(info.conditionNames{cond}, ...
                info.conditionDescriptions{cond},info.trialObs{t}, ...
                info.refLeg,cond,filename,info.type{cond}, ...
                info.schenleyLab,info.perceptualTasks,info.ExpDescription);
        end
    end
end

end

