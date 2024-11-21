function [snippets,timesSnippet] = extractSnippets(indsPeaks,rawEMG_MG,GRFz)
%EXTRACTSNIPPETS Extract H-reflex & GRF snippets for plotting waveforms
%   Extract the snippets of the H-reflex from the medial gastrocnemus
% muscle raw EMG signal based on the stimulation artifact peak alignment.
% Also, extract the ground reaction force (GRF) snippets for plotting to
% visually detect if stimulation occurs during single stance.
%
% input:
%   indsPeaks: 2 x 1 cell array of number of peaks x 1 arrays of the
%       stimulation artifact peaks found by the algorithm
%   rawEMG_MG: 2 x 1 cell array of number of samples x 1 arrays for right
%       (cell 1) and left (cell 2) leg MG muscle EMG signal (NOTE: if one
%       cell is input as empty array, that leg will not be computed)
%   GRFz: 2 x 1 cell array of number of samples x 1 arrays for right
%       (cell 1) and left (cell 2) treadmill force plate z-axis GRFs (NOTE:
%       if one cell is input as empty array, that leg will not be computed)
% output:
%   snippets: 2 x 3 cell array of number of stimuli x 1 arrays for
%       right (row 1) and left (row 2) leg H-reflex (col 1), ipsilateral
%       (col 2) and contralateral (col 3) GRF snippets for later plotting
%   timesSnippet: number of samples x 1 array with the relative time in
%       seconds of each snippet (t=0s is stimulation artifact peak
%       alignment time)

narginchk(3,3); % verify correct number of input arguments
% TODO: update input argument data validation (e.g., for force data)
if all(cellfun(@isempty,indsPeaks)) || all(cellfun(@isempty,rawEMG_MG))
    error(['There is data missing that is crucial for extracting the ' ...
        'H-reflex snippets.']);
end

% NOTE: should always be same across trials and should be same for forces
% TODO: make optional input argument
period = 0.0005; % EMG.sampPeriod;    % sampling period
snipStart = -0.005;                     % include 5 ms before artifact peak
snipEnd = 0.055;                        % include 55 ms after artifact peak
% store array of snippet sample times for plotting
timesSnippet = snipStart:period:snipEnd;
numSamps = length(timesSnippet);        % number of samples in EMG snippet
numStimR = length(indsPeaks{1});        % number of right leg stimuli
numStimL = length(indsPeaks{2});        % number of left leg stimuli

% store right (row 1) and left (row 2) leg H-reflex (col 1), ipsilateral
% (col 2) and contralateral (col 3) GRF snippets for plotting
snippets = cell(2,3);                   % store snippets for each leg
snippets(1,:) = cellfun(@(x) nan(numStimR,numSamps),snippets(1,:), ...
    'UniformOutput',false);
snippets(2,:) = cellfun(@(x) nan(numStimL,numSamps),snippets(2,:), ...
    'UniformOutput',false);

% TODO: move into helper function to handle case of only one leg and reduce
% likelihood of copy and paste errors
for stR = 1:numStimR                    % for each right leg stimulus, ...
    winR = (indsPeaks{1}(stR) + (snipStart/period)): ...
        (indsPeaks{1}(stR) + (snipEnd/period));
    if ~isempty(rawEMG_MG{1})
        snippets{1,1}(stR,:) = rawEMG_MG{1}(winR);
    end
    if ~isempty(GRFz{1})
        snippets{1,2}(stR,:) = GRFz{1}(winR);
    end
    if ~isempty(GRFz{2})
        snippets{1,3}(stR,:) = GRFz{2}(winR);
    end
end

for stL = 1:numStimL                    % for each left leg stimulus, ...
    winL = (indsPeaks{2}(stL) + (snipStart/period)): ...
        (indsPeaks{2}(stL) + (snipEnd/period));
    if ~isempty(rawEMG_MG{2})
        snippets{2,1}(stL,:) = rawEMG_MG{2}(winL);
    end
    if ~isempty(GRFz{2})
        snippets{2,2}(stL,:) = GRFz{2}(winL);
    end
    if ~isempty(GRFz{1})
        snippets{2,3}(stL,:) = GRFz{1}(winL);
    end
end

end

