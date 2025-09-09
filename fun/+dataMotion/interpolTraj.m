function interpolTraj(pathSess,indsTrials,vicon)
% %INTERPOLTRAJ Interpolates trajectories to fill in marker gaps 
% %   This function fills in the marker gaps by interpolating the trajectory of each X,Y,Z direction. 
% %   Make sure the Vicon Nexus SDK is installed and added to the MATLAB path.
% %
% % input(s):
% %   pathSess: path to the session folder where all trial data is stored.
% %   nameMarker: marker of choice for which trajectory you want to fill
% %   indsTrials: (optional) array of indices indicating which trials to
% %       process. By default, all files starting with 'Trial' are processed.
% %   vicon: (optional) Vicon Nexus SDK object. If not supplied, a new Vicon
% %       object will be created and connected.
% 
% narginchk(1,4);                 % verify correct number of input arguments
% 
% % ensure session folder path exists
% if ~isfolder(pathSess)
%     error('The session folder path specified does not exist: %s',pathSess);
% end
% 
% % get all trial files that start with 'Trial'
% trialFiles = dir(fullfile(pathSess,'Trial*.x1d'));
% if isempty(trialFiles)      % if no trial files found, ...
%     fprintf('No trials found in session folder: %s\n',pathSess);
%     return;
% end
% 
% % extract trial indices from filenames
% [~,namesFiles] = cellfun(@fileparts,{trialFiles.name}, ...
%     'UniformOutput',false);
% indsTrialsAll = cellfun(@(s) str2double(s(end-1:end)),namesFiles);
% 
% % select trials to process
% if nargin < 2 || isempty(indsTrials)    % if 'indsTrials' not provided, ...
%     indsTrials = indsTrialsAll;         % process all trials
% else    % otherwise, ensure no values provided as input do not exist
%     indsTrials = indsTrials(ismember(indsTrials,indsTrialsAll));
% end
% 
% % initialize the Vicon Nexus object if not provided
% if nargin < 3 || isempty(vicon)
%     fprintf(['No Vicon SDK object provided. Connecting to Vicon ' ...
%         'Nexus...\n']);
%     vicon = ViconNexus();
% end
% 
% for tr = indsTrials     % for each trial specified, ...
%     pathTrial = fullfile(pathSess,sprintf('Trial%02d',tr));
%     fprintf('Processing trial %d: %s\n',tr,pathTrial);
% 
%     % run reconstruct and label pipeline on the trial
%     dataMotion.reconstructAndLabelTrial(pathTrial,vicon);
% 
% end
% 
% if ~dataMotion.openTrialIfNeeded(pathTrial,vicon)
%     return;                         % exit if the trial could not be opened
% end
% 
% 
% fprintf('All specified trials have been processed.\n');
% 
% 
% % get subject name (assuming only one subject in the trial)
% subject = vicon.GetSubjectNames();
% 
% if isempty(subject)
%     error('No subject found in the trial.');
% end
% subject = subject{1};
% % get trajectory of each direction of the marker of choice 
% nameMarker = input('Enter the marker name (e.g., RGT, RKNEE, RANK, etc): ', 's');
% 
% [X,Y,Z,existsTraj] = vicon.GetTrajectory(subject,nameMarker);
% 
% %% Loop 
% % Example of data for X, Y, Z
% X_exist = X; 
% Y_exist = Y;
% Z_exist = Z;
% 
% % Assume existsTraj contains the binary data for the existence of trajectory data (1 for existing data, 0 for missing data)
% X_exist(existsTraj == 0) = nan; 
% Y_exist(existsTraj == 0) = nan; 
% Z_exist(existsTraj == 0) = nan;
% 
% % Set cycle 
% cycle_test=1:length(X);
%     
% variables = {'X', 'Y', 'Z'};
% for trajvar = variables
%     % Extract the variable name from the cell
%     var_name = trajvar{1};
%     
%     % Get the corresponding variable data
%     data_exist = eval([var_name, '_exist']);  % Get the variable data dynamically
% 
%     % Cut the trajectory array to match the size of the cycle
%     data_exist_test = data_exist(cycle_test);
%     
%     % Cut the cycle and trajectory array to start from the first non-NaN value
%     idx = find(~isnan(data_exist_test), 1);
%     cycle_test_cut = cycle_test(cycle_test(1) + idx:end);
%     data_exist_test_cut = data_exist(cycle_test_cut);
% 
%     % Find known (non-NaN) data indices
%     known_idx = ~isnan(data_exist_test_cut);
% 
%     % Interpolate the trajectory of the cycle using the known data
%     data_filled = interp1(cycle_test_cut(known_idx), data_exist_test_cut(known_idx), cycle_test_cut, 'makima');
%    
%     % Dynamically create the filled data variable names (e.g., data_filled_X, data_filled_Y, etc.)
%     eval([var_name, '_data_filled = data_filled;']);
%     
%     % Plot the interpolated trajectory over the original data
%     figure;
%     plot(cycle_test_cut, data_exist_test_cut, 'bo', 'LineWidth', 1, 'MarkerSize', 2, 'DisplayName', [var_name, ' - Original Data (with NaNs)']);
%     hold on;
%     plot(cycle_test_cut, data_filled, 'ro-', 'MarkerSize', 1, 'DisplayName', [var_name, ' - Interpolated Data']);
%     hold off;
%     title([var_name, ' - Interpolation']);
%     xlabel('Cycle');
%     ylabel('Value');
%     legend('Location', 'best');;
%     
%     % Update the interpolated trajectory on Vicon
%     vicon.SetTrajectory(subject,nameMarker,X_data_filled,Y_data_filled,Z_data_filled,existsTraj);
%     
% end
%% 
%INTERPOLTRAJ Interpolates trajectories to fill in marker gaps 
%   This function fills in the marker gaps by interpolating the trajectory of each X,Y,Z direction. 
%   Make sure the Vicon Nexus SDK is installed and added to the MATLAB path.
%
% input(s):
%   pathSess: path to the session folder where all trial data is stored.
%   nameMarkers: cell array of marker names for which trajectories you want to fill (e.g., {'RGT', 'RKNEE', 'RANK'})
%   indsTrials: (optional) array of indices indicating which trials to process. By default, all files starting with 'Trial' are processed.
%   vicon: (optional) Vicon Nexus SDK object. If not supplied, a new Vicon object will be created and connected.

