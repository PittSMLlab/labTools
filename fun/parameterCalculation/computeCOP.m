function [COP] = computeCOP(GRFDataS,GRFDataF,s,f)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

        LTransformationMatrix=[1,0,0,0;20,1,0,0;1612,0,-1,0;0,0,0,-1];
        RTransformationMatrix=[1,0,0,0;-944,-1,0,0;1612,0,-1,0;0,0,0,-1];
        eval(['STransformationMatrix=' s 'TransformationMatrix(2:end,2:end);' ])
        eval(['FTransformationMatrix=' f 'TransformationMatrix(2:end,2:end);' ])
        eval(['STransformationVec=' s 'TransformationMatrix(2:end,1);' ])
        eval(['FTransformationVec=' f 'TransformationMatrix(2:end,1);' ])
        
        relGRF=GRFDataS;
        COPS(:,2)=(-5*relGRF(:,2) + relGRF(:,4))./relGRF(:,3);
        COPS(:,1)=(-5*relGRF(:,1) - relGRF(:,5))./relGRF(:,3);
        COPS(:,3)=0;
        COPS=bsxfun(@plus, STransformationMatrix*COPS', STransformationVec);
        
        FzS=relGRF(:,3);
        relGRF=GRFDataF;
        COPF(:,2)=(-5*relGRF(:,2) + relGRF(:,4))./relGRF(:,3);
        COPF(:,1)=(-5*relGRF(:,1) - relGRF(:,5))./relGRF(:,3);
        COPF(:,3)=0;
        COPF=bsxfun(@plus, FTransformationMatrix*COPF', FTransformationVec);
        FzF=relGRF(:,3);
        COP=bsxfun(@rdivide,(bsxfun(@times,COPF,FzF') + bsxfun(@times,COPS,FzS')),(FzS'+FzF'));

end

