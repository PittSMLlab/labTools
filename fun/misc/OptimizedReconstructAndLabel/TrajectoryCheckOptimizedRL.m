markersToCompare = {'RANK'};  % Update as needed
subject = 'C3S24';           % Confirm this is the correct subject
trialOld = 'Z:\Nathan\ViconNexusReconstructAndLabel\Vicon\C3S24_S1\(2)Trial16';
trialNew = 'Z:\Nathan\ViconNexusReconstructAndLabel\Vicon\C3S24_S1\Trial16';

trajData = struct();

%% Load Old Trial Trajectories
fprintf('\n=== Loading Old Trial ===\n');
viconOld = ViconNexus();
dataMotion.openTrialIfNeeded(trialOld, viconOld);
pause(2);

% Confirm subject and markers
subjectsOld = viconOld.GetSubjectNames();
disp('Subjects in Old Trial:'); disp(subjectsOld);
subject = subjectsOld{1};  % Use correct subject name if needed

markerNamesOld = viconOld.GetMarkerNames(subject);
disp('Markers in Old Trial:'); disp(markerNamesOld');

for m = 1:numel(markersToCompare)
    marker = markersToCompare{m};
    if ~any(strcmp(markerNamesOld, marker))
        warning('Marker %s not found in OLD trial.', marker);
        continue;
    end
    [trajX, trajY, trajZ, existsTraj] = viconOld.GetTrajectory(subject, marker);
    traj = NaN(length(trajX), 3);
    trajX = trajX(:);
    trajY = trajY(:);
    trajZ = trajZ(:);
    traj(existsTraj, :) = [trajX(existsTraj), trajY(existsTraj), trajZ(existsTraj)];
    trajData.(marker).Old = traj;
end

%% Load New Trial Trajectories
fprintf('\n=== Loading New Trial ===\n');
viconNew = ViconNexus();
dataMotion.openTrialIfNeeded(trialNew, viconNew);
pause(2);

subjectsNew = viconNew.GetSubjectNames();
disp('Subjects in New Trial:'); disp(subjectsNew);
subject = subjectsNew{1};  % Reconfirm if needed

markerNamesNew = viconNew.GetMarkerNames(subject);
disp('Markers in New Trial:'); disp(markerNamesNew');

for m = 1:numel(markersToCompare)
    marker = markersToCompare{m};
    if ~any(strcmp(markerNamesNew, marker))
        warning('Marker %s not found in NEW trial.', marker);
        continue;
    end
    [trajX, trajY, trajZ, existsTraj] = viconNew.GetTrajectory(subject, marker);
    traj = NaN(length(trajX), 3);
    trajX = trajX(:);
    trajY = trajY(:);
    trajZ = trajZ(:);
    traj(existsTraj, :) = [trajX(existsTraj), trajY(existsTraj), trajZ(existsTraj)];
    trajData.(marker).New = traj;
end

%% Plot Overlaid Trajectories
components = {'X', 'Y', 'Z'};

for m = 1:numel(markersToCompare)
    marker = markersToCompare{m};
    
    if ~isfield(trajData.(marker), 'Old') || ~isfield(trajData.(marker), 'New')
        warning('Skipping %s due to missing data.', marker);
        continue;
    end
    
    trajOld = trajData.(marker).Old;
    trajNew = trajData.(marker).New;
    
    if isempty(trajOld) || isempty(trajNew) || ...
       all(all(isnan(trajOld))) || all(all(isnan(trajNew)))
        warning('Skipping plot for %s due to NaN trajectories.', marker);
        continue;
    end
    
    nFrames = min(size(trajOld,1), size(trajNew,1));
    time = (1:nFrames) / 100;  % Adjust sampling rate if not 100 Hz

    figure('Name', ['Overlay - ' marker], 'NumberTitle', 'off');
    tiledlayout(3,1);
    
    for dim = 1:3
        nexttile;
        hold on;
        plot(time, trajOld(1:nFrames,dim), 'b', 'DisplayName', 'Old');
        plot(time, trajNew(1:nFrames,dim), 'r--', 'DisplayName', 'New');
        title([marker ' - ' components{dim}]);
        xlabel('Time (s)'); ylabel('Position (mm)');
        legend('Location', 'best');
        hold off;
    end
end