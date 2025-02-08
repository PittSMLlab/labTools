function fig = plotCal(amplitudesStim,values,yLabel,leg,id,trialNum, ...
    varargin)
%PLOTCAL Plot the H-reflex recruitment or ratio calibration curve
%   Plot the calibration curve (H-wave and M-wave recruitment or H-to-M
% ratio) for a single leg.
%
% input(s):
%   amplitudesStim: 1 x number of samples array of stimulation current
%       intensities (in mA)
%   values: 2 x 1 or 1 x 1 cell array of number of samples x 1 array(s) of
%       the H-wave and M-wave amplitudes (in mV) or ratios
%   yLabel: string or character array of the y-axis label
%   leg: 'Right Leg' or 'Left Leg' are the two possible values
%   id: string or character array of participant / session ID for naming
%   trialNum: string or character array of the trial number for naming
%   noise: OPTIONAL input for the background noise level for the
%       eligibility threshold
%   pathFig: OPTIONAL input for saving figures (not saved if not provided)
%
% output:
%   fig: handle object to the figure generated

narginchk(6,8); % verify correct number of input arguments

numOptArgs = length(varargin);
switch numOptArgs
    case 0
        noise = nan;   % default to Not-a-Number
        pathFig = '';      % default to empty
    case 1  % one optional argument provided
        if isnumeric(varargin{1})   % if a number, ...
            noise = varargin{1};   % it is the threshold
            pathFig = '';
        else                        % otherwise, ...
            pathFig = varargin{1};     % is is the file saving path
            noise = nan;
        end
    case 2  % both optional arguments provided
        noise = varargin{1};   % first always threshold
        pathFig = varargin{2};     % second always file saving path
end

isRatio = contains(yLabel,'ratio','IgnoreCase',true);   % is ratio plot?

amplitudesStimU = unique(amplitudesStim);   % unique stimulation amplitudes
avgs = cellfun(@(x) arrayfun(@(u) mean(x(amplitudesStim == u), ...
    'omitnan'),amplitudesStimU),values,'UniformOutput',false);
hasVals = cellfun(@(x) ~isnan(x),avgs,'UniformOutput',false);

% compute maximum values and corresponding stimulation amplitudes
[valMax,indMax] = max(avgs{end});
I_max = amplitudesStimU(indMax);

% TODO: is it necessary to sort the data?
% [ampsStimR,indsOrderR] = sort(ampsStimR);
% ampsHwaveR = ampsHwaveR(indsOrderR);
% ampsMwaveR = ampsMwaveR(indsOrderR);

fig = figure;                           % create a figure
hold on;
if ~isnan(noise)                        % if noise threshold provided, ...
    yline(noise,'r--','LineWidth',1.5); % plot it
    yline(4*noise,'r','H-Wave V_{pp} Threshold');
end

if isRatio  % if this is an H:M ratio curve, ...
    plot(amplitudesStim,values{1},'ok','MarkerSize',10);    % raw points
    plot(amplitudesStimU(hasVals{1}),avgs{1}(hasVals{1}),'k', ...
        'LineWidth',2);                                     % avg curve
else        % otherwise, this is an H- and M-wave recruitment curve
    plot(amplitudesStim,values{1},'x','Color',[0.5 0.5 0.5], ...
        'MarkerSize',10);                       % raw M-wave points
    p1 = plot(amplitudesStimU(hasVals{1}),avgs{1}(hasVals{1}), ...
        'LineWidth',2,'Color',[0.5 0.5 0.5]);   % averaged M-wave
    plot(amplitudesStim,values{2},'ok','MarkerSize',10);    % raw H-wave
    p2 = plot(amplitudesStimU(hasVals{2}),avgs{2}(hasVals{2}),'k', ...
        'LineWidth',2);                         % averaged H-wave
    % p3 = plot(xL,yL,'b--','LineWidth',2);
end


% Highlight max values with lines and labels
maxYOffset = 0.05 * max(cell2mat(values));
plot([I_max I_max],[0 valMax],'k-.');  % vertical line from I_max to valMax
% add label to vertical line (I_max) shifted up from x-axis by 5% of max y
% value and over from the line by 0.1 mA
% TODO: add handle of title
if isRatio
    text(I_max + 0.1,maxYOffset, ...
        sprintf('I_{Ratio_{max}} = %.1f mA',I_max));
else
    text(I_max + 0.1,maxYOffset, ...
        sprintf('I_{H_{max}} = %.1f mA',I_max));
end

% horizontal line to valMax
plot([min(amplitudesStim)-1 I_max],[valMax valMax],'k-.');
% add label to horizontal line (valMax)
if isRatio
    text(min(amplitudesStim)-1 + 0.1,valMax + maxYOffset, ...
        sprintf('Ratio_{max} = %.2f',valMax));
else
    text(min(amplitudesStim)-1 + 0.1,valMax + maxYOffset, ...
        sprintf('H_{max} = %.2f mV',valMax));
end
hold off;

xlim([min(amplitudesStim)-1 max(amplitudesStim)+1]);
xlabel('Stimulation Amplitude (mA)');
ylabel(yLabel);
if isRatio              % if ratio curve, ...
    type = 'Ratio';     % update title and file name accordingly
else
    type = 'Recruitment';
end
txtTitle = sprintf('%s - Trial %s - %s - %s Curve',id,trialNum,leg,type);
title(txtTitle);
if ~isRatio                                             % if not ratio, ...
    legend([p1 p2],'M-wave','H-wave','Location','best');% add legend
end

% TODO: make figure title and filename optional inputs
if ~isempty(pathFig)                % if figure saving path provided, ...
    nameFile = fullfile(pathFig,sprintf('%s_Hreflex%sCurve_Trial%s_%s', ...
        id,type,trialNum,erase(leg,' ')));
    saveas(fig,nameFile + ".png");  % save figure
    saveas(fig,nameFile + ".fig");  % TODO: just use 'fullfile' if readable
end

end

