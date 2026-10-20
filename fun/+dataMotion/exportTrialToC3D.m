function exportTrialToC3D(pathTrial,vicon)
%EXPORTTRIALTOC3D Save a trial as a C3D file with no processing.
%
%   Opens the trial in Vicon Nexus if it is not already open and runs the
% SaveC3D pipeline on it.
%
% Side effects: needs a running Vicon Nexus (a connection is opened when
%   no vicon object is passed); opens the trial and writes its C3D file.
%   A failed export only warns.
%
% Inputs:
%   pathTrial - full path to the trial file
%   vicon     - (optional) Vicon Nexus SDK object
%
% Outputs:
%   none
%
% Toolbox Dependencies: None
%
% See also DATAMOTION.EXPORTSESSIONTOC3D, DATAMOTION.OPENTRIALIFNEEDED.

narginchk(1,2);                 % verify correct number of input arguments

%% Connect to Nexus and open the trial
if nargin < 2 || isempty(vicon)
    fprintf(['No Vicon SDK object provided. Connecting to Vicon ' ...
        'Nexus...\n']);
    vicon = ViconNexus();
end

% open the trial if needed
if ~dataMotion.openTrialIfNeeded(pathTrial,vicon)
    return;     % exit if the trial could not be opened
end

%% Export
fprintf('Exporting trial to C3D file\n');
try
    vicon.RunPipeline('SaveC3D','',200);
    fprintf('C3D file exported successfully\n');
catch ME
    warning(ME.identifier,'%s',ME.message);
end

end

