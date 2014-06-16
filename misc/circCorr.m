function lag=circCorr(trace1,trace2)
%Finds the phase shift of two sinuoidal traces. trace1 and trace2 must be
%vectors of the same length.

s1=std(trace1);
s2=std(trace2);

c=[];
n=length(trace1);
for t=1:n
    c(t)=(trace1'*trace2)./((n-1)*s1*s2);
    trace2=circshift(trace2,1);
end

[cmax,lag]=max(c);
lag=lag/n;

if cmax<0.5
    lag=NaN;
end

end