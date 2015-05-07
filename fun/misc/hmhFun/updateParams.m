function updateParams(subjects,eventClass,ignoreMatFlag)
%UPDATEPARAMS recomputes parameters and saves new subject file(s).
%Designed for batch re-processing.
%   updateParams(Subject) recomputes the adaptation 
%   parameters and overwrites the (Subject).mat and
%   (Subject)params.mat files if Subject is a string 
%   containing a subject ID for which a .mat file
%   exists either in the current working directory
%   or in a folder named after the same subject ID.
%
%   updateParams(Subject,1) Only overwrites the 
%   (Subject)params.mat file. Only use when changes
%   to calcExperimentalData have been made.
%   
%   See also calcParameters, experimentData.recomputeParameters, experimentData.makeDataObj.

h=waitbar(0, 'Checking input for errors...');
hw=findobj(h,'Type','Patch');
set(hw,'EdgeColor',[0 0 1],'FaceColor',[0 0 1]) % changes the color to green

if isa(subjects,'char')
    subjects={subjects};    
end

for s=1:length(subjects)
    try
        load([subjects{s} '.mat'])
        saveloc = [];
    catch
        try
            load([subjects{s} filesep char(s) '.mat'])
            saveloc=[subjects{s} filesep];
        catch
            ME=MException('makeDataObject:loadSubject',[char(s) ' could not be loaded, try changing your matlab path.']);
            throw(ME)
        end
    end

    if nargin<3 || ignoreMatFlag~=1   
        expData=expData.recomputeParameters(eventClass); 
        save([saveloc subjects{s} '.mat'],'expData'); %overwrites file
    end

    expData.makeDataObj([saveloc subjects{s}]); %overwrites file
    waitbar(s/length(subjects))
end

end