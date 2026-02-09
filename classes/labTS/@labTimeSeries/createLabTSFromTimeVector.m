function this = createLabTSFromTimeVector(data, time, labels)
%createLabTSFromTimeVector  Creates labTS from non-uniform time vector
%
%   this = createLabTSFromTimeVector(data, time, labels) creates a
%   labTimeSeries from data with potentially non-uniform time vector
%
%   Inputs:
%       data - data matrix
%       time - time vector (may be non-uniform)
%       labels - cell array of label strings
%
%   Outputs:
%       this - labTimeSeries object (uniformly sampled)
%
%   Note: Need to compute appropriate t0 and Ts constants and call the
%         constructor. Tricky if time is not uniformly sampled.
%
%   See also: labTimeSeries

% TODO: not implemented
end

