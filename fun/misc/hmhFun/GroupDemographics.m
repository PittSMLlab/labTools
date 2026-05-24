function [ Demographics ] = GroupDemographics(SMatrix)

grps=fieldnames(SMatrix);
StudyAge=[];
StudyMale=[];
for g=1:length(grps)  
    [Demographics.(grps{g})]=SMatrix.(grps{g}).GroupDemographics;
    StudyAge=[StudyAge Demographics.(grps{g}).AllAge];
    StudyMale=[StudyMale Demographics.(grps{g}).NMale];
end

Demographics.StudyDemographics.N=length(StudyAge);
Demographics.StudyDemographics.MeanAge=mean(StudyAge);
Demographics.StudyDemographics.StdAge=std(StudyAge);
Demographics.StudyDemographics.NMale=sum(StudyMale);
end

%GROUPDEMOGRAPHICS Compute group and study-level demographics.
%
%   Calculates the number of subjects, mean and SD of age, and number of
% males for each group in SMatrix, then aggregates across all groups for
% study-level summaries.
%
% Inputs:
%   SMatrix - Struct whose fields are group names; each field must have
%             a GroupDemographics sub-struct with AllAge and NMale fields
%             (as returned by makeSMatrixV2 or uiCreateStudy)
%
% Outputs:
%   Demographics - Struct with one field per group from SMatrix plus a
%                  StudyDemographics field containing N, MeanAge, StdAge,
%                  and NMale aggregated across all groups
%
% Toolbox Dependencies: None
%
% See also MAKESMATRIXV2, UICREATESTUDY.
