function fig = plotNoiseHistogram( ...
    amplitudesNoise, leg, id, trialNum, options)
%PLOTNOISEHISTOGRAM Plot the noise amplitude distribution for the H-reflex.
%
%   Plot the H-reflex noise distribution histogram for a single leg. When
% pathFig is nonempty, also writes <id>_NoiseDistribution_Trial<n>_<leg>
% as .png and .fig there, silently overwriting existing files (see
% DATA_OUTPUTS.md).
%
% Inputs:
%   amplitudesNoise - 1 x number of stimuli array of noise amplitudes (mV)
%   leg             - 'Right Leg' or 'Left Leg'
%   id              - string or character array of participant/session ID
%   trialNum        - string or character array of the trial number
%
% Optional Name-Value Inputs:
%   pathFig - path for saving figures; not saved if empty (default: '')
%
% Outputs:
%   fig - handle to the figure generated
%
% Toolbox Dependencies:
%   Statistics and Machine Learning Toolbox (prctile; core MATLAB
%   from R2024a)
%
% See also HREFLEX.PLOTCAL, GENERATEHREFLEXRECRUITMENTCURVES.

arguments
    amplitudesNoise (1,:) double
    leg             (1,:) {mustBeText}
    id              (1,:) {mustBeText}
    trialNum        (1,:) {mustBeText}
    options.pathFig (1,:) char = ''
end

noiseMean = mean(amplitudesNoise);      % mean of all noise amplitudes
noiseMed  = median(amplitudesNoise);    % median noise amplitude
noise75   = prctile(amplitudesNoise, 75); % 75th percentile

noiseHistMax = 0.30;                    % max expected noise amplitude (mV)
noiseHistBin = 0.05;                    % histogram bin width (mV)
propYMax     = 0.80;                    % max y-axis proportion for display

%% Create Figure
fig = figure;
hold on;
histogram(amplitudesNoise, 0:noiseHistBin:noiseHistMax, ...
    'Normalization', 'probability');
xline(noiseMean, 'r', sprintf('Mean = %.2f mV', noiseMean), 'LineWidth', 2);
xline(noiseMed, 'g', sprintf('Median = %.2f mV', noiseMed), 'LineWidth', 2);
xline(noise75, 'k', sprintf('75^{th} Percentile = %.2f mV', noise75), ...
    'LineWidth', 2);
hold off;
axis([0 noiseHistMax 0 propYMax]);
xlabel('Noise Amplitude Peak-to-Peak (mV)');
ylabel('Proportion of Stimuli');
title(sprintf('%s - Trial %s - %s - Noise Distribution', ...
    id, trialNum, leg));

% if figure saving path provided, ...
if ~isempty(options.pathFig)
    legNoSpace = regexprep(leg, '\s+', '');
    % TODO: make figure title and filename optional inputs
    nameFile = fullfile(options.pathFig, sprintf( ...
        '%s_NoiseDistribution_Trial%s_%s', id, trialNum, legNoSpace));
    saveas(fig, nameFile + ".png");     % save figure
    % TODO: just use 'fullfile' if readable
    saveas(fig, nameFile + ".fig");
end

end
