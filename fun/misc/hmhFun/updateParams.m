function updateParams(subjects, eventClass, ignoreMatFlag)
%UPDATEPARAMS Recompute parameters and save updated subject files.
%
%   For each subject ID, loads the saved .mat file, recomputes adaptation
% parameters via recomputeParameters, and overwrites both the .mat and
% the params.mat files. A progress bar is shown during batch runs.
%
%   updateParams(subjects) recomputes parameters for all subjects and
% overwrites both (subject).mat and (subject)params.mat.
%
%   updateParams(subjects, eventClass, 1) skips recomputeParameters and
% only regenerates the params.mat file; use when only calcParameters
% logic has changed.
%
% Inputs:
%   subjects      - Cell array of subject ID strings, or a single string
%   eventClass    - Event class passed to recomputeParameters
%   ignoreMatFlag - (Optional) If 1, skip .mat recomputation and only
%                   regenerate the params.mat file
%
% Outputs:
%   None (saves files to disk)
%
% See also EXPERIMENTDATA.RECOMPUTEPARAMETERS, EXPERIMENTDATA.MAKEDATAOBJ,
%   BATCHREPROCESS.

h  = waitbar(0, 'Updating...');
hw = findobj(h, 'Type', 'Patch');
set(hw, 'EdgeColor', [0 0 1], 'FaceColor', [0 0 1])

if isa(subjects, 'char')
    subjects = {subjects};
end

for ss = 1:length(subjects)
    try
        load([subjects{ss} '.mat'])
        saveloc = [];
    catch
        try
            load([subjects{ss} filesep char(ss) '.mat'])
            saveloc = [subjects{ss} filesep];
        catch
            ME = MException('makeDataObject:loadSubject', ...
                [char(ss) ' could not be loaded, try changing ' ...
                'your matlab path.']);
            throw(ME)
        end
    end

    if nargin < 3 || ignoreMatFlag ~= 1
        expData = expData.recomputeParameters(eventClass);
        save([saveloc subjects{ss} '.mat'], 'expData');
    end

    expData.makeDataObj([saveloc subjects{ss}]);
    waitbar(ss / length(subjects))
end

close(h)

end
