function [expData,rawExpData,adaptData] = c3d2matCLI(infoFile,eventClass)
% c3d2matCLI  Parses C3D session files into a MAT file without a GUI.
%
%   Performs the same processing as the c3d2mat script, but accepts a
% previously saved session info file in place of the GetInfoGUI interactive
% session. This allows batch processing or re-processing of experimental
% data without user interaction.
%
%   Inputs:
%     infoFile   - Full path to a previously saved session info MAT file
%                  (created by GetInfoGUI or c3d2mat). The file must
%                  contain an info struct as its primary variable.
%     eventClass - (optional) String specifying the gait event detection
%                  method. Options:
%                    ''      - default: forces for TM trials, kinematics
%                              otherwise (default if omitted)
%                    'kin'   - strictly from kinematics (overground trials
%                              with limited or no force plate data)
%                    'force' - strictly from forces (treadmill trials with
%                              consistent, reliable force plate data)
%
%   Outputs:
%     expData    - Processed experimental data object
%     rawExpData - Raw experimental data object
%     adaptData  - Adaptation parameters data object
%
%   Toolbox Dependencies:
%     None
%
%   See also: c3d2mat, GetInfoGUI, loadSubject, errorProofInfo

arguments
    infoFile   (1,:) char
    eventClass (1,:) char = ''              % default gait event detection
end

%% Load Experimental Session Information
handles = loadInfoFile(infoFile,'');
out = errorProofInfo(handles,ignoreErrors);

%% Process Experimental Data
[expData,rawExpData,adaptData] = loadSubject(info,eventClass);

end

