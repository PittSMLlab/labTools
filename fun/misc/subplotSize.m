function [rows,cols]=subplotSize(n_plots,relHeight,relWidth)

widthRatio = relWidth/(relWidth+relHeight);
heightRatio= relHeight/(relWidth+relHeight);
ratio=relWidth/relHeight;

ceilsqrt=ceil(sqrt(n_plots));
%ceilsqrt=n_plots;

delta=ceilsqrt*(ratio-1)/(1+ratio);

rows=round(ceilsqrt-delta);
cols=round(ceilsqrt+delta);

diff=rows*cols-n_plots;

while diff<0
    if (rows/cols)>(relHeight/relWidth)
        cols=cols+1;
    else
        rows=rows+1;
    end
    diff=rows*cols-n_plots;
end

if relWidth>relHeight
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


