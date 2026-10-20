function newThis = flipAxis(this, axis)
%FLIPAXIS Flips specified axis.
%
%   newThis = flipAxis(this, axis) flips sign of specified axis
%
% Inputs:
%   this - orientedLabTimeSeries object
%   axis - axis to flip: 'x', 'y', 'z' or 1, 2, 3
%
% Outputs:
%   newThis - flipped orientedLabTimeSeries
%
% Toolbox Dependencies: None
%
% See also ROTATE.

matrix = eye(3);
if isa(axis, 'char')
    % This converts 'x', 'y', 'z' to 1, 2, 3
    axis = axis - 'w';
end
matrix(axis, axis) = -1;
newThis = this.rotate(matrix);
end

