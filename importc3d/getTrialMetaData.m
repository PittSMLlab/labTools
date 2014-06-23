function [trialMD,fileList,secFileList] = getTrialMetaData(info)

dirStr = info.dir_location;
basename = info.basename;

fileList={};
secFileList={};
trialMD={};

i = 1;

for cond = info.cond 
    for t = info.trialnums{cond}
        %there may be an easier way to do this, basically this assumes that
        %the .c3d files are named basename01, basename02,..., basename10,
        %basename11,...
        if t<10
            filename = [dirStr '\' basename  '0' num2str(t)];
        else
            filename = [dirStr '\' basename num2str(t)];
        end
        
        fileList{end+1}=filename;
        
        if info.EMGs
            if t<10
                secFileList{end+1} = [info.sec_dir_location '\' basename '0' num2str(t)];
            else
                secFileList{end+1} = [info.sec_dir_location '\' basename num2str(t)];
            end
        end
        
        if info.isOverGround(cond)
            type = 'OG';
        else
            type = 'TM';
        end
        
        % (name,desc,obs,refLeg,cond,filename,type)
        trialMD{end+1}=trialMetaData(info.conditionNames{cond},info.conditionDescriptions{cond},info.trialObs{i},...
            info.refLeg,cond,filename,type);
        i = i+1;
    end    
end