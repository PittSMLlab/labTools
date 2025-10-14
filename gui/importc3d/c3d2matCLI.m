function [expData,rawExpData,adaptData] = c3d2matCLI(infoFile,eventClass)
% This function is the same as c3d2mat without a GUI. The information
% typically acquired through the GUI is loaded from a file. To create this
% information file (requires using the GUI), call c3d2mat or GetInfoGUI.

if nargin < 2                           % if no second input argument, ...
    eventClass = '';                    % use default event detection
end

handles = loadInfoFile(infoFile,'');
out = errorProofInfo(handles,ignoreErrors);
[expData,rawExpData,adaptData] = loadSubject(info,eventClass);

end

