function updateParams(subjects,ignoreMatFlag)
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

if isa(subjects,'char')
    subjects={subjects};    
end

for s=subjects
    try
        load([char(s) '.mat'])
        saveloc = [];
    catch
        try
            load([char(s) filesep char(s) '.mat'])
            saveloc=[char(s) filesep];
        catch
            ME=MException('makeDataObject:loadSubject',[char(s) ' could not be loaded, try changing your matlab path.']);
            throw(ME)
        end
    end

    if nargin<2 || ignoreMatFlag~=1   
        expData=expData.recomputeParameters; 
        save([saveloc char(s) '.mat'],'expData'); %overwrites file
    end

    expData.makeDataObj([saveloc char(s)]); %overwrites file
end

end