function [trialMD,fileList,secFileList] = getTrialMetaData(info)

dirStr = info.dir_location;
basename = info.basename;

fileList={};
secFileList={};
trialMD={};


for cond = sort(info.cond) 
    for t = info.trialnums{cond}
        %there may be an easier way to do this, basically this assumes that
        %the .c3d files are named basename01, basename02,..., basename10,
        %basename11,...
        if t<10
            filename = [dirStr filesep basename  '0' num2str(t)];
        else
            filename = [dirStr filesep basename num2str(t)];
        end
        
        fileList{t}=filename;
               
        if info.EMGs
            if t<10
                secFileList{t} = [info.secdir_location filesep basename '0' num2str(t)];
            else
                secFileList{t} = [info.secdir_location filesep basename num2str(t)];
            end
        end       
        
        
        if ~isfield(info,'trialObs')
            info.trialObs=cell(info.numoftrials,1);
        end
        % constructor: (name,desc,obs,refLeg,cond,filename,type)
        trialMD{t}=trialMetaData(info.conditionNames{cond},info.conditionDescriptions{cond},...
            info.trialObs{t},info.refLeg,cond,filename,info.type{cond});        
    end    
end