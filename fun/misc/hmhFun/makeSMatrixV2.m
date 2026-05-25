function Subs = makeSMatrixV2
%MAKESMATRIXV2 Build a groupAdaptationData struct from params.mat files.
%
%   Scans the current working directory for *params.mat files, loads
% each adaptData variable, and groups subjects by the abbreviated group
% string from adaptData.metaData.ID. Returns each group as a
% groupAdaptationData object rather than a raw struct.
%
% Inputs:
%   None
%
% Outputs:
%   Subs - Struct with one field per group, each a groupAdaptationData
%          object constructed from all subjects' adaptData in that group
%
% Toolbox Dependencies: None
%
% See also MAKESMATRIX, GROUPADAPTATIONDATA, GETRESULTSSMART.

sub      = struct;
files    = what;
fileList = files.mat;

for ii = 1:length(fileList)
    aux1 = strfind(lower(fileList{ii}), 'params');
    if ~isempty(aux1)
        subID      = fileList{ii}(1:(aux1 - 1));
        % subID = adaptData.subData.ID; % I think this is more appropriate.-Pablo
        load(fileList{ii});

        group      = adaptData.metaData.ID;
        abrevGroup = group(ismember(group, ['A':'Z' 'a':'z']));
        if isempty(abrevGroup)
            abrevGroup = 'NoDescription';
        end

        if isfield(sub, abrevGroup)
            sub.(abrevGroup).IDs{end+1}       = subID;
            sub.(abrevGroup).adaptData{end+1} = adaptData;
        else
            sub.(abrevGroup).IDs      = {subID};
            sub.(abrevGroup).adaptData = {adaptData};
        end
    end
end

groups = fields(sub);
for ii = 1:length(groups)
    Subs.(groups{ii}) = groupAdaptationData( ...
        sub.(groups{ii}).IDs, sub.(groups{ii}).adaptData);
end

end
