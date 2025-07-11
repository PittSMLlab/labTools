markersToCompare = {'LGT'};
subject = 'C3S24';
trialPath = 'Z:\Nathan\ViconNexusReconstructAndLabel\Vicon\C3S24_S1\Trial16';

% Connect to Vicon and open trial
fprintf('Connecting to Vicon Nexus...\n');
vicon = ViconNexus();
dataMotion.openTrialIfNeeded(trialPath, vicon);
pause(2);

% Run the optimized pipeline function (assumes this saves the trial)
fprintf('Running optimized pipeline...\n');
Part1RL(trialPath);  
pause(5);

trajData = struct();

for m = 1:numel(markersToCompare)
    nameMarker = markersToCompare{m};
    try 
        [trajX, trajY, trajZ, existsTraj] = vicon.GetTrajectory(subject, nameMarker);
        times = (1:numel(trajX)) / 100;  % or use frameStart/frameEnd for time
        
        if any(existsTraj)
            trajX2 = trajX; trajX2(~existsTraj) = NaN;
            trajY2 = trajY; trajY2(~existsTraj) = NaN;
            trajZ2 = trajZ; trajZ2(~existsTraj) = NaN;

            figure('Name', ['Trajectories for ' nameMarker], 'NumberTitle', 'off');
            tl = tiledlayout(3,1);

            ax1 = nexttile;
            plot(times, trajX2); ylabel('X (mm)');
            title([nameMarker ' - X']);

            ax2 = nexttile;
            plot(times, trajY2); ylabel('Y (mm)');
            title([nameMarker ' - Y']);

            ax3 = nexttile;
            plot(times, trajZ2); ylabel('Z (mm)');
            title([nameMarker ' - Z']);
            xlabel('Time (s)');

            drawnow;
            pause(0.1);  % ensures figure updates
        else
            warning('No valid data for %s.', nameMarker);
        end
    end
end