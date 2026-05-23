function angle=calcangle(jt1, jt2, jt3)
      vector1=jt2-jt1;
      vector2=jt2-jt3;
      dotprod=dot(vector1,vector2,2); %find dot product in 2D
      [rr, cc]=size(jt1);
      
      if cc==3 %3D
       len1=sqrt((vector1(:,1).^2)+(vector1(:,2).^2)+(vector1(:,3).^2));
       len2=sqrt((vector2(:,1).^2)+(vector2(:,2).^2)+(vector2(:,3).^2));
       theangle=acos(dotprod./(len1.*len2));
      else %2D
       len1=sqrt((vector1(:,1).^2)+(vector1(:,2).^2));
       len2=sqrt((vector2(:,1).^2)+(vector2(:,2).^2));
       theangle=acos(dotprod./(len1.*len2));
      end;
      angle=theangle*(180/pi);
              
      

    clear vector1 vector2 dotprod jt1 jt2 jt3 rr cc len1 len2 tempang theangle%CALCANGLE Compute the joint angle at the vertex joint.
%
%   Calculates the angle in degrees between vectors formed by three
% joint positions. JT2 is the vertex. Accepts both 2D (N×2) and 3D
% (N×3) position matrices.
%
% Inputs:
%   jt1 - N×2 or N×3 matrix of joint 1 positions
%   jt2 - N×2 or N×3 matrix of vertex joint positions
%   jt3 - N×2 or N×3 matrix of joint 3 positions
%
% Outputs:
%   angle - N×1 vector of joint angles in degrees
%
% Toolbox Dependencies: None
%
% See also DOT, ACOS.
