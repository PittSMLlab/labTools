function refMap = getPatternFillReferenceMap()
%GETPATTERNFILLREFERENCEMAP Build reference-to-target marker map for pattern fill.
%
%   Returns a containers.Map mapping each target marker name to its
% designated reference marker for pattern-based gap filling. The map
% encodes the anatomical hierarchy: pelvis/hip markers reference the
% greater trochanter, which references the knee, and so on distally.
%
% Inputs:
%   None
%
% Outputs:
%   refMap - containers.Map of target marker names to reference marker
%            names (strings)
%
% Toolbox Dependencies: None
%
% See also RUNCUSTOMPATTERNFILL.

refMap = containers.Map;

refMap('RPSIS')  = 'RGT';
refMap('RASIS')  = 'RGT';
refMap('LPSIS')  = 'LGT';
refMap('LASIS')  = 'LGT';
refMap('RGT')    = 'RKNEE';
refMap('RTHI')   = 'RGT';
refMap('RKNEE')  = 'RGT';
refMap('RSHANK') = 'RKNEE';
refMap('RANK')   = 'RKNEE';
refMap('RHEEL')  = 'RANK';
refMap('RTOE')   = 'RANK';
refMap('LGT')    = 'LKNEE';
refMap('LTHI')   = 'LGT';
refMap('LKNEE')  = 'LGT';
refMap('LSHANK') = 'LKNEE';
refMap('LANK')   = 'LKNEE';
refMap('LHEEL')  = 'LANK';
refMap('LTOE')   = 'LANK';

end
