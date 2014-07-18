function [coefs] = coefExtrFromSyn(data,syn)
%coefExtrFromSyn Extract a coeficient (activation) matrix such that it
%solves the least squares problem data=syn*act; subject to the
%non-negativity of the activations.


opts= optimset('display','off','TolFun',.0001/size(data,2)^2,'TolX',.0001);
x0=ones(size(syn,2),size(data,1));

poolFlag=0;
matlabpool size;
if (ans==0)
    matlabpool open
    poolFlag=1;
end
   
coefs=[];
parfor i=1:size(data,1)
    x0=ones(size(syn,2),1);
    coefs(:,i) = lsqnonneg(syn,data(i,:)',opts);
end

if poolFlag==1
    matlabpool close
end
end

