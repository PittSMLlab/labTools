function [rows,cols] = subplotSize(n_plots,relRows,relCols)
%SUBPLOTSIZE Rows and columns for a subplot figure.
%
%   [rows,cols] = SUBPLOTSIZE(n_plots) returns the number of rows and
% columns that fit n_plots into one figure; SUBPLOTSIZE(n_plots,relRows,
% relCols) uses the layout closest to a relRows:relCols ratio.
%
% Inputs:
%   n_plots - number of plots
%   relRows - (optional) relative number of rows (default: 1)
%   relCols - (optional) relative number of columns (default: 1)
%
% Outputs:
%   rows - number of rows
%   cols - number of columns
%
% Example:
%   For n_plots = 23, [r,c] = subplotSize(23) gives r = 5, c = 5 and
%   subplotSize(23,2,1) gives r = 6, c = 4.
%
% Toolbox Dependencies: None
%
% See also SUBPLOT, OPTIMIZEDSUBPLOT, GETFIGSTRUCT.

%   Copyright 2014 HMRL.

if nargin > 0 && nargin < 3
    relRows = 1;
    relCols = 1;
end

% widthRatio = relCols/(relCols+relRows);
% heightRatio= relRows/(relCols+relRows);
ratio = relCols/relRows;

ceilsqrt = ceil(sqrt(n_plots));

delta = ceilsqrt*(ratio-1)/(1+ratio);

rows = round(ceilsqrt-delta);
cols = round(ceilsqrt+delta);

diff = rows*cols-n_plots;

while diff < 0
    if (rows/cols) > (relRows/relCols)
        cols = cols+1;
    else
        rows = rows+1;
    end
    diff = rows*cols-n_plots;
end

if relCols > relRows
    if diff >= cols
        rows = rows-1;
    elseif diff >= rows
        cols = cols-1;
    end
else
    if diff >= rows
        cols = cols-1;
    elseif diff >= cols
        rows = rows-1;
    end
end

end


