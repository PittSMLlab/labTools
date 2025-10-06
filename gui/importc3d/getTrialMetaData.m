function [trialMD,fileList,secFileList,datlogExist] = getTrialMetaData(info)
%getTrialMetaData creates trialMetaData object for each trial of experiment
%
%INPUT:
%info: structured array output from GetInfoGUI
%
%OUTPUTS:
%trialMD: cell array of trialMetaData objects where the cell index
%corresponds to the trial number
%fileList: list of .c3d files containing kinematic and force data for a
%given experiment
%secFileList: list of files containing EMG data for a given experiment
%datlogExist: boolean indicating if datlog folder exists (if so will sync
%it later)
%
%See also: trialMetaData

dirStr = info.dir_location;
basename = info.basename;

% initialize output parameters to empty cell arrays
fileList = {};
secFileList = {};
trialMD = {};

% check if 'datalog' folder exists in 'save_folder' or 'dir_location'
datlogExist = false;                    % boolean for data log existance
filesInDir = [dir(info.dir_location);dir(info.save_folder)];
for fi = 1:numel(filesInDir)            % for each file in directory, ...
    % search data logs with various naming conventions
    datlogExist = ismember(lower(filesInDir(fi).name), ...
        {'datalog','datalogs','datlog','datlogs'});
    if datlogExist                      % if data log files exist, ...
        datalogFolder = ...               retrieve folder for later loading
            [filesInDir(fi).folder filesep filesInDir(fi).name];
        break;
    end
end

for cond = sort(info.cond)              % for each exp. condition, ...
    for t = info.trialnums{cond}        % for each trial in condition, ...
        % assumes C3D files are named basename01, ..., basename10, ...
        filename = [dirStr filesep basename sprintf('%02d',t)];

        if datlogExist                  % if data logs exist, ...
            filenameDatlog = ...
                [datalogFolder filesep basename sprintf('%02d',t)];
            try                         % try loading data log
                % open data log for this specific condition
                info.datlog{cond} = load([filenameDatlog '.mat']);
            catch ME
                error(['Datalog folder exists (%s) but could not find ' ...
                    'datalog file for trial: %s. Maybe forget to ' ...
                    'rename them? Will ignore this trial.'], ...
                    datalogFolder,[basename sprintf('%02d',t)]);
            end
        end
        fileList{t} = filename;

        % Pablo I. changed 07/16/2015 to consider case of EMG from one file
        if ~isempty(info.secdir_location)   % if no second directory, ...
            if t < 10                       % if fewer than ten trials, ...
                secFileList{t} = ...          append '0' to file name
                    [info.secdir_location filesep basename '0' num2str(t)];
            else                            % otherwise, ...
                secFileList{t} = ...
                    [info.secdir_location filesep basename num2str(t)];
            end
        else                                % otherwise, ...
            secFileList{t} = '';            % set to empty string
        end

        if ~isfield(info,'trialObs')        % if no trial observations, ...
            info.trialObs = cell(info.numoftrials,1);
        end

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

