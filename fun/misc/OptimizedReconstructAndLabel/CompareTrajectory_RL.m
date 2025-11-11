markersToCompare = {'LGT', 'LANK'};
subject = 'C3S24';
basePath = 'Z:\Nathan\ViconNexusReconstructAndLabel\Vicon\C3S24_S1';
trialName = 'Trial16';
trialPath = fullfile(basePath, trialName);

trajData = struct();

% -----------------------------
% Step 1: OLD PIPELINE
% -----------------------------
fprintf('\n=== Running OLD pipeline ===\n');
viconOld = ViconNexus();
dataMotion.openTrialIfNeeded(trialPath, viconOld);
pause(2);

disp(viconOld.GetMarkerNames(subject));  % for old
disp(viconNew.GetMarkerNames(subject));  % for new

for m = 1:numel(markersToCompare)
    marker = markersToCompare{m};
    try
        [trajX, trajY, trajZ, existsTraj] = viconOld.GetTrajectory(subject, marker);
        traj = NaN(length(trajX), 3);
        traj(existsTraj, :) = [trajX(existsTraj), trajY(existsTraj), trajZ(existsTraj)];
        trajData.(marker).Old = NaN(0,3);
    catch
        warning('Could not retrieve OLD trajectory for %s.', marker);
        trajData.(marker).Old = NaN(0,3);
    end
end

% -----------------------------
% Step 2: NEW (Optimized) PIPELINE
% -----------------------------
fprintf('\n=== Running NEW (optimized) pipeline ===\n');
viconNew = ViconNexus();
dataMotion.openTrialIfNeeded(trialPath, viconNew);
pause(2);
try
    viconNew.CloseTrial(200);  % Close with force
    pause(2);
catch
    warning('Could not close trial before re-opening.');
end
Part1RL(trialPath);
%Part1RL(trialPath);  % Replace with your optimized R&L pipeline
pause(3);

for m = 1:numel(markersToCompare)
    marker = markersToCompare{m};
    try
        [trajX, trajY, trajZ, existsTraj] = viconNew.GetTrajectory(subject, marker);
        traj = NaN(length(trajX), 3);
        traj(existsTraj, :) = [trajX(existsTraj), trajY(existsTraj), trajZ(existsTraj)];
        trajData.(marker).New = NaN(0,3);
    catch
        warning('Could not retrieve NEW trajectory for %s.', marker);
        trajData.(marker).New = NaN(0,3);
    end
end

% -----------------------------
% Step 3: PLOTTING
% -----------------------------
components = {'X', 'Y', 'Z'};

for m = 1:numel(markersToCompare)
    marker = markersToCompare{m};
    trajOld = trajData.(marker).Old;
    trajNew = trajData.(marker).New;
    nFrames = size(trajOld, 1);
    time = (1:nFrames) / 100;  % 100 Hz

    figure('Name', ['Trajectory Comparison: ' marker], 'NumberTitle', 'off');
    tiledlayout(3,1);

    for dim = 1:3
        nexttile;
        hold on;
        title(sprintf('%s - %s trajectory', marker, components{dim}));
        xlabel('Time (s)');
        ylabel('Position (mm)');

        if ~isempty(trajOld) && ~all(isnan(trajOld(:,dim)))
            plot(time, trajOld(:,dim), 'b', 'DisplayName', 'Old');
        end
        if ~isempty(trajNew) && ~all(isnan(trajNew(:,dim)))
            plot(time, trajNew(:,dim), 'r--', 'DisplayName', 'New');
        end
        legend;
        hold off;
    end
end