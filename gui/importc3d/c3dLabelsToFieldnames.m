function fieldNames = c3dLabelsToFieldnames(labels)
%C3DLABELSTOFIELDNAMES Convert C3D labels to field names exactly as BTK.
%
%   Reproduces btkMXCreateMeasuresStructure (BTKCore,
% Wrapping/Matlab/btkMXMeasure.h), which names the fields returned by
% btkGetAnalogs and btkGetMarkers:
%     1. every character is mapped through btk::ASCIIConverter; letters
%        and digits are kept and other characters become '_' (so
%        'Force.Fx1' -> 'Force_Fx1' and Vicon '*12' -> '_12')
%     2. a 'C' is prepended when the result starts with '_' or a digit
%        ('_12' -> 'C_12', which loadTrials skips as unlabeled)
%     3. a repeated name gets a numeric suffix, using BTK's single pass
%        over the names already assigned ('X', 'X' -> 'X', 'X1')
%
%   Inputs:
%     labels - cell array of C3D channel labels (char), in file order
%
%   Outputs:
%     fieldNames - cell array of field names, same size as labels
%
%   Toolbox Dependencies:
%     None
%
%   See also GETC3DANALOGS, GETC3DMARKERS, MATLAB.LANG.MAKEVALIDNAME.

arguments
    labels cell
end

fieldNames = cell(size(labels));
for ii = 1:numel(labels)
    lbl = char(labels{ii});

    %% Map Characters (btk::ASCIIConverter)
    % NOTE: only ASCII letters and digits are confirmed to pass through;
    % BTK's table also maps some accented Latin-1 letters, which do not
    % occur in lab labels. VALIDATEC3DREADERS checks every name.
    isKept = (lbl >= 'A' & lbl <= 'Z') | (lbl >= 'a' & lbl <= 'z') | ...
        (lbl >= '0' & lbl <= '9');
    converted = lbl;
    converted(~isKept) = '_';

    %% Fix an Invalid First Character
    if ~isempty(converted) && (converted(1) == '_' || ...
            (converted(1) >= '0' && converted(1) <= '9'))
        converted = ['C' converted]; %#ok<AGROW>
    end

    %% Disambiguate Repeated Names (BTK's single-pass rule)
    suffixId  = 0;
    candidate = converted;
    for jj = 1:(ii - 1)
        if strcmp(candidate, fieldNames{jj})
            suffixId  = suffixId + 1;
            candidate = [converted num2str(suffixId)];
        end
    end
    fieldNames{ii} = candidate;
end

end
