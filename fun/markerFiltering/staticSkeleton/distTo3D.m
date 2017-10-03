function [pos3d] = distTo3D(distances,anchorPositions,anchorIndexes)
%Takes a matrix of distances N^2 x 1 and returns the minimum squared-error
%reconstruction in a 3D space through multi-dimensional scaling
%
pos3d=mdscale(distances,3); %Need to choose the proper metric, I don't think the default is the best
%getPoisitionFromDistances.m in /sideProjects/markerModels has an
%alternative way to do it.

%Do a rotation+translation to find the most likely position
[R,t,X1proy] = getRotationAndTranslation(pos3d(anchorIndexes,:),anchorPositions); %pos3D
pos3d=pos3d*R+t;
end

