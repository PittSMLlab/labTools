function isOpen = openTrialIfNeeded(pathTrial,vicon)
%OPENTRIALIFNEEDED Open a trial in Vicon Nexus unless it is already open.
%
%   Compares the open trial with pathTrial; if a different trial is open
% it is closed first, then the requested trial is opened.
%
% Side effects: closes the currently open Nexus trial when it differs
%   from pathTrial and opens pathTrial. Failures only warn.
%
% Inputs:
%   pathTrial - full path to the trial file (.x2d or trial folder path)
%   vicon     - Vicon Nexus SDK object
%
% Outputs:
%   isOpen - true if the requested trial is open on return
%
% Toolbox Dependencies: None

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

