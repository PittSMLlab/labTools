function reader = getC3DReader()
%GETC3DREADER Select the C3D reader for this computer: BTK or ezc3d.
%
%   BTK (Biomechanical ToolKit) is the default reader. It is distributed
% only as compiled MEX files, and the copy bundled in fun/ext/BTK has no
% binaries for some platforms (e.g., Apple Silicon Macs, where MATLAB
% then resolves btkReadAcquisition to an @IO class method and fails with
% "Incorrect number or types of inputs or outputs"). When no BTK MEX file
% exists for the running platform, ezc3d is used instead; its output is
% converted to match BTK's exactly (see GETC3DANALOGS, GETC3DMARKERS).
%
%   The choice can be forced with a MATLAB preference, e.g. to validate
% the readers against each other on a computer where both work:
%     setpref('labTools', 'c3dReader', 'ezc3d')   % or 'btk' or 'auto'
%
%   Inputs:
%     none
%
%   Outputs:
%     reader - 'btk' or 'ezc3d'
%
%   Toolbox Dependencies:
%     None (BTK or ezc3d must be available for the reader selected)
%
%   See also READC3DACQUISITION, GETC3DANALOGS, GETC3DMARKERS,
%   VALIDATEC3DREADERS.

persistent hasWarned        % show the ezc3d notice once per session

%% Honor an Explicit Preference
choice = getpref('labTools', 'c3dReader', 'auto');
if ~any(strcmpi(choice, {'auto', 'btk', 'ezc3d'}))
    error('getC3DReader:badPreference', ['Preference labTools/' ...
        'c3dReader must be ''auto'', ''btk'' or ''ezc3d''.']);
end
if strcmpi(choice, 'btk')
    reader = 'btk';
    return
end

%% Detect Whether BTK Can Run on This Platform
% BTK functions are MEX files; without a binary for this platform's MEX
% extension MATLAB finds only BTK's help/class-method .m files.
btkPath   = which('btkReadAcquisition');
btkUsable = endsWith(btkPath, ['.' mexext()]);
if strcmpi(choice, 'auto') && btkUsable
    reader = 'btk';
    return
end

%% Fall Back to ezc3d
addEzc3dToPath();
reader = 'ezc3d';
if strcmpi(choice, 'auto') && isempty(hasWarned)
    hasWarned = true;
    warning('getC3DReader:usingEzc3d', ['No BTK binary for this ' ...
        'platform (%s, %s); reading C3D files with ezc3d instead.'], ...
        computer('arch'), mexext());
end

end

function addEzc3dToPath()
%ADDEZC3DTOPATH Ensure ezc3dRead is callable, or explain how to get it.
%
%   Looks for ezc3d on the MATLAB path, then in fun/ext/ezc3d of this
% labTools copy. Errors with download instructions if not found.
%
%   Inputs:
%     none
%
%   Outputs:
%     none

if exist('ezc3dRead', 'file') == 3      % MEX already on the path
    return
end
labToolsRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
bundled = dir(fullfile(labToolsRoot, 'fun', 'ext', 'ezc3d', '**', ...
    ['ezc3dRead.' mexext()]));
if ~isempty(bundled)
    addpath(bundled(1).folder);
    return
end
error('getC3DReader:noReader', ['No C3D reader is available for this ' ...
    'platform (%s).\nBTK has no binary for it; download the ezc3d ' ...
    'MATLAB binaries (Release 1.7.2 or later) from\n' ...
    'https://github.com/pyomeca/ezc3d/releases, unzip them, and add ' ...
    'the folder to the MATLAB path\n(or place it in %s).'], ...
    computer('arch'), fullfile(labToolsRoot, 'fun', 'ext', 'ezc3d'));
end
