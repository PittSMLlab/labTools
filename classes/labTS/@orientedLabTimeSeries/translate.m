function newThis = translate(this, vector)
%translate  Translates data by vector
%
%   newThis = translate(this, vector) applies vector translation to all
%   oriented data
%
%   Inputs:
%       this - orientedLabTimeSeries object
%       vector - 1x3 or Tx3 translation vector
%
%   Outputs:
%       newThis - translated orientedLabTimeSeries
%
%   Note: Vector has to be size 3 on second dim, and singleton or of
%         length(time) in first
%
%   See also: rotate, referenceToMarker

% Check: vector is 1x3 or Tx3
[M, N] = size(vector);
if N ~= 3 || (M ~= 1 && M ~= numel(this.Time))
    error('orientedLabTS:translate', ...
        ['Translation vector has to be size 3 on second dim, and ' ...
        'singleton or of length(time) in the first.']);
end
data = getOrientedData(this);
vector = reshape(vector, M, 1, 3);
newData = permute(bsxfun(@plus, data, vector), [1 3 2]);
newThis = orientedLabTimeSeries(newData(:, :), this.Time(1), ...
    this.sampPeriod, this.labels, this.orientation);
% newThis.UserData.translation = ; % TODO: store the translation info
% in some structure so that it can be backtracked
end

