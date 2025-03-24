function snippets = extractBackgroundEMG(inds,rawEMG,opts)
%EXTRACTSNIPPETS Extract background EMG snippets before given indices
%   Extract the snippets of the background EMG from the muscle signal
% before the indices provided.
%
% input:
%   inds: 2 x 1 cell array of number of indices x 1 arrays of the
%       indices for which to determine background EMG
%   rawEMG: 2 x 1 cell array of number of samples x 1 arrays for right
%       (cell 1) and left (cell 2) leg EMG signal (NOTE: if one cell is
%       input as empty array, that leg will not be computed)
%   opts (optional): structure with fields:
%       .dur        : background window duration (seconds, default = 0.050)
%       .sampsBefore: number of samples to skip before index (default = 0)
% output:
%   snippets: 2 x 1 cell array of number of indices x number of samples
%       arrays for right (row 1) and left (row 2) leg background EMG

narginchk(2,3);         % verify correct number of input arguments

% check input data exists
if all(cellfun(@isempty,inds)) || all(cellfun(@isempty,rawEMG))
    error('Missing critical data for extracting background EMG.');
end

% default options
if nargin < 3                           % if no opt. 3rd input arg., ...
    dur = 0.050;                        % 50 ms background EMG window
    sampsBefore = 0;                    % samples to skip before index
else                                    % otherwise, ...
    dur = opts.dur;                     % use input arguments
    sampsBefore = opts.sampsBefore;
end
% NOTE: assuming sampling period remains constant
period = 0.0005;                        % sampling period (seconds)
numSamps = round(dur / period);         % number of samples in the window
relStart = -numSamps - sampsBefore;     % relative window start index
relEnd   = -sampsBefore;                % relative window end index

% initialize the snippets cell array to be populated by extraction
numInds = cellfun(@length,inds);        % number of indices for each leg

% store right (row 1) and left (row 2) leg background EMG snippets
snippets = cell(2,1);                   % preallocate output cell array

for leg = 1:2                           % for right and left leg, ...
    if isempty(inds{leg}) || isempty(rawEMG{leg})   % if missing data, ...
        snippets{leg} = [];             % return empty array
        continue;                       % advance to next leg
    end
    numInds = numel(inds{leg});         % number of indices for current leg
    % Preallocate matrix for snippets: rows = number of indices, columns = window samples.
    snipLeg = nan(numInds,numSamps);    % initialize snippet array for leg
    for ii = 1:numInds                  % for each index, ...
        win = (inds{leg}(ii) + relStart):(inds{leg}(ii) + relEnd);
        % check boundaries: if window exceeds signal limits, fill with NaN
        % TODO: may be overkill since likely would never occur (or just at
        % first and last strides), snippets{leg}(ii,:) = rawEMG{leg}(win);
        valid = (win >= 1) & (win <= length(rawEMG{leg}));
        if any(valid)
            temp = nan(1,numSamps);
            temp(valid) = rawEMG{leg}(win(valid));
            snipLeg(ii,:) = temp;
        end
    end
    snippets{leg} = snipLeg;
end

end

