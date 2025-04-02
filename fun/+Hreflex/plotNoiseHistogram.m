function fig = plotNoiseHistogram(amplitudesNoise,leg,id,trialNum,pathFig)
%PLOTNOISEHISTOGRAM Plot the distribution of the noise for the H-reflex
%   Plot the H-reflex noise distribution histogram for a single leg.
%
% input(s):
%   amplitudesNoise: 1 x number of samples array of stimulation current
%       intensities (in mA)
%   leg: 'Right Leg' or 'Left Leg' are the two possible values
%   id: string or character array of participant / session ID for naming
%   trialNum: string or character array of the trial number for naming
%   pathFig: OPTIONAL input for saving figures (not saved if not provided)
%
% output:
%   fig: handle object to the figure generated

narginchk(4,5);                         % verify correct # input arguments

if nargin < 5                           % if no figure saving path, ...
    pathFig = '';                       % default to empty path (no saving)
end

noiseMean = mean(amplitudesNoise);      % mean of all noise amplitudes
noiseMed = median(amplitudesNoise);     % median
noise75 = prctile(amplitudesNoise,75);  % 75th percentile

fig = figure;                           % create a figure
hold on;
histogram(amplitudesNoise,0.00:0.05:0.30,'Normalization','probability');
xline(noiseMean,'r',sprintf('Mean = %.2f mV',noiseMean),'LineWidth',2);
xline(noiseMed,'g',sprintf('Median = %.2f mV',noiseMed),'LineWidth',2);
xline(noise75,'k',sprintf('75^{th} Percentile = %.2f mV',noise75), ...
    'LineWidth',2);
hold off;
axis([0 0.3 0 0.8]);
xlabel('Noise Amplitude Peak-to-Peak (mV)');
ylabel('Proportion of Stimuli');

txtTitle = sprintf('%s - Trial %s - %s - Noise Distribution', ...
    id,trialNum,leg);
title(txtTitle);

if ~isempty(pathFig)                % if figure saving path provided, ...
    legNoSpace = regexprep(leg,'\s+','');
    % TODO: make figure title and filename optional inputs
    nameFile = fullfile(pathFig,sprintf( ...
        '%s_NoiseDistribution_Trial%s_%s',id,trialNum,legNoSpace));
    saveas(fig,nameFile + ".png");  % save figure
    saveas(fig,nameFile + ".fig");  % TODO: just use 'fullfile' if readable
end

end

