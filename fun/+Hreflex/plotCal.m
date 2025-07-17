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
%       pathFig: input for saving figures (default: '', i.e., not saved).
%       shouldAnnotate: logical indicating whether to add annotations
%           (default: true).
%       nameFile: string or character array of custom filename (default:
%           generated automatically)
%
% output:
%   fig: handle object to the figure generated

%% Input Parsing
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
addParameter(p,'shouldAnnotate',true,@islogical);
addParameter(p,'nameFile','',@(x) ischar(x) || isstring(x));
parse(p,amplitudesStim,values,yLabel,leg,id,trialNum,varargin{:});
% retrieve option input arguments
fit = p.Results.fit;
shouldNormalize = p.Results.shouldNormalize;
noise = p.Results.noise;
pathFig = p.Results.pathFig;
shouldAnnotate = p.Results.shouldAnnotate;
nameFile = p.Results.nameFile;

%% Determine Plot Type & Leg Identifier
isRatio = contains(yLabel,'ratio','IgnoreCase',true);   % is ratio plot?
legID = leg(1);     % use 1st character to select field (e.g., 'R' or 'L')

%% Normalize Data if Requested & Fit Provided
if shouldNormalize && ~isempty(fieldnames(fit)) && ...
        isfield(fit,'M') && isfield(fit.M,legID)
    values = cellfun(@(x) x ./ fit.M.(legID).Mmax,values, ...
        'UniformOutput',false);
end

%% Compute Unique Stimulation Intensities & Averages
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

gray = [0.5 0.5 0.5];                   % define color for convenience

%% Create Figure & Plot
fig = figure;                           % create a figure
hold on;
if ~isnan(noise) && ~shouldNormalize    % if noise threshold provided, ...
    yline(noise,'r--','LineWidth',1.5); % plot it
    yline(4*noise,'r','H-Wave V_{pp} Threshold');
end

if isRatio  % if this is an H:M ratio curve, ...
    plot(amplitudesStim,values{1},'ok','MarkerSize',10);    % raw points
    plot(amplitudesStimU(hasVals{1}),avgs{1}(hasVals{1}),'k', ...
        'LineWidth',2);                                     % avg curve
else        % otherwise, this is an H- and M-wave recruitment curve
    plot(amplitudesStim,values{1},'x','Color',gray, ...
        'MarkerSize',10);                       % raw M-wave points
    p1 = plot(amplitudesStimU(hasVals{1}),avgs{1}(hasVals{1}),'--', ...
        'LineWidth',2,'Color',gray);            % averaged M-wave
    plot(amplitudesStim,values{2},'ok','MarkerSize',10);    % raw H-wave
    p2 = plot(amplitudesStimU(hasVals{2}),avgs{2}(hasVals{2}),'k--', ...
        'LineWidth',2);                         % averaged H-wave
    if ~isempty(fieldnames(fit))                % if fit provided, ...
        I_fit = linspace(min(amplitudesStim),max(amplitudesStim),1000);
        if isfield(fit.M.(legID),'R2') && fit.M.(legID).R2 > 0.8
            M_fit = fit.M.modHyperbolic(fit.M.(legID).params,I_fit);
            if shouldNormalize                  % if normalizing data, ...
                M_fit = M_fit ./ fit.M.(legID).Mmax;
            end
            plot(I_fit,M_fit,'LineWidth',2,'Color',gray);
        else
            % TODO: display warning that fit quality is low not adding
        end
        if isfield(fit.H.(legID),'R2') && fit.H.(legID).R2 > 0.5
            H_fit = fit.H.asymGaussian(fit.H.(legID).params,I_fit);
            if shouldNormalize                      % if normalizing data, ...
                H_fit = H_fit ./ fit.M.(legID).Mmax;
            end
            plot(I_fit,H_fit,'k','LineWidth',2);
        end
    end
end

% highlight maximum values with lines and labels
maxYOffset = 0.05 * max(cell2mat(values),[],'omitnan');
% plot([I_max I_max],[0 valMax],'k-.');  % vertical line from I_max to valMax
% add label to vertical line (I_max) shifted up from x-axis by 5% of max y
% value and over from the line by 0.1 mA
% TODO: add handle of title
% if isRatio
%     text(I_max + 0.1,maxYOffset, ...
%         sprintf('I_{Ratio_{max}} = %.1f mA',I_max));
% else
%     text(I_max + 0.1,maxYOffset, ...
%         sprintf('I_{H_{max}} = %.1f mA',I_max));
% end

