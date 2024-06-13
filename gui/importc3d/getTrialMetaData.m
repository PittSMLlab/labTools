function [trialMD,fileList,secFileList, datlogExist] = getTrialMetaData(info)
%getTrialMetaData  generates trialMetaData objects for each trial of a
%given experiment.
%
%INPUTS:
%info: structured array output from GetInfoGUI
%
%OUTPUT:
%trialMD: cell array of trialMetaData objects where the cell index corresponds
%to the trial number
%fileList: list of .c3d files containing kinematic and force data for a given experiment
%secFileList: list of files containing EMG data for a given experiment
%datlogExist: boolean indicating if datlog folder exists (if so will sync it later)
%See also: trialMetaData

dirStr = info.dir_location;
basename = info.basename;

fileList={};
secFileList={};
trialMD={};

%check if datalog directory exists (exist in either save or dir_folder and in format datalog or datlog.
% if exists, load it later
datlogExist = false;
filesInDir = [dir(info.dir_location);dir(info.save_folder)];
for i = 1:numel(filesInDir)
    % search for alternative naming conventions.
    datlogExist = ismember(lower(filesInDir(i).name), {'datalog','datalogs','datlog','datlogs'});
    if datlogExist
        datalogFolder = [filesInDir(i).folder filesep filesInDir(i).name];
        break
    end
end

for cond = sort(info.cond) 
    for t = info.trialnums{cond}
        %This assumes that the .c3d files are named basename01, basename02,..., basename10,
        %basename11,...
        filename = [dirStr filesep basename sprintf('%02d',t)];
       
        if datlogExist %datalog folder found, load it.
            filenameDatlog = [datalogFolder filesep basename sprintf('%02d',t)];
            try
                % Upload the datalog for the specifica condition   
                info.datlog{cond} = load([filenameDatlog '.mat']);
            catch ME
                error('Datalog folder exists (%s) but could not find datalog file for trial: %s. Maybe forget to rename them? Will ignore this trial.',datalogFolder,[basename sprintf('%02d',t)])
            end
        end
                
        fileList{t}=filename;
               
        if ~isempty(info.secdir_location) %Pablo changed on 7/16/2015 to consider the case where there is EMG from a single file.
            if t<10
                secFileList{t} = [info.secdir_location filesep basename '0' num2str(t)];
            else
                secFileList{t} = [info.secdir_location filesep basename num2str(t)];
            end
        else
            secFileList{t}='';
        end       
        
        
        if ~isfield(info,'trialObs')
            info.trialObs=cell(info.numoftrials,1);
        end
        
         if info.perceptualTasks ==1 || datlogExist
               % constructor: (name,desc,obs,refLeg,cond,filename,type)
            trialMD{t}=trialMetaData(info.conditionNames{cond},info.conditionDescriptions{cond},...
                info.trialObs{t},info.refLeg,cond,filename,info.type{cond},info.schenleyLab,info.perceptualTasks,info.ExpDescription,info.datlog{cond});   
         else
            trialMD{t}=trialMetaData(info.conditionNames{cond},info.conditionDescriptions{cond},...
                info.trialObs{t},info.refLeg,cond,filename,info.type{cond},info.schenleyLab,info.perceptualTasks,info.ExpDescription); 
         end
    end 
   
end