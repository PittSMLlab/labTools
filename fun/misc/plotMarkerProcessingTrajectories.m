function mrkrData = plotMarkerProcessingTrajectories(trialPaths, savePath)
%PLOTMARKERPROCESSINGTRAJECTORIES Run marker pipelines on trials and save.
%
%   Iterates over trial paths and runs the OLD or NEW marker processing
% pipeline on each trial (selected by trial ID prefix), then saves all
% trajectory results to a .mat file.
%
% Inputs:
%   trialPaths - cell array of full trial folder paths
%   savePath   - full .mat file path to save the result
%
% Outputs:
%   mrkrData - struct with per-subject/trial trajectory data from
%              the OLD or NEW pipeline
%
% Toolbox Dependencies:
%   None
%
% See also PROCESSANDFILLMARKERGAPSTRIAL, PART1RL.

mrkrData = struct();

%% Process trials
for tr = 1:numel(trialPaths)
    trialPath = trialPaths{tr};
    [parentDir, trialID] = fileparts(trialPath);
    [~, subjectID]       = fileparts(parentDir);

    fprintf('\n--- Processing %s/%s ---\n', subjectID, trialID);

    if startsWith(trialID, 'Old_')
        try
            fprintf('Running OLD Pipeline on: %s\n', trialID);
            trajsOld = processAndFillMarkerGapsTrial(trialPath);
            mrkrData.(subjectID).(trialID).Old.trajectories = trajsOld;
        catch ME
            warning(ME.identifier, ...
                'OLD pipeline failed for %s/%s: %s', ...
                subjectID, trialID, ME.message);
        end
    else
        try
            fprintf('Running NEW Pipeline on: %s\n', trialID);
            trajsNew = Part1RL(trialPath);
            mrkrData.(subjectID).(trialID).New.trajectories = trajsNew;
        catch ME
            warning(ME.identifier, ...
                'NEW pipeline failed for %s/%s: %s', ...
                subjectID, trialID, ME.message);
        end
    end
end

%% Save
fprintf('\nSaving all trajectory data to: %s\n', savePath);
try
    save(savePath, 'mrkrData', '-v7.3');
    fprintf('Saved successfully.\n');
catch ME
    warning(ME.identifier, 'Failed to save results: %s', ME.message);
end

end

% function plotMarkerProcessingTrajectories(mrkrTrajs)
%     steps = fieldnames(mrkrTrajs);
%     markers = fieldnames(mrkrTrajs.Step1RandL);
%     components = {'X','Y','Z'};
%     colors = lines(numel(steps));
%     for m = 1:numel(markers)
%         marker = markers{m};
%
%         figure('Name', ['Trajectory - ' marker], 'NumberTitle', 'off');
%         tiledlayout(3,1);
%
%         for dim = 1:3  % X, Y, Z
%             nexttile;
%             hold on;
%
%             for s = 1:numel(steps)
%                 stepName = steps{s};
%                 traj = mrkrTrajs.(stepName).(marker);
%
%                 if size(traj,2) < 3
%                     warning('Trajectory for %s in %s is incomplete.', marker, stepName);
%                     continue;
%                 end
%
%                 plot(traj(:,dim), 'DisplayName', stepName, ...
%                     'Color', colors(s,:), 'LineWidth', 1.2);
%             end
%
%             title([marker ' - ' components{dim}]);
%             xlabel('Frame'); ylabel('Position (mm)');
%             legend('Location', 'best');
%             grid on;
%         end
%     end
% end
