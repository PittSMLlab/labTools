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
%   OPTIONAL PARAMETERS (passed as name/value pairs):
%       fit: input structure of the M-wave and H-wave model fits (default:
%           empty structure). If provided and 'shouldNormalize' is true,
%           data are normalized to Mmax.
%       shouldNormalize: logical indicating whether to normalize data by
%           Mmax (default: false).
%       noise: input for the background noise level for the eligibility
%           threshold (default: NaN).
%       pathFig: input for saving figures (default: '', i.e., not saved)
%
% output:
%   fig: handle object to the figure generated

narginchk(6,10);                % verify correct number of input arguments

p = inputParser;                % create and parse input arguments
addRequired(p,'amplitudesStim',@(x) isnumeric(x) && isvector(x));
addRequired(p,'values',@iscell);
addRequired(p,'yLabel',@(x) ischar(x) || isstring(x));
addRequired(p,'leg',@(x) ischar(x) || isstring(x));
addRequired(p,'id',@(x) ischar(x) || isstring(x));
addRequired(p,'trialNum',@(x) ischar(x) || isstring(x));
addParameter(p,'fit',struct(),@isstruct);
addParameter(p,'shouldNormalize',false,@islogical);
addParameter(p,'noise',NaN,@isnumeric);
addParameter(p,'pathFig','',@(x) ischar(x) || isstring(x));
parse(p,amplitudesStim,values,yLabel,leg,id,trialNum,varargin{:});
% retrieve option input arguments
fit = p.Results.fit;
shouldNormalize = p.Results.shouldNormalize;
noise = p.Results.noise;
pathFig = p.Results.pathFig;

% determine if this is a ratio curve based on yLabel
isRatio = contains(yLabel,'ratio','IgnoreCase',true);   % is ratio plot?
legID = leg(1);     % use 1st character to select field (e.g., 'R' or 'L')

if ~isempty(fieldnames(fit))            % if model fit available, ...
    I_fit = linspace(min(amplitudesStim),max(amplitudesStim),100);
    M_fit = fit.M.modHyperbolic(fit.M.(legID).params,I_fit);
    H_fit = fit.H.asymGaussian(fit.H.(legID).params,I_fit);
end

amplitudesStimU = unique(amplitudesStim);   % unique stimulation amplitudes
% calculate average values at each intensity
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
    p1 = plot(amplitudesStimU(hasVals{1}),avgs{1}(hasVals{1}),'--', ...
        'LineWidth',2,'Color',[0.5 0.5 0.5]);   % averaged M-wave
    plot(amplitudesStim,values{2},'ok','MarkerSize',10);    % raw H-wave
    p2 = plot(amplitudesStimU(hasVals{2}),avgs{2}(hasVals{2}),'k--', ...
        'LineWidth',2);                         % averaged H-wave
    if ~isempty(fieldnames(fit))
        p3 = plot(I_fit,M_fit,'LineWidth',2,'Color',[0.5 0.5 0.5]); % fit
        p4 = plot(I_fit,H_fit,'k','LineWidth',2);
    end
end

% highlight maximum values with lines and labels
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
    text(min(amplitudesStim)-0.9,valMax + maxYOffset, ...
        sprintf('Ratio_{max} = %.2f',valMax));
else
    text(min(amplitudesStim)-0.9,valMax + maxYOffset, ...
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

if ~isempty(pathFig)                % if figure saving path provided, ...
    legNoSpace = regexprep(leg,'\s+','');
    % TODO: make figure title and filename optional inputs
    nameFile = fullfile(pathFig,sprintf('%s_Hreflex%sCurve_Trial%s_%s', ...
        id,type,trialNum,legNoSpace));
    saveas(fig,nameFile + ".png");  % save figure
    saveas(fig,nameFile + ".fig");  % TODO: just use 'fullfile' if readable
end

end

