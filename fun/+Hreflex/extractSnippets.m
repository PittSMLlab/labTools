function [snippets,timesSnippet] = extractSnippets(indsPeaks,rawEMG,GRFz)
%EXTRACTSNIPPETS Extract H-reflex & optional GRF snippets for plotting
%   Extract the snippets of the H-reflex from the muscle raw EMG signal
% based on the stimulation artifact peak alignment. Optionally, extract the
% ground reaction force (GRF) snippets for visualizing if stimulation
% occurs during single stance.
%
% input:
%   indsPeaks: 2 x 1 cell array of number of peaks x 1 arrays of the
%       stimulation artifact peaks found by the algorithm
%   rawEMG: 2 x 1 cell array of number of samples x 1 arrays for right
%       (cell 1) and left (cell 2) leg EMG signal (NOTE: if one cell is
%       input as empty array, that leg will not be computed)
%   GRFz (optional): 2 x 1 cell array of number of samples x 1 arrays for
%       right (cell 1) and left (cell 2) treadmill force plate z-axis GRFs
% output:
%   snippets: 2 x 3 cell array of number of stimuli x number of samples
%       arrays for right (row 1) and left (row 2) leg H-reflex (col 1),
%       ipsilateral (col 2) and contralateral (col 3) GRF snippets to plot
%   timesSnippet: number of samples x 1 array with relative time in seconds
%       of each snippet (t=0s is stimulation artifact peak alignment time)

narginchk(2,3);         % verify correct number of input arguments

if nargin == 2          % if only two input arguments, ...
    GRFz = {[], []};    % default to empty GRFz array
end

if all(cellfun(@isempty,indsPeaks)) || all(cellfun(@isempty,rawEMG))
    error(['There is data missing that is critical for extracting the ' ...
        'H-reflex snippets.']);     % return with error
end

% NOTE: should always be same across trials and should be same for forces
% TODO: make optional input argument?
% constants for snippet extraction
period = 0.0005;                        % sampling period (seconds)
snipStart = -0.005;                     % include 5 ms before artifact peak
snipEnd = 0.055;                        % include 55 ms after artifact peak
timesSnippet = snipStart:period:snipEnd;% snippet sample times for plotting
numSamps = numel(timesSnippet);         % number of samples in EMG snippet

snippets = initializeSnippets(indsPeaks,numSamps);

for leg = 1:2                           % for right and left leg, ...
    if ~isempty(indsPeaks{leg})         % if stim. artifact peaks, ...
        snippets = extractSnippetsLeg(leg,indsPeaks,rawEMG,GRFz, ...
            snippets,snipStart,snipEnd,period);
    end
end

end

function snippets = initializeSnippets(indsPeaks,numSamps)
% initialize the snippets cell array to be populated by extraction

numStim = cellfun(@length,indsPeaks);   % number of stimuli for each leg

% store right (row 1) and left (row 2) leg H-reflex (col 1), ipsilateral
% (col 2) and contralateral (col 3) GRF snippets for plotting
snippets = cell(2,3);   % store snippets for each leg
for leg = 1:2           % for right and left leg, ...
    snippets(leg,:) = {nan(numStim(leg),numSamps), ...
        nan(numStim(leg),numSamps), ...
        nan(numStim(leg),numSamps)};
end

end

function snippets = extractSnippetsLeg(leg,indsPeaks,rawEMG,GRFz, ...
    snippets,snipStart,snipEnd,period)
% extract H-reflex snippets for a single leg

numStim = numel(indsPeaks{leg});        % number of stimuli for current leg
for st = 1:numStim                      % for each stimulus, ...
    win = (indsPeaks{leg}(st) + (snipStart / period)) : ...
        (indsPeaks{leg}(st) + (snipEnd / period));    % snippet window

    if ~isempty(rawEMG{leg})            % if EMG data available, ...
        snippets{leg,1}(st,:) = rawEMG{leg}(win);       % H-reflex snippet
    end

    if ~isempty(GRFz{leg})              % if GRFz data available, ...
        snippets{leg,2}(st,:) = GRFz{leg}(win);         % ipsilateral GRF
    end

    legContra = 3 - leg;                % contralat. index (1 -> 2, 2 -> 1)
    if ~isempty(GRFz{legContra})        % if GRFz data available, ...
        snippets{leg,3}(st,:) = GRFz{legContra}(win);   % contralateral GRF
    end
end

end

