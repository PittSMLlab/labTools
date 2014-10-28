function [xnew, xnewstd]=bin_dataV1(x,binwidth)
% writen based on bin_data
% function does running average. xnew averages rows of x
% binwidth indicates the duration of each time bin
%writen by GTO April 14th 2009

if ~isempty(x)
    if binwidth==1
        xnew=x;
        xnewstd=zeros(size(x,1),size(x,2));
    else
        bstart=[1:size(x,1)-(binwidth-1)];
        bend=[bstart+binwidth-1];
        bend(find(bend>size(x,1)))=size(x,1);

        for  l=1:length(bstart)
            t1 = bstart(l);
            t2 = bend(l);
            if t2==t1;
                xnew(l,:)=NaN*zeros(1,size(x,2));
                xnewstd(l,:)=NaN*zeros(1,size(x,2));
                
                %xnew(l,:)=x(t1,:);
                %xnewstd(l,:)=zeros(1,size(x,2));             

            else
                xnew(l,:) = nanmean(x(t1:t2,:));
                xnewstd(l,:) = nanstd(x(t1:t2,:));
            end
        end
    end
else
    xnew=[];
    xnewstd=[];
end