narginchk(1,4);                 % verify correct number of input arguments

% ensure session folder path exists
if ~isfolder(pathSess)
    error('The session folder path specified does not exist: %s',pathSess);
end

% get all trial files that start with 'Trial'
trialFiles = dir(fullfile(pathSess,'Trial*.x1d'));
if isempty(trialFiles)      % if no trial files found, ...
    fprintf('No trials found in session folder: %s\n',pathSess);
    return;
end

% extract trial indices from filenames
[~,namesFiles] = cellfun(@fileparts,{trialFiles.name}, ...
    'UniformOutput',false);
indsTrialsAll = cellfun(@(s) str2double(s(end-1:end)),namesFiles);

% select trials to process
if nargin < 2 || isempty(indsTrials)    % if 'indsTrials' not provided, ...
    indsTrials = indsTrialsAll;         % process all trials
else    % otherwise, ensure no values provided as input do not exist
    indsTrials = indsTrials(ismember(indsTrials,indsTrialsAll));
end

% initialize the Vicon Nexus object if not provided
if nargin < 3 || isempty(vicon)
    fprintf(['No Vicon SDK object provided. Connecting to Vicon ' ...
        'Nexus...\n']);
    vicon = ViconNexus();
end

reconstruct_y = input('Run Reconstruct and Label? "Y" or "N": ');



fprintf('All specified trials have been processed.\n');

% get subject name (assuming only one subject in the trial)
subject = vicon.GetSubjectNames();

if isempty(subject)
    error('No subject found in the trial.');
end
subject = subject{1};

% Input for multiple markers (this can be given as a cell array)
nameMarkers = input('Enter the marker names (e.g., {''RGT'', ''RKNEE'', ''RANK''}): ');

