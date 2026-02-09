function inds = indsInTrial(this, t)
%indsInTrial  Returns indices for specified trial(s)
%
%   inds = indsInTrial(this, t) returns stride indices belonging to
%   specified trial number(s)
%
%   Inputs:
%       this - parameterSeries object
%       t - trial number or vector of trial numbers (optional, returns
%           empty if not provided)
%
%   Outputs:
%       inds - cell array of index vectors, one per trial
%
%   See also: stridesTrial

if nargin < 2 || isempty(t)
    inds = [];
else
    inds = cell(length(t), 1);
    for ii = 1:length(t)
        inds{ii, 1} = find(this.stridesTrial == t(ii));
    end
end
end

