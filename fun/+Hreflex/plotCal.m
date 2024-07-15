function fig = plotCal(amplitudesStim,values,yLabel,leg,id, ...
    trialNum,varargin)
%PLOTCAL Plot either the recruitment or ratio H-reflex calibration curve
%   Plot the calibration curve (H-wave and M-wave recruitment or H-to-M
% ratio) for a single leg.
%
% input:
%   amplitudesStim: 1 x number of samples array of stimulation current
%       intensities (in mA)
%   values: 2 x 1 or 1 x 1 cell array of number of samples x 1 array(s) of
%       the H-wave and M-wave amplitudes (in mV) or ratios
%   yLabel: character array or string of the y-axis label
%   leg: either 'Right Leg' or 'Left Leg' are the two possible values
%   id: string or character array of participant / session ID for naming
%   trialNum: string or character array of the trial number for naming
%   noise: OPTIONAL input for the background noise level for the
%       eligibility threshold
%   path: OPTIONAL input for saving figures (not saved if not provided)
% output:
%   fig: handle object to the figure generated

narginchk(6,8); % verify correct number of input arguments

numOptArgs = length(varargin);
switch numOptArgs
    case 0
        noise = nan;   % default to Not-a-Number
        path = '';      % default to empty
    case 1  % one optional argument provided
        if isnumeric(varargin{1})   % if a number, ...
            noise = varargin{1};   % it is the threshold
            path = '';
        else                        % otherwise, ...
            path = varargin{1};     % is is the file saving path
            noise = nan;
        end
    case 2  % both optional arguments provided
        noise = varargin{1};   % first always threshold
        path = varargin{2};     % second always file saving path
end

isRatio = contains(yLabel,'ratio','IgnoreCase',true);

amplitudesStimU = unique(amplitudesStim);
avgs = cellfun(@(x1) arrayfun(@(x2) mean(x1(amplitudesStim == x2), ...
    'omitmissing'),amplitudesStimU),values,'UniformOutput',false);
hasVals = cellfun(@(x) ~isnan(x),avgs,'UniformOutput',false);
% compute Hmax or Ratiomax along with current at which it occurs
[valMax,indMax] = max(avgs{end});
I_max = amplitudesStimU(indMax);

% TODO: is it necessary to sort the data?
% [ampsStimR,indsOrderR] = sort(ampsStimR);
% ampsHwaveR = ampsHwaveR(indsOrderR);
% ampsMwaveR = ampsMwaveR(indsOrderR);

fig = figure;
hold on;
if ~isnan(noise)
    yline(noise,'r--');
    yline(4*noise,'r','H-Wave V_{pp} Threshold');
end

if isRatio  % if this is an H:M ratio curve, ...
    plot(amplitudesStim,values{1},'ok','MarkerSize',10);% individual points
    plot(amplitudesStimU(hasVals{1}),avgs{1}(hasVals{1}),'k', ...
        'LineWidth',2);
else        % otherwise, this is an H- and M-wave recruitment curve
    plot(amplitudesStim,values{1},'x','Color',[0.5 0.5 0.5], ...
        'MarkerSize',10);
    p1 = plot(amplitudesStimU(hasVals{1}),avgs{1}(hasVals{1}), ...
        'LineWidth',2,'Color',[0.5 0.5 0.5]);
    plot(amplitudesStim,values{2},'ok','MarkerSize',10);
    p2 = plot(amplitudesStimU(hasVals{2}),avgs{2}(hasVals{2}),'k', ...
        'LineWidth',2);
    % p3 = plot(xL,yL,'b--','LineWidth',2);
end

plot([I_max I_max],[0 valMax],'k-.');  % vertical line from I_max to valMax
% add label to vertical line (I_max) shifted up from x-axis by 5% of max y
% value and over from the line by 0.1 mA
% TODO: do not hardcode x offset for label
% TODO: add handle of title
if isRatio
    text(I_max + 0.1,0 + (0.05*max(cell2mat(values))), ...
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
        (0.05*max(cell2mat(values))),sprintf('Ratio_{max} = %.2f',valMax));
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

