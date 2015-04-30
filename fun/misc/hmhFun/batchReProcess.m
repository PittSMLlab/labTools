function batchReProcess(subjects)
% ex: subs= {'OG11','OG12','OG13','OG14','OG15','OG16','OG18'}

if isa(subjects,'char')
    subjects={subjects};    
end

for s=subjects
    try
        load([char(s),'RAW.mat']) %could do this with not raw, but raw is faster to load
        saveloc = [];
    catch
        try
            load([char(s) filesep char(s) 'RAW.mat'])
            saveloc=[char(s) filesep];
        catch
            ME=MException('makeDataObject:loadSubject',[char(s) ' could not be loaded, try changing your matlab path.']);
            throw(ME)
        end
    end
    
    
    expData=rawExpData.process;
    save([saveloc,char(s)],'expData','-v7.3')
    expData.makeDataObj([saveloc char(s)]); %overwrites file
    
    clear all
end