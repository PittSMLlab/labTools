function [analogs, analogsInfo] = getC3DAnalogs(acq)
%GETC3DANALOGS Analog channels of a C3D file, in btkGetAnalogs format.
%
%   With BTK this simply calls btkGetAnalogs. With ezc3d it builds the
% identical output, following BTKCore's C3D reader (Code/IO/
% btkC3DFileIO.cpp) and MEX wrapper (Wrapping/Matlab/btkMXAnalog.cxx):
%     - values are (raw - OFFSET) * SCALE * GEN_SCALE, as returned by
%       ezc3dRead (ezc3d >= 1.7.2; earlier releases mis-scaled floats)
%     - info.scale stores SCALE * GEN_SCALE (GEN_SCALE = 0 is read as 1)
%     - info.gain maps ANALOG:GAIN codes 0-5 to BTK's Analog::Gain enum
%
%   Inputs:
%     acq - struct returned by READC3DACQUISITION
%
%   Outputs:
%     analogs     - struct with one nSamples-by-1 double field per
%                   channel, named by C3DLABELSTOFIELDNAMES
%     analogsInfo - struct with fields (in BTK's order) label,
%                   description, gain, offset, scale (structs with one
%                   field per channel), frequency (scalar, Hz) and units
%                   (struct of unit strings per channel)
%
%   Toolbox Dependencies:
%     BTK or ezc3d (see READC3DACQUISITION)
%
%   See also READC3DACQUISITION, GETC3DMARKERS, C3DLABELSTOFIELDNAMES,
%   BTKGETANALOGS.

arguments
    acq (1,1) struct
end

if strcmp(acq.reader, 'btk')
    [analogs, analogsInfo] = btkGetAnalogs(acq.handle);
    return
end

%% Read Channel Parameters
% BTK's Analog::Gain values (millivolts of range) for C3D ANALOG:GAIN
% codes 0-5 (btkC3DFileIO.cpp; enum in Code/Common/btkAnalog.h)
gainCodeToBtk = [0 10000 5000 2500 1250 1000];   % codes 0, 1, ..., 5

c3d      = acq.c3d;
values   = c3d.data.analogs;                    % nSamples x nChannels
nChannel = size(values, 2);
analogParams = struct();
if isfield(c3d.parameters, 'ANALOG')
    analogParams = c3d.parameters.ANALOG;
end

labels       = c3dParameterValues(analogParams, 'LABELS', nChannel, ...
    'uname*');
descriptions = c3dParameterValues(analogParams, 'DESCRIPTIONS', ...
    nChannel, '');
units        = c3dParameterValues(analogParams, 'UNITS', nChannel, '');
offsets      = c3dParameterValues(analogParams, 'OFFSET', nChannel, 0);
scales       = c3dParameterValues(analogParams, 'SCALE', nChannel, 1);
gainCodes    = c3dParameterValues(analogParams, 'GAIN', nChannel, 0);

genScale = 1;
if isfield(analogParams, 'GEN_SCALE') && ...
        ~isempty(analogParams.GEN_SCALE.DATA)
    genScale = double(analogParams.GEN_SCALE.DATA(1));
end
if genScale == 0                       % BTK replaces 0 by 1 (warning)
    genScale = 1;
end

frequency = 0;
if isfield(analogParams, 'RATE') && ~isempty(analogParams.RATE.DATA)
    frequency = double(analogParams.RATE.DATA(1));
end

%% Build Outputs in BTK's Layout
fieldNames = c3dLabelsToFieldnames(labels);
analogs    = struct();
info       = struct('label', struct(), 'description', struct(), ...
    'gain', struct(), 'offset', struct(), 'scale', struct(), ...
    'frequency', frequency, 'units', struct());
for ch = 1:nChannel
    fn = fieldNames{ch};
    analogs.(fn) = double(values(:, ch));

    gain = 0;                              % Analog::Unknown
    if gainCodes(ch) >= 0 && gainCodes(ch) <= 5 && ...
            gainCodes(ch) == round(gainCodes(ch))
        gain = gainCodeToBtk(gainCodes(ch) + 1);
    end

    info.label.(fn)       = labels{ch};
    info.description.(fn) = descriptions{ch};
    info.gain.(fn)        = gain;
    info.offset.(fn)      = offsets(ch);
    info.scale.(fn)       = scales(ch) * genScale;
    info.units.(fn)       = units{ch};
end
analogsInfo = info;

end
