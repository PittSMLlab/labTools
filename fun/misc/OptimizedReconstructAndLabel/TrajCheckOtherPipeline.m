%% Trajectory Check — Other Pipeline
% Connects to Vicon Nexus, runs the optimized processing pipeline on a
% specified trial, and plots X/Y/Z trajectories for each marker of
% interest.

markersToCompare = {'LGT'};
subject          = 'C3S24';
trialPath        = 'Z:\Nathan\ViconNexusReconstructAndLabel\Vicon\C3S24_S1\(2)Trial16';

fprintf('Connecting to Vicon Nexus...\n');
vicon = ViconNexus();
dataMotion.openTrialIfNeeded(trialPath, vicon);
pause(2);

fprintf('Running optimized pipeline...\n');
processAndFillMarkerGapsTrial(trialPath, vicon);
pause(5);

trajData = struct();

for mrkr = 1:numel(markersToCompare)
    nameMarker = markersToCompare{mrkr};
    try
        [trajX, trajY, trajZ, existsTraj] = ...
            vicon.GetTrajectory(subject, nameMarker);
        times = (1:numel(trajX)) / 100;

        if any(existsTraj)
            trajX2 = trajX; trajX2(~existsTraj) = NaN;
            trajY2 = trajY; trajY2(~existsTraj) = NaN;
            trajZ2 = trajZ; trajZ2(~existsTraj) = NaN;

            figure('Name', ['Trajectories for ' nameMarker], ...
                'NumberTitle', 'Off');
            tiledlayout(3, 1);

            nexttile;
            plot(times, trajX2);
            ylabel('X (mm)');
            title([nameMarker ' - X']);

            nexttile;
            plot(times, trajY2);
            ylabel('Y (mm)');
            title([nameMarker ' - Y']);

            nexttile;
            plot(times, trajZ2);
            ylabel('Z (mm)');
            title([nameMarker ' - Z']);
            xlabel('Time (s)');

            drawnow;
            pause(0.1);
        else
            warning('No valid data for %s.', nameMarker);
        end
    catch ME
        warning('Could not retrieve trajectory for %s: %s', ...
            nameMarker, ME.message);
    end
end
