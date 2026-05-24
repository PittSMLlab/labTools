function batchReProcess(subjects,eventClass)
% ex: subjects= {'OG11','OG12','OG13','OG14','OG15','OG16','OG18'}

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
        
    expData=rawExpData.process(eventClass);
    save([saveloc,char(s)],'expData','-v7.3')
    expData.makeDataObj([saveloc char(s)]); %overwrites file
    
    clearvars -except eventClass
end%BATCHREPROCESS Reprocess raw experiment data for a list of subjects.
%
%   Loads each subject's RAW.mat file, runs process() with the given
% event class, and saves both the expData struct and the derived data
% object to the same location as the RAW file.
%
%   Example:
%     batchReProcess({'OG11','OG12','OG13'}, eventClass)
%
% Inputs:
%   subjects   - Cell array of subject ID strings, or a single string
%   eventClass - Event class passed to rawExpData.process()
%
% Outputs:
%   None (saves files to disk)
%
% Toolbox Dependencies: None
%
% See also EXPERIMENTDATA.
