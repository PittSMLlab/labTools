function [yS_hat,eS,nS,ytS_hat,etS,ntS] = computeGelsysParameterCorrelations(uS,yS,utS,ytS,ytS_hat)

    uSprev=[NaN; uS(1:end-1)];
    r=nanmean(yS./uS); %foreaft ratio
    yS_hat=uS*r;
    eS=yS-yS_hat;
    eSprev=[NaN; eS(1:end-1)];
    nS=(uS-uSprev)./eSprev;
    
    
    utSprev=[NaN; utS(1:end-1)];
    etS=ytS-ytS_hat;
    etSprev=[NaN; etS(1:end-1)];
    ntS=(utS-utSprev)./etSprev;


end
