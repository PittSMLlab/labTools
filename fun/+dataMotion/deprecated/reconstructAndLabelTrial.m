function reconstructAndLabelTrial(pathTrial,vicon,shouldSave)
%RECONSTRUCTANDLABEL Run reconstruct and label pipeline on Vicon trial data
%   This function accepts as input the full path to the trial to process by
% running the reconstruct and label pipelines and saving the processed
% trial. Make sure the Vicon Nexus SDK is installed and added to the MATLAB
% path.
%
% input(s):
%   pathTrial: string or character array of the full path of the trial on
%       which to run the reconstruct and label processing pipeline
%   vicon: (optional) Vicon Nexus SDK object; connects if not supplied.
%   shouldSave: (optional) logical, whether to save changes (default: true)

% TODO: add a GUI input option if helpful
narginchk(1,3);         % verify correct number of input arguments

if nargin < 3 || isempty(shouldSave)       % if no 'shouldSave' input
    shouldSave = true;                     % default to saving changes
end

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

% The reconstruct and label step will process the raw camera data and
% reconstruct 3D marker positions. The labeling step assigns names to the
% reconstructed markers based on the Vicon Nexus labeling scheme.
fprintf('Running reconstruction and labeling pipeline...\n');
try                     % try running reconstruct and label pipeline
    vicon.RunPipeline('Reconstruct And Label','',200);
    fprintf('Reconstruction and labeling complete.\n');
catch ME
    warning(ME.identifier,'%s',ME.message);
end

% saves the trial changes made if 'shouldSave' is true back to trial file
if shouldSave
    fprintf('Saving the trial...\n');
    try                     % try saving the processed trial
        vicon.SaveTrial(200);
        fprintf('Trial saved successfully.\n');
    catch ME
        warning(ME.identifier,'%s',ME.message);
    end
else
    fprintf('Save option is disabled; trial not saved.\n');
end

end

