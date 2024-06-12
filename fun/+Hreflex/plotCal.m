function fig = plotCal(amplitudesStim,values,yLabel,leg,id, ...
    trialNum,varargin)
%PLOTCAL Summary of this function goes here
%   Detailed explanation goes here

narginchk(6,8); % verify correct number of input arguments

numOptArgs = length(varargin);
switch numOptArgs
    case 0
        thresh = nan;   % default to Not-a-Number
        path = '';      % default to empty
    case 1  % one optional argument provided
        if isnumeric(varargin{1})   % if a number, ...
            thresh = varargin{1};   % it is the threshold
            path = '';
        else                        % otherwise, ...
            path = varargin{1};     % is is the file saving path
            thresh = nan;
        end
    case 2  % both optional arguments provided
        thresh = varargin{1};   % first always threshold
        path = varargin{2};     % second always file saving path
end

isRatio = contains(yLabel,'ratio','IgnoreCase',true);

amplitudesStimU = unique(amplitudesStim);
avgs = arrayfun(@(x) mean(values(amplitudesStim == x)),amplitudesStimU);
[valMax,indMax] = max(avgs);
I_max = ampsStimLU(indMax);

fig = figure;
hold on;
if ~isnan(thresh)
    yline(thresh,'r','Threshold');
end

if isRatio  % if this is an H:M ratio curve, ...
    plot(amplitudesStim,values,'ok','MarkerSize',10);   % individual points
    plot(amplitudesStimU,avgs,'k','LineWidth',2);       % line through means
else        % otherwise, this is an H- and M-wave recruitment curve
    plot(amplitudesStim,values{1},'x','Color',[0.5 0.5 0.5],'MarkerSize',10);
    p1 = plot(amplitudesStimU,avgs{1},'LineWidth',2,'Color',[0.5 0.5 0.5]);
    plot(amplitudesStim,values{2},'ok','MarkerSize',10);
    p2 = plot(amplitudesStimU,avgs{2},'k','LineWidth',2);
    % p3 = plot(xL,yL,'b--','LineWidth',2);
end

plot([I_max I_max],[0 valMax],'k-.');  % vertical line from I_max to valMax
% add label to vertical line (I_max) shifted up from x-axis by 5% of max y
% value and over from the line by 0.1 mA
% TODO: do not hardcode x offset for label
% TODO: add handle of title
if isRatio
    text(I_max + 0.1,0 + (0.05*max(values)), ...
        sprintf('I_{Ratio_{max}} = %.1f mA',I_max));
else
    text(I_max + 0.1,0 + (0.05*max(cell2mat(values))), ...
        sprintf('I_{H_{max}} = %.1f mA',I_max));
end

% horizontal line to valMax
plot([min(amplitudesStim)-1 I_max],[valMax valMax],'k-.');
% add label to horizontal line (valMax)
if isRatio
    text(min(amplitudesStim)-1 + 0.1,valMax + ...
        (0.05*max(values)),sprintf('Ratio_{max} = %.2f',valMax));
else
    text(min(amplitudesStim)-1 + 0.1,valMax + ...
        (0.05*max(cell2mat(values))),sprintf('H_{max} = %.2f mV',valMax));
end
hold off;

xlim([min(amplitudesStim)-1 max(amplitudesStim)+1]);
xlabel('Stimulation Amplitude (mA)');
ylabel(yLabel);
if isRatio
    title([id ' - Trial' trialNum ' - ' leg ' - Ratio Curve']);
else
    legend([p1 p2],'M-wave','H-wave','Location','best');
    title([id ' - Trial' trialNum ' - ' leg ' - Recruitment Curve']);
end
saveas(gcf,[pathFigs id '_HreflexRatioCurve_Trial' trialNum ...
    '_LeftLeg.png']);
saveas(gcf,[pathFigs id '_HreflexRatioCurve_Trial' trialNum ...
    '_LeftLeg.fig']);

% TODO: make figure title and filename optional inputs

if ~isempty(path)   % if figure saving path provided as input argument, ...
    % save figure
    if isRatio
        saveas(gcf,[path id '_HreflexRatioCurve_Trial' trialNum ...
            '_' erase(leg,' ') '.png']);
        saveas(gcf,[path id '_HreflexRatioCurve_Trial' trialNum ...
            '_' erase(leg,' ') '.fig']);
    else
        saveas(gcf,[path id '_HreflexRecruitmentCurve_Trial' trialNum ...
            '_' erase(leg,' ') '.png']);
        saveas(gcf,[path id '_HreflexRecruitmentCurve_Trial' trialNum ...
            '_' erase(leg,' ') '.fig']);
    end
end

end

