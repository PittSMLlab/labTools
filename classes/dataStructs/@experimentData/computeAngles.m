function this = computeAngles(this)
%COMPUTEANGLES Calculates joint angles for all trials
%
%   this = computeAngles(this) computes limb angles from marker data for all
% trials in the experiment
%
% Inputs:
%   this - experimentData object
%
% Outputs:
%   this - experimentData object with angleData populated
%
% Toolbox Dependencies: None
%
% See also LABDATA.CALCLIMBANGLES.

for trial = 1:length(this.data)
    disp(['Computing angles for trial ' num2str(trial) '...']);
    if ~isempty(this.data{trial})
        this.data{trial}.angleData = ...
            this.data{trial}.calcLimbAngles();
    else
        % not implemented
    end
end
end

