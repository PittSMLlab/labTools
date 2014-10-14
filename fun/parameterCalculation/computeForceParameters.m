function [COPrangeF,COPrangeS,COPsym,COPsymM,handHolding] = computeForceParameters(GRFData,s,f,indSHS,indSTO,indFHS,indFTO,indSHS2,indFTO2)
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here
[GRFDataF, GRFDataS, GRFDataH] = getGRFs(GRFData,s,f);    
%% COP range and symmetry
[COP] = computeCOP(GRFDataS,GRFDataF,s,f);
        %Mawase's way based on TO and HS
        %COPrangeF(step)=COP(2,indFTO)-COP(2,indSHS);
        %COPrangeS(step)=COP(2,indSTO)-COP(2,indFHS);
        %May way based on TO and HS
%         COPrangeF(step)=COP(2,indFTO)-COP(2,indFHS);
%         COPrangeS(step)=COP(2,indSTO)-COP(2,indSHS);
        %Mawase's ugly way:
        COPrangeF=min(COP(2,indSHS:indFHS))-max(COP(2,max([indSHS-100,1]):indFTO));
        COPrangeS=min(COP(2,indFHS:indSHS2))-max(COP(2,indFTO:indSTO));
        COPsymM=(COPrangeF-COPrangeS)/(COPrangeF+COPrangeS);
        %My very nice way:
        COPrangeF=min(COP(2,indSHS:indFHS))-max(COP(2,indFTO:indSTO));
        COPrangeS=min(COP(2,indFHS:indSHS2))-max(COP(2,indSTO:indFTO2)); 
        COPsym=(COPrangeF-COPrangeS)/(COPrangeF+COPrangeS);

%% Hand holding
        handHolding=sum(mean(abs(GRFDataH)))>2;

end

