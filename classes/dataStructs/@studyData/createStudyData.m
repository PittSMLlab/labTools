function this = createStudyData(groupAdaptationDataList)
%createStudyData  Creates studyData from list of data files
%
%   this = createStudyData(groupAdaptationDataList) creates a studyData
%   object by loading groupAdaptationData objects from a list of files
%
%   Inputs:
%       groupAdaptationDataList - cell array of strings containing file
%                                 paths to saved groupAdaptationData
%                                 objects
%
%   Outputs:
%       this - studyData object containing all loaded groups
%
%   Note: This function loads groupAdaptation objects from .mat files.
%         Each file should contain a saved groupAdaptationData object.
%
%   See also: studyData, groupAdaptationData

% Check: groupAdaptationDataList is a cell of strings
% Doxy
aux = cell(size(groupAdaptationDataList));
for i = 1:length(groupAdaptationDataList)
    aux{i} = load(groupAdaptationDataList{i});
end
this = studyData(aux);
end

