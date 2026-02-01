function structure = getDataAsMatrices(this, fields, conditions, N)
%getDataAsMatrices  Converts stride data to matrices
%
%   structure = getDataAsMatrices(this, fields, conditions, N)
%   extracts and organizes stride data into matrices for analysis
%
%   Inputs:
%       this - stridedExperimentData object
%       fields - field name or cell array of field names to extract
%       conditions - vector of condition indices
%       N - number of samples for resampling
%
%   Outputs:
%       structure - cell array (one per condition) containing matrices
%                   of size (samples x channels x strides). If multiple
%                   fields requested, structure contains a struct with
%                   one field per requested data field
%
%   See also: strideData/cell2mat, getStridesFromCondition

for cond = conditions
    strides = this.getStridesFromCondition(cond);
    if isa(fields, 'cell')
        for f = 1:length(fields)
            for s = 1:length(strides)
                aux = strideData.cell2mat(strides, fields{f}, N);
            end
            eval(['structure{cond}.' fields{f} ' = aux;']);
        end
    else
        aux = strideData.cell2mat(strides, fields, N);
        structure{cond} = aux;
    end
end
end

