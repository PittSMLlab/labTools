function closeC3DAcquisition(acq)
%CLOSEC3DACQUISITION Release a C3D acquisition opened by READC3DACQUISITION.
%
%   With BTK this calls btkCloseAcquisition, freeing the C++ memory BTK
% holds for the acquisition (MATLAB does not release it on its own).
% ezc3d data are ordinary MATLAB variables, so nothing is needed there.
%
%   Inputs:
%     acq - struct returned by READC3DACQUISITION
%
%   Outputs:
%     none
%
%   Toolbox Dependencies:
%     BTK or ezc3d (see READC3DACQUISITION)
%
%   See also READC3DACQUISITION, BTKCLOSEACQUISITION.

arguments
    acq (1,1) struct
end

if strcmp(acq.reader, 'btk') && ~isempty(acq.handle)
    btkCloseAcquisition(acq.handle);
end

end
