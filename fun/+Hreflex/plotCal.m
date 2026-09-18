function fig = plotCal(amplitudesStim, values, yLabel, leg, id, ...
    trialNum, options)
%PLOTCAL Plot the H-reflex recruitment or ratio calibration curve.
%
%   Plot the calibration curve (H-wave and M-wave recruitment or H-to-M
% ratio) for a single leg.
%
% Inputs:
%   amplitudesStim - 1 x number of stimuli array of stimulation current
%                    intensities (mA)
%   values         - 2 x 1 or 1 x 1 cell of number of stimuli x 1 arrays
%                    of H-wave and M-wave amplitudes (mV) or ratios
%   yLabel         - string or character array for the y-axis label
%   leg            - 'Right Leg' or 'Left Leg'
%   id             - string or character array of participant/session ID
%   trialNum       - string or character array of the trial number
%
% Optional Name-Value Inputs:
%   fit             - struct of M-wave and H-wave model fits from FITCAL;
%                     if provided with shouldNormalize, data are normalized
%                     to Mmax (default: empty struct)
%   shouldNormalize - logical; whether to normalize data by Mmax
%                     (default: false)
%   noise           - background noise level for eligibility threshold
%                     (default: NaN, not shown)
%   pathFig         - path for saving figures; not saved if empty
%                     (default: '')
%   shouldAnnotate  - logical; whether to add annotations (default: true)
%   nameFile        - custom filename string; auto-generated if empty
%                     (default: '')
%
% Outputs:
%   fig - handle to the figure generated
%
% Toolbox Dependencies:
%   Signal Processing Toolbox (findpeaks)
%
% See also HREFLEX.FITCAL, GENERATEHREFLEXRECRUITMENTCURVES.

arguments
    amplitudesStim  (1,:) double
    values          (:,1) cell
    yLabel          (1,:) {mustBeText}
    leg             (1,:) {mustBeText}
    id              (1,:) {mustBeText}
    trialNum        (1,:) {mustBeText}
    options.fit             (1,1) struct  = struct()
    options.shouldNormalize (1,1) logical = false
    options.noise           (1,1) double  = NaN
    options.pathFig         (1,:) char    = ''
    options.shouldAnnotate  (1,1) logical = true
    options.nameFile        (1,:) char    = ''
end

% extract options to local variables for readability
fit             = options.fit;
shouldNormalize = options.shouldNormalize;
noise           = options.noise;
pathFig         = options.pathFig;
shouldAnnotate  = options.shouldAnnotate;
nameFile        = options.nameFile;

%% Determine Plot Type & Leg Identifier
isRatio = contains(yLabel, 'ratio', 'IgnoreCase', true); % is ratio plot?
legID   = leg(1);   % 1st character selects struct field (e.g., 'R' or 'L')
% FITCAL skips a leg with no stimulation data (see its noLegData warning),
% so a one-leg session's fit struct has no M.(legID)/H.(legID) for the
% missing leg. Every fit dereference below is guarded on this rather than
% only on fit being non-empty, so a single-leg session degrades to an
% unannotated plot instead of a "Reference to non-existent field" error.
hasFitLeg = isfield(fit, 'M') && isfield(fit.M, legID) && ...
    isfield(fit, 'H') && isfield(fit.H, legID);

%% Normalize Data if Requested & Fit Provided
if shouldNormalize && hasFitLeg
    values = cellfun(@(x) x ./ fit.M.(legID).Mmax, values, ...
        'UniformOutput', false);
end

%% Compute Unique Stimulation Intensities & Averages
amplitudesStimU = unique(amplitudesStim);   % unique stimulation amplitudes
% calculate average values at each intensity
avgs = cellfun(@(x) arrayfun(@(u) mean(x(amplitudesStim == u), ...
    'omitnan'), amplitudesStimU), values, 'UniformOutput', false);
hasVals = cellfun(@(x) ~isnan(x), avgs, 'UniformOutput', false);
% compute maximum values and corresponding stimulation amplitudes
[valMax, indMax] = max(avgs{end});
I_max = amplitudesStimU(indMax);

gray = [0.5 0.5 0.5];                  % define color for convenience

%% Create Figure & Plot
fig = figure;
hold on;
if ~isnan(noise) && ~shouldNormalize    % if noise threshold provided, ...
    yline(noise, 'r--', 'LineWidth', 1.5);          % plot it
    yline(4 * noise, 'r', 'H-Wave V_{pp} Threshold');
end

if isRatio  % if this is an H:M ratio curve, ...
    plot(amplitudesStim, values{1}, 'ok', 'MarkerSize', 10);
    plot(amplitudesStimU(hasVals{1}), avgs{1}(hasVals{1}), 'k', ...
        'LineWidth', 2);
else        % otherwise, this is an H- and M-wave recruitment curve
    plot(amplitudesStim, values{1}, 'x', 'Color', gray, 'MarkerSize', 10);
    p1 = plot(amplitudesStimU(hasVals{1}), avgs{1}(hasVals{1}), '--', ...
        'LineWidth', 2, 'Color', gray);         % averaged M-wave
    plot(amplitudesStim, values{2}, 'ok', 'MarkerSize', 10);
    p2 = plot(amplitudesStimU(hasVals{2}), avgs{2}(hasVals{2}), 'k--', ...
        'LineWidth', 2);                        % averaged H-wave
    if hasFitLeg                                % if fit provided, ...
        I_fit = linspace(min(amplitudesStim), max(amplitudesStim), 1000);
        if isfield(fit.M.(legID), 'R2') && fit.M.(legID).R2 > 0.8
            M_fit = fit.M.modHyperbolic(fit.M.(legID).params, I_fit);
            if shouldNormalize
                M_fit = M_fit ./ fit.M.(legID).Mmax;
            end
            plot(I_fit, M_fit, 'LineWidth', 2, 'Color', gray);
        else
            % TODO: display warning that fit quality is low not adding
        end
        if isfield(fit.H.(legID), 'R2') && fit.H.(legID).R2 > 0.5
            H_fit = fit.H.asymGaussian(fit.H.(legID).params, I_fit);
            if shouldNormalize
                H_fit = H_fit ./ fit.M.(legID).Mmax;
            end
            plot(I_fit, H_fit, 'k', 'LineWidth', 2);
        end
    end
