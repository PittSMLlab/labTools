function angle=calcangle(jt1, jt2, jt3)
%angle.m
% data=angle(jt1, jt2, jt3)
%calculates angle between vectors
%pass it the 3D position of three joints - e.g. jt1=[x y z] jt2=[x y z] jt3=[x y z]
%make jt2 the vertex. Pass 2D position for 2D angle


     
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
              
      

    clear vector1 vector2 dotprod jt1 jt2 jt3 rr cc len1 len2 tempang theangle