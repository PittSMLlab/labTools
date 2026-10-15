function values = c3dParameterValues(group, name, count, default)
%C3DPARAMETERVALUES Collect a per-channel C3D parameter as BTK does.
%
%   C3D parameters hold at most 255 entries, so files with more channels
% continue them in NAME2, NAME3, ... (e.g., ANALOG:LABELS2). Like BTK's
% MetaDataCollapseChildrenValues, this concatenates NAME, NAME2, ...,
% keeps the first COUNT entries, and pads missing entries with DEFAULT.
%
%   Inputs:
%     group   - one parameter group of an ezc3dRead struct
%               (e.g., c3d.parameters.ANALOG)
%     name    - base parameter name (e.g., 'LABELS')
%     count   - number of channels the values describe
%     default - pad value: a char vector for text parameters, a number
%               for numeric ones. For labels pass 'uname*': missing
%               labels become 'uname*1', 'uname*2', ... (by channel)
%
%   Outputs:
%     values - 1-by-COUNT cell array of char (text parameters) or
%              1-by-COUNT double vector (numeric parameters)
%
%   Toolbox Dependencies:
%     None
%
%   See also GETC3DANALOGS, GETC3DMARKERS.

arguments
    group   struct
    name    char
    count   (1,1) double {mustBeNonnegative, mustBeInteger}
    default
end

%% Concatenate NAME, NAME2, NAME3, ...
collected = {};
suffix    = '';
nextIdx   = 2;
while isfield(group, [name suffix])
    data = group.([name suffix]).DATA;
    if ischar(data)
        data = cellstr(data);
    end
    if isnumeric(data) || islogical(data)
        data = num2cell(double(data(:)));
    end
    collected = [collected; data(:)]; %#ok<AGROW>
    suffix    = num2str(nextIdx);
    nextIdx   = nextIdx + 1;
end

%% Trim to COUNT and Pad Missing Entries
isText = ischar(default);
values = cell(1, count);
for ch = 1:count
    if ch <= numel(collected) && ~isempty(collected{ch})
        values{ch} = collected{ch};
    elseif isText && strcmp(default, 'uname*')
        values{ch} = ['uname*' num2str(ch)];
    else
        values{ch} = default;
    end
    if isText
        values{ch} = strtrim(char(values{ch}));
    end
end
if ~isText
    values = cell2mat(values);
end

end
