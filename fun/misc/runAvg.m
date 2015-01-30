function [xnew, xnewstd]=runAvg(x,binwidth,dim)
% writen based on bin_dataV1 writen by GTO April 14th 2009
% function does running average. xnew averages x along dimension entered,
% if specified (1=rows, 2=cols) otherwise it averages along larger dimension.
% binwidth indicates the duration of each time bin
% Created by HH on 9/18/2014

rows=size(x,1);
cols=size(x,2);

if ~isempty(x)
    if binwidth==1
        xnew=x;
        xnewstd=zeros(rows,cols);
    else
        if rows>=cols || (nargin>2 && dim==1) %average rows
            for  i=1:rows
                t1=max([1 i-floor(binwidth/2)]);
                t2=min([rows i+ceil(binwidth/2)]);
                
                xnew(i,:) = nanmean(x(t1:t2,:),1);
                xnewstd(i,:) = nanstd(x(t1:t2,:),[],1);                
            end
        elseif cols>rows || (nargin>2 && dim==2) %average columns
            for  i=1:cols
                t1=max([1 i-floor(binwidth/2)]);
                t2=min([cols i+ceil(binwidth/2)]);
                
                xnew(:,i) = nanmean(x(:,t1:t2),2);
                xnewstd(:,i) = nanstd(x(:,t1:t2),[],2);                
            end
        else
            warning('Dimension entered not correct')
            xnew=[];
            xnewstd=[];
        end
    end
else
    xnew=[];
    xnewstd=[];
end
