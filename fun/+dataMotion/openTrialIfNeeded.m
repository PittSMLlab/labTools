function isOpen = openTrialIfNeeded(pathTrial,vicon)
%OPENTRIALIFNECESSARY Check if the trial is open, open if not, close others
%   This helper function checks if a specified trial is already open, and
% if not, it closes any other open trial and opens the desired one.
%
% input(s):
%   pathTrial: full path to the trial file (e.g., .x2d or folder path)
%   vicon: Vicon Nexus SDK object
%
% output(s):
%   isOpen: logical, true if the specified trial is open, false otherwise

narginchk(2,2);                 % verify correct number of input arguments

isOpen = false;
try
    [dirCurrentTrial,nameCurrentTrial] = vicon.GetTrialName();
    if ~isempty(nameCurrentTrial)
        pathCurrentTrial = fullfile(dirCurrentTrial,nameCurrentTrial);
        if strcmpi(pathCurrentTrial,pathTrial)
            fprintf('Trial is already open: %s\n',pathTrial);
            isOpen = true;
            return;
        else
            fprintf('Another trial is open. Closing current trial...\n');
            vicon.CloseTrial(200);
        end
    end
catch ME
    warning(ME.identifier,'%s',ME.message);
end

% open the trial if not already open
if ~isOpen
    fprintf('Opening trial from %s...\n',pathTrial);
    try
        vicon.OpenTrial(pathTrial,200);
        fprintf('Trial opened successfully.\n');
        isOpen = true;
    catch ME
        warning(ME.identifier,'%s',ME.message);
    end
end

end

