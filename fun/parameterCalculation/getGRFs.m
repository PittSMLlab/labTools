function [GRFf, GRFs, GRFh] = getGRFs(GRFData,s,f)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
        auxLabels={'Fx','Fy','Fz','Mx','My','Mz'};
        for i=1:6
            GRFLabels{i}=[s auxLabels{i}];
        end
        GRFDataS=GRFData.getDataAsVector(GRFLabels);
        [GRFs] = idealLPF(GRFDataS,10/GRFData.sampFreq);
        for i=1:6
            GRFLabels{i}=[f auxLabels{i}];
        end
        GRFDataF=GRFData.getDataAsVector(GRFLabels);
        [GRFf] = idealLPF(GRFDataF,10/GRFData.sampFreq);
        for i=1:6
            GRFLabels{i}=['H' auxLabels{i}];
        end
        GRFDataH=GRFData.getDataAsVector(GRFLabels);
        [GRFh] = idealLPF(GRFDataH,10/GRFData.sampFreq);

end

