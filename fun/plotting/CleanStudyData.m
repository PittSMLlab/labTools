function cleanedStudyData = CleanStudyData(StudyData, params)
%CleanStudyData Makes group data files safe to put online
%   For the group data, for each group, it will only keep the parameters
%   that you indicate that you need in params as well as a few that are
%   needed for general proper function such as bas and trial number
cleanedStudyData=StudyData;
% For each group
groups=fieldnames(StudyData);
for g=1:length(groups)
    %For each adaptData
    for a=1:length(StudyData.(groups{g}).adaptData)
        %% Carly's Crude Way --  Only use if you do not have a new enough labtools
%         % Find the labels I want
%         KeepIndex=[1 2 3 find(ismember(StudyData.(groups{g}).adaptData{a}.data.labels, params))'];
%         RemoveIndex=setdiff([1:length(StudyData.(groups{g}).adaptData{a}.data.labels)], KeepIndex);
%         
%         %NAN the data I do not want to share
%         cleanedStudyData.(groups{g}).adaptData{a}.data.Data(:, RemoveIndex)=NaN;
        
        %% Pablo's Way -- Obiviously better!
        cleanedStudyData.(groups{g}).adaptData{a}=cleanedStudyData.(groups{g}).adaptData{a}.reduce(params);
    end
end
end