end

% highlight maximum values with lines and labels
maxYOffset = 0.05 * max(cell2mat(values), [], 'omitnan');
% plot([I_max I_max],[0 valMax],'k-.');  % vertical line I_max to valMax
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
plot([min(amplitudesStim)-1 I_max], [valMax valMax], 'k-.');
if isRatio
    text(min(amplitudesStim)-0.9, valMax + maxYOffset, ...
        sprintf('Ratio_{max} = %.2f', valMax));
else
    if shouldNormalize
        text(min(amplitudesStim)-0.9, valMax + maxYOffset, ...
            sprintf('H_{max} = %.2f', valMax));
    else
        text(min(amplitudesStim)-0.9, valMax + maxYOffset, ...
            sprintf('H_{max} = %.2f mV', valMax));
    end
end

% optional: annotate additional features if fit quality is high. This
% needs M_fit, which is only computed in the ~isRatio branch above, so
% ~isRatio is required here too (a ratio call that happened to pass a
% fit struct would otherwise hit an undefined-variable error on M_fit;
% the actual caller never does this, but the guard costs nothing).
if ~isRatio && hasFitLeg && isfield(fit.M.(legID), 'R2') && ...
        fit.M.(legID).R2 > 0.8 && shouldAnnotate
    % find third derivative maximum index as a feature (M*). A fit whose
    % half-saturation intensity falls outside the delivered current range
    % (unsaturated data, e.g. R2 in (0.8, 0.95] with a rank-deficient
    % nlinfit) never leaves its rising limb, so the third difference is
    % monotonic and has no interior peak -- findpeaks then returns empty,
    % which must not reach the plot() calls below (see the M_star guard
    % further down, which relies on M_star never being assigned here).
    [~, ind3rdDeriv] = findpeaks(diff(diff(diff(M_fit))), 'NPeaks', 1);
    if isempty(ind3rdDeriv)
        warning('Hreflex:plotCal:No3rdDerivPeak', ...
            ['%s M-wave fit has no third-derivative peak within the ' ...
            'stimulation range; skipping I*/M* annotation.'], leg);
    else
        I_star = I_fit(ind3rdDeriv);
        M_star = M_fit(ind3rdDeriv);
        plot([I_star I_star], [0 M_star], 'k-.');           % vertical line
        text(I_star + 0.1, maxYOffset, sprintf('I* = %.1f mA', I_star));
        plot([min(amplitudesStim)-1 I_star], [M_star M_star], 'k-.');
        if shouldNormalize
            text(min(amplitudesStim)-0.9, M_star + maxYOffset, ...
                sprintf('M* = %.2f', M_star));
        else
            text(min(amplitudesStim)-0.9, M_star + maxYOffset, ...
                sprintf('M* = %.2f mV', M_star));
        end
    end
end

if ~isRatio && hasFitLeg && ...
        isfield(fit.M.(legID), 'R2') && isfield(fit.H.(legID), 'R2') && ...
        shouldAnnotate
    text(max(amplitudesStim)-3.0, max(values{1})*0.75, ...
        sprintf('{R^{2}}_{H} = %.2f', fit.H.(legID).R2));
    text(max(amplitudesStim)-3.0, max(values{1})*0.65, ...
        sprintf('{R^{2}}_{M} = %.2f', fit.M.(legID).R2));
end

if ~isRatio && hasFitLeg && ~shouldNormalize
    % display additional metrics if available
    % TODO: should use H-wave curve fit if good R2?
    text(min(amplitudesStim)-0.9, max(values{1})*0.75, ...
        sprintf('H_{max}/M_{max} = %.2f', valMax/fit.M.(legID).Mmax));
    % M_star only exists (and is non-empty) when the I*/M* annotation
    % block above found a third-derivative peak; exist() alone is true
    % even for an emptied M_star, which would print a blank number
    if exist('M_star', 'var') && ~isempty(M_star)
        text(min(amplitudesStim)-0.9, max(values{1})*0.65, ...
            sprintf('M*/M_{max} = %.2f', M_star/fit.M.(legID).Mmax));
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
        id, trialNum, leg, type);
else
    txtTitle = sprintf('%s - Trial %s - %s - %s Curve', ...
        id, trialNum, leg, type);
end
title(txtTitle);

if ~isRatio                             % if not ratio curve, ...
    legend([p1 p2], 'M-wave', 'H-wave', 'Location', 'best', 'Box', 'off');
end

%% Save Figure
if ~isempty(pathFig)                    % if figure saving path provided, ...
    legNoSpace = regexprep(leg, '\s+', '');
    if isempty(nameFile)
        if shouldNormalize
            nameFile = sprintf('%s_Hreflex%sCurveNormalized_Trial%s_%s', ...
                id, type, trialNum, legNoSpace);
        else
            nameFile = sprintf('%s_Hreflex%sCurve_Trial%s_%s', ...
                id, type, trialNum, legNoSpace);
        end
    end
    saveas(fig, fullfile(pathFig, nameFile + ".png")); % save figure
    saveas(fig, fullfile(pathFig, nameFile + ".fig"));
end

end
