function [slices] = sliceArray(data,inds,dim)
%SLICEARRAY Extract slices of an array along a given dimension.
%
%   Returns the subset of slices indexed by inds along dimension dim.
%   Equivalent to data(:,...,inds,...,:) where inds occupies position dim.
%   Preferable to permute-based solutions, which copy the full array.
%
% Inputs:
%   data - N-D array to index into
%   inds - index vector selecting slices along dimension dim
%   dim  - dimension along which to slice (scalar integer)
%
% Outputs:
%   slices - array with size(slices, dim) == length(inds)
%
% Toolbox Dependencies: None
%
% See also PERMUTE, SQUEEZE.

nd=ndims(data);
if dim>nd
    error('')
end
N=size(data,dim);
if any(inds>N | inds<1)
    error()
end
prefix=repmat(':,',1,dim-1);
suffix=repmat(',:',1,nd-dim);
eval(['slices=data(' prefix 'inds' suffix ');'])
end

