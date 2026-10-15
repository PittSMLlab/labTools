function [markers, markersInfo] = getC3DMarkers(acq)
%GETC3DMARKERS Marker trajectories of a C3D file, in btkGetMarkers format.
%
%   With BTK this simply calls btkGetMarkers. With ezc3d it builds the
% identical output, following BTKCore's C3D reader (Code/IO/
% btkC3DFileIO.cpp) and MEX wrapper (Wrapping/Matlab/btkGetMarkers.cpp):
%     - markers are the POINT channels not listed in POINT:ANGLES,
%       FORCES, MOMENTS, POWERS, SCALARS or REACTIONS (Vicon model
%       outputs), in file order
%     - occluded samples (C3D residual < 0) keep the coordinates stored
%       in the file, which are 0 in Vicon files. ezc3d returns NaN for
%       them, so NaN is converted to 0 (loadTrials then sets 0 to NaN)
%
%   Inputs:
%     acq - struct returned by READC3DACQUISITION
%
%   Outputs:
%     markers     - struct with one nFrames-by-3 double field (X, Y, Z)
%                   per marker, named by C3DLABELSTOFIELDNAMES
%     markersInfo - struct with fields frequency (scalar, Hz) and units
%                   (struct with the single field ALLMARKERS)
%
%   Toolbox Dependencies:
%     BTK or ezc3d (see READC3DACQUISITION)
%
%   See also READC3DACQUISITION, GETC3DANALOGS, C3DLABELSTOFIELDNAMES,
%   BTKGETMARKERS.

arguments
    acq (1,1) struct
end

if strcmp(acq.reader, 'btk')
    [markers, markersInfo] = btkGetMarkers(acq.handle);
    return
end

%% Read Point Parameters
c3d    = acq.c3d;
points = c3d.data.points;                       % 3 x nPoints x nFrames
nPoint = size(points, 2);
pointParams = struct();
if isfield(c3d.parameters, 'POINT')
    pointParams = c3d.parameters.POINT;
end
labels = c3dParameterValues(pointParams, 'LABELS', nPoint, 'uname*');

%% Select Markers (BTK point types)
% Vicon lists model outputs by type in POINT:ANGLES, FORCES, ...; BTK
% assigns those types and btkGetMarkers returns only the rest.
modelTypeParams = {'ANGLES', 'FORCES', 'MOMENTS', 'POWERS', ...
    'SCALARS', 'REACTIONS'};
isModelOutput = false(1, nPoint);
for ii = 1:numel(modelTypeParams)
    if isfield(pointParams, modelTypeParams{ii})
        typeLabels = c3dParameterValues(pointParams, ...
            modelTypeParams{ii}, ...
            numel(pointParams.(modelTypeParams{ii}).DATA), '');
        isModelOutput = isModelOutput | ismember(labels, typeLabels);
    end
end
markerIdx = find(~isModelOutput);

%% Build Outputs in BTK's Layout
fieldNames = c3dLabelsToFieldnames(labels(markerIdx));
markers    = struct();
for mrkr = 1:numel(markerIdx)
    xyz = permute(points(1:3, markerIdx(mrkr), :), [3 1 2]);  % nFr x 3
    xyz(isnan(xyz)) = 0;                % BTK keeps stored zeros at gaps
    markers.(fieldNames{mrkr}) = double(xyz);
end

frequency = 0;
if isfield(pointParams, 'RATE') && ~isempty(pointParams.RATE.DATA)
    frequency = double(pointParams.RATE.DATA(1));
end
unitList = c3dParameterValues(pointParams, 'UNITS', 1, '');
markersInfo = struct('frequency', frequency, ...
    'units', struct('ALLMARKERS', unitList{1}));

end
