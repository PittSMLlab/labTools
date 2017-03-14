function [pp] = polyfit1PCA(x,y)
%Finding best line through PCA
my=mean(y);
y=y(:)'-my;
mx=mean(x);
    x=x(:)'-mx;
[ppp,ccc,aaa]=pca([x; y],'Centered',false); 
ccc=ccc(:,1);
pp(1)=ccc(2)/ccc(1);
pp(2)=my-mx*pp(1);


end

