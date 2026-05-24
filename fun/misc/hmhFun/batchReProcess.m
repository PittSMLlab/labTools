function batchReProcess(subjects, eventClass)
%BATCHREPROCESS Reprocess raw experiment data for a list of subjects.
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

if isa(subjects, 'char')
    subjects = {subjects};
end

for sub = subjects
    try
        load([char(sub) 'RAW.mat'])
        saveloc = [];
    catch
        try
            load([char(sub) filesep char(sub) 'RAW.mat'])
            saveloc = [char(sub) filesep];
        catch
            ME = MException('makeDataObject:loadSubject', ...
                [char(sub) ' could not be loaded, try changing ' ...
                'your matlab path.']);
            throw(ME)
        end
    end

    expData = rawExpData.process(eventClass);
    save([saveloc, char(sub)], 'expData', '-v7.3')
    expData.makeDataObj([saveloc char(sub)]);

    clearvars -except eventClass
end

end
