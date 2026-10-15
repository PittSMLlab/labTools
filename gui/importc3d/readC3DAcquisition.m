function acq = readC3DAcquisition(fileName)
%READC3DACQUISITION Open a C3D file with BTK, or ezc3d where BTK can't run.
%
%   Platform-independent replacement for btkReadAcquisition. BTK is used
% whenever it can run (all lab Windows computers); otherwise ezc3d reads
% the file (see GETC3DREADER). Pass the result to GETC3DANALOGS and
% GETC3DMARKERS, which return exactly what btkGetAnalogs and
% btkGetMarkers return, and release it with CLOSEC3DACQUISITION.
%
%   Inputs:
%     fileName - path to a .c3d file
%
%   Outputs:
%     acq - struct with fields
%             reader   - 'btk' or 'ezc3d'
%             fileName - the file read
%             handle   - BTK acquisition handle ('btk' only)
%             c3d      - struct returned by ezc3dRead ('ezc3d' only)
%
%   Toolbox Dependencies:
%     BTK - Biomechanical ToolKit (default; external dependency)
%     ezc3d - pyomeca C3D reader (fallback; external dependency)
%
%   See also GETC3DREADER, GETC3DANALOGS, GETC3DMARKERS,
%   CLOSEC3DACQUISITION, BTKREADACQUISITION.

arguments
    fileName {mustBeTextScalar}
end

fileName = char(fileName);
if ~isfile(fileName)
    error('readC3DAcquisition:fileNotFound', ...
        'C3D file not found: %s', fileName);
end

acq = struct('reader', getC3DReader(), 'fileName', fileName, ...
    'handle', [], 'c3d', []);
switch acq.reader
    case 'btk'
        acq.handle = btkReadAcquisition(fileName);
    case 'ezc3d'
        acq.c3d = ezc3dRead(fileName);
end

end
