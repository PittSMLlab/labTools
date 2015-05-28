function [rows,cols]=subplotSize(n_plots,relRows,relCols)
%SUBPLOTSIZE Find the optimal dimensions of a subplot figure
%   [rows,cols] = SUBPLOTSIZE(n_plots) returns the number of rows and
%   columns that would optimally fit the given number of plots into a
%   single figure
%
%   [rows,cols] = SUBPLOTSIZE(n_plots,relRows,relCols) finds the optimal
%   subplot dimensions that most closely has a relRows:relCols ratio
%
%   Example: If n_plots = 23
%     then [r,c] = subplotSize(n_plots) reutrns r = 5 c = 5
%     and [r,c] = subplotSize(n_plots,2,1) returns r = 6 c = 4
%
%   See also subplot optimizedSubPlot

%   Copyright 2014 HMRL.

if nargin>0 && nargin<3
    relRows=1;
    relCols=1;
end

% widthRatio = relCols/(relCols+relRows);
% heightRatio= relRows/(relCols+relRows);
ratio=relCols/relRows;

ceilsqrt=ceil(sqrt(n_plots));

delta=ceilsqrt*(ratio-1)/(1+ratio);

rows=round(ceilsqrt-delta);
cols=round(ceilsqrt+delta);

diff=rows*cols-n_plots;

while diff<0
    if (rows/cols)>(relRows/relCols)
        cols=cols+1;
    else
        rows=rows+1;
    end
    diff=rows*cols-n_plots;
end

if relCols>relRows
    if diff>=cols
        rows=rows-1;
    elseif diff>=rows
        cols=cols-1;
    end
else
    if diff>=rows
        cols=cols-1;
    elseif diff>=cols
        rows=rows-1;
    end
end

end