for tr = indsTrials     % for each trial specified, ...
    pathTrial = fullfile(pathSess,sprintf('Trial%02d',tr));
    
    if ~dataMotion.openTrialIfNeeded(pathTrial,vicon)
        return;                         % exit if the trial could not be opened
    end
    if reconstruct_y == 'Y'
        % run reconstruct and label pipeline on the trial
        dataMotion.reconstructAndLabelTrial(pathTrial,vicon);
    end 
    fprintf('Processing trial %d: %s\n',tr,pathTrial);
    % Loop over all markers
    for markerIdx = 1:length(nameMarkers)
        nameMarker = nameMarkers{markerIdx};
        fprintf('Processing marker: %s\n', nameMarker);
        
        % Get trajectory of each direction of the marker of choice
        data_filled_matrix = []; % Initialize an empty matrix
        [X, Y, Z, existsTraj] = vicon.GetTrajectory(subject, nameMarker);
        
        % Example of data for X, Y, Z
        X_exist = X;
        Y_exist = Y;
        Z_exist = Z;
        
        % Assume existsTraj contains the binary data for the existence of trajectory data (1 for existing data, 0 for missing data)
        X_exist(existsTraj == 0) = nan;
        Y_exist(existsTraj == 0) = nan;
        Z_exist(existsTraj == 0) = nan;
        
        % Set cycle
        cycle_test = 1:length(X);
        
        % Process each direction (X, Y, Z)
        variables = {'X', 'Y', 'Z'};
        
        for trajvar = variables
            % Extract the variable name from the cell
            var_name = trajvar{1};
            
            % Get the corresponding variable data
            data_exist = eval([var_name, '_exist']);  % Get the variable data dynamically
            
            % Cut the trajectory array to match the size of the cycle
            data_exist_test = data_exist(cycle_test);
            
%             % Find divisors of the given number n
%             divisors = [];
%             for i = 1:length(data_exist_test)
%                 if mod(length(data_exist_test), i) == 0
%                     divisors = [divisors, i];  % Store the divisor
%                 end
%             end
%             
%             % Find the closest divisor to 100
%             [~, idx] = min(abs(divisors - 100));  % Find the index with the minimum difference
%             closest_divisor = divisors(idx);  % Return the closest divisor
            
            windowSize = 100;  % Define the moving window size
            %         data_outlier_loc = ~isoutlier(data_exist_test,"movmedian",windowSize);
            moving_mean = movmean(data_exist_test, windowSize);
            moving_std = movstd(data_exist_test, windowSize);
            
            % Define a more conservative threshold (e.g., 2 standard deviations)
            threshold = 1.5;
            
            % Identify outliers: points that are outside of mean ± threshold * std
            data_outlier_loc = (data_exist_test < moving_mean - threshold * moving_std) | ...
                (data_exist_test > moving_mean + threshold * moving_std);
            data_exist_filt = data_exist_test(~data_outlier_loc);
            
            % Cut the cycle and trajectory array to start from the first non-NaN value
            idx = find(~isnan(data_exist_filt));
            cycle_test_cut = cycle_test(1 + idx(1):idx(end));
            data_exist_filt_cut = data_exist_filt(cycle_test_cut);
            
            
            % Find known (non-NaN) data indices
            known_idx = ~isnan(data_exist_filt_cut);
            
            % Interpolate the trajectory of the cycle using the known data
            data_filled = interp1(cycle_test_cut(known_idx), data_exist_filt_cut(known_idx), cycle_test_cut, 'makima');
            
            % Fill in zeros to match the size of the original data
            data_filled_match = [zeros(1,idx(1)),data_filled,zeros(1,length(cycle_test)-idx(end))];
            
            % Append the interpolated data for this variable to the matrix
            data_filled_matrix = [data_filled_matrix; data_filled_match];
            existsTraj(idx+1:end) = true;
            
            % Plot the interpolated trajectory over the original data
            figure;
            plot(cycle_test_cut, data_exist_filt_cut, 'bo', 'LineWidth', 1, 'MarkerSize', 2, 'DisplayName', [var_name, ' - Original Data (with NaNs)']);
            hold on;
            plot(cycle_test_cut, data_filled, 'ro-', 'MarkerSize', 1, 'DisplayName', [var_name, ' - Interpolated Data']);
            hold off;
            title([var_name, ' - Interpolation; ',nameMarker]);
            xlabel('Cycle');
            ylabel('Value');
            legend('Location', 'best');
            
        end
        % Update trajectory on vicon
        vicon.SetTrajectory(subject,nameMarker,data_filled_matrix(1,:),data_filled_matrix(2,:),data_filled_matrix(3,:),existsTraj);
        fprintf(append(nameMarker, ' trajectory interpolation completed.\n'));
        
    end
    vicon.SaveTrial(200);
