function exportTrialToC3D(pathTrial,vicon)
%EXPORTTRIALTOC3D Saves a trial as a C3D file with no additional processing
%   This function checks if the specified trial is already open, only
% opening it if necessary, and saves it as a C3D file with no processing
% applied.
%
% input(s):
%   pathTrial: full path to the trial file
%   vicon: (optional) Vicon Nexus SDK object; connects if not provided

narginchk(1,2);                 % verify correct number of input arguments

% initialize the Vicon Nexus object if not provided
if nargin < 2 || isempty(vicon)
    fprintf(['No Vicon SDK object provided. Connecting to Vicon ' ...
        'Nexus...\n']);
    vicon = ViconNexus();
end

% open the trial if needed
if ~dataMotion.openTrialIfNeeded(pathTrial,vicon)
    return;     % exit if the trial could not be opened
end

% export to C3D file
fprintf('Exporting trial to C3D file\n');
try
    vicon.RunPipeline('SaveC3D','',200);
    fprintf('C3D file exported successfully\n');
catch ME
    warning(ME.identifier,'%s',ME.message);
end

end