% horizontal line to valMax
plot([min(amplitudesStim)-1 I_max],[valMax valMax],'k-.');
% add label to horizontal line (valMax)
if isRatio
    text(min(amplitudesStim)-0.9,valMax + maxYOffset, ...
        sprintf('Ratio_{max} = %.2f',valMax));
else
    if shouldNormalize
        text(min(amplitudesStim)-0.9,valMax + maxYOffset, ...
            sprintf('H_{max} = %.2f',valMax));
    else
        text(min(amplitudesStim)-0.9,valMax + maxYOffset, ...
            sprintf('H_{max} = %.2f mV',valMax));
    end
end

% optional: annotate additional features if fit quality is high
if ~isempty(fieldnames(fit)) && isfield(fit.M.(legID),'R2') && ...
        fit.M.(legID).R2 > 0.8 && shouldAnnotate
    % find third derivative maximum index as a feature (M*)
    [~,ind3rdDeriv] = findpeaks(diff(diff(diff(M_fit))),'NPeaks',1);
    I_star = I_fit(ind3rdDeriv);
    M_star = M_fit(ind3rdDeriv);
    plot([I_star I_star],[0 M_star],'k-.');         % vertical line
    text(I_star + 0.1,maxYOffset,sprintf('I* = %.1f mA',I_star));
    plot([min(amplitudesStim)-1 I_star],[M_star M_star],'k-.');
    if shouldNormalize
        text(min(amplitudesStim)-0.9,M_star + maxYOffset, ...
            sprintf('M* = %.2f',M_star));
    else
        text(min(amplitudesStim)-0.9,M_star + maxYOffset, ...
            sprintf('M* = %.2f mV',M_star));
    end
end

if ~isRatio && ~isempty(fieldnames(fit)) && ...
        isfield(fit.M.(legID),'R2') && isfield(fit.H.(legID),'R2') && ...
        shouldAnnotate
    text(max(amplitudesStim)-3.0,max(values{1})*0.75, ...
        sprintf('{R^{2}}_{H} = %.2f',fit.H.(legID).R2));
    text(max(amplitudesStim)-3.0,max(values{1})*0.65, ...
        sprintf('{R^{2}}_{M} = %.2f',fit.M.(legID).R2));
end

if ~isRatio && ~isempty(fieldnames(fit)) && ~shouldNormalize
    % display additional metrics if available
    % TODO: should use H-wave curve fit if good R2?
    text(min(amplitudesStim)-0.9,max(values{1})*0.75, ...
        sprintf('H_{max}/M_{max} = %.2f',valMax/fit.M.(legID).Mmax));
    if exist('M_star')
        text(min(amplitudesStim)-0.9,max(values{1})*0.65, ...
            sprintf('M*/M_{max} = %.2f',M_star/fit.M.(legID).Mmax));
    end
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

if shouldNormalize
    txtTitle = sprintf('%s - Trial %s - %s - Normalized %s Curve', ...
        id,trialNum,leg,type);
else
    txtTitle = sprintf('%s - Trial %s - %s - %s Curve', ...
        id,trialNum,leg,type);
end
title(txtTitle);

if ~isRatio                                             % if not ratio, ...
    legend([p1 p2],'M-wave','H-wave','Location','best','Box','off');
end

if ~isempty(pathFig)                % if figure saving path provided, ...
    legNoSpace = regexprep(leg,'\s+','');
    if isempty(nameFile)
        if shouldNormalize
            nameFile = sprintf('%s_Hreflex%sCurveNormalized_Trial%s_%s',...
                id,type,trialNum,legNoSpace);
        else
            nameFile = sprintf('%s_Hreflex%sCurve_Trial%s_%s', ...
                id,type,trialNum,legNoSpace);
        end
    end
    saveas(fig,fullfile(pathFig,nameFile + ".png"));    % save figure
    saveas(fig,fullfile(pathFig,nameFile + ".fig"));
end

end