end


%%
% Initialize matrix to store the filled data (X, Y, Z)



%%
% % Loop over all markers
% for markerIdx = 1:length(nameMarkers)
%     nameMarker = nameMarkers{markerIdx};
%     fprintf('Processing marker: %s\n', nameMarker);
%     
%     % Get trajectory of each direction of the marker of choice 
%     [X, Y, Z, existsTraj] = vicon.GetTrajectory(subject, nameMarker);
%     
%     % Example of data for X, Y, Z
%     X_exist = X; 
%     Y_exist = Y;
%     Z_exist = Z;
% 
%     % Assume existsTraj contains the binary data for the existence of trajectory data (1 for existing data, 0 for missing data)
%     X_exist(existsTraj == 0) = nan; 
%     Y_exist(existsTraj == 0) = nan; 
%     Z_exist(existsTraj == 0) = nan;
% 
%     % Set cycle 
%     cycle_test = 1:length(X);
%     
%     % Process each direction (X, Y, Z)
%     variables = {'X', 'Y', 'Z'};
%     for trajvar = variables
%         % Extract the variable name from the cell
%         var_name = trajvar{1};
%         
%         % Get the corresponding variable data
%         data_exist = eval([var_name, '_exist']);  % Get the variable data dynamically
% 
%         % Cut the trajectory array to match the size of the cycle
%         data_exist_test = data_exist(cycle_test);
%         
%         % Cut the cycle and trajectory array to start from the first non-NaN value
%         idx = find(~isnan(data_exist_test), 1);
%         cycle_test_cut = cycle_test(1 + idx:end);
%         data_exist_test_cut = data_exist(cycle_test_cut);
% 
%         % Find known (non-NaN) data indices
%         known_idx = ~isnan(data_exist_test_cut);
% 
%         % Interpolate the trajectory of the cycle using the known data
%         data_filled = interp1(cycle_test_cut(known_idx), data_exist_test_cut(known_idx), cycle_test_cut, 'makima');
%         
%         % Dynamically create the filled data variable names (e.g., data_filled_X, data_filled_Y, etc.)
%         eval([var_name, '_data_filled_', nameMarker, ' = data_filled;']);
%         
%         % Plot the interpolated trajectory over the original data
%         figure;
%         plot(cycle_test_cut, data_exist_test_cut, 'bo', 'LineWidth', 1, 'MarkerSize', 2, 'DisplayName', [var_name, ' - Original Data (with NaNs)']);
%         hold on;
%         plot(cycle_test_cut, data_filled, 'ro-', 'MarkerSize', 1, 'DisplayName', [var_name, ' - Interpolated Data']);
%         hold off;
%         title([var_name, ' - Interpolation']);
%         xlabel('Cycle');
%         ylabel('Value');
%         legend('Location', 'best');
%         
%         % Update the interpolated trajectory on Vicon for this marker
%         eval(['vicon.SetTrajectory(subject, nameMarker, ', var_name, '_data_filled_', nameMarker, ', existsTraj);']);
%     end
%     vicon.SetTrajectory(subject,nameMarker,,Y_data_filled,Z_data_filled,existsTraj);
% end

%% Butterworth filter 

% d1 = designfilt("lowpassiir",FilterOrder=2, ...
%     HalfPowerFrequency=0.15,DesignMethod="butter");
% [b,a] = butter(6,fc/(fs/2));
% X_new_filt = filtfilt(b,a,X_new);
% 
% figure;
% plot(cycle_test, X_existtest, 'bo-', 'LineWidth', 1, 'MarkerSize', 2, 'DisplayName', 'Original Data (with NaNs)');
% hold on;
% plot(cycle_test, X_new_filt,'r-')
% hold off;

end
