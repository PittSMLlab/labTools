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


%function mrkrData = plotMarkerProcessingTrajectories(trialPaths, savePath)
% plotMarkerProcessingTrajectories - runs OLD and NEW pipelines on all trial paths and saves result
%
% Inputs:
%   trialPaths - cell array of full trial folder paths
%   savePath   - full .mat file path to save the result

% mrkrData = struct(); % Initialize structure
% 
% for i = 1:numel(trialPaths)
%     trialPath = trialPaths{i};
%     [parentDir, trialID] = fileparts(trialPath);
%     [~, subjectID] = fileparts(parentDir);
% 
%     fprintf('\n--- Processing %s/%s ---\n', subjectID, trialID);
% 
%     % OLD pipeline
%     try
%         if startsWith(trialID, '(2)')
%             fprintf('Running OLD Pipeline on: %s\n', trialID);
%             trajsOld = processAndFillMarkerGapsTrial(trialPath);
%             mrkrData.(subjectID).(trialID).Old.trajectories = trajsOld;
%         else
%             fprintf('Running NEW Pipeline on: %s\n', trialID);
%             trajsNew = Part1RL(trialPath);
%             mrkrData.(subjectID).(trialID).New.trajectories = trajsNew;
%         end
%     catch ME
%         warning('Old pipeline failed for %s/%s: %s', subjectID, trialID, ME.message);
%     end
% end
% 
% % Save result
% fprintf('\nSaving all trajectory data to: %s\n', savePath);
% try
%     save(savePath, 'mrkrData', '-v7.3');
%     fprintf('Saved successfully.\n');
% catch ME
%     warning('Failed to save results: %s', ME.message);
% end
% 
% end

function mrkrData = plotMarkerProcessingTrajectories(trialPaths, savePath)
% plotMarkerProcessingTrajectories - runs OLD and NEW pipelines on all trial paths and saves result
%
% Inputs:
%   trialPaths - cell array of full trial folder paths
%   savePath   - full .mat file path to save the result

mrkrData = struct(); % Initialize structure

for i = 1:numel(trialPaths)
    trialPath = trialPaths{i};
    [parentDir, trialID] = fileparts(trialPath);
    [~, subjectID] = fileparts(parentDir);

    fprintf('\n--- Processing %s/%s ---\n', subjectID, trialID);

    if startsWith(trialID, 'Old_')
        % ----------------- OLD PIPELINE -----------------
        try
            fprintf('Running OLD Pipeline on: %s\n', trialID);
            trajsOld = processAndFillMarkerGapsTrial(trialPath);
            mrkrData.(subjectID).(trialID).Old.trajectories = trajsOld;
        catch ME
            warning('OLD pipeline failed for %s/%s: %s', subjectID, trialID, ME.message);
        end
    else
        % ----------------- NEW PIPELINE -----------------
        try
            fprintf('Running NEW Pipeline on: %s\n', trialID);
            trajsNew = Part1RL(trialPath);
            mrkrData.(subjectID).(trialID).New.trajectories = trajsNew;
        catch ME
            warning('NEW pipeline failed for %s/%s: %s', subjectID, trialID, ME.message);
        end
    end
end



% Save result
fprintf('\nSaving all trajectory data to: %s\n', savePath);
try
    save(savePath, 'mrkrData', '-v7.3');
    fprintf('Saved successfully.\n');
catch ME
    warning('Failed to save results: %s', ME.message);
end

end