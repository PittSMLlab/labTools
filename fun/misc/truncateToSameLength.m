function [newMatrix1, newMatrix2] = truncateToSameLength(matrix1,matrix2)
%Works along dim 1, by truncating the longest of matrix1 and 2 so that
%size(newMatrix1,1)=size(newMatrix2,1)

if size(matrix2,1)>size(matrix1,1)
    newMatrix2=matrix2(1:size(matrix1,1),:);
    newMatrix1=matrix1;
else
    newMatrix1=matrix1(1:size(matrix2,1),:);
    newMatrix2=matrix2;
end

end

