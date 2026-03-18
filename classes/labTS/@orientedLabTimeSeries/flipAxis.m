function newThis = flipAxis(this, axis)
%flipAxis  Flips specified axis
%
%   newThis = flipAxis(this, axis) flips sign of specified axis
%
%   Inputs:
%       this - orientedLabTimeSeries object
%       axis - axis to flip: 'x', 'y', 'z' or 1, 2, 3
%
%   Outputs:
%       newThis - flipped orientedLabTimeSeries
%
%   See also: rotate

matrix = eye(3);
if isa(axis, 'char')
    % This converts 'x', 'y', 'z' to 1, 2, 3
    axis = axis - 'w';
end
matrix(axis, axis) = -1;
newThis = this.rotate(matrix);
end

