function [pp] = polyfit1PCA(x,y,varNormalizeFlag)
%Finding best line through PCA
my=mean(y);
y=y(:)'-my;
mx=mean(x);
    x=x(:)'-mx;
    if nargin>2 && ~isempty(varNormalizeFlag) && varNormalizeFlag==1
      vx=std(x);
      vy=std(y);
    else
      vx=1;
      vy=1;
end
[ppp,ccc,aaa]=pca([x/vx; y/vy],'Centered',false);
ccc=ccc(:,1);
pp(1)=ccc(2)*vy/(ccc(1)*vx);
pp(2)=my-mx*pp(1);


end
