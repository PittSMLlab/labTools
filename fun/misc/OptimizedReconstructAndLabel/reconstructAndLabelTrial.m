function reconstructAndLabelTrial(pathTrial, vicon, shouldSave)
%RECONSTRUCTANDLABELTRIAL Run reconstruct and label pipeline on a trial.
%
%   Accepts the full path to a Vicon Nexus trial folder, opens the
% trial if needed, runs the reconstruct and label pipeline, and
% optionally saves the result. Requires the Vicon Nexus SDK on the
% MATLAB path.
%
% Inputs:
%   pathTrial  - String or character array; full path to the trial
%                folder on which to run the pipeline
%   vicon      - (optional) Vicon Nexus SDK object; connects if not
%                supplied
%   shouldSave - (optional) Logical; whether to save changes after
%                processing (default: true)
%
% Outputs:
%   None
%
% Toolbox Dependencies: None
%
% See also RECONSTRUCTANDLABELSESSION.

% TODO: add a GUI input option if helpful
narginchk(1, 3);

if nargin < 3 || isempty(shouldSave)
    shouldSave = true;
end

if nargin < 2 || isempty(vicon)
    fprintf(['No Vicon SDK object provided. Connecting to Vicon ' ...
        'Nexus...\n']);
    vicon = ViconNexus();
end

if ~dataMotion.openTrialIfNeeded(pathTrial, vicon)
    return;
end

% The reconstruct and label step processes raw camera data, reconstructs
% 3D marker positions, and assigns names per the Vicon labeling scheme.
fprintf('Running reconstruction and labeling pipeline...\n');
try
    vicon.RunPipeline('Reconstruct And Label', '', 200);
    fprintf('Reconstruction and labeling complete.\n');
catch ME
    warning(ME.identifier, '%s', ME.message);
end

if shouldSave
    fprintf('Saving the trial...\n');
    try
        vicon.SaveTrial(200);
        fprintf('Trial saved successfully.\n');
    catch ME
        warning(ME.identifier, '%s', ME.message);
    end
else
    fprintf('Save option is disabled; trial not saved.\n');
end

end
