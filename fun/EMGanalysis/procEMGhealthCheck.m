function h = procEMGhealthCheck(procExperimentData)
%PROCEMGHEALTHCHECK Plot processed EMG of every trial for a visual check.
%
%   For each trial, opens a figure with the processed EMG channels in
% groups of four per subplot, linked on the time axis.
%
% Side effects: opens one figure per non-empty trial (figure number =
%   trial number).
%
% Inputs:
%   procExperimentData - processed experimentData whose trials hold
%                        procEMGData
%
% Outputs:
%   h - figure handles, indexed by trial
%
% Toolbox Dependencies: None
%
% See also RAWEMGHEALTHCHECK.

signalBW = [20,450];
colors   = {[1,0,0],[0,0,1],[0,0.6,0.3],[0.7,0.7,0.7]};

for trial = 1:length(procExperimentData.data)
    if ~isempty(procExperimentData.data{trial})
        %Visual check:
        data = procExperimentData.data{trial}.procEMGData;
        N    = size(data.Data,2);
        h(trial) = figure(trial);
        set(h(trial),'units','Normalized','OuterPosition',[0,0,1,1]);
        k       = 4;
        legInds = zeros(ceil(N/k),mod(N-1,k)+1);
        legLabs = zeros(ceil(N/k),mod(N-1,k)+1);
        for ii = 1:N
            sp = ceil(ii/k);
            M  = mod(ii-1,k)+1;
            hh(sp) = subplot(ceil(N/8),2,sp);
            hold on
            a = plot(data.Time,data.Data(:,ii),'LineWidth',2,'Color', ...
                colors{M});
            legInds(sp,M) = a;
            legLabs(sp,M) = ii;
            if M == k || ii == N
                legend(legInds(sp,legLabs(sp,:) > 0), ...
                    data.labels{legLabs(sp,legLabs(sp,:) > 0)})
            end
            hold off

        end
        linkaxes(hh,'x')
        %uiwait(h(trial))
    end
end





end

