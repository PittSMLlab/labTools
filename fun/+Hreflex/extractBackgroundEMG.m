function snippets = extractBackgroundEMG(inds,rawEMG,opts)
%EXTRACTSNIPPETS Extract background EMG snippets for plotting & amplitude
%   Extract the snippets of the background EMG from the muscle signal based
% on the indices provided.
%
% input:
%   inds: 2 x 1 cell array of number of indices x 1 arrays of the
%       indices for which to determine background EMG
%   rawEMG: 2 x 1 cell array of number of samples x 1 arrays for right
%       (cell 1) and left (cell 2) leg EMG signal (NOTE: if one cell is
%       input as empty array, that leg will not be computed)
% output:
%   snippets: 2 x 1 cell array of number of indices x number of samples
%       arrays for right (row 1) and left (row 2) leg background EMG

narginchk(2,3);         % verify correct number of input arguments

if all(cellfun(@isempty,inds)) || all(cellfun(@isempty,rawEMG))
    error(['There is data missing that is critical for extracting the ' ...
        'H-reflex snippets.']);     % return with error
end

if nargin < 3                       % if no optional third input arg., ...
    dur = 0.050;                    % 50 ms background EMG window
    sampsBefore = 0;                % samples to skip before index
else                                % otherwise, ...
    dur = opts.dur;                 % use input arguments
    sampsBefore = opts.sampsBefore;
end

% NOTE: should always be same across trials and should be same for forces
% constants for snippet extraction
period = 0.0005;                        % sampling period (seconds)
numSamps = dur / period;                % number of samples in EMG snippet
snipStart = -numSamps - sampsBefore;    % snippet starting sample
snipEnd = -sampsBefore;                 % snippet ending sample

% initialize the snippets cell array to be populated by extraction
numInds = cellfun(@length,inds);        % number of indices for each leg

% store right (row 1) and left (row 2) leg background EMG snippets
snippets = cell(2,1);
snippets{1} = {nan(numInds(1),numSamps)};
snippets{2} = {nan(numInds(2),numSamps)};

for leg = 1:2                           % for right and left leg, ...
    if ~isempty(inds{leg})              % if indices, ...
        snippets{leg} = extractSnippetsLeg(inds{leg},rawEMG{leg}, ...
            snippets{leg},snipStart,snipEnd);
    end
end

end

function snippets = extractSnippetsLeg(inds,rawEMG,snippets, ...
    snipStart,snipEnd)
% extract background EMG snippets for a single leg

numInds = numel(inds);                  % number of indices for current leg
for ii = 1:numInds                      % for each index, ...
    win = (inds(ii) + snipStart):(inds(ii) + snipEnd);  % snippet window

    if ~isempty(rawEMG)                 % if EMG data available, ...
        snippets(ii,:) = rawEMG(win);   % background EMG snippet
    end
end

end

