function newThis = alignRotate(this, newX, newZ)
%alignRotate  Aligns to new coordinate system
%
%   newThis = alignRotate(this, newX, newZ) rotates data to align with
%   new coordinate system
%
%   Inputs:
%       this - orientedLabTimeSeries object
%       newX - desired x-axis direction (1x3 or Nx3)
%       newZ - desired z-axis direction (1x3 or Nx3)
%
%   Outputs:
%       newThis - aligned orientedLabTimeSeries
%
%   Note: newX and newZ need to be 1x3 or Nx3 where N =
%         size(this.Data, 1). FIXME - Align z to newZ, and x to newX
%         projected in direction orthogonal to newZ
%
%   See also: rotate, translate

% newX and newZ need to be 1x3 or Nx3 where N = size(this.Data, 1)
% Check:
N = size(this.Data, 1);
if (size(newX, 1) ~= 1 && size(newX, 1) ~= N) || size(newX, 2) ~= 3
    error('orientedLabTS:alignRotate', 'newX has to be 1x3 or Nx3.');
end
if size(newZ, 1) ~= 1 && size(newZ, 1) ~= N || size(newZ, 2) ~= 3
    error('orientedLabTS:alignRotate', 'newZ has to be 1x3 or Nx3.');
end

% In case of one being 1x3 and the other Nx3, making them both Nx3
% FIXME: Align z to newZ, and x to newX projected in a direction
% orthogonal to newZ (or check that newX is orthogonal to newZ to
% start with)
if size(newX, 1) ~= size(newZ, 1)
    if size(newX, 1) == 1
        newX = repmat(newX, N, 1);
    else
        newZ = repmat(newZ, N, 1);
    end
end

newX = bsxfun(@rdivide, newX, sqrt(sum(newX.^2, 2)));
newZ = bsxfun(@rdivide, newZ, sqrt(sum(newZ.^2, 2)));
% Find rotation matrix
newY = -cross(newX, newZ); % orthogonal to the other two
newY = bsxfun(@rdivide, newY, sqrt(sum(newY.^2, 2)));
matrix1 = permute(newX, [1, 3, 2]);
matrix2 = permute(newY, [1, 3, 2]);
matrix3 = permute(newZ, [1, 3, 2]);
matrix = cat(2, matrix1, matrix2);
matrix = cat(2, matrix, matrix3);
for i = 1:size(matrix, 1)
    if ~any(isnan(matrix(i, :, :)))
        % Very expensive computation
        matrix(i, 1:3, 1:3) = inv(squeeze(matrix(i, :, :)));
    else
        matrix(i, 1:3, 1:3) = nan;
    end
end
% Rotate
newThis = rotate(this, matrix);
end

