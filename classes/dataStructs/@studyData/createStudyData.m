function this = createStudyData(groupAdaptationDataList)
%CREATESTUDYDATA Creates studyData from list of data files.
%
%   this = createStudyData(groupAdaptationDataList) creates a studyData
% object by loading groupAdaptationData objects from a list of files
%
% Inputs:
%   groupAdaptationDataList - cell array of strings containing file paths to
%                             saved groupAdaptationData objects
%
% Outputs:
%   this - studyData object containing all loaded groups
%
% NOTE: This function loads groupAdaptation objects from .mat files. Each
%       file should contain a saved groupAdaptationData object.
%
% Toolbox Dependencies: None
%
% See also STUDYDATA, GROUPADAPTATIONDATA.

% TODO: check that groupAdaptationDataList is a cell of strings
aux = cell(size(groupAdaptationDataList));
for ii = 1:length(groupAdaptationDataList)
    aux{ii} = load(groupAdaptationDataList{ii});
end
this = studyData(aux);
end

