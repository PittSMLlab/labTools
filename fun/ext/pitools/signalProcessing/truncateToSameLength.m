function [newMatrix1, newMatrix2] = truncateToSameLength(matrix1, matrix2)
%TRUNCATETOSAMELENGTH Truncate two matrices to the same number of rows.
%
%   Compares the row counts of matrix1 and matrix2 and truncates the
% longer one so both have the same number of rows. Operates along
% dimension 1 only; columns are preserved.
%
% Inputs:
%   matrix1 - first input matrix
%   matrix2 - second input matrix
%
% Outputs:
%   newMatrix1 - matrix1, possibly truncated to match matrix2's row count
%   newMatrix2 - matrix2, possibly truncated to match matrix1's row count
%
% Toolbox Dependencies: None
%
% See also MATCHSIGNALS, RESAMPLESHIFTANDSCALE.

arguments
    matrix1 (:,:) double
    matrix2 (:,:) double
end

%% Truncate Longer Matrix
if size(matrix2, 1) > size(matrix1, 1)
    newMatrix2 = matrix2(1:size(matrix1, 1), :);
    newMatrix1 = matrix1;
else
    newMatrix1 = matrix1(1:size(matrix2, 1), :);
    newMatrix2 = matrix2;
end

end
