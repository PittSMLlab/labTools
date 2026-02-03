function N = getMasterSampleLength(this)
%getMasterSampleLength  Returns common sample length if time
%normalized
%
%   N = getMasterSampleLength(this) returns the common sample
%   length across all time series if data is time normalized.
%   Returns 0 if not time normalized.
%
%   Inputs:
%       this - strideData object
%
%   Outputs:
%       N - common sample length (0 if not time normalized)
%
%   See also: timeNormalize

cname = class(this);
auxLst = properties(cname);
N = 0;
for i = 1:length(auxLst)
    % Should try to do this only if the property is not dependent,
    % otherwise, I'm computing things I don't need
    eval(['oldVal = this.' auxLst{i} ';']);
    if isa(oldVal, 'labTimeSeries')
        if oldVal.Nsamples ~= N % Discrepancy
            if N == 0 % First discrepancy: does not really say anything
                N = oldVal.Nsamples;
            else % New discrepancy, it is not time normalized
                N = 0;
                break;
            end
        end
    end
end
end

