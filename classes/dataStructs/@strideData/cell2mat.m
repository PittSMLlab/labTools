function strideMat = cell2mat(strides, field, N)
%cell2mat  Converts cell array of strideData to matrix
%
%   strideMat = cell2mat(strides, field, N) converts a cell
%   array of strideData objects to a 3D matrix by extracting and
%   resampling the specified field
%
%   Inputs:
%       strides - cell array of strideData objects
%       field - name of property to extract (e.g.,
%               'markerData', 'procEMGData')
%       N - number of samples for resampling
%
%   Outputs:
%       strideMat - 3D matrix (samples x channels x strides)
%                   containing resampled data
%
%   See also: plotCell, plotCellAvg

strideMat = [];
if isa(strides, 'cell') && all(cellisa(strides, 'strideData'))
    auxLst = properties('strideData');
    if any(strcmp(auxLst, field))
        eval(['testField = strides{1}.' field ';'])
        if isa(testField, 'labTimeSeries')
            M = length(strides);
            for i = 1:M
                eval(['testField = strides{i}.' field ';'])
                strideMat(:, :, i) = testField.resampleN(N)...
                    .getDataAsVector(testField.getLabels);
            end
        elseif ~isa(testField, 'double')
            for i = 1:length(strides)
                eval(['testField = strides{i}.' field ';'])
                strideMat(:, :, i) = testField;
            end
        end

    else
        ME = MException('strideDataCell2mat:unknownField', ...
            ['The provided fieldname is not a property of ' ...
            'strideData objects, or is not of labTS type.']);
        throw(ME);
    end
else
    ME = MException('strideDataCell2mat:wrongInput', ...
        ['Input needs to be a cell array of strideData ' ...
        'objects.']);
    throw(ME);
end
end

