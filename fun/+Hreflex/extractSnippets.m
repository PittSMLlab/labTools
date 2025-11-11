function [snippets,timesSnippet] = extractSnippets(indsPeaks,rawEMG,GRFz)
%EXTRACTSNIPPETS Extract H-reflex and optional GRF snippets for plotting
%   Extract the snippets of the H-reflex from the muscle raw EMG signal
% based on the stimulation artifact peak alignment. Optionally, extract the
% ground reaction force (GRF) snippets for visualizing if stimulation
% occurs during single stance.
%
% input(s):
%   indsPeaks: 2 x 1 cell array of number of peaks x 1 arrays of the
%       stimulation artifact peaks found by the algorithm
%   rawEMG: 2 x 1 cell array of number of samples x 1 arrays for right
%       (cell 1) and left (cell 2) leg EMG signal (NOTE: if one cell is
%       input as empty array, that leg will not be computed)
%   GRFz (optional): 2 x 1 cell array of number of samples x 1 arrays for
%       right (cell 1) and left (cell 2) treadmill force plate z-axis GRFs
% output(s):
%   snippets: 2 x 3 cell array of number of stimuli x number of samples
%       arrays for right (row 1) and left (row 2) leg H-reflex (col 1),
%       ipsilateral (col 2) and contralateral (col 3) GRF snippets to plot
%   timesSnippet: number of samples x 1 array with relative time in seconds
%       of each snippet (t=0s is stimulation artifact peak alignment time)

narginchk(2,3);         % verify correct number of input arguments

if nargin == 2          % if only two input arguments, ...
    GRFz = {[], []};    % default to empty GRFz cell array
end

if all(cellfun(@isempty,indsPeaks)) || all(cellfun(@isempty,rawEMG))
    error('Critical data missing for extracting the H-reflex snippets.');
end

% NOTE: should always be same across trials and should be same for forces
% TODO: make optional input argument?
% parameters for snippet extraction
period = 0.0005;                        % sampling period (seconds)
snipStart = -0.005;                     % include 5 ms before artifact peak
snipEnd = 0.055;                        % include 55 ms after artifact peak
timesSnippet = snipStart:period:snipEnd;% snippet sample times for plotting
numSamps = numel(timesSnippet);         % number of samples in EMG snippet

% initialize the snippets cell array to be populated by extraction
numStim = cellfun(@length,indsPeaks);   % number of stimuli for each leg
% store right (row 1) and left (row 2) leg H-reflex (col 1), ipsilateral
% (col 2) and contralateral (col 3) GRF snippets for plotting
snippets = cell(2,3);                   % store snippets for each leg
for leg = 1:2                           % for right and left leg, ...
    snippets{leg,1} = nan(numStim(leg),numSamps);   % EMG snippets
    snippets{leg,2} = nan(numStim(leg),numSamps);   % ipsilateral GRF
    snippets{leg,3} = nan(numStim(leg),numSamps);   % contralateral GRF
end

for leg = 1:2                           % for right and left leg, ...
    if isempty(indsPeaks{leg}) || isempty(rawEMG{leg})
        continue;                       % advance to next leg
    end
    snippets(leg,:) = extractSnippetsLeg(indsPeaks{leg},rawEMG{leg},GRFz,leg,numSamps,snipStart,snipEnd,period);
end

end

function snipCell = extractSnippetsLeg(indsPeaks,EMG,GRFz,leg, ...
    numSamples,snipStart,snipEnd,period)
%EXTRACTSNIPPETSLEG Extract snippets for a single leg (EMG and GRF)
%   This function loops over each provided index, extracts the window
% relative to the index, and fills any out-of-bound indices with 'NaN'.

numStim = numel(indsPeaks);             % number of stimuli for current leg
snipEMG = nan(numStim,numSamples);      % EMG snippets
snipIpsi = nan(numStim,numSamples);     % ipsilateral GRFz snippets
snipContra = nan(numStim,numSamples);   % contralateral GRFz snippets

for st = 1:numStim                      % for each stimulus, ...
    win = (indsPeaks(st) + round(snipStart / period)) : ...
        (indsPeaks(st) + round(snipEnd / period));      % snippet window
    % create a temporary array for the snippet filled with 'NaN'
    temp = nan(1,numSamples);
    % determine valid indices within bounds for EMG
    valid = (win >= 1) & (win <= numel(EMG));
    if any(valid)                       % if any data within bounds, ...
        temp(valid) = EMG(win(valid));  % H-reflex snippet
    end
    snipEMG(st,:) = temp;

    if ~isempty(GRFz{leg})              % if GRFz data available, ...
        temp = nan(1,numSamples);
        valid = (win >= 1) & (win <= numel(GRFz{leg}));
        if any(valid)
            temp(valid) = GRFz{leg}(win(valid));        % ipsilateral GRFz
        end
        snipIpsi(st,:) = temp;
    end

    legContra = 3 - leg;                % contralat. index (1 -> 2, 2 -> 1)
    if ~isempty(GRFz{legContra})        % if GRFz data available, ...
        temp = nan(1,numSamples);
        valid = (win >= 1) & (win <= numel(GRFz{legContra}));
        if any(valid)
            temp(valid) = GRFz{legContra}(win(valid));  % contralateral GRF
        end
        snipContra(st,:) = temp;
    end
end

% return as a cell array [EMG, Ipsilateral GRF, Contralateral GRF]
snipCell = {snipEMG,snipIpsi,snipContra};

end

