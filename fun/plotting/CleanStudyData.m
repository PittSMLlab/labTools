function cleanedStudyData = CleanStudyData(StudyData, params)
%CLEANSTUDYDATA Reduce group data to the parameters needed for sharing.
%
%   For every group and adaptationData in the study data, keeps only the
% parameters in params plus the ones required for the data to work (via
% adaptationData.reduce) so the files are safe to put online.
%
% Inputs:
%   StudyData - struct with one field per group, each with an adaptData
%               cell array
%   params    - cell array of parameter names to keep
%
% Outputs:
%   cleanedStudyData - copy of StudyData with reduced adaptData
%
% Toolbox Dependencies: None
%
% See also ADAPTATIONDATA.REDUCE.

cleanedStudyData = StudyData;
% For each group
groups = fieldnames(StudyData);
for g = 1:length(groups)
    %For each adaptData
    for a = 1:length(StudyData.(groups{g}).adaptData)
        % Fallback for labtools versions without reduce() (commented out):
        % % Find the labels I want
        % KeepIndex=[1 2 3 ...
        %    find(ismember(StudyData.(groups{g}).adaptData{ ...
        %    a}.data.labels, params))'];
        % RemoveIndex=setdiff( ...
        %    [1:length(StudyData.(groups{g}).adaptData{a}.data.labels)], ...
        %    KeepIndex);
        %
        % %NAN the data I do not want to share
        % cleanedStudyData.(groups{g}).adaptData{a}.data.Data(:, ...
        %    RemoveIndex)=NaN;

        % Keep only the requested parameters
        cleanedStudyData.(groups{g}).adaptData{a} = ...
            cleanedStudyData.(groups{g}).adaptData{a}.reduce(params);
    end
end
end


