function newThis = rotate(this, matrix)
%rotate  Rotates data by matrix
%
%   newThis = rotate(this, matrix) applies rotation/transformation
%   matrix to data
%
%   Inputs:
%       this - orientedLabTimeSeries object
%       matrix - 3x3 or Tx3x3 transformation matrix
%
%   Outputs:
%       newThis - transformed orientedLabTimeSeries
%
%   Note: Since no check is done on matrix, allows any linear
%         transformation including contractions/expansions and inversions
%
%   See also: translate, alignRotate, flipAxis

[data, label] = getOrientedData(this);
if ndims(matrix) == 3
    M = size(matrix, 1);
else
    M = 1;
end
matrix = reshape(matrix, M, 1, 3, 3);
newData = permute(sum(bsxfun(@times, data, matrix), 3), [1, 4, 2, 3]);
newThis = orientedLabTimeSeries(newData(:, :), this.Time(1), ...
    this.sampPeriod, this.labels, this.orientation);
% newThis.UserData.rotation = ; % TODO: store the rotation info in some
% structure so that it can be backtracked
end

